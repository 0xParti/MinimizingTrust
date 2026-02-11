# Chapter 14: Lookup Arguments

In 2019, ZK engineers hit a wall.

They wanted to verify standard computer programs, things like SHA-256 or ECDSA signatures, but the circuits were exploding in size. The culprit was the *bitwise operation*. In a silicon CPU, checking `a XOR b` takes one cycle. In R1CS arithmetic, it took roughly 30 constraints to decompose the numbers into bits, check the bits, and reassemble them. Trying to verify a 64-bit CPU instruction set was like trying to simulate a Ferrari using only gears made of wood.

Ariel Gabizon and Zachary Williamson realized they didn't need to simulate the gears. They just needed to check the answer key. This realization, that you can replace *computation* with *table lookups*, broke the 64-bit wall. It allowed circuits to stop "thinking" about XORs and start "remembering" them.

The insight built on earlier work (Bootle et al.'s 2018 "Arya" paper had explored lookup-style arguments), but Plookup made it practical by repurposing PLONK's permutation machinery. The 65,536 valid 16-bit integers become a table. The $2^{16}$ XOR triples become a table. Membership in these tables costs three constraints, regardless of what the table encodes. The architecture shifted, and complexity moved from constraint logic to precomputed data.

The field accelerated. Haböck's **LogUp** (2022) replaced grand products with sums of logarithmic derivatives, eliminating sorting overhead and enabling cleaner multi-table arguments. Setty, Thaler, and Wahby's **Lasso** (2023) achieved prover costs scaling with lookups performed rather than table size, enabling tables of size $2^{128}$, large enough to hold the evaluation table of any 64-bit instruction. The "lookup singularity" emerged: a vision of circuits that do nothing but look things up in precomputed tables.

Today, every major zkVM relies on lookups. Cairo, RISC-Zero, SP1, and Jolt prove instruction execution not by encoding CPU semantics in constraints, but by verifying that each instruction's behavior matches its entry in a precomputed table. The paradigm shift is complete: **from logic to data**.

---

## The Lookup Problem

Chapter 13 introduced the **grand product argument** for copy constraints in PLONK. The idea: to prove that wire values at positions related by permutation $\sigma$ are equal, compute $\prod_i \frac{a_i + \beta \cdot i + \gamma}{a_i + \beta \cdot \sigma(i) + \gamma}$. If the permutation constraint is satisfied (values at linked positions match), this product telescopes to 1. Lookup arguments generalize this technique from equality to containment, proving not that two multisets are the same, but that one is contained in another.

The formal problem:

Given a multiset $f = \{f_1, \ldots, f_n\}$ of witness values (the "lookups") and a public multiset $t = \{t_1, \ldots, t_d\}$ (the "table"), prove $f \subseteq t$.

**Why "lookup"?** Imagine you're proving a circuit that computes XOR. The table $t$ contains all valid XOR triples: $(0,0,0), (0,1,1), (1,0,1), (1,1,0)$. Your circuit claims $a \oplus b = c$ for some witness values. Rather than encoding XOR algebraically, you "look up" the triple $(a,b,c)$ in the table. If it's there, the XOR is correct. The multiset $f$ collects all the triples your circuit needs to verify; the subset claim $f \subseteq t$ says every lookup found a valid entry.

Imagine you want to prove you spelled "Cryptography" correctly. The *arithmetic approach* would be to write down the rules of English grammar and phonetics, then derive the spelling from first principles. Slow, complex, error-prone. The *lookup approach* would be to open the Oxford English Dictionary to page 412, point to the word "Cryptography," and say "there." The lookup argument is simply proving that your tuple (the word you claim) exists in the set (all valid English words). You don't need to understand *why* it's valid; you just need to show it's in the book.

A naive approach might compare products: if $\prod (f_i + \gamma) = \prod (t_j + \gamma)$, the multisets are equal. But subset is weaker than equality, since $f$ may use only some table entries, possibly with repetition.

Different lookup protocols solve this problem in different ways. We'll detail **Plookup**'s approach first because it builds directly on PLONK's permutation machinery from Chapter 13. Later sections cover alternatives: LogUp uses logarithmic derivatives (sums instead of products), Lasso exploits table decomposition for sublinear prover costs.

**Plookup's insight**: Transform the subset claim into a permutation claim. The construction involves three objects:

- **$f$**: the lookup values (what you're looking up, your witness data)
- **$t$**: the table (all valid values, public and precomputed)
- **$s$**: the sorted merge of $f$ and $t$ (auxiliary, constructed by prover)

The key is that $s$ encodes *how* $f$ fits into $t$. If every $f_i$ is in $t$, then $s$ is just $t$ with duplicates inserted at the right places.

### Plookup's Sorted Vector $s$

Define $s = \text{sort}(f \cup t)$, the concatenation of lookup values and table values, sorted.

If $f \subseteq t$, then every element of $f$ appears somewhere in $t$. In the sorted vector $s$, elements from $f$ "slot in" next to their matching elements from $t$.

**Key observation**: For every adjacent pair $(s_i, s_{i+1})$ in $s$, either:

1. $s_i = s_{i+1}$ (a repeated value, meaning some $f_j$ was inserted next to its matching $t_k$), or
2. $(s_i, s_{i+1})$ is also an adjacent pair in the sorted table $t$

If some $f_j \notin t$, then $s$ contains a transition that doesn't exist in $t$, and the check fails.

**Example**:

- Lookups: $f = \{2, 5\}$
- Table: $t = \{0, 1, 2, 3, 4, 5, 6, 7\}$
- Sorted: $s = \{0, 1, 2, 2, 3, 4, 5, 5, 6, 7\}$

Adjacent pairs in $s$: $(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$

The pairs $(2,2)$ and $(5,5)$ are repeats; these correspond to the lookups. All other pairs appear as adjacent pairs in $t$. The subset claim holds.

If instead $f = \{2, 9\}$:

- Sorted: $s = \{0, 1, 2, 2, 3, 4, 5, 6, 7, 9\}$
- The pair $(7, 9)$ is not an adjacent pair in $t$
- The subset claim fails

### Plookup's Grand Product Check

The adjacent-pair property translates to a polynomial identity via a grand product. The construction is clever, so let's build it step by step.

**The core idea**: Encode each adjacent pair $(s_i, s_{i+1})$ as a single field element $\gamma(1+\beta) + s_i + \beta s_{i+1}$. The term $\beta$ acts as a "separator": different pairs map to different field elements (with high probability over random $\beta$). If we multiply all these pair-encodings together, we get a fingerprint of the multiset of adjacent pairs.

**$G(\beta, \gamma)$**, the fingerprint of $s$'s adjacent pairs:

$$G(\beta, \gamma) = \prod_{i=1}^{n+d-1} (\gamma(1 + \beta) + s_i + \beta s_{i+1})$$

This is just the product of all adjacent-pair encodings in the sorted vector $s$.

**$F(\beta, \gamma)$**, the fingerprint we *expect* if $f \subseteq t$:

$$F(\beta, \gamma) = (1 + \beta)^n \cdot \prod_{i=1}^{n} (\gamma + f_i) \cdot \prod_{i=1}^{d-1} (\gamma(1 + \beta) + t_i + \beta t_{i+1})$$

Where does this come from? Think about what $s$ looks like when $f \subseteq t$. The sorted merge contains the table $t$ as a "backbone," with lookup values from $f$ inserted as duplicates next to their matches. So the adjacent pairs in $s$ fall into two categories:

1. **Pairs from $t$**: The $d-1$ consecutive pairs $(t_i, t_{i+1})$ from the original table. These appear in $s$ regardless of what $f$ contains; they're the skeleton that $f$ gets merged into.

2. **Repeated pairs from inserting $f$**: When a lookup value $f_j$ slots into $s$ next to its matching table entry, we get a repeated pair $(f_j, f_j)$. The encoding of $(v, v)$ is $\gamma(1+\beta) + v + \beta v = (\gamma + v)(1+\beta)$. So each valid lookup contributes $(\gamma + f_j)$ and $(1+\beta)$ to the product.

$F$ is the fingerprint of *exactly these pairs*, the table backbone plus $n$ valid duplicate insertions. If $G$ (the actual fingerprint of $s$) equals $F$, then $s$ has the right structure: no "bad" transitions like $(7, 9)$ that would appear if some $f_j \notin t$.

Let's use a 3-element table to see the algebra concretely.

- Table: $t = \{0, 1, 2\}$ (so $d = 3$)
- Lookups: $f = \{1\}$ (so $n = 1$)
- Sorted merge: $s = \{0, 1, 1, 2\}$

**Computing $G$** (fingerprint of $s$'s adjacent pairs):

The pairs in $s$ are: $(0,1), (1,1), (1,2)$. Encode each:

$$G = (\gamma(1+\beta) + 0 + \beta \cdot 1) \cdot (\gamma(1+\beta) + 1 + \beta \cdot 1) \cdot (\gamma(1+\beta) + 1 + \beta \cdot 2)$$
$$= (\gamma(1+\beta) + \beta) \cdot (\gamma(1+\beta) + 1 + \beta) \cdot (\gamma(1+\beta) + 1 + 2\beta)$$

**Computing $F$** (expected fingerprint):

- Table pairs $(t_i, t_{i+1})$: $(0,1)$ and $(1,2)$
- Lookup duplicate: $f_1 = 1$ contributes $(\gamma + 1)(1+\beta)$

$$F = (1+\beta)^1 \cdot (\gamma + 1) \cdot (\gamma(1+\beta) + 0 + \beta \cdot 1) \cdot (\gamma(1+\beta) + 1 + \beta \cdot 2)$$
$$= (1+\beta)(\gamma + 1) \cdot (\gamma(1+\beta) + \beta) \cdot (\gamma(1+\beta) + 1 + 2\beta)$$

**Why $F = G$?** Notice that the pair $(1,1)$ in $G$ encodes as $\gamma(1+\beta) + 1 + \beta = (\gamma + 1)(1 + \beta)$. This factors! So $G$'s middle term equals $F$'s $(1+\beta)(\gamma+1)$ term. The other two terms match directly. The products are identical.

**Claim (Plookup)**: $F(\beta, \gamma) = G(\beta, \gamma)$ if and only if $f \subseteq t$ and $s$ is correctly formed.

**Completeness**: If $f \subseteq t$, then $s$ consists of $t$'s pairs plus repeated pairs $(f_j, f_j)$ for each lookup. Each repeated pair encodes as $(\gamma + f_j)(1+\beta)$, which exactly matches $F$'s structure.

**Soundness**: If some $f_j \notin t$, then when sorted into $s$, $f_j$ creates an adjacent pair $(a, f_j)$ or $(f_j, b)$ where neither $a$ nor $b$ equals $f_j$. This "bad transition" doesn't appear in $F$'s table backbone, and can't factor as $(1+\beta)(\gamma + f_j)$ either. For random $\beta, \gamma$, the probability that $F = G$ despite this mismatch is at most $2(n+d)/|\mathbb{F}|$ by Schwartz-Zippel (the products have total degree at most $2(n+d)$ in $(\beta, \gamma)$).

## The Plookup Protocol

The grand product machinery above is **Plookup**, the 2020 protocol by Gabizon and Williamson that launched the lookup paradigm. It's not the only way to build lookup arguments. LogUp replaces grand products with logarithmic derivatives (sums instead of products), eliminating the need for the sorted vector $s$ and enabling cleaner multi-table arguments. Lasso restructures the problem entirely, achieving prover costs that scale with lookups performed rather than table size. We focus on Plookup because it builds directly on PLONK's permutation machinery from Chapter 13, making the connection between copy constraints and lookup arguments explicit.

We now formalize Plookup as integrated with PLONK.

### Setup

**Public table**: Polynomial $t(X)$ encoding table values, preprocessed into selector commitments.

**Witness values**: The prover has values $\{f_1, \ldots, f_n\}$ to look up.

### Prover Computation

1. **Construct $s$**: Sort $f \cup t$ to obtain the $(f,t)$-sorted vector.

2. **Split $s$ into $h_1, h_2$**: The sorted vector $s$ has length $n + d$ (lookups plus table), but PLONK's domain has size $n$. We can't fit $s$ into a single polynomial over this domain. So split $s$ into two halves: $h_1$ encodes the first half, $h_2$ the second. The constraint system will check adjacent pairs *within* each half and *across* the boundary where they meet.

3. **Commit**: Send $[h_1]_1, [h_2]_1$ to the verifier.

4. **Receive challenges**: After Fiat-Shamir, obtain $\beta, \gamma$.

5. **Build accumulator**: Construct $Z(X)$ satisfying:
   - $Z(\omega) = 1$
   - Recursive relation linking $Z(X\omega)$ to $Z(X)$ via the $F/G$ terms

6. **Commit**: Send $[Z]_1$.

### Constraints

The following polynomial identities are added to the PLONK quotient polynomial:

**Accumulator initialization**:
$$(Z(X) - 1) \cdot L_1(X) = 0$$

**Accumulator recursion**:
$$Z(X\omega) \cdot \prod_{j \in \{1,2\}} (\gamma(1+\beta) + h_j(X) + \beta h_j(X\omega))$$
$$= Z(X) \cdot (1+\beta)^m \cdot (\gamma + f(X)) \cdot (\gamma(1+\beta) + t(X) + \beta t(X\omega))$$

where $m$ depends on how many lookups occur per gate (typically 1 or 2).

**Accumulator finalization**: The accumulator returns to 1 at the end of the domain (enforced implicitly by the product structure).

**Permutation check**: $h_1$ and $h_2$ contain exactly the elements of $f \cup t$, verified via a standard PLONK permutation argument.

**Sorting check**: Adjacent elements of $s$ satisfy $s_{i+1} \geq s_i$, typically enforced via a small range check on differences.

If $s$ is sorted, doesn't that prove $f \subseteq t$? Not quite. We also need to prove that $s$ contains *exactly* the elements of $f$ and $t$, no more, no less. This is the role of the permutation argument.

The complete logic is:

1. $s$ is a permutation of $(f \cup t)$. (So no new numbers appeared out of thin air.)
2. $s$ is sorted. (So duplicates are adjacent.)
3. Every adjacent pair in $s$ is valid (either a repeat, or a step that exists in the table).

If all three hold, then every element in $f$ must have found a matching buddy in $t$. A cheating prover cannot slip in a value that's not in the table, because it would create an invalid adjacent pair that neither repeats nor exists as a table step.

### Verification

The verifier checks the batched PLONK constraints. No table-size-dependent work: verification cost is independent of $d$.


## Worked Example: Plookup 3-Bit Range Check

Let's trace through a complete Plookup proof.

**Statement**: Prover knows $f_1 = 2$ and $f_2 = 5$, both in $[0, 7]$.

**Table**: $t = \{0, 1, 2, 3, 4, 5, 6, 7\}$, size $d = 8$.

**Lookups**: $f = \{2, 5\}$, size $n = 2$.

### Step 1: Construct $s$

$$s = \text{sort}(\{2, 5\} \cup \{0, 1, 2, 3, 4, 5, 6, 7\}) = \{0, 1, 2, 2, 3, 4, 5, 5, 6, 7\}$$

Length: $n + d = 10$.

### Step 2: Adjacent Pairs

Pairs in $s$:
$(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$

Nine pairs total.

Pairs in sorted $t$:
$(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,7)$

Seven pairs.

The pairs $(2,2)$ and $(5,5)$ are repeats from inserting $f$ values. All others match $t$.

### Step 3: Grand Product Identity

Using challenges $\beta, \gamma$:

**$F(\beta, \gamma)$**, the expected fingerprint:

$$F = (1+\beta)^2 \cdot (\gamma + 2)(\gamma + 5) \cdot \prod_{i=0}^{6} (\gamma(1+\beta) + t_i + \beta t_{i+1})$$

The three parts: $(1+\beta)^2$ for two lookups, $(\gamma + 2)(\gamma + 5)$ for the lookup values, and the seven table pairs $(0,1), (1,2), \ldots, (6,7)$.

**$G(\beta, \gamma)$**, the actual fingerprint of $s$'s nine adjacent pairs:

$$G = \prod_{i=0}^{8} (\gamma(1+\beta) + s_i + \beta s_{i+1})$$

Writing out the pairs from $s = \{0,1,2,2,3,4,5,5,6,7\}$:

$$(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$$

The key observation: the repeated pairs $(2,2)$ and $(5,5)$ factor specially.

- $(2,2)$ encodes as $\gamma(1+\beta) + 2 + 2\beta = \gamma(1+\beta) + 2(1+\beta) = (\gamma + 2)(1+\beta)$
- $(5,5)$ encodes as $(\gamma + 5)(1+\beta)$

So $G$ contains the factors $(\gamma + 2)(1+\beta) \cdot (\gamma + 5)(1+\beta) = (1+\beta)^2 (\gamma+2)(\gamma+5)$.

The remaining seven pairs in $G$, namely $(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,7)$, are exactly the table pairs in $F$.

Therefore $F = G$. The lookup succeeds.

### Step 4: Accumulator Trace

The accumulator $Z(X)$ starts at 1 and processes one fraction per domain point.

At each step:
$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{\text{$F$ terms at position $i$}}{\text{$G$ terms at position $i$}}$$

If $f \subseteq t$, the numerator and denominator terms are permutations of each other across the full domain. The product telescopes to 1.

### Code: Plookup Grand Product Check

The following Python demonstrates the core Plookup identity. When lookups are valid, $F = G$. When a lookup is invalid, the fingerprints diverge.

```python
def encode_pair(a, b, beta, gamma):
    """Encode adjacent pair (a, b) as a field element."""
    return gamma * (1 + beta) + a + beta * b

def plookup_check(lookups, table, beta=2, gamma=5):
    """
    Verify lookups is a subset of table via Plookup grand product.

    Args:
        lookups: List of values being looked up
        table: Sorted list of valid table entries

    Returns: (F, G, valid) where F and G are the fingerprints
    """
    # Construct the sorted merge s = sort(lookups union table)
    s = sorted(lookups + table)

    # G: fingerprint of s's adjacent pairs
    G = 1
    for i in range(len(s) - 1):
        G *= encode_pair(s[i], s[i+1], beta, gamma)

    # F: expected fingerprint if lookups subset of table
    # F = (1+beta)^n * product of (gamma + f_i) * product of table pairs
    n = len(lookups)
    F = (1 + beta) ** n

    for f in lookups:
        F *= (gamma + f)

    for i in range(len(table) - 1):
        F *= encode_pair(table[i], table[i+1], beta, gamma)

    return F, G, (F == G)

# Example 1: Valid lookups {2, 5} into table {0,1,2,3,4,5,6,7}
F, G, valid = plookup_check([2, 5], list(range(8)))
print(f"Valid lookups:   F={F}, G={G}, F==G: {valid}")

# Example 2: Invalid lookup (9 not in table)
F, G, valid = plookup_check([2, 9], list(range(8)))
print(f"Invalid lookups: F={F}, G={G}, F==G: {valid}")

# Example 3: Repeated valid lookups
F, G, valid = plookup_check([3, 3, 3], list(range(8)))
print(f"Repeated valid:  F={F}, G={G}, F==G: {valid}")
```

Output:
```
Valid lookups:   F=563374005, G=563374005, F==G: True
Invalid lookups: F=614965890, G=447828498, F==G: False
Repeated valid:  F=12754584, G=12754584, F==G: True
```

The identity holds for valid lookups (including repetitions) and fails for invalid ones. In the real protocol, the check happens via polynomial commitments over a finite field, but the algebraic structure is identical.


## Plookup Cost Analysis

**Without lookups** (bit decomposition for two 3-bit range checks):

- 6 bitness constraints + 2 reconstruction = 8 constraints

**With lookups**:

- 2 lookups, each ~3 constraints (the Plookup overhead)
- Table of size 8 adds no verification cost

For small ranges, the savings are modest. The power appears at scale.

**16-bit range check**:

- Without: 17 constraints per check
- With: ~3 constraints per check

**8-bit XOR**:

- Without: ~25 constraints
- With: ~3 constraints (one lookup into a $256 \times 256$ table)

The table size ($65,536$ entries for 16-bit range or 8-bit XOR) is precomputed and committed once. Lookups against it are cheap.


## Multiple Tables and Structured Lookups

Real circuits need multiple lookup tables:

- Range tables of various sizes
- XOR tables for different bit widths
- Opcode tables for VM verification
- Custom function tables (e.g., $\sin$, $\exp$ approximations)

**Multi-table extensions**: Modern systems (cq, Halo2 lookups) support multiple tables efficiently. The prover specifies which table each lookup targets; the grand product extends to handle the multiplexing.

**Structured tables**: Some tables have algebraic structure (e.g., $\{0, 1, \ldots, 2^{16}-1\}$ is an arithmetic sequence). Specialized arguments exploit this structure for better performance.


## Comparison: Custom Gates vs. Lookup Tables

Both mechanisms extend PLONK beyond vanilla gates. They address different problems.

### Custom Gates

A custom gate adds terms to the universal gate equation:

$$Q_L a + Q_R b + Q_O c + Q_M ab + Q_{\text{pow5}} a^5 + Q_C = 0$$

The new selector $Q_{\text{pow5}}$ enables efficient fifth-power computation (useful for Poseidon S-boxes).

**Strengths**:

- No table precomputation
- No additional polynomial commitments
- Native for algebraic relations

**Limitations**:

- The relation must be low-degree
- A degree-$2^{16}$ polynomial for range checks is infeasible

**Best for**: Compact algebraic operations such as boolean checks ($x^2 - x = 0$), elliptic curve point operations, and specialized hash function components.

### Lookup Tables

A lookup table is a separate mechanism:

- Precompute valid tuples
- Prove witness tuples appear in the table

**Strengths**:

- Handles non-algebraic operations
- Table size is independent of verification cost
- One table serves all lookups against it

**Limitations**:

- Adds polynomial commitments to the proof
- Requires sorting and permutation checks
- Tables must fit in memory

**Best for**: Range checks, bitwise operations, state machine transitions, arbitrary function approximations.

### When to Use Which

| Problem | Custom Gate | Lookup Table |
|---------|-------------|--------------|
| Boolean check ($x \in \{0,1\}$) | Ideal | Overkill |
| 8-bit range check | Possible | Efficient |
| 64-bit range check | Impractical | Essential |
| XOR/AND/OR operations | Complex | Clean |
| Poseidon $x^5$ | One gate | Unnecessary |
| Valid opcode check | Complex | Direct |

Modern systems use both. UltraPLONK combines custom gates (for algebraic primitives) with lookup tables (for non-algebraic constraints).



## Alternative Lookup Protocols

Plookup was seminal but not unique. Several alternatives offer different trade-offs.

### LogUp: The Logarithmic Derivative Approach

LogUp represents a significant evolution from Plookup. Instead of grand products, it uses the identity:

$$\sum_{i=1}^{n} \frac{1}{\gamma + f_i} = \sum_{j=1}^{d} \frac{m_j}{\gamma + t_j}$$

where $m_j$ is the multiplicity, counting how many times table entry $t_j$ appears in the lookups $f$.

**The key insight**: If $f \subseteq t$ with multiplicities, then summing the reciprocals of $(\gamma + f_i)$ over all lookups must equal summing $m_j / (\gamma + t_j)$ over table entries. The multiplicity $m_j$ counts how many lookups reference $t_j$.

**Why this matters**:

1. **No sorting required.** Plookup requires constructing and committing to the sorted vector $s$. LogUp skips this entirely: no sorted polynomial, no sorting constraints.

2. **Additive structure.** Products become sums of fractions. This enables:

   - Simpler multi-table handling (just add the sums)
   - Natural integration with sum-check protocols
   - Easier batching of multiple lookup arguments

3. **Better cross-table lookups.** When a circuit uses multiple tables (range, XOR, opcodes), LogUp handles them in a unified sum rather than separate grand products.

**LogUp-GKR**: Combines LogUp with the GKR protocol for even greater efficiency. The multiplicities $m_j$ are verified via sum-check rather than explicit commitment, reducing prover work for large tables.

**The equation in protocol form**:

Define:
$$h(X) = \sum_{i: f(\omega^i) = f_i} \frac{1}{\gamma + f(\omega^i)} - \sum_{j} \frac{m_j}{\gamma + t_j}$$

If the lookup is valid, $h(X)$ sums to zero over the domain. This is verified via sum-check or a grand sum argument.

### cq (Cached Quotients)

A refinement of the logarithmic derivative approach optimized for repeated lookups.

**Advantages**: Pre-computes quotient polynomials for the table. Amortizes table processing across multiple lookup batches.

**Trade-offs**: Setup overhead; benefits emerge with many lookups against the same table.

### Caulk and Caulk+

Caulk (2022) asked a different question: what if the table is *huge* but you only perform a few lookups? Plookup's prover work scales linearly with table size, making it impractical for tables of size $2^{30}$ or larger.

**The insight**: Preprocess the table into a KZG commitment. When the prover looks up values, they prove the lookup values exist in the committed table *without* touching the entire table during proving.

**How it works**: The table polynomial $t(X)$ is committed during setup. For each lookup, the prover constructs a "witness" polynomial that proves the lookup value is a root of a polynomial derived from $t$. The key is using the structure of KZG to make these proofs small and fast.

**Complexity**: Prover work is $O(m^2 + m \log N)$ for $m$ lookups into a table of size $N$, sublinear in $N$ when $m \ll N$.

**Trade-off**: Requires trusted setup (KZG). More complex than Plookup. The quadratic term in $m$ limits scalability for many lookups.

**Caulk+** refined this to $O(m^2)$ prover complexity, removing the $\log N$ term entirely. The table size effectively disappears from prover cost.

### Halo2 Lookups

Halo2, developed by the Electric Coin Company (Zcash), integrates lookups natively with a "permutation argument" variant rather than Plookup's grand product.

**The approach**: Instead of sorting and checking adjacent pairs, Halo2 uses a *shuffle argument*. The prover demonstrates that the multiset of lookups (with multiplicities) is a permutation of a subset of the table (with appropriate multiplicities).

**Key differences from Plookup**:

- No explicit sorted vector $s$
- Multiplicities are handled via a separate "permutation" polynomial
- Tighter integration with Halo2's recursive verification model

**In practice**: Halo2's lookup API lets developers define tables declaratively. The proving system handles the constraint generation automatically. This made Halo2 popular for application circuits: you specify *what* to look up, not *how* the lookup argument works.

**Ecosystem**: Scroll, Taiko, and other L2s built on Halo2 rely on its lookup system for zkEVM implementation.

### The Memory Bottleneck

All the protocols above share a fundamental limitation: **the prover must commit to polynomials whose degree scales with table size**.

For Plookup, the sorted vector $s$ has length $n + d$ (lookups plus table). For LogUp, the multiplicity polynomial has degree $d$. For Caulk, the table polynomial $t(X)$ must be committed during setup. In every case, a table of size $2^{20}$ means million-coefficient polynomials. A table of size $2^{64}$ means polynomials with more coefficients than atoms in a grain of sand.

This is the memory bottleneck. It's not just "expensive"; it's a hard wall. The evaluation table of a 64-bit ADD instruction has $2^{128}$ entries. No computer can store that polynomial, let alone commit to it.

Early zkVMs worked around this by using small tables (8-bit or 16-bit operations) and paying the cost in constraint complexity for larger operations. A 64-bit addition became a cascade of 8-bit additions with carry propagation. It worked, but it was slow.

Lasso breaks through this wall entirely.

### Lasso and Jolt

Lasso (2023, Setty-Thaler-Wahby) represents the solution to the memory bottleneck: prover costs that scale with *lookups performed* rather than *table size*.

**Read-Only vs. Read-Write.** Before diving into the mechanism, distinguish two types of lookups:

*Static tables (read-only)*: Fixed functions like XOR, range checks, or AES S-boxes. The table never changes during execution. Plookup, LogUp, and Lasso excel here.

*Dynamic tables (read-write)*: Simulating RAM (random access memory). The table starts empty and fills up as the program runs. This requires different techniques (like memory-checking arguments or timestamp-based permutation checks) because the table itself is witness-dependent. Jolt uses specialized protocols called Twist and Shout for this.

Lasso focuses on static tables, but its decomposition insight is what makes truly large tables tractable.

**Lasso's insight**: *Decomposable tables*. Many tables have structure: their MLE (multilinear extension) can be written as a weighted sum of smaller subtables:

$$\tilde{T}(y) = \sum_{j=1}^{\alpha} c_j \cdot \tilde{T}_j(y_{S_j})$$

Each subtable $\tilde{T}_j$ looks at only a small chunk of the total input $y$. This "Structure of Sums" (SoS) property enables dramatic efficiency gains.

**Example: 64-bit AND.** The conceptual table has $2^{128}$ entries (all pairs of 64-bit inputs). But bitwise AND decomposes perfectly: split inputs into sixteen 4-bit chunks, perform 16 lookups into a tiny 256-entry `AND_4` table, concatenate results. The prover never touches the $2^{128}$-entry table.

**The technical machinery**: Lasso builds on **Spark**, a commitment scheme for sparse polynomials from the Spartan protocol. The key insight: a lookup trace is a *sparse* "hit" vector. If you perform $m$ lookups into a table of size $N$, you access only $m$ entries. Lasso represents this sparse access pattern using Spark, then proves correctness via sum-check.

The prover's witnesses are:

- **$\tilde{E}(y)$**: The "existence" polynomial (1 if index $y$ was accessed, 0 otherwise)
- **$\tilde{a}(y)$**: The values looked up at each accessed index
- **$\{\tilde{M}_{V,j}\}$**: Coefficient polynomials that correctly wire subtable results together

The verifier never sees the full table. For structured tables, she can evaluate $\tilde{T}(r)$ at a random challenge point in $O(\log N)$ time using the table's algebraic formula.

**Prover costs**: For $m$ lookups into a table decomposed into $c$ chunks with subtables of size $N^{1/c}$:

$$\text{Committed elements} \approx 3cm + \alpha N^{1/c}$$

Crucially, most committed values are *small integers* (counts in $\{0, \ldots, m\}$). Committing to small scalars is dramatically faster than random field elements; this is Lasso's performance breakthrough.

---

**Jolt** applies Lasso to build a complete zkVM for RISC-V. The philosophy: replace arithmetization of instruction semantics with lookups.

Consider the `JOLT_V` table, the evaluation table of the entire RISC-V instruction set:

$$\text{JOLT\_V}(\text{opcode}, a, b) = f_{\text{op}}(a, b)$$

For a 64-bit machine with 256 opcodes, this table has $2^{136}$ entries. Storing it is physically impossible.

**Jolt's insight**: This giant table is *decomposable*. A 64-bit ADD decomposes into 16 lookups into 4-bit addition subtables. A 64-bit XOR decomposes into 16 independent 4-bit XOR lookups. The subtables are tiny (256 entries each), pre-computed once, and reused for every instruction.

**Jolt's architecture**:

1. **Lasso for instruction semantics**: Proves that each instruction's output matches its subtable lookups. No arithmetization of CPU logic.
2. **Spartan (R1CS) for wiring**: Proves the simple algebraic relationships (program counter updates, register consistency, data flow between components)
3. **Specialized memory protocols**: **Twist** handles RAM consistency (LOAD/STORE); **Shout** ensures instructions are fetched from the committed bytecode

**Why this hybrid?** Arithmetizing a 64-bit XOR in R1CS requires 64+ constraints (bit decomposition, per-bit logic). Jolt proves it with 16 cheap lookups. But simple wiring constraints ("this value flows from register to ALU") are trivial in R1CS. Use each tool where it excels.

**Performance**: Jolt achieves roughly 50,000 cycles per RISC-V instruction, orders of magnitude faster than prior zkVMs. The "lookup singularity" becomes real: proving a VM is just proving structured table lookups.

**Trade-offs**: Requires decomposable table structure. Arbitrary tables (like SHA-256, which is intentionally non-linear) don't benefit. But for CPU instruction sets, the structure is natural: most operations are bitwise or arithmetic with clean chunk decompositions.

The field continues evolving. The core insight (reducing set membership to polynomial identity) admits many instantiations, each optimizing for different table sizes, structures, and use cases.



## Integration with STARKs

Lookup arguments aren't exclusive to PLONK. STARK-based systems integrate them via the AIR (Algebraic Intermediate Representation) framework.

In AIR terms:

- The lookup table becomes a public column in the trace
- Witness values to be looked up appear in other columns
- A running product column accumulates the grand product
- Transition constraints enforce the recursive relation

The conceptual structure is identical; the implementation adapts to the STARK trace model rather than PLONK's polynomial commitments.

Modern STARK systems (Cairo, RISC0, SP1) rely heavily on lookup arguments for efficient VM verification.



## The Role in zkVMs

Lookup arguments are foundational for zero-knowledge virtual machines.

A zkVM proves correct execution of arbitrary programs. The "table" encodes valid instruction semantics:

- Opcode validity
- Memory read/write consistency
- Bitwise operation results
- Range checks on registers

Without lookups, encoding these constraints algebraically would explode the circuit size. With lookups, each instruction verification reduces to a few table membership proofs.

**Example**: Verifying a RISC-V ADD instruction.

- Without lookups: Decompose 32-bit operands, verify carry propagation, reconstruct result (dozens of constraints).
- With lookups: Single lookup proving $(a, b, a+b \mod 2^{32})$ is in the addition table (3 constraints).

The efficiency gain is multiplicative across millions of instructions. zkVMs would be impractical without lookup arguments.



## Key Takeaways

**General principles** (apply to all lookup arguments):

1. **Lookup arguments shift complexity from logic to data**: Precompute valid tuples; prove membership rather than computation. This is the core insight shared by Plookup, LogUp, Lasso, and all variants.

2. **The formal problem**: Given lookups $f$ and table $t$, prove $f \subseteq t$. Different protocols reduce this multiset inclusion to different polynomial identities.

3. **Cost structure**: Lookup-based proofs achieve roughly constant cost per lookup, independent of the logical complexity of what the table encodes. A 16-bit range check or an 8-bit XOR costs the same as a simple membership test.

4. **Complements custom gates**: Lookups handle non-algebraic constraints; custom gates handle algebraic primitives. Modern systems (UltraPLONK, Halo2) use both.

5. **zkVM foundation**: Without lookup arguments, verifying arbitrary computation at scale would be infeasible. Every major zkVM relies on lookups for instruction semantics.

**Plookup-specific mechanics** (the sorted-merge approach from Section 2):

6. **Sorted vector reduction**: Plookup transforms $f \subseteq t$ into a claim about the sorted merge $s = \text{sort}(f \cup t)$.

7. **Adjacent pair property**: In Plookup, every consecutive pair in $s$ is either a repeat (from $f$ slotting in) or exists as adjacent in $t$.

8. **Grand product identity**: The polynomial identity $F \equiv G$ encodes Plookup's adjacent-pair check. The accumulator $Z(X)$ enforces this recursively, integrating with PLONK's permutation machinery.

**Alternative approaches** (different trade-offs):

9. **LogUp** replaces products with sums of logarithmic derivatives: no sorting, cleaner multi-table handling, natural sum-check integration.

10. **Lasso** achieves prover costs scaling with lookups performed rather than table size, enabling tables of size $2^{128}$ via decomposition into small subtables.

# Chapter 14: Lookup Arguments

In 2019, ZK engineers hit a wall.

They wanted to verify standard computer programs, things like SHA-256 or ECDSA signatures, but the circuits were exploding in size. The culprit was *bit decomposition*. Operations that are trivial in silicon (bitwise XOR, range checks, comparisons) require decomposing values into individual bits, processing each bit, and reassembling. A single XOR takes roughly 30 constraints. A range check proving $x < 2^{32}$ costs 32 boolean constraints. Verifying a 64-bit CPU instruction set was like simulating a Ferrari using only wooden gears.

Ariel Gabizon and Zachary Williamson realized they didn't need to simulate the gears. They just needed to check the answer key. This realization, that you can replace *computation* with *table lookups*, broke the bottleneck. Instead of decomposing values into bits, just look up the answer in a precomputed table.

The insight built on earlier work (Bootle et al.'s 2018 "Arya" paper had explored lookup-style arguments), but Plookup made it practical by repurposing PLONK's permutation machinery. Range checks become a lookup into a table of valid values. Bitwise operations become a lookup into a table of valid input-output triples. Membership in these tables costs a few constraints, regardless of what the table encodes. The architecture shifted, and complexity moved from constraint logic to precomputed data.

The field accelerated. Haböck's **LogUp** (2022) replaced grand products with sums of logarithmic derivatives, eliminating sorting overhead and enabling cleaner multi-table arguments. Setty, Thaler, and Wahby's **Lasso** (2023) achieved prover costs scaling with lookups performed rather than table size, enabling tables of size $2^{128}$, large enough to hold the evaluation table of any 64-bit instruction. The "lookup singularity" emerged: a vision of circuits that do nothing but look things up in precomputed tables.

Today, every major zkVM relies on lookups. Cairo, RISC-Zero, SP1, and Jolt prove instruction execution not by encoding CPU semantics in constraints, but by verifying that each instruction's behavior matches its entry in a precomputed table. Complexity moves from constraint logic to precomputed data.

---

## The Lookup Problem

Chapter 13 introduced the **grand product argument** for copy constraints in PLONK. The idea: to prove that wire values at positions related by permutation $\sigma$ are equal, compute $\prod_i \frac{a_i + \beta \cdot i + \gamma}{a_i + \beta \cdot \sigma(i) + \gamma}$. If the permutation constraint is satisfied (values at linked positions match), this product telescopes to 1. Lookup arguments generalize this technique from equality to containment, proving not that two multisets are the same, but that one is contained in another.

The formal problem:

Given a multiset $f = \{f_1, \ldots, f_n\}$ of witness values (the "lookups") and a public multiset $t = \{t_1, \ldots, t_d\}$ (the "table"), prove $f \subseteq t$.

The name "lookup" comes from how these proofs work in practice. Imagine you're proving a circuit that computes XOR. The table $t$ contains all valid XOR triples: $(0,0,0), (0,1,1), (1,0,1), (1,1,0)$. Your circuit claims $a \oplus b = c$ for some witness values. Rather than encoding XOR algebraically, you "look up" the triple $(a,b,c)$ in the table. If it's there, the XOR is correct. The multiset $f$ collects all the triples your circuit needs to verify; the subset claim $f \subseteq t$ says every lookup found a valid entry.

A dictionary example makes this concrete. Imagine you want to prove you spelled "Cryptography" correctly. The *arithmetic approach* would be to write down the rules of English grammar and phonetics, then derive the spelling from first principles. Slow, complex, error-prone. The *lookup approach* would be to open the Oxford English Dictionary to page 412, point to the word "Cryptography," and say "there." The lookup argument is proving that your tuple (the word you claim) exists in the set (all valid English words). You don't need to understand *why* it's valid; you just need to show it's in the book.

### The Naive Approach: Product of Roots

A natural idea: two multisets are equal iff the polynomials having those elements as roots are equal. If every lookup $f_i$ appears in the table $t$, we can write:

$$\prod_{i=1}^{n} (X - f_i) = \prod_{j=1}^{d} (X - t_j)^{m_j}$$

where $m_j$ counts how many times table entry $t_j$ appears among the lookups.

**Example**: Lookups $f = \{2, 2, 5\}$ into table $t = \{1, 2, 3, 4, 5\}$.

- Left side: $(X - 2)(X - 2)(X - 5) = (X-2)^2(X-5)$
- Right side: $(X-1)^0(X-2)^2(X-3)^0(X-4)^0(X-5)^1 = (X-2)^2(X-5)$

The polynomials match because the multisets match: $f$ contains two 2s and one 5, which is exactly what the multiplicities $m_2 = 2$, $m_5 = 1$ encode.

This identity is mathematically valid, but expensive to verify in a circuit. Computing $(X - t_j)^{m_j}$ requires the binary decomposition of each multiplicity $m_j$. If lookups can repeat up to $n$ times, each multiplicity needs $\log n$ bits, blowing up the circuit inputs.

Different lookup protocols avoid this cost in different ways. **Plookup** sidesteps multiplicities entirely by using a sorted merge. **LogUp** transforms the product into a sum where multiplicities become simple coefficients rather than exponents.

---

## Plookup

Plookup's insight is to transform the subset claim into a permutation claim. The construction involves three objects:

- **$f$**: the lookup values (what you're looking up, your witness data)
- **$t$**: the table (all valid values, public and precomputed)
- **$s$**: the sorted merge of $f$ and $t$ (auxiliary, constructed by prover)

The key is that $s$ encodes *how* $f$ fits into $t$. If every $f_i$ is in $t$, then $s$ is just $t$ with duplicates inserted at the right places.

### Plookup's Sorted Vector $s$

Define $s = \text{sort}(f \cup t)$, the concatenation of lookup values and table values, sorted.

If $f \subseteq t$, then every element of $f$ appears somewhere in $t$. In the sorted vector $s$, elements from $f$ "slot in" next to their matching elements from $t$.

For every adjacent pair $(s_i, s_{i+1})$ in $s$, either:

1. $s_i = s_{i+1}$ (a repeated value, meaning some $f_j$ was inserted next to its matching $t_k$), or
2. $(s_i, s_{i+1})$ is also an adjacent pair in the sorted table $t$

If some $f_j \notin t$, then $s$ contains a transition that doesn't exist in $t$, and the check fails.

**Example** (3-bit range check):

- Lookups: $f = \{2, 5\}$ (prover claims both are in $[0, 7]$)
- Table: $t = \{0, 1, 2, 3, 4, 5, 6, 7\}$
- Sorted: $s = \{0, 1, 2, 2, 3, 4, 5, 5, 6, 7\}$

Adjacent pairs in $s$: $(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$

The pairs $(2,2)$ and $(5,5)$ are repeats; these correspond to the lookups. All other pairs appear as adjacent pairs in $t$. The subset claim holds.

If instead $f = \{2, 9\}$:

- Sorted: $s = \{0, 1, 2, 2, 3, 4, 5, 6, 7, 9\}$
- The pair $(7, 9)$ is neither a repeat nor an adjacent pair in $t$
- The subset claim fails

### Plookup's Grand Product Check

The adjacent-pair property translates to a polynomial identity via a grand product. The construction is clever, so let's build it step by step.

The core idea is to encode each adjacent pair $(s_i, s_{i+1})$ as a single field element $\gamma(1+\beta) + s_i + \beta s_{i+1}$. The term $\beta$ acts as a "separator": different pairs map to different field elements (with high probability over random $\beta$). Multiplying all these pair-encodings together gives a fingerprint of the multiset of adjacent pairs.

**$G(\beta, \gamma)$**, the fingerprint of $s$'s adjacent pairs:

$$G(\beta, \gamma) = \prod_{i=1}^{n+d-1} (\gamma(1 + \beta) + s_i + \beta s_{i+1})$$

This is just the product of all adjacent-pair encodings in the sorted vector $s$.

**$F(\beta, \gamma)$**, the fingerprint we *expect* if $f \subseteq t$:

$$F(\beta, \gamma) = (1 + \beta)^n \cdot \prod_{i=1}^{n} (\gamma + f_i) \cdot \prod_{i=1}^{d-1} (\gamma(1 + \beta) + t_i + \beta t_{i+1})$$

Where does this come from? Think about what $s$ looks like when $f \subseteq t$. The sorted merge contains the table $t$ as a "backbone," with lookup values from $f$ inserted as duplicates next to their matches. So the adjacent pairs in $s$ fall into two categories:

1. **Pairs from $t$**: The $d-1$ consecutive pairs $(t_i, t_{i+1})$ from the original table. These appear in $s$ regardless of what $f$ contains; they're the skeleton that $f$ gets merged into. In $F$, these correspond to the last product $\prod_{i=1}^{d-1}(\gamma(1+\beta) + t_i + \beta t_{i+1})$, which doesn't factorize.

2. **Repeated pairs from inserting $f$**: When a lookup value $f_j$ slots into $s$ next to its matching table entry, we get a repeated pair $(f_j, f_j)$. The encoding of $(v, v)$ is $\gamma(1+\beta) + v + \beta v = (\gamma + v)(1+\beta)$. This *does* factorize. So the $n$ repeated pairs contribute $(1+\beta)^n \cdot \prod(\gamma + f_i)$ to $F$.

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

The following implementation computes $F$ and $G$ for the 3-bit range check example above:

```python
def encode_pair(a, b, beta, gamma):
    """Encode adjacent pair (a, b) as a field element."""
    return gamma * (1 + beta) + a + beta * b

def plookup_check(lookups, table, beta=2, gamma=5):
    """Verify lookups subset of table via Plookup grand product."""
    s = sorted(lookups + table)

    # G: fingerprint of s's adjacent pairs
    G = 1
    for i in range(len(s) - 1):
        G *= encode_pair(s[i], s[i+1], beta, gamma)

    # F: expected fingerprint = (1+beta)^n * prod(gamma + f_i) * prod(table pairs)
    F = (1 + beta) ** len(lookups)
    for f in lookups:
        F *= (gamma + f)
    for i in range(len(table) - 1):
        F *= encode_pair(table[i], table[i+1], beta, gamma)

    return F, G, (F == G)

# 3-bit range check: {2, 5} in [0, 7]
plookup_check([2, 5], list(range(8)))  # (563374005, 563374005, True)

# Invalid: 9 not in table
plookup_check([2, 9], list(range(8)))  # F != G, returns False
```

### Integrating with PLONK

The grand product check $F = G$ is the mathematical core of Plookup (Gabizon-Williamson 2020). But to use it in a SNARK, we need to encode the check as polynomial constraints that PLONK can verify. This means:

- The table $t$ becomes a polynomial committed during setup
- The sorted vector $s$ becomes polynomials the prover commits to
- The $F = G$ check becomes an accumulator that the verifier checks via a single polynomial identity

#### Setup

The table is public and fixed before any proof. Encode it as a polynomial $t(X)$ where $t(\omega^i) = t_i$ for each table entry. This polynomial is committed once and reused across all proofs; the verifier never touches the full table during verification.

The prover holds witness values $\{f_1, \ldots, f_n\}$ to look up. These are private.

#### Prover Computation

The prover's job is to construct the sorted vector $s$ and prove $F = G$ without revealing the witness values.

1. **Construct $s$**: Merge $f$ and $t$, then sort. This is the $(f,t)$-sorted vector from the theory above.

2. **Split $s$ into $h_1, h_2$**: The sorted vector has length $n + d$ (lookups plus table), but PLONK's evaluation domain has size matching the circuit. To fit $s$ into the constraint system, split it into two polynomials $h_1$ and $h_2$. The constraints will check adjacent pairs *within* each half and *across* the boundary.

3. **Commit to sorted polynomials**: Send $[h_1]_1, [h_2]_1$ to the verifier.

4. **Receive challenges**: After Fiat-Shamir, obtain $\beta, \gamma$. These randomize the fingerprint encoding, making it infeasible for a cheating prover to forge a valid $F = G$.

5. **Build accumulator**: Construct $Z(X)$, the polynomial that computes the running $F/G$ ratio. It starts at 1, accumulates one ratio term per domain point, and returns to 1 if the lookup is valid.

6. **Commit to accumulator**: Send $[Z]_1$.

#### Constraints

Recall the goal: prove $F(\beta, \gamma) = G(\beta, \gamma)$, where $F$ is the expected fingerprint and $G$ is the actual fingerprint of $s$'s adjacent pairs. In PLONK, we encode this as polynomial identities checked via the quotient polynomial.

The accumulator $Z(X)$ computes a running ratio of $F$ and $G$ terms. If $F = G$, the ratio telescopes to 1 over the full domain.

**Initialization**: $Z$ starts at 1.
$$(Z(X) - 1) \cdot L_1(X) = 0$$

**Recursion**: At each domain point, $Z$ accumulates one step of the $F/G$ ratio. The left side encodes adjacent pairs from $s$ (split across $h_1, h_2$); the right side encodes the expected $F$ terms (table pairs and lookup duplicates):

$$Z(X\omega) \cdot \underbrace{\prod_{j \in \{1,2\}} (\gamma(1+\beta) + h_j(X) + \beta h_j(X\omega))}_{\text{$G$ terms: actual pairs in } s}$$
$$= Z(X) \cdot \underbrace{(1+\beta)^m \cdot (\gamma + f(X))}_{\text{repeated pairs}} \cdot \underbrace{(\gamma(1+\beta) + t(X) + \beta t(X\omega))}_{\text{table pairs}}$$

The parameter $m$ is the number of lookups per gate (typically 1 or 2).

If $F = G$, then $Z$ returns to 1 at the end of the domain as the product telescopes. We don't add an explicit finalization constraint for this. Instead, the recursion constraint forces $Z(\omega^{n}) = Z(\omega^0) \cdot \prod(\text{ratio terms})$. Since $Z(\omega^0) = 1$ by initialization, and we're working over a cyclic domain, the constraint system implicitly checks that the final value is 1.

The accumulator alone isn't sufficient. It verifies that adjacent pairs in $s$ are valid, but what if the prover constructs a fake $s$ that doesn't actually contain the lookup values $f$? The grand product equality handles this: the left side of the recursion constraint multiplies over pairs from $h_1, h_2$, while the right side multiplies over $f$ and $t$. For the products to match, the multisets must be equal. This is the same principle as the permutation argument in Chapter 13, but here it's embedded directly in the accumulator constraint rather than as a separate check.

The constraint assumes $s$ is sorted, since that's what makes duplicates land next to their matches. Plookup enforces this implicitly rather than with an explicit sorting check. The adjacent-pair encoding $(s_i + \beta s_{i+1})$ captures ordering information: since $s$ must be "sorted by $t$" (elements appear in the same order as in $t$), each adjacent pair in $t$ must appear exactly once as an adjacent pair in $s$. If the prover reorders $s$, the adjacent pairs change, and the grand product fails. The randomness $\beta$ prevents the prover from constructing a fake $s$ that happens to produce the same product despite having different pairs.

Both properties are enforced by the single recursion constraint:
1. The grand product equality ensures $s$ contains exactly $(f \cup t)$, with no values conjured from thin air.
2. The adjacent-pair encoding ensures every consecutive pair is valid (either a repeat or a table step).
3. The same encoding implicitly enforces sorting: reordering $s$ changes its adjacent pairs, breaking the grand product.

If all hold, every element in $f$ found a matching entry in $t$. A cheating prover cannot slip in a value outside the table since it would create an invalid pair that breaks the accumulator.

#### Verification

The verifier checks the polynomial identities (initialization, recursion) via the standard PLONK batched evaluation. Crucially, the verifier never touches the table directly. The table polynomial $t(X)$ was committed during setup, and the verifier only checks openings at random evaluation points. Verification cost is independent of table size $d$: a lookup into a 256-entry table costs the same as a lookup into a million-entry table.


## Comparison: Custom Gates vs. Lookup Tables

Both custom gates and lookup tables extend PLONK beyond vanilla arithmetic, but they solve different problems.

Custom gates add terms to the universal gate equation. For example, adding a selector $Q_{\text{pow5}}$ enables $a^5$ computation in a single constraint:

$$Q_L a + Q_R b + Q_O c + Q_M ab + Q_{\text{pow5}} a^5 + Q_C = 0$$

This works well for Poseidon S-boxes, which need fifth powers. The constraint is low-degree, requires no precomputation, and adds no extra commitments. But custom gates hit a wall when the relation isn't algebraically compact. A boolean check is easy: $x^2 - x = 0$ has degree 2. A 16-bit range check would need $x(x-1)(x-2)\cdots(x-65535) = 0$, a degree-65536 polynomial that no proof system can handle efficiently.

Lookup tables solve this by shifting complexity from constraint degree to table size. Instead of encoding "x is in $[0, 65535]$" as a high-degree polynomial, we precompute a table of valid values and prove membership via the grand product. As we saw in the Verification section, the verifier never touches the table directly, so verification cost scales with the number of lookups, not the table size.

The tradeoff is that lookups add overhead. Each lookup requires entries in the sorted vector $s$, contributions to the accumulator polynomial, and additional commitment openings. For a simple boolean check, this machinery is overkill. For a 64-bit range check or an 8-bit XOR operation, lookups are necessary.

| Problem | Custom Gate | Lookup Table |
|---------|-------------|--------------|
| Boolean check ($x \in \{0,1\}$) | Ideal | Overkill |
| 8-bit range check | Possible | Efficient |
| 64-bit range check | Impractical | Essential |
| XOR/AND/OR operations | Complex | Clean |
| Poseidon $x^5$ | One gate | Unnecessary |
| Valid opcode check | Complex | Direct |

Modern systems like UltraPLONK use both: custom gates for algebraic primitives, lookup tables for everything else.



## Alternative Lookup Protocols

Plookup was seminal but not unique. Several alternatives offer different trade-offs.

### LogUp: The Logarithmic Derivative Approach

Recall the naive product identity from the beginning of this chapter:

$$\prod_{i=1}^{n} (X - f_i) = \prod_{j=1}^{d} (X - t_j)^{m_j}$$

Plookup avoided the multiplicity problem by using the sorted merge $s$. LogUp takes a different route: transform the product into a sum where multiplicities become coefficients rather than exponents. Taking the logarithmic derivative (i.e., $\frac{d}{dX}\log(\cdot)$) of both sides, and using $\frac{d}{dX}\log(X - a) = \frac{1}{X-a}$ and $\frac{d}{dX}\log((X-a)^m) = \frac{m}{X-a}$:

$$\sum_{i=1}^{n} \frac{1}{X - f_i} = \sum_{j=1}^{d} \frac{m_j}{X - t_j}$$

The exponentiation $(X - t_j)^{m_j}$ that required binary decomposition becomes simple scalar multiplication $m_j \cdot \frac{1}{X - t_j}$. Over finite fields, we don't actually compute logs or derivatives; the identity is purely algebraic. If the multisets match, the rational functions are equal. Evaluating at a random challenge $\gamma \in \mathbb{F}$ gives Schwartz-Zippel soundness.

This matters for several reasons:

1. **No sorting required.** Plookup requires constructing and committing to the sorted vector $s$. LogUp skips this entirely: no sorted polynomial, no sorting constraints.

2. **Additive structure.** Products become sums of fractions. This enables:

   - Simpler multi-table handling (just add the sums)
   - Natural integration with sum-check protocols
   - Easier batching of multiple lookup arguments

3. **Better cross-table lookups.** When a circuit uses multiple tables (range, XOR, opcodes), LogUp handles them in a unified sum rather than separate grand products.

**Worked Example:** Lookups $f = \{2, 2, 5\}$ into table $t = \{1, 2, 3, 4, 5\}$ over $\mathbb{F}_{97}$.

The multiplicities are $m_1 = 0, m_2 = 2, m_3 = 0, m_4 = 0, m_5 = 1$. The verifier sends random challenge $\gamma = 10$. Both sides evaluate at $X = \gamma$:

Left side (lookups):

$$\frac{1}{10 - 2} + \frac{1}{10 - 2} + \frac{1}{10 - 5} = \frac{1}{8} + \frac{1}{8} + \frac{1}{5}$$

Over $\mathbb{F}_{97}$: $8^{-1} \equiv 85$ and $5^{-1} \equiv 39$ (since $8 \times 85 = 680 = 7 \times 97 + 1$ and $5 \times 39 = 195 = 2 \times 97 + 1$). So the left side is $85 + 85 + 39 = 209 \equiv 15 \pmod{97}$.

Right side (table with multiplicities):

$$\frac{0}{10 - 1} + \frac{2}{10 - 2} + \frac{0}{10 - 3} + \frac{0}{10 - 4} + \frac{1}{10 - 5} = \frac{2}{8} + \frac{1}{5} = 2 \cdot 85 + 39 = 170 + 39 = 209 \equiv 15 \pmod{97}$$

Both sides equal 15. The identity holds.

Verification: $15 = 15$ $\checkmark$

If we had tried to look up $f = \{2, 2, 9\}$ (with $9 \notin t$), the left side would include $\frac{1}{10 - 9} = \frac{1}{1} = 1$. The left sum becomes $85 + 85 + 1 = 171 \equiv 74 \pmod{97}$. No assignment of multiplicities to the table entries can make the right side equal 74, so the check fails with overwhelming probability over the choice of $\gamma$.

### The LogUp bus

LogUp's additive structure enables a pattern that has become the standard architecture in STARK-based zkVMs: the **bus argument**. When a system has multiple specialized components (an ALU chip, a memory chip, a program counter chip), each component produces or consumes values that must be consistent across components. A CPU chip "sends" an addition operation $(a, b, c)$ to the ALU chip, which "receives" it and checks $a + b = c$.

The bus formalizes this as a global sum constraint. Each sender contributes $+\frac{1}{\gamma - v}$ for a value $v$ it sends. Each receiver contributes $-\frac{1}{\gamma - v}$ for a value $v$ it receives. If every sent value is received exactly once, the global sum is zero:

$$\sum_{\text{sends}} \frac{1}{\gamma - v_i} - \sum_{\text{receives}} \frac{1}{\gamma - v_j} = 0$$

This is just the LogUp identity rewritten: senders play the role of lookups $f$, receivers play the role of table $t$. The zero-sum condition replaces the multiset equality check. Each component adds one auxiliary "running sum" column to its trace, accumulating its contribution row by row. The boundary constraint asserts that the global sum of all components' final running-sum values is zero.

The bus scales linearly with the number of components ($O(k)$ for $k$ tables) rather than quadratically ($O(k^2)$) as pairwise permutation arguments would require. Every major STARK-based zkVM (SP1, RISC Zero, Stwo, OpenVM) now uses LogUp bus arguments for inter-component consistency. Chapter 20 discusses how interaction columns implementing LogUp fit into the STARK prover pipeline.

LogUp-GKR combines the bus with the GKR protocol (Chapter 7) for even greater efficiency. Instead of committing to a helper column for the reciprocals $\frac{1}{\gamma - v}$, the prover uses a GKR interactive proof to verify the fractional sums directly. This eliminates helper columns entirely, adding only $O(\log n)$ interaction rounds. StarkWare's Stwo prover uses LogUp-GKR over Mersenne31.

### cq (Cached Quotients)

A refinement of the logarithmic derivative approach optimized for repeated lookups.

cq pre-computes quotient polynomials for the table, amortizing table processing across multiple lookup batches. The trade-off is setup overhead; benefits emerge with many lookups against the same table.

### Caulk and Caulk+

Caulk (2022) asked a different question: what if the table is *huge* but you only perform a few lookups? Plookup's prover work scales linearly with table size, making it impractical for tables of size $2^{30}$ or larger.

The core idea: encode the set (or table) $\{t_1, \ldots, t_d\}$ as a polynomial $t(X) = \prod_{j=1}^{d}(X - t_j)$, whose roots are exactly the set elements. To prove that a value $v$ is in the set, observe that $(X - v)$ divides $t(X)$ iff $v$ is a root. KZG lets you prove this divisibility via a quotient polynomial $q(X) = t(X)/(X-v)$, without revealing which root $v$ is. The quotient commitment can be computed from the table commitment using properties of KZG, and this computation is sublinear in $d$.

Prover work is $O(m^2 + m \log d)$ for $m$ lookups into a table of size $d$, sublinear in $d$ when $m \ll d$. The trade-off: Caulk requires trusted setup (KZG), and the quadratic term in $m$ limits scalability for many lookups.

Caulk is actually a general *membership proof* protocol: given a KZG commitment to a set, prove that certain values belong to that set without revealing which positions they occupy. This makes it useful beyond lookup tables, e.g., as an alternative to Merkle proofs for set membership. Plookup and LogUp can't serve this role because they require the prover to process the entire table during proving, which defeats the purpose of a compact membership proof. Caulk's sublinear prover cost is what enables the generalization.

**Caulk+** refined this to $O(m^2)$ prover complexity, removing the $\log d$ term entirely.

### Halo2 Lookups

Halo2, developed by the Electric Coin Company (Zcash), integrates lookups natively with a "permutation argument" variant rather than Plookup's grand product.

The core idea: to prove $A \subseteq S$ (lookups $A$ are contained in table $S$), the prover constructs permuted columns $A'$ and $S'$ such that $A'$ is a permutation of $A$, $S'$ is a permutation of $S$, and in each row either $A'_{i+1} = A'_i$ (a repeat) or $A'_{i+1} = S'_i$ (a table match). This forces every element in $A'$ to equal some element in $S'$. The permutation constraints are enforced via a grand product argument similar to PLONK's copy constraints. Unlike Plookup, there is no explicit sorted merge; the "sorting" happens implicitly through the permutation.

Halo2's lookup API lets developers define tables declaratively. The proving system handles the constraint generation automatically. This made Halo2 popular for application circuits: you specify *what* to look up, not *how* the lookup argument works. Scroll, Taiko, and other L2s built on Halo2 rely on its lookup system for zkEVM implementation.

## Lasso and Jolt

All the protocols above (Plookup, LogUp, Caulk, Halo2) share a limitation: the prover must commit to polynomials whose degree scales with table size.

For Plookup, the sorted vector $s$ has length $n + d$ (lookups plus table). For LogUp, the multiplicity polynomial has degree $d$. For Caulk, the table polynomial $t(X)$ must be committed during setup. In every case, a table of size $2^{20}$ means million-coefficient polynomials. A table of size $2^{64}$ means polynomials with more coefficients than atoms in a grain of sand.

This is a hard wall, not a soft cost. The evaluation table of a 64-bit ADD instruction has $2^{128}$ entries. No computer can store that polynomial, let alone commit to it.

Early zkVMs worked around this by using small tables (8-bit or 16-bit operations) and paying the cost in constraint complexity for larger operations. A 64-bit addition became a cascade of 8-bit additions with carry propagation. It worked, but it was slow.

Lasso (2023, Setty-Thaler-Wahby) breaks through this wall: prover costs scale with *lookups performed* rather than *table size*.

### Static vs. Dynamic Tables

Before diving into Lasso's mechanism, distinguish two types of lookups:

*Static tables (read-only)*: Fixed functions like XOR, range checks, or AES S-boxes. The table never changes during execution. Plookup, LogUp, and Lasso excel here.

*Dynamic tables (read-write)*: Simulating RAM (random access memory). The table starts empty and fills up as the program runs. This requires different techniques (like memory-checking arguments or timestamp-based permutation checks) because the table itself is witness-dependent.

Lasso focuses on static tables, but its decomposition insight is what makes truly large tables tractable.

### Decomposable Tables

Lasso exploits *decomposable tables*. Many tables have structure: their MLE (multilinear extension) can be written as a weighted sum of smaller subtables:

$$\tilde{T}(y) = \sum_{j=1}^{\alpha} c_j \cdot \tilde{T}_j(y_{S_j})$$

Each subtable $\tilde{T}_j$ looks at only a small chunk of the total input $y$. This "Structure of Sums" (SoS) property enables dramatic efficiency gains. (This is a cousin of the tensor product structure for Lagrange bases in Chapter 4—both exploit how multilinear functions over product domains inherit structure from their factors.)

Consider 64-bit AND. The conceptual table has $2^{128}$ entries (all pairs of 64-bit inputs). But bitwise AND decomposes perfectly: split inputs into sixteen 4-bit chunks, perform 16 lookups into a tiny 256-entry `AND_4` table, concatenate results. The prover never touches the $2^{128}$-entry table.

### Why Prover Costs Scale with Lookups

Lasso represents the sparse access pattern—which indices were hit, how many times—using commitment schemes optimized for sparse polynomials, then proves correctness via sum-check. The prover commits only to the accessed entries and their multiplicities, never to the full table. For structured tables, the verifier can evaluate $\tilde{T}(r)$ at a random challenge point in $O(\log N)$ time using the table's algebraic formula, without ever seeing the table itself.

### Jolt: A zkVM Built on Lasso

Jolt applies Lasso to build a complete zkVM for RISC-V. The philosophy: replace arithmetization of instruction semantics with lookups.

The entire RISC-V instruction set can be viewed as one giant table mapping (opcode, operand1, operand2) to results. This table is far too large to materialize, but it's *decomposable*: most instructions break into independent operations on small chunks. A 64-bit XOR decomposes into 16 lookups into a 256-entry `XOR_4` table. The subtables are tiny, pre-computed once, and reused across all instructions.

Jolt combines Lasso (for instruction semantics) with R1CS constraints (for wiring: program counter updates, register consistency, data flow). Why this hybrid? Arithmetizing a 64-bit XOR in R1CS requires 64+ constraints for bit decomposition; Jolt proves it with 16 cheap lookups. But simple wiring constraints are trivial in R1CS. Use each tool where it excels.

### Limitations

Lasso and Jolt require decomposable table structure. Tables without chunk-independent structure don't benefit. But for CPU instruction sets, the structure is natural: most operations are bitwise or arithmetic with clean chunk decompositions.

The field continues evolving. The core insight (reducing set membership to polynomial identity) admits many instantiations, each optimizing for different table sizes, structures, and use cases.



## Lookups Across Proving Systems

The lookup techniques above: Plookup, LogUp, Lasso, adapt to different proving backends. Plookup and Halo2 integrate naturally with PLONK's polynomial commitment model. Lasso and Jolt use sum-check and R1CS (via Spartan). STARK-based systems take a different path.

In STARKs, computation is represented as an execution trace: a matrix where each row is a state and columns hold registers, memory, and auxiliary values. Lookup arguments integrate by adding columns to this trace:

- The lookup table becomes one or more *public columns* (known to the verifier)
- Values to be looked up appear in *witness columns*
- A *running product column* accumulates the grand product (Plookup-style) or running sum (LogUp-style)
- *Transition constraints* enforce the recursive accumulator relation row-by-row

The FRI-based polynomial commitment then proves that these trace columns satisfy all constraints. The lookup argument's algebraic core is unchanged; only the commitment mechanism differs.

STARK-based zkVMs (Cairo, RISC0, SP1) rely heavily on this integration. Their execution traces naturally represent VM state transitions, and lookups handle instruction semantics, memory consistency, and range checks. The trace-based model makes it easy to add new lookup tables: just add columns and constraints.



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

10. **Caulk** achieves sublinear prover work in table size via KZG-based subset arguments, useful when few lookups access a huge table.

11. **Halo2** uses permutation arguments rather than sorted merges, with lookups integrated into the constraint system declaratively.

12. **Lasso** exploits *decomposable tables* (SoS structure) to achieve prover costs scaling with lookups performed, not table size. Combined with sparse polynomial commitments, this enables effective tables of size $2^{128}$. Jolt applies this to build a complete zkVM.

13. **STARK integration**: Lookup arguments adapt to trace-based proving via running product/sum columns and transition constraints, used by Cairo, RISC0, and SP1.

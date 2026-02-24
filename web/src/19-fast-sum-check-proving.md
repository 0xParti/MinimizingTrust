# Chapter 19: Fast Sum-Check Proving

> *Most chapters in this book can be read with pencil and paper. This one assumes you've already internalized the sum-check protocol (Chapter 3) and multilinear extensions (Chapter 4), not as definitions to look up, but as tools you can wield. If those still feel foreign, consider this chapter a preview of where the road leads, and return when the foundations feel solid.*

In 1992, the sum-check protocol solved the problem of succinct verification. Lund, Fortnow, Karloff, and Nisan had achieved something that sounds impossible: verifying a sum over $2^n$ terms while the verifier performs only $O(n)$ work. Exponential compression in verification time. The foundation of succinct proofs.

Then, for three decades, almost nobody used it.

Why? Because everyone thought it was too slow. A naive reading of the protocol suggests the prover performs $O(n \cdot 2^n)$ operations, worse than just computing the sum directly. For $n = 30$, that's over 30 billion operations per proof. Researchers chased other paths: PCPs, pairing-based SNARKs, trusted setups. Groth16 and PLONK took univariate polynomials, quotient-based constraints, FFT-driven arithmetic. Sum-check remained a theoretical marvel, admired in complexity circles but dismissed as impractical.

They were wrong.

It turned out that a simple algorithmic trick, available since the 90s but overlooked, made the prover linear time. With the right algorithms, sum-check proving runs in $O(2^n)$ time, linear in the number of terms. For sparse sums where only $T \ll 2^n$ terms are non-zero, prover time drops to $O(T)$. These are not approximations or heuristics; they're exact algorithms exploiting algebraic structure that was always present.

When this was rediscovered and popularized by Justin Thaler in the late 2010s, it triggered a revolution. The field realized it had been sitting on the "Holy Grail" of proof systems for three decades without noticing. This chapter explains the trick that woke up the giant, and then shows how it enables Spartan, the SNARK that proved sum-check alone suffices for practical zero-knowledge proofs. No univariate encodings. No pairing-based trusted setup. Just multilinear polynomials, sum-check, and a commitment scheme.

### Why This Matters: The zkVM Motivation

The techniques in this chapter find their most compelling application in *zkVMs* (zero-knowledge virtual machines). A zkVM proves correct execution of arbitrary programs without requiring a new circuit for each program.

The idea is simple in principle. Take an instruction set architecture like RISC-V. Write a SNARK that proves: "given this program and this input, the CPU executed correctly and produced this output." The circuit encodes the CPU's transition function: fetch instruction, decode, execute, update registers and memory, repeat. Any program compiles to RISC-V; the same circuit proves them all.

The scale is staggering. A modest program might execute millions of CPU cycles. Each cycle involves dozens of constraints: register reads, ALU operations, memory accesses, program counter updates. A million cycles at 50 constraints each yields 50 million constraints. And that's a *small* program.

At this scale, constant factors matter. The difference between $O(n \log n)$ and $O(n)$ proving time is the difference between minutes and seconds. The difference between $5n$ and $2n$ operations is the difference between a practical system and an impractical one.

This is why fast sum-check proving isn't an academic curiosity. It's the foundation that makes zkVMs possible.

> **Remark (Sum-checks compose into graphs).** A zkVM doesn't run one sum-check; it runs dozens. Each sum-check ends with an evaluation claim ("prove $\tilde{f}(r) = v$"). If $\tilde{f}$ is committed, open it. If $\tilde{f}$ is *virtual*, defined in terms of other polynomials, another sum-check proves that evaluation, producing its own claims. The structure is a directed acyclic graph: sum-checks as nodes, claims as edges. The prover traverses this graph, and the graph's structure determines proof efficiency.
>
> Two dimensions matter. *Depth* (longest path through the graph) determines the minimum number of sequential *stages*, meaning sum-checks that depend on each other's outputs. *Width* (sum-checks at the same depth) allows *batching*, combining independent sum-checks via random linear combination into a single sum-check. A well-designed protocol minimizes depth and maximizes batching at each stage. We'll develop this perspective fully in Chapter 20; for now, just note that fast sum-check proving matters not just once, but dozens of times per proof.

## The Prover's Apparent Problem

Let's examine the naive prover cost more carefully.

The sum-check protocol proves:
$$H = \sum_{b \in \{0,1\}^n} g(b)$$

In round $i$, the prover sends a univariate polynomial capturing the partial sum with $X_i$ left as a formal variable:

$$s_i(X_i) = \sum_{(b_{i+1}, \ldots, b_n) \in \{0,1\}^{n-i}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

If $g$ has individual degree $d$ in each variable, then $s_i$ has degree $d$ in $X_i$. The prover specifies $s_i$ by sending $d+1$ evaluations.

**The apparent cost:** Computing $s_i(t)$ for a single value $t$ requires summing over $2^{n-i}$ terms. Computing $s_i(0), s_i(1), \ldots, s_i(d)$ requires $(d+1) \cdot 2^{n-i}$ evaluations of $g$.

Across all $n$ rounds:
$$\sum_{i=1}^n (d+1) \cdot 2^{n-i} = (d+1)(2^{n-1} + 2^{n-2} + \cdots + 1) = (d+1)(2^n - 1)$$

This is $O(d \cdot 2^n)$, linear in the table size when $d$ is constant. But the naive approach computes this by brute force, re-evaluating $g$ at the same points multiple times across rounds.

The insight is that we don't need to recompute from scratch each round. The work halves with each round, and we can reuse intermediate results.

## The Halving Trick

Consider the most important case: $g(x) = \tilde{a}(x) \cdot \tilde{b}(x)$ where $\tilde{a}$ and $\tilde{b}$ are multilinear polynomials (the multilinear extensions of some tables $a$ and $b$).

Since multilinear polynomials have degree at most 1 in each variable, their product has degree at most 2. So $d = 2$, and each round the prover sends three field elements: $s_i(0), s_i(1), s_i(2)$.

### The Key Algebraic Fact

For any multilinear polynomial $\tilde{a}(x_1, x_2, \ldots, x_n)$ and field element $r_1$:

$$\tilde{a}(r_1, x_2, \ldots, x_n) = (1 - r_1) \cdot \tilde{a}(0, x_2, \ldots, x_n) + r_1 \cdot \tilde{a}(1, x_2, \ldots, x_n)$$

This follows from the definition of multilinear: linear in each variable separately. The function $\tilde{a}(X_1, x_2, \ldots)$ is linear in $X_1$, so it's determined by its values at $X_1 = 0$ and $X_1 = 1$. (This is exactly the streaming evaluation formula from Chapter 4, where we used it to evaluate MLEs efficiently.)

This fact enables **folding**: after receiving challenge $r_1$, we can compute the restricted polynomial $\tilde{a}(r_1, x_2, \ldots, x_n)$ from the unrestricted polynomial $\tilde{a}$ in linear time.

### The Algorithm

Recall from Chapter 3: in round $i$ of sum-check, the prover sends a univariate polynomial $s_i(X_i)$ representing the partial sum with $X_i$ left as a formal variable. Since $g = \tilde{a} \cdot \tilde{b}$ has degree 2 in each variable, $s_i$ is degree-2, requiring three evaluations $s_i(0), s_i(1), s_i(2)$ to specify.

**Initialization.** Store all $2^n$ evaluations $\tilde{a}(b)$ and $\tilde{b}(b)$ for $b \in \{0,1\}^n$ in arrays $A[b]$ and $B[b]$.

**Round 1.** Compute three evaluations of $s_1(X_1) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} \tilde{a}(X_1, b_2, \ldots, b_n) \cdot \tilde{b}(X_1, b_2, \ldots, b_n)$:

- $s_1(0) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(0, b_2, \ldots, b_n)] \cdot B[(0, b_2, \ldots, b_n)]$
- $s_1(1) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(1, b_2, \ldots, b_n)] \cdot B[(1, b_2, \ldots, b_n)]$
- $s_1(2) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(2, b_2, \ldots, b_n)] \cdot B[(2, b_2, \ldots, b_n)]$

For $s_1(0)$ and $s_1(1)$, we read values directly from the stored arrays (these are Boolean points). For $s_1(2)$, the point $X_1 = 2$ isn't in our table, but since $\tilde{a}$ is linear in $X_1$, we interpolate. A line through $(0, y_0)$ and $(1, y_1)$ has the form $y_0 + (y_1 - y_0) \cdot X$, which at $X = 2$ gives $y_0 + 2(y_1 - y_0) = -y_0 + 2y_1$. So $A[(2, b_2, \ldots, b_n)] = -A[(0, b_2, \ldots, b_n)] + 2 \cdot A[(1, b_2, \ldots, b_n)]$. Similarly for $B$.

Send $(s_1(0), s_1(1), s_1(2))$. This takes $O(2^{n-1})$ operations.

**Fold after round 1.** Receive challenge $r_1$. Create a new array $A'$ of size $2^{n-1}$, indexed by $(b_2, \ldots, b_n) \in \{0,1\}^{n-1}$:
$$A'[(b_2, \ldots, b_n)] = (1 - r_1) \cdot A[(0, b_2, \ldots, b_n)] + r_1 \cdot A[(1, b_2, \ldots, b_n)] = \tilde{a}(r_1, b_2, \ldots, b_n)$$

Discard the old array and rename $A' \to A$. The array now stores the restricted polynomial $\tilde{a}(r_1, x_2, \ldots, x_n)$ evaluated on the $(n-1)$-dimensional hypercube. Similarly fold $B$.

**Subsequent rounds.** Repeat: compute $s_i$ from the current arrays, send it, fold the arrays using $r_i$.

**Complexity.** Round $i$ operates on arrays of size $2^{n-i+1}$, then folds to size $2^{n-i}$:
$$O(2^{n-1}) + O(2^{n-2}) + \cdots + O(1) = O(2^n)$$

The total prover work is $O(2^n)$, down from the naive $O(n \cdot 2^n)$ analysis at the start of this chapter. This is optimal: any algorithm proving a claim about a sum over $2^n$ terms must read all $2^n$ inputs at least once, so $\Omega(2^n)$ is an information-theoretic lower bound.

**Formal complexity bound.** Let $T(n)$ denote the total field operations across all $n$ rounds. In round $i$, computing the three evaluations $s_i(0), s_i(1), s_i(2)$ requires $O(2^{n-i})$ operations (one pass over the current arrays), and folding requires another $O(2^{n-i})$ operations. Thus:
$$T(n) = \sum_{i=1}^{n} c \cdot 2^{n-i} = c \cdot (2^{n-1} + 2^{n-2} + \cdots + 1) = c \cdot (2^n - 1) = O(2^n)$$
for some constant $c$ depending on the number of field operations per entry (typically $c \leq 10$ for the product $\tilde{a} \cdot \tilde{b}$). The key insight: the geometric series $\sum_{i=0}^{n-1} 2^i = 2^n - 1$ converts what appears to be $n$ rounds of $O(2^n)$ work each into $O(2^n)$ total. $\square$

**Why the speedup works.** The core insight is simple once you see it.

*Naive approach*: In each of the $n$ rounds, re-evaluate the polynomial at all necessary points from scratch. Round 1 touches $O(2^n)$ terms. Round 2 touches $O(2^{n-1})$ terms, but computes each by going back to the original tables. Round 3 the same. Each round performs a fresh evaluation, and "fresh evaluation" costs the full table size for that round. Total: $n$ separate evaluations, giving $O(n \cdot 2^n)$.

*Folding approach*: Evaluate once at the start, storing results in a table. Then, after each challenge $r_i$, *update* the table rather than re-evaluate. The update is cheap: just a linear combination of adjacent entries. No re-evaluation from scratch, ever. The table shrinks by half each round, and we touch each entry exactly once.

> **The Origami Analogy**
>
> Imagine a long strip of paper with numbers written on it. You want to compute a weighted sum.
>
> *Naive approach*: Walk down the strip, reading numbers and adding them up. For the next round, walk down the strip again.
>
> *Folding approach*: Fold the paper in half. Where the paper overlaps, mix the two numbers together based on the random challenge. Now you have a strip half as long. Throw away the original.
>
> By the end, you have folded the paper into a single square containing one number. You never had to walk back and forth. This is why the prover achieves $O(N)$ total work instead of $O(N \log N)$: each number is touched exactly once, during the fold that eliminates its dimension.

The naive prover asks "what is $\tilde{a}(r_1, \ldots, r_i, x_{i+1}, \ldots)$?" afresh each round. The folding prover asks "given what I already computed, how does fixing $x_i = r_i$ change the table?" The former is $O(2^{n-i})$ per round times $n$ rounds. The latter is $O(2^{n-i})$ per round, summing to a geometric series: $2^{n-1} + 2^{n-2} + \ldots + 1 = 2^n - 1$.

This is dynamic programming: intermediate results flow forward, each round reusing the previous round's work. The fold operation after round $i$ produces exactly the data structure needed for round $i+1$. Instead of recomputing $\tilde{a}(r_1, \ldots, r_i, x_{i+1}, \ldots, x_n)$ from scratch, we derive it from the previous round's output with a single linear pass.

### Worked Example: The Halving Trick with $n = 2$

Let's trace through a complete example. Take $n = 2$ variables and consider the sum-check claim:
$$H = \sum_{(b_1, b_2) \in \{0,1\}^2} \tilde{a}(b_1, b_2) \cdot \tilde{b}(b_1, b_2)$$

Suppose the tables are:

| $(b_1, b_2)$ | $A[b_1, b_2]$ | $B[b_1, b_2]$ | Product |
|--------------|---------------|---------------|---------|
| $(0, 0)$ | 2 | 3 | 6 |
| $(0, 1)$ | 5 | 1 | 5 |
| $(1, 0)$ | 4 | 2 | 8 |
| $(1, 1)$ | 3 | 4 | 12 |

The true sum is $H = 6 + 5 + 8 + 12 = 31$.

**Round 1: Compute $s_1(X_1)$.**

We need three evaluations to specify this degree-2 polynomial:

- $s_1(0) = A[0,0] \cdot B[0,0] + A[0,1] \cdot B[0,1] = 2 \cdot 3 + 5 \cdot 1 = 11$
- $s_1(1) = A[1,0] \cdot B[1,0] + A[1,1] \cdot B[1,1] = 4 \cdot 2 + 3 \cdot 4 = 20$
- $s_1(2)$: First interpolate $A$ and $B$ at $X_1 = 2$:
  - $A[2, 0] = -A[0,0] + 2 \cdot A[1,0] = -2 + 8 = 6$
  - $A[2, 1] = -A[0,1] + 2 \cdot A[1,1] = -5 + 6 = 1$
  - $B[2, 0] = -B[0,0] + 2 \cdot B[1,0] = -3 + 4 = 1$
  - $B[2, 1] = -B[0,1] + 2 \cdot B[1,1] = -1 + 8 = 7$
  - $s_1(2) = 6 \cdot 1 + 1 \cdot 7 = 13$

Verifier checks: $s_1(0) + s_1(1) = 11 + 20 = 31 = H$. $\checkmark$

Prover sends $(11, 20, 13)$. Verifier sends challenge $r_1 = 3$.

**Fold after Round 1.**

Update arrays using $A'[b_2] = (1 - r_1) \cdot A[0, b_2] + r_1 \cdot A[1, b_2]$:

- $A'[0] = (1-3) \cdot 2 + 3 \cdot 4 = -4 + 12 = 8$
- $A'[1] = (1-3) \cdot 5 + 3 \cdot 3 = -10 + 9 = -1$

Similarly for $B$:

- $B'[0] = (1-3) \cdot 3 + 3 \cdot 2 = -6 + 6 = 0$
- $B'[1] = (1-3) \cdot 1 + 3 \cdot 4 = -2 + 12 = 10$

Arrays now have size 2 (down from 4).

**Round 2: Compute $s_2(X_2)$.**

- $s_2(0) = A'[0] \cdot B'[0] = 8 \cdot 0 = 0$
- $s_2(1) = A'[1] \cdot B'[1] = (-1) \cdot 10 = -10$
- $s_2(2) = (-A'[0] + 2 \cdot A'[1]) \cdot (-B'[0] + 2 \cdot B'[1]) = (-8 - 2) \cdot (0 + 20) = (-10) \cdot 20 = -200$

Verifier checks: $s_2(0) + s_2(1) = 0 + (-10) = -10 \stackrel{?}{=} s_1(r_1) = s_1(3)$.

This is the core consistency check of sum-check. The prover committed to $s_1$ before knowing the challenge $r_1 = 3$. Now the verifier demands that $s_2$ (the next round's polynomial) sum to the value $s_1(r_1)$. If the prover lied about $s_1$, the fabricated polynomial almost certainly evaluates incorrectly at the random point $r_1$, and the check fails.

Compute $s_1(3)$ from the degree-2 polynomial through points $(0, 11), (1, 20), (2, 13)$:

Using Lagrange interpolation: 

$s_1(X) = 11 \cdot \frac{(X-1)(X-2)}{(0-1)(0-2)} + 20 \cdot \frac{(X-0)(X-2)}{(1-0)(1-2)} + 13 \cdot \frac{(X-0)(X-1)}{(2-0)(2-1)}$
$= 11 \cdot \frac{(X-1)(X-2)}{2} - 20 \cdot (X)(X-2) + 13 \cdot \frac{X(X-1)}{2}$

At $X = 3$: $s_1(3) = 11 \cdot \frac{2 \cdot 1}{2} - 20 \cdot 3 \cdot 1 + 13 \cdot \frac{3 \cdot 2}{2} = 11 - 60 + 39 = -10$. $\checkmark$

**Total operations:** Round 1 touched 4 entries; Round 2 touched 2 entries. Total: 6 operations, not $2 \cdot 4 = 8$ as naive analysis suggests. For larger $n$, the savings compound: $O(2^n)$ instead of $O(n \cdot 2^n)$.

### Code: The Halving Trick

The following Python implements the folding prover for sum-check over a product $\tilde{a}(x) \cdot \tilde{b}(x)$. Notice how the arrays shrink after each round.

```python
def sumcheck_fold(A, B, challenges):
    """
    Sum-check prover using the halving trick.
    Proves: H = sum over hypercube of A[x] * B[x]

    Args:
        A, B: Tables of size 2^n (as flat lists, index = binary encoding)
        challenges: List of n verifier challenges r_1, ..., r_n

    Returns: List of round polynomials, each as (s(0), s(1), s(2))
    """
    rounds = []

    for r in challenges:
        half = len(A) // 2

        # Compute s(0), s(1), s(2) for this round's polynomial
        # s(t) = sum over remaining vars of A(t, ...) * B(t, ...)
        s0 = sum(A[2*i] * B[2*i] for i in range(half))
        s1 = sum(A[2*i + 1] * B[2*i + 1] for i in range(half))

        # s(2): extrapolate using linearity. For a line through
        # (0, y0) and (1, y1), the value at t=2 is 2*y1 - y0
        s2 = sum((2*A[2*i + 1] - A[2*i]) * (2*B[2*i + 1] - B[2*i])
                 for i in range(half))

        rounds.append((s0, s1, s2))

        # FOLD: A'[i] = (1-r)*A[2i] + r*A[2i+1]
        # This computes A restricted to first variable = r
        A = [(1 - r) * A[2*i] + r * A[2*i + 1] for i in range(half)]
        B = [(1 - r) * B[2*i] + r * B[2*i + 1] for i in range(half)]

    return rounds

# Reproduce the worked example above
A = [2, 5, 4, 3]  # A[00]=2, A[01]=5, A[10]=4, A[11]=3
B = [3, 1, 2, 4]  # B[00]=3, B[01]=1, B[10]=2, B[11]=4

print(f"True sum: {sum(A[i]*B[i] for i in range(4))}")  # 31

rounds = sumcheck_fold(A, B, challenges=[3, 7])
for i, (s0, s1, s2) in enumerate(rounds):
    print(f"Round {i+1}: s(0)={s0}, s(1)={s1}, s(2)={s2}")
    print(f"  Check: s(0) + s(1) = {s0 + s1}")
```

Output:
```
True sum: 31
Round 1: s(0)=11, s(1)=20, s(2)=13
  Check: s(0) + s(1) = 31
Round 2: s(0)=0, s(1)=-10, s(2)=-200
  Check: s(0) + s(1) = -10
```

The key insight: each round, the arrays halve in size. Total work is $4 + 2 = 6$ operations, not $4 + 4 = 8$. For $n$ variables with table size $N = 2^n$, this gives $N + N/2 + N/4 + \cdots = O(N)$.



## Sparse Sums

The halving trick solves the dense case: when all $2^n$ terms are present, we achieve optimal $O(2^n)$ proving time. But many applications involve **sparse** sums, where only $T \ll 2^n$ terms are non-zero, and here the halving trick falls short.

Consider a lookup table with $N = 2^{30}$ possible indices but only $T = 2^{20}$ actual lookups. The halving trick still touches all $2^{30}$ positions, folding arrays of zeros. We're wasting a factor of 1000 in both time and space.

Can the prover exploit sparsity?

### The Challenge

The dense algorithm folds arrays of size $N$. Even if most entries are zero, the fold operation touches all positions. We need a fundamentally different approach.

### The Key Assumption: Separable Product Structure

Not every sparse polynomial admits fast proving. The technique requires a specific structure.

**Clarification: sparse input, dense polynomial.** When we say "sparse sum," we mean the *input data* is sparse: the table of values on the Boolean hypercube has mostly zeros. The multilinear extension of this sparse vector is typically a *dense* polynomial with non-zero values everywhere on the continuous domain. This distinction matters because we operate on the basis vector (the table), not the polynomial coefficients. Sparsity in the table is what we exploit.

Suppose the polynomial factors as:

$$g(p, s) = \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$$

where we split the $n$ variables into prefix $p = (x_1, \ldots, x_{n/2})$ and suffix $s = (x_{n/2+1}, \ldots, x_n)$, and:

- **$\tilde{a}(p, s)$** is a **sparse** selector with only $T$ non-zero entries
- **$\tilde{f}(p)$** depends only on prefix variables (dense, size $2^{n/2}$)
- **$\tilde{h}(s)$** depends only on suffix variables (dense, size $2^{n/2}$)

This structure arises naturally in memory-checking arguments, lookup protocols, and batch polynomial evaluation. Think of $\tilde{a}$ as selecting "which (address, value) pairs actually occur," $\tilde{f}$ as encoding "address-dependent data," and $\tilde{h}$ as encoding "value-dependent data."

### Why This Structure Enables Sparsity Exploitation

The separable product structure is what makes sparse proving possible. Here's the key observation:

When we build intermediate arrays for sum-check, the sparse factor $\tilde{a}(p,s)$ acts as a filter. To compute an aggregate like $\sum_s \tilde{a}(p,s) \cdot \tilde{h}(s)$, we only need to touch the $T$ positions where $\tilde{a}$ is non-zero. The dense factors $\tilde{f}$ and $\tilde{h}$ are accessed only at locations dictated by the sparse selector.

Without this structure, exploiting sparsity is impossible. A general sparse polynomial $g(x_1, \ldots, x_n)$ doesn't decompose into independent prefix and suffix factors, so we can't avoid touching all $2^n$ positions during folding.

### Two-Stage Proving

Given the separable product structure, we prove the sum in two stages. Each stage handles half the variables, building dense arrays of size $2^{n/2}$ by scanning only the $T$ sparse entries.

**Stage 1: Sum-check over prefix variables.**

Define aggregated arrays $P$ and $F$, each of size $2^{n/2}$, indexed by prefix bit-vectors $p \in \{0,1\}^{n/2}$:

$$P[p] = \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{h}(s)$$
$$F[p] = \tilde{f}(p)$$

The arrays $P$ and $F$ have size $2^{n/2}$, not $2^n$. By summing out the suffix variables when building $P$, we reduce the problem from $n$ variables to $n/2$ variables for Stage 1.

Computing $P$ requires one pass over the $T$ non-zero terms: for each non-zero $(p, s)$ pair, add $\tilde{a}(p, s) \cdot \tilde{h}(s)$ to $P[p]$.

Now observe: the original sum-check claim is
$$\sum_{p \in \{0,1\}^{n/2}} \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s) = \sum_{p \in \{0,1\}^{n/2}} \tilde{f}(p) \cdot \underbrace{\sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{h}(s)}_{= P[p]}$$

So proving the original sum reduces to proving $\sum_p \tilde{P}(p) \cdot \tilde{F}(p)$, a sum-check with only $n/2$ variables. Here $\tilde{P}$ and $\tilde{F}$ are the multilinear extensions of arrays $P$ and $F$.

Run the dense halving algorithm on these $2^{n/2}$-sized arrays. Time: $O(T)$ to build $P$ from sparse entries, plus $O(2^{n/2})$ for the dense sum-check.

**Stage 2: Sum-check over suffix variables (to verify Stage 1's evaluation).**

Stage 1 is a complete sum-check on its own polynomial, ending with an evaluation claim. But that claim involves $\tilde{P}(r_p)$, which is itself defined as a sum. Where does Stage 2 come from?

**The key point:** Stage 1 is a complete sum-check, but on a *different polynomial* than the original. Compare:

| | Original claim | Stage 1 claim |
|---|---|---|
| **Polynomial** | $g(p,s) = \tilde{a}(p,s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$ | $\tilde{P}(p) \cdot \tilde{F}(p)$ |
| **Variables** | $n$ (both $p$ and $s$) | $n/2$ (only $p$) |
| **Rounds** | $n$ | $n/2$ |

The two sums are equal (both equal $H$), but Stage 1's polynomial has half the variables because we pre-summed the suffix into $P[p]$.

Like any sum-check, Stage 1 ends with a final evaluation claim: "I claim $\tilde{P}(r_p) \cdot \tilde{F}(r_p) = v_1$." The verifier can check $\tilde{F}(r_p)$ via polynomial commitment. But what about $\tilde{P}(r_p)$?

Expanding using the definition of $P$:

$$\tilde{P}(r_p) = \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(r_p, s) \cdot \tilde{h}(s)$$

This is a sum over $2^{n/2}$ terms. The verifier can't compute it directly. **Stage 2 is a second sum-check to prove this evaluation claim.** We use sum-check to verify that the final evaluation from Stage 1 is correct.

Define arrays $H$ and $Q$, each of size $2^{n/2}$, indexed by suffix bit-vectors $s \in \{0,1\}^{n/2}$:

$$H[s] = \tilde{a}((r_1, \ldots, r_{n/2}), s)$$
$$Q[s] = \tilde{h}(s)$$

Here $H$ is the sparse selector with its prefix fixed to the random challenges: it answers "what is the selector's value at address $(r_p, s)$?" The factor $\tilde{f}(r_p)$ is now a constant (computed once from the dense $F$ array) that multiplies the entire Stage 2 sum.

Computing $H$ requires the MLE interpolation identity: $\tilde{a}(r_p, s) = \sum_{p'} \tilde{a}(p', s) \cdot \widetilde{\text{eq}}(p', r_p)$. For each sparse entry $(p, s)$, we need the Lagrange coefficient $\widetilde{\text{eq}}(p, r_p)$ to weight its contribution to $H[s]$.

(The function $\widetilde{\text{eq}}$ is the "equality polynomial" that extracts a specific Boolean point's contribution to an MLE. We'll define it formally in the Spartan section below; for now, just think of it as the multilinear Lagrange basis function.)

A naive approach computes each $\widetilde{\text{eq}}(p, r_p)$ independently in $O(n/2)$ field ops, giving $O(T \cdot n)$ total. But we can do better: precompute *all* $2^{n/2}$ values $\widetilde{\text{eq}}(p, r_p)$ for every Boolean $p$ in $O(2^{n/2})$ time using the product structure of $\widetilde{\text{eq}}$. Then each sparse entry requires only a table lookup plus one multiplication. Total: $O(2^{n/2})$ for precomputation, $O(T)$ for the pass over sparse entries.

Run the dense halving algorithm on $H$ and $Q$ for the remaining $n/2$ rounds. Time: $O(2^{n/2})$ for precomputing $\widetilde{\text{eq}}$ values, $O(T)$ to accumulate into $H$, plus $O(2^{n/2})$ for the dense sum-check.

**Total.** The structure is two chained sum-checks:

1. **Stage 1** ($n/2$ rounds): proves the sum equals $H$, ends with evaluation claim about $\tilde{P}(r_p)$
2. **Stage 2** ($n/2$ rounds): proves that evaluation claim, ends with evaluation of $\tilde{a}(r_p, r_s)$ and $\tilde{h}(r_s)$

Together: $n/2 + n/2 = n$ rounds, matching the original $n$-variable sum-check. But prover work is only:
$$O(T + 2^{n/2})$$

Two passes over $T$ sparse terms (one per stage), plus two $2^{n/2}$-sized dense sum-checks. With appropriate parameters, this can be much less than $O(2^n)$.

### Worked Example: Sparse Sum with $N = 16$, $T = 3$

Consider a table of size $N = 16$ (so $n = 4$ variables), but only $T = 3$ entries are non-zero. We want to prove:
$$H = \sum_{(p, s) \in \{0,1\}^4} \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$$

where $p = (x_1, x_2)$ is the 2-bit prefix and $s = (x_3, x_4)$ is the 2-bit suffix.

**The sparse data.** Suppose the only non-zero entries are:

| Index | Prefix $p$ | Suffix $s$ | $\tilde{a}(p,s)$ | $\tilde{f}(p)$ | $\tilde{h}(s)$ | Product |
|-------|------------|------------|------------------|----------------|----------------|---------|
| 5 | $(0,1)$ | $(0,1)$ | 3 | 2 | 4 | 24 |
| 9 | $(1,0)$ | $(0,1)$ | 5 | 1 | 4 | 20 |
| 14 | $(1,1)$ | $(1,0)$ | 2 | 3 | 7 | 42 |

True sum: $H = 24 + 20 + 42 = 86$.

**Dense approach (bad).** Store all 16 entries, fold arrays of size 16 → 8 → 4 → 2 → 1. Touches all 16 positions even though 13 are zero.

**Sparse two-stage approach (good).**

**Stage 1: Build aggregated prefix array $P$.**

Scan the 3 non-zero terms and accumulate:
$$P[p] = \sum_{s} \tilde{a}(p, s) \cdot \tilde{h}(s)$$

- Entry $(0,1), (0,1)$: Add $3 \cdot 4 = 12$ to $P[(0,1)]$
- Entry $(1,0), (0,1)$: Add $5 \cdot 4 = 20$ to $P[(1,0)]$
- Entry $(1,1), (1,0)$: Add $2 \cdot 7 = 14$ to $P[(1,1)]$

Result: $P = [0, 12, 20, 14]$ (indexed by prefix $(0,0), (0,1), (1,0), (1,1)$).

Also store $F[p] = \tilde{f}(p)$: 

$F = [\tilde{f}(0,0), 2, 1, 3]$.

**Run dense sum-check on $\tilde{P}(p) \cdot \tilde{F}(p)$ for 2 rounds.**

This is a size-4 sum-check (not size-16). Suppose after rounds 1-2, we get challenges $(r_1, r_2)$.

**Stage 2: Verify Stage 1's evaluation claim.**

Stage 1 ended with the claim "$\tilde{P}(r_1, r_2) \cdot \tilde{F}(r_1, r_2) = v_1$." The verifier can check $\tilde{F}(r_1, r_2)$ via polynomial commitment, but $\tilde{P}(r_1, r_2)$ is defined as a sum:

$$\tilde{P}(r_1, r_2) = \sum_{s \in \{0,1\}^2} \tilde{a}((r_1, r_2), s) \cdot \tilde{h}(s)$$

Stage 2 is a second sum-check to prove this. Define arrays indexed by suffix $s \in \{0,1\}^2$:

$$H[s] = \tilde{a}((r_1, r_2), s)$$
$$Q[s] = \tilde{h}(s)$$

**Building $H$ via $\widetilde{\text{eq}}$ precomputation.** First, precompute the Lagrange table for all 4 Boolean prefixes:

$\widetilde{\text{eq}}((0,0), (r_1,r_2)) = (1-r_1)(1-r_2)$
$\widetilde{\text{eq}}((0,1), (r_1,r_2)) = (1-r_1) \cdot r_2$
$\widetilde{\text{eq}}((1,0), (r_1,r_2)) = r_1 \cdot (1-r_2)$
$\widetilde{\text{eq}}((1,1), (r_1,r_2)) = r_1 \cdot r_2$

This takes $O(4) = O(2^{n/2})$ field operations. Now scan the 3 sparse entries, looking up weights from the table:

- Entry $(p,s) = ((0,1), (0,1))$, $\tilde{a} = 3$: Add $3 \cdot \widetilde{\text{eq}}((0,1), (r_1,r_2)) = 3(1-r_1)r_2$ to $H[(0,1)]$
- Entry $(p,s) = ((1,0), (0,1))$, $\tilde{a} = 5$: Add $5 \cdot \widetilde{\text{eq}}((1,0), (r_1,r_2)) = 5 r_1(1-r_2)$ to $H[(0,1)]$
- Entry $(p,s) = ((1,1), (1,0))$, $\tilde{a} = 2$: Add $2 \cdot \widetilde{\text{eq}}((1,1), (r_1,r_2)) = 2 r_1 r_2$ to $H[(1,0)]$

Result: $H = [0, \; 3(1-r_1)r_2 + 5r_1(1-r_2), \; 2r_1 r_2, \; 0]$.

**Building $Q$:** Just copy from the $\tilde{h}$ values: $Q = [\tilde{h}(0,0), 4, 7, \tilde{h}(1,1)]$.

**Run dense sum-check on $\tilde{H}(s) \cdot \tilde{Q}(s)$ for 2 rounds** to prove $\sum_s H[s] \cdot Q[s] = \tilde{P}(r_1, r_2)$.

**Work analysis:**

- Stage 1: $O(T)$ to build $P$ + $O(2^{n/2})$ for dense sum-check = 3 + 4 = 7 operations
- Stage 2: $O(2^{n/2})$ to precompute $\widetilde{\text{eq}}$ table + $O(T)$ to build $H$ + $O(2^{n/2})$ for dense sum-check = 4 + 3 + 4 = 11 operations
- **Total: $O(T + 2^{n/2})$ = 18 operations** instead of $O(N) = 16$ for the dense approach

(In this tiny example, sparse isn't faster because $T = 3$ and $2^{n/2} = 4$ are similar to $N = 16$. The win comes at scale.)

For realistic parameters ($N = 2^{30}$, $T = 2^{20}$), the savings are dramatic: $O(2^{20} + 2^{15})$ instead of $O(2^{30})$, a 1000× speedup.

### Generalization to $c$ Chunks

Split into $c$ chunks instead of 2. Each stage handles $n/c$ variables:

- Time: $O(c \cdot T + c \cdot N^{1/c})$
- Space: $O(N^{1/c})$

Choosing $c \approx \log N / \log \log N$ yields prover time $O(T \cdot \text{polylog}(N))$ with polylogarithmic space. The prover runs in time proportional to the number of non-zero terms, with only logarithmic overhead.

## Spartan: Sum-Check for R1CS

What's the simplest possible SNARK?

Not in terms of assumptions (transparent or trusted setup, pairing-based or hash-based). In terms of *conceptual machinery*. What's the minimum set of ideas needed to go from "here's a constraint system" to "here's a succinct proof"?

Spartan (Setty, 2020) provides a surprisingly clean answer: sum-check plus polynomial commitments. Nothing else. No univariate encodings, no FFTs over roots of unity, no quotient polynomials, no PCP constructions. Just the two building blocks we've already developed.

### The R1CS Setup

An R1CS instance consists of sparse matrices $A, B, C \in \mathbb{F}^{m \times n}$ and a constraint: find a witness $z \in \mathbb{F}^n$ such that
$$Az \circ Bz = Cz$$
where $\circ$ denotes the Hadamard (entrywise) product. Each row of this equation is a constraint; the system has $m$ constraints over $n$ variables.

### The Multilinear View

Interpret the witness $z$ as evaluations of a multilinear polynomial $\tilde{z}$ over the Boolean hypercube $\{0,1\}^{\log n}$:
$$z_i = \tilde{z}(i) \quad \text{for } i \in \{0,1\}^{\log n}$$

Similarly, view the matrices $A, B, C$ as bivariate functions: $A(i, j)$ is the entry at row $i$, column $j$. Their multilinear extensions $\tilde{A}, \tilde{B}, \tilde{C}$ are defined over $\{0,1\}^{\log m} \times \{0,1\}^{\log n}$.

The constraint $Az \circ Bz = Cz$ becomes: for every row index $x \in \{0,1\}^{\log m}$,
$$\left(\sum_{y \in \{0,1\}^{\log n}} \tilde{A}(x, y) \cdot \tilde{z}(y)\right) \cdot \left(\sum_{y \in \{0,1\}^{\log n}} \tilde{B}(x, y) \cdot \tilde{z}(y)\right) = \sum_{y \in \{0,1\}^{\log n}} \tilde{C}(x, y) \cdot \tilde{z}(y)$$

Define the error at row $x$:
$$g(x) = \left(\sum_y \tilde{A}(x, y) \tilde{z}(y)\right) \cdot \left(\sum_y \tilde{B}(x, y) \tilde{z}(y)\right) - \sum_y \tilde{C}(x, y) \tilde{z}(y)$$

The R1CS constraint is satisfied iff $g(x) = 0$ for all $x \in \{0,1\}^{\log m}$.

> **Remark: Multilinear vs. Univariate Encodings.**
> This multilinear view differs fundamentally from the QAP approach in Chapter 12 (Groth16). There, R1CS matrices become univariate polynomials via Lagrange interpolation over roots of unity. The constraint $Az \circ Bz = Cz$ transforms into a polynomial divisibility condition: $A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$, where $Z_H$ is the vanishing polynomial over the evaluation domain. Proving satisfaction means exhibiting the quotient $H(X)$.
>
> Spartan takes a different path. Instead of interpolating over roots of unity, it interprets vectors and matrices as multilinear extensions over the Boolean hypercube. Instead of checking divisibility by a vanishing polynomial, it checks that an error polynomial evaluates to zero on all Boolean inputs, via sum-check. No quotient polynomial, no FFT, no roots of unity. Just multilinear algebra and sum-check.
>
> Both approaches reduce R1CS to polynomial claims. QAP reduces to divisibility; Spartan reduces to vanishing on the hypercube. The sum-check approach avoids the $O(n \log n)$ FFT costs and the trusted setup of pairing-based SNARKs, at the cost of larger proofs (logarithmic in the constraint count rather than constant).

### The Zero-on-Hypercube Reduction

Here is Spartan's key insight: checking that $g$ vanishes on the Boolean hypercube reduces to a single sum-check. The technique works for any polynomial, not just R1CS errors.

**The problem:** We want to verify that $g(x) = 0$ for all $x \in \{0,1\}^{\log m}$.

**The reduction:** Sample random $\tau \in \mathbb{F}^{\log m}$ and check:
$$\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$$

**The equality polynomial.** The function $\widetilde{\text{eq}}: \mathbb{F}^n \times \mathbb{F}^n \to \mathbb{F}$ (previewed in the sparse sum-check section above) is defined as:
$$\widetilde{\text{eq}}(\tau, x) = \prod_{i=1}^{n} \left(\tau_i x_i + (1-\tau_i)(1-x_i)\right)$$

Think of $\widetilde{\text{eq}}$ as Lagrange interpolation in disguise. It creates a function that equals 1 at exactly one Boolean point and 0 at all others. When $\tau$ is Boolean, $\widetilde{\text{eq}}(\tau, x)$ is 1 if $x = \tau$ and 0 for every other Boolean $x$. When $\tau$ is a general field element, $\widetilde{\text{eq}}(\tau, x)$ smoothly interpolates, giving the coefficients needed to "select" any value from a table.

Each factor is linear in both $\tau_i$ and $x_i$. On Boolean inputs, the factor equals 1 when $\tau_i = x_i$ (both 0 or both 1) and equals 0 when they differ. On non-Boolean inputs, the factor interpolates smoothly; for instance, $\tau_i x_i + (1-\tau_i)(1-x_i)$ at $(\tau_i, x_i) = (2, 0)$ gives $0 + (-1)(1) = -1$.

**The key observation:** When both inputs are Boolean, the product equals $\mathbf{1}[\tau = x]$, the indicator function that is 1 if and only if $\tau = x$, and 0 otherwise. But the formula extends smoothly to all field elements. This is precisely the multilinear extension of the equality indicator over $\{0,1\}^n \times \{0,1\}^n$.

**A small example.** Take $n = 2$. We have $\widetilde{\text{eq}}((\tau_1, \tau_2), (x_1, x_2)) = (\tau_1 x_1 + (1-\tau_1)(1-x_1)) \cdot (\tau_2 x_2 + (1-\tau_2)(1-x_2))$.

Evaluate at $\tau = (2, 3)$ for each Boolean $x$:

- $\widetilde{\text{eq}}((2,3), (0,0)) = (0 + (-1)(-1)) \cdot (0 + (-2)(-1)) = 1 \cdot 2 = 2$
- $\widetilde{\text{eq}}((2,3), (0,1)) = (0 + (-1)(-1)) \cdot (3 + 0) = 1 \cdot 3 = 3$
- $\widetilde{\text{eq}}((2,3), (1,0)) = (2 + 0) \cdot (0 + (-2)(-1)) = 2 \cdot 2 = 4$
- $\widetilde{\text{eq}}((2,3), (1,1)) = (2 + 0) \cdot (3 + 0) = 2 \cdot 3 = 6$

Notice these sum to $2 + 3 + 4 + 6 = 15 \neq 1$. The equality polynomial doesn't form a partition of unity when $\tau$ is non-Boolean, but it doesn't need to. What matters is the next property.

**The key identity.** For any function $f: \{0,1\}^n \to \mathbb{F}$ with multilinear extension $\tilde{f}$:
$$\sum_{x \in \{0,1\}^n} \widetilde{\text{eq}}(\tau, x) \cdot f(x) = \tilde{f}(\tau)$$

This is the MLE evaluation formula from Chapter 4: the sum "selects" the value at $\tau$ via weighted interpolation. When $\tau$ is Boolean, exactly one term survives (weight 1, all others 0). When $\tau$ is a general field element, all $2^n$ terms contribute with the appropriate interpolation weights.

**Why not just sum $g$ directly?** A natural first attempt: prove $\sum_{x \in \{0,1\}^n} g(x) = 0$ via sum-check. If $g$ vanishes on the hypercube, this sum is indeed zero. But the converse fails: the sum can be zero even when $g$ doesn't vanish everywhere. For instance, if $g(0,0) = 5$ and $g(0,1) = -5$ with $g(1,0) = g(1,1) = 0$, then $\sum_x g(x) = 0$ despite $g$ being nonzero at two points. The positive and negative values cancel.

The equality polynomial fixes this. By weighting each term with a random coefficient $\widetilde{\text{eq}}(\tau, x)$, cancellation becomes overwhelmingly unlikely.

**Why the reduction works.** The sum $\sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x)$ is a random linear combination of the values $\{g(x)\}_{x \in \{0,1\}^n}$. The coefficients $\widetilde{\text{eq}}(\tau, x)$ depend on the random challenge $\tau$, and for random $\tau$, these coefficients are essentially random field elements.

If all $g(x) = 0$, the sum is trivially zero. But if even one $g(x^*) \neq 0$, the sum becomes a random linear combination with at least one nonzero term. Such a combination equals zero only when the coefficients "conspire" to cancel, an event with negligible probability over random $\tau$.

More precisely: define $Q(\tau) = \sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x)$. By the key identity, $Q(\tau) = \tilde{g}(\tau)$, the multilinear extension of $g$ evaluated at $\tau$. This polynomial $Q$ has degree at most $n$ (one per variable).

- If $g(x) = 0$ for all $x \in \{0,1\}^n$, then $\tilde{g}$ is the zero polynomial, so $Q(\tau) = 0$ for all $\tau$.
- If some $g(x^*) \neq 0$, then $\tilde{g}$ is a nonzero polynomial of degree at most $n$. By Schwartz-Zippel, $Q(\tau) \neq 0$ for random $\tau$ with probability $\geq 1 - n/|\mathbb{F}|$.

**Formal soundness statement.** Let $g: \{0,1\}^n \to \mathbb{F}$ be any function with multilinear extension $\tilde{g}$. Define the predicate $\text{ZERO}(g) := \forall x \in \{0,1\}^n, g(x) = 0$. Then:
$$\Pr_{\tau \leftarrow \mathbb{F}^n}\left[\tilde{g}(\tau) = 0 \mid \neg\text{ZERO}(g)\right] \leq \frac{n}{|\mathbb{F}|}$$
*Proof.* If $\neg\text{ZERO}(g)$, then $\tilde{g}$ is a nonzero multilinear polynomial (since $\tilde{g}(x) = g(x) \neq 0$ for some Boolean $x$). A nonzero multilinear polynomial has total degree at most $n$. By Schwartz-Zippel, a nonzero polynomial of degree $d$ over $\mathbb{F}$ has at most $d \cdot |\mathbb{F}|^{n-1}$ roots in $\mathbb{F}^n$. Thus the probability of hitting a root is at most $n \cdot |\mathbb{F}|^{n-1} / |\mathbb{F}|^n = n/|\mathbb{F}|$. $\square$

This reduces "check $g$ vanishes on $2^n$ points" to "run sum-check on one random linear combination and verify it equals zero."

### The Sum-Check Protocol

1. **Verifier sends** random $\tau \in \mathbb{F}^{\log m}$
2. **Prover claims** $\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$, where $g(x) = \left(\sum_y \tilde{A}(x, y) \tilde{z}(y)\right) \cdot \left(\sum_y \tilde{B}(x, y) \tilde{z}(y)\right) - \sum_y \tilde{C}(x, y) \tilde{z}(y)$
3. **Run sum-check** on this claim

At the end, the verifier holds a random point $r \in \mathbb{F}^{\log m}$ and needs to evaluate $g(r)$. This requires:

- $\sum_y \tilde{A}(r, y) \tilde{z}(y)$, $\sum_y \tilde{B}(r, y) \tilde{z}(y)$, $\sum_y \tilde{C}(r, y) \tilde{z}(y)$

Each of these is itself a sum over the hypercube, requiring three more sum-checks! But now the sums are over $y$, and the polynomials have the form $\tilde{M}(r, y) \cdot \tilde{z}(y)$ for the fixed $r$ from the outer sum-check.

**The reduction chain.** After running these three inner sum-checks (which can be batched into one using random linear combinations), the verifier holds a random point $s \in \mathbb{F}^{\log n}$ and needs to check:

- $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$: evaluations of the matrix MLEs
- $\tilde{z}(s)$: evaluation of the witness MLE

The matrix evaluations are handled by SPARK (below). The witness evaluation $\tilde{z}(s)$ is where polynomial commitments enter: the prover opens the committed $\tilde{z}$ at the random point $s$, and the verifier checks the opening proof.

This is the full reduction: R1CS satisfaction → zero-on-hypercube (outer sum-check) → matrix-vector products (inner sum-checks) → point evaluations (polynomial commitment openings).

### Handling Sparse Matrices: SPARK

We've reduced R1CS to sum-check, but there's a lingering problem: the matrices $A$, $B$, $C$ are $m \times n$, potentially huge. A dense representation costs $O(mn)$ space, and committing to them naively would dominate the entire protocol.

But R1CS matrices are sparse. A circuit with $m$ constraints typically has only $O(m)$ non-zero entries total, not $O(mn)$. Can we exploit this?

**The sparse representation.** A sparse matrix with $T$ non-zero entries can be stored as a list of $(i, j, v)$ tuples: row index, column index, value. This costs $O(T)$ space instead of $O(mn)$.

**The evaluation problem.** At the end of the inner sum-checks, the verifier needs the matrix MLE evaluations $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$ at random points $(r, s) \in \mathbb{F}^{\log m} \times \mathbb{F}^{\log n}$. How do we compute these from the sparse representation?

The MLE of a matrix $M$ evaluated at $(r_x, r_y)$ is:
$$\tilde{M}(r_x, r_y) = \sum_{(i,j) \in \{0,1\}^{\log m} \times \{0,1\}^{\log n}} M(i,j) \cdot \widetilde{\text{eq}}(i, r_x) \cdot \widetilde{\text{eq}}(j, r_y)$$

Since $M(i,j) = 0$ for most entries, this simplifies to a sum over only the $T$ non-zero entries:
$$\tilde{M}(r_x, r_y) = \sum_{(i,j): M(i,j) \neq 0} M(i,j) \cdot \widetilde{\text{eq}}(i, r_x) \cdot \widetilde{\text{eq}}(j, r_y)$$

**The naive cost.** For each non-zero entry $(i, j, v)$, we need $\widetilde{\text{eq}}(i, r_x)$ and $\widetilde{\text{eq}}(j, r_y)$. Computing $\widetilde{\text{eq}}(i, r_x)$ directly from the formula $\prod_k (i_k \cdot (r_x)_k + (1-i_k)(1-(r_x)_k))$ costs $O(\log m)$. Over $T$ entries, total cost: $O(T \log m)$.

**SPARK's insight.** Spartan introduces **SPARK** (Sparse Polynomial Arithmetic via Randomized Kernels) to reduce this to $O(T)$. The trick: precompute lookup tables.

1. **Precompute row weights.** Build a table $E_{\text{row}}[i] = \widetilde{\text{eq}}(i, r_x)$ for all $i \in \{0,1\}^{\log m}$. This costs $O(m)$ using the standard MLE evaluation algorithm (stream through bit-vectors, accumulate products).

2. **Precompute column weights.** Build a table $E_{\text{col}}[j] = \widetilde{\text{eq}}(j, r_y)$ for all $j \in \{0,1\}^{\log n}$. Cost: $O(n)$.

3. **Evaluate via lookups.** Initialize a running sum to zero. For each non-zero entry $(i, j, v)$, look up $E_{\text{row}}[i]$ and $E_{\text{col}}[j]$, then add $v \cdot E_{\text{row}}[i] \cdot E_{\text{col}}[j]$ to the running sum. After processing all $T$ entries, the sum equals $\tilde{M}(r_x, r_y)$. Cost: $O(T)$.

Total: $O(m + n + T)$, linear in the sparse representation size.

**But who checks the lookups?** The prover claims to have looked up the correct values, but the verifier can't check this directly without the full tables. SPARK uses a memory-checking argument to verify consistency.

Here's the intuition. Think of $E_{\text{row}}$ as a read-only memory with $m$ cells. The prover reads from this memory $T$ times, once per sparse entry. Each read is a pair $(\text{addr}_k, v_k)$: "I read value $v_k$ from address $\text{addr}_k$." The prover collects all $T$ reads into a list.

Now the key observation: if every read is honest, then the multiset of reads must be consistent with the memory contents. Concretely, if address $i$ appears $c_i$ times in the reads, the claimed values at those positions must all equal $E_{\text{row}}[i]$. A cheating prover who claims a wrong value creates an inconsistency.

To check this efficiently, both the reads and the memory contents are encoded as polynomials. The verifier picks a random challenge and checks that a certain polynomial identity holds. This identity essentially compares "fingerprints" of the read list versus the memory. If any read is incorrect, the fingerprints mismatch with high probability over the random challenge.

We'll develop this memory-checking technique fully in Chapter 20. For now, the key point is that it adds only $O(\log T)$ to proof size and verification time, preserving SPARK's linear prover efficiency.

### The Full Protocol

Putting it together, Spartan proceeds as follows:

1. **Commitment phase.** The prover commits to the witness $\tilde{z}$ using a multilinear polynomial commitment scheme. The matrices $A$, $B$, $C$ are public (part of the circuit description), so no commitment is needed for them.

2. **Outer sum-check.** The verifier sends random $\tau \in \mathbb{F}^{\log m}$. The prover and verifier run sum-check on:
   $$\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$$
   This reduces to evaluating $g(r)$ at a random point $r \in \mathbb{F}^{\log m}$.

3. **Inner sum-checks.** Evaluating $g(r)$ requires three matrix-vector products: $\sum_y \tilde{A}(r, y) \cdot \tilde{z}(y)$, $\sum_y \tilde{B}(r, y) \cdot \tilde{z}(y)$, and $\sum_y \tilde{C}(r, y) \cdot \tilde{z}(y)$. The verifier sends random $\rho_A, \rho_B, \rho_C \in \mathbb{F}$, and the parties run a single sum-check on the combined claim:
   $$\sum_{y \in \{0,1\}^{\log n}} \left(\rho_A \tilde{A}(r, y) + \rho_B \tilde{B}(r, y) + \rho_C \tilde{C}(r, y)\right) \cdot \tilde{z}(y) = v$$
   where $v$ is the prover's claimed value for the batched sum. At the end of sum-check, the verifier holds a random point $s \in \mathbb{F}^{\log n}$ and a claimed evaluation $v_{\text{final}}$ of the polynomial at $s$.

4. **SPARK.** The prover provides claimed values $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$ and proves they're consistent with the sparse matrix representation via memory-checking fingerprints.

5. **Witness opening.** The prover opens $\tilde{z}(s)$ using the polynomial commitment scheme. The verifier checks the opening proof and obtains the value $\tilde{z}(s)$.

6. **Final verification.** The verifier computes $\left(\rho_A \tilde{A}(r, s) + \rho_B \tilde{B}(r, s) + \rho_C \tilde{C}(r, s)\right) \cdot \tilde{z}(s)$ using the values from steps 4-5, and checks that it equals the final claimed value $v_{\text{final}}$ from the inner sum-check. This is the "reduction endpoint": if the prover cheated anywhere in the sum-check, this equality fails with high probability.

### Complexity

| Component | Prover | Verifier | Communication | Technique |
|-----------|--------|----------|---------------|-----------|
| Outer sum-check | $O(m)$ | $O(\log m)$ | $O(\log m)$ | Halving trick |
| Inner sum-checks | $O(n)$ | $O(\log n)$ | $O(\log n)$ | Halving trick + batching |
| SPARK | $O(T)$ | $O(\log T)$ | $O(\log T)$ | Precomputed $\widetilde{\text{eq}}$ tables + memory checking |
| Witness commitment | depends on PCS | depends on PCS | depends on PCS | Multilinear PCS (IPA, FRI, etc.) |

**Why each step achieves its complexity:**

- **Outer sum-check $O(m)$:** The halving trick from earlier in this chapter. Instead of recomputing $2^{\log m} = m$ terms each round, fold the evaluation tables after each challenge. Total work across all $\log m$ rounds: $m + m/2 + m/4 + \ldots = O(m)$.

- **Inner sum-checks $O(n)$:** Same halving trick, but applied to three matrix-vector products at once. Batching with random coefficients $\rho_A, \rho_B, \rho_C$ combines the three sums into one sum-check, avoiding a $3\times$ overhead.

- **SPARK $O(T)$:** Precompute $\widetilde{\text{eq}}(i, r_x)$ for all row indices and $\widetilde{\text{eq}}(j, r_y)$ for all column indices in $O(m + n)$ time. Then each of the $T$ non-zero entries requires only two table lookups and one multiplication, with no logarithmic-cost $\widetilde{\text{eq}}$ computations per entry. Memory-checking fingerprints verify the lookups in $O(T)$ additional work.

- **Verifier $O(\log m + \log n + \log T)$:** The verifier never touches the full tables. In sum-check, it receives $O(d)$ evaluations per round and performs $O(1)$ field operations to check consistency. Over $\log m + \log n$ rounds, that's $O(\log m + \log n)$ work. SPARK verification adds $O(\log T)$ for the memory-checking fingerprint comparison.

> **Remark (UniSkip).** Spartan's outer sum-check can skip the first round entirely using a technique called UniSkip. The idea: Spartan indexes constraints symmetrically over $\{-N, \ldots, N\}$ rather than $\{0, \ldots, 2N\}$. When summing the first-round polynomial $s_1(X)$ over this symmetric domain, odd-degree terms cancel (for every $+i$ there's a $-i$). The sum depends only on even-degree coefficients, which the verifier can check using precomputed power sums $\sigma_k = \sum_{i=-N}^{N} i^k$. The prover sends the full polynomial; the verifier computes the sum via a dot product with the power sums, then samples a random challenge and continues with round 2. This saves one round of interaction and enables prover optimizations from the symmetric structure.

With $T$ non-zero matrix entries, total prover work is $O(m + n + T)$, linear in the instance size. No trusted setup is required when using IPA or FRI as the polynomial commitment.

### Why This Matters

Step back and consider what we've built. Spartan proves R1CS satisfaction, the standard constraint system for zkSNARKs, using only sum-check and polynomial commitments. No univariate polynomial encodings (like PLONK's permutation argument). No pairing-based trusted setup (like Groth16). No PCP constructions (like early STARKs).

The architecture is minimal: multilinear polynomials, sum-check, commitment scheme. Three ideas, combined cleanly. This simplicity is not merely aesthetic. It's the reason Spartan became the template for subsequent systems. Lasso added lookup arguments; Jolt extended further to prove virtual machine execution. Each built on the same foundation.

Notice the graph structure emerging. Spartan has two levels: an outer sum-check (over constraints) and inner sum-checks (over matrix-vector products). The outer sum-check ends with a claim; the inner sum-checks prove that claim. This is exactly the depth-two graph from the remark at the chapter's start. More complex protocols like Lasso (for lookups) and Jolt (for full RISC-V execution) extend this graph to dozens of nodes across multiple stages, but the pattern remains: sum-checks reducing claims to other sum-checks, bottoming out at committed polynomials.

When a construction is this simple, it becomes a building block for everything that follows.



## The PCP Detour and Sum-Check's Return

Now that we've seen Spartan's elegance (sum-check plus commitments, nothing more) the historical question becomes pressing: how did the field spend two decades missing this?

The answer involves one of cryptography's most instructive wrong turns.

### The Road Not Taken

In 1990, sum-check arrived. Two years later, the PCP theorem landed: every NP statement has a proof checkable by reading only a constant number of bits. *Constant* query complexity. This was astonishing, and it captured the field's imagination completely.

The PCP theorem seemed to obsolete sum-check. Why settle for logarithmic verification when you could have constant-query verification? Kilian showed how to compile PCPs into succinct arguments: commit to the PCP via Merkle tree, let the verifier query random locations, authenticate responses with hash paths. This became *the* template for succinct proofs. Systems like Pepper, Ginger, and early Pinocchio drew on PCP-derived constructions.

Sum-check faded into the background, remembered as a stepping stone rather than a destination.

### The Unnecessary Indirection

Here's what everyone missed: a logical error hiding in plain sight.

The PCP theorem transforms an interactive proof into a *static* proof string that the verifier can query non-adaptively. The prover writes down the entire PCP upfront; the verifier reads random locations without talking to the prover. Interaction removed.

But a PCP string is enormous, polynomial in the computation size. To make it succinct, Kilian's construction has the prover commit to the PCP via a Merkle tree, then the verifier interactively requests random query locations, and the prover reveals those locations with authentication paths. Interaction reintroduced.

To deploy in practice, you apply Fiat-Shamir to make Kilian's protocol non-interactive. Interaction removed again.

Count the transformations: IP → PCP (remove interaction) → Kilian argument (add interaction back) → Fiat-Shamir (remove interaction again).

Two removals of interaction. One obviously redundant. If Fiat-Shamir handles the final step anyway, why go through the PCP at all? Why not apply Fiat-Shamir directly to the original interactive proof, the one based on sum-check?

For twenty years, this question hung in the air, unanswered.

### The Return

Starting around 2018, the answer finally arrived. The missing pieces had fallen into place: fast proving algorithms (the halving trick, sparse sums) and efficient polynomial commitment schemes (KZG, FRI, IPA) that could handle multilinear polynomials directly.

A wave of systems returned to the source:

- **Hyrax** (2018), **Libra** (2019): early sum-check-based SNARKs with linear-time provers
- **Spartan** (2020): sum-check for R1CS without trusted setup
- **HyperPlonk** (2023): sum-check meets Plonkish arithmetization
- **Lasso/Jolt** (2023-24): sum-check plus lookup arguments for zkVMs
- **Binius** (2024): sum-check over binary fields
- **HybridPlonk** (2025): sublogarithmic proof size with linear-time prover

The pattern is consistent:

1. Sum-check as the core interactive proof
2. Polynomial commitments for cryptographic binding
3. Fiat-Shamir applied once

No PCP construction. No double removal. No enormous proof strings that need to be Merkle-hashed and then re-interactivized. The resulting systems are simpler, faster, and closer to optimal, with prover times within a small constant factor of computing the witness itself.

The detour lasted twenty years. The destination was where we started. Sometimes the most powerful technique is the one that was always there, waiting to be taken seriously.



## Application: The Hadamard Product Constraint

The Spartan construction involves R1CS matrices, inner/outer sum-checks, and SPARK. Let's strip away that complexity and see the core ideas in isolation: the zero-on-hypercube reduction (using $\widetilde{\text{eq}}$ to convert "vanishes everywhere" into a single sum) and the halving trick for $O(N)$ proving. No sparsity here, just the dense case.

**Problem.** Given committed vectors $a, b, c \in \mathbb{F}^N$ (where $N = 2^n$), prove that $a \circ b = c$, the entrywise product.

This constraint appears everywhere: multiplication gates in arithmetic circuits, quadratic constraints in R1CS, polynomial products in PLONK. It's the core building block that Spartan lifts to full R1CS.

### The Reduction

Define the error polynomial:
$$g(x) = \tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x)$$

where $\tilde{a}, \tilde{b}, \tilde{c}$ are multilinear extensions. (Note that $g$ is not itself multilinear since the product $\tilde{a} \cdot \tilde{b}$ has degree 2, so we write $g$ without the tilde.)

The constraint $a \circ b = c$ holds if and only if $g(x) = 0$ for all $x \in \{0,1\}^n$.

Using the zero-on-hypercube reduction from Spartan, sample random $r \in \mathbb{F}^n$ and check:
$$\sum_{x \in \{0,1\}^n} \widetilde{\text{eq}}(r, x) \cdot g(x) = 0$$

If any $g(x) \neq 0$, this sum is nonzero with high probability (Schwartz-Zippel).

### The Protocol

1. Verifier sends random $r \in \mathbb{F}^n$
2. Prover claims $H = 0$ (the sum should be zero)
3. Parties run sum-check on $\sum_x \widetilde{\text{eq}}(r, x) \cdot g(x) = 0$
4. At the end, the verifier holds a random point $z = (z_1, \ldots, z_n)$ and a claimed final value $v_{\text{final}}$ from the last round of sum-check
5. Prover opens $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$ via polynomial commitments
6. Verifier computes $\widetilde{\text{eq}}(r, z) \cdot (\tilde{a}(z) \cdot \tilde{b}(z) - \tilde{c}(z))$ and checks that it equals $v_{\text{final}}$

The final check is the sum-check reduction endpoint: the verifier directly evaluates the polynomial being summed at the random point $z$ and confirms it matches what the prover claimed during the protocol.

### Prover Efficiency

The polynomial being summed is:
$$\widetilde{\text{eq}}(r, x) \cdot (\tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x))$$

This is a product of multilinear polynomials. The halving trick applies directly:

- Store tables for $\widetilde{\text{eq}}(r, \cdot)$, $\tilde{a}$, $\tilde{b}$, $\tilde{c}$ (or compute on the fly)
- Fold all four tables after each round

Total prover time: $O(N)$, linear in the constraint size.

### Worked Example: Hadamard Product with $N = 4$

Let $n = 2$ and consider vectors of length 4:

| Index $(b_1, b_2)$ | $a$ | $b$ | $c = a \circ b$ |
|--------------------|-----|-----|-----------------|
| $(0, 0)$ | 2 | 3 | 6 |
| $(0, 1)$ | 4 | 2 | 8 |
| $(1, 0)$ | 1 | 5 | 5 |
| $(1, 1)$ | 3 | 1 | 3 |

We want to prove $a \circ b = c$ via sum-check.

**Step 1: Verifier sends random challenge $r = (r_1, r_2) = (2, 3)$.**

**Step 2: Compute $\widetilde{\text{eq}}(r, x)$ for all $x \in \{0,1\}^2$.**

The equality polynomial is $\widetilde{\text{eq}}(r, x) = \prod_i (r_i x_i + (1-r_i)(1-x_i))$.

- $\widetilde{\text{eq}}((2,3), (0,0)) = (1-2)(1-3) = (-1)(-2) = 2$
- $\widetilde{\text{eq}}((2,3), (0,1)) = (1-2)(3) = (-1)(3) = -3$
- $\widetilde{\text{eq}}((2,3), (1,0)) = (2)(1-3) = (2)(-2) = -4$
- $\widetilde{\text{eq}}((2,3), (1,1)) = (2)(3) = 6$

**Step 3: Compute $g(x) = \tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x)$ on Boolean inputs.**

Since $c = a \circ b$ is correct, $g(x) = 0$ for all $x \in \{0,1\}^2$:

- $g(0,0) = 2 \cdot 3 - 6 = 0$
- $g(0,1) = 4 \cdot 2 - 8 = 0$
- $g(1,0) = 1 \cdot 5 - 5 = 0$
- $g(1,1) = 3 \cdot 1 - 3 = 0$

**Step 4: The claimed sum.**

$$H = \sum_{x \in \{0,1\}^2} \widetilde{\text{eq}}(r, x) \cdot g(x) = 2 \cdot 0 + (-3) \cdot 0 + (-4) \cdot 0 + 6 \cdot 0 = 0$$

Prover claims $H = 0$. This is correct because $a \circ b = c$.

**Step 5: Run sum-check protocol.**

**Round 1:** The prover computes $s_1(X_1)$ by summing over $X_2 \in \{0,1\}$:
$$s_1(X_1) = \sum_{x_2 \in \{0,1\}} \widetilde{\text{eq}}((2,3), (X_1, x_2)) \cdot g(X_1, x_2)$$

Since $g$ is zero on Boolean inputs, the degree-3 polynomial $s_1(X_1)$ satisfies $s_1(0) + s_1(1) = 0$. The prover sends four evaluations $s_1(0), s_1(1), s_1(2), s_1(3)$ to specify this degree-3 polynomial (degree bound is 3: $\widetilde{\text{eq}}$ is degree 1, times $\tilde{a} \cdot \tilde{b}$ which is degree 2, giving degree 3 total).

*Technique: The prover computes $s_1$ by iterating over all $N = 4$ table entries once, $O(N)$ work for this round.*

**Round 2:** After receiving challenge $z_1$, fold all four arrays using the halving trick from earlier in this chapter: $A'[x_2] = (1-z_1) \cdot A[0, x_2] + z_1 \cdot A[1, x_2]$, and similarly for $B$, $C$, and the $\widetilde{\text{eq}}$ table. Then compute $s_2(X_2)$ from the folded arrays. The verifier checks $s_2(0) + s_2(1) = s_1(z_1)$.

*Technique: Halving trick. After folding, the four tables of size 4 become four tables of size 2. Computing $s_2$ requires $O(N/2) = O(2)$ work. Total across both rounds: $O(4 + 2) = O(N)$, not $O(N \log N)$.*

**Final check:** The verifier holds point $z = (z_1, z_2)$ and value $s_2(z_2)$. The prover opens $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$. The verifier checks:
$$\widetilde{\text{eq}}(r, z) \cdot (\tilde{a}(z) \cdot \tilde{b}(z) - \tilde{c}(z)) \stackrel{?}{=} s_2(z_2)$$

*Technique: Polynomial commitment opening. The prover uses the PCS to prove the three evaluations. The verifier checks the opening proofs (cost depends on PCS) and computes $\widetilde{\text{eq}}(r, z)$ directly in $O(\log N) = O(2)$ field multiplications.*

**Why this catches cheating.** The left-hand side is just $f(z)$, the polynomial being summed, evaluated at the random point $z$. The right-hand side $s_2(z_2)$ is what the prover *claimed* this value would be during the sum-check protocol.

The sum-check protocol guarantees: if the prover's claimed sum $H$ was correct, and all the round polynomials $s_1, s_2$ were consistent, then the final claimed value $s_2(z_2)$ must equal $f(z)$. If the prover lied anywhere (wrong sum, wrong round polynomial) the equality fails with high probability over the random challenges $z_1, z_2$.

*Technique: Schwartz-Zippel. If $a \circ b \neq c$, then some $g(x) \neq 0$ for at least one Boolean $x$. The random linear combination $H = \sum_x \widetilde{\text{eq}}(r, x) \cdot g(x)$ is nonzero with high probability over the random choice of $r$. A cheating prover claiming $H = 0$ when $H \neq 0$ will be caught by sum-check's final verification.*

**Work summary:**

| Step | Prover | Verifier | Technique |
|------|--------|----------|-----------|
| Round 1 | $O(N)$ | $O(d)$ | Direct summation over tables |
| Round 2 | $O(N/2)$ | $O(d)$ | Halving trick (folded tables) |
| Final check | PCS-dependent | $O(\log N)$ + PCS | Polynomial commitment opening |
| **Total** | $O(N)$ | $O(\log N)$ + PCS | Geometric series: $N + N/2 + \ldots = O(N)$ |



## Reducing the Final Evaluation Cost

Every sum-check protocol ends the same way: the verifier holds a random point $z$ and needs to check that $g(z)$ equals some claimed value. We've deferred this question throughout the chapter. Now it's time to address it directly.

If $g = \tilde{a} \cdot \tilde{b} - \tilde{c}$, then $g(z)$ requires knowing $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$.

**Without commitments:** Evaluating $\tilde{a}(z)$ from the coefficient representation takes $O(2^n)$ time, as expensive as the original sum.

**With commitments:** The polynomial commitment scheme handles this. The prover provides evaluation proofs for $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$. The verifier checks these proofs (typically in time logarithmic or constant, depending on the PCS) and computes $g(z)$ with three field operations.

This is where polynomial commitments earn their keep: they shift the final evaluation burden from direct computation to cryptographic verification.

### Batching

When sum-check produces multiple evaluation queries at the same point (like $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$) batch evaluation arguments reduce proof size and verification time. Instead of three opening proofs, a single batched proof suffices.

Chapter 20 develops these batch techniques.



## The Streaming Model

For truly massive computations ($N = 2^{40}$ terms), even $O(N)$ memory becomes prohibitive. That's a terabyte of field elements. The prefix-suffix decomposition opens an unexpected door: **streaming provers** that use sublinear memory.

**Definition.** A streaming prover processes the non-zero terms in sequential passes, using memory sublinear in $N$.

With $c$ chunks:

- Passes: $c$
- Memory: $O(N^{1/c})$

For $c = 2$: two passes, $O(\sqrt{N})$ memory. When $N = 2^{40}$, this means ~$2^{20}$ memory instead of $2^{40}$, a million-fold reduction.

Streaming provers differ from recursive SNARKs. Recursion proves proofs of proofs, adding cryptographic overhead at each level. Streaming exploits the algebraic structure of sum-check directly, without recursion.



## Key Takeaways

### Core Techniques

1. **The halving trick achieves $O(N)$ prover time.** Naive sum-check costs $O(N \log N)$ because each of $\log N$ rounds recomputes $N$ terms. The halving trick folds evaluation tables after each round: $N \to N/2 \to N/4 \to \ldots$ Total work: $N + N/2 + N/4 + \ldots = O(N)$.

2. **Folding relies on the hybrid evaluation property.** For multilinear $\tilde{f}$: evaluating at $(r, x_2, \ldots, x_n)$ is a linear combination of evaluations at $(0, x_2, \ldots)$ and $(1, x_2, \ldots)$. This lets the prover collapse a table of size $N$ into size $N/2$ with $O(N)$ field operations.

3. **Sum-check is cache-friendly.** The halving trick scans memory linearly: adjacent pairs combine, then adjacent pairs of results combine, and so on. Contrast with FFT's butterfly operations, which shuffle data non-locally (element $i$ interacts with element $i + N/2$, then $i + N/4$, ...), causing cache misses. For large $N$, this memory access pattern often matters more than the arithmetic.

4. **Sparse sums via prefix-suffix decomposition.** Factor $\widetilde{\text{eq}}(\tau, x) = \widetilde{\text{eq}}(\tau_{\text{prefix}}, x_{\text{prefix}}) \cdot \widetilde{\text{eq}}(\tau_{\text{suffix}}, x_{\text{suffix}})$. Precompute suffix contributions, then stream through non-zero terms. Cost: $O(T + \sqrt{N})$ for $T$ non-zeros with two passes and $O(\sqrt{N})$ memory.

5. **Batching avoids linear blowup.** When sum-check produces $k$ evaluation queries, don't run $k$ separate protocols. Combine with random coefficients: $\sum_i \rho_i \cdot \text{claim}_i$. One sum-check suffices; soundness follows from Schwartz-Zippel.

### Spartan's Architecture

6. **Zero-on-hypercube reduction.** To prove $g(x) = 0$ for all $x \in \{0,1\}^n$, prove instead that $\sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$ for random $\tau$. The $\widetilde{\text{eq}}$ polynomial acts as a random linear combination of the constraints: if any constraint fails, the sum is nonzero with high probability (Schwartz-Zippel).

7. **R1CS reduces to two sum-checks.** Outer sum-check handles the zero-on-hypercube claim (prover: $O(m)$, halving trick). Inner sum-check handles matrix-vector products (prover: $O(n)$, halving trick + batching). Total: $O(m + n)$ for the interactive protocol.

8. **SPARK achieves $O(T)$ for sparse matrices.** Precompute $\widetilde{\text{eq}}(i, r)$ tables for all row/column indices in $O(m + n)$. Then each of $T$ non-zero entries requires only table lookups, with no per-entry logarithmic cost. Memory-checking fingerprints verify correctness.

### The Full Pipeline

9. **Sum-check reduces verification to evaluation.** After $\log N$ rounds, the verifier holds a random point $z$ and a claimed value $v$. All that remains: check that $f(z) = v$ for the polynomial $f$ being summed.

10. **Polynomial commitments handle evaluations.** The prover opens the committed polynomial at $z$; the verifier checks the opening proof. This is where cryptographic hardness enters, since sum-check itself is information-theoretic.

11. **Streaming provers trade passes for memory.** With $c$ passes, memory drops to $O(N^{1/c})$. At $c = 2$: two passes, $O(\sqrt{N})$ memory. This exploits sum-check's algebraic structure directly, without recursive proof composition.

### Historical Perspective

12. **The PCP detour cost two decades.** The path IP → PCP → Kilian → Fiat-Shamir removes interaction, reintroduces it, then removes it again. The direct path (sum-check + Fiat-Shamir) skips the redundant steps. Modern systems (Spartan, Lasso, Jolt, Binius) follow the direct path and achieve prover times within small constants of witness computation.

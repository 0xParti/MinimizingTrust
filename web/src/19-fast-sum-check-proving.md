# Chapter 19: Fast Sum-Check Proving

> *Most chapters in this book can be read with pencil and paper. This one assumes you've already internalized the sum-check protocol (Chapter 3) and multilinear extensions (Chapter 4), not as definitions to look up, but as tools you can wield. If those still feel foreign, consider this chapter a preview of where the road leads, and return when the foundations feel solid.*

In 1992, the sum-check protocol solved the problem of succinct verification. Lund, Fortnow, Karloff, and Nisan had achieved something that sounds impossible: verifying a sum over $2^n$ terms while the verifier performs only $O(n)$ work. Exponential compression in verification time. The foundation of succinct proofs.

Then, for three decades, almost nobody used it.

Why? Because everyone thought the prover was too slow. The total work across all rounds sums to $O(d \cdot 2^n)$ (as Chapter 3 showed via the geometric series), but achieving this requires the prover to evaluate the partially-fixed polynomial efficiently at each round. Without a way to reuse work across rounds, each round's evaluations require going back to the original $2^n$-entry table, inflating the cost to $O(n \cdot 2^n)$. For $n = 30$, that's over 30 billion operations per proof. Researchers chased other paths: PCPs, pairing-based SNARKs, trusted setups. Groth16 and PLONK took univariate polynomials, quotient-based constraints, FFT-driven arithmetic. Sum-check remained a theoretical marvel, admired in complexity circles but dismissed as impractical.

They were wrong.

It turned out that a simple algorithmic trick, available since the 90s but overlooked, made the prover linear time. With the right algorithms, sum-check proving runs in $O(2^n)$ time, linear in the number of terms. For sparse sums where only $T \ll 2^n$ terms are non-zero, prover time drops to $O(T)$. These are not approximations or heuristics; they're exact algorithms exploiting algebraic structure that was always present.

When this was rediscovered and popularized by Justin Thaler in the late 2010s, it triggered a revolution. The field realized it had been sitting on the "Holy Grail" of proof systems for three decades without noticing. This chapter explains the trick that woke up the giant, and then shows how it enables Spartan, the SNARK that proved sum-check alone suffices for practical zero-knowledge proofs. No univariate encodings. No pairing-based trusted setup. Just multilinear polynomials, sum-check, and a commitment scheme.

### Why This Matters: The zkVM Motivation

These techniques find their most compelling application in *zkVMs* (zero-knowledge virtual machines): SNARKs that prove correct execution of arbitrary programs over an instruction set like RISC-V. A million CPU cycles at 50 constraints each yields 50 million constraints. At this scale, $O(n \log n)$ versus $O(n)$ proving is the difference between minutes and seconds. Even the constant factor matters. Fast sum-check proving is what makes zkVMs practical.

## The Prover's Apparent Problem

Let's examine the naive prover cost more carefully.

The sum-check protocol proves:
$$H = \sum_{b \in \{0,1\}^n} g(b)$$

where $g: \mathbb{F}^n \to \mathbb{F}$ is an $n$-variate polynomial. The prover begins by sending the claimed sum $H$ (this is $V_0$). Then in round $i$, the prover sends a univariate polynomial capturing the partial sum with $X_i$ left as a formal variable:

$$s_i(X_i) = \sum_{(b_{i+1}, \ldots, b_n) \in \{0,1\}^{n-i}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

The polynomial $s_i$ is univariate in $X_i$, with degree equal to the degree of $g$ in that variable. Call this degree $d_i$. A degree-$d_i$ univariate is determined by $d_i + 1$ evaluations, but the consistency check $s_i(0) + s_i(1) = V_{i-1}$ (where $V_{i-1}$ is the claim from the previous round) lets the verifier derive one evaluation for free, so the prover sends only $d_i$ values.

For simplicity, assume $g$ has individual degree $d$ in every variable (the common case in practice). Computing $s_i$ requires evaluating it at $d + 1$ points, and each evaluation sums over $2^{n-i}$ terms of the form $g(r_1, \ldots, r_{i-1}, t, b_{i+1}, \ldots, b_n)$.

Here is the problem. In round 1, no variables have been fixed to challenges yet, so each term in the sum for $s_1(t)$ has the form $g(t, b_2, \ldots, b_n)$ with all remaining coordinates Boolean. For $t \in \{0, 1\}$, these are values of $g$ on the hypercube, which the prover computed before the protocol began. For $t > 1$ (the non-Boolean evaluation points needed to determine $s_1$), the prover must interpolate, but only in the first variable. Round 1 is manageable. But from round 2 onward, the first variables are fixed to non-Boolean challenges $r_1, \ldots, r_{i-1}$. The values $g(r_1, \ldots, r_{i-1}, t, b_{i+1}, \ldots, b_n)$ were never precomputed. Without a way to access them cheaply, the prover must recompute them from scratch each round by interpolating over the full $2^n$ Boolean evaluations. This costs $O(2^n)$ per round, and over $n$ rounds the total is $O(n \cdot 2^n)$.

Notice, however, that round $i$ only sums over $2^{n-i}$ terms. The work should shrink by half each round, and the geometric series gives:

$$\sum_{i=1}^n (d+1) \cdot 2^{n-i} = (d+1)\sum_{k=0}^{n-1} 2^k = (d+1)(2^n - 1) = O(d \cdot 2^n)$$

(using the geometric series identity $\sum_{k=0}^{n-1} r^k = \frac{r^n - 1}{r-1}$ with $r = 2$). The bottleneck is not the number of terms but *access*: can the prover obtain the $2^{n-i}$ partially-fixed values for round $i$ without recomputing them from the original $2^n$ values each time? If not, each round costs $O(2^n)$ regardless of how few terms it sums, and the total remains $O(n \cdot 2^n)$.

## The Halving Trick

The answer to the access problem is a single identity from Chapter 4: multilinear folding. After each challenge $r_i$, the prover can update a multilinear polynomial's table of Boolean evaluations in place, producing the restricted polynomial's table in half the space. No recomputation from scratch.

But folding applies to multilinear polynomials, and in the interesting sum-check instances $g$ has degree > 1 in each variable, so $g$ itself is not multilinear. The trick is that $g$ does not need to be multilinear as long as it *decomposes* into multilinear factors. If $g = \tilde{a} \cdot \tilde{b}$ (or more generally a sum of products of MLEs), the prover folds each factor's table independently and recomputes $g$'s values from the folded factors each round. This covers essentially all practical cases: GKR's layer reductions (Chapter 18) use products of MLEs with the equality polynomial, R1CS verification uses $\tilde{a} \cdot \tilde{b} \cdot \tilde{c}$, and Spartan (later in this chapter) reduces to the same form.

We develop the algorithm for the simplest case: $g(x) = \tilde{a}(x) \cdot \tilde{b}(x)$, a product of two multilinear polynomials over $n$ variables.

Since multilinear polynomials have degree at most 1 in each variable, their product has degree at most 2. So $d = 2$, and each round the prover sends two field elements (say $s_i(0)$ and $s_i(2)$); the verifier recovers $s_i(1) = V_{i-1} - s_i(0)$ from the consistency check.

### The Multilinear Folding Identity

Recall from Chapter 4 the streaming evaluation identity: for any multilinear polynomial $\tilde{a}(x_1, x_2, \ldots, x_n)$ and field element $r_1$,

$$\tilde{a}(r_1, x_2, \ldots, x_n) = (1 - r_1) \cdot \tilde{a}(0, x_2, \ldots, x_n) + r_1 \cdot \tilde{a}(1, x_2, \ldots, x_n)$$

This is linear interpolation: $\tilde{a}$ restricted to $X_1$ is a line through $(0, y_0)$ and $(1, y_1)$, given by $y_0 + (y_1 - y_0) \cdot X$. The identity evaluates that line at any $r_1 \in \mathbb{F}$. Chapter 4 used it with challenges in $[0,1]$ to evaluate MLEs in $O(2^n)$ time. Here we also need non-Boolean points: setting $r_1 = 2$ gives $-y_0 + 2y_1$, extrapolating the line beyond its defining points using only stored Boolean evaluations.

This fact enables **folding**: after receiving challenge $r_1$, we can compute the restricted polynomial $\tilde{a}(r_1, x_2, \ldots, x_n)$ from the unrestricted polynomial $\tilde{a}$ in linear time.

### The Algorithm

**Initialization.** Store all $2^n$ evaluations $\tilde{a}(b)$ and $\tilde{b}(b)$ for $b \in \{0,1\}^n$ in arrays $A[b]$ and $B[b]$.

**Round 1.** Compute three evaluations of $s_1(X_1) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} \tilde{a}(X_1, b_2, \ldots, b_n) \cdot \tilde{b}(X_1, b_2, \ldots, b_n)$:

- $s_1(0) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(0, b_2, \ldots, b_n)] \cdot B[(0, b_2, \ldots, b_n)]$
- $s_1(1) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(1, b_2, \ldots, b_n)] \cdot B[(1, b_2, \ldots, b_n)]$
- $s_1(2) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(2, b_2, \ldots, b_n)] \cdot B[(2, b_2, \ldots, b_n)]$

For $s_1(0)$ and $s_1(1)$, we read directly from the stored arrays. For $s_1(2)$, apply the folding identity with $r_1 = 2$: $A[(2, b_2, \ldots, b_n)] = -A[(0, b_2, \ldots, b_n)] + 2 \cdot A[(1, b_2, \ldots, b_n)]$, and similarly for $B$.

Each evaluation sums over $2^{n-1}$ terms, so the three evaluations cost $3 \cdot 2^{n-1}$ operations total. The prover sends two; the verifier recovers the third from $s_1(0) + s_1(1) = H$.

**Fold after round 1.** Receive challenge $r_1$. Create a new array $A'$ of size $2^{n-1}$, indexed by $(b_2, \ldots, b_n) \in \{0,1\}^{n-1}$:
$$A'[(b_2, \ldots, b_n)] = (1 - r_1) \cdot A[(0, b_2, \ldots, b_n)] + r_1 \cdot A[(1, b_2, \ldots, b_n)] = \tilde{a}(r_1, b_2, \ldots, b_n)$$

Discard the old array and rename $A' \to A$. The array now stores the restricted polynomial $\tilde{a}(r_1, x_2, \ldots, x_n)$ evaluated on the $(n-1)$-dimensional hypercube. Similarly fold $B$.

**Round $i$ (general).** After $i-1$ folds, the arrays $A$ and $B$ have size $2^{n-i+1}$, storing $\tilde{a}(r_1, \ldots, r_{i-1}, b_i, \ldots, b_n)$ on the remaining Boolean hypercube. The array splits naturally into two halves of size $2^{n-i}$: entries with $b_i = 0$ and entries with $b_i = 1$. Then:

- $s_i(0) = \sum_{(b_{i+1}, \ldots, b_n)} A[(0, b_{i+1}, \ldots)] \cdot B[(0, b_{i+1}, \ldots)]$ : the sum over the $b_i = 0$ half
- $s_i(1) = \sum_{(b_{i+1}, \ldots, b_n)} A[(1, b_{i+1}, \ldots)] \cdot B[(1, b_{i+1}, \ldots)]$ : the sum over the $b_i = 1$ half
- $s_i(2)$: apply the folding identity with $r = 2$ to get $A[(2, b_{i+1}, \ldots)] = -A[(0, b_{i+1}, \ldots)] + 2 \cdot A[(1, b_{i+1}, \ldots)]$, then sum the products

Each evaluation sums over $2^{n-i}$ terms, costing $3 \cdot 2^{n-i}$ operations total. The prover sends two values, then folds $A$ and $B$ using challenge $r_i$, halving the arrays to size $2^{n-i}$.

The arrays shrink by half each round: $2^n \to 2^{n-1} \to \cdots \to 2 \to 1$. By round $n$, the arrays are singletons and the protocol terminates.

Folding solves the access problem. After each challenge $r_i$, the prover updates the arrays in place via the folding identity, producing exactly the partially-fixed values needed for round $i+1$. No recomputation from scratch. Round $i$ costs $O(2^{n-i})$ for evaluation and $O(2^{n-i})$ for folding, with a constant $c \leq 10$ field operations per entry for the product $\tilde{a} \cdot \tilde{b}$. The total is the geometric series from above:

$$T(n) = \sum_{i=1}^{n} c \cdot 2^{n-i} = c(2^n - 1) = O(2^n)$$

This is optimal: any prover must read all $2^n$ inputs at least once.

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

Each round, the arrays halve in size. The total work across all rounds is the geometric series $N + N/2 + N/4 + \cdots = O(N)$. This is optimal: any prover must read all $N$ inputs at least once.



## Beyond Black-Box Arithmetic

The halving trick achieves $O(2^n)$ field operations, which is optimal. For a textbook, the story could end here. But in practice, sum-check provers over 256-bit fields remain slow even at optimal operation count, because each field multiplication carries a different concrete cost depending on the size of its operands. The next three sections (this one, high-degree products, and small-value proving) progressively reduce the concrete cost by exploiting structure that asymptotic analysis ignores. All three build on the same observation: not all field multiplications are equal.

Not all field multiplications are equal. Over a 256-bit prime field (BN254, BLS12-381), multiplying two arbitrary field elements requires multi-limb integer arithmetic plus modular reduction. But when one operand fits in a single 64-bit machine word, the cost drops dramatically. Three classes emerge:

- **big-big (bb)**: two arbitrary field elements. Roughly 8x the cost of sb.
- **small-big (sb)**: one machine-word integer, one field element.
- **small-small (ss)**: two machine-word integers. A single native multiplication, roughly 30x cheaper than bb.

A further optimization, *delayed reduction*, avoids redundant modular reductions when accumulating a linear combination $\sum c_i \cdot a_i$ with small coefficients $c_i$. Instead of reducing each product separately, the prover accumulates unreduced integer products and performs a single reduction at the end. This nearly halves the cost of sb-dominated loops, which is precisely the structure of the sum-check prover's inner loop.

Why does this matter for sum-check? In round 1, all evaluations lie on the Boolean hypercube. In a zkVM, these are witness values (register contents, memory entries), typically 32- or 64-bit integers stored in a 256-bit field. Round 1 uses only ss and sb operations. After the verifier sends challenge $r_1$, subsequent rounds involve full-width random elements and require bb multiplications.

Round 1 is not a small fraction of the work. By the geometric series, round 1 accounts for *half* the total operations ($2^{n-1}$ out of $2^n - 1$). Rounds 1 and 2 together account for three-quarters. The most expensive rounds are precisely those where values are small. This observation, that the prover's bottleneck rounds coincide with the regime where cheap arithmetic applies, is the starting point for small-value proving.


## High-Degree Products

The halving trick as presented handles $g = \tilde{a} \cdot \tilde{b}$, a product of two multilinear factors with degree $d = 2$. Each round, the prover evaluates the product at $d + 1 = 3$ points, spending a constant number of multiplications per summand. The same idea generalizes to $g = \prod_{k=1}^d p_k$, a product of $d$ multilinear factors: fold each factor independently, then multiply. The folding is unchanged; what changes is the cost of multiplying $d$ factors together at $d + 1$ evaluation points.

Modern proof systems demand this generalization. In batch-evaluation arguments and lookup protocols, the sum-check polynomial is a product of $d$ multilinear factors where $d$ can be 16 or 32. The naive approach evaluates each factor at $d + 1$ points by extrapolation from the Boolean evaluations at 0 and 1, then multiplies pointwise. This costs $(d-1)(d+1) \approx d^2$ bb multiplications per summand. At $d = 32$, that is nearly 1000 bb multiplications per term per round, and the prover's cost balloons to $O(d^2 \cdot 2^n)$.

The question is whether the $d^2$ factor is intrinsic to the problem.

### Divide-and-Conquer via Extrapolation

It is not. A recursive algorithm reduces the bb cost from $O(d^2)$ to $O(d \log d)$ per evaluation point.

We work entirely in *evaluation representation*: each polynomial is stored as its values at a fixed set of points. A linear polynomial (degree 1) is determined by two evaluations (at 0 and 1). A degree-$d$ product needs $d + 1$ evaluations. Multiplying two polynomials in evaluation form is just pointwise multiplication of their values at each point: one field multiplication per point.

Given evaluations of $d$ linear polynomials $p_1, \ldots, p_d$ at the two points $\{0, 1\}$, the goal is to compute evaluations of their product $g = \prod_i p_i$ at $d + 1$ points.

1. Split the $d$ polynomials into two halves of size $\lfloor d/2 \rfloor$ and $\lceil d/2 \rceil$.
2. Recursively compute the product of each half. Each half-product has degree $\sim d/2$ and is known at $\sim d/2 + 1$ points.
3. **Extrapolate** both half-products from their $\sim d/2 + 1$ known points to the full set of $d + 1$ points, using Lagrange interpolation. The interpolation weights are small integers (derived from the evaluation-point coordinates $0, 1, 2, \ldots$), so each multiplication is sb. Cost: $O(d)$ sb multiplications per polynomial.
4. **Multiply pointwise**: at each of the $d + 1$ points, multiply the two half-product values. Both values are arbitrary field elements (results of prior recursion), so each multiplication is bb. Cost: $d + 1$ bb multiplications.

The only source of bb multiplications is step 4. Each level of recursion contributes $d+1$ pointwise products, and the two recursive calls handle the subproblems. Writing $a(d)$ for the total bb count:

$$a(d) \leq d \lceil \log_2 d \rceil + d - 1$$

The extrapolation steps contribute $O(d^2)$ sb multiplications total, but since sb is far cheaper than bb, the wall-clock cost is dominated by the $O(d \log d)$ bb multiplications.

This extends to the multivariate case. In the sum-check prover's inner loop, the product involves $d$ multilinear polynomials in $v$ variables, evaluated on a grid of $(d+1)^v$ points. Multivariate extrapolation reduces to repeated univariate extrapolation along each coordinate dimension. The bb cost becomes $O(d^v)$ for $v \geq 2$, improving by a factor of $d$ over the naive $O(d^{v+1})$.

When used as a subroutine in the linear-time sum-check prover, the total bb cost across all rounds drops from $\Theta(d^2 \cdot 2^n)$ to $\Theta(d \log d \cdot 2^n)$. For $d = 32$, this represents roughly a 5x reduction in the dominant arithmetic cost.



## Small-Value Round-Batching

There is a structural inefficiency hiding in the halving trick. In round 1, all evaluations lie on the Boolean hypercube: the values come from the witness table and fit in machine words. Round 1 uses only ss/sb operations. But the moment the prover binds $X_1 = r_1$ (a random 256-bit challenge), every subsequent value becomes a full-width field element. From round 2 onward, bb multiplications are unavoidable.

Round 1 accounts for half the total work. Round 2 accounts for a quarter. The most expensive rounds are exactly where values are small. Can we extend the cheap-arithmetic regime beyond a single round?

The idea is *delayed binding*: instead of binding $X_1 = r_1$ immediately, treat the first $v$ variables as symbolic and precompute the $v$-variate polynomial:

$$q(X_1, \ldots, X_v) = \sum_{x' \in \{0,1\}^{n-v}} \prod_{k=1}^d p_k(X_1, \ldots, X_v, x')$$

Every summand has Boolean $x'$ and small witness values, so the entire precomputation uses only ss multiplications. The polynomial $q$ is stored as its evaluations on a $(d+1)^v$ grid. Once computed, the prover answers rounds 1 through $v$ by evaluating $q$ at the received challenges (which does require bb, but only $O((d+1)^v)$ work per round instead of $O(2^{n-i})$). After $v$ rounds, the prover binds all $v$ challenges at once and resumes the standard halving trick on arrays of size $2^{n-v}$.

The optimal window size $v$ balances the ss precomputation cost against the bb savings. For $d = 2$ over 256-bit fields, $v \approx 4$ or 5 rounds. The asymptotic complexity is unchanged, but the concrete runtime drops substantially because the largest rounds (which dominate the geometric series) now use the cheapest arithmetic.

### Streaming provers

Round-batching generalizes beyond the small-value setting. For truly massive computations ($N = 2^{40}$ terms), even $O(N)$ memory becomes prohibitive: a terabyte of field elements. The halving trick is optimal in time but demands linear space.

A *streaming prover* applies round-batching iteratively, processing the input in sequential passes with sublinear memory. Instead of batching only the first $v$ rounds, the streaming prover batches *every* group of rounds into windows. For a window of $\omega$ rounds, the prover scans the relevant terms in one pass, computes a $\omega$-variate polynomial on a $(d+1)^\omega$ grid, answers $\omega$ rounds from it, then moves to the next window. Early windows are small (the input is large). Later windows grow larger (the remaining input shrinks exponentially). A final phase switches to the standard linear-time algorithm.

With a tunable parameter $k \geq 2$, the streaming prover achieves $O(N^{1/k})$ space and $O(d \log d \cdot N \cdot (k + \log \log N))$ time. For $k = 2$: two passes and $O(\sqrt{N})$ memory. This exploits the algebraic structure of sum-check directly, without recursive proof composition.


## Sparse Sums

The halving trick solves the dense case: when all $2^n$ terms are present, we achieve optimal $O(2^n)$ proving time. But many applications involve **sparse** sums, where only $T \ll 2^n$ terms are non-zero, and here the halving trick falls short.

Consider a lookup table with $N = 2^{30}$ possible indices but only $T = 2^{20}$ actual lookups. The halving trick still touches all $2^{30}$ positions, folding arrays of zeros. We're wasting a factor of 1000 in both time and space.

Can the prover exploit sparsity?

### Separable Product Structure

A clarification first: "sparse sum" means the *input data* is sparse (the table on the Boolean hypercube has mostly zeros). The multilinear extension of a sparse vector is typically dense over the continuous domain. Sparsity in the table is what we exploit. Doing so requires a specific factorization.

In lookup arguments and memory-checking protocols, the problem is constructed with a natural variable split: a prefix $p = (x_1, \ldots, x_{n/2})$ encodes an address or row index, and a suffix $s = (x_{n/2+1}, \ldots, x_n)$ encodes a value or column index. The constraints on addresses and values are independent by design, but a sparse selector connects them: most (address, value) pairs are unused, and only $T \ll 2^n$ entries are active. For instance, a memory with $2^{16}$ addresses and $2^{16}$ possible values has $2^{32}$ (address, value) pairs, but a program that performs $T = 10{,}000$ memory accesses touches only $10{,}000$ of them.

This gives the factorization:

$$g(p, s) = \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$$

where $\tilde{a}(p, s)$ is a sparse selector with only $T$ non-zero entries, $\tilde{f}(p)$ depends only on prefix variables (dense, size $2^{n/2}$), and $\tilde{h}(s)$ depends only on suffix variables (dense, size $2^{n/2}$). The separability is what makes sparsity exploitable: to compute an aggregate like $\sum_s \tilde{a}(p,s) \cdot \tilde{h}(s)$, the prover touches only the $T$ positions where $\tilde{a}$ is non-zero.

### Two-Stage Proving

Given the separable product structure, we prove the sum in two stages: an outer sum-check over the prefix variables (addresses) and an inner sum-check over the suffix variables (values) to verify the outer stage's evaluation claim. Each stage handles half the variables, building dense arrays of size $2^{n/2}$ by scanning only the $T$ sparse entries.

**Stage 1 (outer): Sum-check over prefix variables.**

Define aggregated arrays $P$ and $F$, each of size $2^{n/2}$, indexed by prefix bit-vectors $p \in \{0,1\}^{n/2}$:

$$P[p] = \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{h}(s)$$
$$F[p] = \tilde{f}(p)$$

The array $P$ pre-sums all suffix contributions into a single value per prefix. This is the key move: the suffix variables are absorbed *before* the protocol starts, collapsing the original double sum $\sum_p \sum_s$ into a single sum over prefixes $\sum_p$. Computing $P$ requires one pass over the $T$ non-zero entries: for each non-zero $(p, s)$ pair, add $\tilde{a}(p, s) \cdot \tilde{h}(s)$ to $P[p]$.

To see why this is correct, expand the original claim:
$$\sum_{p \in \{0,1\}^{n/2}} \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s) = \sum_{p \in \{0,1\}^{n/2}} \tilde{f}(p) \cdot \underbrace{\sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{h}(s)}_{= P[p]}$$

So proving the original sum reduces to proving $\sum_p \tilde{P}(p) \cdot \tilde{F}(p)$, a sum-check with only $n/2$ variables. Here $\tilde{P}$ and $\tilde{F}$ are the multilinear extensions of arrays $P$ and $F$.

Run the dense halving algorithm on these $2^{n/2}$-sized arrays. Time: $O(T)$ to build $P$ from sparse entries, plus $O(2^{n/2})$ for the dense sum-check.

**Stage 2 (inner): Sum-check over suffix variables.**

Like any sum-check, Stage 1 ends with a final evaluation claim: "I claim $\tilde{P}(r_p) \cdot \tilde{F}(r_p) = v_1$." The verifier can check $\tilde{F}(r_p)$ via polynomial commitment. But $\tilde{P}(r_p)$ is itself defined as a sum over suffix variables:

$$\tilde{P}(r_p) = \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(r_p, s) \cdot \tilde{h}(s)$$

This is where Stage 2 comes in: it runs sum-check over the suffix variables to verify this claim. Stage 1 summed out the prefixes; Stage 2 sums out the suffixes. Together they cover all $n$ variables, but each stage operates on arrays of size $2^{n/2}$ instead of $2^n$.

Define arrays $H$ and $Q$, each of size $2^{n/2}$, indexed by suffix bit-vectors $s \in \{0,1\}^{n/2}$:

$$H[s] = \tilde{a}((r_1, \ldots, r_{n/2}), s)$$
$$Q[s] = \tilde{h}(s)$$

Here $H$ is the sparse selector with its prefix fixed to the random challenges: it answers "what is the selector's value at address $(r_p, s)$?" The factor $\tilde{f}(r_p)$ is now a constant (computed once from the dense $F$ array) that multiplies the entire Stage 2 sum.

Computing $H$ requires the MLE interpolation identity: $\tilde{a}(r_p, s) = \sum_{p'} \tilde{a}(p', s) \cdot \widetilde{\text{eq}}(p', r_p)$. For each sparse entry $(p, s)$, we need the Lagrange coefficient $\widetilde{\text{eq}}(p, r_p)$ to weight its contribution to $H[s]$.

(Recall from Chapter 4: $\widetilde{\text{eq}}(\tau, x) = \prod_i (\tau_i x_i + (1-\tau_i)(1-x_i))$ is the multilinear Lagrange basis function, and $\sum_x \widetilde{\text{eq}}(\tau, x) \cdot f(x) = \widetilde{f}(\tau)$.)

A naive approach computes each $\widetilde{\text{eq}}(p, r_p)$ independently in $O(n/2)$ field ops, giving $O(T \cdot n)$ total. But we can do better: precompute *all* $2^{n/2}$ values $\widetilde{\text{eq}}(p, r_p)$ for every Boolean $p$ in $O(2^{n/2})$ time using the product structure of $\widetilde{\text{eq}}$. Then each sparse entry requires only a table lookup plus one multiplication. Total: $O(2^{n/2})$ for precomputation, $O(T)$ for the pass over sparse entries.

Run the dense halving algorithm on $H$ and $Q$ for the remaining $n/2$ rounds. Time: $O(2^{n/2})$ for precomputing $\widetilde{\text{eq}}$ values, $O(T)$ to accumulate into $H$, plus $O(2^{n/2})$ for the dense sum-check.

The structure is two chained sum-checks:

1. **Stage 1** ($n/2$ rounds): proves the sum equals $H$, ends with evaluation claim about $\tilde{P}(r_p)$
2. **Stage 2** ($n/2$ rounds): proves that evaluation claim, ends with evaluation of $\tilde{a}(r_p, r_s)$ and $\tilde{h}(r_s)$

Together: $n/2 + n/2 = n$ rounds, matching the original $n$-variable sum-check. But prover work is only:
$$O(T + 2^{n/2})$$

Two passes over $T$ sparse terms (one per stage), plus two $2^{n/2}$-sized dense sum-checks. With appropriate parameters, this can be much less than $O(2^n)$.

### Worked Example: Sparse Sum with $N = 16$, $T = 3$

Consider a table of size $N = 16$ (so $n = 4$ variables), but only $T = 3$ entries are non-zero. We want to prove:
$$H = \sum_{(p, s) \in \{0,1\}^4} \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$$

where $p = (x_1, x_2)$ is the 2-bit prefix and $s = (x_3, x_4)$ is the 2-bit suffix.

Suppose the only non-zero entries are:

| Index | Prefix $p$ | Suffix $s$ | $\tilde{a}(p,s)$ | $\tilde{f}(p)$ | $\tilde{h}(s)$ | Product |
|-------|------------|------------|------------------|----------------|----------------|---------|
| 5 | $(0,1)$ | $(0,1)$ | 3 | 2 | 4 | 24 |
| 9 | $(1,0)$ | $(0,1)$ | 5 | 1 | 4 | 20 |
| 14 | $(1,1)$ | $(1,0)$ | 2 | 3 | 7 | 42 |

True sum: $H = 24 + 20 + 42 = 86$.

A dense approach would store all 16 entries and fold arrays of size 16 → 8 → 4 → 2 → 1, touching all 16 positions even though 13 are zero. The sparse two-stage approach avoids this.

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

To build $H$, first precompute the Lagrange table for all 4 Boolean prefixes:

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

This multilinear view differs from the QAP approach in Chapter 12 (Groth16). There, R1CS matrices become univariate polynomials via Lagrange interpolation over roots of unity. The constraint $Az \circ Bz = Cz$ transforms into a polynomial divisibility condition: $A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$, where $Z_H$ is the vanishing polynomial over the evaluation domain. Proving satisfaction means exhibiting the quotient $H(X)$.

Spartan takes a different path. Instead of interpolating over roots of unity, it interprets vectors and matrices as multilinear extensions over the Boolean hypercube. Instead of checking divisibility by a vanishing polynomial, it checks that an error polynomial evaluates to zero on all Boolean inputs, via sum-check. No quotient polynomial, no FFT, no roots of unity. Just multilinear algebra and sum-check.

Both approaches reduce R1CS to polynomial claims. QAP reduces to divisibility; Spartan reduces to vanishing on the hypercube. The sum-check approach avoids the $O(n \log n)$ FFT costs and the trusted setup of pairing-based SNARKs, at the cost of larger proofs (logarithmic in the constraint count rather than constant).

### The Zero-on-Hypercube Reduction

Here is Spartan's key insight: checking that $g$ vanishes on the Boolean hypercube reduces to a single sum-check. The technique works for any polynomial, not just R1CS errors.

**The problem:** We want to verify that $g(x) = 0$ for all $x \in \{0,1\}^{\log m}$.

A natural first attempt: prove $\sum_{x \in \{0,1\}^n} g(x) = 0$ via sum-check. If $g$ vanishes on the hypercube, this sum is indeed zero. But the converse fails: if $g(0,0) = 5$ and $g(0,1) = -5$ with $g(1,0) = g(1,1) = 0$, then $\sum_x g(x) = 0$ despite $g$ being nonzero at two points. Positive and negative values cancel. A bare sum cannot distinguish "all zeros" from "zeros that happen to add up."

The fix is to weight each term with a pseudorandom coefficient so that accidental cancellation becomes overwhelmingly unlikely. Recall from Chapter 4 the equality polynomial $\widetilde{\text{eq}}: \mathbb{F}^n \times \mathbb{F}^n \to \mathbb{F}$:
$$\widetilde{\text{eq}}(\tau, x) = \prod_{i=1}^{n} \left(\tau_i x_i + (1-\tau_i)(1-x_i)\right)$$

On Boolean inputs, each factor equals 1 when $\tau_i = x_i$ and 0 when they differ, so the product is the indicator $\mathbf{1}[\tau = x]$. The formula extends smoothly to all field elements: this is the multilinear extension of the equality indicator over $\{0,1\}^n \times \{0,1\}^n$. By the MLE evaluation formula (Chapter 4), $\sum_x \widetilde{\text{eq}}(\tau, x) \cdot f(x) = \tilde{f}(\tau)$ for any $f$ with multilinear extension $\tilde{f}$.

**The reduction:** Sample random $\tau \in \mathbb{F}^{\log m}$ and check:
$$\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$$

This sum is a random linear combination of $\{g(x)\}_{x \in \{0,1\}^n}$, with coefficients determined by $\tau$. If every $g(x) = 0$, the sum is trivially zero. If even one $g(x^*) \neq 0$, the sum is nonzero with high probability because the pseudorandom weights prevent cancellation. The equality polynomial turns "check $2^n$ values are all zero" into "check one random linear combination is zero."

We can bound the probability that a cheating prover passes this check. Define $Q(\tau) = \sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x) = \tilde{g}(\tau)$. Let $\text{ZERO}(g) := \forall x \in \{0,1\}^n, g(x) = 0$. Then:
$$\Pr_{\tau \leftarrow \mathbb{F}^n}\left[\tilde{g}(\tau) = 0 \mid \neg\text{ZERO}(g)\right] \leq \frac{n}{|\mathbb{F}|}$$
*Proof.* If $\neg\text{ZERO}(g)$, then $\tilde{g}$ is a nonzero multilinear polynomial (since $\tilde{g}(x) = g(x) \neq 0$ for some Boolean $x$). A nonzero multilinear polynomial has total degree at most $n$. By Schwartz-Zippel, a nonzero polynomial of degree $d$ over $\mathbb{F}$ has at most $d \cdot |\mathbb{F}|^{n-1}$ roots in $\mathbb{F}^n$. Thus the probability of hitting a root is at most $n \cdot |\mathbb{F}|^{n-1} / |\mathbb{F}|^n = n/|\mathbb{F}|$. $\square$

This reduces "check $g$ vanishes on $2^n$ points" to "run sum-check on one random linear combination and verify it equals zero."

### Spartan's outer sum-check

1. **Verifier sends** random $\tau \in \mathbb{F}^{\log m}$
2. **Prover claims** $\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$, where $g(x) = \left(\sum_y \tilde{A}(x, y) \tilde{z}(y)\right) \cdot \left(\sum_y \tilde{B}(x, y) \tilde{z}(y)\right) - \sum_y \tilde{C}(x, y) \tilde{z}(y)$
3. **Run sum-check** on this claim

At the end, the verifier holds a random point $r \in \mathbb{F}^{\log m}$ and needs to evaluate $g(r)$. This requires three matrix-vector products: $\sum_y \tilde{A}(r, y) \tilde{z}(y)$, $\sum_y \tilde{B}(r, y) \tilde{z}(y)$, and $\sum_y \tilde{C}(r, y) \tilde{z}(y)$.

### Spartan's inner sum-checks

Each of these is itself a sum over the hypercube, requiring three more sum-checks. But now the sums are over $y$, and the polynomials have the form $\tilde{M}(r, y) \cdot \tilde{z}(y)$ for the fixed $r$ from the outer sum-check.

After running these three inner sum-checks (which can be batched into one using random linear combinations), the verifier holds a random point $s \in \mathbb{F}^{\log n}$ and needs to check:

- $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$: evaluations of the matrix MLEs
- $\tilde{z}(s)$: evaluation of the witness MLE

The matrix evaluations are handled by SPARK (below). The witness evaluation $\tilde{z}(s)$ is where polynomial commitments enter: the prover opens the committed $\tilde{z}$ at the random point $s$, and the verifier checks the opening proof.

This is the full reduction: R1CS satisfaction → zero-on-hypercube (outer sum-check) → matrix-vector products (inner sum-checks) → point evaluations (polynomial commitment openings).

### Handling sparse matrices with SPARK

The inner sum-checks end with evaluation claims: the verifier needs $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$ at the random points $(r, s) \in \mathbb{F}^{\log m} \times \mathbb{F}^{\log n}$ produced by the protocol. But the matrices $A$, $B$, $C$ are $m \times n$, and a dense representation costs $O(mn)$ space. Committing to them naively would dominate the entire protocol.

R1CS matrices are sparse. A circuit with $m$ constraints typically has only $O(m)$ non-zero entries total, not $O(mn)$. A sparse matrix with $T$ non-zero entries can be stored as a list of $(i, j, v)$ tuples at $O(T)$ cost. The question is how to evaluate the matrix MLEs at $(r, s)$ from this sparse representation.

Applying the MLE evaluation formula to the bivariate function $M(i,j)$ gives:
$$\tilde{M}(r_x, r_y) = \sum_{(i,j) \in \{0,1\}^{\log m} \times \{0,1\}^{\log n}} M(i,j) \cdot \widetilde{\text{eq}}(i, r_x) \cdot \widetilde{\text{eq}}(j, r_y)$$

Since $M(i,j) = 0$ for most entries, this simplifies to a sum over only the $T$ non-zero entries:
$$\tilde{M}(r_x, r_y) = \sum_{(i,j): M(i,j) \neq 0} M(i,j) \cdot \widetilde{\text{eq}}(i, r_x) \cdot \widetilde{\text{eq}}(j, r_y)$$

For each non-zero entry $(i, j, v)$, we need $\widetilde{\text{eq}}(i, r_x)$ and $\widetilde{\text{eq}}(j, r_y)$. Computing $\widetilde{\text{eq}}(i, r_x)$ directly from the formula $\prod_k (i_k \cdot (r_x)_k + (1-i_k)(1-(r_x)_k))$ costs $O(\log m)$. Over $T$ entries, total cost: $O(T \log m)$.

SPARK reduces this to $O(T)$ by precomputing lookup tables.

1. **Precompute row weights.** Build a table $E_{\text{row}}[i] = \widetilde{\text{eq}}(i, r_x)$ for all $i \in \{0,1\}^{\log m}$. This costs $O(m)$ using the standard MLE evaluation algorithm (stream through bit-vectors, accumulate products).

2. **Precompute column weights.** Build a table $E_{\text{col}}[j] = \widetilde{\text{eq}}(j, r_y)$ for all $j \in \{0,1\}^{\log n}$. Cost: $O(n)$.

3. **Evaluate via lookups.** Initialize a running sum to zero. For each non-zero entry $(i, j, v)$, look up $E_{\text{row}}[i]$ and $E_{\text{col}}[j]$, then add $v \cdot E_{\text{row}}[i] \cdot E_{\text{col}}[j]$ to the running sum. After processing all $T$ entries, the sum equals $\tilde{M}(r_x, r_y)$. Cost: $O(T)$.

Total: $O(m + n + T)$, linear in the sparse representation size.

The remaining question is who checks the lookups. The prover claims to have read the correct $\widetilde{\text{eq}}$ values from the precomputed tables, but the verifier does not have those tables. SPARK resolves this with a *memory-checking argument*: a protocol that verifies the prover's reads against the table contents by comparing random fingerprints of both. If any lookup is incorrect, the fingerprints mismatch with high probability. Chapter 21 develops this technique in full. The overhead is $O(\log T)$ in proof size and verification time, preserving SPARK's linear prover efficiency.

### The full Spartan protocol

Putting it together:

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

With $T$ non-zero matrix entries, total prover work is $O(m + n + T)$, linear in the instance size. No trusted setup is required when using IPA or FRI as the polynomial commitment.

### Why This Matters

Step back and consider what we've built. Spartan proves R1CS satisfaction, the standard constraint system for zkSNARKs, using only sum-check and polynomial commitments. No univariate polynomial encodings (like PLONK's permutation argument). No pairing-based trusted setup (like Groth16). No PCP constructions (like early STARKs).

The architecture is minimal: multilinear polynomials, sum-check, commitment scheme. Three ideas, combined cleanly. This simplicity is not merely aesthetic. It's the reason Spartan became the template for subsequent systems. Lasso added lookup arguments; Jolt extended further to prove virtual machine execution. Each built on the same foundation.

Notice the graph structure emerging. Spartan has two levels: an outer sum-check (over constraints) and inner sum-checks (over matrix-vector products). The outer sum-check ends with a claim; the inner sum-checks prove that claim. This is exactly the depth-two graph from the remark at the chapter's start. More complex protocols like Lasso (for lookups) and Jolt (for full RISC-V execution) extend this graph to dozens of nodes across multiple stages, but the pattern remains: sum-checks reducing claims to other sum-checks, bottoming out at committed polynomials.

When a construction is this simple, it becomes a building block for everything that follows.



## The PCP Detour and Sum-Check's Return

Now that we've seen Spartan's architecture (sum-check plus commitments, nothing more), the historical question becomes pressing: why did the field spend two decades pursuing a different path?

### The PCP path

In 1990, sum-check arrived. Two years later, the PCP theorem landed: every NP statement has a proof checkable by reading only a constant number of bits. This captured the field's imagination completely.

The PCP theorem seemed to obsolete sum-check. Why settle for logarithmic verification when you could have constant-query verification? Kilian showed how to compile PCPs into succinct arguments: commit to the PCP via Merkle tree, let the verifier query random locations, authenticate responses with hash paths. This became *the* template for succinct proofs.

Sum-check faded into the background, remembered as a stepping stone rather than a destination.

### The redundant indirection

In hindsight, the PCP-based pipeline contained a redundancy. The PCP theorem transforms an interactive proof into a *static* proof string that the verifier queries non-adaptively. Interaction removed. But the proof string is enormous, so Kilian's construction has the prover commit to it via a Merkle tree and the verifier interactively requests query locations. Interaction reintroduced. Then Fiat-Shamir makes the protocol non-interactive. Interaction removed again.

The transformations: IP → PCP (remove interaction) → Kilian argument (add interaction back) → Fiat-Shamir (remove interaction again). Two removals of interaction. If Fiat-Shamir handles the final step anyway, why not apply it directly to the original interactive proof based on sum-check?

### The return

Starting around 2018, the missing pieces fell into place: fast proving algorithms (the halving trick, sparse sums) and polynomial commitment schemes (KZG, FRI, IPA) that could handle multilinear polynomials directly. A wave of systems returned to sum-check:

- **Hyrax** (2018), **Libra** (2019): early sum-check-based SNARKs with linear-time provers
- **Spartan** (2020): sum-check for R1CS without trusted setup
- **HyperPlonk** (2023): sum-check meets Plonkish arithmetization
- **Lasso/Jolt** (2023-24): sum-check plus lookup arguments for zkVMs
- **Binius** (2024): sum-check over binary fields

The pattern: sum-check as the core interactive proof, polynomial commitments for cryptographic binding, Fiat-Shamir applied once.

### What the PCP path got right

The architectural redundancy does not mean the PCP path was wasted. It produced STARKs, which remain among the most deployed proof systems. STARKs compile an IOP (the AIR + FRI pipeline from Chapter 15) using only hash functions, no elliptic curves. This gives them a property that sum-check-based systems struggle to match: post-quantum security out of the box.

Sum-check itself is information-theoretic and quantum-safe. But it produces evaluation claims that must be resolved by a polynomial commitment scheme, and the most mature multilinear PCS options (KZG, IPA, Dory) rely on discrete-log assumptions that Shor's algorithm breaks. Post-quantum alternatives exist: hash-based multilinear commitments and lattice-based schemes are active areas of research, but they remain less mature than the FRI-based commitments that STARKs use today.

The practical landscape reflects this. For applications where post-quantum security matters now (long-lived proofs, regulatory environments, sovereign infrastructure), STARKs offer a proven path. For applications where prover speed dominates and classical assumptions suffice, sum-check-based systems like Jolt and Binius achieve prover times closer to the witness computation itself. The two approaches are converging: Binius uses sum-check over binary fields with FRI-based commitments, combining both traditions. Chapter 20 develops the STARK-side optimization story in parallel with this chapter, showing how small-field techniques, NTT optimization, and FRI batching close the gap between STARK proving and witness computation from the other direction.





## Key Takeaways

1. **The halving trick achieves $O(N)$ prover time.** Fold evaluation tables after each challenge: $N \to N/2 \to N/4 \to \ldots$ via multilinear interpolation. Total work is the geometric series $N + N/2 + \cdots = O(N)$.

2. **Not all field multiplications are equal.** Over 256-bit fields, bb multiplications are roughly 8x more expensive than sb and 30x more expensive than ss. Delayed reduction amortizes modular reduction across linear combinations. These distinctions dominate wall-clock time despite being invisible in $O(\cdot)$ notation.

3. **High-degree products cost $O(d \log d)$, not $O(d^2)$.** A divide-and-conquer algorithm splits $d$ factors in half, recurses, extrapolates via Lagrange (sb work), and multiplies pointwise (bb work). Only the pointwise step is expensive.

4. **Small-value round-batching exploits the geometric series.** The first $v$ rounds dominate total work and operate on small witness values. Treating these variables as symbolic replaces bb multiplications with ss, reducing the concrete cost of the most expensive portion of the protocol.

5. **Streaming provers trade passes for memory.** Applying round-batching iteratively gives $O(N^{1/k})$ space for any $k \geq 2$, without recursive proof composition.

6. **Sparse sums exploit separable structure.** When the polynomial factors into a sparse selector and dense prefix/suffix components, two chained sum-checks over $n/2$ variables each achieve $O(T + 2^{n/2})$ cost instead of $O(2^n)$.

7. **Spartan reduces R1CS to sum-check.** The zero-on-hypercube reduction converts "$g$ vanishes on $\{0,1\}^n$" into a single sum-check weighted by $\widetilde{\text{eq}}(\tau, x)$, which acts as a random linear combination preventing cancellation. An outer sum-check ($O(m)$) plus batched inner sum-checks ($O(n)$) plus SPARK ($O(T)$) handle the full R1CS constraint system.

8. **Sum-check graphs structure complex protocols.** Each sum-check ends with evaluation claims. If the polynomial is committed, open it. If it is virtual, another sum-check proves the evaluation. The result is a DAG where depth determines sequential stages and width enables batching. Chapter 21 develops this perspective.

9. **The PCP path and the sum-check path are converging.** The IP → PCP → Kilian → Fiat-Shamir pipeline contains an architectural redundancy (interaction removed, reintroduced, removed again). Sum-check + Fiat-Shamir skips this. But the PCP lineage produced STARKs, which offer post-quantum security via hash-based commitments. Sum-check systems need a post-quantum PCS to match, and those remain less mature. Binius bridges both traditions: sum-check over binary fields with FRI-based commitments.

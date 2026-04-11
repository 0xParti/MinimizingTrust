# Chapter 22: The Two Classes of PIOPs

Every modern SNARK, stripped to its essence, follows the same recipe: a Polynomial Interactive Oracle Proof (PIOP), compiled with a Polynomial Commitment Scheme (PCS), made non-interactive via Fiat-Shamir. The PIOP provides information-theoretic security: it would be sound even against unbounded provers if the verifier could magically check polynomial evaluations. The PCS adds cryptographic binding. Fiat-Shamir removes interaction.

But within this unifying framework, two distinct philosophies have emerged. They use different polynomial types, different domains, different proof strategies. They lead to systems with different performance profiles.

Understanding when to use which is not academic curiosity; it shapes every SNARK design decision.

## The Divide

The two paradigms differ in their fundamental approach to constraint verification. At the deepest level, the split is *geometric*: where does your data live?

**Quotienting-based PIOPs** (Groth16, PLONK, STARKs) place data on a **circle**. Evaluation points are roots of unity, cycling around the unit circle in the complex plane. Constraints become questions about divisibility: does the error polynomial vanish on this circular domain? The machinery is algebraic (division, remainder, quotient) and the key algorithm is the FFT, which converts between point-values on the circle and polynomial coefficients.

**Sum-check-based PIOPs** (Spartan, HyperPlonk, Jolt) place data on a **hypercube**. Evaluation points are vertices of the $n$-dimensional Boolean cube $\{0,1\}^n$. Constraints become questions about sums: does the weighted average over all vertices equal zero? The machinery is probabilistic (randomization collapses exponentially many constraints into one) and the key algorithm is the halving trick, which scans data linearly.

For a decade, the circle dominated because its mathematical tools (pairings, FFTs) matured first. But the hypercube has risen recently because it fits better with how computers actually work: bits, arrays, and linear memory scans.

Both achieve the same goal: succinct verification of arbitrary computations. Both ultimately reduce to polynomial evaluation queries. But they arrive there by different paths, and those paths have consequences.

## Historical Arc

The divide between paradigms has a history.

### The PCP Era (1990s-2000s)

The theoretical foundations came from PCPs (Probabilistically Checkable Proofs). These were non-interactive by construction: a single, static proof string that the verifier queries at random positions.

PCPs used univariate polynomials implicitly. The prover encoded the computation as polynomial evaluations; the verifier checked random positions. Soundness came from low-degree testing and divisibility arguments, the ancestors of quotienting.

Merkle trees provided commitment. Kilian showed how to make the proof succinct: hash the full proof, let the verifier query random positions, have the prover open those positions with Merkle paths.

### The SNARK Era (2010s)

Groth16, PLONK, and their relatives refined the quotienting approach. KZG's constant-size proofs made verification blazingly fast: just a few pairings. The trusted setup was an acceptable trade-off for many applications.

These systems dominated deployed ZK applications: Zcash, various rollups, privacy protocols. Quotienting became synonymous with "practical SNARKs."

### The Sum-Check Renaissance (2020s)

Systems like Spartan, Lasso, and Jolt demonstrated that sum-check-based designs achieve the fastest prover times. The key insight, crystallized in Chapter 19: interaction is a resource, and removing it twice (once in the PIOP, once via Fiat-Shamir) is wasteful.

GKR's layer-by-layer virtualization, combined with efficient multilinear PCS, enabled provers to approach linear time. Virtual polynomials slashed commitment costs.

The modern view: quotienting and sum-check are both valid tools. Neither dominates universally. Choose based on your specific application's constraints.



## A Common Task: Proving $a \circ b = c$

To make the comparison concrete, consider the entrywise product constraint:

$$a_i \cdot b_i = c_i \quad \text{for all } i = 1, \ldots, N$$

where $N = 2^n$. The prover has committed to vectors $a, b, c \in \mathbb{F}^N$ and must prove this relationship holds at every coordinate.

This constraint captures half the logic of circuit satisfiability: verifying that gate outputs equal products of gate inputs. (The other half, wiring constraints that enforce copying, we'll address shortly.) Let's trace both paradigms through this single task.

## The Quotienting Path

### Setup

Choose an evaluation domain $H = \{\alpha_1, \ldots, \alpha_N\} \subset \mathbb{F}$ of size $N$. The standard choice: the $N$-th roots of unity, $H = \{1, \omega, \omega^2, \ldots, \omega^{N-1}\}$ where $\omega^N = 1$.

Define univariate polynomials by Lagrange interpolation:

- $\hat{a}(X)$ of degree $< N$: the unique polynomial satisfying $\hat{a}(\alpha_i) = a_i$
- $\hat{b}(X)$ and $\hat{c}(X)$ similarly

These are univariate low-degree extensions of the vectors, anchored at the roots of unity.

### The Key Identity

The constraint $a_i \cdot b_i = c_i$ for all $i$ is equivalent to saying that $\hat{a}(\alpha) \cdot \hat{b}(\alpha) - \hat{c}(\alpha) = 0$ for all $\alpha \in H$.

By the Factor Theorem, a polynomial vanishes on all of $H$ if and only if it's divisible by the vanishing polynomial:

$$Z_H(X) = \prod_{\alpha \in H}(X - \alpha)$$

So the constraint becomes: there exists a polynomial $Q(X)$ such that

$$\hat{a}(X) \cdot \hat{b}(X) - \hat{c}(X) = Q(X) \cdot Z_H(X)$$

The quotient $Q$ is the witness to divisibility.

### The Protocol

1. **Prover commits** to $\hat{a}, \hat{b}, \hat{c}$ using a univariate PCS (typically KZG)
2. **Prover computes** the quotient: $Q(X) = \frac{\hat{a}(X) \cdot \hat{b}(X) - \hat{c}(X)}{Z_H(X)}$
3. **Prover commits** to $Q$
4. **Verifier sends** random challenge $r \in \mathbb{F}$
5. **Prover provides** evaluations $\hat{a}(r), \hat{b}(r), \hat{c}(r), Q(r)$ with opening proofs
6. **Verifier checks**: $\hat{a}(r) \cdot \hat{b}(r) - \hat{c}(r) = Q(r) \cdot Z_H(r)$

### Why Roots of Unity?

For arbitrary $H$, computing $Z_H(r)$ requires $O(N)$ operations: a factor of $(r - \alpha)$ for each element. But when $H$ consists of $N$-th roots of unity:

$$Z_H(X) = X^N - 1$$

The verifier computes $Z_H(r) = r^N - 1$ in $O(\log N)$ time via repeated squaring. This simple structure, an accident of multiplicative group theory, makes quotienting practical. Chapter 13 develops this further: roots of unity also enable FFT-based polynomial arithmetic and the shift structure needed for accumulator checks.

### Soundness

If the constraint fails at some $\alpha_i \in H$, then $\hat{a}(X) \cdot \hat{b}(X) - \hat{c}(X)$ is *not* divisible by $Z_H(X)$. Any claimed quotient $Q$ will fail: the polynomial

$$\hat{a}(X) \cdot \hat{b}(X) - \hat{c}(X) - Q(X) \cdot Z_H(X)$$

is non-zero. By Schwartz-Zippel, a random $r$ catches this with probability at least $1 - (2N-1)/|\mathbb{F}|$ (overwhelming for large fields).

### Cost Analysis

The quotient polynomial has degree at most $2N - 2 - N = N - 2$. Computing it requires polynomial division, typically done via FFT in $O(N \log N)$ time. Committing to $Q$ costs additional PCS work.

The prover's dominant costs: FFT for quotient computation, MSM for commitment.

The hidden cost in univariate systems is not just the $O(N \log N)$ time complexity but the *memory access pattern*. FFTs require "butterfly" operations that shuffle data across the entire memory space: element $i$ interacts with element $i + N/2$, then $i + N/4$, and so on. These non-local accesses cause massive cache misses on modern CPUs. In contrast, sum-check's halving trick scans data linearly (adjacent pairs combine), which is cache-friendly and easy to parallelize across cores. For large $N$, the memory bottleneck often dominates the arithmetic.



## The Sum-Check Path

### Setup

The quotienting approach indexed vectors by roots of unity: $a_i$ at $\omega^i$. Sum-check indexes them by bit-strings instead: $a_w$ for $w \in \{0,1\}^n$, where $N = 2^n$. For $N = 4$: positions $\omega^0, \omega^1, \omega^2, \omega^3$ become $00, 01, 10, 11$. Same data, different addressing scheme.

Define multilinear polynomials, the unique extensions that are linear in each variable:

- $\tilde{a}(x)$: satisfies $\tilde{a}(w) = a_w$ for all $w \in \{0,1\}^n$
- $\tilde{b}(x)$ and $\tilde{c}(x)$ similarly

Where quotienting uses Lagrange interpolation over roots of unity to get univariate polynomials of degree $N-1$, sum-check uses multilinear extension over the hypercube to get $n$-variate polynomials of degree 1 in each variable. Both encodings uniquely determine the original vector; they just live in different polynomial spaces.

### The Key Identity

The constraint $a_w \cdot b_w = c_w$ for all $w \in \{0,1\}^n$ means:

$$\tilde{a}(w) \cdot \tilde{b}(w) - \tilde{c}(w) = 0 \quad \text{for all } w \in \{0,1\}^n$$

Define $g(x) = \tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x)$. We want $g$ to vanish on the hypercube.

Here's the key move: instead of proving divisibility, we take a *random linear combination*. Define:

$$q(r) = \sum_{w \in \{0,1\}^n} \widetilde{\text{eq}}(r, w) \cdot g(w)$$

for verifier-chosen random $r \in \mathbb{F}^n$.

The polynomial $\widetilde{\text{eq}}(r, x)$ is the multilinear extension of the equality predicate: it equals 1 when $x = r$ (on the hypercube) and 0 otherwise. But for general field elements, it acts as a random weighting function:

$$\widetilde{\text{eq}}(r, w) = \prod_{i=1}^{n} (r_i \cdot w_i + (1-r_i)(1-w_i))$$

If any $g(w) \neq 0$, then $q$ is a non-zero polynomial in $r$. By Schwartz-Zippel, $q(r) \neq 0$ with probability at least $1 - n/|\mathbb{F}|$.

### The Protocol

1. **Prover commits** to $\tilde{a}, \tilde{b}, \tilde{c}$ using an MLE-based PCS
2. **Verifier sends** random $r \in \mathbb{F}^n$
3. **Prover and verifier run sum-check** on $\sum_w \widetilde{\text{eq}}(r, w) \cdot g(w)$, claimed to equal 0
4. **Sum-check reduces** to evaluating $\widetilde{\text{eq}}(r, z) \cdot g(z)$ at a random point $z \in \mathbb{F}^n$
5. **Prover provides** $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$ with opening proofs
6. **Verifier computes** $\widetilde{\text{eq}}(r, z)$ directly (just $n$ multiplications) and checks that $\widetilde{\text{eq}}(r, z) \cdot (\tilde{a}(z) \cdot \tilde{b}(z) - \tilde{c}(z))$ equals the claimed final value

### Cost Analysis

Sum-check proving via the halving trick (Chapter 19) takes $O(N)$ time for dense polynomials. The prover provides three opening proofs, no quotient commitment needed.

The prover's dominant costs: sum-check field operations, PCS opening proofs.



## The Comparison

| Aspect | Quotienting | Sum-Check |
|--------|-------------|-----------|
| **Polynomial type** | Univariate, degree $< N$ | Multilinear, $n$ variables |
| **Domain** | Roots of unity $H$ | Boolean hypercube $\{0,1\}^n$ |
| **Constraint verification** | $Z_H$ divides error | Random linear combination |
| **Extra commitment** | Quotient $Q(X)$ | None |
| **Prover time** | $O(N \log N)$ for FFT | $O(N)$ dense, $O(T)$ sparse |
| **Interaction** | 1 round (after commitment) | $n$ rounds (sum-check) |
| **Sparsity handling** | Quotient typically dense | Natural via prefix-suffix |

> **Signal Processing vs. Statistics**
>
> The two paradigms embody different engineering mindsets.
>
> **Quotienting is signal processing.** It treats data like a sound wave. To check constraints, it runs a Fourier Transform (FFT) to convert the signal into a frequency domain where errors stick out like a sour note. Divisibility by $Z_H$ is the test: a clean signal has no energy at the forbidden frequencies.
>
> **Sum-check is statistics.** It treats data like a population. To check constraints, it takes a random weighted average (expected value) over the whole population. If the average is zero, the population is healthy. No frequency analysis required, just a linear scan.
>
> This explains the performance gap. FFTs require "shuffling" data across the entire memory space (butterfly operations), which causes cache misses on modern CPUs. Sum-check scans data linearly, which is cache-friendly and trivially parallelizable.

The quotient polynomial is the key difference. Quotienting requires it; sum-check doesn't. For dense constraints, this may not matter much: the quotient is proportional to the constraint size. But for sparse constraints, the quotient can be far larger than the non-zero terms, wasting commitment effort.



## Wiring Constraints: The Second Half

The $a \circ b = c$ constraint checks that gate computations are correct. But a circuit also has *wiring*: the output of gate $j$ might feed into gates $k$ and $\ell$ as inputs. We must verify that copied values match, that $a_k = c_j$ and $b_\ell = c_j$.

This is the "copy constraint" problem, and the two paradigms handle it differently.

### Quotienting: Permutation Arguments

PLONK-style systems encode wiring as a permutation. Consider all wire values arranged in a single vector. The permutation $\sigma$ maps each wire position to the position that should hold the same value.

The constraint: $a_{\sigma(i)} = a_i$ for all $i$.

PLONK verifies this through a grand product argument (Chapter 13). For each wire position, form the ratio:

$$\frac{a_i + \beta \cdot i + \gamma}{a_i + \beta \cdot \sigma(i) + \gamma}$$

If the permutation constraint is satisfied, multiplying all these ratios gives 1: a massive cancellation of numerators and denominators.

Proving this grand product requires an accumulator polynomial: $z_i = \prod_{j \leq i} (\text{ratio}_j)$. The prover commits to this accumulator and proves it satisfies the recurrence relation via... quotienting. An additional quotient polynomial for the accumulator constraint.

### Sum-Check: Memory Checking

Sum-check systems take a different view: wiring is memory access.

Each wire value is "written" to a memory cell when it's computed. Each wire position that uses that value "reads" from the cell. The constraint: reads return the values that were written.

The verification reduces to sum-check over access patterns. For each read at position $j$, define an access indicator $ra(k, j) = 1$ if the read targets cell $k$, and 0 otherwise. The read value must satisfy:

$$rv_j = \sum_k ra(k, j) \cdot f(k)$$

where $f(k)$ is the value stored at cell $k$. This equation says: "the value I read equals the sum over all cells, but the indicator zeroes out everything except the cell I actually accessed."

For read-only tables (like bytecode or lookup tables), $f(k)$ is fixed. For read-write memory (like registers or RAM), $f(k)$ becomes $f(k, j)$: the value at cell $k$ at time $j$, reconstructed from the history of writes. Chapter 21 shows how this state table can be virtualized: rather than committing to the full $K \times T$ matrix, commit only to write addresses and value increments, then compute the state implicitly via sum-check.

The access indicator matrix $ra$ is sparse (each read touches exactly one cell) and decomposes via tensor structure, making commitment cost proportional to operations rather than memory size.

### Wiring: The Comparison

| Aspect | Permutation Argument | Memory Checking |
|--------|---------------------|-----------------|
| **Abstraction** | Wires as permutation cycles | Wires as memory cells |
| **Core mechanism** | Grand product of ratios | Sum over access indicators |
| **Extra commitment** | Accumulator polynomial $Z$ | Access matrices (tensor-decomposed) |
| **Structured access** | No special benefit | Exploits sparsity naturally |
| **Read-write memory** | Requires separate handling | Unified with wiring |

Notice the algebraic shift: permutation arguments use **products** (accumulators that multiply ratios), while memory checking uses **sums** (access counts weighted by values). In finite fields, sums are generally cheaper than products. Sums linearize naturally (the sum of two access patterns is the combined access pattern), while products require careful accumulator bookkeeping. This is why memory checking integrates more cleanly with sum-check's additive structure.

For circuits with random wiring, both approaches have similar cost. The permutation argument requires an accumulator commitment; memory checking requires access matrices. The difference emerges with structure: repeated reads from the same cell, locality in access patterns, or mixing read-only and read-write data all favor the memory checking view.



## The PCS Connection

Each PIOP paradigm pairs naturally with a matching polynomial commitment scheme.

**Univariate PCS for quotienting:**

- *KZG*: Single group element commitment, constant-size opening proofs, requires pairing-friendly curves and trusted setup
- *FRI*: Merkle-based, logarithmic proofs, transparent (no trusted setup), post-quantum candidate

Both work over the same roots-of-unity domain. The FFT is literally polynomial evaluation at roots of unity (Chapter 5), serving both the PIOP (quotient computation in evaluation form) and the PCS (commitment requires both forms).

**Multilinear PCS for sum-check:**

- *Bulletproofs/IPA*: Logarithmic proofs via recursive folding, no trusted setup, no pairings needed
- *Dory*: Pairing-based with efficient batch opening
- *Hyrax/Ligero*: Merkle and linear-code based

These commit to evaluation tables over $\{0,1\}^n$ and open at arbitrary points in $\mathbb{F}^n$.

In principle, any PIOP can use any PCS of the matching polynomial type. In practice, the best systems co-optimize PIOP and PCS: choices in one influence efficiency in the other.



## Choosing a Paradigm

The comparisons above reveal a pattern. Quotienting and sum-check differ not just in mechanism but in what they optimize for.

**Quotienting excels when structure is fixed and dense.** The quotient polynomial costs $O(N)$ regardless of how many constraints actually matter. FFT runs in $O(N \log N)$ regardless of sparsity. The permutation argument handles any wiring pattern equally. This uniformity is a strength when constraints fill the domain densely and circuit topology is known at compile time. Small circuits with degree-2 or degree-3 constraints, existing infrastructure with optimized KZG and FFT libraries, applications where proof size matters more than prover time: these favor quotienting. Chapter 20 shows how small-field NTT optimization, DEEP-ALI, and batched FRI reduce the concrete cost of this $O(N \log N)$ path to the point where it competes with sum-check for structured workloads like hashing.

**Sum-check excels when structure is dynamic and sparse.** The prefix-suffix algorithm runs in $O(T)$ for $T$ non-zero terms, ignoring the $N - T$ zeros entirely. Memory checking handles structured access patterns (locality, repeated reads) more efficiently than permutation arguments. Virtual polynomials let you skip commitment entirely for intermediate values. This adaptivity matters for large circuits with billions of gates, memory-intensive computation with lookup arguments and batch evaluation, and zkVMs where the constraint pattern depends on the program being executed.

The wiring story reinforces this. Permutation arguments treat all wire patterns uniformly: a random scramble costs the same as a structured dataflow. Memory checking adapts: tensor decomposition exploits address structure, virtualization skips commitment to state tables, and read-only versus read-write falls out of the same framework.

A useful heuristic: if you know exactly what your circuit looks like at compile time and it fits comfortably in memory, quotienting's simplicity wins. If your circuit's shape depends on runtime data, or if you're pushing toward billions of constraints, sum-check's adaptivity wins.


## Key Takeaways

1. **The core distinction.** Quotienting proves "$Z_H$ divides the error polynomial" via a committed quotient. Sum-check proves "the weighted sum equals zero" via interactive reduction. Same goal, different algebra.

2. **Domain shapes computation.** Roots of unity give FFT and simple $Z_H(X) = X^N - 1$. The Boolean hypercube gives tensor structure and the halving trick. Each domain has algebraic gifts; the proof strategy exploits them.

3. **The quotient is overhead.** Every quotienting proof commits to $Q(X)$. Sum-check needs no extra commitment beyond the original polynomials. For sparse constraints, this difference is dramatic.

4. **Sparsity changes everything.** Quotienting costs $O(N \log N)$ regardless of how many constraints are non-trivial. Sum-check costs $O(T)$ for $T$ non-zero terms. When $T \ll N$, sum-check wins by orders of magnitude.

5. **Wiring has two faces.** Quotienting encodes copy constraints as permutations, verified via a grand product accumulator. Sum-check encodes them as memory access, verified via sparse indicator matrices. Same constraint, different abstractions.

6. **PIOP and PCS co-evolve.** Univariate PIOPs pair with KZG or FRI over roots of unity. Multilinear PIOPs pair with Bulletproofs, Dory, or Hyrax over the hypercube. Mixing paradigms is possible but rarely optimal.

7. **Virtualization is sum-check's superpower.** Any polynomial computable from committed polynomials can be "virtual": defined implicitly, never committed. Quotienting requires explicit commitment to every polynomial that appears in a divisibility check.

8. **The design heuristic.** Fixed circuit, dense constraints, proof size matters: quotienting. Dynamic structure, sparse constraints, prover speed matters: sum-check. Neither dominates; choose based on your bottleneck.

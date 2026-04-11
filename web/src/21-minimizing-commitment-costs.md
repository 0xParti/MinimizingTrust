# Chapter 21: Minimizing Commitment Costs

> *This chapter lives at the frontier. The techniques here, some from papers published in 2024 and 2025, represent the current edge of what's known about fast proving. We assume comfort with polynomial commitments (Chapter 9), sum-check (Chapter 3), and the memory checking ideas from Chapter 14. First-time readers may find themselves reaching for earlier chapters often; that's expected. The reward for persisting is a view of how the fastest SNARKs actually work.*

Profile any modern SNARK prover and the same pattern appears. The proving algorithm touches each constraint once. The information-theoretic protocol is near-optimal. Yet wall-clock time is dominated by something else entirely: polynomial commitments.

For elliptic curve-based systems, the bottleneck is multi-scalar multiplication (MSM): computing $\sum_i s_i \cdot G_i$ where each $s_i$ is a scalar and each $G_i$ is a curve point. A single curve exponentiation costs roughly 3,000 field multiplications. An MSM over $N$ points costs about $N / \log N$ exponentiations. For a polynomial of degree $10^6$, commitment alone requires $\approx 3 \times 10^8$ field operations, while the proving algorithm might run in $10^7$. The cryptography dwarfs the algebra. For hash-based systems (STARKs, FRI), the analogous bottleneck is Merkle hashing and FRI's repeated polynomial evaluations. The numbers differ but the pattern is the same. Chapter 20 addresses the STARK-side optimization story, where the bottleneck concentrates in NTT and hashing rather than commitments.

This chapter focuses on the elliptic curve setting, where sum-check-based minimization techniques apply most directly.

This observation crystallizes into a design principle: **commit to as little as possible**. Not zero (some commitment is necessary for succinctness) but the absolute minimum required for soundness.

This chapter develops the techniques that make minimization possible. Together with fast sum-check proving, they form the foundation of the fastest modern SNARKs.



## The Two-Stage Paradigm

Every modern SNARK decomposes into two phases. First, the prover *commits*: to the witness, to intermediate values, to auxiliary polynomials that will help later proofs. Second, the prover *proves well-formed*: demonstrates that these committed objects satisfy the required constraints.

Both phases cost time. And here's the trap: **more commitment means more proving**. Every committed object must later be shown well-formed. If you commit to a polynomial, you'll eventually need to prove something about it: its evaluations, its degree, its relationship to other polynomials. Each such proof compounds the cost.

The obvious extremes are both suboptimal. Commit nothing, and proofs cannot be succinct: the verifier must read the entire witness. Commit everything, and you drown in overhead: each intermediate value requires cryptographic operations and well-formedness proofs.

The art lies in the middle: commit to exactly what enables succinct verification. No more.

### Untrusted Advice

Sometimes the sweet spot involves committing to *more* than the bare witness. This seems paradoxical. Didn't we just say to minimize commitment? But there's a trade-off: additional committed values can simplify constraint checking enough to pay for their commitment cost.

Consider division. Proving "I correctly computed $a/b$" by directly checking division is expensive, since division isn't a native operation in our constraint systems. But watch what happens with a small addition:

1. The prover commits to quotient $q$ and remainder $R$ alongside the witness
2. The prover proves $a = q \cdot b + R$ and $R < b$

Multiplication and comparison are simpler than division. The extra commitments enable simpler constraints: a net win.

This is "untrusted advice," where the prover volunteers additional information that (if verified correct) accelerates the overall proof. The verifier doesn't trust this advice blindly; the constraints ensure it's valid.

The trade-off is specific: we pay for Commitments (cryptography) to save on Degree (arithmetic). Extra committed values mean extra MSM cost, but the constraints that check them can be lower-degree. Since high-degree constraints are expensive to prove via sum-check, the exchange often favors more commitments and simpler constraints.

The pattern generalizes. Any computation with an efficient verification shortcut benefits:

**Square roots.** To prove $y = \sqrt{x}$, the prover commits to $y$ and proves $y^2 = x$ and $y \geq 0$. One multiplication plus a range check, rather than implementing the square root algorithm in constraints.

**Sorting.** To prove a list is sorted, the prover commits to the sorted output and proves: (1) it's a permutation of the input (via permutation argument), and (2) adjacent elements satisfy $a_i \leq a_{i+1}$. Linear comparisons rather than $O(n \log n)$ sorting constraints.

**Inverses.** To prove $y = x^{-1}$, commit to $y$ and check $x \cdot y = 1$. Field inversion (expensive to express directly) becomes a single multiplication.

**Exponentiation.** To prove $y = g^x$, the prover commits to $y$ and all intermediate values from the square-and-multiply algorithm: $r_0 = 1, r_1, r_2, \ldots, r_k = y$. Each step satisfies $r_{i+1} = r_i^2$ (if bit $x_i = 0$) or $r_{i+1} = r_i^2 \cdot g$ (if $x_i = 1$). Verifying $k$ quadratic constraints is far cheaper than expressing the full exponentiation logic.

The economics are clear: if verifying a result costs less than computing it, let the prover compute and commit, then let the verifier check. The prover bears the computational burden; the constraint system bears only the verification burden.

This division of labor is the essence of succinct proofs, now applied within the proof system itself.



## Batch Evaluation Arguments

Suppose the prover has committed to addresses $(y_1, \ldots, y_T)$ and claimed outputs $(z_1, \ldots, z_T)$. A public function $f: \{0,1\}^\ell \to \mathbb{F}$ is known to all. The prover wants to demonstrate:

$$z_1 = f(y_1), \quad z_2 = f(y_2), \quad \ldots, \quad z_T = f(y_T)$$

One approach: prove each evaluation separately. That's $T$ independent proofs, linear in the number of evaluations. Can we do better?

The batch evaluation perspective reveals a connection: this is read-only memory checking. Think of $f$ as a memory array indexed by $\ell$-bit addresses. Each $(y_i, z_i)$ pair is a read operation: "I read value $z_i$ from address $y_i$." The prover claims all $T$ reads are consistent with the memory $f$.

One approach uses lookup arguments (Chapter 14): prove that each $(y_i, z_i)$ pair exists in the table $\{(x, f(x)) : x \in \{0,1\}^\ell\}$. But sum-check offers a more direct path that exploits the structure of the problem.

### Three Flavors of Batching

Before diving into sum-check, let's map the batching landscape. The term "batching" appears throughout this book, but it means different things in different contexts.

**Approach 1: Batching verification equations.** The simplest form. Suppose you have $T$ equations to check: $L_1 = R_1, \ldots, L_T = R_T$. Sample a random $\alpha$ and check the single combined equation $\sum_j \alpha^j L_j = \sum_j \alpha^j R_j$. By Schwartz-Zippel, if any original equation fails, the combined equation fails with high probability. This reduces $T$ verification checks to one.

Chapter 2 uses this for Schnorr batch verification. Chapter 13 uses it to combine PLONK's constraint polynomials. Chapter 15 uses it to merge STARK quotients. The pattern is ubiquitous: random linear combination collapses many checks into one.

**Approach 2: Batching PCS openings.** Polynomial commitment schemes often support proving multiple evaluations cheaper than proving each separately. KZG's batch opening (Chapter 9) proves $f(z_1) = v_1, \ldots, f(z_k) = v_k$ with a single group element, using Lagrange interpolation and a quotient polynomial. The proof size stays constant regardless of $k$.

This is PCS-specific. KZG achieves it through algebraic structure (the quotient $\frac{f(X) - I(X)}{Z(X)}$ exists iff all evaluations are correct). Other schemes have different batching properties.

**Approach 3: Batching via domain-level sum-check.** This is what this section develops. Rather than batch the $T$ *claims* directly, we restructure the problem as a sum over the *domain* of $f$. The key equation:

$$\tilde{z}(r') = \sum_{x \in \{0,1\}^\ell} \widetilde{ra}(x, r') \cdot \tilde{f}(x)$$

This sum has $2^\ell$ terms (the entire domain), but most are zero. Sum-check proves it, exploiting sparsity. At the end, the verifier needs a single evaluation $\tilde{f}(r)$ at a random point: one PCS opening, not $T$.

**Why the distinction matters.** Approaches 1 and 2 batch at the *claim level*: the prover must still open $f$ at all $T$ points $y_1, \ldots, y_T$. Approach 1 saves the verifier work (one check instead of $T$), but doesn't reduce openings. Approach 2 compresses the proof, but the prover still computes all $T$ evaluations internally.

Approach 3 batches at the *domain level*: the $T$ point evaluations collapse into a single random evaluation. The prover opens $\tilde{f}$ at one point $r$, not $T$ points.

**When to use each.** Approach 1 applies whenever you have multiple equations to verify, even outside the PCS setting. It's the go-to technique for combining constraint checks, and it costs nothing beyond sampling one random field element.

Approach 2 applies when the polynomial is already committed and you need to prove multiple openings. If you're using KZG and must open at $T$ points anyway, batch opening compresses proof size from $T$ group elements to one. The prover still does $O(T)$ work internally, and verifier work is comparable to Approach 1. The win is purely in proof size: one group element instead of $T$.

Approach 3 applies when openings dominate cost and you can restructure the problem as a domain sum. This is the setting of this chapter: proving many evaluations of a committed or structured polynomial. When each opening costs an MSM, reducing $T$ openings to one is a massive win. When $f$ has structure (sparsity, tensor decomposition), sum-check exploits it. When you're already in the MLE world, the $\widetilde{\text{eq}}$-weighted sum is the natural formulation.

There's a deeper connection: evaluating an MLE at a random point $r'$ *is* a random linear combination, weighted by the Lagrange basis $\widetilde{\text{eq}}(r', \cdot)$ rather than powers of $\alpha$. The sum-check formulation is random linear combination in MLE clothing, but operating at the domain level unlocks optimizations that claim-level batching cannot reach.

### The Sum-Check Approach

Let $\tilde{f}$ be the multilinear extension of $f$. Define the "access matrix" $ra(x, j)$, a Boolean matrix where $ra(x, j) = 1$ iff $y_j = x$. Think of each column $j$ as one-hot: exactly one entry is 1 (at the row corresponding to address $y_j$).

**Example.** Suppose $f$ is defined on 2-bit addresses $\{00, 01, 10, 11\}$, and we have $T = 3$ accesses to addresses $y_1 = 01$, $y_2 = 11$, $y_3 = 01$. The access matrix is:

$$ra = \begin{pmatrix} 0 & 0 & 0 \\ 1 & 0 & 1 \\ 0 & 0 & 0 \\ 0 & 1 & 0 \end{pmatrix} \quad \text{rows: } x \in \{00, 01, 10, 11\}, \quad \text{columns: } j \in \{1, 2, 3\}$$

Each column $j$ encodes "which address did access $j$ hit?" as a one-hot vector: column $j$ equals the basis vector $e_{y_j}$. Here column 1 is $e_{01}$ (since $y_1 = 01$), column 2 is $e_{11}$ (since $y_2 = 11$), and column 3 is $e_{01}$ again (since $y_3 = 01$).

For a single evaluation, we can write:

$$z_j = \sum_{x \in \{0,1\}^\ell} ra(x, j) \cdot f(x)$$

This looks like overkill. The one-hot structure of $ra(\cdot, j)$ zeroes out every term except the one at address $y_j$, so the sum trivially collapses to $f(y_j) = z_j$. Why bother?

The payoff comes from multilinear extensions. We have $T$ such equations, one for each $j$. Define the "error" at index $j$:

$$e_j = z_j - \sum_{x \in \{0,1\}^\ell} ra(x, j) \cdot f(x)$$

All evaluations are correct iff $e_j = 0$ for every $j$. This is exactly the "zero on hypercube" setting from Chapter 19's Spartan analysis. Take MLEs and evaluate at random $r' \in \mathbb{F}^{\log T}$:

$$\tilde{e}(r') = \tilde{z}(r') - \sum_{x \in \{0,1\}^\ell} \widetilde{ra}(x, r') \cdot \tilde{f}(x)$$

If all $e_j = 0$, then $\tilde{e}$ is the zero polynomial and $\tilde{e}(r') = 0$ for any $r'$. If some $e_j \neq 0$, then $\tilde{e}$ is nonzero, and by Schwartz-Zippel, $\tilde{e}(r') \neq 0$ with high probability over random $r'$. The verifier checks whether $\tilde{e}(r') = 0$, equivalently whether:

$$\tilde{z}(r') = \sum_{x \in \{0,1\}^\ell} \widetilde{ra}(x, r') \cdot \tilde{f}(x)$$

If this holds, all $T$ evaluations are correct with high probability.

Sum-check proves this identity. The prover commits to $\widetilde{ra}$ and $\tilde{z}$, then runs sum-check to verify consistency with the public $\tilde{f}$.

### The Sparsity Advantage

The sum has $2^\ell$ terms, potentially enormous (imagine $\ell = 128$ for CPU word operations). But $\widetilde{ra}$ is sparse: only $T$ non-zero entries, one per access. Sum-check exploits this.

**Why one-hotness matters.** The matrix $ra$ has dimensions $K \times T$ where $K = 2^\ell$, but only $T$ entries are non-zero (exactly one per column). Sums that appear to range over $K$ positions actually touch only $T$ terms. This is why batch evaluation costs $O(T)$ rather than $O(KT)$: the one-hot structure makes the exponentially large table effectively linear-sized. When $K = 2^{128}$ (as in Jolt's instruction lookups), this is the difference between tractable and impossible.

Chapter 19's prefix-suffix algorithm achieves prover time $O(T + 2^{\ell/c})$ for any constant $c$. When $T \geq 2^{\ell/c}$, the amortized cost per evaluation is $O(c)$ field operations.

Compare to proving each evaluation separately: $\Omega(T)$ total work just to *state* the claims. The batch approach matches this lower bound while providing cryptographic guarantees.



## Virtual Polynomials

The access matrix $ra$ in our batch evaluation has $K = 2^\ell$ rows (one per possible address) and $T$ columns (one per access). For a zkVM with 32-bit addresses, $K = 2^{32}$. Committing to a $2^{32} \times T$ matrix is obviously impossible.

Virtual polynomials offer escape. The core idea: a polynomial need not exist to be useful. If its evaluations can be computed from other polynomials, it exists implicitly. Commit only to the sources; the rest follows by algebra.

The key observation: during sum-check, the verifier eventually needs $\tilde{a}(r)$ at a random point $r$. If $\tilde{a}$ factors as a product (or sum, or other simple combination) of smaller polynomials, the verifier can reconstruct $\tilde{a}(r)$ from evaluations of those smaller pieces. No commitment to the large $\tilde{a}$ is needed.

The polynomial $\tilde{a}$ is *virtual*: it exists implicitly through a formula, never committed, never stored.

### Tensor Decomposition

For the access matrix, tensor structure provides the compression. Recall: $ra(k, j) = 1$ iff the $j$-th access hit address $k$ (i.e., $y_j = k$). Split an address $k \in \{0,1\}^\ell$ into $d$ chunks:

$$k = (k_1, \ldots, k_d) \quad \text{where each } k_i \in \{0,1\}^{\ell/d}$$

For each chunk $i$, define $ra_i(k_i, j)$ as 1 iff the $i$-th chunk of $y_j$ equals $k_i$. Each $ra_i$ is a smaller matrix: $K^{1/d} \times T$ instead of $K \times T$.

The full access matrix factors:

$$ra(k, j) = \prod_{i=1}^{d} ra_i(k_i, j)$$

**Example.** Return to our 2-bit addresses with accesses $y_1 = 01$, $y_2 = 11$, $y_3 = 01$. Split each address into $d = 2$ chunks of 1 bit each: $y_1 = (0, 1)$, $y_2 = (1, 1)$, $y_3 = (0, 1)$.

The chunk matrices are (columns: $j \in \{1, 2, 3\}$):

$$ra_1 = \begin{pmatrix} 1 & 0 & 1 \\ 0 & 1 & 0 \end{pmatrix} \quad \text{rows: first bit } k_1 \in \{0, 1\}$$

$$ra_2 = \begin{pmatrix} 0 & 0 & 0 \\ 1 & 1 & 1 \end{pmatrix} \quad \text{rows: second bit } k_2 \in \{0, 1\}$$

In $ra_1$: row 0 has 1s in columns 1 and 3 because accesses $y_1 = 01$ and $y_3 = 01$ have first bit 0. Row 1 has a 1 in column 2 because $y_2 = 11$ has first bit 1.

In $ra_2$: row 1 has 1s in all columns because all three accesses ($01, 11, 01$) have second bit 1.

To recover $ra(01, j=1)$: check $ra_1(0, 1) \cdot ra_2(1, 1) = 1 \cdot 1 = 1$. Indeed, access 1 hit address 01. For $ra(10, j=1)$: $ra_1(1, 1) \cdot ra_2(0, 1) = 0 \cdot 0 = 0$. Access 1 did not hit address 10.

Instead of one $4 \times 3$ matrix (12 entries), we store two $2 \times 3$ matrices (12 entries total, same here, but the savings grow with $\ell$).

The commitment savings are dramatic. Instead of a $K \times T$ matrix, the prover commits to $d$ matrices of size $K^{1/d} \times T$ each. For $K = 2^{128}$ and $d = 4$: from $2^{128}$ to $4 \times 2^{32}$.

The exponential has become polynomial.

### Virtualizing Everything

Once you see virtualization, you see it everywhere. And the savings compound.

Consider a zkVM executing a million instructions. Each instruction touches several polynomials: opcode, operands, intermediate values, flags. Naive commitment: millions of polynomials, each requiring an MSM. Virtualized: perhaps a dozen root polynomials, everything else derived. The difference between a 30-second proof and a 3-second proof.

**A toy example.** Suppose the prover commits to polynomials $\tilde{a}$ and $\tilde{b}$, and the verifier wants to check a claim about $\tilde{c}(x) = \tilde{a}(x) \cdot \tilde{b}(x)$. Should the prover commit to $\tilde{c}$ as well?

No. When the verifier eventually needs $\tilde{c}(r)$ at some random point $r$, the protocol can instead ask for $\tilde{a}(r)$ and $\tilde{b}(r)$, then compute $\tilde{c}(r) = \tilde{a}(r) \cdot \tilde{b}(r)$ locally. The polynomial $\tilde{c}$ is virtual: defined by a formula, never committed.

This saves one commitment. Now iterate: If $\tilde{a}$ itself equals $\tilde{d} + \tilde{e}$ for committed $\tilde{d}, \tilde{e}$, then $\tilde{a}$ is also virtual. The pattern cascades, and any polynomial computable from others need not be stored.

**The read values need not exist.** Consider $z = (z_1, \ldots, z_T)$, the outputs of our batch evaluation. One might think these are concrete values that must be committed. But once $ra$ and $f$ are known:

$$\tilde{z}(r') = \sum_{x \in \{0,1\}^\ell} \widetilde{ra}(x, r') \cdot \tilde{f}(x)$$

The right side *defines* $\tilde{z}$ implicitly. We never commit to $z$. When the verifier needs $\tilde{z}(r')$, sum-check reduces this to evaluations of $\widetilde{ra}$ and $\tilde{f}$, which are already committed or public.

**GKR as virtualization.** The GKR protocol (Chapter 7) builds an entire verification strategy from this idea. A layered arithmetic circuit computes layer by layer from input to output. The naive approach commits to every layer's values. GKR commits to almost nothing:

Let $\tilde{V}_k$ denote the multilinear extension of gate values at layer $k$. The layer reduction identity:

$$\tilde{V}_k(r) = \sum_{i,j \in \{0,1\}^s} \widetilde{\text{mult}}_k(r, i, j) \cdot \tilde{V}_{k-1}(i) \cdot \tilde{V}_{k-1}(j) + \ldots$$

Each layer's values are virtual: defined via sum-check in terms of the previous layer. Iterate from output to input: only $\tilde{V}_0$ (the input layer) is ever committed. A circuit with 100 layers has 99 virtual layers that exist only as claims passed through sum-check reductions.

**More examples.** The pattern appears throughout modern SNARKs.

- *Constraint polynomials.* In Spartan (Chapter 19), the polynomial $\tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x)$ is never committed. Sum-check verifies it equals zero on the hypercube by evaluating at random points.

- *Grand products.* Permutation arguments express $Z(X)$ as a running product. Each $Z(i)$ is determined by $Z(i-1)$ and the current term. One starting value plus a recurrence defines everything.

- *Folding.* In Nova (Chapter 23), the accumulated instance is virtual. Each fold updates a claim about what could be verified (not data sitting in memory).

- *Write values from read values.* In read-write memory checking, the prover commits to read addresses, write addresses, and increments $\Delta$. What about write values? They need not be committed: $\textsf{wv}(j) = \textsf{rv}(j) + \Delta(j)$. The write value at cycle $j$ is the previous value at that address plus the change. Three committed objects define four.

**The design principle.** Ask not "what do I need to store?" but "what can I define implicitly?" Every polynomial expressible as a function of others is a candidate for virtualization. Every value recoverable from a sum-check reduction need never be committed.

The fastest provers are the ones that commit least, because computation is cheap but cryptography is expensive.

> **Remark (Sum-checks as a DAG).** Virtualization creates dependencies: when a sum-check ends at random point $r$ and the polynomial is virtual, another sum-check must prove its evaluation at $r$. This structure forms a directed acyclic graph (DAG) where each sum-check is a node, output claims are outgoing edges, and input claims are incoming edges. The DAG captures the protocol's data flow: committed polynomials are sources (no incoming edges from other sum-checks), and the final opening proof is the sink.
>
> The DAG induces a partial order and thus a minimum number of *stages*: sum-checks can run in the same stage only if neither depends on the other's output. Complex protocols like Jolt (which proves RISC-V execution) have ~40 sum-checks organized into 8 stages based on this dependency structure.
>
> Within each stage, independent sum-checks can be *batched* via random linear combination: sample $\rho_1, \ldots, \rho_k$, form $g_{\text{batch}} = \sum_i \rho_i \cdot g_i$, run one sum-check. This is the *horizontal* dimension (batching within a stage); stages are the *vertical* dimension (sequential dependencies). The design heuristic: map the full DAG, minimize stages (the longest path determines the minimum), batch everything independent within each stage.

## Time-Varying Functions

Batch evaluation proves claims of the form $z_j = f(y_j)$ where $f$ is a fixed function. But real computation mutates state. Registers change. Memory gets written. The lookup tables from Chapter 14 assume static data, yet a CPU's registers are anything but static.

Consider what happens when a zkVM executes `ADD R1, R2, R3`. It reads R1 and R2, computes the sum, writes to R3. The next instruction might read R3 and get the new value. If we modeled registers as a fixed function, we'd get the wrong answer: the value at R3 depends on *when* you query it.

This is the time-varying function problem. A function $f$ that gets updated at certain steps. At time $j$, a query $f(y_j)$ returns the value $f$ had *at that moment*. The claim "I correctly evaluated $f$" depends on when the evaluation happened.

### The Setting

Over $T$ time steps, the computation performs operations on a table with $K$ entries. Each operation is either:

- **Read**: query position $k$, receive value $v$
- **Write**: set position $k$ to value $v$

The prover commits to the *operation log*: which positions were accessed and what values were read or written. The claim: each read returns the value from the most recent write to that position.

### The Challenge

To verify this claim, we need to know the table's state at each time step. The naive approach: commit to a $K \times T$ matrix (positions × time steps) where entry $(k, j)$ is "the value at position $k$ after step $j$."

For a zkVM with 32 registers and a million instructions, that's $32 \times 10^6 = 3.2 \times 10^7$ entries. Expensive but perhaps manageable.

For RAM with $2^{32}$ addresses and a million instructions: $2^{52}$ entries. Not manageable. The entire blockchain couldn't store this matrix, let alone commit to it.

### Offline Memory Checking: The Blum Paradigm

The foundational insight comes from Blum et al.: memory consistency can be checked *offline* without maintaining the full memory state. Operations on different addresses are independent, but operations on the *same* address must be ordered correctly.

**The read/write log.** Record every memory operation as a tuple:

- $(a, v, t, \text{op})$: address $a$, value $v$, timestamp $t$, operation type (read or write)

**The consistency check.** For correct memory behavior:

1. Reads return the value from the most recent write to that address
2. The initial memory state is zero (or a specified initialization)

**The permutation approach.** Sort all operations by $(address, timestamp)$. Within each address's operations (in temporal order), check:

- Each write sets the value at that address
- Each read returns the value from the immediately preceding write

This reduces memory checking to a permutation argument (like PLONK's copy constraints) plus local consistency checks.

### The Unified Principle

Step back and notice something surprising. Both read-only and read-write checking answer the same question: "what value should this read return?" And both answer it the same way: as a sum over positions, weighted by an access indicator, verified via sum-check. Recall: $K$ is the table size (number of positions), $T$ is the number of operations.

**Read-only case.** The value at position $k$ is just $f(k)$, a fixed function. The verification equation:

$$rv_j = \sum_{k} ra(k, j) \cdot f(k)$$

The sum has $K$ terms but collapses to one (since $ra(\cdot, j)$ is one-hot). The function $f$ is public or preprocessed once. The access matrix $ra$ has $K \times T$ entries, but tensor decomposition compresses it: split each address into $d$ chunks, factor $ra$ as a product of $d$ smaller matrices, each of size $K^{1/d} \times T$.

**What gets committed (read-only):**

- $ra_1, \ldots, ra_d$: the $d$ chunk matrices (total size $d \cdot K^{1/d} \cdot T$)
- The read values $rv$ are *virtual*: defined by the sum above, never committed

**Read-write case.** Here's where it gets interesting. The value at position $k$ at time $j$ depends on the history of writes. Define $f(k, j)$ as "what value is stored at $k$ just before time $j$?" The verification equation has the same form:

$$rv_j = \sum_{k} ra(k, j) \cdot f(k, j)$$

The challenge: $f(k, j)$ is now a $K \times T$ table, far too large to commit. But here's the escape: $f(k, j)$ is *determined* by the write history. We don't need to store what's in each cell at each moment; we can reconstruct it from what was written when:

$$f(k, j) = \text{initial}(k) + \sum_{j' < j} \mathbf{1}[wa_{j'} = k] \cdot \Delta_{j'}$$

The massive $K \times T$ state table dissolves into two sparse objects: write addresses $wa$ (which get the same tensor decomposition as read addresses) and increments $\Delta$ (just a length-$T$ vector). Virtualization strikes again.

**What gets committed (read-write):**

- $wa_1, \ldots, wa_d$: write address chunk matrices (same tensor trick)
- $ra_1, \ldots, ra_d$: read address chunk matrices
- $\Delta$: increment vector (length $T$)
- The state table $f(k,j)$ and read values $rv$ are *virtual*

| Data | Changes? | Technique | Committed | Virtual |
|------|----------|-----------|-----------|---------|
| Instruction tables | No | Read-only | $ra$ chunks | $rv$, table $f$ |
| Bytecode | No | Read-only | $ra$ chunks | $rv$, table $f$ |
| Registers | Yes | Read-write | $ra$, $wa$ chunks, $\Delta$ | $rv$, state $f(k,j)$ |
| RAM | Yes | Read-write | $ra$, $wa$ chunks, $\Delta$ | $rv$, state $f(k,j)$ |

Both techniques use the same sum-check structure. The difference is that read-only tables have $f(k)$ fixed (public or preprocessed), while read-write tables have $f(k,j)$ that must be virtualized from the write history.

Both paths lead to the same destination, where commitment cost is proportional to operations $T$ (not table size $K$). A table with $2^{128}$ entries costs no more to access than one with $2^{8}$.

### Why This Matters for Real Systems

In a zkVM proving a million CPU cycles, memory operations dominate the execution trace. Every instruction reads registers, many access RAM, all fetch from bytecode. A RISC-V instruction like `lw t0, 0(sp)` involves: one bytecode fetch (read-only), one register read for `sp` (read-write), one memory read (read-write), one register write to `t0` (read-write). Four memory operations for one instruction.

If each memory operation required commitment proportional to memory size, proving would be impossible. A million instructions × four operations × $2^{32}$ addresses = $2^{54}$ commitments. The sun would burn out first.

The techniques above make it tractable. Registers, RAM, and bytecode all reduce to the same pattern: commit to addresses and values (or increments), virtualize everything else. The distinction between "read-only" and "read-write" is simply whether the table $f$ is fixed or must be reconstructed from writes.

What emerges is a surprising economy. A zkVM with $2^{32}$ bytes of addressable RAM, 32 registers, and a megabyte of bytecode commits roughly the same amount per cycle regardless of these sizes. The commitment cost tracks operations, not capacity. Memory becomes (in a sense) free. You pay for what you use, not what you could use.



## The Padding Problem and Jagged Commitments

We've virtualized polynomials, memory states, and intermediate circuit layers. But a subtler waste remains: the boundaries between different-sized objects.

This problem emerged when zkVM teams tried to build *universal* recursion circuits. The dream was one circuit that can verify any program's proof, regardless of what instructions that program used. The reality was that different programs have different instruction mixes, and the verifier circuit seemed to depend on those mixes.

### The Problem: Tables of Different Sizes

A zkVM's computation trace comprises multiple tables, one per CPU instruction type. The ADD table holds every addition executed; the MULT table every multiplication; the LOAD table every memory read. These tables have wildly different sizes depending on what the program actually does.

Consider two programs:

- Program A: heavy on arithmetic. 1 million ADDs, 500,000 MULTs, 10,000 LOADs.
- Program B: heavy on memory. 100,000 ADDs, 50,000 MULTs, 800,000 LOADs.

Same total operations, but completely different table shapes. If the verifier circuit depends on these shapes, we need a different circuit for every possible program behavior. That's not universal recursion but combinatorial explosion.

Now we need to commit to all this data. What are our options?

**Option 1: Commit to each table separately.** Each table becomes its own polynomial commitment. The problem is that verifier cost scales linearly with the number of tables. In a real zkVM with dozens of instruction types and multiple columns per table, verification becomes expensive. Worse, in recursive proving, where we prove that a verifier accepted, each separate commitment adds complexity to the circuit we're proving.

**Option 2: Pad everything to the same size.** Put all tables in one big matrix, padding shorter tables with zeros until they match the longest. Now we commit once. The problem is that if the longest table has $2^{20}$ rows and the shortest has $2^{10}$, we're committing to a million zeros for the short table. Across many tables, the wasted commitments dwarf the actual data.

Neither option is satisfactory. We want the efficiency of a single commitment without paying for empty space.

### The Intuition: Stacking Books on a Shelf

Think of each table as a stack of books. The ADD table is a tall stack (many additions). The MULT table is shorter (fewer multiplications). The LOAD table is somewhere in between.

If we arrange them side by side, we get a jagged skyline: different heights and lots of empty space above the shorter stacks. Committing to the whole rectangular region wastes the empty space.

But what if we packed the books differently? Take all the books off the shelf and line them up end-to-end in a single row. The first million books come from ADD, the next 50,000 from MULT, then 200,000 from LOAD. No gaps and no wasted space. The total length equals exactly the number of actual books.

This is the jagged commitment idea, which is to *pack different-sized tables into one dense array*. We commit to the packed array (cheap and without wasted space) and separately tell the verifier where each table's data begins and ends.

### A Concrete Example

Suppose we have three tiny tables:

| Table | Data | Height |
|-------|------|--------|
| A | [a₀, a₁, a₂] | 3 |
| B | [b₀, b₁] | 2 |
| C | [c₀, c₁, c₂, c₃] | 4 |

If we arranged them as columns in a matrix, padding to height 4:

```
     A    B    C
0:  a₀   b₀   c₀
1:  a₁   b₁   c₁
2:  a₂    0   c₂
3:   0    0   c₃
```

We'd commit to 12 entries, but only 9 contain real data. The three zeros are waste.

Instead, pack them consecutively into a single array:

```
Index:  0   1   2   3   4   5   6   7   8
Value: a₀  a₁  a₂  b₀  b₁  c₀  c₁  c₂  c₃
```

Now we commit to exactly 9 values: the real data. We also record the cumulative heights: table A ends at index 3, table B ends at index 5, table C ends at index 9. Given these boundaries, we can recover which table any index belongs to, and its position within that table.

### From Intuition to Protocol

Now formalize this. We have $2^k$ tables (columns), each with its own height $h_y$. Arranged as a matrix, this forms a *jagged function* $p(x, y)$ where $x$ is the row (up to $2^n$) and $y$ identifies the table. The function satisfies $p(x, y) = 0$ whenever row $x \geq h_y$ (beyond that table's height).

The total non-zero entries: $M = \sum_y h_y$. This is the *trace area*: what actually matters for proving.

Pack all non-zero entries into a single dense array $q$ of length $M$. The packing is deterministic, with table 0's entries first, then table 1's, and so on. This is *flattening*: a 2D table with variable-height columns becomes a 1D array that skips the padding zeros.

The cumulative heights $t_y = \sum_{y' < y} h_{y'}$ track where each column starts in the flattened array. Given a dense index $i$, two functions recover the original coordinates:

- $\text{row}_t(i)$: the row within the padded table (offset from that column's start)
- $\text{col}_t(i)$: which column $i$ belongs to (found by comparing $i$ against cumulative heights)

For example, with heights $(16, 16, 256)$, the cumulative heights are $(0, 16, 32)$. Index $i = 40$ falls in column 2 (since $32 \leq 40 < 288$) at row $40 - 32 = 8$.

The prover commits to:

- $q$: the dense array of length $M$ containing all actual values
- The cumulative heights $t_y = h_0 + h_1 + \cdots + h_{y-1}$, sent in the clear (just $2^k$ integers)

The jagged polynomial $p$ is never committed. It exists only as a relationship between the dense $q$ and the boundary information.

### Making It Checkable

The verifier wants to query the original jagged polynomial and ask, "what is $\tilde{p}(z_r, z_c)$?" This asks for a weighted combination of entries from table $z_c$ at rows weighted by $z_r$.

The key equation translates this into a sum over the dense array:

$$\tilde{p}(z_r, z_c) = \sum_{i \in \{0,1\}^m} q(i) \cdot \widetilde{\text{eq}}(\text{row}(i), z_r) \cdot \widetilde{\text{eq}}(\text{col}(i), z_c)$$

Read this as follows: for each dense index $i$, include $q(i)$ if index $i$ corresponds to the requested (row, column) pair. The $\widetilde{\text{eq}}$ terms act as selectors, where $\widetilde{\text{eq}}(\text{col}(i), z_c)$ picks out entries from the right table and $\widetilde{\text{eq}}(\text{row}(i), z_r)$ picks out entries from the right row. The product of two $\widetilde{\text{eq}}$ terms enforces *double selection*: a term contributes only when dense index $i$ maps to both the correct row and the correct column.

This is a sum over $M$ terms and exactly the sum-check form we've used throughout the chapter. The prover runs sum-check; at the end, the verifier needs $\tilde{q}(r)$ at a random point (handled by the underlying PCS) and the selector function evaluated at that point.

The selector function (despite involving $\text{row}_t(i)$ and $\text{col}_t(i)$) is efficiently computable, since it's a simple comparison of $i$ against the cumulative heights. This comparison can be done by a small read-once branching program (essentially a specialized circuit that checks if an index falls within a specific range using very few operations). This means its multilinear extension evaluates in $O(m \cdot 2^k)$ field operations.

> **Remark (Batching selector evaluations).** During sum-check, the verifier must evaluate the selector function $\hat{f}_t$ at each round's challenge point. With $m$ rounds, that's $m$ evaluations at $O(2^k)$ each, totaling $O(m \cdot 2^k)$. A practical optimization: the prover claims all $m$ evaluations upfront, and the verifier batches them via random linear combination. Sample random $\alpha$, check $\sum_j \alpha^j \hat{f}_t(r_j) = \sum_j \alpha^j y_j$ where $y_j$ are the claimed values. The left side collapses to a single $\hat{f}_t$ evaluation at a combined point. Cost drops from $O(m \cdot 2^k)$ to $O(m + 2^k)$.

### The Payoff

The prover performs roughly $5M$ field multiplications, or five per actual trace element, regardless of how elements are distributed across tables. No padding and no wasted commitment.

For the verifier, something useful happens. The verification circuit depends only on $m = \log_2(M)$ (the log of total trace area), not on the individual table heights $h_y$. Whether the trace has 100 tables of equal size or 100 tables of wildly varying sizes, the verifier does the same work.

This is the solution to the universal recursion problem from the beginning of this section. When proving proofs of proofs, the verifier circuit becomes the statement being proved. A circuit whose size depends on table configuration creates the combinatorial explosion we feared. But a circuit depending only on total trace area yields one universal recursion circuit.

One circuit to verify any program. The jagged boundaries dissolve into a single integer: total trace size.

### The Deeper Point

Jagged commitments are virtualization applied not to polynomial values but to polynomial *boundaries*. The staircase shape (where each table ends) is virtual, defined by the height integers but never materialized as explicit zeros. The sparse $2^{n+k}$-sized polynomial $p$ dissolves into the dense $M$-sized polynomial $q$ plus a handful of integers.

The theme recurs throughout this chapter: ask not what exists but what can be computed. The jagged boundary exists only as a formula.



## Small-Value Preservation

We've focused on *what* to commit, but *how large* the committed values are matters too.

The Jolt paper (Arasu et al., 2024) reported a 4× speedup from tracking value sizes. Not from algorithmic improvement or better cryptography, but just from noticing that witness values are usually small and exploiting that fact.

The reason is that computing $g^x$ via double-and-add takes $O(\log |x|)$ group operations. If $x$ is a 64-bit integer rather than a 256-bit field element, exponentiation takes 64 steps instead of 256. That's 4× faster. For an MSM over a million points, this translates to seconds of wall-clock time.

Real witness values are usually small (8-bit bytes, 32-bit words, 64-bit addresses). Random challenges injected by the verifier are the main source of large field elements. A well-designed protocol keeps these sources of largeness contained, avoiding unnecessary multiplication by random values that would inflate small quantities into large ones.

The impact compounds everywhere:

- MSM with 64-bit scalars: 4× faster than 256-bit
- Hashing small values has fewer field reductions
- FFT with small inputs gives smaller intermediate values and fewer overflows
- Sum-check products where inputs fit in 64 bits yield products that fit in 128 bits, so no modular reduction is needed

Modern sum-check-based systems track value sizes explicitly, and Jolt, Lasso, and related systems maintain separate "small" and "large" polynomial categories. Small polynomials get optimized 64-bit arithmetic. Large polynomials get full field operations. The boundary is tracked through the protocol.

The difference between a 10-second prover and a 2-second prover often lies in these details.



## Key Takeaways

Commitment is the bottleneck. A single elliptic curve exponentiation costs ~3,000 field multiplications. An MSM over $N$ points costs $\approx N/\log N$ exponentiations. In most SNARKs, the prover spends more time committing to polynomials than proving claims about them.

**The design principle:**
Commit to as little as possible. Not zero, since succinctness requires some commitment, but the absolute minimum for soundness.

**The techniques:**

1. **Virtual polynomials.** If $\tilde{c} = \tilde{a} \cdot \tilde{b}$ for committed $\tilde{a}, \tilde{b}$, then $\tilde{c}$ need not be committed. Query $\tilde{a}(r)$ and $\tilde{b}(r)$, then compute $\tilde{c}(r)$ locally. Any polynomial computable from others is a candidate for virtualization.

2. **Batch evaluation.** To prove $z_1 = f(y_1), \ldots, z_T = f(y_T)$, encode the access pattern as a sparse matrix and run sum-check. The amortized cost is $O(1)$ field operations per evaluation.

3. **Tensor decomposition.** An address $k \in \{0,1\}^\ell$ splits into $d$ chunks. The indicator $ra(k, j) = 1$ iff $y_j = k$ factors as $\prod_{i=1}^d ra_i(k_i, j)$. Commitment drops from $2^\ell \times T$ to $d \times 2^{\ell/d} \times T$, so exponential becomes polynomial.

4. **Time-varying functions.** Read-write memory state $f(k,j)$ is virtualized from the write history: $f(k,j) = \text{initial}(k) + \sum_{j' < j} \mathbf{1}[wa_{j'} = k] \cdot \Delta_{j'}$. The $K \times T$ state table dissolves into two sparse objects.

5. **Jagged commitments.** Pack different-sized tables into one dense array. Record cumulative heights so that the verifier circuit depends only on total trace size $M$ (not individual heights). One universal recursion circuit for all programs.

6. **Small-value preservation.** MSM with 64-bit scalars runs 4× faster than 256-bit. Track value sizes through the protocol. Keep witness values small and contain the largeness from random challenges.

**The payoff:**
A zkVM with $2^{32}$ addressable memory, dozens of instruction types, and millions of cycles commits roughly the same amount per cycle regardless of memory size or instruction mix. The commitment cost tracks operations, not capacity. Memory is free, instruction variety is free, and only actual computation costs.

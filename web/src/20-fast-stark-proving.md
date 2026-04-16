# Chapter 20: Fast STARK Proving

> *This chapter is part of Part VI (Prover Optimization, Chapters 19-21), which is optional on a first read. The rest of the book does not depend on it. The material here is essential for anyone designing or implementing a STARK prover.*
>
> *Specific prerequisites: fluency with the STARK pipeline (Chapter 15), FRI (Chapter 10), and the small-field/small-value ideas from Chapter 19. This chapter parallels Chapter 19's treatment of sum-check prover optimization, now applied to the STARK side. Together they give a complete picture of how both proof traditions close the gap between witness computation and proof generation.*

A STARK prover does far more work than the computation it proves. Executing a million steps of a hash function takes microseconds. Generating a proof of that execution takes seconds. The prover overhead, the ratio of proof generation time to raw computation time, exceeded 1000× in early systems. Where does all that prover time go?

The answer is not one bottleneck but a shifting pipeline of them. For small traces, constraint evaluation and polynomial arithmetic consume most of the prover's cycles. For medium traces, the number-theoretic transform (NTT) takes over, since its $O(N \log N)$ cost eventually dominates linear-time constraint evaluation. For the largest traces, Merkle hashing for FRI commitments becomes the wall. Profiling data from production provers confirms this progression: NTT can account for up to 91% of prover runtime in workloads dominated by polynomial operations, while Merkle tree construction dominates at roughly 60% in hash-intensive recursive proving workloads. The prover engineer's task is to push each bottleneck down until the next one surfaces, then push that one down too.

The trajectory of improvement across the ecosystem has been dramatic. Early STARK provers (circa 2021) achieved roughly 10,000 Poseidon hashes per second. By 2024, provers built on small-field techniques and Circle STARKs over Mersenne31 exceeded 500,000 Poseidon2 hashes per second on commodity quad-core hardware, with some configurations surpassing 620,000 per second. That is a 50× improvement from algorithmic and field-choice optimizations alone, without GPU acceleration. Multiple independent teams converged on similar techniques: 31-bit prime fields, AIR-based constraint systems, batched FRI, LogUp bus arguments. Much of this convergence crystallized around **Plonky3** (Polygon), an open-source framework providing shared field arithmetic (BabyBear, Mersenne31), an AIR trait interface, and a modular FRI backend. SP1 (Succinct), OpenVM (Axiom/Scroll), and several other production provers build on Plonky3, while StarkWare's Stwo and RISC Zero's prover implement the same ideas independently. Understanding the shared principles behind these gains is the subject of this chapter.

---

## The prover pipeline

The STARK prover executes a sequence of stages, each feeding into the next. Understanding where time goes requires tracing this pipeline end to end. The following variables recur throughout this chapter:

- **$T$** — trace length (number of rows/timesteps), always a power of two
- **$w$** — trace width (number of columns/registers)
- **$d$** — maximum constraint degree across all AIR transition polynomials
- **$\rho$** — blowup factor, the ratio $|D|/|H|$ between the LDE evaluation domain and the trace domain (typically 2, 4, or 8)
- **$\lambda$** — number of FRI query repetitions (security parameter)
- **$c_h$** — cost of one hash invocation measured in field multiplications

**Stage 1: Trace generation.** The prover runs the computation, filling the execution trace, a matrix with $w$ columns (registers) and $T$ rows (timesteps). For a hash function like Poseidon with 30 rounds and state width 12, the trace might have 12-24 columns and $30 \cdot B$ rows for $B$ input blocks. This stage performs the same arithmetic the original computation would, plus bookkeeping for each intermediate state. Cost: $O(w \cdot T)$ field operations with a small constant per cell.

**Stage 2: Constraint evaluation.** The prover evaluates the AIR constraint polynomials at every row. If the maximum constraint degree is $d$ over $w$ registers, each row costs $O(d \cdot w)$ field operations. Total: $O(d \cdot w \cdot T)$.

**Stage 3: Composition and quotient formation.** The prover forms the composition polynomial by batching all constraint quotients with random Fiat-Shamir challenges (Chapter 15). The composition polynomial has degree roughly $d \cdot T$.

**Stage 4: Low-degree extension (LDE).** The prover evaluates trace polynomials and the composition polynomial on a domain $D$ that is $\rho$ times larger than $H$, where $\rho$ is the blowup factor. The evaluation proceeds by inverse NTT (interpolation from $H$ to coefficient form) followed by forward NTT (evaluation on $D$). The **number-theoretic transform** (NTT) is the finite-field analogue of the FFT: it converts between coefficient and evaluation representations of a polynomial over a domain of roots of unity, using the same butterfly algorithm that Chapter 5 developed for the discrete Fourier transform over $\mathbb{F}_p$. Each polynomial requires two NTTs costing $O(\rho T \log(\rho T))$. With $w$ columns, the total is $O(w \cdot \rho T \log(\rho T))$.

**Stage 5: Merkle commitment.** The prover hashes every row of the LDE matrix into a Merkle tree. The ethSTARK specification (Ben-Sasson et al., 2021), which formalized the production STARK pipeline into a reference document, groups all field elements in a row of the trace LDE into a single leaf, so the tree has $\rho T$ leaves. Building it requires $O(\rho T)$ hash invocations.

**Stage 6: FRI protocol.** The prover executes FRI folding rounds, each halving the polynomial via an NTT and committing the result in a Merkle tree. The total across $\log_2(\rho T / d)$ rounds is a geometric series of NTTs and trees, dominated by the first round.

**Stage 7: Query responses.** The prover opens Merkle paths at queried positions. This is fast (logarithmic per query) and rarely a bottleneck.

The relative costs shift with scale. At $T = 2^{16}$, constraint evaluation can dominate. At $T = 2^{20}$, NTT takes over. At $T = 2^{24}$, Merkle hashing becomes comparable to NTT. Optimization must address each stage in sequence.

The following table summarizes the cost model. Here $w$ is the trace width, $T$ the trace length, $d$ the maximum constraint degree, $\rho$ the blowup factor, $\lambda$ the number of FRI queries, and $c_h$ the cost of one hash invocation measured in field multiplications.

| Stage | Cost | Dominates when |
|-------|------|----------------|
| Trace generation | $O(wT)$ | Rarely (linear, small constant) |
| Constraint evaluation | $O(wT)$ | Small $T$ ($< 2^{18}$) |
| Composition | $O(dT \log(dT))$ | High constraint degree $d$ |
| LDE (NTT) | $O(w \rho T \log(\rho T))$ | Medium $T$ ($2^{18}$ to $2^{24}$) |
| Merkle commitment | $O(w \rho T \cdot c_h)$ | Large $T$ with cheap field arithmetic |
| FRI (folding + trees) | $O(\rho T \log(\rho T) + \rho T \cdot c_h)$ | Comparable to LDE + Merkle combined |
| Query responses | $O(\lambda \log(\rho T))$ | Never |

The ratio $c_h$ is what determines the crossover between NTT-dominated and hash-dominated regimes. Over a 256-bit field, $c_h$ is small relative to field multiplication cost, so NTT dominates. Over a 31-bit field like BabyBear, field multiplications become so cheap that $c_h$ grows relatively large, shifting the bottleneck toward Merkle hashing. This ratio is the single most useful diagnostic for predicting where a given prover spends its time.

The cost table reveals two levers for optimization. The first is to reduce the *inputs* to the pipeline: the parameters $w$, $d$, and $\rho$ that determine how much work each stage performs. This is the domain of AIR design. The second is to reduce the *cost per operation* within each stage: faster field arithmetic (small fields), better memory access (cache-friendly NTTs), fewer redundant commitments (FRI optimizations). The remainder of this chapter addresses these in order.

---

## AIR design and the degree-blowup tradeoff

The encoding of a computation into an AIR often matters more than any algorithmic optimization applied afterward. Two designs for the same computation can differ in prover time by an order of magnitude, because they feed different values of $d$ and $w$ into the same pipeline. The cost table makes this concrete: doubling $d$ doubles every row from "Composition" downward, while doubling $w$ only adds to "LDE" and "Merkle commitment."

The central tension is between trace width and constraint degree. A wider trace (more columns) with low-degree constraints breaks complex expressions into simpler pieces by storing intermediate values. A narrower trace (fewer columns) requires higher-degree constraints to compress the same logic.

The reason width is cheap and degree is expensive comes from how they propagate through the pipeline. Adding a column costs one extra NTT of size $\rho T$ and widens each Merkle leaf; the cost grows linearly in $w$. Raising the constraint degree from $d$ to $2d$ doubles the composition polynomial's degree, doubling the LDE domain, every NTT, every Merkle tree, and all FRI work. Degree is a *multiplicative* cost on the entire pipeline; width is an *additive* cost on one stage. The heuristic follows: add columns to reduce constraint degree until further splitting no longer lowers $d$ to the next power of two. Production STARK frameworks formalize this by setting the blowup factor to the smallest power of two greater than or equal to the highest transition constraint degree, so any reduction in $d$ that crosses a power-of-two boundary halves the downstream cost.

Consider a transition that computes $y = x^8$. With one column, the constraint is $P(\omega X) - P(X)^8 = 0$, degree 8. With three auxiliary columns storing $x^2$, $x^4$, $x^8$, the constraints become four degree-2 checks, where each squaring is $P_{i+1}(\omega X) - P_i(X)^2$. The constraint degree drops from 8 to 2, at the cost of widening the trace from 1 to 4 columns.

Why does constraint degree matter so much? The composition polynomial has degree roughly $d \cdot T$. FRI must prove a degree bound on this polynomial, so the LDE domain must be at least $d \cdot T \cdot \rho$ points. Every doubling of $d$ doubles the NTT size, the Merkle tree size, all FRI operations. A degree-8 constraint over $T = 2^{20}$ rows produces a composition polynomial of degree $\approx 2^{23}$, requiring an LDE domain of $2^{25}$ at blowup $\rho = 4$. Reducing to degree 2 drops the LDE domain to $2^{23}$, a 4× reduction in all subsequent stages. Most production systems keep constraint degree between 2 and 4.

The overarching recipe: keep $d \leq 4$ by trading additive cost in $w$ for multiplicative savings through $d$. Two design patterns achieve this (periodic columns and trace widening), while a third pattern (interaction columns) addresses a different problem: extending AIR expressiveness to handle constraints that span distant rows.

### Reducing degree: periodic columns

Many computations repeat structure at regular intervals. A hash function applies the same round constants in a cycle of length $r$. A CPU cycles through a fixed instruction decode pattern. Naively, these constants would occupy a committed trace column, adding one NTT and one column's worth of Merkle leaf data. Periodic columns avoid this cost entirely.

A **periodic column** encodes public constants that repeat on a fixed cycle. Suppose a hash function uses $r = 4$ round constants $[c_0, c_1, c_2, c_3]$ and the trace has $T = 16$ rows. The constants repeat: row 0 gets $c_0$, row 1 gets $c_1$, ..., row 4 gets $c_0$ again, and so on. The key observation is that on the trace domain $H = \{1, \omega, \omega^2, \ldots, \omega^{15}\}$, the map $\omega^i \mapsto \omega^{4i}$ collapses all rows sharing the same round position to the same value (since $\omega^{4 \cdot 0} = \omega^{4 \cdot 4} = \omega^{4 \cdot 8} = \omega^{4 \cdot 12} = 1$). So the periodic column is really a polynomial of degree $r - 1 = 3$ in the "compressed" variable $X^{T/r} = X^4$, cycling automatically because roots of unity wrap around. Both prover and verifier can compute $c(X)$ from the $r$ public constants without any commitment. The prover saves one NTT of size $\rho T$ and all associated Merkle leaf contributions.

The tradeoff is that $c(X)$ contributes degree $r - 1$ when it appears multiplicatively in a constraint. The design rule: use a periodic column when $r - 1 \leq d$, where $d$ is the constraint degree already imposed by other terms. In that case the periodic column adds no degree overhead and saves an entire committed column. If $r - 1 > d$, the periodic column would raise the effective constraint degree, potentially crossing a power-of-two boundary and doubling all downstream costs. In that case, commit the constants as a regular trace column instead.

Poseidon2 illustrates the tension. The S-box degree is 5 (or 3 after decomposition into auxiliary columns), while the round-constant cycle has $r = 8$. Since $r - 1 = 7 > 3$, treating the round constants as periodic would push $d$ from 3 to 7. Most implementations therefore either commit the round constants as ordinary columns or restructure the cycle into shorter sub-periods.

### Reducing degree: wide versus tall traces

The principle above (add columns to reduce degree) applies not just to individual constraints like $x^8$ but to the overall trace architecture. The total number of trace cells $w \cdot T$ is roughly fixed by the computation, so the question is how to partition that area: many columns with few rows, or few columns with many rows?

For hash functions, where the computation is regular and the state width is fixed, the trace width maps naturally to the state size. For virtual machines, the choice is less obvious. A zkVM instruction like `ADD R1, R2, R3` touches three registers, a program counter, various flags. Representing all of these as separate columns creates a wide trace (50-100 columns in practice) with degree-2 or degree-3 constraints. Alternatively, encoding multiple values per column via bit-packing creates a narrower trace with higher-degree constraints to extract individual fields.

Production systems overwhelmingly favor wide traces. When $w \cdot T$ is fixed, doubling $w$ while halving $T$ leaves the Merkle commitment cost ($w \cdot \rho \cdot T$) unchanged and saves roughly one butterfly stage per NTT ($\log(\rho T/2)$ vs $\log(\rho T)$). But the decisive reason is that wider traces enable lower constraint degree, and as established above, each halving of $d$ that crosses a power-of-two boundary cuts all downstream costs in half.

### Extending expressiveness: interaction columns and LogUp

Periodic columns and trace widening reduce the cost of constraints the AIR can already express. But there is a class of constraints that a pure AIR *cannot* express at all: relationships between non-adjacent rows. The AIR model from Chapter 15 sees only consecutive pairs (row $i$, row $i+1$). Memory consistency, lookup arguments, and register-file reads all require matching values across distant rows. This is not a control-flow issue (a `JUMP` merely updates the program counter between adjacent rows) but a *data consistency* problem: values written at one timestep must be readable at another.

Consider a concrete example. A zkVM executes `LOAD R1, [addr]` at row 3,912, reading a value that was written by `STORE R1, [addr]` at row 47. The transition constraint at row 3,912 can verify that the instruction is well-formed (correct opcode, valid register index), but it sees only rows 3,912 and 3,913. It has no way to reach back to row 47 and check that the loaded value matches what was stored there.

The solution is to avoid checking distant-row consistency directly. Instead, the prover builds a *running summary* of all writes and all reads, then proves the two summaries match. If every read returned the value that was written, the summaries agree; if any read was faked, they disagree with overwhelming probability. The summary itself is stored as an auxiliary column that accumulates one entry per row, turning the global consistency check into a local transition constraint (each row updates the running total).

For this to be sound, the prover must not be able to choose summary values that hide an inconsistency. The protocol achieves this by making the summary depend on a random challenge $\beta$ that the verifier provides (via Fiat-Shamir) *after* the prover has already committed to the main trace. The prover then extends the trace with **auxiliary columns** computed from $\beta$. Because $\beta$ was unknown when the main trace was fixed, the prover cannot game the summary.

The most widely deployed version of this idea is **LogUp** (Chapter 14). If two multisets are equal, then for a random $\beta$ the sums $\sum_i \frac{1}{a_i - \beta}$ and $\sum_j \frac{m_j}{t_j - \beta}$ must agree (where $m_j$ counts how many times table entry $t_j$ was looked up). This global sum-equality becomes a *local* transition constraint by introducing an accumulator column $Z$. Row $i$ increments $Z$ by $\frac{1}{a_i - \beta}$, so $Z$ walks through the partial sums. A boundary constraint checks $Z_0 = 0$ and $Z_T$ equals the expected table-side sum. If any lookup is invalid (some $a_i \notin t$), the sums disagree with probability $1 - T/|\mathbb{F}|$ over the random choice of $\beta$.

AIR constraints are polynomial equations; they can multiply but not divide. The prover cannot write $\frac{1}{a_i - \beta}$ directly in a constraint. Instead, the prover stores each reciprocal as a witness value in an auxiliary column $h_i$ and adds the constraint $h_i \cdot (a_i - \beta) = 1$, which is degree 2. The verifier never computes the division; it just checks that the product equals 1. Each LogUp bus therefore adds 2 auxiliary columns: the accumulator $Z$ and the reciprocal column $h$.

Each of these columns requires one additional NTT of size $\rho T$ and widens the Merkle leaf. For a zkVM with three buses (memory, instruction lookup, range checks), the auxiliary columns total roughly 6, increasing $w$ by 6. Compared to the main trace width of 50-100, this is a 6-12% increase in per-column costs. Unlike periodic columns and trace widening, interaction columns are not an optimization. They are a requirement. A pure AIR without auxiliary columns cannot express memory consistency, lookup arguments, or any constraint relating non-adjacent rows. LogUp is what makes it possible to build zkVMs on top of the AIR model at all. The cost (a few extra columns per bus) is simply the price of expressiveness.

---

AIR design reduces the parameters feeding the pipeline. The next three sections reduce the cost *per operation* within the pipeline stages: field arithmetic (this section), the NTT (next section), and FRI (the section after).

## Small fields and extension field lifting

Every cost in the pipeline table is measured in field multiplications. Making each multiplication cheaper is the most direct way to speed up the prover. The question is: how small can the field be before soundness breaks?

Chapter 19 showed that sum-check provers exploit small *witness values* within a large 256-bit field. STARK provers take a more radical approach: they work over a genuinely small field, where every element fits in a single machine word.

Chapter 19 introduced the cost hierarchy within a 256-bit field: bb (big-by-big) multiplications dominate because both operands span multiple machine words. Over BN254, a bb multiply splits each 254-bit element into four 64-bit limbs and performs multiple limb-by-limb products with carry propagation, typically 30-50 CPU cycles per field multiplication. STARK provers sidestep this hierarchy entirely by working over a prime small enough that every element fits in a single machine word, eliminating multi-limb arithmetic altogether.

Why 31 bits specifically? The constraint comes from hardware. Multiplying two $k$-bit values produces a $2k$-bit result. For the product to fit in a single 64-bit register without multi-word handling, we need $2k \leq 64$, giving $k \leq 32$. A 31-bit prime is the largest that satisfies this while leaving room for modular reduction. Two 31-bit field elements multiply via a single 32×32→64 hardware instruction, and the 62-bit result reduces modulo $p$ in 3-4 cycles total. Compare this with the 30-50 cycles for a 256-bit bb multiply. (64-bit primes like Goldilocks, $p = 2^{64} - 2^{32} + 1$, also avoid multi-limb arithmetic since x86 `MUL` produces a 128-bit result in two registers, but the reduction is more expensive and vectorization is half as dense.)

Vectorization amplifies the advantage further. Modern CPUs process multiple field elements in parallel through SIMD (Single Instruction, Multiple Data) registers. A 512-bit vector register packs 16 elements of a 31-bit field (such as BabyBear or Mersenne31, introduced below) side by side, performing 16 independent multiplications in a single instruction. Over a 64-bit field like Goldilocks ($p = 2^{64} - 2^{32} + 1$, the previous generation of STARK-friendly primes), the same register holds only 8 elements. Over BN254, field multiplication cannot be vectorized at all because each multiply already consumes the full register width for its multi-limb computation. The combined speedup from native arithmetic and vectorization exceeds 10× per element compared to 256-bit fields, with some analyses reporting 40× improvement in end-to-end prover time.

The speedup comes at a cost to soundness. Every interactive protocol in this book (sum-check, FRI, DEEP-ALI) derives security from the verifier's random challenges being hard to predict. A cheating prover guessing a random challenge succeeds with probability $1/|\mathbb{F}|$. Over BN254, that probability is $2^{-254}$, negligible. Over a 31-bit field, it is $2^{-31}$, far from the $2^{-128}$ target. Shrinking the field made arithmetic cheaper but made each challenge weaker.

The solution is **extension field lifting**, which separates where the *data* lives from where the *randomness* lives. The trace, constraint evaluation, and NTT all operate over the base field $\mathbb{F}_p$ (cheap, 31-bit arithmetic). Verifier challenges, which must be unpredictable, live in an extension field $\mathbb{F}_{p^k}$ for $k = 4$ or $k = 8$. An element of $\mathbb{F}_{p^4}$ is a tuple $(a_0, a_1, a_2, a_3) \in \mathbb{F}_p^4$, representing $a_0 + a_1\alpha + a_2\alpha^2 + a_3\alpha^3$ modulo an irreducible quartic. Multiplication costs roughly 9 base field multiplications via Karatsuba (compared to 16 for schoolbook expansion). The field size jumps to $p^4 \approx 2^{124}$, providing adequate soundness. Only the parts of the protocol that involve verifier randomness (FRI folding challenges, DEEP-ALI point $z$, LogUp challenge $\beta$) use extension arithmetic; the bulk of the prover's work never leaves the base field.

How much does extension arithmetic actually cost? The two largest stages provide the comparison. The NTT runs once per trace column, processing $w$ polynomials in the base field. FRI folding processes only a single batched polynomial, but each operation uses an extension challenge and therefore costs roughly 9× a base multiplication. So the FRI work, measured in base field operations, is about $9$× the cost of a single column's NTT, while the total NTT work scales with all $w$ columns. The extension overhead is a fraction roughly $9/w$ of the NTT cost. For a typical trace with $w = 40$, this is around 22%: a noticeable surcharge, but far from dominant.

Two 31-bit primes dominate modern STARK proving, chosen for different algebraic reasons:

**BabyBear** ($p = 2^{31} - 2^{27} + 1 = 15 \times 2^{27} + 1$). What matters is the multiplicative group order $p - 1 = 15 \times 2^{27}$. The factor $2^{27}$ means the field contains a subgroup of order $2^{27}$, which serves as the NTT domain. This supports traces with up to $2^{27} \approx 134$ million rows. BabyBear is the field behind RISC Zero's zkVM.

**Mersenne31** ($p = 2^{31} - 1$). This is a Mersenne prime, giving the cheapest possible modular reduction: since $2^{31} \equiv 1 \pmod{p}$, reducing a 62-bit product is just splitting it into a low 31-bit half and a high half, adding them, and doing one conditional subtract. No multi-limb arithmetic at all. The tradeoff: $p - 1 = 2(2^{30} - 1)$ has only one factor of 2, so the multiplicative group has no large power-of-two subgroup. Standard NTTs are impossible over this field. Circle STARKs (discussed in the FRI section below) resolve this by replacing the multiplicative group with the circle group $\{(x,y) : x^2 + y^2 = 1\}$, which has order $p + 1 = 2^{31}$. Stwo (StarkWare), Plonky3 (Polygon), and Airbender (ZKsync) all use M31 through this mechanism.

**Worked example: counting base multiplications inside an extension multiply.**

Let $p = 2013265921$ (BabyBear). A base field multiplication is one hardware operation: $1234567 \times 7654321 = 9449771988807$, which reduces to $9449771988807 - 4p = 1396708123$ with a single conditional subtract.

Now consider the same operation in the quadratic extension $\mathbb{F}_{p^2} = \mathbb{F}_p[\alpha]/(\alpha^2 + 1)$, which uses 2 coefficients per element (we use the quadratic case for clarity; the quartic extends the same idea). Let $a = a_0 + a_1\alpha$ and $b = b_0 + b_1\alpha$. The schoolbook expansion is:
$$ab = a_0 b_0 + (a_0 b_1 + a_1 b_0)\alpha + a_1 b_1 \alpha^2 = (a_0 b_0 - a_1 b_1) + (a_0 b_1 + a_1 b_0)\alpha$$
where the last step uses $\alpha^2 = -1$. This requires 4 base multiplications: $a_0 b_0$, $a_1 b_1$, $a_0 b_1$, $a_1 b_0$.

Standard polynomial-multiplication tricks (Karatsuba's algorithm, which substitutes two of these multiplications with sums of the other products) reduce the count from 4 to 3 in the quadratic case. Applied recursively to the quartic extension, this drops the naive 16 base multiplications to roughly 9. That is the source of the $9$ figure used in the overhead estimate above.

Concretely, with $a = 5 + 7\alpha$ and $b = 2 + 3\alpha$: the schoolbook computation gives $(5 \cdot 2 - 7 \cdot 3) + (5 \cdot 3 + 7 \cdot 2)\alpha = -11 + 29\alpha$. Each coefficient of the result requires 2 base multiplications and one addition, totaling 4 base multiplications for the full extension product.

---

## NTT optimization

Small fields make each multiplication cheaper but do nothing to reduce the *number* of multiplications. If anything they raise the count slightly, since the parts of the protocol that touch extension elements pay roughly 9 base multiplies per extension multiply. The pipeline stage that consumes most of those multiplications is the low-degree extension (Stage 4): the prover takes each of the $w$ trace polynomials defined on the trace domain $H$ and re-evaluates it on the larger LDE domain $D$ of size $\rho T$. The algorithm that does this efficiently is the **number-theoretic transform** (NTT), which converts between coefficient and evaluation representations of a polynomial in $O(N \log N)$ field operations.

The arithmetic cost is fixed by the domain size: $O(\rho T \log(\rho T))$ multiplications per polynomial, $O(w \rho T \log(\rho T))$ total across all $w$ trace columns. For a trace with $T = 2^{20}$ rows, $w = 40$ columns, and blowup $\rho = 4$, this comes to roughly $40 \times 4 \times 2^{20} \times 22 \approx 3.7 \times 10^9$ field multiplications in the NTT alone. Even at 3-4 cycles per BabyBear multiply, this is over a second on a single core. The NTT is not merely a subroutine; for medium-to-large traces, it *is* the prover.

The algorithm is the same Cooley-Tukey butterfly as the FFT from Chapter 5; in the STARK context, "NTT" and "FFT" are interchangeable, with "NTT" emphasizing the finite-field setting. (Lattice cryptography also uses NTTs, but over a different domain: the reduction polynomial is $X^n + 1$ rather than $X^n - 1$, so the transform evaluates at primitive $2n$-th roots of unity and computes a *negacyclic* convolution. The STARK NTT uses $n$-th roots and computes a standard cyclic convolution, matching the vanishing polynomial $Z_H(X) = X^n - 1$ from Chapter 15.) Beyond the LDE, the prover also runs NTTs in each FRI folding round to extract even/odd parts of the polynomial, but those are smaller and form a geometric series dominated by the first round.

The asymptotic cost is not what makes NTTs hard to optimize. The problem is memory access. Modern CPUs have a small, fast on-chip memory called the **cache**, organized in layers (L1 at roughly 32-64 KB per core, accessed in 4 cycles; L2 at hundreds of KB; L3 in megabytes). Anything not in cache must be fetched from main RAM, which costs 100-300 cycles, fifty times slower than a hit. An algorithm that touches data already in cache runs near peak compute throughput; an algorithm that constantly misses spends most of its time stalled, waiting for RAM.

An NTT of size $N$ performs $O(N \log N)$ multiplications in $\log N$ "butterfly" stages. Each stage $k$ pairs elements at distance $N/2^k$. The first stages access widely separated memory addresses (stride $N/2$), so each butterfly's two operands sit far apart in memory and almost certainly cause cache misses. The last stages access nearby elements, which are cache-friendly. For $N = 2^{20}$, the first stage's stride is $2^{19}$ elements ($\approx 2$ MB for 32-bit fields), far exceeding any L1 or L2 cache. A naive implementation spends most of its time waiting for RAM rather than computing.

### The four-step NTT

The **four-step NTT** rearranges the computation so that all but one stage operates on chunks small enough to fit entirely in L1 cache. Instead of one large NTT of size $N$, the prover treats the data as a $\sqrt{N} \times \sqrt{N}$ matrix and runs many small NTTs of size $\sqrt{N}$.

The procedure has four steps:

1. Perform $\sqrt{N}$ small NTTs of size $\sqrt{N}$, one along each row of the matrix
2. Multiply each element by a twiddle factor (a precomputed root of unity)
3. Transpose the matrix
4. Perform $\sqrt{N}$ small NTTs along each row again

Why this is faster: each small NTT reads and writes only $\sqrt{N}$ elements, which for realistic STARK sizes fits in L1 cache. For $N = 2^{24}$, $\sqrt{N} = 2^{12} = 4096$ elements, occupying $4096 \times 4 = 16$ KB over a 31-bit field. That fits in a 32 KB L1 cache with room to spare. The CPU loads the row once, runs the entire small NTT against fast on-chip memory, and writes the result back. Cache-miss penalties no longer dominate.

The naive NTT, by contrast, has $\log_2 N = 24$ butterfly stages, and the early stages have stride $N/2 = 2^{23}$ elements ($\approx 32$ MB), causing a cache miss on essentially every butterfly. The four-step layout incurs cache-line-friendly access in steps 1 and 4, and concentrates the unavoidable long-stride memory traffic into a single transposition (step 3) that can be done in cache-friendly blocked fashion.

GPU implementations extend this further. Research on GPU NTT optimization (Özcan, 2023) implements both "Merge" and "4-Step" NTT models for GPU architectures, where the memory hierarchy (global memory → shared memory → registers) creates an analogous cache structure. The four-step decomposition maps naturally to GPU thread blocks, with each block handling one row NTT in fast shared memory.

### The blowup factor tradeoff

The four-step decomposition makes each NTT faster at fixed size $N$. The other way to make NTTs cheaper is to make $N$ smaller. Recall that the NTT operates on the LDE domain $D$, whose size is $|D| = \rho T$ where $\rho = |D|/|H|$ is the blowup factor. Halving $\rho$ halves $N$, which directly halves the work in every NTT, every Merkle tree, and every FRI round. The only obstacle is that $\rho$ is not a free parameter: FRI's soundness depends on it.

The mechanism is straightforward. FRI proves that a committed function is close to a low-degree polynomial by spot-checking. A cheating prover who deviates from a low-degree polynomial must disagree with every degree-$T$ polynomial on at least a $1 - 1/\rho$ fraction of the LDE domain (a Reed-Solomon distance bound from Chapter 10). Each random query catches such a deviation with probability at least $1 - 1/\rho$, so $\lambda$ queries miss the deviation with probability at most $\rho^{-\lambda}$. Each query contributes $\log_2 \rho$ bits of security.

This relationship encodes a direct tradeoff. Going from $\rho = 16$ to $\rho = 2$ shrinks the LDE by 8× (massive prover speedup) but cuts the security per query from 4 bits to 1 bit, requiring 4× more queries to maintain the same target. Each extra query adds Merkle path openings to the proof, increasing proof size.

One subtlety affects the security accounting. The $\log_2 \rho$ figure depends on a strong assumption called the **proximity gap conjecture**. The conjecture concerns batched FRI, where the prover combines $w$ committed polynomials into a single random linear combination $F = \sum \gamma_i P_i$ and runs FRI once on $F$ instead of $w$ times on each $P_i$. The natural worry is that even if some $P_i$ is far from low-degree, the combination $F$ might *accidentally* land close to low-degree (because the randomness $\gamma_i$ canceled the deviations). The proximity gap conjecture asserts this cannot happen with non-negligible probability: the set of "bad" $\gamma$ that move $F$ across the soundness threshold is exponentially small. If true, batched FRI is as sound as running FRI on the worst individual $P_i$, giving $\log_2 \rho$ bits per query. The fully proven analysis (which makes no conjecture) loses a factor of 2, giving $\frac{1}{2}\log_2 \rho$ bits per query.

For years, deployed STARK systems used the conjectured numbers, halving query counts compared to the proven bound. In late 2025, counterexamples showed the conjecture does not hold in full generality: certain pathological codes admit "bad" $\gamma$ probabilities that the conjecture's quantitative claim ruled out. The counterexamples do not break Reed-Solomon FRI in deployment, but they invalidate the strongest version of the conjecture and force a re-examination of soundness margins. Production systems are responding by either increasing $\rho$ (widening the safety margin between conjectured and proven security) or switching to the proven analysis directly. The Ethereum Foundation's proving roadmap now targets 100 bits of *provable* security by mid-2026 and 128 bits provable by year-end, driving conservative parameter choices across the ecosystem.

For systems targeting 128-bit security, the parameter choices tighten:

| Blowup $\rho$ | Queries for 128 bits (conjectured) | Queries for 128 bits (proven) | LDE size ($T = 2^{20}$) |
|----------------|-------------------------------------|-------------------------------|--------------------------|
| 2 | 128 | 256 | $2^{21}$ |
| 4 | 64 | 128 | $2^{22}$ |
| 8 | $\approx 43$ | $\approx 86$ | $2^{23}$ |
| 16 | 32 | 64 | $2^{24}$ |

Smaller blowup saves prover time (smaller NTTs and Merkle trees) but increases proof size (more query openings). Most modern systems use $\rho = 2$ combined with grinding to compensate.

For a concrete sense of the tradeoff: moving from $\rho = 2$ to $\rho = 8$ on a typical trace ($T = 2^{20}$, $w = 40$) makes the LDE 4× larger and the NTT work roughly 4.4× more expensive, but cuts the FRI query count by about 3× (from 128 conjectured queries to 43), shrinking the proof from $\approx 2.9$ MB to $\approx 1.1$ MB at the same grinding. The blowup factor is the primary knob for trading prover speed against proof size.

---

## FRI optimization

The NTT produces evaluations on the LDE domain. The Merkle tree commits them. But the proof is not yet succinct: the commitment alone proves nothing about degree. FRI (Chapter 10) is what makes the Merkle commitment into a polynomial commitment, by interactively testing that the committed function is close to a low-degree polynomial. The base FRI protocol is already efficient, but four optimizations, each addressing a different cost, combine to reduce FRI's contribution to prover time and proof size by an order of magnitude.

### DEEP-ALI

The base STARK protocol (Chapter 15) commits to two things separately: the trace polynomials and the composition polynomial. Recall that the composition polynomial is the random linear combination of all constraint quotients, a single polynomial whose low-degree-ness certifies that every transition and boundary constraint is satisfied. Committing it requires a full Merkle tree of $\rho T$ leaves, just as expensive as the trace commitment. DEEP-ALI eliminates this second commitment entirely. As a bonus, it tightens FRI's per-query soundness.

The mechanism is a redirection. The composition polynomial is built algebraically from the trace polynomials and known constraint equations. For a Fibonacci-like recurrence $P(\omega X) - P(X) - P(\omega^{-1} X) = 0$, for example, the composition polynomial has the form
$$C(X) = \frac{P(\omega X) - P(X) - P(\omega^{-1} X)}{Z_H(X)}$$
where $Z_H$ is the vanishing polynomial of the trace domain. The key point is that $C(X)$ is *determined* by $P(X)$ and the constraint, not an independent object. Once the verifier knows $P$'s value at a point, it can compute $C$'s value at that point with no help from the prover.

DEEP-ALI exploits this. Instead of asking the prover to commit $C$ separately, the verifier picks a random point $z$ outside the LDE domain $D$ and asks the prover to evaluate the trace at $z$ (and at $\omega z$, to capture the "next row" needed by transition constraints). The prover sends the values $P_j(z)$ and $P_j(\omega z)$ for each trace column. The verifier plugs these into the constraint equations, divides by $Z_H(z)$, and obtains $C(z)$ on its own. No Merkle tree for $C$ is needed; one reconstructed value at one point is all the protocol uses.

For this redirection to be sound, the verifier must check that the prover's claimed evaluation $P_j(z)$ actually agrees with the committed trace polynomial $P_j$. The trick is the **DEEP quotient**:
$$D_j(X) = \frac{P_j(X) - P_j(z)}{X - z}$$
If the claimed $P_j(z)$ is correct, this quotient is a polynomial of degree $\deg(P_j) - 1$. If the claim is wrong, the numerator does not vanish at $z$, so $D_j$ has a pole there and is not a polynomial at all. The prover batches all DEEP quotients into a single polynomial via random linear combination and runs FRI on the result. If FRI accepts (i.e., the batched quotient is close to low-degree), then with overwhelming probability every $P_j(z)$ was honest, which means the verifier's reconstructed composition value is correct, which means all constraints hold.

To make the contrast concrete, consider the Fibonacci AIR with one trace column of length $T = 2^{20}$ and blowup $\rho = 4$ (LDE domain size $2^{22}$).

Without DEEP-ALI, the prover's commitment phase is:

1. Build a Merkle tree over the $2^{22}$ trace evaluations on $D$ (one tree).
2. Compute the composition polynomial $C(X)$ on $D$ (one full NTT).
3. Build a Merkle tree over the $2^{22}$ composition evaluations on $D$ (a second tree).
4. Run FRI on $C$ (folding rounds and additional Merkle trees).

With DEEP-ALI, the same phase becomes:

1. Build a Merkle tree over the $2^{22}$ trace evaluations on $D$ (one tree).
2. Receive a random point $z \notin D$ from the verifier.
3. Send $P(z)$ and $P(\omega z)$ (two field elements).
4. Form the DEEP quotient $D(X) = (P(X) - P(z))/(X - z)$ on $D$ (a divide-by-linear pass, cheaper than a full NTT).
5. Run FRI on $D(X)$.

The composition polynomial never gets an NTT and never gets a Merkle tree. The prover's only added work is computing two trace evaluations at $z$ and forming the DEEP quotient. The verifier's only added work is computing $C(z)$ from $P(z)$ and $P(\omega z)$ via the constraint formula, a constant-time operation. (For traces with multiple columns, all DEEP quotients combine into a single polynomial via batched FRI, the optimization covered in the next subsection.)

The first benefit is direct: the prover saves the entire composition-polynomial Merkle tree, $\rho T$ leaves of hashing, plus the corresponding NTT to evaluate the composition polynomial on $D$. For typical parameters this is a 30-50% reduction in commitment work.

The second benefit is subtler. Standard FRI has a per-query soundness gap: a cheating prover who deviates from low-degree only on a small subset of $D$ might still pass FRI's spot-checks. By demanding answers at a point $z$ chosen *outside* $D$, DEEP-ALI closes this gap. A cheater can fudge values inside $D$ to look low-degree but cannot anticipate where $z$ will land. The DEEP-FRI paper (Ben-Sasson et al., 2019) proves this raises per-query soundness from a constant below $1/8$ to arbitrarily close to 1.

The underlying heuristic generalizes: any polynomial that is algebraically determined by already-committed polynomials does not need to be committed. Evaluating it at a single random point suffices, since the verifier can reconstruct the value from the committed components. The composition polynomial is the obvious case, but the same principle reappears in sum-check-based systems (Chapter 21) under the name *virtual polynomials*. DEEP-ALI is the STARK-side instance of this idea.

In practice, DEEP-ALI is a strict improvement: it removes a Merkle tree, removes an NTT, and tightens soundness. There is no tradeoff against it. It is universal in production STARK provers.

### Grinding

Each FRI query buys $\log_2 \rho$ bits of security (under the conjectured analysis) but adds proof bytes: a query requires opening Merkle paths across every committed layer, costing tens of KB per query at typical parameters. The query count therefore sets the proof size. At $\rho = 2$, achieving 128-bit security requires 128 queries, which produces a proof of several megabytes. The question grinding answers: can the prover *trade computation for proof bytes*, paying CPU time at proving to reduce the number of queries needed?

The mechanism is a hash puzzle. After the FRI commitment phase ends, the verifier's query positions are determined by hashing the transcript. The prover is required to find a 64-bit nonce such that hashing (transcript ∥ nonce) yields a digest with $g$ leading zero bits. Such a nonce exists with probability $2^{-g}$ per attempt, so finding one costs $\approx 2^g$ hash evaluations on average. Crucially, the puzzle binds *every* committed value: a cheating prover who alters any Merkle root changes the hash input and must restart the search from scratch. Inverting a $g$-bit hash prefix costs $\approx 2^g$ work, so grinding contributes exactly $g$ bits of security to the total budget.

To make the trade concrete, consider a target of 128-bit security at $\rho = 2$ and trace width $w = 40$ over BabyBear with $T = 2^{20}$ rows.

Without grinding: 128 queries are needed (1 bit per query). Each query opens Merkle paths of depth $\log_2(\rho T) = 21$ for each of the 40 columns at 32 bytes per hash, costing $\approx 40 \times 21 \times 32 = 26$ KB of authentication paths. Total proof contribution from queries: $128 \times 26$ KB $\approx 3.3$ MB.

With $g = 20$ bits of grinding: only $128 - 20 = 108$ queries are needed. Proof size from queries drops to $108 \times 26$ KB $\approx 2.8$ MB, a savings of roughly 520 KB. The grinding cost is $2^{20} \approx 10^6$ hash evaluations, which a modern CPU completes in under a millisecond. Trading sub-millisecond compute for half a megabyte of proof is an extraordinarily favorable trade.

The heuristic that emerges: grinding is essentially free up to the point where $2^g$ hash evaluations approach the prover's other costs. For modern provers running in seconds, $g$ between 16 and 32 fits comfortably under "free" and shaves substantial proof bytes. Beyond $g = 32$, grinding starts taking measurable wall-clock time (4 billion hashes), and the marginal proof savings shrink. Production systems converge on this range: ethSTARK specifies 32 bits of grinding, RISC Zero uses 16, and typical BabyBear configurations land between 15 and 24.

### Batched FRI

A STARK prover typically needs to prove low-degree-ness of *many* polynomials over the same domain: each of the $w$ trace columns (or, with DEEP-ALI, each DEEP quotient). The naive approach runs an independent FRI instance for each one, which means independent folding rounds and independent Merkle trees per round. For $w = 50$ trace columns and $\log_2(\rho T) = 22$ folding rounds, this is $50 \times 22 = 1100$ Merkle trees built during FRI alone, dominating commitment costs. Batched FRI replaces all of these with a single FRI instance, paying for one set of folding rounds total.

The mechanism is random linear combination. The verifier provides challenges $\gamma_1, \ldots, \gamma_w$ via Fiat-Shamir, and the prover forms:
$$F(X) = \sum_{j=1}^{w} \gamma_j \cdot P_j(X)$$
A single FRI instance then proves $F$ has degree less than $T$. The soundness argument is the same one that makes random linear combinations work throughout this book: if any $P_j$ violates the degree bound, the combination $F$ inherits that violation unless the verifier-chosen $\gamma_j$ accidentally cancel it. This is exactly the situation governed by the proximity gap conjecture from the blowup-factor section above. Under the conjectured analysis, the cancellation probability is negligible (Schwartz-Zippel bounds the linear case at $T/|\mathbb{F}|$ over a 124-bit extension field). Under the proven analysis, the bound is weaker by a constant factor, costing a few extra queries to compensate.

To make the savings concrete, take the same example as before: $w = 50$ trace columns (or DEEP quotients), trace length $T = 2^{20}$, blowup $\rho = 4$. The first FRI fold operates on a polynomial over the $2^{22}$-element LDE domain, with subsequent folds halving each time, giving $\log_2(2^{22}) = 22$ folding rounds in total.

Without batching, each round builds 50 separate Merkle trees (one per polynomial). The first round alone hashes $50 \times 2^{22} = 2 \times 10^8$ leaves. Across 22 rounds the geometric series doubles this, totaling $\approx 4 \times 10^8$ hashes for FRI commitments.

With batching, each round builds one Merkle tree. The first round hashes $2^{22} \approx 4 \times 10^6$ leaves; the geometric series across rounds totals $\approx 8 \times 10^6$ hashes. That is a 50× reduction in FRI Merkle work, exactly the trace width.

The cost of batching is small: one extension multiplication per polynomial per LDE point during the random linear combination step, a single $O(w \rho T)$ pass. For typical parameters this is a few percent of the total prover time, far less than the FRI hashing it eliminates.

Combined with DEEP-ALI, the batched polynomial incorporates both the DEEP quotients and the trace polynomials in a single linear combination, so one FRI instance simultaneously handles degree verification, out-of-domain evaluation consistency, and composition polynomial correctness.

The heuristic: any time a prover needs to prove low-degree-ness of multiple polynomials over the same domain, batching wins. The savings scale linearly with the number of polynomials being batched, and the soundness loss is negligible. No production STARK system runs FRI without it.

### Circle FRI

The small-field story has a gap. BabyBear ($p = 2^{31} - 2^{27} + 1$) supports NTTs natively because $p - 1$ has a large power-of-two factor ($2^{27}$). But Mersenne31 ($p = 2^{31} - 1$) has the cheapest arithmetic of any 31-bit prime, since reduction is a single addition plus a conditional subtract. Its multiplicative group order $p - 1 = 2(2^{30} - 1)$ has only one factor of 2, far too few for a power-of-two NTT domain. The cheapest field cannot use the standard algorithm.

Circle STARKs (Chapter 15) resolve this by replacing the multiplicative group with the **circle group** $\{(x, y) \in \mathbb{F}_p^2 : x^2 + y^2 = 1\}$, which has order $p + 1 = 2^{31}$, a perfect power of two. Circle FRI adapts the FRI folding protocol to this group structure.

Polynomials on the circle are not standard univariates but elements of a Riemann-Roch space, consisting of polynomials modulo the relation $x^2 + y^2 = 1$. This means $y^2$ terms reduce to $1 - x^2$, so every polynomial expression on the circle involves $y$ at most linearly.

The first round of Circle FRI exploits the $y$-symmetry. For opposite points $(x, y)$ and $(x, -y)$ on the circle, the folding decomposes a function $F$ into even and odd parts:

$$f_0(x) = \frac{F(x, y) + F(x, -y)}{2}, \quad f_1(x) = \frac{F(x, y) - F(x, -y)}{2y}$$

Given a random challenge $\alpha$, the folded function is $f_0 + \alpha \cdot f_1$, now depending only on $x$. This halves the domain.

Subsequent rounds use the **doubling map** $x \mapsto 2x^2 - 1$, which arises from the angle-doubling formula $\cos(2\theta) = 2\cos^2(\theta) - 1$. Opposite $x$-values (points at angles $\theta$ and $\pi - \theta$) map to the same doubled coordinate. The folding at each subsequent round is:

$$f_0(2x^2 - 1) = \frac{F(x) + F(-x)}{2}, \quad f_1(2x^2 - 1) = \frac{F(x) - F(-x)}{2x}$$

Each round halves the domain, just as standard FRI halves via the squaring map $x \mapsto x^2$. The total work across all rounds forms the same geometric series, giving $O(N)$ total field operations for the folding itself.

The takeaway is that Circle FRI delivers the algorithmic capabilities of standard FRI (low-degree testing via halving folds, $O(N \log N)$ NTTs, $O(N)$ folding work) over a field where standard FRI cannot run. The win is the ability to use Mersenne31 arithmetic, whose modular reduction is roughly 1.4× faster per multiplication than BabyBear. The Circle STARKs paper (Haböck, Levit, Papini, 2024) measures this speedup directly on real workloads. Combined with the 4× advantage of 31-bit over 64-bit arithmetic that motivated small fields in the first place, Circle STARKs over Mersenne31 represent the current frontier of STARK proving speed and are deployed in Stwo (StarkWare), Plonky3 (Polygon), and Airbender (ZKsync).

The design rule: if your prover's bottleneck is field arithmetic and you can build the rest of your stack (extension fields, hash function, recursion) over Mersenne31, Circle FRI is worth the additional machinery. If the bottleneck is elsewhere (constraint evaluation, Merkle hashing with an expensive hash function), the BabyBear/standard-FRI combination is simpler and gives most of the same benefit.

---

## A worked example: proving Poseidon2 hashes

The chapter has introduced optimizations one at a time. To see how they compound, consider a single concrete task and trace what each optimization saves. The task: prove 1024 invocations of the Poseidon2 hash function. We will work through two configurations in parallel, a naive baseline and an optimized prover, and compare the cost at each stage.

**The computation.** Poseidon2 with state width 16 uses 8 full rounds and 14 partial rounds per permutation, for 22 rounds total. Each round applies a non-linear function called an **S-box** (substitution box, the standard term for the non-linear component of a hash or block cipher) to one or more state elements; in Poseidon2 the S-box is simply $x \mapsto x^5$. Full rounds apply it to all 16 state elements; partial rounds apply it to only one. After each S-box, an MDS matrix linearly mixes the state. The total trace length for 1024 hashes is $T = 1024 \times 22 = 22{,}528$ rows, rounded up to $T = 2^{15}$ for NTT compatibility.

**Configuration A: naive baseline.** Use BN254 (a 254-bit field), encode each S-box directly as a degree-5 constraint, commit the composition polynomial separately, run a fresh FRI instance per polynomial.

- Field arithmetic: each multiplication is 30-50 cycles (multi-limb 254-bit operations).
- Trace columns: $w = 16$ (just the state elements).
- Constraint degree: $d = 5$ (degree of $x \mapsto x^5$).
- LDE blowup: $\rho = 8$ (must satisfy $\rho \geq d$).
- LDE domain size: $\rho T = 2^{18}$.
- Per-column NTT: $\approx 2^{18} \times 18 / 2 \approx 2.4 \times 10^6$ multiplications. Across 16 trace columns plus a composition polynomial of degree-bound $\approx d \cdot T$, total NTT work is roughly $2^{19}$ multiplications times another factor of $\log$, giving $\approx 5 \times 10^7$ multiplications. At 30 cycles each on a 3 GHz core, that is $\approx 0.5$ seconds for NTT alone.
- Commitment: two large Merkle trees (trace + composition), $\approx 2 \times 2^{18}$ hash invocations.
- FRI: 16 separate FRI instances (one per trace column) plus one for the composition polynomial.

**Configuration B: optimized prover.** Switch to Mersenne31 with Circle STARKs, decompose S-boxes into auxiliary columns to reduce degree, apply DEEP-ALI to skip the composition commitment, batch all FRI instances into one, add 20 bits of grinding.

- Field arithmetic: each multiplication is roughly 3 cycles (single 32-bit multiply + Mersenne reduction), with 8-wide AVX2 SIMD.
- Trace columns: $w = 24$ ($16$ state + $\approx 8$ auxiliary $q = x^2$ columns averaged across full and partial rounds).
- Constraint degree: $d = 3$ (using $x^5 = x \cdot (x^2)^2$ via the auxiliary column, splitting into degree-2 and degree-3 checks).
- LDE blowup: $\rho = 2$ (the smallest practical value, compensated by grinding).
- LDE domain size: $\rho T = 2^{16}$.
- Per-column NTT: $\frac{1}{2} \cdot 2^{16} \cdot 16 \approx 5 \times 10^5$ M31 multiplications.
- Total NTT across 24 columns: $\approx 1.2 \times 10^7$ multiplications.
- With SIMD throughput of $\approx 8 \times 10^9$ multiplications per second on a single core, NTT wall time: $\approx 1.5$ ms.
- Commitment: one Merkle tree on the trace, $2^{16}$ leaves of 24 field elements each, $\approx 10^5$ Poseidon2 hash invocations. No composition polynomial commitment (DEEP-ALI).
- FRI: one batched instance (all 24 DEEP quotients combined).
- Queries: 108 (128 bits target − 20 bits grinding) at $\rho = 2$.

**Where the savings come from.** Comparing the two configurations stage by stage:

| Stage | Naive (Config A) | Optimized (Config B) | Source of savings |
|-------|------------------|----------------------|-------------------|
| Field multiplication cost | 30-50 cycles | $\approx 3$ cycles, 8-wide SIMD | Mersenne31 + small fields |
| Constraint degree | 5 | 3 | Auxiliary columns |
| Blowup factor | 8 | 2 | Allowed by lower $d$ |
| LDE domain size | $2^{18}$ | $2^{16}$ | Lower $\rho$ |
| NTT work | $\approx 5 \times 10^7$ | $\approx 1.2 \times 10^7$ | Smaller domain, more columns offset by lower $\log N$ |
| NTT wall time | $\approx 500$ ms | $\approx 1.5$ ms | All of the above plus SIMD |
| Merkle trees committed | $2$ (trace + composition) | $1$ (trace only) | DEEP-ALI |
| FRI instances | $\approx 17$ | $1$ | Batched FRI |
| Queries | 128 (no grinding) | 108 | Grinding shifts 20 bits |

The optimized prover finishes in a few milliseconds where the naive baseline would take hundreds of milliseconds, a roughly $300\times$ improvement. No single optimization in the table is worth more than a single-digit factor on its own; the orders-of-magnitude gap comes from the stack. This matches the trajectory described in the chapter introduction, where production STARK provers improved by 50× from algorithmic and field-choice optimizations alone, with commodity hardware delivering the rest.

---

## Comparison with sum-check optimization

Chapters 19 and 20 solve the same problem from opposite directions. The techniques differ because the cost structures differ.

Sum-check provers run in $O(N)$ field operations. The bottleneck lies in the sum-check rounds themselves plus polynomial commitment openings. Optimization focuses on reducing cost per operation through small-value tricks, delayed binding, Karatsuba for high-degree products. Polynomial commitments (MSM for curve-based schemes) are a separate cost center, often the dominant one, addressed in Chapter 21.

STARK provers pay an $O(N \log N)$ NTT cost that sum-check avoids entirely, since multilinear polynomials need no Fourier transform. But their Merkle commitments are vastly cheaper than the MSMs that curve-based sum-check systems require. A Merkle commitment costs one hash per element; a KZG commitment costs one elliptic curve scalar multiplication per element, roughly 3000× more expensive per operation.

Both traditions exploit the principle of doing most work in cheap arithmetic. Sum-check provers work over 256-bit fields but exploit small witness values for fast ss/sb multiplications in early rounds (Chapter 19). STARK provers work over 31-bit base fields, lifting to 124-bit extension fields only for verifier challenges. The mechanism differs (small values within a large field vs. a genuinely small field with extensions) but the economics are identical: the prover's heaviest rounds coincide with the regime where the cheapest arithmetic applies.

A second shared principle is the avoidance of unnecessary commitments. DEEP-ALI (this chapter) eliminates the composition polynomial commitment by exploiting that the composition polynomial is algebraically determined by the trace. Sum-check systems take the same idea further with **virtual polynomials** (Chapter 21): any polynomial computable from already-committed polynomials can be evaluated at a verifier-chosen point without ever being committed. The principle generalizes: derived data should not be paid for twice. Different systems implement this differently (DEEP quotients, virtual polynomials, quotient-free PCS designs), but the underlying observation is the same.

Neither tradition dominates universally. STARKs pay $\log N$ overhead per element but get cheap commitments. Sum-check achieves linear time but faces expensive commitments. At small scales with structured computations (hashing), STARKs excel because their Merkle-based commitments scale linearly while curve-based MSMs grow superlinearly. At large scales with sparse constraints, sum-check's $O(T)$ sparse proving (Chapter 19) pulls ahead because the NTT processes the entire trace regardless of sparsity.

The convergence of the two traditions is already underway. Binius (Chapter 26) uses sum-check over binary tower fields with FRI-based commitments, combining sum-check's linear-time proving with hash-based post-quantum commitments. Systems like Plonky3 support both quotienting-based and sum-check-based frontends over the same small-field backend. Chapter 22 develops this comparison fully.

---

## Key takeaways

1. **The STARK prover bottleneck shifts with scale.** Constraint evaluation dominates for small traces; the NTT dominates for medium traces ($T = 2^{18}$ to $2^{24}$); Merkle hashing dominates at the largest scales. The crossover ratio is $c_h$, the cost of one hash relative to one field multiplication; the larger $c_h$, the earlier hashing takes over. Optimization must address whichever stage currently dominates.

2. **AIR design is the highest-leverage optimization.** Two encodings of the same computation can differ in prover time by an order of magnitude because they feed different $w$ and $d$ into the pipeline. Width $w$ is an additive cost on a few stages; degree $d$ is a multiplicative cost on the entire pipeline downstream of the composition polynomial. The design rule: add columns to reduce degree until $d$ stops crossing power-of-two boundaries downward.

3. **Interaction columns are a requirement, not an optimization.** A pure AIR sees only adjacent rows and cannot express memory consistency, lookup arguments, or any constraint relating distant rows. LogUp uses verifier randomness to convert global multiset equalities into local accumulator constraints, at the cost of a few extra columns per bus. Without this mechanism, AIR-based zkVMs would be impossible.

4. **Small fields exploit the hardware register hierarchy.** A 31-bit prime is the largest whose product fits in a single 64-bit register, eliminating multi-limb arithmetic. Combined with SIMD packing (16 elements per 512-bit vector), small fields deliver 10× per-element speedup over 256-bit fields. Extension fields supply the missing soundness for verifier challenges, at a cost of $\approx 9/w$ overhead relative to base field NTT work.

5. **The NTT optimizes by fitting into cache, not by algorithmic improvement.** The four-step decomposition restructures a size-$N$ NTT into $\sqrt{N}$ small NTTs that fit in L1 cache, eliminating the cache misses that dominate naive implementations. The asymptotic stays $O(N \log N)$ but the constant factor improves dramatically because the CPU stops waiting for RAM.

6. **The blowup factor $\rho$ trades prover speed against proof size.** Larger $\rho$ means each FRI query catches a cheater with higher probability, so fewer queries are needed and proofs are smaller, but every NTT and Merkle tree grows proportionally. Most production systems use $\rho = 2$ with grinding to compensate.

7. **Many "optimizations" are really commitment avoidance.** DEEP-ALI eliminates the composition polynomial commitment by reconstructing it from an out-of-domain trace evaluation; the same principle reappears as virtual polynomials in sum-check systems (Chapter 21). The general rule: any polynomial algebraically determined by already-committed polynomials does not need its own commitment. Evaluating it at one verifier-chosen point suffices.

8. **Random linear combination is the universal batching technique.** Batched FRI replaces $w$ separate FRI instances with one by combining all polynomials into a random linear combination, reducing FRI hashing by a factor of $w$. The soundness rests on the proximity gap conjecture, whose late-2025 partial refutation has driven the ecosystem toward larger blowup factors and provable-security parameter regimes.

9. **Grinding is essentially free up to $g \approx 32$.** Replacing FRI queries with proof-of-work shrinks proof size at sub-millisecond compute cost. Beyond 32 bits of grinding the wall-clock cost becomes noticeable, so production systems converge on $g$ between 16 and 32.

10. **Circle STARKs unlock Mersenne31.** The circle group over $M_{31}$ has order $2^{31}$, enabling NTT-like algorithms (via the doubling map $x \mapsto 2x^2 - 1$) over the field with the cheapest arithmetic of any 31-bit prime. Production provers using this stack achieve over 500,000 Poseidon2 hashes per second on commodity hardware.

11. **No single optimization is worth more than a single-digit factor.** The 50-300× speedup achieved by modern STARK provers compared to early ones comes from compounding many small wins: small fields, extension lifting, AIR width tuning, four-step NTT, DEEP-ALI, batched FRI, grinding, Circle STARKs. Each contributes individually; none replaces the others.

12. **STARKs and sum-check systems converge on the same principles via different mechanisms.** Both push the bulk of work into cheap arithmetic (small fields with extensions vs. small values within large fields). Both avoid unnecessary commitments (DEEP-ALI vs. virtual polynomials). The pipelines differ ($O(N \log N)$ NTT for STARKs vs. $O(N)$ sum-check; cheap Merkle commitments for STARKs vs. expensive MSMs for curve-based sum-check), but the design philosophies rhyme. Chapter 22 develops this comparison.

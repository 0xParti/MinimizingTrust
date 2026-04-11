# Chapter 20: Fast STARK Proving

> *This chapter assumes fluency with the STARK pipeline (Chapter 15), FRI (Chapter 10), the small-field/small-value ideas from Chapter 19. It parallels Chapter 19's treatment of sum-check prover optimization, now applied to the STARK side. Together these two chapters give a complete picture of how both proof traditions close the gap between witness computation and proof generation.*

A STARK prover does far more work than the computation it proves. Executing a million steps of a hash function takes microseconds. Proving that execution takes seconds. The ratio between "compute the answer" and "prove you computed it correctly" can exceed 1000× in early systems. Where does all that time go?

The answer is not one bottleneck but a shifting pipeline of them. For small traces, constraint evaluation and polynomial arithmetic consume most cycles. For medium traces, the number-theoretic transform (NTT) takes over, since its $O(N \log N)$ cost eventually dominates linear-time constraint evaluation. For the largest traces, Merkle hashing for FRI commitments becomes the wall. Profiling data from production systems confirms this progression: NTT can account for up to 91% of prover runtime in workloads dominated by polynomial operations, while Merkle tree construction dominates at roughly 60% in hash-intensive recursive proving workloads. The prover engineer's task is to push each bottleneck down until the next one surfaces, then push that one down too.

The trajectory of improvement has been dramatic. StarkWare's ethSTARK benchmark achieved 10,000 Poseidon hashes per second. Their Stone prover improved to 530 hashes per second on identical hardware (a different hash configuration). Then Stwo, built on Circle STARKs over the Mersenne31 field, reached over 500,000 Poseidon2 hashes per second on a quad-core Intel i7. On an M3 Pro it exceeded 620,000 per second. That is a 50× improvement over ethSTARK from algorithmic and field-choice optimizations alone, without GPU acceleration. Understanding how these gains were achieved is the subject of this chapter.

---

## The prover pipeline

The STARK prover executes a sequence of stages, each feeding into the next. Understanding where time goes requires tracing this pipeline end to end.

**Stage 1: Trace generation.** The prover runs the computation, filling the execution trace, a matrix with $w$ columns (registers) and $T$ rows (timesteps). For a hash function like Poseidon with 30 rounds and state width 12, the trace might have 12-24 columns and $30 \cdot B$ rows for $B$ input blocks. This stage performs the same arithmetic the original computation would, plus bookkeeping for each intermediate state. Cost: $O(w \cdot T)$ field operations with a small constant per cell.

**Stage 2: Constraint evaluation.** The prover evaluates the AIR constraint polynomials at every row. If the maximum constraint degree is $d$ over $w$ registers, each row costs $O(d \cdot w)$ field operations. Total: $O(d \cdot w \cdot T)$.

**Stage 3: Composition and quotient formation.** The prover forms the composition polynomial by batching all constraint quotients with random Fiat-Shamir challenges (Chapter 15). The composition polynomial has degree roughly $d \cdot T$.

**Stage 4: Low-degree extension (LDE).** The prover evaluates trace polynomials and the composition polynomial on a domain $D$ that is $\rho$ times larger than $H$, where $\rho$ is the blowup factor. The evaluation proceeds by inverse NTT (interpolation from $H$ to coefficient form) followed by forward NTT (evaluation on $D$). Each polynomial requires two NTTs costing $O(\rho T \log(\rho T))$. With $w$ columns, the total is $O(w \cdot \rho T \log(\rho T))$.

**Stage 5: Merkle commitment.** The prover hashes every row of the LDE matrix into a Merkle tree. The ethSTARK implementation groups all field elements in a "row" of the trace LDE into a single leaf, so the tree has $\rho T$ leaves. Building it requires $O(\rho T)$ hash invocations.

**Stage 6: FRI protocol.** The prover executes FRI folding rounds, each halving the polynomial via an NTT and committing the result in a Merkle tree. The total across $\log_2(\rho T / d)$ rounds is a geometric series of NTTs and trees, dominated by the first round.

**Stage 7: Query responses.** The prover opens Merkle paths at queried positions. This is fast (logarithmic per query) and rarely a bottleneck.

The relative costs shift with scale. At $T = 2^{16}$, constraint evaluation can dominate. At $T = 2^{20}$, NTT takes over. At $T = 2^{24}$, Merkle hashing becomes comparable to NTT. Optimization must address each stage in sequence.

---

## AIR design and the degree-blowup tradeoff

The encoding of a computation into an AIR often matters more than any algorithmic optimization applied afterward. Two designs for the same computation can differ in prover time by an order of magnitude.

The central tension is between trace width and constraint degree. A wider trace (more columns) with low-degree constraints breaks complex expressions into simpler pieces by storing intermediate values. A narrower trace (fewer columns) requires higher-degree constraints to compress the same logic. The Winterfell framework makes this explicit by defining the blowup factor as the smallest power of two greater than or equal to the highest transition constraint degree.

Consider a transition that computes $y = x^8$. With one column, the constraint is $P(\omega X) - P(X)^8 = 0$, degree 8. With three auxiliary columns storing $x^2$, $x^4$, $x^8$, the constraints become four degree-2 checks, where each squaring is $P_{i+1}(\omega X) - P_i(X)^2$. The constraint degree drops from 8 to 2, at the cost of widening the trace from 1 to 4 columns.

Why does constraint degree matter so much? The composition polynomial has degree roughly $d \cdot T$. FRI must prove a degree bound on this polynomial, so the LDE domain must be at least $d \cdot T \cdot \rho$ points. Every doubling of $d$ doubles the NTT size, the Merkle tree size, all FRI operations. A degree-8 constraint over $T = 2^{20}$ rows produces a composition polynomial of degree $\approx 2^{23}$, requiring an LDE domain of $2^{25}$ at blowup $\rho = 4$. Reducing to degree 2 drops the LDE domain to $2^{23}$, a 4× reduction in all subsequent stages. Most production systems keep constraint degree between 2 and 4.

### Periodic columns

Many computations repeat structure at regular intervals. A hash function applies the same round constants in a cycle of length $r$. A CPU cycles through a fixed instruction decode pattern.

**Periodic columns** exploit this repetition without wasting committed trace space. Define a polynomial $c(X)$ of degree $r - 1$ that cycles through constants on the trace domain. Since $c(X)$ is public and precomputed, it enters constraints as a known function, not a committed column. The Winterfell documentation notes that degrees of periodic columns depend on their cycle length but are typically close to 1, having minimal impact on the composition polynomial degree.

### Interaction columns and LogUp

After committing to the main trace, the verifier provides random challenges via Fiat-Shamir. The prover then extends the trace with **auxiliary columns** computed from these challenges, enabling permutation and lookup arguments within the AIR framework.

The LogUp technique reduces a lookup argument to a sum of rational functions. Given a table $t$ and lookup values $a_1, \ldots, a_T$, the prover must show every $a_i$ appears in $t$. LogUp introduces an auxiliary column accumulating partial sums of $\sum_i \frac{1}{a_i - \beta}$, where $\beta$ is a verifier challenge. The global sum equality becomes a local transition constraint on the accumulator, adding one or two columns but enabling lookups without the quotient-based permutation arguments of Chapter 13.

Interaction columns are sound because they depend on verifier randomness that the prover learns only after committing to the main trace. The prover cannot choose main trace values to game the auxiliary computation.

### Wide versus tall traces

The width-versus-height tradeoff extends beyond individual constraints to the overall trace architecture. A "wide" trace with many columns and few rows encodes the computation with low-degree constraints but requires more Merkle leaves per row (each leaf hashes $w$ field elements). A "tall" trace with fewer columns but more rows uses higher-degree constraints and needs fewer field elements per leaf.

For hash functions, where the computation is regular and the state width is fixed, the trace width maps naturally to the state size. For virtual machines, the choice is less obvious. A zkVM instruction like `ADD R1, R2, R3` touches three registers, a program counter, various flags. Representing all of these as separate columns creates a wide trace (50-100 columns in practice) with degree-2 or degree-3 constraints. Alternatively, encoding multiple values per column via bit-packing creates a narrower trace with higher-degree constraints to extract individual fields.

Production systems overwhelmingly favor wide traces. The NTT cost scales with $w \cdot T \cdot \log T$, so doubling $w$ while halving $T$ at the same constraint degree saves a factor of $\log(T/2) / \log T \approx 1$ on the NTT but reduces the blowup from the constraint degree. The commitment cost (Merkle hashing) is proportional to $w \cdot \rho \cdot T$, which is invariant under the width-height exchange when the product $w \cdot T$ (total trace area) stays constant. The constraint degree reduction is the tiebreaker.

---

## Small fields and extension field lifting

Chapter 19 showed that sum-check provers gain speed by exploiting small witness values within a 256-bit field. STARK provers take a more direct approach by working over an entirely different, smaller field.

Over a 31-bit prime, each field element fits in a single 32-bit word. Multiplication uses a native 32×32→64 instruction. SIMD vectorization processes 4-8 elements per cycle. The arithmetic speedup over 64-bit Goldilocks ($p = 2^{64} - 2^{32} + 1$) is roughly 4× per element; over 256-bit BN254 fields it exceeds 10×. One analysis reports a 40× performance improvement simply from moving to a smaller field.

The soundness problem is immediate. With a 31-bit field, a cheating prover can guess a random element with probability $2^{-31}$. A single challenge provides only 31 bits of security, far from the 128-bit target.

The solution is **extension field lifting**. Most work (trace generation, constraint evaluation, NTT) stays in the base field $\mathbb{F}_p$. Verifier challenges live in an extension field $\mathbb{F}_{p^k}$ for $k = 4$. Each extension element is a tuple of $k$ base field elements, with multiplication costing roughly $O(k^2)$ base operations (or $O(k \log k)$ via Karatsuba). The bulk of the prover's computation never touches extension arithmetic.

Two small primes dominate modern STARK proving:

**BabyBear** ($p = 2^{31} - 2^{27} + 1 = 15 \times 2^{27} + 1$). The multiplicative group has order $p - 1 = 15 \times 2^{27}$, so $2^{27}$ divides $p - 1$. This means the field supports NTTs of size up to $2^{27}$, sufficient for traces with over 100 million rows. RISC Zero's zkVM is built on BabyBear. With a quartic extension ($k = 4$), the extension field has $p^4 \approx 2^{124}$ elements, providing adequate soundness. For 128-bit security, an octic extension ($k = 8$, giving $p^8 \approx 2^{248}$) can be used at higher cost.

**Mersenne31** ($p = 2^{31} - 1$). This is a Mersenne prime, giving exceptionally cheap modular reduction: since $2^{31} \equiv 1 \pmod{p}$, a 64-bit product $ab$ splits as $\text{lo} + \text{hi} \cdot 2^{31}$, reducing to $\text{lo} + \text{hi}$ plus a conditional subtraction. No division or extended multiplication needed. However, the multiplicative group has order $p - 1 = 2(2^{30} - 1)$, which is divisible by 2 only once. Standard NTTs, which require power-of-two subgroups, cannot use this field. Circle STARKs (discussed below) solve this by using the circle group of order $p + 1 = 2^{31}$ instead. StarkWare's Stwo and Polygon's Plonky3 both exploit M31 through this mechanism.

**Worked example: BabyBear extension field arithmetic.**

Let $p = 2013265921$ (BabyBear). Consider the quartic extension $\mathbb{F}_{p^4} = \mathbb{F}_p[\alpha] / (m(\alpha))$ for an irreducible quartic $m$. An element is $a = a_0 + a_1\alpha + a_2\alpha^2 + a_3\alpha^3$ with each $a_i \in \mathbb{F}_p$.

A base field multiplication: $17 \times 42 = 714$. One 32-bit multiply, no reduction needed (result fits in $\mathbb{F}_p$).

An extension multiplication: $(a_0 + a_1\alpha + a_2\alpha^2 + a_3\alpha^3)(b_0 + b_1\alpha + b_2\alpha^2 + b_3\alpha^3)$. Expanding produces 16 terms, but Karatsuba reduces this to about 9 base field multiplications plus additions and reduction modulo $m(\alpha)$.

The prover's trace generation performs $w \cdot T$ base field multiplications. The NTT performs $O(w \cdot \rho T \log(\rho T))$ base field multiplications. FRI folding, which uses extension challenges, performs $O(\rho T \log(\rho T))$ extension multiplications, equivalent to $\approx 9 \cdot \rho T \log(\rho T)$ base operations. Since there are $w$ columns in the NTT stage but only one batched polynomial in FRI, the extension overhead is a factor of roughly $9/w$, which is small when $w \geq 20$.

---

## NTT optimization

The number-theoretic transform converts between coefficient and evaluation representations of polynomials. The prover needs this for low-degree extension (evaluating trace polynomials on the larger domain $D$) and for FRI folding (extracting even/odd parts via inverse NTT).

An NTT of size $N$ performs $O(N \log N)$ multiplications in $\log N$ "butterfly" stages. Each stage $k$ pairs elements at distance $N/2^k$. The first stages access widely separated memory addresses (stride $N/2$), causing cache misses on modern CPUs where L1 cache holds 32-64 KB. The last stages access nearby elements, which are cache-friendly.

### The four-step NTT

The **four-step NTT** restructures the computation for better cache locality. View the $N$-element array as a $\sqrt{N} \times \sqrt{N}$ matrix, then:

1. Perform $\sqrt{N}$ small NTTs of size $\sqrt{N}$ along each row (these fit in L1 cache)
2. Multiply each element by a twiddle factor (roots of unity)
3. Transpose the matrix
4. Perform $\sqrt{N}$ small NTTs along each row again

The transposition is one large-stride memory operation, but it happens once instead of at every stage. Row NTTs operate on contiguous memory, benefiting from cache lines and hardware prefetching. For $N = 2^{24}$ with $\sqrt{N} = 2^{12}$, each row NTT operates on $2^{12} \times 4 = 16$ KB, fitting comfortably in a 32 KB L1 cache.

GPU implementations extend this further. Research on GPU NTT optimization (Özcan, 2023) implements both "Merge" and "4-Step" NTT models for GPU architectures, where the memory hierarchy (global memory → shared memory → registers) creates an analogous cache structure. The four-step decomposition maps naturally to GPU thread blocks, with each block handling one row NTT in fast shared memory.

### The blowup factor tradeoff

The blowup factor $\rho = |D|/|H|$ controls the redundancy in the Reed-Solomon encoding. Larger $\rho$ means each FRI query catches a cheater with higher probability, requiring fewer queries, but it also means larger NTTs and Merkle trees.

The soundness per query depends on $\rho$. Under the standard (conjectured) analysis, each query contributes $\log_2 \rho$ bits of security. Under the proven analysis (which is more conservative), each query contributes roughly $\frac{1}{2}\log_2 \rho$ bits. This gap between conjectured and proven FRI soundness is one of the open problems in STARK security. StarkWare's SHARP production verifier uses a Reed-Solomon code with rate $1/\rho$ where $\rho = 16$ and 12 FRI queries, yielding $12 \times \log_2(16) = 48$ conjectured security bits from FRI alone. Adding 32 bits of grinding gives 80 bits total, which the a16z crypto security analysis identifies as providing "under 10 bits of wiggle room" against feasible GPU-powered attacks.

For systems targeting 128-bit security, the parameter choices tighten:

| Blowup $\rho$ | Queries for 128 bits (conjectured) | Queries for 128 bits (proven) | LDE size ($T = 2^{20}$) |
|----------------|-------------------------------------|-------------------------------|--------------------------|
| 2 | 128 | 256 | $2^{21}$ |
| 4 | 64 | 128 | $2^{22}$ |
| 8 | $\approx 43$ | $\approx 86$ | $2^{23}$ |
| 16 | 32 | 64 | $2^{24}$ |

Smaller blowup saves prover time (smaller NTTs and Merkle trees) but increases proof size (more query openings). Most modern systems use $\rho = 2$ combined with grinding to compensate.

**Worked example: NTT cost at $\rho = 2$ vs $\rho = 8$.**

Trace with $T = 2^{20}$ rows and $w = 40$ columns over BabyBear.

At $\rho = 2$, the LDE domain has $2^{21}$ points. Each column requires a forward NTT of size $2^{21}$. Total NTT work is $40 \times 2^{21} \times 21 \approx 1.76 \times 10^9$ base field multiplications.

At $\rho = 8$, the LDE domain has $2^{23}$ points. Total NTT work is $40 \times 2^{23} \times 23 \approx 7.7 \times 10^9$ base field multiplications.

The 4.4× difference in NTT cost is partially offset by needing fewer FRI queries at $\rho = 8$ (43 vs 128), which shrinks proof size. At $\rho = 2$ with 20 bits of grinding, the query count drops to 108, giving a proof size of roughly $108 \times 40 \times \log_2(2^{21}) \times 32 \approx 2.9$ MB of Merkle paths (before further optimizations). At $\rho = 8$ with the same grinding, only 36 queries are needed, giving $\approx 1.1$ MB. The blowup factor is the primary knob for trading prover speed against proof size.

---

## FRI optimization

FRI is where STARK proofs achieve succinctness. It is also where several of the most impactful optimizations apply.

### DEEP-ALI

The standard STARK protocol (Chapter 15) commits to both the trace polynomials and the composition polynomial in separate Merkle trees. DEEP-ALI (Domain Extension for Eliminating Pretenders, combined with the Algebraic Linking IOP) eliminates the separate composition commitment and simultaneously improves soundness.

After the prover commits to the trace, the verifier (via Fiat-Shamir) samples an **out-of-domain point** $z$ from outside both the trace domain $H$ and the LDE domain $D$. The prover evaluates each trace polynomial at $z$ and at $\omega z$ (capturing the "next row"), sending these values to the verifier. The verifier locally computes what the composition polynomial should equal at $z$, since it knows the constraint equations and the claimed trace evaluations.

The protocol then constructs **DEEP quotients** for each trace column:

$$D_j(X) = \frac{P_j(X) - P_j(z)}{X - z}$$

If $P_j(z)$ is the true evaluation, this quotient is a polynomial of degree $\deg(P_j) - 1$. If the claimed value is wrong, the quotient has a pole at $z$, making it a rational function rather than a polynomial. Similarly, quotients at $\omega z$ verify the "next row" evaluations.

The prover batches all DEEP quotients into a single polynomial via random linear combination, then runs FRI on this batched polynomial. FRI proves low-degree-ness, which simultaneously verifies all claimed evaluations.

The savings are twofold. First, the prover avoids committing the composition polynomial on the full LDE domain, saving an entire Merkle tree of $\rho T$ leaves. Second, by forcing the prover to answer at a point outside $D$, DEEP-ALI closes the soundness gap in standard FRI. A cheating prover who faked values only on $D$ (maintaining low-degree appearance within the committed domain) cannot consistently answer at the out-of-domain point $z$. The DEEP-FRI paper (Ben-Sasson et al., 2019) proves that this technique improves the per-query soundness of the ALI protocol from a small constant below $1/8$ to a constant arbitrarily close to 1.

### Grinding

**Grinding** adds a proof-of-work step that trades prover CPU time for smaller proofs. After completing the FRI commitment phase, the prover searches for a 64-bit nonce that, when hashed together with the transcript, produces a hash with $g$ leading zero bits. This costs the prover $2^g$ hash evaluations on average.

The security accounting credits $g$ bits from grinding toward the total target. If $\lambda = 128$ bits of security are needed and grinding provides $g = 20$ bits, then FRI queries need only contribute $\lambda - g = 108$ bits. An honest prover grinds once; a cheating prover who alters any commitment must grind again from scratch, since the hash input changes.

Production systems use grinding aggressively. The ethSTARK documentation specifies 32 bits of grinding in conjunction with $\rho = 16$ and 12 queries, targeting 80 bits of total security. For Winterfell's Baby Bear configuration targeting 112-bit security, 15 bits of proof-of-work are specified. Grinding is embarrassingly parallel (independent nonces test on separate cores), so even 32 bits of grinding completes in under a second on modern hardware.

### Batched FRI

Running separate FRI instances for each of $w$ trace columns would multiply all FRI costs by $w$. **Batched FRI** avoids this by combining all polynomials into one.

The verifier provides random challenges $\gamma_1, \ldots, \gamma_w$ via Fiat-Shamir. The prover forms:

$$F(X) = \sum_{j=1}^{w} \gamma_j \cdot P_j(X)$$

A single FRI instance proves $F$ has degree less than $T$. If some $P_j$ had degree $\geq T$, the random combination $F$ would inherit this with high probability, since the $\gamma_j$ would need to conspire to cancel the high-degree terms. Schwartz-Zippel bounds this probability at $T / |\mathbb{F}|$.

Combined with DEEP-ALI, the batched polynomial incorporates both the DEEP quotients and the trace polynomials in a single random linear combination. One FRI instance handles degree verification, out-of-domain evaluation consistency, composition polynomial correctness simultaneously. STARKPack (Nethermind) extends this further by batching across multiple proof instances, achieving roughly 2× verifier speedup and 3× proof size reduction for typical configurations (traces with $2^{16}$ rows and 100 columns).

The savings scale with trace width. Without batching, $w = 50$ columns require 50 parallel Merkle trees per FRI round. With batching, one tree suffices. This reduces hashing by a factor of $w$.

### Circle FRI

Chapter 15 introduced Circle STARKs. Circle FRI adapts the FRI folding protocol to the circle group structure.

Over $M_{31} = 2^{31} - 1$, the circle group $\{(x, y) \in \mathbb{F}_p^2 : x^2 + y^2 = 1\}$ has order $p + 1 = 2^{31}$, a perfect power of two. Polynomials on the circle are not standard univariates but elements of a Riemann-Roch space, consisting of polynomials modulo the relation $x^2 + y^2 = 1$. This means $y^2$ terms reduce to $1 - x^2$, so every polynomial expression on the circle involves $y$ at most linearly.

The first round of Circle FRI exploits the $y$-symmetry. For opposite points $(x, y)$ and $(x, -y)$ on the circle, the folding decomposes a function $F$ into even and odd parts:

$$f_0(x) = \frac{F(x, y) + F(x, -y)}{2}, \quad f_1(x) = \frac{F(x, y) - F(x, -y)}{2y}$$

Given a random challenge $\alpha$, the folded function is $f_0 + \alpha \cdot f_1$, now depending only on $x$. This halves the domain.

Subsequent rounds use the **doubling map** $x \mapsto 2x^2 - 1$, which arises from the angle-doubling formula $\cos(2\theta) = 2\cos^2(\theta) - 1$. Opposite $x$-values (points at angles $\theta$ and $\pi - \theta$) map to the same doubled coordinate. The folding at each subsequent round is:

$$f_0(2x^2 - 1) = \frac{F(x) + F(-x)}{2}, \quad f_1(2x^2 - 1) = \frac{F(x) - F(-x)}{2x}$$

Each round halves the domain, just as standard FRI halves via the squaring map $x \mapsto x^2$. The total work across all rounds forms the same geometric series, giving $O(N)$ total field operations for the folding itself.

The Circle STARKs paper (Haböck, Levit, Papini, 2024) reports a 1.4× speedup over traditional STARKs using BabyBear, attributable to M31's cheaper modular reduction. Combined with the 4× advantage of 31-bit over 64-bit arithmetic, Circle STARKs over M31 represent the current frontier of STARK proving speed.

---

## A worked example: proving Poseidon2 over Mersenne31

To ground these abstractions, consider proving 1024 invocations of Poseidon2 over M31 using Circle STARKs with $\rho = 2$.

**Setup.** Poseidon2 with state width 16 uses 8 full rounds and 14 partial rounds per permutation, for 22 rounds total. Each full round applies the S-box $x \mapsto x^5$ to all 16 state elements; each partial round applies it to one. An MDS matrix mixes the state after each S-box.

**Trace design.** The trace has $w = 16$ columns (state elements), plus auxiliary columns for the S-box decomposition. Since $x^5 = x \cdot (x^2)^2$, introducing one auxiliary column $q = x^2$ per active S-box element reduces the constraint degree from 5 to 3 (checking $q - x^2 = 0$ at degree 2, then $y - x \cdot q^2 = 0$ at degree 3). For full rounds, this adds 16 auxiliary columns; for partial rounds, just 1. Averaging over the round mix gives roughly 24 total columns.

The trace has $T = 1024 \times 22 = 22{,}528$ rows, rounded to $T = 2^{15} = 32{,}768$ (next power of two for Circle NTT compatibility).

**NTT.** At $\rho = 2$, the LDE domain has $2^{16} = 65{,}536$ points. Each of the 24 columns requires a Circle NTT of size $2^{16}$, costing $\approx 2^{16} \times 16 = 10^6$ M31 multiplications per column. Total: $24 \times 10^6 = 2.4 \times 10^7$ multiplications. Over M31, each multiplication is a single 32-bit multiply plus a shift-and-add reduction. With AVX2 processing 8 elements per SIMD instruction at 3 GHz, the NTT completes in roughly $2.4 \times 10^7 / (8 \times 3 \times 10^9) \approx 1$ ms.

**Merkle commitment.** The trace tree has $2^{16}$ leaves, each containing 24 field elements (one row). Building the tree: $2^{16}$ leaf hashes plus $2^{16} - 1$ internal hashes $\approx 1.3 \times 10^5$ hash invocations. Using a STARK-friendly hash (Poseidon2 over M31), each invocation is fast but still the dominant per-element cost.

**FRI.** With batched FRI, all 24 columns compress into one polynomial. The FRI folding chain has $\log_2(2^{16}) - \log_2(d) \approx 14$ rounds (depending on when the polynomial reduces to a constant). Each round requires a Circle NTT and Merkle tree at half the previous size. Total FRI work: geometric series summing to $\approx 2 \times 2^{16} \approx 1.3 \times 10^5$ multiplications plus $1.3 \times 10^5$ hashes.

**Security.** At $\rho = 2$, each query provides $\log_2(2) = 1$ bit of conjectured security. For 128-bit security with $g = 20$ bits of grinding, the prover needs 108 queries. The proof contains 108 Merkle path openings across the trace tree, the FRI layers, the DEEP quotients.

**Throughput.** The prover completes 1024 Poseidon2 hashes in a few milliseconds on a single core, giving throughput in the range of $10^5$ to $10^6$ hashes per second, consistent with the Stwo benchmarks. At this scale, the NTT and Merkle hashing are roughly balanced.

---

## Comparison with sum-check optimization

Chapters 19 and 20 solve the same problem from opposite directions. The techniques differ because the cost structures differ.

Sum-check provers run in $O(N)$ field operations. The bottleneck lies in the sum-check rounds themselves plus polynomial commitment openings. Optimization focuses on reducing cost per operation through small-value tricks, delayed binding, Karatsuba for high-degree products. Polynomial commitments (MSM for curve-based schemes) are a separate cost center, often the dominant one, addressed in Chapter 21.

STARK provers pay an $O(N \log N)$ NTT cost that sum-check avoids entirely, since multilinear polynomials need no Fourier transform. But their Merkle commitments are vastly cheaper than the MSMs that curve-based sum-check systems require. A Merkle commitment costs one hash per element; a KZG commitment costs one elliptic curve scalar multiplication per element, roughly 3000× more expensive per operation.

Both traditions exploit the principle of doing most work in cheap arithmetic. Sum-check provers work over 256-bit fields but exploit small witness values for fast ss/sb multiplications in early rounds (Chapter 19). STARK provers work over 31-bit base fields, lifting to 124-bit extension fields only for verifier challenges. The mechanism differs (small values within a large field vs. a genuinely small field with extensions) but the economics are identical: the prover's heaviest rounds coincide with the regime where the cheapest arithmetic applies.

Neither tradition dominates universally. STARKs pay $\log N$ overhead per element but get cheap commitments. Sum-check achieves linear time but faces expensive commitments. At small scales with structured computations (hashing), STARKs excel because their Merkle-based commitments scale linearly while curve-based MSMs grow superlinearly. At large scales with sparse constraints, sum-check's $O(T)$ sparse proving (Chapter 19) pulls ahead because the NTT processes the entire trace regardless of sparsity.

The convergence of the two traditions is already underway. Binius (Chapter 25) uses sum-check over binary tower fields with FRI-based commitments, combining sum-check's linear-time proving with hash-based post-quantum commitments. Systems like Plonky3 support both quotienting-based and sum-check-based frontends over the same small-field backend. Chapter 22 develops this comparison fully.

---

## Key takeaways

1. **The STARK prover pipeline has multiple bottlenecks that shift with scale.** Constraint evaluation dominates for small traces; NTT dominates for medium traces ($T = 2^{18}$ to $2^{24}$); Merkle hashing dominates at the largest scales. Optimization must address each stage in turn.

2. **Constraint degree is the primary AIR design lever.** The composition polynomial has degree $d \cdot T$, so doubling $d$ doubles the NTT cost, the Merkle tree size, the FRI work. Auxiliary columns that reduce constraint degree from $d$ to $d'$ are worthwhile whenever the extra column cost is less than the $d/d'$ savings downstream.

3. **Small base fields with extension field lifting provide the largest speedups.** BabyBear ($p = 15 \times 2^{27} + 1$) supports NTTs up to $2^{27}$ with 31-bit arithmetic. M31 ($p = 2^{31} - 1$) gives even cheaper reduction via the Mersenne structure. Extension fields ($\mathbb{F}_{p^4}$) provide soundness for challenges without slowing down the bulk computation.

4. **The four-step NTT enables cache-efficient proving.** Decomposing a size-$N$ NTT into $\sqrt{N}$ row-NTTs of size $\sqrt{N}$, separated by a single transposition, keeps working sets in L1 cache. This is invisible in $O(N \log N)$ analysis but determines the constant factor.

5. **DEEP-ALI eliminates the composition polynomial commitment and closes a soundness gap.** Sampling an out-of-domain point $z$ and forming DEEP quotients $\frac{P_j(X) - P_j(z)}{X - z}$ forces consistency at a point the prover could not anticipate, improving ALI soundness from below $1/8$ to near 1.

6. **Grinding trades hash computation for smaller proofs.** At 16-32 bits of proof-of-work, the prover spends negligible extra time but reduces the FRI query count, shrinking proof size. StarkWare's SHARP uses 32 bits of grinding with 12 queries at rate $1/16$ for 80 total bits of security.

7. **Batched FRI reduces hashing by a factor of $w$.** Random linear combination of $w$ trace polynomials into a single polynomial requires only one Merkle tree per FRI round instead of $w$, with soundness loss bounded by Schwartz-Zippel.

8. **Circle STARKs unlock Mersenne primes.** The circle group over $M_{31}$ has order $2^{31}$, enabling NTT-like algorithms via the doubling map $x \mapsto 2x^2 - 1$. Stwo achieves over 500,000 Poseidon2 hashes per second on commodity hardware, a 50× improvement over ethSTARK.

9. **Conjectured FRI soundness exceeds proven bounds.** Each query contributes $\log_2 \rho$ bits under the standard conjecture but only $\frac{1}{2}\log_2 \rho$ bits under proven analysis. This 2× gap means production systems with tight security margins rely on unproven assumptions. The gap is an active area of research.

10. **STARKs and sum-check systems optimize against different cost profiles.** STARKs pay $O(N \log N)$ for NTT but get cheap Merkle commitments. Sum-check achieves $O(N)$ proving but needs expensive polynomial commitments (Chapter 21). Both exploit small-field arithmetic through different mechanisms. Neither dominates universally.

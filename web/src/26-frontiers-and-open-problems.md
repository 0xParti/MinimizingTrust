# Chapter 26: Frontiers and Open Problems

In 1900, Lord Kelvin told the British Association for the Advancement of Science that physics was essentially complete. Only "two small clouds" remained on the horizon: the failure of the Michelson-Morley experiment to detect the luminiferous ether, and the inability of classical theory to predict the spectrum of blackbody radiation. Those two clouds became special relativity and quantum mechanics. Kelvin had mistaken a plateau for a summit.

In 2020, SNARKs felt similarly settled. Groth16 for minimal proofs, PLONK for universal setups. The trade-offs seemed fixed, the design space mapped. Then came lookups (2020), folding schemes (2021), and binary field techniques (2023). Each opened territory that the previous framework couldn't reach.



## Small fields and Binius

Every proof system in this book operates over large prime fields, typically 254-bit or 256-bit elements. But most real-world data is small: booleans, bytes, 32-bit integers. Representing a single bit as a 256-bit field element wastes 255 bits of capacity. The waste is expensive. Field multiplications dominate prover time, and each multiplication operates on the full 256 bits even when the meaningful data is a single bit. For bit-level operations like hashing, AES, or bitwise logic, the overhead approaches 256×.

**Binius** attacks this problem directly by working over binary fields $\mathbb{F}_{2^k}$ where field elements are actual $k$-bit strings. A boolean is a 1-bit field element. A byte is an 8-bit field element. No padding, no waste.

The arithmetic of binary fields differs from prime fields. Addition is XOR (free in hardware). Multiplication uses polynomial arithmetic over $\mathbb{F}_2$. There are no "negative" elements; the field characteristic is 2. Binary fields lack the convenient structure of prime-order groups, but Binius recovers efficiency through protocol design that exploits the tower structure of binary extensions.

### Tower architecture

Rather than a single large field, Binius organizes computation in a tower of nested extensions: $\mathbb{F}_2 \subset \mathbb{F}_{2^2} \subset \mathbb{F}_{2^4} \subset \mathbb{F}_{2^8} \subset \ldots$ up to $\mathbb{F}_{2^{128}}$ for cryptographic security. Each level doubles the extension degree, and every element of a smaller field is automatically an element of every larger field above it. A bit in $\mathbb{F}_2$ is a valid element of $\mathbb{F}_{2^{128}}$; it's just a very special one.

This nesting enables a natural optimization. Witness data lives in the smallest field that fits: bits stay in $\mathbb{F}_2$, bytes in $\mathbb{F}_{2^8}$, 32-bit integers in $\mathbb{F}_{2^{32}}$. Arithmetic happens at the appropriate level. Only when the verifier's random challenges enter does computation lift to the full tower height. The 256× overhead vanishes.

(This "tower" is unrelated to the "tower of proofs" in Chapter 23's recursion discussion. There, "tower" refers to recursive proof composition $\pi_1 \to \pi_2 \to \pi_3$. Here, it refers to nested field extensions.)

### Protocol components

**GKR-based multiplication (multilinear).** Binary field multiplication is polynomial multiplication modulo an irreducible polynomial. Rather than encoding this as constraints, Binius uses the GKR protocol (Chapter 7) to verify multiplications via sum-check over multilinear extensions. The prover commits only to inputs and outputs; intermediate multiplication steps are checked interactively.

**FRI over binary fields (univariate).** For polynomial commitments, Binius adapts FRI to binary domains. The standard FRI folding doesn't directly transfer since the squaring map $x \mapsto x^2$ is not 2-to-1 on binary fields as it is over roots of unity. FRI-Binius instead uses *subspace vanishing polynomials* with an *additive NTT* to achieve the necessary folding structure, enabling commitment to polynomials over tiny fields like $\mathbb{F}_2$ with no embedding overhead.

Binius thus straddles both PIOP paradigms from Chapter 22: sum-check-based (multilinear) for the computation layer, FRI-based (univariate) for the commitment layer.

### Where it stands

For bit-intensive computations, Binius achieves order-of-magnitude improvements:

| Operation | Traditional (256-bit field) | Binius |
|-----------|-----------------------------|--------------------|
| SHA-256 hash | ~25,000 constraints | ~5,000 constraints |
| AES block | ~10,000 constraints | ~1,000 constraints |
| Bitwise AND | 1 constraint + range check | 1 native operation |

Fewer constraints mean smaller polynomials, faster transforms, smaller proofs. But the path from theory to deployment has been instructive about the real tradeoffs.

Irreducible (the primary Binius implementation team) archived the original Binius codebase in September 2025 and replaced it with **Binius64**, a simplified design that operates natively over 64-bit words. The pivot reflected lessons from production experience: the original tower architecture was too general for practical use. Binius64 retains the core ideas (binary field towers, GKR multiplication, FRI-Binius commitments) but targets CPU-based client-side proving rather than competing as a general-purpose zkVM. Early benchmarks show Binius64 on multi-threaded CPUs outperforming SP1 and R0VM on GPUs by roughly 5× for hash-based signature aggregation.

The tradeoffs that motivated the pivot remain relevant for any binary-field system. Binius achieves faster proving at the cost of larger proofs and slower verification than prime-field FRI. Recursion is harder because verifying a binary-field proof inside another binary-field proof requires embedding the arithmetic, and the algebraic structure that makes Binius fast for computation makes it awkward for recursive self-verification. Zero knowledge itself was not yet implemented as of the Binius64 launch, listed as the top priority for subsequent releases.

The benefits are also workload-dependent. Binius shines for bit-intensive operations (hashing, AES, bitwise logic) but the advantage shrinks for 32/64-bit arithmetic, memory operations, or control flow. The Binius64 team's focus on signature aggregation and client-side proving suggests binary fields may find their niche in specialized components rather than full VM execution, composed with prime-field provers via the techniques from Chapter 23.

The broader principle holds regardless of Binius's specific trajectory: matching the proof system's field to the computation's natural representation eliminates artificial overhead.

Field representation is only one axis of adaptation. Another looms larger: the cryptographic assumptions themselves.

## Post-quantum SNARKs

Every system in Part IV of this book (Groth16, PLONK, KZG-based constructions) rests on the hardness of discrete logarithm or elliptic curve problems. These will break once cryptographically relevant quantum computers exist, because they all share **hidden periodic structure in abelian groups** that Shor's algorithm exploits via the quantum Fourier transform.

Timeline estimates have compressed sharply. Recent results reducing the qubit requirements for breaking elliptic curve cryptography (from millions to hundreds of thousands under newer architectures) have moved several expert assessments into the 5-10 year range. Google targets 2029 for full post-quantum migration; the Global Risk Institute rates a cryptographically relevant quantum computer as "quite possible" within 10 years. Even conservative government planning horizons have shortened to 15-25 years. For infrastructure with long lifespans (financial systems, identity, archival signatures) the question is no longer whether to prepare but how fast.

### Paths forward

**Hash-based systems.** STARKs and FRI rely only on collision-resistant hashing. Hash functions resist Shor (no hidden periodic structure). The best known quantum attack on hashes is Grover's algorithm, which searches an unstructured space of $N$ elements in $\sqrt{N}$ steps instead of $N$. This is a quadratic speedup, not an exponential one, so doubling the hash output (e.g., from 128-bit to 256-bit security) neutralizes it entirely. Beyond FRI, WHIR (EUROCRYPT 2025) provides a hash-based multilinear PCS with faster verification, giving sum-check-based provers (Chapter 22) a post-quantum commitment scheme without switching to the univariate/STARK paradigm. The Ethereum Foundation's Whirlaway stack (Chapter 24) combines WHIR with SuperSpartan for exactly this purpose. Hash-based systems are the current practical choice for post-quantum proofs. Their proof sizes are larger than pairing-based alternatives, but they work today.

**Lattice-based commitments.** Replace Pedersen commitments with schemes based on Module-LWE or similar lattice problems. Lattices resist quantum attacks because the problem of finding short vectors in high-dimensional lattices has no known abelian group structure for the QFT to extract. A polynomial commitment encodes coefficients as a lattice point, with the hardness of finding short vectors ensuring binding and noise flooding or rejection sampling providing hiding. The algebraic structure is richer than hashes, enabling homomorphic operations on commitments that support sum-check-style protocols. The tradeoff is noise growth: LWE noise accumulates with operations, eventually overwhelming the signal unless parameters grow. Recent work is closing the efficiency gap. Hachi (eprint 2026/156) achieves a multilinear PCS under Module-SIS with ~55KB proofs and verification 12.5× faster than prior lattice constructions, bringing lattice-based commitments closer to practical use in sum-check-based proof systems (Chapter 24 discusses the implications for SNARK selection).

**Symmetric-key SNARKs.** The MPC-in-the-head paradigm (Chapter 25) builds proofs entirely from hash-based commitments, with no algebraic assumptions at all. Ligero improved this with linear-time proving via interleaved Reed-Solomon codes, but constants remain large (10-100× slower than algebraic SNARKs). Security reduces to collision resistance of the hash function.

### Open problems

Three interrelated challenges define this frontier. Lattice-based polynomial commitments remain 10-100× slower than hash-based alternatives; closing this gap while maintaining rigorous security is an active research problem. Security reductions are often loose, so the concrete security is much worse than asymptotic claims suggest. Tighter reductions would either increase confidence or reveal that larger parameters are needed. The transition period creates its own problem: building hybrid systems secure against *both* classical and quantum adversaries without paying twice the cost.

The post-quantum transition will reshape the SNARK landscape, but it operates on a timescale of years to decades. A different revolution is already underway.

## zkVMs

Every proof system we've studied requires translating the computation into a constraint system: R1CS, AIR, PLONKish gates. This translation is a specialized craft. Experts hand-optimize circuits for months; a single bug invalidates the work. The barrier to entry is enormous.

zkVMs invert this relationship. Instead of adapting computations to proof systems, adapt proof systems to computations. Compile any program to a standard virtual machine (RISC-V, EVM, WASM) and prove correct execution. The zkVM handles memory, branching, loops, function calls. Write your logic in Rust. Compile to the target ISA. Prove execution. No circuit engineering required.

### The current race

The zkVM landscape has stratified into distinct architectural approaches.

**SP1 (Succinct).** The most widely adopted zkVM, powering OP Succinct rollups, Polygon's Agglayer, and Celestia's bridge to Ethereum. Cross-table lookup architecture with a precompile system that accelerates common operations (signature verification, hashing) by 5-10× over raw RISC-V. SP1 Hypercube (2025) moved from STARKs to multilinear polynomials, achieving near-real-time Ethereum proving: over 93% of L1 blocks proven in under 12 seconds (average 10.3s) on a cluster of ~160 RTX 4090 GPUs (~$300-400K in hardware). First general-purpose zkVM to eliminate proximity gap conjectures by leaving the FRI paradigm entirely.

**ZKsync Airbender.** STARK-based over Mersenne31 with a custom DEEP-ALI implementation, open-sourced and live on mainnet. Claims the highest single-GPU throughput: 21.8 MHz (million cycles proven per second) on an H100, roughly 6× faster than competing zkVMs. Proves an average Ethereum block in ~17 seconds on a single H100 before recursion, ~35 seconds end-to-end. Designed as the proving backbone for the ZK Stack, with proving costs under $0.0001 per transfer.

**RISC Zero.** STARK-based with FRI commitments over BabyBear, targeting RISC-V. Uses continuations to split large computations into bounded segments (~$10^6$ cycles), proves each independently, then aggregates via recursion. Final proofs wrap in Groth16 for cheap on-chain verification. R0VM 2.0 (April 2025) reduced Ethereum block proving from 35 minutes to 44 seconds. The Boundless network provides a decentralized proof marketplace.

*Note on continuations:* Instead of proving the entire computation history at each step, continuations prove only the current segment plus a commitment to the previous segment's final state. This lets you pause and resume computation at arbitrary points, bounding peak prover memory regardless of total computation length.

**Jolt (a16z).** Built entirely on multilinear polynomials and the Lasso lookup argument (Chapter 21). Implements CPU instructions via lookups into structured tables rather than hand-crafted constraints. Achieves over 1 million RISC-V cycles per second on a 32-core CPU with ~50KB proofs, an order of magnitude smaller than STARK-based alternatives with roughly 10× lower prover overhead per cycle. A streaming prover is under development for arbitrarily long executions in under 2GB RAM. Jolt does not yet support recursion or continuation, which limits direct comparison with SP1 and RISC Zero on long computations.

**Zisk (Polygon spinoff).** Spun out of Polygon's zkEVM team (led by co-founder Jordi Baylina) in June 2025, with all Polygon zkEVM IP transferred. Built on RISC-V 64, designed for low-latency distributed proving with a 1.5 GHz zkVM execution engine, GPU-optimized code, and advanced aggregation circuits.

The convergence across these systems is notable: multilinear polynomials displacing univariate STARKs, real-time Ethereum proving as the benchmark target, precompiles for common cryptographic operations. Techniques developed for one system transfer rapidly to others.

### Design patterns from production

Beyond the specific systems, several design patterns have emerged that generalize across implementations.

Physical CPUs distinguish registers (fast, few) from memory (slow, large). In ZK circuits this distinction vanishes because both register access and memory access are polynomial lookups with identical cost. Valida exploited this by eliminating general-purpose registers entirely in favor of a stack machine, reducing per-cycle constraint count. The deeper lesson is that zkVM architectures should not inherit assumptions from physical hardware that have no analogue in the proving system.

Long computations face a memory wall: proving $10^9$ cycles requires holding intermediate state for $10^9$ steps. Segment-based proving (pioneered by RISC Zero) splits execution into bounded segments of roughly $10^6$ cycles, proves each independently, then aggregates via recursive composition. Peak prover memory stays bounded regardless of total computation length.

Memory consistency can be verified through Merkle trees (hashing inside the circuit, expensive) or through algebraic challenges that accumulate memory operations into fingerprint polynomials and verify consistency via Schwartz-Zippel. The challenge approach, formalized in Twist-and-Shout (Chapter 21) and used in SP1 and Jolt, relies only on field arithmetic and is 10× faster or more for memory-heavy workloads.

Finally, zkVMs expose *precompiles* for operations that appear frequently and have specialized efficient circuits (SHA256, Keccak, ECDSA, pairings). These run 10-100× faster than interpreted execution at the cost of additional engineering complexity per precompile. The ECDSA verification bottleneck has also driven adoption of EdDSA over "embedded" curves like BabyJubJub, whose base field matches the scalar field of the outer proving curve so that signature verification becomes native field arithmetic.

### Open problems

The overhead gap is the defining challenge. Current zkVMs run 100-1000× slower than native computation; the near-term target is 10×. Where does this overhead come from, and which parts are compressible?

Part of it is inherent: every operation must produce a cryptographic trace, and that trace must be committed and checked. But much of the overhead is structural. Memory is one source. A 4GB address space means $2^{32}$ potential cells, far too many to commit individually. Virtual polynomial techniques (Chapter 21) help, but scaling to gigabytes of working memory remains open. Precompile selection is another. Current systems hand-pick which operations get dedicated circuits based on blockchain workloads. General-purpose proving may need different choices, and automating precompile discovery (profiling hot operations and generating specialized circuits) would change the economics of zkVM design. Sequentiality is a third source. Most zkVMs execute instructions one at a time, each depending on the previous state. Proving parallel programs efficiently, or even exploiting prover-side parallelism for sequential programs, remains largely unexplored.

These problems are connected. Memory overhead limits the computations you can prove. Precompile overhead limits the operations worth proving. Sequential execution limits the hardware you can exploit. Solving any one of them shifts the bottleneck to the others.

But speed means nothing if the proofs are wrong.

## Formal verification

A soundness bug in a ZK system is unlike most software bugs. A crash announces itself; a soundness bug operates in silence. An attacker forges proofs, the verifier accepts, the system behaves as though everything is fine. By the time the compromise is discovered, the damage is done. High-profile vulnerabilities have been found in deployed systems: missing constraint checks that allowed invalid witnesses to pass, incorrect range assumptions that permitted overflow attacks, field confusion bugs where values were interpreted in the wrong field.

Several defenses are gaining traction. Verified compilers prove that compilation from a high-level circuit language to low-level constraints preserves semantics. Machine-checked soundness proofs (in Coq, Lean, Isabelle) establish that the protocol is sound by construction. OpenVM's RV32IM extension was formally verified in Lean by Nethermind Research in early 2026, and SP1 Hypercube's core RISC-V chips have been verified in Lean as well. Static analysis tools detect common vulnerability patterns before deployment: unconstrained variables, degree violations, missing range checks.

The persistent challenge is the gaps between verified components. You might verify the compiler but not the runtime, the protocol but not the implementation, the circuit but not the witness generator. Bugs hide at the boundaries. End-to-end verification, from source code to final proof, remains open. So does verification of optimized implementations: the fastest provers use hand-tuned assembly and GPU kernels that are inherently hard to reason about formally.

Formal verification addresses correctness. The remaining frontiers are systems-level problems: making proofs faster to generate, cheaper to verify at scale, and applicable to demanding workloads.

## Deployment frontiers

Several bottlenecks sit between correct proof systems and practical deployment. They are less glamorous than new cryptographic constructions but increasingly determine what is actually buildable.

**Hardware and memory.** Prover computation (MSMs, NTTs, hashing) is massively parallel, making GPUs 10-100× faster than CPUs for these workloads. But the binding constraint is increasingly memory bandwidth rather than arithmetic throughput. Large circuits require gigabytes of data, and memory transfer between CPU and GPU often exceeds computation time. Proof systems designed around GPU memory hierarchy rather than adapted to it after the fact would look very different from what we have.

**Witness generation.** Academic benchmarks report "prover time" as the cryptographic work (commitments, sum-check, polynomial evaluations), but witness generation (computing all $O(n)$ intermediate values for an $n$-gate circuit) often takes longer. A paper might report "proving takes 10 seconds" while silently omitting that witness generation took 60 seconds. The two scale differently: proving parallelizes across GPUs while witness generation is often sequential and memory-bound. For zkVMs, the execution trace already exists; translating it into the format the prover needs is the expensive step.

**Aggregation.** A rollup processing millions of transactions generates millions of proofs. Verifying them individually costs $O(n)$ time. Recursive aggregation (Chapter 23) collapses $n$ proofs into one but adds prover overhead. Proof compression (wrapping a STARK in a Groth16 proof) is already standard. The open targets are incremental aggregation (adding proof $n+1$ without recomputing the aggregate) and cross-system aggregation (combining proofs from different proof systems into a single attestation).

**Privacy-preserving ML.** The most demanding application on the horizon. Proof of inference for small neural networks (thousands of parameters) is tractable but carries 100×+ overhead. Proof of training at GPT scale (billions of parameters, trillions of operations) remains far out of reach. Non-linearities (ReLU, softmax) are expensive in arithmetic circuits; "ZK-friendly" model architectures with amenable activation functions could help but remain speculative. FHE offers a complementary path where the server computes on encrypted data without seeing the inputs (Chapter 27), with hybrid ZK+FHE approaches under active research.

## Theoretical foundations

The engineering frontiers above rest on theoretical questions that remain open.

We lack tight lower bounds on proof size for a given soundness error. We have constructions, but no matching impossibility results. Perhaps dramatically better systems are possible; perhaps we're close to optimal. The answer determines whether to keep searching or focus on engineering.

Deep recursion may degrade knowledge soundness. Current security reductions lose tightness with each recursive layer. Whether this is inherent or an artifact of our proof techniques matters directly for the recursive composition that underpins modern zkVMs.

The assumptions underlying SNARKs (knowledge assumptions, generic group model) are stronger than standard cryptographic assumptions. Whether they hold is a matter of ongoing debate. Resolving this either validates the foundations or forces a rethinking of what we build on.

SNARK techniques also have implications beyond cryptography. Progress on proof compression connects to circuit lower bounds, algebraic computation, and the structure of NP. These are among the deepest problems in theoretical computer science.

The field is young enough that systems considered optimal five years ago have already been superseded. Some patterns are visible: post-quantum concerns driving hash-based systems, zkVMs becoming the default abstraction, multilinear polynomials displacing univariate encodings. But ZK proofs are part of a larger landscape that includes fully homomorphic encryption, program obfuscation, and the convergence of programmable cryptography. The next chapter steps back to see where ZK fits in that broader picture.

## Key takeaways

1. **Binary fields eliminate representation overhead.** Binius and its successor Binius64 prove that matching the field to the data (bits as bits, bytes as bytes) removes the 256× penalty of encoding small values in large prime fields. The tower architecture enables this without sacrificing cryptographic security.

2. **Post-quantum migration is accelerating.** Hash-based systems (STARKs, WHIR) work today. Lattice-based commitments (Hachi) are closing the efficiency gap. The Ethereum Foundation targets 128-bit provable security by end of 2026. The question is no longer whether to prepare but how fast.

3. **zkVMs are converging on multilinear proofs.** SP1, Jolt, and the Ethereum Foundation's Whirlaway stack have moved to multilinear polynomials and sum-check, while Airbender and RISC Zero push STARK-based approaches to their limits. Real-time Ethereum block proving is now achieved by multiple teams.

4. **Formal verification is catching up to deployment.** Machine-checked proofs in Lean now cover core zkVM components (OpenVM, SP1 Hypercube). The persistent gap is end-to-end verification from source code to final proof, especially for optimized GPU implementations.

5. **The bottleneck is shifting from cryptography to systems engineering.** Witness generation, memory bandwidth, precompile selection, and proof aggregation increasingly determine real-world performance more than the choice of proof system.

6. **Tight lower bounds remain unknown.** We lack matching impossibility results for proof size, and deep recursion may degrade knowledge soundness in ways we cannot yet quantify. The theoretical foundations are solid but incomplete.

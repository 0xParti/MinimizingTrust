# Chapter 24: Choosing a SNARK

In 2016, Zcash launched with Groth16. The choice seemed obvious: smallest proofs, fastest verification, mature implementation. But Groth16 required a trusted setup ceremony. Six participants generated randomness, then destroyed their computers. The protocol was secure only if at least one participant was honest. If all six had colluded or been compromised, they could reconstruct the secret, mint unlimited currency, and no one would ever know.

Three years later, the Zcash team switched to Halo 2. No trusted setup. The proofs were larger. The proving was slower. But the existential risk evaporated.

This is the nature of SNARK selection: every choice trades one virtue for another. There is no universal optimum, no "best" system. There is only the right system for your constraints, your threat model, your willingness to accept which category of failure.

The preceding chapters developed a complete toolkit: sum-check protocols, polynomial commitments, arithmetization schemes, zero-knowledge techniques, composition and recursion. Each admits multiple instantiations. The combinations number in the dozens. Each combination produces a system with different properties: proof sizes ranging from 128 bytes to 100 kilobytes, proving times from milliseconds to hours, trust assumptions from ceremony-dependent to fully transparent.

This chapter provides a framework for navigating that landscape. Not a prescription (the field moves too fast for prescriptions) but a map of the territory and a compass for orientation.

## The Five Axes of Trade-off

Every SNARK balances five properties. Improve one, and another suffers. The physics of cryptography permits no free lunch.

### Proof Size

How many bytes cross the wire? For on-chain verification, proof size translates directly to gas costs (the blockchain section below gives concrete numbers). The spectrum spans three orders of magnitude:

- **Constant-size** (~100-300 bytes): Groth16, PLONK with KZG
- **Logarithmic** (~1-10 KB): Bulletproofs, Spartan
- **Polylogarithmic** (~10-100+ KB): STARKs, FRI-based systems

For on-chain verification, proof size is often the binding constraint. Everything else is negotiable.

### Verification Time

How fast can the verifier check the proof?

On-chain, verification time translates directly to gas costs. A pairing operation costs roughly 45,000 gas. Groth16 needs 3 pairings. PLONK needs about 10. STARKs replace pairings with hashes, but require many of them.

The hierarchy:

- **Constant-time** (~3 pairings): Groth16
- **Logarithmic** (~10-20 pairings): PLONK, IPA-based systems
- **Polylogarithmic** (hash-dominated): STARKs

Groth16's 3-pairing verification is hard to beat. Everything else is playing catch-up. But pairings rely on discrete log, which Shor's algorithm breaks, so this advantage may not survive the quantum transition.

### Prover Time

How fast can an honest prover generate a proof?

For small circuits, this barely matters. For zkVMs processing real programs, it's everything.

Consider a billion-constraint proof. At $O(n)$, with each field operation taking 10 nanoseconds, proving takes about 10 seconds. At $O(n \log n)$, with $\log n \approx 30$, the same proof takes 5 minutes. At $O(n^2)$, it takes 300 years.

The hierarchy:

- **Linear in constraint count**: Sum-check-based systems (Spartan, Lasso, Jolt)
- **Quasilinear** ($O(n \log n)$): PLONK, Groth16, FFT-dominated systems
- **Superlinear**: Some theoretical constructions (impractical at scale)

At billion-constraint scale, the $\log n$ factor (roughly 30) is the difference between a 10-second proof and a 5-minute proof. This is why zkVMs have increasingly moved toward sum-check-based architectures: when proving a million CPU instructions at 50 constraints each, linear time is a requirement, not a luxury.

The gap is wider than the asymptotics suggest. FFT-based provers (Groth16, PLONK) perform butterfly operations that jump across memory at strides of $N/2$, thrashing caches and stalling on RAM latency (Chapter 20 develops this in detail). Sum-check provers scan data linearly, keeping it streaming through the cache hierarchy. At billion-constraint scale, memory access patterns can dominate wall-clock time even more than the operation count, compounding sum-check's asymptotic advantage with a large constant-factor improvement.

### Trust Assumptions

What must you trust for security?

The Zcash ceremony involved six participants on three continents. Each generated randomness, contributed to the parameters, then destroyed their machines. One participant used a Faraday cage. Another broadcast from an airplane. The paranoia was justified: if *all six* colluded or were compromised, they could mint unlimited currency, and the counterfeits would be cryptographically indistinguishable from real coins.

This is the price of trusted setup.

The spectrum:

- **Circuit-specific trusted setup** (Groth16): Each circuit requires its own ceremony. Change the circuit, repeat the ritual.
- **Universal trusted setup** (PLONK, Marlin): One ceremony supports all circuits up to a size bound. The trust is amortized, not eliminated.
- **Transparent** (STARKs, Bulletproofs): No trusted setup. Security derives entirely from public-coin randomness and standard assumptions.

Transparency eliminates an entire category of catastrophic failure, at the cost of larger proofs, sometimes by two orders of magnitude.

### Post-Quantum Security

Will the system survive Shor's algorithm?

Shor's algorithm solves discrete logarithm and factoring in polynomial time on a quantum computer. The day a cryptographically relevant quantum computer boots, every pairing-based SNARK becomes insecure. Groth16 proofs could be forged. KZG commitments could be opened to false values. The entire security model collapses.

The threatened systems:

- All pairing-based SNARKs (Groth16, KZG-based PLONK)
- All discrete-log commitments (Pedersen, Bulletproofs)

The resistant systems form a growing family:

- Hash-based constructions (STARKs with FRI, WHIR-based systems)
- Sum-check + hash-based PCS (Whirlaway combines SuperSpartan with WHIR, achieving both multilinear proving and post-quantum security with proofs smaller than FRI at the same security level)
- Lattice-based commitments (LatticeFold, Neo; under active research, not yet production-ready)

The sum-check tradition is no longer tied to discrete-log commitments. WHIR (EUROCRYPT 2025) provides a hash-based multilinear PCS with faster verification than FRI, enabling sum-check-based provers to achieve post-quantum security without switching to the univariate/STARK paradigm. This closes a gap that previously forced sum-check systems to rely on IPA or KZG, both quantum-vulnerable.

When will quantum computers arrive? Estimates as of 2026 range from 5 to 20 years for cryptographically relevant machines, with the timeline compressing as investment accelerates. For a private transaction, the uncertainty is tolerable. For infrastructure meant to last decades (identity systems, legal records, financial settlements), the Ethereum Foundation's response is instructive: provable 128-bit security by end of 2026, with proof-size caps that push the ecosystem toward hash-based schemes.

## The System Landscape

Each major proof system occupies a different position in the trade-off space. None dominates all others. The choice depends on which constraints bind tightest.

### Groth16: The Incumbent

Groth16 has the smallest proofs in the business: 128 bytes, three group elements. Verification requires three pairings. Implementations exist in every language, optimized for every platform, battle-tested across billions of dollars in transactions.

The cost is trust. Every circuit needs its own ceremony. Change one constraint, and the parameters are worthless. The ceremony participants must be trusted absolutely, or the "toxic waste" (the secret randomness) must never be reconstructed.

This combination (minimal proofs, maximal trust) made Groth16 the default for years. It remains dominant for on-chain verification where proof size is the binding constraint and the application can absorb a one-time ceremony.

### PLONK: The Flexible Middle Ground

PLONK solved Groth16's upgrade problem. A single ceremony generates parameters that work for any circuit up to a size bound. Modify the circuit, keep the same parameters. The trust is amortized across an ecosystem rather than concentrated on a single application.

Proofs grow to 500-2000 bytes. Verification requires more pairings. But the flexibility is transformative: zkEVMs can upgrade their circuits without coordinating new ceremonies. Application developers can iterate without security theater.

Custom gates push PLONK further. Where Groth16 accepts only R1CS, PLONK's constraint system accommodates specialized operations. A hash function that requires 10,000 R1CS constraints might need only 100 Plonkish constraints with a custom gate.

Variants proliferated: UltraPLONK, TurboPLONK, HyperPLONK, each optimizing a different axis (proof size, custom gates, multilinear polynomials). PLONK became the platform on which much of the industry standardized for general-purpose proving.

### STARKs: The Transparent Option

STARKs eliminate trust entirely. No ceremony. No toxic waste. No existential risk from compromised participants. Security rests on collision-resistant hashing, nothing more.

The price is size. STARK proofs run 50-100+ KB, sometimes larger. Verification is polylogarithmic rather than constant. For on-chain deployment, this can be prohibitive.

But STARKs offer compensations. Provers approach linear time (Chapter 20 develops how FRI folding and small-field techniques achieve this). Hash-based constructions are believed to be post-quantum secure, since the best known quantum attack (Grover's algorithm) provides only a quadratic speedup, manageable by doubling the hash output size. And there's a philosophical clarity: the proof stands alone, answerable only to mathematics.

StarkWare built a company on this trade-off. For rollups processing millions of transactions, the amortized proof cost per transaction becomes negligible. The prover speed matters; the verifier runs once.

### Bulletproofs: The Pairing-Free Path

Bulletproofs occupy a specific niche: transparency without the STARK size explosion. Proofs grow logarithmically (typically 600-700 bytes for range proofs). No trusted setup. No pairings required.

The tradeoff is that verification takes linear time in the circuit size. For small circuits (range proofs, confidential transactions), this is acceptable. For large computations, it becomes prohibitive.

Monero adopted Bulletproofs for confidential amounts. The proofs are small enough to fit in transactions, transparent enough to satisfy decentralization purists, and specialized enough for the specific task of range proofs.

But Bulletproofs aren't post-quantum. They rely on discrete log hardness. The same quantum computer that breaks Groth16 breaks Bulletproofs.

### Sum-check-based systems

Spartan, Lasso, Jolt, HyperPlonk, Binius, and the Whirlaway stack all belong to the sum-check tradition described in Chapters 19-21. Their shared characteristic is linear-time proving, which at billion-constraint scale is the difference between a 10-second proof and a 5-minute one.

Virtual polynomials minimize commitment costs (Chapter 21). Sparse sum-check handles irregular constraint structures naturally. The apparatus is optimized for general-purpose computation, which is why zkVMs have increasingly adopted sum-check architectures.

Sum-check systems produce larger proofs (logarithmic, not constant), have newer implementations (less battle-tested), and historically depended on discrete-log-based PCS (IPA, KZG) that made them quantum-vulnerable. This last limitation is dissolving from two directions. WHIR (EUROCRYPT 2025) provides a hash-based multilinear PCS with faster verification than FRI; Hachi (eprint 2026/156) provides a lattice-based multilinear PCS under Module-SIS with $\approx 55$ KB proofs and 12.5× faster verification than prior lattice schemes. Whirlaway (SuperSpartan + WHIR) demonstrates that sum-check-based systems can achieve post-quantum security without switching to the univariate/STARK paradigm. The Ethereum Foundation's Lean Ethereum project is building a minimal zkVM on this stack (KoalaBear field, WHIR PCS, sum-check proving), targeting post-quantum on-chain verification.

### The converging zkVM landscape

The boundaries between the categories above are blurring in production zkVMs. The major systems as of 2026:

- **SP1** (Succinct): migrated from STARK-based (SP1 Turbo, FRI over BabyBear) to sum-check-based (SP1 Hypercube, multilinear polynomials with a jagged PCS from Chapter 21 and Logup-GKR). Proves over 93% of Ethereum blocks in under 12 seconds (average 10.3s) on a cluster of ~160 RTX 4090 GPUs (~$300-400K in hardware).
- **RISC Zero**: STARK-based with FRI over BabyBear, Groth16 wrapper for on-chain verification. Proves Ethereum blocks in under 45 seconds.
- **Jolt** (a16z): pure sum-check with Lasso lookups (Chapter 21) and Twist/Shout memory checking. Over 1 million RISC-V cycles per second on a 32-core CPU.
- **ZKsync Airbender**: STARK-based over Mersenne31 with a custom DEEP-ALI implementation.
- **Zisk** (Polygon spinoff): RISC-V 64 with a 1.5 GHz execution engine, optimized for low-latency distributed proving.
- **Lean Ethereum** (Ethereum Foundation): minimal zkVM using Whirlaway (SuperSpartan + WHIR) over KoalaBear, targeting provable 128-bit post-quantum security.

All of these use small fields (BabyBear or Mersenne31), AIR or CCS constraints, and Logup-style bus arguments for cross-table consistency. The convergence on shared primitives (Chapter 20) is striking even as the architectural choices diverge.

## Application-Specific Guidance

Theory meets practice at the application boundary. The abstract trade-offs crystallize into concrete decisions.

### Blockchain Verification (On-Chain)

The verifier runs on Ethereum, paying gas for every operation. Two costs dominate: calldata (bytes shipped to the chain) and computation (opcodes executed on-chain).

At current gas prices, a 128-byte Groth16 proof costs about 20,000 gas in calldata. Verification adds roughly 150,000 gas for the pairing checks. Total: under 200,000 gas. A simple ETH transfer costs 21,000 gas. The proof verification is economically viable.

A 50 KB STARK costs 800,000 gas in calldata alone. Verification adds another 300,000-500,000 gas. Total: over a million gas. For individual transactions, this is often prohibitive.

Composition (Chapter 23) bridges the gap. Generate a STARK proof (transparent, fast prover), then prove "the STARK verifier accepted" with Groth16 (small proof, cheap verification). The inner STARK provides transparency; the outer Groth16 provides on-chain efficiency. The trust assumption applies only to the wrapper. The economics favor large computations: wrapping a million-constraint STARK in Groth16 adds $\approx 50{,}000$ constraints for the STARK verifier (5% overhead), while wrapping a thousand-constraint STARK adds 50× overhead.

### zkRollups

Rollups amortize proof costs across thousands of transactions. A proof that costs 200,000 gas becomes 20 gas per transaction when it covers 10,000 transactions. The economics invert. Larger proofs become tolerable when they aggregate more computation.

StarkNet uses STARKs directly. The proofs are large (100+ KB), but the amortization across massive batches makes the per-transaction cost negligible. The transparency is a feature, not a compromise.

zkSync and Scroll use Groth16 wrappers around internal proving systems. The outer proof is tiny. The inner system can be whatever works best for their EVM implementation.

Prover efficiency matters most (the prover runs for every batch), while proof size matters less (it amortizes across all transactions in the batch).

### zkVMs

Proving correct execution of arbitrary programs requires billions of constraints. The system landscape section above lists the major zkVMs; the choosing question is which architectural pattern fits your deployment.

The binding constraint is prover speed. A 10-second proof is a feature. A 10-minute proof is a bug. Virtual polynomials (Chapter 21) minimize commitment costs; lookup arguments (Chapter 14) replace expensive constraint checks with table lookups; small fields (Chapter 20) cut per-operation cost by 10×. Everything is oriented toward making the prover faster.

On-chain verification still demands small proofs, so zkVMs follow the same composition pattern described in the blockchain section above (STARK or sum-check inner proof, Groth16 wrapper for Ethereum). Eliminating this wrapper, via STARK verification precompiles on Ethereum or efficient hash-based on-chain verification via WHIR, is an active area of work.

### Privacy-Preserving Applications

When zero-knowledge is the point (not just a bonus), implementation quality matters as much as theoretical properties.

Groth16 and PLONK produce ZK proofs with modest overhead. The masking techniques are well-understood. But implementation errors can leak information through timing side channels, error messages, or malformed proof handling.

STARKs require more care. The execution trace is exposed during proving, then masked. The masking must be done correctly. A bug here doesn't crash the system; it silently leaks witnesses. You might never know until the damage is done.

Tornado Cash used Groth16. Zcash used Groth16, then Halo 2. Aztec uses UltraPlonk and Honk (PLONK variants co-developed by the Aztec team). All chose mature implementations with extensive auditing, because privacy failures are catastrophic and silent.

Beyond the choice of proof system, privacy applications face a second decision that further constrains the options: *where the prover runs*. **Server-side proving** (zkRollups, zkVMs) runs provers on powerful infrastructure; the witness data reaches the server, which generates proofs and posts them on-chain. Privacy comes from the proof hiding witness details from the chain, not from the prover. **Client-side proving** (Aztec, Zcash) runs provers on user devices, so sensitive data never leaves the machine and only the proof and minimal public inputs reach the network.

Client-side proving constrains system choice dramatically. A browser or mobile device can't match datacenter hardware. Aztec's architecture is instructive: private functions execute locally, requiring proof systems efficient enough for consumer hardware. This rules out anything demanding server-grade resources for reasonable latency.

### Post-quantum applications

The "Post-Quantum Security" axis above lists the resistant systems (STARKs, WHIR-based, lattice-based). For application guidance, the critical distinction is between integrity and privacy. For integrity-only applications (proving a computation was correct, no sensitive data in the witness), a dual-proof strategy works: generate both a classical proof (for efficiency today) and a post-quantum proof (for survival tomorrow), and migrate when quantum threatens. For applications involving *private data*, the dual strategy fails. A "harvest now, decrypt later" adversary records classical proofs today and breaks them with a future quantum computer, retroactively extracting the witness. Private data needs post-quantum security from day one.

## The Trade-Off Triangle

Project managers know the Iron Triangle: Fast, Good, Cheap. Pick two. SNARKs have their own version: **Succinct, Transparent, Fast Proving**. The physics of cryptography enforces the same brutal constraint.

Three properties stand in tension: **proof size, prover time, and trust assumptions**.

| System | Proof Size | Prover Time | Trust |
|--------|-----------|-------------|-------|
| Groth16 | Minimal (128 B) | Quasilinear | Maximal (circuit-specific) |
| PLONK | Small (500 B) | Quasilinear | Moderate (universal) |
| STARKs | Large (50+ KB) | Linear | None |

Pick any two vertices. The third suffers.

This is not a failure of engineering. It's a reflection of information-theoretic and complexity-theoretic constraints. Small proofs require structured commitments. Structured commitments require trusted setup or expensive verification. Fast provers require simple commitment schemes. Simple commitment schemes produce large proofs.

Every production system that appears to break this triangle does so through composition (Chapter 23). Halo 2 wraps a transparent IPA-based inner proof in a succinct accumulation scheme. RISC Zero and SP1 wrap transparent STARKs in Groth16. Folding-based systems defer all verification to a single final SNARK. In each case, the "escape" is architectural complexity: two or more proof systems cooperating, each contributing the vertex it handles best.

## Implementation Realities

The best algorithm with a buggy implementation is worse than a mediocre algorithm implemented correctly.

### Audit status

ZK bugs are silent: a soundness error lets attackers forge proofs, a witness leak exposes private data, and neither produces error messages. Zcash's Sprout had a soundness bug for years, discovered by a researcher rather than an attacker. Use audited implementations; multiple recent audits matter more than theoretical elegance.

### Hardware acceleration

GPU proving is now standard for production zkVMs, with 10-100× speedups over CPU for NTT and MSM operations. SP1 Hypercube achieves real-time Ethereum proving on 16 GPUs. The choice of proof system constrains which hardware optimizations are available: NTT-heavy systems (STARKs, PLONK) benefit most from GPU parallelism, while sum-check provers with linear memory access patterns also parallelize well across CPU cores via SIMD (Chapter 20).

### Tooling

The choice of proof system often follows from the available tooling rather than the other way around. Circom targets Groth16 and PLONK circuits. Cairo is StarkWare's language for STARK-based programs. Noir (Aztec) compiles to multiple backends. At the library level, Arkworks provides modular Rust primitives for field arithmetic, curves, and SNARK components, and Plonky3 (Polygon) is the shared proving framework underlying SP1, OpenVM, and several other production zkVMs, with pluggable field backends (BabyBear, Mersenne31) and a modular AIR interface. Mature tooling compounds over time; switching frameworks mid-project is expensive.

## Quick Reference

| System | Proof Size | Verify Time | Prove Time | Setup | Post-Quantum |
|--------|-----------|-------------|------------|-------|--------------|
| Groth16 | ~128 B | 3 pairings | $O(n \log n)$ | Circuit-specific | No |
| PLONK+KZG | ~500 B | ~10 pairings | $O(n \log n)$ | Universal | No |
| STARK (FRI) | ~50-100 KB | $O(\log^2 n)$ hashes | $O(n)$ | Transparent | Yes |
| Bulletproofs | ~600 B + log | $O(n)$ exp | $O(n)$ exp | Transparent | No |
| Spartan/Jolt | ~log KB | $O(\log n)$ exp | $O(n)$ | Transparent | No |
| Whirlaway (WHIR) | ~50-100 KB | $O(\log^2 n)$ hashes | $O(n)$ | Transparent | Yes |


## Key Takeaways

1. **Every application has a binding constraint; the system choice follows from it.** On-chain verification binds on proof size (Groth16/PLONK). zkVMs bind on prover speed (sum-check/STARKs). Privacy binds on implementation quality and client-side efficiency. Long-lived infrastructure binds on quantum resistance (hash-based systems only). Identify which constraint binds tightest; the rest is negotiable.

2. **The trade-off triangle is inescapable within a single system.** Small proofs + fast provers requires trusted setup. Small proofs + transparent requires slow verification. Fast provers + transparent requires large proofs. Composition (Chapter 23) breaks the triangle by combining systems, at the cost of architectural complexity.

3. **Sum-check systems are no longer quantum-vulnerable.** WHIR and Hachi provide hash-based and lattice-based multilinear PCS respectively, closing the gap that previously forced sum-check provers onto discrete-log commitments. For private data, post-quantum security is needed from day one (harvest-now-decrypt-later attacks make deferred migration dangerous).

4. **The zkVM landscape is converging on shared primitives.** Small fields, AIR or CCS constraints, Logup bus arguments, and STARK→Groth16 composition appear across SP1, RISC Zero, Jolt, ZKsync Airbender, and Lean Ethereum, even as their architectural choices diverge. Plonky3 and Arkworks provide the shared infrastructure.

5. **Tooling and audit status constrain choices as much as theory.** ZK bugs are silent (Zcash's Sprout had a soundness bug for years), so multiple recent audits matter more than theoretical elegance. Mature tooling compounds; switching frameworks mid-project is expensive.

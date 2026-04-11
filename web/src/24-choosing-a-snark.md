# Chapter 24: Choosing a SNARK

In 2016, Zcash launched with Groth16. The choice seemed obvious: smallest proofs, fastest verification, mature implementation. But Groth16 required a trusted setup ceremony. Six participants generated randomness, then destroyed their computers. The protocol was secure only if at least one participant was honest. If all six had colluded or been compromised, they could reconstruct the secret, mint unlimited currency, and no one would ever know.

Three years later, the Zcash team switched to Halo 2. No trusted setup. The proofs were larger. The proving was slower. But the existential risk evaporated.

This is the nature of SNARK selection: every choice trades one virtue for another. There is no universal optimum, no "best" system. There is only the right system for your constraints, your threat model, your willingness to accept which category of failure.

The preceding chapters developed a complete toolkit: sum-check protocols, polynomial commitments, arithmetization schemes, zero-knowledge techniques, composition and recursion. Each admits multiple instantiations. The combinations number in the dozens. Each combination produces a system with different properties: proof sizes ranging from 128 bytes to 100 kilobytes, proving times from milliseconds to hours, trust assumptions from ceremony-dependent to fully transparent.

This chapter provides a framework for navigating that landscape. Not a prescription (the field moves too fast for prescriptions) but a map of the territory and a compass for orientation.

## The Five Axes of Trade-off

Every SNARK balances five properties. Improve one, and another suffers. The physics of cryptography permits no free lunch.

### Proof Size

How many bytes cross the wire?

On Ethereum, calldata costs roughly 16 gas per byte. A 128-byte Groth16 proof costs about 2,000 gas in calldata. A 50 KB STARK costs 800,000 gas. That's not a rounding error. That's the difference between a viable product and an economic impossibility.

The spectrum spans three orders of magnitude:

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

Groth16's 3-pairing verification is hard to beat. Everything else is playing catch-up. But pairings are the first casualty of quantum computers, so "hard to beat" may have an expiration date.

### Prover Time

How fast can an honest prover generate a proof?

For small circuits, this barely matters. For zkVMs processing real programs, it's everything.

Consider a billion-constraint proof. At $O(n)$, with each field operation taking 10 nanoseconds, proving takes about 10 seconds. At $O(n \log n)$, with $\log n \approx 30$, the same proof takes 5 minutes. At $O(n^2)$, it takes 300 years.

The hierarchy:

- **Linear in constraint count**: Sum-check-based systems (Spartan, Lasso, Jolt)
- **Quasilinear** ($O(n \log n)$): PLONK, Groth16, FFT-dominated systems
- **Superlinear**: Some theoretical constructions (impractical at scale)

The $\log n$ factor seems innocuous. It determines whether a proof finishes during a coffee break or overnight.

But asymptotic complexity tells only half the story. FFT-based provers (Groth16, PLONK) jump randomly through memory, thrashing caches and stalling on RAM latency. Sum-check provers scan linearly, keeping data streaming through the cache hierarchy. At billion-constraint scale, the memory access pattern can matter as much as the operation count.

### Trust Assumptions

What must you trust for security?

The Zcash ceremony involved six participants on three continents. Each generated randomness, contributed to the parameters, then destroyed their machines. One participant used a Faraday cage. Another broadcast from an airplane. The paranoia was justified: if *all six* colluded or were compromised, they could mint unlimited currency, and the counterfeits would be cryptographically indistinguishable from real coins.

This is the price of trusted setup.

The spectrum:

- **Circuit-specific trusted setup** (Groth16): Each circuit requires its own ceremony. Change the circuit, repeat the ritual.
- **Universal trusted setup** (PLONK, Marlin): One ceremony supports all circuits up to a size bound. The trust is amortized, not eliminated.
- **Transparent** (STARKs, Bulletproofs): No trusted setup. Security derives entirely from public-coin randomness and standard assumptions.

Transparency eliminates an entire category of catastrophic failure. The cost: larger proofs, sometimes by two orders of magnitude.

### Post-Quantum Security

Will the system survive Shor's algorithm?

Shor's algorithm solves discrete logarithm and factoring in polynomial time on a quantum computer. The day a cryptographically relevant quantum computer boots, every pairing-based SNARK becomes insecure. Groth16 proofs could be forged. KZG commitments could be opened to false values. The entire security model collapses.

The threatened systems:

- All pairing-based SNARKs (Groth16, KZG-based PLONK)
- All discrete-log commitments (Pedersen, Bulletproofs)

The resistant systems:

- Hash-based constructions (STARKs, FRI)

When will quantum computers arrive? Estimates range from 10 to 30 years. For a private transaction, that uncertainty is tolerable. For infrastructure meant to last decades (identity systems, legal records, financial settlements), it's a sword hanging overhead.

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

The ecosystem followed. UltraPLONK, TurboPLONK, HyperPLONK. Each variant optimizes a different aspect. The platform became an industry standard for general-purpose proving.

### STARKs: The Transparent Option

STARKs eliminate trust entirely. No ceremony. No toxic waste. No existential risk from compromised participants. Security rests on collision-resistant hashing, nothing more.

The price is size. STARK proofs run 50-100+ KB, sometimes larger. Verification is polylogarithmic rather than constant. For on-chain deployment, this can be prohibitive.

But STARKs offer compensations. Provers approach linear time (FRI folding is remarkably efficient). Post-quantum security is plausible (hash functions resist known quantum attacks). And there's a philosophical clarity: the proof stands alone, answerable only to mathematics.

StarkWare built a company on this trade-off. For rollups processing millions of transactions, the amortized proof cost per transaction becomes negligible. The prover speed matters; the verifier runs once.

### Bulletproofs: The Pairing-Free Path

Bulletproofs occupy a specific niche: transparency without the STARK size explosion. Proofs grow logarithmically (typically 600-700 bytes for range proofs). No trusted setup. No pairings required.

The catch: verification takes linear time in the circuit size. For small circuits (range proofs, confidential transactions), this is acceptable. For large computations, it becomes prohibitive.

Monero adopted Bulletproofs for confidential amounts. The proofs are small enough to fit in transactions, transparent enough to satisfy decentralization purists, and specialized enough for the specific task of range proofs.

But Bulletproofs aren't post-quantum. They rely on discrete log hardness. The same quantum computer that breaks Groth16 breaks Bulletproofs.

### Sum-Check-Based Systems: The New Frontier

Spartan. Lasso. Jolt. These systems represent the sum-check renaissance described in Chapters 19-21. Their characteristic: linear-time proving.

For zkVMs proving billion-instruction programs, this isn't an optimization. It's the difference between feasibility and fantasy. A 30× speedup (from $O(n \log n)$ to $O(n)$) determines whether proving takes minutes or hours.

Virtual polynomials minimize commitment costs. Sparse sum-check handles irregular constraint structures naturally. The entire apparatus is optimized for the specific challenge of general-purpose computation.

The trade-offs are familiar: larger proofs (logarithmic, not constant), newer implementations (less battle-tested), multilinear PCS requirements (different tooling). But for the zkVM use case, where prover speed dominates all other concerns, sum-check-based systems are becoming the default choice.

## Application-Specific Guidance

Theory meets practice at the application boundary. The abstract trade-offs crystallize into concrete decisions.

### Blockchain Verification (On-Chain)

The verifier runs on Ethereum, paying gas for every operation. Two costs dominate: calldata (bytes shipped to the chain) and computation (opcodes executed on-chain).

At current gas prices, a 128-byte Groth16 proof costs about 20,000 gas in calldata. Verification adds roughly 150,000 gas for the pairing checks. Total: under 200,000 gas. A simple ETH transfer costs 21,000 gas. The proof verification is economically viable.

A 50 KB STARK costs 800,000 gas in calldata alone. Verification adds another 300,000-500,000 gas. Total: over a million gas. For individual transactions, this is often prohibitive.

The solution: composition. Generate a STARK proof (transparent, fast prover), then wrap it in Groth16 (small proof, cheap verification). The inner STARK provides transparency. The outer Groth16 provides on-chain efficiency. The trust assumption applies only to the wrapper, not the original computation.

### zkRollups

Rollups amortize proof costs across thousands of transactions. A proof that costs 200,000 gas becomes 20 gas per transaction when it covers 10,000 transactions. The economics invert: larger proofs become tolerable if they aggregate more computation.

StarkNet uses STARKs directly. The proofs are large (100+ KB), but the amortization across massive batches makes the per-transaction cost negligible. The transparency is a feature, not a compromise.

zkSync and Scroll use Groth16 wrappers around internal proving systems. The outer proof is tiny. The inner system can be whatever works best for their EVM implementation.

The pattern: prover efficiency matters (it runs for every batch), proof size matters less (it amortizes across all transactions in the batch).

### zkVMs

Prove correct execution of arbitrary programs. The circuit is enormous: a single transaction might require billions of constraints.

Jolt uses sum-check with lookup arguments. RISC-Zero uses STARKs with AIR. SP1 uses a hybrid approach. All three optimize obsessively for prover speed.

The constraint: proving must be fast enough that users will wait for it. A 10-second proof is a feature. A 10-minute proof is a bug. A 10-hour proof is a research project, not a product.

Virtual polynomials (Chapter 21) minimize commitment costs. Lookup arguments (Chapter 14) replace expensive constraint checks with table lookups. Everything is oriented toward making the prover faster, because at billion-constraint scale, prover time is the binding constraint.

But on-chain verification still demands small proofs. The pattern that emerged: prove with a STARK (fast, transparent), then wrap in Groth16 (tiny proof, cheap verification). RISC-Zero, SP1, and others follow this architecture. The inner STARK handles billions of constraints with linear-time proving. The outer Groth16 compresses everything to 128 bytes for Ethereum. The trust assumption applies only to the wrapper ceremony, not to the original computation.

### Privacy-Preserving Applications

When zero-knowledge is the point (not just a bonus), implementation quality matters as much as theoretical properties.

Groth16 and PLONK produce ZK proofs with modest overhead. The masking techniques are well-understood. But implementation errors can leak information through timing side channels, error messages, or malformed proof handling.

STARKs require more care. The execution trace is exposed during proving, then masked. The masking must be done correctly. A bug here doesn't crash the system; it silently leaks witnesses. You might never know until the damage is done.

Tornado Cash used Groth16. Zcash used Groth16, then Halo 2. Aztec uses UltraPlonk and Honk (PLONK variants co-developed by the Aztec team). The pattern: mature implementations with extensive auditing, because privacy failures are catastrophic and silent.

The architecture splits into two camps. **Server-side proving** (zkRollups, zkVMs) runs provers on powerful infrastructure. The witness data reaches the server, which generates proofs and posts them on-chain. Privacy comes from the proof hiding witness details from the chain, not from the prover. **Client-side proving** (Aztec, Zcash) runs provers on user devices. Sensitive data never leaves the machine. Only the proof and minimal public inputs reach the network.

Client-side proving constrains system choice dramatically. A browser or mobile device can't match datacenter hardware. Aztec's architecture is instructive: private functions execute locally, requiring proof systems efficient enough for consumer hardware. This rules out anything demanding server-grade resources for reasonable latency.

### Post-Quantum Applications

Government identity systems. Land registries. Legal archives. Anything with a 20+ year horizon must consider quantum risk.

The rule is simple: avoid discrete log and pairings. That eliminates Groth16, PLONK with KZG, Bulletproofs, and most established systems.

STARKs remain. Hash-based systems survive Shor's algorithm (though Grover's algorithm reduces their security by roughly half, requiring larger parameters). Lattice-based SNARKs are under active research but aren't production-ready.

For the paranoid: generate proofs with two systems, one classical (for efficiency today) and one post-quantum (for survival tomorrow). Store both. Use the efficient one now; the post-quantum one is insurance.

### Low-Trust Environments

Some contexts admit no trust. Decentralized protocols where no ceremony could satisfy all participants. Adversarial settings where any trust assumption becomes an attack surface. Applications in jurisdictions where ceremony participants could be coerced.

Transparency is the only option. STARKs for large computations, Bulletproofs for smaller ones.

The larger proofs are not a bug. They are the manifestation of a theorem: you cannot simultaneously minimize proof size, eliminate trust, and achieve post-quantum security. Something must give. In low-trust environments, you know what to sacrifice.

## The Trade-Off Triangle

Project managers know the Iron Triangle: Fast, Good, Cheap. Pick two. SNARKs have their own version: **Succinct, Transparent, Fast Proving**. The physics of cryptography enforces the same brutal constraint.

Three properties stand in fundamental tension: **proof size, prover time, and trust assumptions**.

| System | Proof Size | Prover Time | Trust |
|--------|-----------|-------------|-------|
| Groth16 | Minimal (128 B) | Quasilinear | Maximal (circuit-specific) |
| PLONK | Small (500 B) | Quasilinear | Moderate (universal) |
| STARKs | Large (50+ KB) | Linear | None |

Pick any two vertices. The third suffers.

This is not a failure of engineering. It's a reflection of information-theoretic and complexity-theoretic constraints. Small proofs require structured commitments. Structured commitments require trusted setup or expensive verification. Fast provers require simple commitment schemes. Simple commitment schemes produce large proofs.

The systems that appear to break this triangle (Halo 2, for instance) achieve it through composition: a transparent inner system wrapped in a succinct outer system, accepting architectural complexity as the price of having it all.

## Implementation Realities

The best algorithm with a buggy implementation is worse than a mediocre algorithm implemented correctly.

### Audit Status

ZK bugs are silent killers. A soundness error lets attackers forge proofs. A witness leak exposes private data. Neither produces error messages or stack traces. The system works perfectly until someone exploits it.

Zcash's original Sprout implementation had a soundness bug for years. It was discovered by a researcher, not an attacker, and patched quietly. The alternative history, where an attacker found it first, is sobering.

Use audited implementations. Multiple audits are better than one. Fresh audits are better than old ones.

### Optimization Level

Groth16 has GPU implementations that achieve 10-100× speedups over CPU. PLONK is catching up. Sum-check systems are newer; optimization is ongoing.

If your application is latency-sensitive, check whether GPU proving exists for your chosen system. If it doesn't, factor in the proving time penalty.

### Tooling

Circom for Groth16 and PLONK. Cairo for STARKs. Noir for multiple backends. Leo for blockchain-specific applications.

Good tooling is force-multiplied engineering time. Bad tooling is hand-written assembly for constraint systems, which is roughly as pleasant as it sounds.

### Community

Abandoned implementations accumulate bugs. Active communities fix them. Check GitHub activity, not just stars. Recent commits matter more than total contributors.

## The Composition Escape Hatch

When no single system fits, compose multiple systems.

The canonical pattern: prove the main computation with a fast-prover system (STARK), then prove "the STARK verification succeeded" with a small-proof system (Groth16).

What you get:

- STARK's proving speed (applied to the large computation)
- STARK's transparency (the inner proof is private; only the outer proof is revealed)
- Groth16's proof size (only the wrapper touches the chain)
- Groth16's verification speed (three pairings, regardless of inner complexity)

What you pay:

- One additional proving step (the wrapper proof)
- Architectural complexity (two proving systems to maintain)
- The outer system's trust assumptions (if Groth16 wraps a STARK, you trust the Groth16 ceremony)

The economics work when the inner computation is large. Wrapping a million-constraint STARK in Groth16 adds perhaps 50,000 constraints for the STARK verifier. The overhead is 5%. Wrapping a thousand-constraint STARK in Groth16 adds 50× overhead. Composition is for the big computations.


## Quick Reference

| System | Proof Size | Verify Time | Prove Time | Setup | Post-Quantum |
|--------|-----------|-------------|------------|-------|--------------|
| Groth16 | ~128 B | 3 pairings | $O(n \log n)$ | Circuit-specific | No |
| PLONK+KZG | ~500 B | ~10 pairings | $O(n \log n)$ | Universal | No |
| STARK | ~50-100 KB | $O(\log^2 n)$ hashes | $O(n)$ | Transparent | Yes |
| Bulletproofs | ~600 B + log | $O(n)$ exp | $O(n)$ exp | Transparent | No |
| Spartan | ~log KB | $O(\log n)$ exp | $O(n)$ | Transparent | No |


## Key Takeaways

**The constraints that matter:**

1. **On-chain verification is proof-size constrained.** A 128-byte Groth16 proof costs ~2K gas in calldata. A 50KB STARK costs ~800K gas. For single-transaction proofs, this difference determines viability. Groth16 and PLONK with KZG dominate on-chain applications.

2. **Large computations are prover-time constrained.** At billion-constraint scale, the difference between $O(n)$ and $O(n \log n)$ is hours versus minutes. Sum-check systems (Spartan, Lasso, Jolt) and STARKs achieve linear-time proving.

3. **Privacy applications are implementation-quality constrained.** ZK bugs are silent: soundness errors let attackers forge proofs, witness leaks expose secrets, and neither produces error messages. Use audited implementations. Aztec's client-side proving model shows that efficiency on consumer hardware matters when sensitive data can't leave the device.

4. **Long-lived infrastructure is quantum constrained.** Shor's algorithm breaks discrete log and pairings. For 20+ year horizons (identity systems, legal archives), avoid pairing-based SNARKs. STARKs and hash-based systems survive.

**The trade-offs:**

5. **The trade-off triangle is fundamental.** Small proofs + fast provers → requires trusted setup (Groth16). Small proofs + transparent → requires slow verification (Bulletproofs). Fast provers + transparent → requires large proofs (STARKs). Pick any two vertices; the third suffers.

6. **Composition is the escape hatch.** Prove with a STARK (fast, transparent), wrap in Groth16 (tiny proof, cheap verification). zkVMs like RISC-Zero and SP1 use this pattern: the inner STARK handles billions of constraints; the outer Groth16 compresses to 128 bytes for Ethereum. The trust assumption applies only to the wrapper.

**The practical considerations:**

7. **Audit status matters more than theoretical properties.** Zcash's Sprout had a soundness bug for years. The alternative history where an attacker found it first is sobering. Multiple recent audits beat theoretical elegance.

8. **Tooling determines development velocity.** Circom for Groth16/PLONK. Cairo for STARKs. Noir for multiple backends. Good tooling is force-multiplied engineering time; bad tooling is hand-written constraint assembly.

**The fundamental insight:**

9. **No universal winner exists.** Applications have different binding constraints: proof size, prover time, trust model, quantum resistance, implementation maturity. Identify which constraint binds tightest. The system choice follows.

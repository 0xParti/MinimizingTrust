# Appendix B: Historical Timeline

The development of zero-knowledge proofs and succinct arguments spans four decades. This timeline traces the key theoretical breakthroughs and practical systems that shaped the field.



## Theoretical foundations (1985-1992)

**1985: GMR (Interactive Proofs and Zero-Knowledge)**
Goldwasser, Micali, and Rackoff introduce interactive proofs and define zero-knowledge. The paper "The Knowledge Complexity of Interactive Proof Systems" establishes the foundational concepts: completeness, soundness, and the simulation paradigm for zero-knowledge. A conceptual revolution: proving something is true without revealing why it's true.

**1986: Fiat-Shamir Transform**
Fiat and Shamir show how to eliminate interaction by replacing verifier randomness with hash function outputs. The prover computes challenges as hashes of the transcript, producing a non-interactive proof. The random oracle model provides the security analysis.

**1986-1987: GMW (Zero-Knowledge for All of NP)**
Goldreich, Micali, and Wigderson prove that every NP language has a zero-knowledge proof, assuming one-way functions exist. The graph 3-coloring construction is theoretical (impractical for real use) but establishes the surprising generality of zero-knowledge.

**1990: LFKN (Algebraic Interactive Proofs)**
Lund, Fortnow, Karloff, and Nisan develop the sum-check protocol for proving claims about polynomial sums. This algebraic technique becomes the cornerstone of later efficient protocols. The paper shows #P $\subseteq$ IP.

**1991: MIP = NEXP (Babai, Fortnow, Lund)**
Multi-prover interactive proofs, where the verifier interrogates two non-communicating provers, can verify nondeterministic exponential time computations. The result establishes the surprising power of multiple provers and connects to PCP theory.

**1992: IP = PSPACE (Shamir)**
Shamir proves that interactive proofs can verify exactly the problems solvable in polynomial space. The result uses multilinear extensions and sum-check, establishing the power of interaction + randomness.

**1992: The PCP Theorem (AS, ALMSS)**
Arora and Safra (AS) prove NP $\subseteq$ PCP[log n, polylog n]; Arora, Lund, Motwani, Sudan, and Szegedy (ALMSS) strengthen this to NP = PCP[log n, O(1)]. Every NP statement has a proof where the verifier reads only a constant number of bits. The theoretical foundation for succinct arguments.

**1992: Kilian's Succinct Arguments**
Kilian shows how to compile PCPs using Merkle trees and collision-resistant hashing. The prover commits to the PCP, the verifier queries random bits, and the prover opens with authentication paths. This is the first succinct argument for NP, with proof size polylogarithmic in the computation.



## The ZK winter (1992-2008)

For sixteen years, zero-knowledge proofs remained impractical. The PCP theorem promised succinct proofs, but the constructions had astronomical overhead ($O(n^{10})$ blowup in early versions). Researchers refined PCP constructions, developed new proof composition techniques, and explored connections to coding theory, but there were no implementations and no urgency.

Two developments changed that. In 2008, Goldwasser, Kalai, and Rothblum published GKR, showing that sum-check could verify arithmetic circuits with manageable overhead. In 2009, Bitcoin launched, creating a financial ecosystem with urgent demand for privacy, scalability, and trustless verification. The tool and the demand arrived at roughly the same time.



## Path to practical systems (2008-2016)

**2008: GKR (Efficient Verification of Arithmetic Circuits)**
Goldwasser, Kalai, and Rothblum develop a protocol for verifying layered arithmetic circuits using sum-check. The prover does polynomial work; the verifier does polylogarithmic work. Later refinements by Cormode, Mitzenmacher, and Thaler make it truly practical.

**2010: Groth10 (First Practical Pairing-Based SNARK)**
Groth introduces succinct arguments using pairings, building on ideas from linear PCPs. The construction enables constant-size proofs verified with a constant number of pairings.

**2010: Kate-Zaverucha-Goldberg (KZG) Commitments**
The KZG paper formalizes polynomial commitments using pairings. Commit to a polynomial with one group element; prove evaluations with one group element. This becomes the cryptographic engine for most practical SNARKs.

**2013: Pinocchio**
Parno, Howell, Gentry, and Raykova build the first complete, implemented SNARK for general computation. C programs compile to circuits; circuits compile to proofs. Real-world verification becomes possible.

**2014: Zcash Begins Development**
The Zerocoin team, building on Pinocchio, starts developing what becomes Zcash, the first major deployment of zkSNARKs for cryptocurrency privacy.

**2016: Groth16 (The Speed King)**
Groth publishes an optimized SNARK with the smallest known proofs (3 group elements) and fastest verification (3 pairings). Despite requiring per-circuit trusted setup, Groth16 becomes the de facto standard for production systems.

**2016: ZKBoo (MPC-in-the-Head)**
Giacomelli, Madsen, and Orlandi publish ZKBoo, the first practical implementation of "MPC-in-the-head." The prover simulates a multiparty computation internally, then lets the verifier audit random subsets. ZKBoo proves that zero-knowledge could be built entirely from symmetric primitives (hashes), offering a third path distinct from pairings (Groth16) and polynomial commitments (STARKs).



## The scaling era (2017-2020)

**2017: STARKs (Transparent Scalable Arguments)**
Ben-Sasson, Bentov, Horesh, and Riabzev introduce STARKs (Scalable Transparent ARguments of Knowledge). Based on FRI and hash functions, STARKs require no trusted setup and resist quantum attacks. Proofs are larger but prover time is quasi-linear.

**2018: Bulletproofs (Logarithmic Range Proofs)**
Bünz, Bootle, Boneh, Poelstra, Wuille, and Maxwell develop Bulletproofs using inner-product arguments. Logarithmic proof size for range proofs without trusted setup. Adopted by Monero for confidential transactions.

**2018: Zcash Sapling Upgrade**
Zcash launches Sapling with improved Groth16-based proofs. Proving time drops from ~40 seconds to ~7 seconds on mobile devices.

**2019: PLONK (Universal Setup)**
Gabizon, Williamson, and Ciobotaru introduce PLONK (Permutations over Lagrange-bases for Oecumenical Noninteractive arguments of Knowledge). One trusted setup ceremony supports all circuits up to a size bound. The permutation argument elegantly handles copy constraints.

**2019: Halo (Recursive Proofs Without Pairings)**
Bowe, Grigg, and Hopwood demonstrate recursion using inner-product arguments over elliptic curves, avoiding the pairing bottleneck. Proofs verify proofs verify proofs, with unlimited depth.

**2019-2020: zk-Rollups Emerge**
Teams including Loopring, zkSync, and StarkWare deploy zk-rollups on Ethereum. Transaction data lives on-chain; execution validity is proven off-chain. Throughput increases 100-1000×.

### Three lineages

By the end of this era, three distinct lineages of zero-knowledge proofs had emerged from a common ancestor:

```
                    Interactive Proofs (1985)
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
    PAIRING LINEAGE     HASH LINEAGE     SUM-CHECK LINEAGE
            │                 │                 │
            ▼                 ▼                 ▼
     Pinocchio (2013)    FRI (2017)        GKR (2008)
            │                 │                 │
            ▼                 ▼                 ▼
     Groth16 (2016)    STARKs (2017)    Spartan (2019)
            │                 │                 │
            ▼                 ▼                 ▼
      PLONK (2019)    Circle STARKs      Jolt (2023)
```

*Three lineages of zero-knowledge proofs, each with distinct cryptographic foundations: pairings, hashes, and sum-check.*



## The modern era (2020-present)

**2020-2022: Lookup Arguments Mature**
Plookup (Gabizon, Williamson, and Maller, 2020), cq, and other lookup protocols become standard. Table-based constraint checking replaces expensive algebraic encoding for range checks, bitwise operations, and memory access.

**2021-2022: Nova and Folding Schemes**
Kothapalli, Setty, and Tzialla introduce Nova, which replaces expensive recursive SNARK verification with cheap algebraic "folding." Per-step overhead drops from thousands of constraints to a handful of group operations.

**2022: Plonky2 (PLONK + FRI)**
Polygon Zero combines PLONK's flexible arithmetization with FRI's transparent polynomial commitments over a small Goldilocks field. Fast recursion (under 300ms on a laptop) enables practical proofs of Ethereum execution.

**2023: Lasso and Jolt**
Setty, Thaler, and colleagues develop Lasso (efficient lookups for sum-check-based systems) and Jolt (a RISC-V zkVM using these techniques). The sum-check renaissance: proving returns to its interactive-proof roots.

**2023: zkEVMs Launch**
Multiple teams (Polygon, Scroll, zkSync Era, Linea) deploy zkEVMs that prove Ethereum Virtual Machine execution. Arbitrary smart contracts gain ZK privacy or scalability.

**2023: SP1 and Competitive zkVMs**
Succinct Labs releases SP1, a RISC-V zkVM emphasizing developer experience. Competition intensifies: RISC Zero, Jolt, Valida, and others push proving speed and flexibility.

**2024: Circle STARKs and Small Fields**
StarkWare and others explore STARKs over small fields (Mersenne primes, binary towers), trading field size for faster arithmetic. Proof sizes shrink; prover speeds increase.

**2024-Present: Folding and IVC Proliferate**
Nova variants (SuperNova, HyperNova, ProtoStar) extend folding to handle complex constraint types. Incrementally verifiable computation becomes practical for long-running programs.

### Convergence

Modern zkVMs are the confluence of three decades of distinct research streams:

```
    SUM-CHECK              LOOKUPS              FOLDING
    (1990)                 (2020)               (2021)
        │                     │                    │
        │   LFKN, GKR         │   Plookup, Lasso   │   Nova, HyperNova
        │   Spartan           │   cq, Jolt         │   ProtoStar
        │                     │                    │
        └─────────────────────┼────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │     zkVMs       │
                    │                 │
                    │  Jolt, SP1,     │
                    │  RISC Zero,     │
                    │  Zisk           │
                    └─────────────────┘
```

*Modern systems like Jolt and SP1 combine sum-check's linear proving, lookup arguments' efficient table access, and folding's cheap recursion. The zkVM is where three rivers meet.*



## Visual timeline

```
1985 ─────── GMR: Interactive Proofs, Zero-Knowledge
1986 ─────── Fiat-Shamir Transform, GMW begins
1990 ─────── LFKN: Sum-Check Protocol
1991 ─────── MIP = NEXP (Multi-Prover Proofs)
1992 ─────── IP = PSPACE, PCP Theorem, Kilian
      │
2008 ─────── GKR Protocol
2010 ─────── Groth's First Pairing-Based SNARK
2010 ─────── KZG Polynomial Commitments
2013 ─────── Pinocchio (First Practical SNARK)
2016 ─────── Groth16 (Optimal Proof Size)
      │
2017 ─────── STARKs (Transparency)
2018 ─────── Bulletproofs (Range Proofs)
2019 ─────── PLONK (Universal Setup)
2019 ─────── Halo (Recursive Without Pairings)
2020 ─────── zk-Rollups Deploy, Plookup
      │
2022 ─────── Plonky2 (PLONK + FRI), Nova (Folding)
2023 ─────── Lasso/Jolt (Sum-Check Renaissance)
2023 ─────── zkEVMs Launch
2024 ─────── Circle STARKs, Small Fields
      │
      ▼
    NOW ─── Folding proliferates, zkVMs compete
```



## Key themes

**Theory to practice (1985-2016)**: Early work established that zero-knowledge proofs exist for all of NP, but constructions were impractical. The path from GMR to Groth16 took 31 years.

**The trusted setup debate (2016-2019)**: Groth16's efficiency came with per-circuit trusted setup. PLONK's universal setup and STARKs' transparency offered alternatives. The field fragmented into camps, each valid for different applications.

**The zkVM vision (2020-present)**: Rather than hand-crafting circuits for each application, prove correct execution of arbitrary programs. RISC-V emerges as the dominant target ISA.

**The sum-check renaissance (2022-present)**: After years of PCP-inspired constructions, the field rediscovers sum-check's elegance. Linear-time proving, virtual polynomials, and folding schemes push efficiency toward theoretical limits.

Chapter 26 surveys the active frontiers in detail.

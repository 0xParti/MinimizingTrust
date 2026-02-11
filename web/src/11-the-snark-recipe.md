# Chapter 11: The SNARK Recipe: Assembling the Pieces

Before 1913, building a car was a bespoke craft. Mechanics hand-fitted gears, engines, and chassis. It was slow, expensive, and inconsistent. Then Henry Ford introduced the assembly line. He realized that if you standardized the parts and the process, you could build complex machines at scale.

For the first 30 years of zero-knowledge (1985–2015), protocols were bespoke. A cryptographer would hand-craft a protocol for Graph Isomorphism, then start from scratch to build one for Hamiltonian Cycles. Each proof system was a custom creation, and expertise in one barely transferred to another.

Then came the realization: we don't need bespoke proofs. We need an assembly line. We need a standardized way to take *any* computation, feed it into a machine, and get a proof out the other side. This chapter describes that machine. It is the recipe that powers every modern SNARK, from Groth16 to Halo 2 to STARKs. It turns the art of cryptography into engineering.

Modern SNARKs decompose into three layers, each with a distinct role. Understanding this decomposition is more valuable than memorizing any particular system; it provides the conceptual vocabulary to navigate the entire landscape.



## The Three-Layer Architecture

Every modern SNARK follows the same structural pattern:

```mermaid
flowchart TB
    subgraph input["INPUT"]
        COMP["COMPUTATION<br/>'I know x such that f(x) = y'"]
    end

    subgraph arith["ARITHMETIZATION"]
        POLY["POLYNOMIAL CONSTRAINTS<br/>R1CS, PLONK gates, AIR, etc."]
    end

    subgraph layer1["LAYER 1: Interactive Oracle Proof (IOP)"]
        IOP1["• Prover sends polynomials (abstractly)"]
        IOP2["• Verifier queries evaluations at random points"]
        IOP3["• Protocol logic: what to check, how to challenge"]
        IOP4["Examples: Sum-check, PLONK IOP, GKR"]
    end

    subgraph layer2["LAYER 2: Polynomial Commitment Scheme (PCS)"]
        PCS1["• Commit: polynomial → short commitment"]
        PCS2["• Open: prove evaluation at a point"]
        PCS3["• Binding: can't change polynomial after commit"]
        PCS4["Options: KZG (trusted), IPA (transparent), FRI (post-quantum)"]
    end

    subgraph layer3["LAYER 3: Fiat-Shamir Transformation"]
        FS1["• Replace verifier randomness with hash outputs"]
        FS2["• Challenge = Hash(transcript so far)"]
        FS3["• Interactive → Non-interactive"]
        FS4["Security: Random Oracle Model"]
    end

    subgraph output["RESULT"]
        SNARK["NON-INTERACTIVE ZERO-KNOWLEDGE ARGUMENT (SNARK)<br/>• Proof: ~100 bytes to ~100 KB<br/>• Verification: milliseconds<br/>• Properties: succinct, sound, (optionally) zero-knowledge"]
    end

    COMP --> POLY
    POLY --> layer1
    layer1 --> layer2
    layer2 --> layer3
    layer3 --> SNARK
```

**Layer 1** operates in an idealized model where the verifier has *oracle access* to polynomials (they can query evaluations at arbitrary points without seeing the polynomial's full description). The protocol's logic is defined here: what polynomials the prover sends, what checks the verifier performs, how challenges and responses interleave.

**Layer 2** instantiates the oracle model cryptographically. Oracle access becomes commitment and opening: the prover commits to a polynomial before seeing queries, then provides evaluation proofs at requested points. The binding property of the commitment scheme ensures the prover cannot retroactively modify their polynomial.

**Layer 3** eliminates interaction. The verifier's random challenges are replaced by hash function outputs computed from the transcript. The prover simulates the entire interaction locally and outputs a static proof.

This separation is not merely pedagogical. It enables genuine modularity: the same IOP can be compiled with different commitment schemes, yielding systems with different trust assumptions, proof sizes, and verification costs. PLONK with KZG gives constant-size proofs requiring trusted setup. PLONK with FRI gives larger proofs but no trusted setup and post-quantum security. The IOP is unchanged; only the cryptographic instantiation differs.



## Layer 1: Interactive Oracle Proofs

An **Interactive Oracle Proof (IOP)** is an interactive protocol where the prover sends *polynomials* rather than field elements, and the verifier has oracle access to these polynomials: they can query any evaluation without seeing the full polynomial description.

### The Oracle Abstraction

The oracle model captures a precise constraint: the prover's polynomial is fixed before the verifier chooses query points. This ordering is essential.

To see why, consider what happens without it. Suppose the prover claims their polynomial $f(X)$ is identically zero. If $f$ were truly zero, it would vanish at every point. If $f$ is nonzero of degree $d$, it has at most $d$ roots. A random query from a field of size $|\mathbb{F}|$ hits a root with probability at most $d/|\mathbb{F}|$.

With $|\mathbb{F}| = 2^{256}$ and $d = 10^6$, this probability is astronomically small. A single random query catches a cheating prover with overwhelming probability.

But this analysis assumes the polynomial is fixed before the query point is chosen. If the prover could see the query point and then construct their polynomial to vanish there, the soundness guarantee would collapse. The oracle abstraction formalizes precisely this constraint: commitment precedes query.

### Sum-Check as an IOP

The sum-check protocol fits naturally into this framework:

1. Prover sends polynomial $g_1(X_1)$
2. Verifier queries $g_1(0)$ and $g_1(1)$, checks $g_1(0) + g_1(1) = H$ (the claimed sum)
3. Verifier sends random challenge $r_1$
4. Prover sends polynomial $g_2(X_2)$
5. Verifier queries $g_2(0)$ and $g_2(1)$, checks $g_1(r_1) = g_2(0) + g_2(1)$
6. Continue for $n$ rounds

The verifier accesses polynomials only through specific evaluations. They never see coefficients directly. The protocol's correctness analysis (its completeness and soundness) requires only that the prover commits to each polynomial before seeing the next challenge.

### IOP Quality Metrics

Not all IOPs are equivalent. The critical parameters:

**Query complexity**: The number of evaluation queries the verifier makes. Each query becomes an evaluation proof in the compiled SNARK, directly affecting proof size.

**Round complexity**: The number of prover-verifier exchanges. Each round becomes a hash computation in Fiat-Shamir. Sum-check has $O(\log n)$ rounds; some IOPs achieve constant rounds.

**Prover complexity**: The computational cost of generating the prover's messages. This should be quasi-linear in the computation size: $O(n \log n)$ or $O(n \log^2 n)$. Quadratic prover complexity renders the system impractical for large computations.

**Soundness error**: The probability that a cheating prover convinces the verifier. Typically $O(d/|\mathbb{F}|)$ per round, where $d$ is the maximum polynomial degree.

These parameters trade off against each other. Fewer queries mean smaller proofs but often require more prover work or stronger assumptions. The art of IOP design lies in navigating these trade-offs for specific applications.



## Layer 2: Polynomial Commitment Schemes

The IOP assumes the verifier can query polynomial evaluations. In reality, there is no oracle: the prover must send something over a communication channel. The **polynomial commitment scheme** provides the cryptographic mechanism.

A PCS provides three operations:

**Commit**: Given polynomial $f$, produce a short commitment $C$

**Open**: Given commitment $C$, point $z$, and claimed value $v$, produce a proof $\pi$ that $f(z) = v$

**Verify**: Given $C$, $z$, $v$, and $\pi$, accept or reject

The critical property is **binding**: once the prover has sent commitment $C$, there exists (with overwhelming probability) only one polynomial $f$ that they can successfully open at any point. The prover cannot commit to one polynomial and later open to a different one.

**Knowledge soundness and extraction.** For arguments *of knowledge* (the "K" in SNARK), binding alone is not enough. The PCS must be *extractable*: it is not sufficient that the commitment contains a polynomial; the prover must actually *know* it. Formally, if a prover can pass the verification check, there must exist a theoretical "extractor" algorithm that can rewind the prover's execution and reconstruct the polynomial they committed to. This extraction property is what lets us claim the prover "knows" a witness, not merely that one exists. It is the heavy lifting behind arguments of knowledge.

### Compilation

The compilation from IOP to **interactive argument**, a protocol where prover and verifier exchange messages with soundness based on cryptographic assumptions rather than information-theoretic guarantees, is mechanical:

- When the IOP specifies "prover sends polynomial $f$," the compiled protocol has the prover send $C = \text{Commit}(f)$
- When the IOP specifies "verifier queries $f(z)$," the compiled protocol has the verifier announce $z$, the prover respond with $v = f(z)$ and proof $\pi$, and the verifier check $\text{Verify}(C, z, v, \pi)$

### Why Compilation Preserves Soundness

The IOP's soundness proof assumes the verifier receives the true evaluation $f(z)$ when they query. After compilation, the verifier instead receives a claimed value $v$ with a proof $\pi$.

The binding property ensures these are equivalent. If the prover committed to polynomial $f$ (by sending $C$), they can only produce valid proofs for evaluations that $f$ actually takes. Any attempt to claim $v \neq f(z)$ requires either breaking the binding property or producing an invalid proof.

The prover sends $C$ before seeing the query point $z$; this is exactly the ordering that the oracle model abstracts. Binding translates the abstract constraint into a concrete cryptographic guarantee.

If the binding property fails (if the prover can commit to one polynomial and open to another) the entire soundness argument collapses. This is why the security of a SNARK ultimately rests on the security of its underlying PCS.

**Formal theorem**: Let the IOP have soundness error $\epsilon_{\text{IOP}}$ and the PCS have binding error $\epsilon_{\text{bind}}$. The compiled SNARK has soundness error at most $\epsilon_{\text{IOP}} + \epsilon_{\text{bind}}$. *Proof sketch*: A cheating prover either (1) breaks the IOP soundness by finding a cheating strategy that succeeds with the committed polynomial, or (2) breaks binding by opening to evaluations inconsistent with the commitment. By union bound, cheating succeeds with probability at most $\epsilon_{\text{IOP}} + \epsilon_{\text{bind}}$.

### PCS Choices

Different commitment schemes offer different trade-offs:

| PCS | Setup | Proof Size | Verification | Assumption |
|-----|-------|------------|--------------|------------|
| KZG | Trusted | $O(1)$ | $O(1)$ | q-SDH + Pairings |
| IPA | Transparent | $O(\log n)$ | $O(n)$ | DLog |
| Dory | Transparent | $O(\log n)$ | $O(\log n)$ | DLog + Pairings |
| FRI | Transparent | $O(\log^2 n)$ | $O(\log^2 n)$ | Collision-resistant hash |

The choice is application-dependent. On-chain verification pays per byte and per operation; KZG's constant-size proofs minimize gas costs. Systems prioritizing trust minimization accept larger proofs for transparent setup. Long-term security considerations may favor FRI's resistance to quantum attacks.



## Layer 3: The Fiat-Shamir Transformation

After PCS compilation, we have an *interactive* argument: prover sends commitment, verifier sends challenge, prover responds, and so on. For many applications (blockchain verification, credential systems, asynchronous protocols) interaction is unacceptable. We need a static proof that anyone can verify without engaging in a conversation.

The **Fiat-Shamir transformation** achieves this by replacing the verifier's random challenges with hash function outputs.

In the interactive protocol:
```
Prover -> commitment C_1 -> Verifier
Verifier -> random r_1 -> Prover
Prover -> commitment C_2 -> Verifier
Verifier -> random r_2 -> Prover
...
```

After Fiat-Shamir:
```
Prover computes:
  C_1 = Commit(f_1)
  r_1 = Hash(C_1)
  C_2 = Commit(f_2)
  r_2 = Hash(C_1 || r_1 || C_2)
  ...
Prover outputs: (C_1, C_2, ..., evaluations, proofs)
```

The verifier reconstructs challenges from the transcript and performs all checks.

### Security Analysis

The interactive protocol's soundness rests on *unpredictability*: the prover commits to $C_1$ without knowing what challenge $r_1$ will be. This prevents the prover from crafting commitments that exploit specific challenges.

In an interactive proof, the verifier sends a random challenge *after* the prover commits. The prover cannot change the past. In a non-interactive proof, the prover generates the challenge themselves. What stops them from cheating?

Fiat-Shamir forces the prover to use the *future* (the hash of their commitment) to determine the *present* (the challenge). If they try to change the commitment to cheat, the future changes, giving them a different challenge that likely fails. They are trapped in a causal loop where every attempt to cheat changes the lock they are trying to pick. The only way out is to find a commitment whose hash happens to yield a favorable challenge, and that requires brute-force search through an astronomically large space.

Fiat-Shamir preserves unpredictability under the **random oracle model**: the assumption that the hash function behaves like a truly random function. If the prover cannot predict $\text{Hash}(C_1)$ before choosing $C_1$, they face the same constraint as in the interactive setting.

A cheating prover's only recourse is to try many values of $C_1$, compute $\text{Hash}(C_1)$ for each, and hope to find one yielding a favorable challenge. This is a **grinding attack**. If the underlying protocol has soundness error $\epsilon$, and the prover can compute $T$ hashes, the effective soundness error becomes roughly $T \cdot \epsilon$.

For a protocol with $\epsilon = 2^{-128}$ and an adversary computing $T = 2^{40}$ hashes, the effective soundness is $2^{-88}$ (still negligible). Larger fields provide additional margin.

### Transcript Construction

A subtle but critical requirement: the hash must include the *entire* transcript up to that point.

The challenge $r_i$ must depend on:

- The public statement being proved
- All previous commitments $C_1, \ldots, C_{i-1}$
- All previous challenges $r_1, \ldots, r_{i-1}$
- All previous evaluation proofs

Omitting the public statement allows the same proof to verify for different statements (a complete soundness failure). Omitting previous challenges may allow the prover to fork the transcript and find favorable paths.

Modern implementations use transcript abstractions (often called "sponges" or "Fiat-Shamir transcripts") that automatically absorb each message. This prevents accidental omissions.

**The Sponge Model.** Think of the transcript as a cryptographic sponge. Every time the prover speaks, they "absorb" their message into the sponge state. Every time they need a challenge, they "squeeze" the sponge to extract random bits. This ensures that each challenge depends on the *entire* history of the conversation, not just the most recent message. The sponge metaphor makes the security property concrete: you cannot get fresh randomness out without first putting your commitment in, and once something is absorbed, it permanently affects all future outputs.

### The Random Oracle Caveat

Fiat-Shamir security is proven in the random oracle model. Real hash functions are not random oracles; they are deterministic algorithms with internal structure.

No practical attacks are known against carefully instantiated Fiat-Shamir. But there is no proof of security from standard assumptions. The hash function must be collision-resistant, but collision resistance alone does not suffice for Fiat-Shamir security.

This remains one of the gaps between theory and practice in deployed cryptography.



## The Complete Pipeline

The three layers compose into a complete SNARK construction pipeline:

**Step 1: Arithmetization**: Convert the computation into a constraint system (R1CS, PLONK gates, AIR). The statement "I know $w$ such that $C(x, w) = 1$" becomes "there exist polynomials satisfying these identities."

**Step 2: IOP Design**: Define an interactive protocol where the prover sends polynomials and the verifier checks algebraic relations via evaluation queries.

**Step 3: PCS Compilation**: Replace polynomial oracles with commitments and evaluation proofs.

**Step 4: Fiat-Shamir**: Replace interactive challenges with hash outputs.

The result is a non-interactive proof that can be verified by anyone with the public statement and verification key.

### A Concrete Trace

Consider proving knowledge of a satisfying R1CS witness.

**Arithmetization**: The R1CS constraint $(A \cdot s) \circ (B \cdot s) = C \cdot s$ becomes a polynomial identity. Define $\tilde{g}(X)$ such that $\tilde{g}$ vanishes on all of $\{0,1\}^n$ if and only if the constraints are satisfied.

**IOP (Sum-Check)**: The prover commits to the witness polynomial $\tilde{w}$. To prove all constraints are satisfied, they prove:

$$\sum_{X \in \{0,1\}^n} \tilde{g}(X) = 0$$

using sum-check. This reduces to a single evaluation of $\tilde{g}$ at a random point $(r_1, \ldots, r_n)$, which in turn requires evaluating $\tilde{w}$ at that point.

**PCS Compilation (with KZG)**:

- Prover sends $C_w = \text{KZG.Commit}(\tilde{w})$
- Each sum-check round, prover commits to the univariate polynomial $g_i$
- Final evaluation $\tilde{w}(r_1, \ldots, r_n)$ comes with a KZG opening proof

**Fiat-Shamir**: Each challenge $r_i$ is computed as $\text{Hash}(\text{transcript})$. The final proof is the collection of commitments, claimed evaluations, and opening proofs.

### Proof Size Analysis

For a circuit with $n = 20$ variables (approximately one million gates), with KZG:

- Sum-check round polynomials: ~20 commitments × 48 bytes = ~1 KB
- Evaluations: ~60 field elements × 32 bytes = ~2 KB
- Batched KZG opening proof: ~48 bytes

Total: approximately 3 KB.

The witness contains millions of field elements. The proof is five orders of magnitude smaller. This is succinctness.

With FRI instead of KZG, proof size grows to ~100 KB (larger, but still succinct, and requiring no trusted setup).



## Zero-Knowledge

We have focused on succinctness and soundness. The basic construction does not provide zero-knowledge: the sum-check polynomials reveal information about the witness.

**Formal definition**: A proof system is *zero-knowledge* if there exists a simulator $\mathcal{S}$ that, given only the statement (not the witness), produces transcripts indistinguishable from real proofs. Intuitively: the proof reveals nothing about the witness beyond the truth of the statement. The verifier could have generated the same transcript themselves without seeing the witness.

Adding zero-knowledge requires additional techniques:

**Hiding commitments**: Use randomized commitments (Pedersen with blinding factors) so that the commitment itself reveals nothing about the polynomial.

**Masking polynomials**: Add random low-degree polynomials to the prover's messages. These polynomials sum to zero and thus don't affect correctness, but they obscure the structure of individual evaluations.

Chapter 17 develops these techniques in detail. The key point here: zero-knowledge is a property *layered on top* of the basic SNARK construction. The three-layer architecture applies equally to zero-knowledge and non-zero-knowledge systems.



## Modularity in Practice

The three-layer decomposition has practical consequences beyond conceptual clarity.

**Upgradability**: When a better PCS is developed, existing IOPs can adopt it. PLONK was originally specified with KZG. It now has FRI-based variants (Plonky2, Plonky3) that inherit PLONK's arithmetization and IOP while gaining transparency and post-quantum resistance.

**Specialized optimization**: Each layer can be optimized independently. Improvements to sum-check proving (Chapter 19) benefit all sum-check-based SNARKs regardless of their PCS. Improvements to KZG batch opening benefit all KZG-based systems regardless of their IOP.

**Analysis decomposition**: Security analysis can proceed layer by layer. The IOP's soundness is analyzed in the oracle model. The PCS's binding property is analyzed under its cryptographic assumption. Fiat-Shamir security is analyzed in the random oracle model. Each analysis is self-contained.

**System comprehension**: When encountering a new SNARK, the first questions are: What is the IOP? What is the PCS? This decomposition makes the landscape navigable. New systems become variations on known themes rather than entirely novel constructions.



## Taxonomy

With the three-layer model, we can classify the SNARK landscape:

**By IOP**:

- *Linear PCP-based*: Groth16 (the prover's messages are linear combinations of wire values, enabling constant verification via encrypted linear checks)
- *Polynomial IOP-based*: PLONK, Marlin (the prover sends polynomials, the verifier checks polynomial identities)
- *Sum-check-based*: Spartan, Lasso (verification reduces to sum-check over multilinear polynomials)
- *FRI-based*: STARKs (low-degree testing via the FRI protocol)

**By PCS**:

- *Pairing-based*: KZG (constant-size proofs, trusted setup)
- *Discrete-log-based*: IPA/Bulletproofs (logarithmic proofs, transparent)
- *Hash-based*: FRI (polylogarithmic proofs, post-quantum)

**By setup requirements**:

- *Circuit-specific*: Groth16 (new trusted setup per circuit)
- *Universal*: PLONK, Marlin (single trusted setup for all circuits up to a size bound)
- *Transparent*: STARKs, Spartan+IPA (no trusted setup)

No single system dominates all metrics. The choice depends on what constraints bind most tightly in a given application.



## Common Failure Modes

Certain mistakes recur in SNARK implementations:

**Incomplete Fiat-Shamir transcripts**: Omitting the public statement, or previous challenges, from the hash input. This allows proof malleability or statement confusion. The fix is systematic: use a transcript abstraction that absorbs every message. This isn't hypothetical; multiple production systems have been broken by incomplete transcripts.

**Insufficient field size**: Soundness error is $O(d/|\mathbb{F}|)$ per round. With many rounds and modest field size, security margins shrink. The 64-bit Goldilocks field, popular for its fast arithmetic, requires careful analysis and sometimes additional protocol rounds.

**Quadratic prover complexity**: Some natural IOP constructions require the prover to perform $O(n^2)$ work. This is acceptable for small circuits but prohibitive at scale. Quasi-linear prover complexity ($O(n \log n)$ or $O(n \log^2 n)$) is the design target.

**Neglecting witness generation**: The prover must compute the witness before proving knowledge of it. Circuit designs that optimize for prover complexity may inadvertently create expensive witness generation. The entire pipeline matters.



## Key Takeaways

1. **Three-layer architecture**: IOP defines protocol logic, PCS provides cryptographic binding, Fiat-Shamir eliminates interaction. Each layer is analyzed independently.

2. **Oracle abstraction**: The prover commits before the verifier queries. This ordering, not any particular commitment mechanism, is what enables random evaluation to catch cheating.

3. **Binding bridges abstraction to cryptography**: The PCS's binding property directly instantiates the oracle model's commitment semantics.

4. **Fiat-Shamir requires unpredictability**: Security holds when the prover cannot predict hash outputs. Grinding attacks bound the effective advantage.

5. **Transcript completeness is critical**: Every message must enter the hash. Omissions break soundness.

6. **Modularity is structural**: Same IOP, different PCS yields different systems. This is how the field evolves.

7. **Query complexity determines proof size**: Each IOP query becomes a PCS opening proof.

8. **Zero-knowledge is additive**: The basic construction gives succinctness and soundness. Zero-knowledge requires additional masking.

9. **No universal optimum**: KZG minimizes proof size with trusted setup. FRI eliminates setup with larger proofs. IPA trades verification time for transparency. The choice is application-dependent.

10. **The decomposition is the understanding**: Knowing how layers compose matters more than memorizing specific systems.

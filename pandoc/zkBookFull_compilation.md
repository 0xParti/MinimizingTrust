---
titlepage: true
titlepage-background: "../images/cover/zkBookCover.png"
titlepage-text-color: "FFFFFF00"
titlepage-rule-height: 0
toc: false
toc-depth: 2
link-citations: true
book: true
classoption: openright
header-includes:
  - \usepackage{graphicx}
  - \usepackage{eso-pic}
---

<!-- Page 2: Anverse image (full page like cover) -->
\newpage
\thispagestyle{empty}
\AddToShipoutPictureBG*{\includegraphics[width=\paperwidth,height=\paperheight]{../images/cover/zkBookAnverse.png}}
\null

<!-- Page 3: Title page -->
\newpage
\thispagestyle{empty}
\begin{center}
\vspace*{3cm}
{\Huge\bfseries Minimizing Trust, Maximizing Truth}\\[1cm]
{\Large\itshape The Architecture of Verifiable Secrets}\\[2cm]
{\large particle}\\[4cm]
\vfill
\end{center}

<!-- Page 4: TOC -->
\newpage
\tableofcontents

<!-- Empty page after TOC -->
\newpage
\thispagestyle{empty}
\mbox{}

# Chapter 1: The Trust Problem

In the summer of 1821, two mathematicians sat in a room in London, exhausted and frustrated. Charles Babbage and John Herschel had been tasked with checking the Nautical Almanac, a book of astronomical tables that sailors used to navigate the globe.

At the time, a "computer" was not a machine. It was a job title. Clerks calculated these tables by hand, other clerks checked their work, and printers typeset the results. Every step was a point of failure. As Babbage and Herschel compared the calculations against the printed proofs, they found error after error. A wrong digit in a logarithm didn't just mean a failed exam; it meant a ship running aground on a reef in the West Indies.

Exasperated, Babbage slammed the table and declared: "I wish to God these calculations had been executed by steam!"

That outburst launched the age of mechanical computation. Babbage spent the rest of his life designing engines to generate mathematical tables automatically, removing the human element from execution. If the machine was built correctly, its outputs could be trusted.

Two centuries later, we have fulfilled Babbage's wish. We have steam, now silicon, executing calculations at speeds he couldn't have imagined. But in solving the speed problem, we reintroduced the trust problem in a new form.

You send your calculation to the cloud. The cloud sends back an answer.

Why should you believe it?

The server might be compromised. The operator might be malicious. The hardware might be faulty. The software might contain bugs. Even if everything works correctly, how would you *know*? The only evidence you have is the answer itself, and the answer, by itself, proves nothing.

Here's the fundamental asymmetry: executing a computation takes resources (time, memory, energy). But *checking* whether the computation was done correctly also takes resources. In many cases, the same resources. If you could check the answer cheaply, you wouldn't have outsourced the computation in the first place.

This is the **trust problem in computation**: how do you verify without redoing all the work?

### Truth Without a Judge

For millennia, knowledge has traveled through testimony. One person tells another: "I computed this result." The listener judges whether to believe. This judgment rests on reputation, authority, past behavior. All the machinery of social trust.

What if claims could carry their own evidence? Not testimony backed by reputation. Not certificates issued by authorities. Something stranger: an object that proves itself. If the claim is false, the object cannot exist. If the object exists and passes inspection, the claim must be true. No judge required.

This is not metaphor. The technology exists. A computational claim can be accompanied by a mathematical object, a *proof*, that anyone can verify in milliseconds. The proof works not because you trust the prover, but because mathematics makes cheating impossible. Two machines that have never communicated can verify the same proof and reach the same conclusion, not because they negotiated, but because the structure of mathematics forces the same answer from any system capable of arithmetic.

We will call this *arithmetic consensus*: agreement enforced by structure rather than achieved by persuasion. Chapter 2 develops the mechanism (the Schwartz-Zippel lemma) and explores why this represents a genuinely new foundation for intersubjective truth. For now, hold this question: what becomes possible when "I trust you" can be replaced with "I verified the math"?

This book teaches you how to build such proofs.



## When Verification Is Easy

Before confronting the hard case, consider situations where verification *is* easy, given the right certificate.

**Factorization**: Given $n$ and a claim that $p, q$ are its prime factors. Verification: multiply $p \times q$, check it equals $n$, verify $p$ and $q$ are prime. Finding those factors is believed to require exponential time; checking them takes polynomial time.

**Graph coloring**: Given a graph and a claimed 3-coloring. Verification: for each edge, check that its endpoints have different colors. Finding such a coloring is NP-hard; verifying one is linear in the number of edges.

**Satisfying assignments**: Given a Boolean formula and a claimed satisfying assignment. Verification: substitute the values and evaluate each clause. Finding such an assignment is NP-complete; checking one is polynomial.

These are problems in **NP**: the class of problems where, if someone hands you a proposed solution, you can *check* whether it's correct in reasonable time (polynomial in the input size). NP doesn't say anything about how hard it is to *find* a solution, only how hard it is to *verify* one. The proposed solution serves as a *witness* or *certificate* of correctness.

Note the asymmetry: NP captures "easy to verify," not "hard to find." Some NP problems are easy to solve (every problem in P is also in NP). The interesting cases are those where finding appears hard but verifying is easy. This gap is what proof systems exploit.


## When Verification Seems As Hard As Computation

But many problems don't have short certificates.

The obvious verification strategy is to recompute: run the same algorithm on the same inputs and compare results. This works, but it defeats the purpose. You outsourced because you couldn't (or didn't want to) pay the computational cost. Verification that costs as much as the original computation is no verification at all.

For a moment, consider what "cheap verification" would even mean. The computation processes some input of size $n$, takes $T$ steps, and produces an output. Cheap verification would mean checking correctness in time $o(T)$: strictly less than the original computation. Ideally, much less. Ideally, polylogarithmic in $T$, or even constant.

But this seems impossible. How can you verify a computation without understanding what it computed? How can you understand what it computed without retracing its steps? The answer is computed from the input through a long chain of operations; surely checking requires following that chain?

### The Cost of Blind Trust

On February 25, 1991, during the Gulf War, a Patriot missile battery in Dhahran, Saudi Arabia, failed to intercept an incoming Iraqi Scud. The missile struck an American barracks, killing 28 soldiers.

The cause was a software bug. The Patriot's tracking system measured time in tenths of a second using a 24-bit register, then multiplied by 0.1 to convert to seconds. But 0.1 has no exact binary representation; it's a repeating fraction, like 1/3 in decimal. The system truncated it, introducing a tiny error of about 0.000000095 seconds per tenth.

Tiny, but cumulative. The battery had been running for 100 hours. Over that time, the error accumulated to 0.34 seconds. For a Scud traveling at Mach 5, that's a tracking error of over 600 meters. The missile defense system calculated that the incoming Scud was outside its range gate and didn't fire.

The bug had been discovered two weeks earlier. Israeli defense forces, who had noticed the drift, warned the U.S. Army and recommended rebooting the system regularly to reset the clock. A software patch was developed. It arrived in Dhahran on February 26, one day after the attack.

Twenty-eight soldiers died because a computation was trusted without verification. The system worked exactly as programmed; the program was wrong. No one checked.

Whether the error comes from a hacker in the server room or a rounding bug in the floating-point unit, the result is the same: a wrong answer accepted as truth. Validity proofs don't care about intent; they care about correctness. They catch malice and accident alike.

The remarkable discovery of the 1980s and 1990s was that cheap verification *is* possible.



## Interactive Proofs: The Breakthrough

The key insight came from complexity theory, and it involved a conceptual leap: *interaction* and *randomness* together can create verification power that neither possesses alone.

A computationally unbounded prover claims to have solved a problem. A polynomially bounded verifier wants to check this claim. The verifier cannot solve the problem themselves (that's the whole point), but they can engage in a conversation with the prover.

In an **interactive proof**, the verifier sends random challenges, the prover responds, and after some number of rounds, the verifier decides whether to accept or reject the claim.

The magic is in two properties:

**Completeness**: If the claim is true, an honest prover can always convince the verifier to accept.

**Soundness**: If the claim is false, no prover, no matter how clever or powerful, can convince the verifier to accept, except with negligible probability.

The probability in soundness comes from the verifier's randomness. The prover doesn't know in advance what challenges the verifier will send. A cheating prover must prepare for all possible challenges, and this is where they fail. The space of possible challenges is exponentially large; the prover cannot succeed at all of them if the claim is false.



## Randomness Creates Asymmetry

Suppose I claim two polynomials $p(x)$ and $q(x)$ are identical. Both polynomials have degree at most $d$, and their coefficients are elements of a large finite field $\mathbb{F}$ of size $|\mathbb{F}| = 2^{256}$.

**Without randomness**, verifying this claim requires comparing all $d+1$ coefficients. If $d$ is large, this is expensive.

**With randomness**, verification becomes trivial:

1. Pick a random $r \in \mathbb{F}$

2. Evaluate $p(r)$ and $q(r)$

3. Accept if they're equal, reject otherwise

If $p = q$, then $p(r) = q(r)$ for all $r$. Verification always succeeds.

If $p \neq q$, then $p - q$ is a nonzero polynomial of degree at most $d$. Such a polynomial has at most $d$ roots. The probability that our random $r$ hits a root is at most $d / |\mathbb{F}|$.

With $d = 10^6$ and $|\mathbb{F}| = 2^{256}$:

$$\Pr[\text{cheating succeeds}] \leq \frac{10^6}{2^{256}} \approx 2^{-236}$$

This is so small it's effectively zero. One random evaluation suffices.

This is the **Schwartz-Zippel lemma** in action. We'll see it again and again throughout this book. It's perhaps the most important tool in interactive proofs: random evaluation catches disagreement between polynomials with overwhelming probability.



## From IP to Succinctness

The theoretical study of interactive proofs established profound results:

**IP = PSPACE**: Interactive proofs with polynomial-time verifiers can verify exactly the class **PSPACE**. What is PSPACE? It's the class of problems solvable using a reasonable amount of memory (polynomial in the input size), but with no limit on time. A PSPACE algorithm might run for centuries, but it can only use a bounded scratch pad. This includes problems like determining the winner in generalized chess (with an $n \times n$ board) or evaluating quantified Boolean formulas ("for all $x$, there exists $y$, such that..."). These problems are believed to be far harder than NP. The verifier's randomness and the prover's computational power combine to verify claims that seem uncheckable.

But these theoretical protocols had a problem: they weren't *succinct*. The total communication (the number of bits exchanged between prover and verifier) could be polynomial in the computation size. Better than redoing the computation, but not by much.

The goal of **succinct arguments** is more ambitious: proofs that are *polylogarithmic* in the computation size, or even constant. A computation taking billions of steps should yield a proof of hundreds or thousands of bits, not billions.

Achieving this goal required new proof models: extensions and variants of interactive proofs that enabled different trade-offs between interaction, query access, and succinctness.



## The Proof System Zoo

The path from interactive proofs to modern SNARKs runs through several distinct proof models. Understanding this taxonomy clarifies where different techniques come from and why modern systems take the forms they do.

This section mentions several *complexity classes* (IP, MIP, PSPACE, NEXP). These are categories that computer scientists use to classify problems by how hard they are to solve or verify. Don't worry if the distinctions feel abstract on first reading. The key intuition is that different proof models have different "verification power," meaning some can verify harder problems than others. The specific class names matter less than the pattern: adding constraints to the prover (like forbidding communication between multiple provers) paradoxically *increases* what the verifier can check.

### Interactive Proofs (IP)

The starting point. A prover and verifier exchange messages. The verifier uses randomness to catch cheating. Security is *information-theoretic*: even an all-powerful prover cannot convince the verifier of a false statement (except with negligible probability).

Think of it as courtroom cross-examination. The prover (witness) wants to convince the verifier (judge) of some claim. The judge cannot independently verify the facts; they weren't there, they don't have the evidence. But through clever questioning, the judge can probe for inconsistencies. An honest witness has nothing to hide; their answers will be consistent. A lying witness must maintain a web of fabrications, and random probing questions will eventually find a thread that unravels it.

The class **IP** contains all languages with such protocols where the verifier runs in polynomial time. The theorem **IP = PSPACE** (Shamir, 1990) shows this class is remarkably large, far larger than NP. The verifier's random questions, combined with the prover's unbounded computational power, can verify claims that no static certificate could capture.

### Multi-Prover Interactive Proofs (MIP)

IP was powerful (it captured all of PSPACE), but verification still required multiple rounds of back-and-forth, and proofs weren't succinct. What if we could constrain the prover more tightly to gain more verification power?

What if the verifier could interrogate *multiple* provers who cannot communicate with each other?

Imagine two suspects in separate rooms: the classic police interrogation. The detective asks each suspect questions, comparing answers for consistency. If the suspects are telling the truth, their stories align effortlessly. If they're lying, they can't coordinate their lies without communicating, and they can't communicate. The detective doesn't need to know the truth themselves; they only need to catch inconsistencies between the two stories.

In a **Multi-Prover Interactive Proof**, two or more provers share the witness but cannot exchange messages during the protocol. The verifier sends different challenges to each prover and cross-checks their responses.

The deep insight here is **non-adaptivity**. In a single-prover IP, the prover sees the verifier's first challenge before answering, then sees the second challenge before answering again. The prover *adapts* to each challenge in sequence. With two non-communicating provers, the verifier can send different questions simultaneously; neither prover knows what the other was asked. This forces both provers to commit to a consistent story *before* seeing the cross-examination.

This apparently simple change unleashes enormous verification power:

**MIP = NEXP** (Babai, Fortnow, Lund, 1991): Multi-prover proofs can verify problems in **NEXP**, which stands for nondeterministic exponential time. What does this mean? Recall that NP is the class where solutions can be verified quickly. NEXP is the exponentially larger cousin: problems where the solution itself might be exponentially large (so even *writing it down* takes exponential time), but once written, it can be checked in exponential time. These are vastly harder problems than NP or even PSPACE.

The gap from PSPACE to NEXP is vast. The non-communication constraint is what makes it possible: the verifier can probe two points of a story simultaneously, catching inconsistencies that a single adaptive prover could finesse.

This idea of forcing commitment before challenge reappears throughout SNARK design. When we study polynomial commitment schemes, we'll see the same principle: the prover commits to a polynomial, then the verifier challenges. The commitment plays the role of the second prover: it locks in answers before the questions are known.

### Probabilistically Checkable Proofs (PCP)

MIP was even more powerful (it captured NEXP), but it required *two separate provers*. In practice, we usually have just one prover. Could we get similar power without needing to literally interrogate two parties in separate rooms?

Here the model shifts from interaction to *query access*. The prover writes down a static proof string $\pi$ (potentially very long), which is just a sequence of symbols like $\pi = (\pi_1, \pi_2, \pi_3, \ldots, \pi_m)$. The verifier doesn't read the whole string. Instead, they pick a few positions at random and look only at those symbols. For example, the verifier might flip some coins, decide to look at positions 17, 42, and 803, read $\pi_{17}$, $\pi_{42}$, and $\pi_{803}$, and make a decision based only on those three values.

A **PCP** is characterized by two parameters, both functions of the input size $n$:

- How many random bits the verifier uses (to decide which positions to query)

- How many positions in the proof string the verifier queries

The verifier's decision depends only on the input, their random coin flips, and the few symbols they read from the proof.

The **PCP Theorem** (Arora, Safra; Arora, Lund, Motwani, Sudan, Szegedy; 1992) is one of the landmark results of complexity theory:

$$\textbf{NP} = \textbf{PCP}[O(\log n), O(1)]$$

What does "every NP problem has a PCP" mean? Recall that an NP problem is one where solutions can be verified quickly given a witness (like checking that a proposed graph coloring is valid). The PCP theorem says something stronger: for any such problem, there exists a way to encode the witness into a longer proof string such that the verifier uses only $O(\log n)$ random bits and queries only a *constant* number of proof positions. The proof might be polynomial-size, but verification reads only $O(1)$ bits.

How can this possibly work? The key is **structured redundancy**.

Think of a completed Sudoku puzzle. The puzzle has internal constraints: each row, column, and 3×3 box must contain the digits 1-9 exactly once. Now imagine "corrupting" one cell by changing a 7 to a 3. This single error violates the constraint for its row, its column, and its box. One mistake creates evidence in multiple places. A random spot-check has a decent chance of catching it.

PCPs work the same way, but with vastly more redundancy. The proof is not the raw witness; it's an *encoded* version where local constraints interlock globally. The encoding transforms the witness into a form where any error, any deviation from a valid proof, creates detectable inconsistencies across many positions.

The technology: low-degree polynomial encoding. The witness is interpreted as evaluations of a polynomial, then extended to many more points. Polynomial structure ensures that errors propagate: a polynomial that's wrong at even one point must disagree with the correct polynomial almost everywhere (Schwartz-Zippel, again). Random queries catch these disagreements with high probability.

This is remarkable. A satisfying assignment to a million-variable formula might require a million bits to write down. But there exists an encoding, a PCP, where checking validity requires reading only, say, 3 bits. The encoding has redundancy; errors anywhere propagate everywhere, detectable by sparse sampling.

### The MIP-PCP Connection

There's a deep connection between multi-prover proofs and PCPs. The two non-communicating provers in an MIP can be simulated by a single long proof string: each possible pair of questions to the two provers corresponds to a position in the string, with the answer pair as the value at that position.

The non-communication constraint in MIP becomes a consistency requirement in PCP: the answers at different positions must be consistent with some underlying witness. The verifier's power to cross-check provers becomes the power to query random positions and check consistency.

This connection was key to proving MIP = NEXP and to subsequent PCP constructions.

### Interactive Oracle Proofs (IOP)

The PCP theorem was a landmark: it showed any NP statement has a proof checkable with constant queries. But PCPs require enormous proof strings, and they're non-interactive (the prover must anticipate all possible verifier randomness). IP had efficient interaction but no query access. Could we combine the best of both?

**Interactive Oracle Proofs** do exactly that.

In an IOP, the protocol has multiple rounds. In each round, the prover sends a *proof string* (or, more abstractly, an *oracle*). The verifier can query this oracle at chosen positions, then sends a challenge. The prover responds with another oracle, and so on.

Why combine interaction and oracles? Each compensates for the other's weakness. Pure PCPs require enormous proof strings to achieve low soundness error; the proof must anticipate all possible verifier randomness. Pure IPs require many rounds of back-and-forth; the verifier probes incrementally, each round narrowing the space of consistent lies. IOPs get the best of both: the prover commits to an oracle (like a PCP), then the verifier challenges (like an IP), then another oracle, another challenge. Each oracle only needs to handle the challenges that could follow *given previous commitments*.

This hybrid captures what modern SNARK constructions actually do:

1. Prover commits to a polynomial (an oracle that the verifier can query for evaluations)

2. Verifier sends a random challenge

3. Prover commits to another polynomial

4. Repeat

5. Verifier makes a few queries and decides

The IOP abstraction separates the *protocol logic* from the *implementation of oracles*. The oracle is abstract; the verifier magically gets evaluations at chosen points. Chapter 11 shows how polynomial commitment schemes instantiate these oracles cryptographically.

### Linear PCPs

IOPs gave us a clean abstraction, but implementing them required a way to make oracles concrete and binding. A key insight: if we restrict what *kind* of queries the verifier can make, we can use cryptography to enforce that restriction. This leads to Linear PCPs.

In a standard PCP (as described above), the proof is a string of symbols and the verifier reads a few specific positions: "give me $\pi_{17}$, $\pi_{42}$, and $\pi_{803}$." In a **Linear PCP**, the proof is still a vector of values $\vec{\pi} = (\pi_1, \pi_2, \ldots, \pi_k)$, but the verifier can only ask for linear combinations: "give me $\sum_i q_i \cdot \pi_i$ for my chosen weights $q$."

Think of it as a library where you can't open the books (that would reveal the witness). You can only ask the librarian to weigh books in specific combinations. "Put 2 copies of book 1 on the scale, plus 3 copies of book 3, plus 1 copy of book 7, and tell me the total weight." The librarian answers with a single number. You ask several such questions. From these weighted sums, you try to verify some property of the books without ever seeing their contents.

The linearity constraint is extraordinarily powerful. If the verifier is restricted to weighted-sum queries, we can use cryptography to *enforce* this restriction. Here's the key insight: **certain cryptographic structures only allow weighted-sum operations, nothing else**.

Elliptic curve groups have this property. In an elliptic curve group, you can add points together and multiply points by numbers, but you cannot multiply two points together. Think of it like a calculator that has + and × buttons, but the × only works when one input is a regular number. If the proof values are encoded as elliptic curve points, then anyone holding those points can only compute weighted sums of them.

Concretely: the prover knows the proof values $\pi_1, \pi_2, \ldots$ and a special group point $G$. The prover creates encoded values $[\pi_i] = \pi_i \cdot G$ (multiply each value by the point $G$). The verifier receives these encoded points. Given weights $q_1, q_2, \ldots$, the verifier can compute $q_1 \cdot [\pi_1] + q_2 \cdot [\pi_2] + \cdots$, which equals the encoding of $q_1 \cdot \pi_1 + q_2 \cdot \pi_2 + \cdots$. The verifier gets the weighted sum, but cannot extract the individual $\pi_i$ values or compute anything beyond weighted sums. The elliptic curve structure itself forces the verifier to play by the Linear PCP rules.

Groth16 (Chapter 12) is built on linear PCPs. The prover's messages are linear combinations of structured reference string elements, which are themselves encodings of powers of a secret. The verifier checks linear relationships via pairings: bilinear maps that allow *one* multiplication in the exponent, just enough to check quadratic constraints.

### From Proof Models to SNARKs

All modern SNARKs arise from one of these proof models combined with cryptographic compilation:

| Proof Model | + Cryptography | = SNARK Family |
|-------------|----------------|----------------|
| IP | + Polynomial Commitments | Spartan, HyperPlonk |
| IOP (polynomial) | + KZG / FRI | PLONK, Marlin, STARKs |
| Linear PCP | + Pairings | Groth16, BCTV14 |
| PCP | + Merkle trees | Kilian-style arguments |

The pattern: start with an information-theoretically secure protocol, then use cryptography to make the prover's messages short and binding.

**Polynomial Commitment Schemes** (Chapter 9-10) instantiate IOP oracles: the prover commits to a polynomial, the verifier queries evaluations, and a short proof demonstrates correctness of each evaluation.

**Fiat-Shamir** (Chapter 11) eliminates interaction: derive the verifier's challenges from hashes of the transcript. The prover computes the entire interaction locally and outputs a static proof.

The combination yields **SNARKs**: Succinct Non-interactive Arguments of Knowledge. A SNARK for a computation of size $n$ has:

- Proof size: $O(\log n)$ or even $O(1)$

- Verification time: $O(\log n)$ or $O(1)$

- Prover time: $O(n \log n)$ or similar quasi-linear

The asymmetry is achieved. Verification is exponentially cheaper than computation.



## Zero-Knowledge: Proving Without Revealing

There's another dimension to this story. So far, we've focused on *soundness*: preventing false claims from being verified. But what about *privacy*?

Suppose you want to prove you know a password without revealing the password itself. Or that you have sufficient funds for a transaction without revealing your balance. Or that you satisfy some credential requirement without exposing your identity.

**Zero-knowledge proofs** achieve exactly this. The proof convinces the verifier that the statement is true, but reveals *nothing* beyond this single bit of information. The verifier learns "yes, this is true" and nothing else.

The formal definition involves a *simulator*: an algorithm that produces transcripts indistinguishable from real proof transcripts, without access to the secret witness. If such a simulator exists, the proof is zero-knowledge; the transcript could have been generated by someone who didn't know the secret, so the transcript cannot leak the secret.

Zero-knowledge adds a layer of privacy to succinct verification. Together, they form **zkSNARKs**: Zero-Knowledge Succinct Non-interactive Arguments of Knowledge.



## The Architecture of Modern Proofs

This book develops the theory and practice of zkSNARKs. The architecture has emerged from decades of research, but it follows a consistent pattern:

**1. Arithmetization** (Chapters 4-8): Convert the computational claim into algebraic form. A program becomes a circuit. A circuit becomes a system of polynomial equations. The claim "I computed correctly" becomes "these polynomials satisfy this identity."

**2. Information-Theoretic Protocol** (Chapters 3, 7): Design an interactive protocol where the prover sends polynomials (or claims about polynomials) and the verifier checks them via random evaluations. This protocol is sound against unbounded provers; no cryptographic assumptions yet.

**3. Cryptographic Compilation** (Chapters 6, 9-10): Replace the abstract polynomials with cryptographic commitments. The prover commits to polynomials before seeing challenges. Polynomial commitment schemes (KZG, FRI, IPA) provide this binding.

**4. Fiat-Shamir Transform** (Chapter 11): Eliminate interaction. The verifier's random challenges are derived from a hash of the transcript. The prover computes the entire interaction locally and outputs a static proof.

The result: a proof that anyone can verify, that reveals nothing about the witness, and that is exponentially smaller than the computation it attests to.



## Why This Matters

Each application is a trust assumption eliminated.

**Verifiable computation** removes trust in the cloud. You outsource to untrusted servers, receive a proof with the result, and verify cheaply. The server's incentives, security practices, and internal controls become irrelevant. You don't trust the server; you verify the proof.

**Blockchain scalability** removes trust in centralized sequencers. Layer 2 solutions process thousands of transactions off-chain, producing a single proof that the main chain verifies. The sequencer cannot lie about execution. Transaction throughput increases by orders of magnitude without introducing new trust assumptions.

**Privacy-preserving credentials** remove trust in identity intermediaries. Prove you're over 21 without revealing your birthdate. Prove you passed a background check without revealing what was checked. The verifier learns exactly one bit: valid or not. No data broker, no identity provider, no linkable trail.

**Computational integrity** removes trust in institutions. Scientific simulations, machine learning inference, financial calculations: any computation can be accompanied by a proof of correctness. The question changes from "do I trust this organization?" to "does this proof verify?"

The pattern is consistent: find a trust assumption, replace it with mathematics.



## The Road Ahead

The chapters that follow develop this technology piece by piece.

We begin with polynomials (Chapter 2), the universal language of algebraic proof systems. The sum-check protocol (Chapter 3) shows how to verify exponential sums in polynomial time, the foundational technique underlying almost everything that follows.

Multilinear extensions (Chapter 4) and univariate polynomials (Chapter 5) provide two complementary encoding schemes for computational data. Commitment schemes (Chapter 6) bind provers to their claims.

The GKR protocol (Chapter 7) verifies arbitrary circuits using sum-check. Arithmetization (Chapter 8) shows how real computations become circuits.

Polynomial commitment schemes (Chapters 9-10) provide the cryptographic foundation: KZG, IPA, and FRI, each with different trade-offs between proof size, verification time, and trust assumptions.

The SNARK recipe (Chapter 11) explains how these pieces assemble. Groth16 (Chapter 12), PLONK (Chapter 13), lookup arguments (Chapter 14), and STARKs (Chapter 15) are complete systems, each optimizing different aspects.

$\Sigma$-protocols (Chapter 16) and zero-knowledge (Chapters 17-18) add privacy. The sum-check renaissance (Chapters 19-21) develops the latest techniques for fast proving.

Composition and recursion (Chapter 22) enable proofs about proofs: unlimited computation with constant verification. The book concludes with system selection guidance (Chapter 23), MPC's parallel path (Chapter 24), open frontiers (Chapter 25), and the broader cryptographic landscape (Chapter 26).

By the end, you'll understand not just what zkSNARKs do, but *how* they work: the mathematical structures that make the impossible possible.



## Key Takeaways

1. **Verification should be cheaper than computation.** If Alice outsources a computation to Bob, she shouldn't have to redo the entire work to check his answer. The goal is *asymmetric verification*: Bob does the hard work once, Alice checks quickly.

2. **Randomness creates verification power.** A deterministic verifier who can't compute the answer can't check it either. But a randomized verifier can probe for inconsistencies. Random questions catch cheaters with high probability.

3. **Schwartz-Zippel is the fundamental tool.** Two different degree-$d$ polynomials agree on at most $d$ points. Evaluating at a random point catches disagreement with probability at least $1 - d/|\mathbb{F}|$. Polynomials are central to proof systems because errors propagate almost everywhere.

4. **Proof models evolved by constraining the prover.** IP captures PSPACE. MIP (multiple non-communicating provers) captures NEXP. PCPs allow constant-query verification. IOPs combine interaction with oracle access. Paradoxically, more constraints on the prover give the verifier more power.

5. **The PCP theorem is foundational.** NP = PCP[$O(\log n)$, $O(1)$]. Any NP statement has a proof where the verifier reads constantly many bits. This requires encoding the witness with structured redundancy so that any error creates detectable inconsistencies.

6. **Polynomial commitments instantiate oracles.** The prover commits to a polynomial; the verifier queries evaluations; a short proof demonstrates each evaluation is correct. Different schemes (KZG, FRI, IPA) offer different trade-offs.

7. **Fiat-Shamir eliminates interaction.** Replace the verifier's random challenges with hashes of the transcript. The prover computes the entire interaction locally and outputs a static proof.

8. **The architecture is modular.** Arithmetization encodes computation as constraints. An IOP proves the constraints are satisfied. Cryptographic compilation (PCS + Fiat-Shamir) makes proofs short and non-interactive. Each layer can be swapped independently.

9. **Zero-knowledge is orthogonal to succinctness.** The proof can reveal nothing beyond the statement's truth. Privacy and compression are independent properties; modern systems achieve both.

\newpage

# Chapter 2: The Alchemical Power of Polynomials

In 1960, Irving Reed and Gustave Solomon were trying to solve a practical problem: how do you send data through space?

The spacecraft transmitting from millions of miles away couldn't retransmit lost bits. The signal would be corrupted by cosmic radiation, hardware glitches, and the fundamental noise of the universe. Reed and Solomon needed a way to encode information so that even after some of it was destroyed, the original could be perfectly recovered.

Their solution was startlingly simple. Instead of sending raw data, they evaluated a polynomial at many points and transmitted the evaluations. A polynomial of degree $d$ is uniquely determined by $d+1$ points, so if you send many more than $d+1$ evaluations, some can be corrupted or lost, and the receiver can still reconstruct the original polynomial from what remains.

What Reed and Solomon had discovered, without quite realizing it, was one of the most powerful ideas in all of computer science: **polynomials are rigid**. A low-degree polynomial cannot "cheat locally." If you change even a single coefficient, the polynomial's values change at almost every point. This rigidity, this inability to lie in one place without being caught elsewhere, would turn out to be exactly what cryptographers needed, thirty years later, to build systems where cheating is mathematically impossible.



## The Motivating Problem: Beyond NP

Before we explore polynomials, let's understand the problem they solve. In Chapter 1, we saw that some problems have the useful property that their solutions are easy to check: multiply the claimed factors to verify factorization, check each edge to verify graph coloring. These are NP problems; the solution serves as its own certificate.

But what about problems that don't have short certificates?

### The SAT Problem: The Mother of All NP Problems

The **Boolean Satisfiability Problem (SAT)** asks: given a Boolean formula, is there an assignment of True/False values to its variables that makes the formula evaluate to True?

Consider the formula (where $\lor$ means OR, $\land$ means AND, and $\neg$ means NOT):
$$\phi(x_1, x_2, x_3) = (x_1 \lor \neg x_2 \lor x_3) \land (\neg x_1 \lor x_2 \lor \neg x_3) \land (x_1 \lor x_2 \lor x_3)$$

This is in *Conjunctive Normal Form (CNF)*: an AND of ORs. Each parenthesized group is a *clause*, and each $x_i$ or $\neg x_i$ is a *literal*.

The question: does there exist an assignment $(x_1, x_2, x_3) \in \{\text{True}, \text{False}\}^3$ that satisfies all clauses simultaneously? This is what makes SAT hard: you must determine whether *any* solution exists, not find a specific one. With 3 variables there are $2^3 = 8$ possibilities; with 100 variables there are $2^{100} \approx 10^{30}$. No known algorithm avoids checking exponentially many cases in the worst case.

For this toy example, we can reason through it. Clause 2 ($\neg x_1 \lor x_2 \lor \neg x_3$) needs at least one of: $x_1 = \text{False}$, $x_2 = \text{True}$, or $x_3 = \text{False}$. Clause 3 needs at least one variable true. Setting $x_2 = \text{True}$ helps both. With $x_2$ fixed, Clause 1 becomes $(x_1 \lor \text{False} \lor x_3)$, requiring $x_1$ or $x_3$ true. Try $(x_1, x_2, x_3) = (\text{True}, \text{True}, \text{True})$:

- Clause 1: $\text{True} \lor \text{False} \lor \text{True} = \text{True}$ $\checkmark$
- Clause 2: $\text{False} \lor \text{True} \lor \text{False} = \text{True}$ $\checkmark$
- Clause 3: $\text{True} \lor \text{True} \lor \text{True} = \text{True}$ $\checkmark$

We found a satisfying assignment, so the formula is satisfiable. But notice: finding this solution required insight or luck. If no solution existed, we would have had to check all $2^n$ possibilities to be certain.

**Why SAT matters:** The Cook-Levin theorem (1971) proved that SAT is *NP-complete*: every problem in NP can be efficiently reduced to a SAT instance. If you can solve SAT efficiently, you can solve *any* NP problem efficiently. This makes SAT the canonical "hard" problem.

**The good news for verification:** Once someone *has* a solution, checking it is easy: just plug in the values. The assignment is a certificate that proves satisfiability. The asymmetry is striking: finding a solution may take exponential time, but verifying one takes linear time.

### #SAT: When Even Certificates Don't Help

Now consider a harder question: **how many** satisfying assignments does a formula have?

This is the **#SAT problem** (pronounced "sharp SAT" or "number SAT"). It's in a complexity class called **#P**, which is believed to be harder than NP.

Why? Because even if someone tells you "there are exactly 47 satisfying assignments," there's no obvious way to verify this without enumerating possibilities. Having one satisfying assignment doesn't tell you there aren't 46 others. Having 47 assignments doesn't prove there isn't a 48th.

For a formula with $n$ variables, there are $2^n$ possible assignments. For $n = 100$, that's about $10^{30}$ assignments (more than the number of atoms in a human body). Even at a trillion checks per second, verifying by enumeration would take longer than the age of the universe.

**This is the hopeless case.** The output is just a number. There's no obvious certificate that proves the count is correct.

Or so it seems.

The breakthrough insight of interactive proofs is that through *interaction* and *randomness*, we can verify even #SAT efficiently. The prover doesn't give us a certificate; instead, we have a conversation that forces a lying prover to contradict themselves.

Polynomials are the key to making this work. They transform #SAT, this hopelessly unverifiable counting problem, into a series of polynomial identity checks where cheating is detectable with overwhelming probability.

We'll see exactly how in Chapter 3 when we study the sum-check protocol. But first, we need to understand why polynomials have this magical power.



## Why Polynomials?

If you've read any paper on zero-knowledge proofs, you've noticed something striking: polynomials are *everywhere*. Witnesses become polynomial evaluations. Constraints become polynomial identities. Verification reduces to checking polynomial properties. The entire field seems obsessed with these algebraic objects.

This is not an accident. Polynomials possess a trinity of properties that make them uniquely suited for verifiable computation:

1. **Representation**: Any discrete data can be encoded as a polynomial

2. **Compression**: A million local constraints become one global identity

3. **Randomization**: The entire polynomial can be tested from a single random point

The rest of this chapter develops each pillar in turn.

## Pillar 1: Representation - From Data to Polynomials

The first magical property: any finite dataset can be encoded as a polynomial.

But first, we must define the terrain. Where do these polynomials live? Not in the real numbers. Remember the Patriot missile from Chapter 1: a rounding error of 0.000000095 seconds, accumulated over time, killed 28 soldiers. Real number arithmetic is treacherous. Equality is approximate, errors accumulate, and 0.1 has no exact binary representation.

Polynomials in ZK proofs live in *finite fields*, mathematical structures where arithmetic is exact. In a finite field, $1/3$ isn't $0.333...$; it's a precise integer. There's no rounding, no overflow, no approximation. Two values are either exactly equal or they're not. This exactness is what makes polynomial "rigidity" possible: if two polynomials differ, they differ exactly, and we can detect it.

It is a historical irony that this structure was discovered by someone who knew he was about to die. In May 1832, twenty-year-old Évariste Galois spent his final night frantically writing mathematics. He had been challenged to a duel the next morning and expected to lose. In those desperate hours, he outlined a new theory of algebraic symmetry, describing number systems that behaved like familiar arithmetic (you could add, subtract, multiply, and divide) but were finite. They didn't stretch to infinity; they looped back on themselves, like a clock.

The next morning, Galois was shot in the abdomen and died the following day. But his "finite fields" turned out to be the perfect environment for computation. Every SNARK, every polynomial commitment, and every error-correcting code in this book lives inside the structure Galois sketched the night before his death.

### Two Ways to Encode Data

Given a vector $a = (a_1, a_2, \ldots, a_n)$ of field elements, we have two natural polynomial representations:

**Coefficient Encoding:** Treat the values as coefficients:
$$p_a(x) = a_1 + a_2 x + a_3 x^2 + \cdots + a_n x^{n-1}$$

This polynomial has degree at most $n-1$. Its coefficients *are* the data. Evaluating $p_a(x)$ at any point $r$ gives us a "fingerprint" of the entire vector: a single value that depends on all the data.

**Evaluation Encoding:** Treat the values as evaluations at fixed points. Find the unique polynomial $q_a(x)$ of degree at most $n-1$ such that:
$$q_a(0) = a_1, \quad q_a(1) = a_2, \quad \ldots, \quad q_a(n-1) = a_n$$

This polynomial exists and is unique, a fact guaranteed by *Lagrange interpolation*, which we'll explore momentarily. Here, the data becomes "the shape of a curve that passes through specific points."

Both encodings are useful in different contexts. Coefficient encoding is natural for fingerprinting; evaluation encoding is natural when we want to extend a function defined on a small domain to a larger one.

### Lagrange Interpolation: The Existence Guarantee

Why does a polynomial passing through $n$ specified points always exist and why is it unique?

Picture a flexible curve that you need to pin down at specific points. With one point, infinitely many curves pass through it. With two points, you've constrained the curve more, but many still fit. The remarkable fact: with $n$ points, there's *exactly one* polynomial of degree at most $n-1$ that passes through all of them. The points completely determine the curve.

**Theorem (Lagrange Interpolation).** Given $n$ distinct points $(x_1, y_1), (x_2, y_2), \ldots, (x_n, y_n)$ in a field $\mathbb{F}$, there exists a unique polynomial $p(x)$ of degree at most $n-1$ such that $p(x_i) = y_i$ for all $i$.

**Construction:** Define the *Lagrange basis polynomials*:
$$L_i(x) = \prod_{j \neq i} \frac{x - x_j}{x_i - x_j}$$

Each $L_i$ has a special property: $L_i(x_i) = 1$ and $L_i(x_j) = 0$ for $j \neq i$. It's a polynomial that "activates" only at point $x_i$.

The interpolating polynomial is then:
$$p(x) = \sum_{i=1}^{n} y_i \cdot L_i(x)$$

Let's verify: at point $x_k$, we get $p(x_k) = \sum_i y_i \cdot L_i(x_k) = y_k \cdot 1 + \sum_{i \neq k} y_i \cdot 0 = y_k$.

**Worked Example:** Find the polynomial through $(0, 2), (1, 5), (2, 10)$.

The Lagrange basis polynomials:
$$L_0(x) = \frac{(x-1)(x-2)}{(0-1)(0-2)} = \frac{(x-1)(x-2)}{2}$$
$$L_1(x) = \frac{(x-0)(x-2)}{(1-0)(1-2)} = \frac{x(x-2)}{-1} = -x(x-2)$$
$$L_2(x) = \frac{(x-0)(x-1)}{(2-0)(2-1)} = \frac{x(x-1)}{2}$$

The interpolating polynomial:
$$p(x) = 2 \cdot \frac{(x-1)(x-2)}{2} + 5 \cdot (-x(x-2)) + 10 \cdot \frac{x(x-1)}{2}$$

Expanding (this is tedious but instructive):
$$p(x) = (x-1)(x-2) - 5x(x-2) + 5x(x-1)$$
$$= (x^2 - 3x + 2) - 5(x^2 - 2x) + 5(x^2 - x)$$
$$= x^2 - 3x + 2 - 5x^2 + 10x + 5x^2 - 5x$$
$$= x^2 + 2x + 2$$

Verification: $p(0) = 2$, $p(1) = 1 + 2 + 2 = 5$, $p(2) = 4 + 4 + 2 = 10$. All match.

**Uniqueness:** If two degree-$(n-1)$ polynomials $p$ and $q$ agree at $n$ points, their difference $p - q$ is a polynomial of degree at most $n-1$. But $p - q$ vanishes at each of the $n$ points where $p$ and $q$ agree, meaning it has $n$ roots. A nonzero polynomial of degree $n-1$ can have at most $n-1$ roots, so $p - q$ must be the zero polynomial. Therefore $p = q$.

### The Rigidity of Polynomials

Here's the key property that makes verification possible:

**Two different degree-$d$ polynomials can agree on at most $d$ points.**

This seems like a simple algebraic fact, but its consequences are profound. Consider what this means:

If you and I each have a degree-99 polynomial, and they're *different* polynomials, then they can agree on at most 99 input values. Out of, say, $2^{256}$ possible inputs in a cryptographic field, they *disagree* on all but at most 99 of them.

This is *rigidity*. A polynomial can't "cheat locally." If a prover tries to construct a fake polynomial that agrees with the honest one at a few strategic points, the fake will disagree almost everywhere else.

Compare this to arbitrary functions. Two functions could agree on 99% of inputs and differ on just 1%. But a degree-99 polynomial that differs from another *anywhere* must differ on essentially *all* points. The disagreement isn't localized; it's smeared across the domain.

This rigidity has a striking consequence: you cannot construct a degree-$d$ polynomial that matches another degree-$d$ polynomial at strategically chosen points while differing elsewhere. If two degree-$d$ polynomials differ at all, they differ almost everywhere. A local patch is impossible; any change propagates globally.

A polynomial cannot lie consistently. It must betray itself almost everywhere.

This property alone is purely mathematical. To turn it into a verification tool, we need one more ingredient: randomness.



## Pillar 2: Randomization - The Schwartz-Zippel Lemma

In 1976, Gary Miller discovered a fast algorithm to test whether a number is prime. There was one problem: proving it correct required assuming the Riemann Hypothesis, one of the deepest unsolved problems in mathematics. Four years later, Michael Rabin found a way out. He modified Miller's test to use random sampling. The new algorithm couldn't *guarantee* the right answer, but it could make errors arbitrarily unlikely, say, less likely than a cosmic ray flipping a bit in your computer's memory. By embracing randomness, Rabin traded an unproven conjecture for a proven bound on failure probability.

This is the paradigm shift: randomness as a *resource* for verification. A cheating prover might fool a deterministic check, but fooling a random check requires being lucky, and we can make luck arbitrarily improbable.

The rigidity of polynomials becomes a verification tool through one of the most important theorems in computational complexity:

**Schwartz-Zippel Lemma.** Let $P(x_1, \ldots, x_n)$ be a non-zero polynomial of total degree $d$ over a field $\mathbb{F}$. If we choose $r_1, \ldots, r_n$ uniformly at random from a finite subset $S \subseteq \mathbb{F}$, then:
$$\Pr[P(r_1, \ldots, r_n) = 0] \leq \frac{d}{|S|}$$

**In plain English:** A non-zero polynomial almost never evaluates to zero at a random point, provided the field is much larger than the polynomial's degree.

### Why This Is Profound

Consider verifying whether two polynomials $p(x)$ and $q(x)$ are equal. The naive approach: compare their coefficients one by one. If each polynomial has degree 1 million, that's a million comparisons.

Schwartz-Zippel offers a shortcut: pick a random $r$ and check if $p(r) = q(r)$.

- If $p = q$: The check always passes.
- If $p \neq q$: The polynomial $p - q$ is non-zero with degree at most 1 million. By Schwartz-Zippel, $\Pr[p(r) = q(r)] = \Pr[(p-q)(r) = 0] \leq \frac{10^6}{|\mathbb{F}|}$.

In a field of size $2^{256}$, this probability is about $2^{-236}$ (far smaller than the odds of guessing a 256-bit private key).

**One random evaluation distinguishes degree-$d$ polynomials with probability $1 - d/|\mathbb{F}|$.**

### A Proof Sketch

For a single variable, the proof is straightforward. A non-zero polynomial of degree $d$ has at most $d$ roots. If $S$ has $|S|$ elements, the probability of hitting a root is at most $d/|S|$.

For multiple variables, the proof proceeds by induction. Write $P(x_1, \ldots, x_n)$ as a polynomial in $x_1$ with coefficients that are polynomials in $x_2, \ldots, x_n$:
$$P(x_1, x_2, \ldots, x_n) = \sum_{i=0}^{d_1} x_1^i \cdot Q_i(x_2, \ldots, x_n)$$

At least one coefficient polynomial is non-zero (otherwise $P = 0$). Call it $Q_j$. By induction, a random choice of $r_2, \ldots, r_n$ makes $Q_j(r_2, \ldots, r_n) \neq 0$ with probability at least $1 - (d - d_1)/|S|$. Conditioned on this, $P(x_1, r_2, \ldots, r_n)$ is a non-zero univariate polynomial of degree at most $d_1$, so a random $r_1$ makes it zero with probability at most $d_1/|S|$. The union bound gives the result.

### Application: Polynomial Fingerprinting for File Comparison

Consider a practical problem: Alice and Bob each have a massive file (think terabytes) and want to check if their files are identical. Sending entire files is prohibitively expensive. Can they compare with minimal communication?

**The setup:** Interpret each file as a vector of $n$ field elements: $a = (a_1, \ldots, a_n)$ for Alice, $b = (b_1, \ldots, b_n)$ for Bob. Encode them as polynomials:
$$p_A(x) = \sum_{i=1}^{n} a_i x^{i-1}, \quad p_B(x) = \sum_{i=1}^{n} b_i x^{i-1}$$

**The protocol:**

1. Alice picks a random $r \in \mathbb{F}$

2. Alice computes her *fingerprint*: $v_A = p_A(r)$

3. Alice sends $(r, v_A)$ to Bob (just two field elements!)

4. Bob computes $v_B = p_B(r)$ and checks if $v_A = v_B$

**Analysis:**

- **Completeness:** If $a = b$, the polynomials are identical, so $p_A(r) = p_B(r)$ always. Bob correctly accepts.

- **Soundness:** If $a \neq b$, then $p_A(x) - p_B(x)$ is non-zero with degree at most $n-1$. By Schwartz-Zippel:
$$\Pr[p_A(r) = p_B(r)] = \Pr[(p_A - p_B)(r) = 0] \leq \frac{n-1}{|\mathbb{F}|}$$

They've compared a terabyte of data by exchanging two field elements. The probability of error is negligible.

**A Worked Example with Actual Numbers:**

Alice has $a = (2, 1)$, Bob has $b = (3, 5)$. Working in $\mathbb{F}_{11}$ (the field of integers modulo 11).

Their polynomials:

- $p_A(x) = 2 + 1 \cdot x = 2 + x$

- $p_B(x) = 3 + 5 \cdot x$

Alice picks $r = 7$:

- $p_A(7) = 2 + 7 = 9$

- $p_B(7) = 3 + 5 \cdot 7 = 3 + 35 = 38 \equiv 5 \pmod{11}$

Since $9 \neq 5$, Bob correctly concludes the vectors differ.

**When would they collide?** Only if $p_A(r) = p_B(r)$:

$$2 + r \equiv 3 + 5r \pmod{11}$$
$$-1 \equiv 4r \pmod{11}$$
$$10 \equiv 4r \pmod{11}$$

To solve for $r$, we need the multiplicative inverse of 4 modulo 11. Since $4 \cdot 3 = 12 \equiv 1 \pmod{11}$, we have $4^{-1} \equiv 3$.

So $r \equiv 3 \cdot 10 = 30 \equiv 8 \pmod{11}$.

The only "bad" random choice is $r = 8$. With 11 possible choices, the collision probability is exactly $1/11 \approx 9\%$. In a cryptographic field with $2^{256}$ elements, this would be $1/2^{256}$ (essentially zero).

### Application: Batch Verification of Signatures

The same principle powers batch verification in signature schemes like Schnorr.

Recall that a Schnorr signature $(R, s)$ on message $m$ under public key $P$ satisfies:
$$s \cdot G = R + e \cdot P$$
where $e = H(R, P, m)$ is the challenge hash. Verifying this requires two scalar multiplications.

Now suppose a node must verify 1000 signatures. Checking each individually costs 2000 scalar multiplications. Can we do better?

**The batch verification trick**: Take a random linear combination of all verification equations. If each equation $s_i G = R_i + e_i P_i$ holds, then for any coefficients $z_i$:
$$\left(\sum_i z_i s_i\right) G = \sum_i z_i R_i + \sum_i z_i e_i P_i$$

This is a single multi-scalar multiplication (MSM), dramatically faster than 1000 separate verifications using algorithms like Pippenger's.

**Why random coefficients?** If we just summed the equations ($z_i = 1$), an attacker could forge two invalid signatures whose errors cancel: one with error $+\Delta$, another with $-\Delta$. The batch check would pass, but individual signatures would fail.

Random $z_i$ prevent this. If any signature is invalid, the batch equation becomes a non-zero polynomial in the $z_i$ variables. By Schwartz-Zippel, random $z_i$ satisfy a non-zero polynomial with negligible probability.

This is polynomial identity testing in disguise. The honest case gives the zero polynomial; any cheating gives a non-zero polynomial that random evaluation catches.

### Arithmetic Consensus

Step back and notice something strange about what just happened.

In the fingerprinting protocol, Alice and Bob reached agreement about whether their files match. They didn't trust each other. They didn't consult a third party. They didn't negotiate or compare credentials. They simply evaluated polynomials at the same random point, and mathematics forced them to the same conclusion.

This is a new kind of agreement. Philosophers have long studied how agents come to share beliefs. The [epistemology of testimony](https://iep.utm.edu/ep-testi/) asks how we gain knowledge from what others tell us, and the answer always involves trust: we believe the speaker because of their reputation, authority, or our assessment of their incentives. [Social epistemology](https://plato.stanford.edu/entries/epistemology-social/) studies how groups arrive at consensus, and the mechanisms are social: communication, persuasion, deference to experts.

Schwartz-Zippel enables something different. Two systems that share no trust relationship, that have never communicated, that know nothing about each other's reliability, can independently verify the same polynomial identity and reach the same conclusion. Not because they agreed to agree, but because the structure of low-degree polynomials leaves no room for disagreement. If $p \neq q$, then $p(r) \neq q(r)$ for almost all $r$. Any system capable of field arithmetic will detect the difference.

Call this **arithmetic consensus**: agreement forced by mathematical structure rather than achieved by social process. The boundaries of this regime are precise. Any statement reducible to polynomial identity testing can be verified this way. Any claim expressible as "these two low-degree polynomials are equal" becomes a claim that any arithmetic system can check, with the same answer guaranteed.

This relates to a tradition in the philosophy of mathematics. [Intuitionism](https://plato.stanford.edu/entries/intuitionism/), developed by Brouwer in the early 20th century, held that a mathematical statement is meaningful only if we can construct a proof of it. For the intuitionist, "there exists an x" means "we can exhibit an x." Truth is inseparable from proof.

Arithmetic consensus takes a different but related position: for statements about polynomial identities, truth is inseparable from *verification*. The proof object (a random evaluation point and its result) doesn't require trust in whoever produced it. Any verifier running the same arithmetic reaches the same conclusion. This is intersubjective truth without intersubjectivity. The agreement happens not between minds but between any systems capable of arithmetic.

The applications in cryptography (verifiable computation, zero-knowledge proofs, blockchain consensus) are engineering achievements. But underneath them lies a philosophical shift: for a certain class of claims, we can replace "I trust the speaker" with "I checked the math." This is not a small thing. It's a new foundation for agreement in a world of untrusted parties.



## Error-Correcting Codes: The Deeper Structure

The polynomial fingerprinting protocol isn't just a clever trick; it's an instance of a profound mathematical structure that appears throughout ZK proofs: **error-correcting codes**.

### What Is an Error-Correcting Code?

Imagine sending a message through a noisy channel (think: radio transmission through interference, reading data from a scratched DVD, or communicating with a spacecraft). Some bits might get flipped. How do you ensure the receiver can still recover the original message?

The naive approach: send the message three times and take a majority vote. If you send "1" as "111" and one bit flips to "011," the receiver sees two 1s and one 0, guesses "1," and succeeds.

But this is inefficient; you've tripled your transmission length to correct one error.

**Error-correcting codes** provide a systematic way to add redundancy that can detect and correct errors far more efficiently.

### The Key Definitions

An **(n, k, d) code** over alphabet $\Sigma$ consists of:

- A set of **messages** of length $k$

- An **encoding function** that maps each message to a **codeword** of length $n > k$

- A **minimum distance** $d$: any two distinct codewords differ in at least $d$ positions

The minimum distance determines the code's power:

- **Error detection:** Can detect up to $d-1$ errors (if we see something that's not a valid codeword, we know an error occurred)

- **Error correction:** Can correct up to $\lfloor(d-1)/2\rfloor$ errors (the corrupted codeword is still closest to the original)

**Example: Repetition Code.** Encode message bit $b$ as $bbb$ (repeat it 3 times). This is a (3, 1, 3) code: codewords are "000" and "111," which differ in all 3 positions. It can detect 2 errors and correct 1 error.

### Reed-Solomon Codes: Polynomials as Codewords

The most important family of error-correcting codes for our purposes is the **Reed-Solomon code**, discovered by Irving Reed and Gustave Solomon in 1960.

**Construction:** Work over a field $\mathbb{F}$ with at least $n$ elements. Choose $n$ distinct evaluation points $\alpha_1, \ldots, \alpha_n \in \mathbb{F}$.

- **Messages:** Polynomials of degree at most $k-1$ (equivalently, vectors of $k$ coefficients)

- **Encoding:** Evaluate the polynomial at all $n$ points:
  $$\text{Encode}(p) = (p(\alpha_1), p(\alpha_2), \ldots, p(\alpha_n))$$

- **Codewords:** Vectors of $n$ field elements

**The minimum distance:** If $p \neq q$ are distinct polynomials of degree at most $k-1$, then $p - q$ is a non-zero polynomial of degree at most $k-1$, which has at most $k-1$ roots. Therefore $p$ and $q$ can agree on at most $k-1$ of the $n$ evaluation points, meaning they *differ* on at least $n - (k-1) = n - k + 1$ positions.

This gives an $(n, k, n-k+1)$ code: an optimal relationship between redundancy and distance, known as a *Maximum Distance Separable (MDS)* code.

**Worked Example:** Consider a Reed-Solomon code over $\mathbb{F}_{11}$ with $n = 7$ evaluation points $\{0, 1, 2, 3, 4, 5, 6\}$ and message polynomials of degree at most $k-1 = 2$ (so $k = 3$).

Message: the polynomial $p(x) = 2 + 3x + x^2$ (coefficients $[2, 3, 1]$).

Codeword: evaluate at each point:

- $p(0) = 2$

- $p(1) = 2 + 3 + 1 = 6$

- $p(2) = 2 + 6 + 4 = 12 \equiv 1 \pmod{11}$

- $p(3) = 2 + 9 + 9 = 20 \equiv 9 \pmod{11}$

- $p(4) = 2 + 12 + 16 = 30 \equiv 8 \pmod{11}$

- $p(5) = 2 + 15 + 25 = 42 \equiv 9 \pmod{11}$

- $p(6) = 2 + 18 + 36 = 56 \equiv 1 \pmod{11}$

Codeword: $(2, 6, 1, 9, 8, 9, 1)$.

The minimum distance is $n - k + 1 = 7 - 3 + 1 = 5$. Any two codewords differ in at least 5 positions. This code can correct up to $\lfloor 4/2 \rfloor = 2$ errors.

### Why Reed-Solomon Codes Power ZK Proofs

The connection to zero-knowledge proofs is now clear:

| Error-Correcting Codes | ZK Proof Systems                        |
|------------------------|-----------------------------------------|
| Message                | Witness (prover's secret)               |
| Encoding               | Polynomial evaluation over large domain |
| Codeword               | Prover's committed values               |
| Distance property      | Cheating changes most of the codeword   |
| Random sampling        | Verifier's random challenges            |

In ZK:

1. The prover's witness $w$ is encoded as a polynomial $p_w$.

2. The polynomial is "committed" by evaluating it at many points (or via a polynomial commitment scheme).

3. The verifier samples random points and checks consistency.

4. If the prover cheated (wrong witness), the polynomial won't satisfy required properties, and this corruption spreads across almost all evaluation points due to the Reed-Solomon distance property.

**The key insight:** Reed-Solomon encoding is *distance-amplifying*. A small, localized lie (wrong witness value) becomes a large, detectable corruption (wrong polynomial evaluations everywhere).

### Real-World Applications of Reed-Solomon

Before we move on, it's worth appreciating how ubiquitous Reed-Solomon codes are:

- **QR codes:** The chunky squares on product labels use Reed-Solomon to remain readable even when partially obscured or damaged.

- **CDs, DVDs, Blu-rays:** Scratches that destroy data are corrected by Reed-Solomon coding.

- **Deep-space communication:** Voyager, Cassini, and other spacecraft use Reed-Solomon codes to send data across billions of miles despite noise and signal degradation.

- **RAID storage:** Disk arrays use Reed-Solomon to survive drive failures.

- **Digital television (DVB):** Broadcast signals use Reed-Solomon to handle transmission errors.

The same mathematical structure that lets your scratched DVD still play a movie is what lets ZK proofs detect a lying prover from a single random query.



## Pillar 3: Compression - From Many Constraints to One

We've seen how polynomials encode data and how random sampling detects differences. The third pillar explains how polynomials let us *aggregate* many checks into one.

### The Compression Problem

A computation consists of many local constraints. Consider a circuit with a million gates. Each multiplication gate with inputs $a$ and $b$ and output $c$ imposes a constraint: $a \cdot b = c$.

Checking all million constraints individually takes a million operations. Can we do better?

**The key insight:** We can aggregate all constraints into a single polynomial identity.

### The Vanishing Polynomial Technique

Suppose we have $n$ constraints that should all equal zero:
$$C_1 = 0, \quad C_2 = 0, \quad \ldots, \quad C_n = 0$$

**Step 1: Encode as a polynomial.** Find a polynomial $C(x)$ such that:

- $C(1) = C_1$

- $C(2) = C_2$

- $\ldots$

- $C(n) = C_n$

**Step 2: The equivalence.** The statement "all constraints are satisfied" is equivalent to:
$$C(x) = 0 \text{ for all } x \in \{1, 2, \ldots, n\}$$

**Step 3: Use the Factor Theorem.** The polynomial $C(x)$ equals zero at points $\{1, 2, \ldots, n\}$ if and only if $C(x)$ is divisible by the *vanishing polynomial*:
$$Z(x) = (x-1)(x-2)\cdots(x-n)$$

Think of $Z(x)$ as a stencil with holes at $x = 1, 2, \ldots, n$. If $C(x)$ truly equals zero at those points, it passes through the holes perfectly: the division $C(x) / Z(x)$ comes out clean with no remainder. If $C(x)$ misses even one hole (nonzero at some constraint point), it hits the stencil, and the division leaves a remainder. The polynomial doesn't fit.

**Step 4: The divisibility test.** The statement "all constraints are satisfied" becomes: there exists a *quotient polynomial* $H(x)$ such that:
$$C(x) = H(x) \cdot Z(x)$$

**Step 5: Random verification.** By Schwartz-Zippel, if this identity holds everywhere, it holds at a random point $r$ with high probability. Conversely, if it fails anywhere, it fails at $r$ with probability $1 - d/|\mathbb{F}|$.

So the verifier only needs to check:
$$C(r) \stackrel{?}{=} H(r) \cdot Z(r)$$

A million local checks become one divisibility test, verified at a single random point.

### A Worked Example: Three Constraints

Let's see this concretely. Suppose we have three constraints that should be zero:

- $C_1 = 0$ (at $x = 1$)

- $C_2 = 0$ (at $x = 2$)

- $C_3 = 0$ (at $x = 3$)

Working in $\mathbb{F}_{17}$, suppose an honest prover has $C_1 = C_2 = C_3 = 0$, so $C(x)$ is the zero polynomial on $\{1, 2, 3\}$.

The vanishing polynomial:
$$Z(x) = (x-1)(x-2)(x-3) = x^3 - 6x^2 + 11x - 6$$

If all constraints are satisfied, $C(x) = H(x) \cdot Z(x)$ for some $H(x)$.

Now suppose a cheating prover has $C_1 = 0$, $C_2 = 5$ (wrong!), $C_3 = 0$. The polynomial $C(x)$ passes through $(1, 0), (2, 5), (3, 0)$.

Using Lagrange interpolation:
$$C(x) = 0 \cdot L_1(x) + 5 \cdot L_2(x) + 0 \cdot L_3(x) = 5 \cdot L_2(x)$$

where $L_2(x) = \frac{(x-1)(x-3)}{(2-1)(2-3)} = \frac{(x-1)(x-3)}{-1} = -(x-1)(x-3) = -x^2 + 4x - 3$.

So $C(x) = 5(-x^2 + 4x - 3) = -5x^2 + 20x - 15 \equiv 12x^2 + 3x + 2 \pmod{17}$.

Is this divisible by $Z(x) = (x-1)(x-2)(x-3)$? Let's check: $C(2) = 12 \cdot 4 + 3 \cdot 2 + 2 = 48 + 6 + 2 = 56 \equiv 5 \pmod{17}$.

Since $C(2) = 5 \neq 0$, but $Z(2) = 0$, the division $C(x) / Z(x)$ would have a pole at $x = 2$. The divisibility fails, and no valid quotient $H(x)$ exists.

The verifier, picking a random $r$, will find that $C(r) \neq H(r) \cdot Z(r)$ for any claimed $H$ with overwhelming probability.



## Freivald's Algorithm: Polynomials in Disguise

Let's examine a beautiful algorithm that shows the polynomial paradigm in a surprising context: verifying matrix multiplication.

### The Problem

Given three $n \times n$ matrices $A$, $B$, and $C$, determine whether $C = A \cdot B$.

**The naive approach:** Compute $A \cdot B$ directly and compare with $C$. Using the standard algorithm, this takes $O(n^3)$ multiplications. Even with the fastest known algorithm (Strassen's descendants), it's $O(n^{2.37\ldots})$ (still much worse than $O(n^2)$).

If we're trying to *verify* that someone else computed the product correctly, do we really need to redo all their work?

### Freivald's Insight (1977)

Rüdiger Freivald proposed a remarkably simple test:

1. Pick a random vector $\vec{x} \in \mathbb{F}^n$

2. Compute $\vec{y} = B\vec{x}$ (one matrix-vector product: $O(n^2)$)

3. Compute $\vec{z} = A\vec{y} = A(B\vec{x})$ (another matrix-vector product: $O(n^2)$)

4. Compute $\vec{w} = C\vec{x}$ (another matrix-vector product: $O(n^2)$)

5. Check if $\vec{z} = \vec{w}$

**Total work:** Three matrix-vector products, so $O(n^2)$ (a full factor of $n$ faster than matrix multiplication!).

### Why It Works

**If $C = AB$:** Then $C\vec{x} = AB\vec{x} = A(B\vec{x})$, so $\vec{w} = \vec{z}$ always. The test passes.

**If $C \neq AB$:** Let $D = C - AB \neq 0$. The test passes only if $D\vec{x} = 0$.

Since $D \neq 0$, at least one row of $D$ is non-zero. Call it row $i$, with entries $(d_{i,1}, d_{i,2}, \ldots, d_{i,n})$ not all zero.

The $i$-th component of $D\vec{x}$ is:
$$(D\vec{x})_i = d_{i,1}x_1 + d_{i,2}x_2 + \cdots + d_{i,n}x_n$$

This is a linear polynomial in the variables $x_1, \ldots, x_n$. For this polynomial to equal zero, we need:
$$d_{i,1}x_1 + d_{i,2}x_2 + \cdots + d_{i,n}x_n = 0$$

If we pick each $x_j$ uniformly at random from $\mathbb{F}$, what's the probability this equation holds?

**Claim:** For a non-zero linear polynomial over $\mathbb{F}$, a random input is a root with probability exactly $1/|\mathbb{F}|$.

**Proof:** Suppose $d_{i,k} \neq 0$ for some $k$. We can rewrite:
$$x_k = -\frac{1}{d_{i,k}}\left(d_{i,1}x_1 + \cdots + d_{i,k-1}x_{k-1} + d_{i,k+1}x_{k+1} + \cdots + d_{i,n}x_n\right)$$

For any fixed choice of $x_1, \ldots, x_{k-1}, x_{k+1}, \ldots, x_n$, there's exactly one value of $x_k$ that makes the sum zero. Since $x_k$ is chosen uniformly from $|\mathbb{F}|$ possibilities, the probability of hitting that one value is $1/|\mathbb{F}|$. $\square$

So with a single random vector, Freivald's algorithm detects incorrect matrix multiplication with probability at least $1 - 1/|\mathbb{F}|$.

### Amplifying Confidence

If $1/|\mathbb{F}|$ isn't small enough, we can repeat with independent random vectors:

1. Pick $k$ independent random vectors $\vec{x}^{(1)}, \ldots, \vec{x}^{(k)}$

2. For each, check if $A(B\vec{x}^{(i)}) = C\vec{x}^{(i)}$

3. Accept if all checks pass

If $C \neq AB$, each check passes with probability at most $1/|\mathbb{F}|$, and the checks are independent. So:
$$\Pr[\text{all } k \text{ checks pass} \mid C \neq AB] \leq (1/|\mathbb{F}|)^k = 1/|\mathbb{F}|^k$$

With $|\mathbb{F}| = 2^{64}$ and $k = 4$ repetitions, the false acceptance probability is $2^{-256}$ (cryptographically negligible).

### Freivald's Algorithm as Polynomial Identity Testing

Here's the connection to polynomials that might not be immediately obvious.

Consider the matrices $A$, $B$, $C$ as defining a polynomial identity. The claim $C = AB$ is equivalent to the matrix identity:
$$C - AB = 0$$

We can view each entry $(C - AB)_{ij}$ as a polynomial in the entries of the matrices. The test $D\vec{x} = 0$ is checking that a related set of linear polynomials (one for each row of $D$) all vanish at the random point $\vec{x}$.

More directly: the expression $\vec{x}^T D \vec{y}$ for random vectors $\vec{x}, \vec{y}$ defines a bilinear polynomial in the entries of $D$. This polynomial is non-zero if and only if $D \neq 0$. By a bilinear version of Schwartz-Zippel, random inputs make a non-zero bilinear form non-zero with high probability.

**Freivald's test is polynomial identity testing in disguise.**

This is a recurring theme: many efficient verification algorithms, when analyzed carefully, turn out to be checking polynomial identities via random evaluation.

### A Complete Worked Example

Let's verify a matrix multiplication over $\mathbb{F}_7$.

$$A = \begin{pmatrix} 2 & 1 \\ 3 & 4 \end{pmatrix}, \quad B = \begin{pmatrix} 1 & 2 \\ 5 & 3 \end{pmatrix}$$

**First, the honest computation:**

$$AB = \begin{pmatrix} 2 \cdot 1 + 1 \cdot 5 & 2 \cdot 2 + 1 \cdot 3 \\ 3 \cdot 1 + 4 \cdot 5 & 3 \cdot 2 + 4 \cdot 3 \end{pmatrix} = \begin{pmatrix} 7 & 7 \\ 23 & 18 \end{pmatrix} \equiv \begin{pmatrix} 0 & 0 \\ 2 & 4 \end{pmatrix} \pmod 7$$

**Suppose the prover claims $C = \begin{pmatrix} 0 & 0 \\ 2 & 4 \end{pmatrix}$ (correct).**

Pick random $\vec{x} = (3, 5)^T$.

Compute $B\vec{x}$:

$$B\vec{x} = \begin{pmatrix} 1 & 2 \\ 5 & 3 \end{pmatrix} \begin{pmatrix} 3 \\ 5 \end{pmatrix} = \begin{pmatrix} 3 + 10 \\ 15 + 15 \end{pmatrix} = \begin{pmatrix} 13 \\ 30 \end{pmatrix} \equiv \begin{pmatrix} 6 \\ 2 \end{pmatrix} \pmod 7$$

Compute $A(B\vec{x})$:

$$A(B\vec{x}) = \begin{pmatrix} 2 & 1 \\ 3 & 4 \end{pmatrix} \begin{pmatrix} 6 \\ 2 \end{pmatrix} = \begin{pmatrix} 12 + 2 \\ 18 + 8 \end{pmatrix} = \begin{pmatrix} 14 \\ 26 \end{pmatrix} \equiv \begin{pmatrix} 0 \\ 5 \end{pmatrix} \pmod 7$$

Compute $C\vec{x}$:

$$C\vec{x} = \begin{pmatrix} 0 & 0 \\ 2 & 4 \end{pmatrix} \begin{pmatrix} 3 \\ 5 \end{pmatrix} = \begin{pmatrix} 0 \\ 6 + 20 \end{pmatrix} = \begin{pmatrix} 0 \\ 26 \end{pmatrix} \equiv \begin{pmatrix} 0 \\ 5 \end{pmatrix} \pmod 7$$

Since $A(B\vec{x}) = (0, 5)^T = C\vec{x}$, the test passes.

**Now suppose a cheating prover claims $C' = \begin{pmatrix} 0 & 1 \\ 2 & 4 \end{pmatrix}$ (wrong in position (1,2)).**

With the same $\vec{x} = (3, 5)^T$:

Compute $C'\vec{x}$:

$$C'\vec{x} = \begin{pmatrix} 0 & 1 \\ 2 & 4 \end{pmatrix} \begin{pmatrix} 3 \\ 5 \end{pmatrix} = \begin{pmatrix} 5 \\ 26 \end{pmatrix} \equiv \begin{pmatrix} 5 \\ 5 \end{pmatrix} \pmod 7$$

We have $A(B\vec{x}) = (0, 5)^T \neq (5, 5)^T = C'\vec{x}$.

The test fails, catching the cheater.



## Beyond Schwartz-Zippel: Why Polynomials Are Uniquely Suited

You might wonder: could we use other functions besides polynomials? What makes them special?

### 1. Low-Degree Extension

Pillar 1 established that any finite dataset can be encoded as a polynomial via Lagrange interpolation. The cryptographic payoff is the *low-degree extension*: given a function $f$ defined on a small domain like $\{0, 1\}^n$ (just $2^n$ points), we can extend it to a unique low-degree polynomial over the entire field (potentially $2^{256}$ points). The extension is determined: there's exactly one degree-$(2^n - 1)$ polynomial that agrees with $f$ on the Boolean hypercube. This is the foundation of the sum-check protocol and the GKR protocol. Compare this to a hash function $H: \mathbb{F} \to \mathbb{F}$, which can take any value at any input. Knowing $H$ at a million points tells you nothing about $H$ at the next point. There's no interpolation, no structure to exploit.

### 2. Efficient Evaluation

Given a polynomial's coefficients, we can compute its value at any point in $O(d)$ time using Horner's method:
$$p(x) = a_0 + x(a_1 + x(a_2 + \cdots + x(a_{d-1} + x \cdot a_d)\cdots))$$

This is $d$ multiplications and $d$ additions (optimal).

### 3. Homomorphic Structure

Polynomials form a *ring*: we can add and multiply them, and these operations correspond to coefficient-wise operations. This algebraic structure is what makes polynomial commitment schemes like KZG possible. They allow us to verify polynomial relationships "in the exponent" without revealing the polynomials themselves. If we commit to $p(x)$ and $q(x)$, we can check $p(x) + q(x) = r(x)$ without learning any coefficients.

### 4. FFT Speedups

Over special domains, specifically the $n$-th roots of unity in a field, polynomial evaluation and interpolation can be performed in $O(n \log n)$ time via the *Fast Fourier Transform*.

Without FFT, evaluating a degree-$n$ polynomial at $n$ points takes $O(n^2)$ operations. With FFT over roots of unity, it's $O(n \log n)$.

This speedup is essential for practical ZK systems. Prover complexity in many SNARKs is dominated by FFT operations.

### 5. Composability

Polynomials compose predictably:

- If $p$ has degree $d_p$ and $q$ has degree $d_q$, then $p(q(x))$ has degree $d_p \cdot d_q$

- Products $p \cdot q$ have degree $d_p + d_q$

- Sums $p + q$ have degree $\max(d_p, d_q)$

This predictability is essential for analyzing protocols. When the verifier asks for $p(r) \cdot q(r)$, they know the result should come from a polynomial of degree $d_p + d_q$, and can set the soundness parameters accordingly.



## The Polynomial Paradigm: A Unified View

We can now state the polynomial paradigm that underlies essentially all modern ZK proofs:

1. **Represent** the computation as polynomials: witness values, constraint evaluations, everything becomes polynomial data

2. **Compress** many constraints into a single polynomial identity, typically a divisibility condition or a summation equality

3. **Randomize** to check the identity: evaluate at random points, relying on Schwartz-Zippel to catch any cheating

This paradigm appears in every major ZK system:

- **Groth16:** R1CS constraints become a QAP divisibility check: $L(x) \cdot R(x) - O(x) = H(x) \cdot Z(x)$

- **PLONK:** Gate constraints and wiring constraints become polynomial identities checked via random challenges

- **STARKs:** AIR constraints become low-degree polynomial conditions verified by the FRI protocol

- **Sum-check:** Summation claims over exponentially many terms reduce to a single polynomial evaluation



## Key Takeaways

1. **The counting problem (#SAT) motivates why polynomials matter:** Some computations have no obvious short certificate, but polynomial encodings enable efficient verification through interaction and randomness.

2. **Polynomials encode data:** Any finite dataset becomes a polynomial through coefficient encoding (data = coefficients) or evaluation encoding (data = values at fixed points). Lagrange interpolation guarantees this encoding exists and is unique.

3. **Polynomials are rigid:** Two different degree-$d$ polynomials agree on at most $d$ points. Local differences become global differences; you can't cheat in one place without affecting almost everywhere.

4. **Schwartz-Zippel enables efficient testing:** A non-zero polynomial evaluates to zero at a random point with probability at most $d/|\mathbb{F}|$. For cryptographic fields, this is negligible.

5. **This is an error-correcting code:** The polynomial paradigm is the Reed-Solomon code applied to computation verification. A small lie in the witness becomes corruption across essentially all evaluation points.

6. **Freivald's algorithm is polynomial identity testing:** Matrix multiplication verification in $O(n^2)$ time (instead of $O(n^3)$) works because it's checking linear polynomial identities via random evaluation.

7. **Constraints compress to identities:** Many local constraints become a single polynomial divisibility condition: $C(x) = H(x) \cdot Z(x)$ where $Z$ is the vanishing polynomial.

8. **The structure is unique:** Polynomials combine efficient evaluation, unique interpolation, homomorphic properties, FFT speedups, and composability in ways no other mathematical object does.

9. **The paradigm is universal:** Every major ZK system (Groth16, PLONK, STARKs, sum-check) uses the same three-step approach: represent as polynomials, compress constraints to identities, verify via random evaluation.

10. **Commitment + evaluation = proof architecture:** Committing to a polynomial locks the prover to a single function; random evaluation checks that function is correct. This commit-then-evaluate pattern is the skeleton of every modern SNARK.





\newpage

# Chapter 3: The Sum-Check Protocol

In late 1989, the field of complexity theory was stuck.

Researchers believed that Interactive Proofs were a relatively weak tool, capable of verifying only a handful of graph problems. The consensus was clear: interaction helped, but not by much.

Then came the email.

Noam Nisan, a master's student at Hebrew University, sent a draft to Lance Fortnow at the University of Chicago. It contained a protocol that used polynomials to verify something thought impossible: the permanent of a matrix. Fortnow showed it to his colleagues Howard Karloff and Carsten Lund. They realized the technique didn't just apply to matrices. It applied to *everything* in the polynomial hierarchy.

When the paper was released, it didn't just solve a problem. It caused a crisis. The result implied that "proofs" were far more powerful than anyone had imagined. Within weeks, Adi Shamir (the "S" in RSA) used the same technique to prove IP = PSPACE: interactive proofs could verify any problem solvable with polynomial memory, even if finding the solution took eons.

The engine powering this revolution was a single elegant idea: the **sum-check protocol**.

The sum-check protocol takes a claim that seems fundamentally expensive to verify, the sum of a polynomial over all points of a high-dimensional domain, and reduces it to something trivial: a single evaluation at a random point. The verifier's work scales *linearly* with the number of variables, not exponentially with the size of the domain.

This chapter develops the sum-check protocol from first principles. We'll see exactly how the protocol works, why it's sound, and how any lie propagates through the protocol until it becomes a simple falsehood the verifier can catch. Along the way, we'll trace through complete worked examples with actual field values, because this protocol is too important to understand only abstractly.



## The Problem: Verifying Exponential Sums

Suppose a prover claims to know the value of the following sum:

$$H = \sum_{b_1 \in \{0,1\}} \sum_{b_2 \in \{0,1\}} \cdots \sum_{b_\nu \in \{0,1\}} g(b_1, b_2, \ldots, b_\nu)$$

Here $g$ is a $\nu$-variate polynomial over a finite field $\mathbb{F}$, and the sum ranges over all $2^\nu$ points of the **boolean hypercube** $\{0,1\}^\nu$: the set of all binary strings of length $\nu$. Think of it as the corners of a $\nu$-dimensional cube, where each coordinate is either 0 or 1. For $\nu = 3$, these are the eight vertices $(0,0,0), (0,0,1), \ldots, (1,1,1)$. The prover says the answer is $H$. Do you believe it?

A naive verifier would evaluate $g$ at every point of the hypercube and add up the results. But this requires $2^\nu$ evaluations, exponential in the number of variables. For $\nu = 100$, this is hopelessly infeasible.

The sum-check protocol solves this problem. It allows a verifier to check the claimed value of $H$ with high probability, in time that is only linear in $\nu$ and the time it takes to evaluate $g$ at a *single* random point. This represents an exponential speedup.

But how can you verify a sum without computing it? The answer lies in a beautiful idea: **claim reduction via deferred evaluation**. Instead of computing the sum directly, the verifier engages in a multi-round dialogue with the prover. In each round, the prover makes a smaller, more specific claim, and the verifier uses randomness to drill down on a single point. An initial lie, no matter how cleverly constructed, gets amplified at each step until it becomes a simple falsehood about a single evaluation, which the verifier catches at the end.



## The Compression Game

Think of the sum-check protocol as a game of progressive compression, or better yet, as a police interrogation.

The suspect (prover) claims to have an alibi for every minute of a 24-hour day ($2^\nu$ moments). The detective (verifier) cannot review surveillance footage for the entire day. Instead, the detective asks for a summary: "Tell me the sum of your activities."

The suspect provides a summary polynomial.

The detective picks one random second ($r_1$) and asks: "Explain this specific moment in detail." To answer, the suspect must provide a new summary for that specific timeframe. If the suspect lied about the total day, they must now lie about that specific second to make the math add up. The detective drills down again: "Okay, explain this millisecond."

The lie has to move. It has to hide in smaller and smaller gaps. Eventually, the detective asks about a single instant that can be fact-checked directly. If the suspect's story at that final instant doesn't match the evidence, the whole alibi crumbles.

More precisely: the prover holds an enormous object, a table of $2^\nu$ values. The verifier wants to know their sum but cannot afford to examine the table. In round 1, the prover compresses the table into a univariate polynomial. The verifier probes it at a random point $r_1$, and that answer becomes the new target: a compressed representation of a table half the size.

Each round, the table shrinks by half while the verifier accumulates random coordinates. After $\nu$ rounds, the "table" has size 1: a single value. The verifier can compute that value herself.

**Honest compression is consistent, but lies leave fingerprints.** If the prover's initial polynomial doesn't represent the true sum, it must differ from the honest polynomial somewhere. The random probes find these differences with overwhelming probability. A cheating prover would need to predict all $\nu$ random challenges in advance; against cryptographic randomness, that's impossible.



## The Protocol Specification

Let's make this precise. The sum-check protocol verifies a claim of the form:

$$H = \sum_{(b_1, \ldots, b_\nu) \in \{0,1\}^\nu} g(b_1, \ldots, b_\nu)$$

where $g$ is a $\nu$-variate polynomial of degree at most $d$ in each variable. The protocol proceeds in $\nu$ rounds.

### Round 1

The prover computes and sends a univariate polynomial $g_1(X_1)$, claimed to equal:

$$g_1(X_1) = \sum_{(b_2, \ldots, b_\nu) \in \{0,1\}^{\nu-1}} g(X_1, b_2, \ldots, b_\nu)$$

In words: $g_1$ is the polynomial obtained by summing $g$ over all boolean values of the last $\nu-1$ variables, leaving $X_1$ as a formal variable.

The verifier performs two checks:

1. **Consistency check**: Verify that $g_1(0) + g_1(1) = H$. This ensures the prover's polynomial is consistent with the claimed total sum.

2. **Degree check**: Verify that $g_1$ has degree at most $d$ in $X_1$. This is essential for soundness; without it, the protocol breaks completely. (We'll see why shortly.)

If either check fails, the verifier rejects. Otherwise, she samples a random field element $r_1 \leftarrow \mathbb{F}$ and sends it to the prover.

**The implicit claim**: The verifier now evaluates the prover's polynomial at this random point, computing $V_1 = g_1(r_1)$. This value represents what the prover is *implicitly* asserting about a reduced sum. The verifier doesn't compute this sum herself; she simply records what the prover's polynomial claims it to be. This $V_1$ becomes the target for round 2: the prover must now justify that the sum over $2^{\nu-1}$ points, with the first variable fixed to $r_1$, actually equals $V_1$.

The key observation: the verifier has now *reduced* the original claim about a sum over $2^\nu$ points to a new claim about a sum over $2^{\nu-1}$ points. Specifically, the prover is now implicitly claiming that:

$$g_1(r_1) = \sum_{(b_2, \ldots, b_\nu) \in \{0,1\}^{\nu-1}} g(r_1, b_2, \ldots, b_\nu)$$

**Why the degree check matters**: The soundness argument relies on Schwartz-Zippel: two *distinct* degree-$d$ polynomials agree on at most $d$ points, so a random evaluation catches the difference with probability $\geq 1 - d/|\mathbb{F}|$. But what if the prover sends a high-degree polynomial instead?

*Attack without degree check*: Suppose the true sum is $H^* = 6$ but the prover claims $H = 100$. The honest polynomial is $s_1(X) = 2X + 2$, with $s_1(0) + s_1(1) = 6$. The prover needs a polynomial passing through $(0, a)$ and $(1, b)$ where $a + b = 100$.

Without a degree bound, the prover is a wizard. He can conjure a polynomial that passes through the lie at $x = 0$ and $x = 1$, yet looks exactly like the honest polynomial everywhere else. A degree-$(|\mathbb{F}| - 1)$ polynomial can match $s_1$ at every point except 0 and 1, making it indistinguishable from the honest polynomial at any random challenge $r_1 \notin \{0, 1\}$.

The degree bound is the handcuffs. It forces the polynomial to be *stiff*. If it must pass through the wrong sum, its stiffness forces it to miss the honest polynomial almost everywhere else. Specifically: if the prover must send a degree-$d$ polynomial, Lagrange interpolation on $d+1$ points fully determines it. The prover cannot simultaneously satisfy $g_1(0) + g_1(1) = H$ and have $g_1$ agree with $s_1$ at more than $d$ points (unless $g_1 = s_1$, which requires $H = H^*$).

### Round $j$ (for $j = 2, \ldots, \nu$)

At the start of round $j$, the verifier holds a value $V_{j-1} = g_{j-1}(r_{j-1})$ from the previous round. This represents the prover's implicit claim about a sum over $2^{\nu-j+1}$ points.

The prover sends the next univariate polynomial $g_j(X_j)$, claimed to equal:

$$g_j(X_j) = \sum_{(b_{j+1}, \ldots, b_\nu) \in \{0,1\}^{\nu-j}} g(r_1, \ldots, r_{j-1}, X_j, b_{j+1}, \ldots, b_\nu)$$

The verifier checks:

1. **Consistency check**: $g_j(0) + g_j(1) = V_{j-1}$

2. **Degree check**: $\deg(g_j) \leq d$

If checks pass, she samples $r_j \leftarrow \mathbb{F}$ and computes $V_j = g_j(r_j)$.

### Final Check (After Round $\nu$)

After $\nu$ rounds, the verifier has received $g_\nu(X_\nu)$ and chosen $r_\nu$. The prover's final claim is that $g_\nu(r_\nu) = g(r_1, \ldots, r_\nu)$.

The verifier now evaluates $g$ at the single point $(r_1, \ldots, r_\nu)$, using her "oracle access" to $g$, and checks whether this equals $g_\nu(r_\nu)$.

If the values match, she accepts. Otherwise, she rejects.

### A Note on Oracle Access

In complexity theory, we say the verifier has "oracle access" to $g$. In practical SNARKs, this simply means the verifier knows the formula for $g$.

For example, if $g$ encodes a multiplication gate, the verifier knows that $g(a, b) = a \cdot b$. She doesn't need a magical black box; she just plugs the random values $r_1, \ldots, r_\nu$ into that equation at the end of the protocol. The "magic" is that she does this only once, at a single point, regardless of how many variables are in the sum or how large the hypercube is.



## Why Does This Work?

### Completeness

If the prover is honest, all checks pass trivially. The polynomials $g_j$ are computed exactly as specified, so the consistency checks hold by construction. The verifier accepts.

### Soundness

The soundness argument is more subtle and relies on the **polynomial rigidity** we developed in Chapter 2.

Suppose the prover's initial claim is false: the true sum is $H^* \neq H$. For the first consistency check to pass, the prover must send some polynomial $g_1(X_1)$ such that $g_1(0) + g_1(1) = H$.

Let $s_1(X_1)$ be the *true* polynomial: the one computed by honestly summing $g$ over the hypercube. By assumption, $s_1(0) + s_1(1) = H^* \neq H$. So the prover's polynomial $g_1$ must be different from $s_1$.

This is exactly where rigidity traps the cheater. The prover wants to send a polynomial that passes through the lie ($H$) but behaves like the truth ($H^*$) everywhere else. Rigidity makes this impossible. The polynomial is too stiff: if $g_1 \neq s_1$, they can agree on at most $d$ points.

By the Schwartz-Zippel lemma, when the verifier samples a random $r_1$ from $\mathbb{F}$, the probability that $g_1(r_1) = s_1(r_1)$ is at most $d/|\mathbb{F}|$.

With overwhelming probability, $g_1(r_1) \neq s_1(r_1)$. The prover has "gotten lucky" only if the random challenge happened to land on one of the few points where the two polynomials agree.

But what does $g_1(r_1) \neq s_1(r_1)$ mean? It means the prover is now committed to defending a *false* claim in round 2: he must convince the verifier that the sum $\sum_{b_2, \ldots} g(r_1, b_2, \ldots)$ equals $g_1(r_1)$, when in fact it equals $s_1(r_1)$.

The same logic cascades through all $\nu$ rounds. In each round, either the prover gets lucky (probability $\leq d/|\mathbb{F}|$) or he's forced to defend a new false claim. By the final round, the prover must convince the verifier that $g_\nu(r_\nu) = g(r_1, \ldots, r_\nu)$, but the verifier checks this directly.

By a union bound, the total probability that a cheating prover succeeds is at most:

$$\delta_s \leq \frac{\nu \cdot d}{|\mathbb{F}|}$$

In cryptographic applications, $|\mathbb{F}|$ is enormous (e.g., $2^{256}$), so this probability is negligible.



## Worked Example: Honest Prover and Cheating Prover

Let's trace through the entire protocol with actual values: first with an honest prover, then with a cheater. Seeing both cases with the same polynomial makes the soundness argument concrete.

**Setup**: Consider the polynomial $g(x_1, x_2) = x_1 + 2x_2$ over a large field $\mathbb{F}$. We have $\nu = 2$ variables.

**Goal**: The prover wants to convince the verifier of the sum over $\{0,1\}^2$:

$$H = g(0,0) + g(0,1) + g(1,0) + g(1,1) = 0 + 2 + 1 + 3 = 6$$

### The Honest Case

**Round 1**: The prover claims $H = 6$ and sends:

$$g_1(X_1) = g(X_1, 0) + g(X_1, 1) = (X_1 + 0) + (X_1 + 2) = 2X_1 + 2$$

The verifier checks: $g_1(0) + g_1(1) = 2 + 4 = 6 = H$. $\checkmark$

She samples $r_1 = 5$ and computes $V_1 = g_1(5) = 12$.

**Round 2**: The prover sends $g_2(X_2) = g(5, X_2) = 5 + 2X_2$.

The verifier checks: $g_2(0) + g_2(1) = 5 + 7 = 12 = V_1$. $\checkmark$

She samples $r_2 = 10$.

**Final check**: The verifier computes $g(5, 10) = 5 + 20 = 25$ and compares to $g_2(10) = 25$. They match. **Accept.**

### The Cheating Case

Now suppose the prover lies: he claims $H = 7$ instead of the true sum $H^* = 6$.

**Round 1**: To pass the consistency check, the prover must send some $g_1(X_1)$ with $g_1(0) + g_1(1) = 7$. The true polynomial $s_1(X_1) = 2X_1 + 2$ sums to 6, so he can't use it.

He sends a lie: $g_1(X_1) = 2X_1 + 2.5$. Check: $g_1(0) + g_1(1) = 2.5 + 4.5 = 7$. $\checkmark$

**The critical moment**: The verifier samples $r_1 = 5$.

- Prover's value: $g_1(5) = 12.5$
- True value: $s_1(5) = 12$

The prover is now committed to defending a false claim: $\sum_{x_2} g(5, x_2) = 12.5$. But the true sum is 12.

**Round 2**: The prover needs $g_2(0) + g_2(1) = 12.5$. He sends $g_2(X_2) = 5.25 + 2X_2$.

The verifier samples $r_2 = 10$.

**Final check**:

- Prover claims: $g_2(10) = 25.25$
- Verifier computes: $g(5, 10) = 25$

$25.25 \neq 25$. **Reject.**

### The Moral

The initial lie forced the prover to send polynomials different from the true ones. By Schwartz-Zippel, the random challenges almost certainly landed on points where these polynomials disagreed. The lie didn't just persist; it *amplified* through the rounds until it became a simple, detectable falsehood.

Notice what happened to the cheating prover. After sending the first dishonest polynomial, they weren't free. The verifier's random challenge $r_1 = 5$ created a new constraint: the prover must now justify that $\sum_{x_2} g(5, x_2) = 12.5$. But they didn't choose 5; the verifier did, unpredictably. The prover is forced to fabricate an answer for a question they couldn't anticipate.

Each round tightens the trap. The second lie must be consistent with the first. The third with the second. Each fabrication constrains the next, and the prover never controls which constraints they'll face. By the final round, the accumulated lies have painted the cheater into a corner: they must claim that $g(5, 10) = 25.25$ when any honest evaluation reveals 25. The system of fabrications collapses under its own weight.

The prover's only hope is that every random challenge happens to land on a point where the cheating polynomial agrees with the true one. For degree-$d$ polynomials over a field of size $|\mathbb{F}|$, this probability is at most $d/|\mathbb{F}|$ per round, negligible in cryptographic settings.



## Application: Counting Satisfying Assignments (#SAT)

The sum-check protocol becomes truly powerful when combined with **arithmetization**: the process of translating discrete, combinatorial problems into the language of polynomials over finite fields. We touched on #SAT in Chapter 2 as motivation for why polynomials matter in complexity theory. Now we see exactly how the translation works and why it enables efficient verification. The full theory of arithmetization will occupy later chapters; for now, we need just enough to see sum-check in action.

**The #SAT problem**: Given a boolean formula $\phi$ with $\nu$ variables, count how many of the $2^\nu$ possible assignments make $\phi$ true.

This is a canonical #P-complete problem, even harder than NP. Verifying the count naively requires checking all $2^\nu$ assignments. But with sum-check, a prover can convince a verifier of the correct count in polynomial time.

### Arithmetization of Boolean Formulas

The key insight is to transform the boolean formula into a polynomial that equals 1 on satisfying assignments and 0 otherwise.

**Step 1: Arithmetize literals**

- The variable $x_i$ stays as $x_i$

- The negation $\neg x_i$ becomes $1 - x_i$

Over $\{0,1\}$, these give the right values: if $x_i = 1$, then $\neg x_i = 0$, and $1 - x_i = 0$. $\checkmark$

**Step 2: Arithmetize clauses**
Consider a clause $C = (z_1 \lor z_2 \lor z_3)$ where each $z_i$ is a literal. The clause is false only when all three literals are false. So:

$$g_C(x) = 1 - (1 - z_1)(1 - z_2)(1 - z_3)$$

where each $z_i$ is the polynomial form of the literal.

**Example**: For the clause $C = (x_1 \lor \neg x_2 \lor x_3)$:
$$g_C(x_1, x_2, x_3) = 1 - (1 - x_1) \cdot x_2 \cdot (1 - x_3)$$

This equals 0 precisely when $x_1 = 0$, $x_2 = 1$, $x_3 = 0$: the only assignment that falsifies the clause.

**Step 3: Arithmetize the full formula**
For a CNF formula $\phi = C_1 \land C_2 \land \cdots \land C_m$, the formula is satisfied when *all* clauses are satisfied:

$$g_\phi(x_1, \ldots, x_\nu) = \prod_{j=1}^m g_{C_j}(x_1, \ldots, x_\nu)$$

Over $\{0,1\}^\nu$, this product equals 1 if all clauses are satisfied and 0 otherwise.

### The Protocol

The number of satisfying assignments is:

$$\text{\#}SAT(\phi) = \sum_{(b_1, \ldots, b_\nu) \in \{0,1\}^\nu} g_\phi(b_1, \ldots, b_\nu)$$

This is exactly a sum over the boolean hypercube! The prover can use the sum-check protocol to convince the verifier of this count.

**Degree analysis**: For a 3-CNF formula, each clause polynomial has degree at most 3. With $m$ clauses, the product $g_\phi$ has total degree at most $3m$. The degree in any single variable is at most $3m$ as well (though often much smaller due to variable sharing).

**Verifier's work**: The verifier performs $\nu$ rounds of sum-check, checking polynomials of degree at most $3m$. The final check requires evaluating $g_\phi$ at a random point; this takes $O(m)$ time since $g_\phi$ is a product of $m$ clause polynomials.

Total verifier time: $O(\nu \cdot m)$, polynomial in the formula size, despite the exponentially large space of assignments.

### Worked Example: A Tiny #SAT Instance

Consider the formula $\phi = (x_1 \lor x_2) \land (\neg x_1 \lor x_2)$ with $\nu = 2$ variables and $m = 2$ clauses.

**Step 1: Arithmetize.**

Clause 1: $(x_1 \lor x_2) \to 1 - (1-x_1)(1-x_2) = x_1 + x_2 - x_1 x_2$

Clause 2: $(\neg x_1 \lor x_2) \to 1 - x_1(1-x_2) = 1 - x_1 + x_1 x_2$

Full formula: $g_\phi(x_1, x_2) = (x_1 + x_2 - x_1 x_2)(1 - x_1 + x_1 x_2)$

**Step 2: Evaluate on $\{0,1\}^2$.**

| $(x_1, x_2)$ | Clause 1 | Clause 2 | $g_\phi$ | $\phi$ satisfied? |
|--------------|----------|----------|----------|-------------------|
| $(0, 0)$ | $0$ | $1$ | $0$ | No |
| $(0, 1)$ | $1$ | $1$ | $1$ | Yes |
| $(1, 0)$ | $1$ | $0$ | $0$ | No |
| $(1, 1)$ | $1$ | $1$ | $1$ | Yes |

**Step 3: Count.**

$$\#SAT(\phi) = \sum_{(b_1, b_2) \in \{0,1\}^2} g_\phi(b_1, b_2) = 0 + 1 + 0 + 1 = 2$$

The formula has exactly 2 satisfying assignments: $(0,1)$ and $(1,1)$ (both require $x_2 = 1$).

The prover uses sum-check to convince the verifier of this count. The polynomial $g_\phi$ has degree 2 in each variable (degree 4 total), so each round polynomial has degree at most 2, requiring 3 field elements per round.



## The Magic of Deferred Evaluation

The sum-check protocol embodies a profound principle: **you don't need to compute a sum to verify it**.

Consider what the verifier actually does:

1. She receives polynomials $g_1, g_2, \ldots, g_\nu$ from the prover.

2. She checks consistency: does $g_j(0) + g_j(1)$ equal the previous round's value?

3. She checks degree bounds.

4. At the very end, she evaluates $g$ at a single random point.

The verifier never computes any intermediate sums. She never evaluates $g$ at any point of the boolean hypercube. All the hard work, computing the actual sums, is done by the prover. The verifier merely checks that the prover's story is internally consistent.

This is claim reduction in action. Each round, the claim shrinks:

- Round 0: "The sum over $2^\nu$ points is $H$"

- Round 1: "The sum over $2^{\nu-1}$ points (at a random slice) is $V_1$"

- Round 2: "The sum over $2^{\nu-2}$ points is $V_2$"

- ...

- Round $\nu$: "The value at one specific point is $V_\nu$"

By the end, we've reduced an exponential claim to a trivial one. And the random challenges ensure that any cheating at an earlier stage propagates into a detectable error at the final stage.



## Complexity Analysis

Let's be precise about the efficiency gains.

**Prover complexity**: In round $j$, the prover must compute a univariate polynomial of degree at most $d$. To specify this polynomial, the prover evaluates it at $d+1$ points (say, $0, 1, 2, \ldots, d$). For each such point $\alpha$, the prover computes:

$$g_j(\alpha) = \sum_{(b_{j+1}, \ldots, b_\nu) \in \{0,1\}^{\nu-j}} g(r_1, \ldots, r_{j-1}, \alpha, b_{j+1}, \ldots, b_\nu)$$

This requires summing over $2^{\nu-j}$ terms. Across all rounds, the prover's total work is:

$$O\left(\sum_{j=1}^{\nu} (d+1) \cdot 2^{\nu-j}\right) = O(d \cdot 2^\nu)$$

The prover does work proportional to the size of the hypercube, but crucially, this is what the prover would need to do anyway to compute the sum. The sum-check protocol doesn't add significant overhead to the prover.

**Verifier complexity**: In each round, the verifier:

- Receives a degree-$d$ polynomial (specified by $d+1$ coefficients)

- Checks that $g_j(0) + g_j(1)$ equals the previous value

- Samples a random field element

- Evaluates $g_j$ at the random point

This is $O(d)$ work per round, or $O(\nu d)$ total.

At the end, the verifier evaluates $g$ at a single point $(r_1, \ldots, r_\nu)$. Let $T$ be the time to evaluate $g$ at one point. The verifier's total work is:

$$O(\nu d + T)$$

**The speedup**: The verifier avoids evaluating $g$ at $2^\nu$ points, an exponential savings. If $g$ arises from a "structured" computation (like a circuit or formula), then $T$ is polynomial in the description of that structure, making the whole protocol efficient.

**Communication complexity**: The prover sends $\nu$ univariate polynomials, each of degree at most $d$. Naively, this requires $d+1$ field elements per polynomial (to specify the coefficients), for a total of $\nu(d+1)$ field elements. But there's a trick.

**The one-coefficient trick**: At each round, the verifier checks $s_i(0) + s_i(1) = V_{i-1}$. This is one linear equation in the polynomial's coefficients, so the polynomial has only $d$ degrees of freedom, not $d+1$.

Write $s_i(X) = c_0 + c_1 X + c_2 X^2 + \cdots + c_d X^d$. Then:
$$s_i(0) + s_i(1) = c_0 + (c_0 + c_1 + c_2 + \cdots + c_d) = 2c_0 + c_1 + c_2 + \cdots + c_d = V_{i-1}$$

So: $c_1 = V_{i-1} - 2c_0 - c_2 - c_3 - \cdots - c_d$.

The prover sends only $(c_0, c_2, c_3, \ldots, c_d)$, and the verifier recovers $c_1$ from the constraint. This saves one field element per round: $\nu d$ field elements total instead of $\nu(d+1)$.

For the common case of multilinear polynomials ($d = 1$), this halves communication: one field element per round instead of two.

**Soundness error**: As computed earlier, the probability that a cheating prover succeeds is at most $\nu d / |\mathbb{F}|$. For a 256-bit field and reasonable values of $\nu$ and $d$, this is negligible.



## Why Sum-Check Enables Everything Else

The sum-check protocol is not just one protocol among many; it's the foundation upon which much of modern verifiable computation is built.

**Interactive proofs**: The celebrated IP = PSPACE theorem, which shows that every problem solvable in polynomial space has an efficient interactive proof, uses sum-check as its core building block. The LFKN protocol arithmetizes quantified boolean formulas and applies sum-check recursively.

**The GKR protocol**: To verify that an arithmetic circuit was evaluated correctly, the GKR protocol (Chapter 7) expresses the relationship between adjacent circuit layers as a sum over a hypercube. Sum-check reduces a claim about one layer to a claim about the next, peeling back the circuit layer by layer until we reach the inputs.

**Modern SNARKs**: Many of today's practical succinct arguments (Spartan, HyperPlonk, and the entire family of "sum-check based" SNARKs) use sum-check as their information-theoretic core. The protocol's structure, where a prover commits to polynomials and a verifier checks random evaluations, maps cleanly onto polynomial commitment schemes.

**The multilinear paradigm**: As we'll see in the next chapter, multilinear polynomials (those with degree at most 1 in each variable) have a natural correspondence with functions on the boolean hypercube. The sum-check protocol works especially elegantly with multilinear polynomials, and this paradigm has become one of the two major approaches to building modern proof systems.

**The sum-check renaissance**: For years after the initial theoretical breakthroughs, practical SNARK systems moved away from sum-check toward other approaches (PCPs, linear PCPs, univariate techniques). But recently, sum-check has made a dramatic comeback. Systems like Lasso and Jolt use sum-check at their core, achieving remarkable prover efficiency. Why the return? It turns out that sum-check provers can run in *linear time* for structured polynomials, and the protocol meshes beautifully with modern polynomial commitment schemes. We'll explore this renaissance in depth in Chapter 19.

The sum-check protocol is where the abstract power of polynomials (their rigidity, their compression of constraints, their amenability to random testing) first crystallizes into a concrete verification procedure. Every protocol we study from here forward either uses sum-check directly or is in dialogue with the principles it established.



## Key Takeaways

1. **The sum-check protocol verifies exponential sums efficiently**: A prover can convince a verifier that $\sum_{b \in \{0,1\}^\nu} g(b) = H$ with the verifier doing only $O(\nu)$ work, plus one evaluation of $g$. The verifier never computes any sum herself.

2. **Claim reduction is the key mechanism**: Each round reduces a claim about $2^k$ points to a claim about $2^{k-1}$ points. After $\nu$ rounds, the exponential sum becomes a single evaluation.

3. **Lies propagate and amplify**: A false initial claim forces the prover to send dishonest polynomials. Random challenges catch the discrepancy with probability $1 - d/|\mathbb{F}|$ per round. The lie can't hide; it gets cornered.

4. **The degree bound is essential**: Without it, a cheating prover could craft high-degree polynomials that pass consistency checks at 0 and 1 while matching the honest polynomial elsewhere. The degree bound forces rigidity.

5. **Arithmetization connects sum-check to computation**: Problems like #SAT encode as sums over the boolean hypercube. The prover does $O(2^\nu)$ work; the verifier does $O(\nu)$. This asymmetry is what makes verification useful.

6. **Sum-check is foundational**: IP = PSPACE, GKR, Spartan, Lasso, and most multilinear SNARKs build on sum-check. The protocol's comeback in practical systems (Chapter 19) shows it wasn't just theoretically elegant but practically powerful.


\newpage

# Chapter 4: Multilinear Extensions

In 1971, the Mariner 9 probe became the first spacecraft to orbit another planet. Its mission: map the surface of Mars. But transmitting high-resolution images across 100 million miles of static-filled space was a nightmare. A single burst of cosmic noise could turn a crater into a glitch.

NASA didn't send raw pixels. They used a code developed years earlier by Irving Reed and David Muller: treat the pixel data as evaluations of a *multivariate polynomial*. The Reed-Muller code could correct up to seven bit errors per 32-bit word. When Mariner 9 arrived to find Mars engulfed in a planet-wide dust storm, mission control reprogrammed the spacecraft from Earth and waited. When the dust cleared, the code delivered 7,329 images, mapping 85% of the Martian surface.

Why not Reed-Solomon? In Chapter 2, we encoded $n$ values as a univariate polynomial of degree $n-1$. That works when $n$ is modest. But Mariner's data was indexed by *bit positions*: a 32-bit word has $2^5$ bit combinations, a memory address space has $2^{64}$ locations, a boolean formula with 100 variables has $2^{100}$ possible assignments. Encoding $2^{100}$ values as a univariate polynomial means degree $2^{100} - 1$. Impossible.

The solution: let each bit be its own variable. A 100-bit index becomes 100 coordinates, each 0 or 1. The polynomial has 100 variables instead of degree $2^{100}$. Data lives not on a line but on a hypercube. This chapter develops that theory.

---

In Chapter 2, we turned data into polynomials via Lagrange interpolation: given $n$ values, construct the unique degree-$(n-1)$ univariate polynomial passing through them. That was interpolation over a *line*.

Now we need interpolation over a *hypercube*. The data lives at $2^n$ vertices, indexed by bit strings. The polynomial must agree with the data at these vertices and extend smoothly to all of $\mathbb{F}^n$. The construction is analogous to univariate Lagrange, but the geometry is different, and the efficiency implications are dramatic.

This chapter develops the theory of **multilinear extensions**: the canonical way to extend functions from the Boolean hypercube $\{0,1\}^n$ to polynomials over $\mathbb{F}^n$. These extensions are the workhorses of sum-check-based proof systems, encoding everything from circuit wire values to constraint satisfaction.



## The Boolean Hypercube

Consider the set $\{0,1\}^n$, all $n$-bit binary strings. This is the **Boolean hypercube**, and it contains exactly $2^n$ points.

```
n = 2:
    (1,1)
     /  \
 (0,1)  (1,0)
     \  /
    (0,0)

n = 3: A cube with 8 vertices
```

Any function $f: \{0,1\}^n \to \mathbb{F}$ assigns a field element to each vertex of this hypercube. There are $2^n$ vertices, so $f$ is essentially a table of $2^n$ values.

**Examples**:

- A vector $(v_1, \ldots, v_{2^n})$ can be viewed as $f(b) = v_{1 + \text{bin}(b)}$ where $\text{bin}(b)$ converts the bit string to an index

- The output values of a layer of circuit gates

- A database of $2^n$ records indexed by $n$-bit keys

The hypercube is our *discrete* domain. We want a polynomial that agrees with $f$ on this domain but is defined everywhere.



## Why Multilinear?

In Chapter 2, we used univariate polynomials (Reed-Solomon). Why switch to multivariate now?

**The degree problem.** If you encode $N = 2^{20}$ data points into a single-variable polynomial $p(x)$, that polynomial has degree about one million. Manipulating degree-million polynomials is expensive, requiring heavy FFT operations.

**The multilinear solution.** If you encode the same $2^{20}$ points into a 20-variable multilinear polynomial, the degree in each variable is just 1. The total degree is only 20. By increasing the number of variables, we drastically lower the per-variable degree. This tradeoff (more variables, lower degree) enables the linear-time prover algorithms that power modern systems like HyperPlonk and Lasso, avoiding the expensive FFTs required by univariate approaches.

A polynomial in $n$ variables has terms like $X_1^{a_1} X_2^{a_2} \cdots X_n^{a_n}$ with various exponents. The **degree** in variable $X_i$ is the maximum exponent of $X_i$ across all terms.

A polynomial is **multilinear** if its degree in every variable is at most 1. Every term looks like a product of distinct variables (or subsets thereof):

$$\tilde{f}(X_1, \ldots, X_n) = \sum_{S \subseteq \{1,\ldots,n\}} c_S \prod_{i \in S} X_i$$

For example, with $n = 2$:
$$\tilde{f}(X_1, X_2) = c_\emptyset + c_{\{1\}} X_1 + c_{\{2\}} X_2 + c_{\{1,2\}} X_1 X_2$$

There are $2^n$ possible subsets $S$, hence $2^n$ coefficients. A multilinear polynomial in $n$ variables is fully specified by $2^n$ numbers, exactly matching the number of points in the hypercube.

This is not a coincidence. It's the key theorem:

**Theorem (Multilinear Extension).** For any function $f: \{0,1\}^n \to \mathbb{F}$, there exists a unique multilinear polynomial $\tilde{f}: \mathbb{F}^n \to \mathbb{F}$ such that $\tilde{f}(b) = f(b)$ for all $b \in \{0,1\}^n$.

The function $\tilde{f}$ is called the **multilinear extension (MLE)** of $f$.



## Constructing the Multilinear Extension

The theorem claims uniqueness. How do we actually construct $\tilde{f}$?

### The Lagrange Basis

For each point $w \in \{0,1\}^n$, define the **Lagrange basis polynomial**:

$$L_w(X) = \prod_{i=1}^{n} \left( w_i \cdot X_i + (1 - w_i)(1 - X_i) \right)$$

This polynomial has a beautiful property: it equals 1 at $w$ and 0 at every other hypercube point.

**Why?** At point $w$:

- If $w_i = 1$: the factor is $1 \cdot X_i + 0 \cdot (1 - X_i) = X_i$, which evaluates to $1$

- If $w_i = 0$: the factor is $0 \cdot X_i + 1 \cdot (1 - X_i) = 1 - X_i$, which evaluates to $1$

Every factor equals 1, so $L_w(w) = 1$.

At any other point $b \neq w$:

- There exists some coordinate $i$ where $b_i \neq w_i$

- If $w_i = 1$ and $b_i = 0$: the factor $X_i$ evaluates to $0$

- If $w_i = 0$ and $b_i = 1$: the factor $1 - X_i$ evaluates to $0$

One factor is zero, so $L_w(b) = 0$.

### The Extension Formula

The multilinear extension is now simply:

$$\tilde{f}(X) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(X)$$

At any hypercube point $b$:
$$\tilde{f}(b) = \sum_w f(w) \cdot L_w(b) = f(b) \cdot 1 + \sum_{w \neq b} f(w) \cdot 0 = f(b)$$

The extension agrees with $f$ on the hypercube. Since it's a sum of multilinear terms (each $L_w$ is multilinear), $\tilde{f}$ is multilinear.

### Uniqueness

If two multilinear polynomials agree on $\{0,1\}^n$, their difference is a multilinear polynomial that vanishes on all $2^n$ hypercube points. But a nonzero multilinear polynomial in $n$ variables has degree 1 in each variable; by Schwartz-Zippel, it can vanish on at most $1/|\mathbb{F}|$ fraction of points per variable. Over the hypercube, this means it can vanish on at most half the points in each direction, unless it's identically zero.

More directly: there are $2^n$ coefficients in a multilinear polynomial, and $2^n$ constraints (values at hypercube points). The system is determined. The unique solution is the MLE.



## The Equality Polynomial

One Lagrange basis polynomial deserves special attention: the **equality polynomial**.

$$\widetilde{\text{eq}}(X, Y) = \prod_{i=1}^{n} \left( X_i Y_i + (1 - X_i)(1 - Y_i) \right)$$

This is the MLE of the equality function:
$$\text{eq}(a, b) = \begin{cases} 1 & \text{if } a = b \\ 0 & \text{otherwise} \end{cases}$$

for $a, b \in \{0,1\}^n$.

The Lagrange basis polynomials are just the equality polynomial with one input fixed:
$$L_w(X) = \widetilde{\text{eq}}(w, X)$$

**Why does this matter?** The equality polynomial appears constantly in sum-check-based protocols. Here's the key use case: suppose you want to "select" a specific hypercube point $w \in \{0,1\}^n$ from a sum. The verifier sends a random challenge $r \in \mathbb{F}^n$, and you evaluate $\widetilde{\text{eq}}(r, w)$. On the hypercube, this function equals 1 at $w$ and 0 everywhere else. But at a random $r$, it gives a *weighted* selection: $\widetilde{\text{eq}}(r, w)$ is large when $r$ is "close" to $w$ (in a polynomial sense) and negligibly small otherwise. This lets the verifier probe specific hypercube points through random field elements.



## Worked Example: A 2-Variable Function

Let's trace through a complete example.

**The function**: $f: \{0,1\}^2 \to \mathbb{F}$ defined by the table:

| $(X_1, X_2)$ | $f(X_1, X_2)$ |
|--------------|---------------|
| $(0, 0)$     | $3$           |
| $(0, 1)$     | $7$           |
| $(1, 0)$     | $2$           |
| $(1, 1)$     | $5$           |

**The Lagrange basis polynomials**:

$$L_{(0,0)}(X) = (1 - X_1)(1 - X_2)$$
$$L_{(0,1)}(X) = (1 - X_1) \cdot X_2$$
$$L_{(1,0)}(X) = X_1 \cdot (1 - X_2)$$
$$L_{(1,1)}(X) = X_1 \cdot X_2$$

**The multilinear extension**:

$$\tilde{f}(X_1, X_2) = 3 \cdot (1-X_1)(1-X_2) + 7 \cdot (1-X_1)X_2 + 2 \cdot X_1(1-X_2) + 5 \cdot X_1 X_2$$

Expanding:

$$= 3(1 - X_1 - X_2 + X_1 X_2) + 7(X_2 - X_1 X_2) + 2(X_1 - X_1 X_2) + 5 X_1 X_2$$
$$= 3 - 3X_1 - 3X_2 + 3X_1X_2 + 7X_2 - 7X_1X_2 + 2X_1 - 2X_1X_2 + 5X_1X_2$$
$$= 3 + (-3 + 2)X_1 + (-3 + 7)X_2 + (3 - 7 - 2 + 5)X_1X_2$$
$$= 3 - X_1 + 4X_2 - X_1X_2$$

**Verification**: Check that this matches the table:

- $\tilde{f}(0,0) = 3 - 0 + 0 - 0 = 3$ (matches)

- $\tilde{f}(0,1) = 3 - 0 + 4 - 0 = 7$ (matches)

- $\tilde{f}(1,0) = 3 - 1 + 0 - 0 = 2$ (matches)

- $\tilde{f}(1,1) = 3 - 1 + 4 - 1 = 5$ (matches)

**Evaluation at a random point**: What is $\tilde{f}(0.5, 0.3)$?
$$\tilde{f}(0.5, 0.3) = 3 - 0.5 + 4(0.3) - (0.5)(0.3) = 3 - 0.5 + 1.2 - 0.15 = 3.55$$

This value has no "meaning" on the hypercube; $(0.5, 0.3)$ isn't a Boolean point. But this is exactly what we want: the polynomial is defined everywhere, and random evaluation is the key to probabilistic verification.



## Efficient Evaluation

Given the table of values $\{f(w) : w \in \{0,1\}^n\}$ and a query point $r \in \mathbb{F}^n$, how fast can we compute $\tilde{f}(r)$?

**Naive approach**: Sum over all $2^n$ terms:
$$\tilde{f}(r) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(r)$$

Each $L_w(r)$ takes $O(n)$ to compute. Total: $O(n \cdot 2^n)$.

**Better: Streaming evaluation**. We can compute $\tilde{f}(r)$ in $O(2^n)$ time with the following observation.

Define $T_k$ as the "partial extension" using only the first $k$ variables of $r$:

$$T_k(x_{k+1}, \ldots, x_n) = \sum_{(b_1, \ldots, b_k) \in \{0,1\}^k} f(b_1, \ldots, b_k, x_{k+1}, \ldots, x_n) \cdot \prod_{i=1}^{k} L_{b_i}(r_i)$$

At $k = 0$: $T_0 = f$ (the original table).

At $k = n$: $T_n = \tilde{f}(r)$ (a single value).

The recursion from $T_k$ to $T_{k+1}$:

$$T_{k+1}(x_{k+2}, \ldots, x_n) = (1 - r_{k+1}) \cdot T_k(0, x_{k+2}, \ldots) + r_{k+1} \cdot T_k(1, x_{k+2}, \ldots)$$

Each step halves the table size. Total work: $2^n + 2^{n-1} + \cdots + 1 = O(2^n)$.

This is linear in the table size, optimal for any algorithm that must touch all values.

### Worked Example: Streaming Evaluation

Let's trace through this algorithm with our earlier function $f: \{0,1\}^2 \to \mathbb{F}$:

| $(b_1, b_2)$ | $f(b_1, b_2)$ |
|--------------|---------------|
| $(0, 0)$     | $3$           |
| $(0, 1)$     | $7$           |
| $(1, 0)$     | $2$           |
| $(1, 1)$     | $5$           |

We want to compute $\tilde{f}(r_1, r_2)$ at the point $r = (0.4, 0.7)$.

**Step 0: Initialize $T_0$**

$T_0$ is just the original table, a function of both variables:
$$T_0(x_1, x_2) = f(x_1, x_2)$$

Think of it as four values indexed by $(x_1, x_2) \in \{0,1\}^2$:
$$T_0 = \begin{array}{c|cc} & x_2=0 & x_2=1 \\ x_1=0 & 3 & 7 \\ x_1=1 & 2 & 5 \end{array}$$

**Step 1: Compute $T_1$ by "folding in" $r_1 = 0.4$**

The recursion says:
$$T_1(x_2) = (1 - r_1) \cdot T_0(0, x_2) + r_1 \cdot T_0(1, x_2)$$

This is a weighted combination of the two rows, using $1 - r_1 = 0.6$ and $r_1 = 0.4$:

- $T_1(0) = 0.6 \cdot T_0(0,0) + 0.4 \cdot T_0(1,0) = 0.6 \cdot 3 + 0.4 \cdot 2 = 1.8 + 0.8 = 2.6$

- $T_1(1) = 0.6 \cdot T_0(0,1) + 0.4 \cdot T_0(1,1) = 0.6 \cdot 7 + 0.4 \cdot 5 = 4.2 + 2.0 = 6.2$

The table has shrunk from 4 values to 2 values: $T_1 = [2.6, 6.2]$.

**Step 2: Compute $T_2$ by "folding in" $r_2 = 0.7$**

$$T_2 = (1 - r_2) \cdot T_1(0) + r_2 \cdot T_1(1) = 0.3 \cdot 2.6 + 0.7 \cdot 6.2 = 0.78 + 4.34 = 5.12$$

The table has shrunk from 2 values to 1 value. This single value is $\tilde{f}(0.4, 0.7) = 5.12$.

**Verification**: Using the explicit formula $\tilde{f}(X_1, X_2) = 3 - X_1 + 4X_2 - X_1X_2$:
$$\tilde{f}(0.4, 0.7) = 3 - 0.4 + 4(0.7) - (0.4)(0.7) = 3 - 0.4 + 2.8 - 0.28 = 5.12 \checkmark$$

**Why does this work?** The Lagrange basis polynomial factorizes into independent pieces, one per coordinate:
$$L_{(b_1, b_2)}(r_1, r_2) = L_{b_1}(r_1) \cdot L_{b_2}(r_2)$$

where $L_0(r) = 1 - r$ and $L_1(r) = r$ are univariate selectors. This factorization holds because the multilinear Lagrange formula is a *product* over coordinates:

$$L_w(X) = \prod_{i=1}^{n} \left( w_i \cdot X_i + (1 - w_i)(1 - X_i) \right)$$

Each factor depends only on one coordinate of $w$ and one coordinate of $X$. So evaluating at $(r_1, r_2)$ gives a product of independent terms.

**How the algorithm exploits this**: The MLE evaluation is:
$$\tilde{f}(r_1, r_2) = \sum_{b_1, b_2 \in \{0,1\}} f(b_1, b_2) \cdot L_{b_1}(r_1) \cdot L_{b_2}(r_2)$$

Rearranging the sum (grouping by $b_2$):
$$= \sum_{b_2} L_{b_2}(r_2) \cdot \underbrace{\left( \sum_{b_1} f(b_1, b_2) \cdot L_{b_1}(r_1) \right)}_{T_1(b_2)}$$

The inner sum is exactly what Step 1 computes: for each value of $b_2$, it combines the two $b_1$ cases using weights $L_0(r_1) = 1 - r_1$ and $L_1(r_1) = r_1$. The result $T_1$ has half as many entries. Step 2 then folds in the $r_2$ weights similarly.

**The Tournament Bracket.** Think of a single-elimination tournament with $2^n$ players. In each round, pairs compete and half are eliminated. After $n$ rounds, one champion remains. The streaming algorithm works the same way: $2^n$ table entries enter, each round uses a random weight to combine pairs, and after $n$ rounds a single evaluation emerges. The tournament bracket is the structure of multilinear computation.

This pattern of using a random challenge to collapse pairs of values and halving the problem size will reappear throughout this book. In Chapter 10 (FRI), we'll name it **folding** and see it as one of the central techniques in zero-knowledge proofs.

### Code: Streaming MLE Evaluation

The algorithm above translates directly to code. Each coordinate of $r$ folds the table in half.

```python
def mle_eval(table, r):
    """
    Evaluate the multilinear extension of `table` at point `r`.

    Args:
        table: List of 2^n field elements (the function values on hypercube)
        r: Tuple of n coordinates (r_1, ..., r_n)

    Returns: The value of the MLE at r
    """
    T = table.copy()

    for r_i in r:
        half = len(T) // 2
        # Fold: T'[j] = (1 - r_i) * T[2j] + r_i * T[2j+1]
        T = [(1 - r_i) * T[2*j] + r_i * T[2*j + 1]
             for j in range(half)]

    return T[0]  # Single value remains

# Example from the worked example above
table = [3, 7, 2, 5]  # f(0,0)=3, f(0,1)=7, f(1,0)=2, f(1,1)=5
r = (0.4, 0.7)

result = mle_eval(table, r)
print(f"Streaming: MLE({r}) = {result}")

# Verify against explicit formula: f(X1,X2) = 3 - X1 + 4*X2 - X1*X2
explicit = 3 - 0.4 + 4*0.7 - 0.4*0.7
print(f"Explicit:  MLE({r}) = {explicit}")
```

Output:
```
Streaming: MLE((0.4, 0.7)) = 5.12
Explicit:  MLE((0.4, 0.7)) = 5.12
```

The streaming algorithm touches each table entry exactly once. For a table of size $N = 2^n$, total work is $N/2 + N/4 + \cdots + 1 = N - 1 = O(N)$.



## Tensor Product Structure

The factorization we used in the streaming algorithm generalizes to any number of variables. For $w = (w_1, \ldots, w_n) \in \{0,1\}^n$:

$$L_w(r_1, \ldots, r_n) = \prod_{i=1}^{n} L_{w_i}(r_i)$$

where $L_0(r_i) = 1 - r_i$ and $L_1(r_i) = r_i$.

This is a **tensor product** structure. To see what this means concretely, consider $n = 2$. Define the vectors:

$$\vec{v}_1 = (L_0(r_1), L_1(r_1)) = (1 - r_1, r_1)$$
$$\vec{v}_2 = (L_0(r_2), L_1(r_2)) = (1 - r_2, r_2)$$

Their tensor product $\vec{v}_1 \otimes \vec{v}_2$ is the $2 \times 2$ matrix (or equivalently, length-4 vector) of all pairwise products:

$$\vec{v}_1 \otimes \vec{v}_2 = \begin{pmatrix} (1-r_1)(1-r_2) & (1-r_1)r_2 \\ r_1(1-r_2) & r_1 r_2 \end{pmatrix}$$

Reading off the entries: $L_{(0,0)}(r), L_{(0,1)}(r), L_{(1,0)}(r), L_{(1,1)}(r)$. The tensor product *is* the vector of Lagrange evaluations.

For general $n$, the vector of all $2^n$ Lagrange evaluations is:

$$(L_0(r_1), L_1(r_1)) \otimes (L_0(r_2), L_1(r_2)) \otimes \cdots \otimes (L_0(r_n), L_1(r_n))$$

**Why this matters**: The streaming algorithm exploits tensor structure. Instead of computing all $2^n$ Lagrange values (expensive), it processes one coordinate at a time, folding the tensor product incrementally. This is why MLE evaluation costs $O(2^n)$ instead of $O(n \cdot 2^n)$. The same tensor structure enables:

- Efficient prover algorithms for sum-check (Chapter 19)

- Recursive proof constructions

- Memory-efficient streaming over large tables



## Multilinear Extensions of Functions on Larger Domains

What if our function isn't defined on $\{0,1\}^n$?

Suppose $f: \{0, 1, \ldots, m-1\} \to \mathbb{F}$ for some $m = 2^n$. We can *interpret* the domain as $\{0,1\}^n$ via binary encoding:

$$\tilde{f}(X_1, \ldots, X_n) = \text{MLE of } (k \mapsto f(k)) \text{ with } k = \sum_i 2^{i-1} X_i$$

Any function on a power-of-two domain has a natural multilinear extension.

For domains not of size $2^n$, we can pad with zeros or use more sophisticated encodings. The key insight: as long as the domain is *finite*, we can always encode it in binary and take the MLE.



## Connection to Sum-Check

The sum-check protocol (Chapter 3) proves claims of the form:

$$H = \sum_{b \in \{0,1\}^n} g(b)$$

for some polynomial $g$. When $g$ is the multilinear extension of a function, this sum is just... the sum of all function values.

**Example**: Prove that a vector $(v_1, \ldots, v_N)$ with $N = 2^n$ sums to a claimed value $H$.

Let $\tilde{v}$ be the MLE encoding the vector. Then:
$$\sum_{b \in \{0,1\}^n} \tilde{v}(b) = \sum_{i=1}^{N} v_i = H$$

Sum-check verifies this identity without the verifier seeing all of $v$. The protocol reduces the sum to a single random evaluation $\tilde{v}(r)$, which the prover supplies (with a commitment proof).

This is the bridge from "data" to "proof": encode data as an MLE, verify properties via sum-check, bind via polynomial commitment.



## The Golden Link: Evaluations = Coordinates

Here's a perspective that clarifies many constructions.

A multilinear polynomial $\tilde{f}$ has $2^n$ coefficients (the $c_S$ values in the monomial expansion $\sum_S c_S \prod_{i \in S} X_i$). These coefficients live in an abstract "coefficient space."

But $\tilde{f}$ also has $2^n$ evaluations on the hypercube. These evaluations are just $f(w)$, the original table values you started with.

These are not the same numbers. The table entry $f(0,0) = 3$ in our worked example is not a coefficient of the polynomial. The polynomial $\tilde{f}(X_1, X_2) = 3 - X_1 + 4X_2 - X_1X_2$ has coefficients $\{3, -1, 4, -1\}$, while the table values are $\{3, 7, 2, 5\}$. They're related by the Lagrange interpolation formula.

**The key insight**: For multilinear polynomials, the evaluation table *is* a complete description. You can recover coefficients from evaluations and vice versa. They're just two bases for the same $2^n$-dimensional vector space.

The transformation between bases is exactly the Lagrange interpolation formula and its inverse. Both can be computed in $O(2^n)$ time.

This means:

- Committing to a multilinear polynomial = committing to its evaluation table

- Evaluating at a random point = a linear combination of table entries

- Sum-check over an MLE = verifying global properties through local queries

The table has $2^n$ entries. The verifier touches $O(n)$ of them. The polynomial is what bridges the gap: it's a compressed representation that can be probed at random points, and those random probes reveal whether the full table satisfies the claimed property. Extension creates redundancy; redundancy enables compression; compression enables succinctness.

### Polynomial Evaluation as Inner Product

There's a beautiful way to see this algebraically: **polynomial evaluation is an inner product**.

For a multilinear polynomial, the evaluation at any point $r$ is:

$$\tilde{f}(r) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(r) = \langle \vec{f}, \vec{L}(r) \rangle$$

where $\vec{f} = (f(w))_{w \in \{0,1\}^n}$ is the table of values and $\vec{L}(r) = (L_w(r))_{w \in \{0,1\}^n}$ is the vector of Lagrange basis evaluations at $r$.

This linear algebra perspective is surprisingly powerful. For decades, sum-check was seen as a beautiful theoretical result with limited practical use. Then came the realization: polynomial evaluation is an inner product, and inner products interact beautifully with commitment schemes. No FFTs, no trusted setups, just vectors and dot products. Systems like Spartan, HyperPlonk, and Lasso all exploit this insight. Chapter 19 tells the full story of this "Sum-Check Renaissance."

The consequences are immediate:

- **Commitment**: Committing to $\tilde{f}$ means committing to the vector $\vec{f}$
- **Evaluation proof**: Proving $\tilde{f}(r) = y$ means proving an inner product claim $\langle \vec{f}, \vec{L}(r) \rangle = y$
- **The verifier knows $\vec{L}(r)$**: Given $r$, anyone can compute the Lagrange evaluations

This reduces polynomial evaluation proofs to inner product proofs, and inner products interact beautifully with homomorphic commitments. We'll exploit this connection in Chapters 6 and 9.



## Key Takeaways

1. **The Boolean hypercube** $\{0,1\}^n$ is the natural domain for multilinear polynomials. It has $2^n$ points.

2. **Multilinear extension (MLE)**: The unique polynomial of degree at most 1 in each variable that agrees with $f$ on the hypercube.

3. **Lagrange basis polynomials** $L_w(X)$ equal 1 at $w$ and 0 elsewhere. The MLE is $\tilde{f}(X) = \sum_w f(w) \cdot L_w(X)$.

4. **The equality polynomial** $\widetilde{\text{eq}}(X, Y)$ is the MLE of the equality indicator. Lagrange bases are $L_w(X) = \widetilde{\text{eq}}(w, X)$.

5. **Tensor product structure**: $L_w(r) = \prod_i L_{w_i}(r_i)$. The basis factorizes, enabling fast algorithms.

6. **Efficient evaluation**: Given the table and a point, compute the MLE in $O(2^n)$ time via streaming.

7. **Sum over the hypercube**: $\sum_b \tilde{f}(b) = \sum_w f(w)$. Sum-check verifies such sums efficiently.

8. **Evaluations = coefficients**: For MLEs, the table of values completely determines the polynomial. They're dual representations.

9. **Binary encoding**: Any function on $\{0, \ldots, 2^n - 1\}$ can be encoded as a function on $\{0,1\}^n$, then extended multilinearly.

10. **The bridge to proofs**: MLEs encode data; sum-check verifies properties; polynomial commitment binds the prover. This trinity underlies sum-check-based SNARKs.


\newpage

# Chapter 5: Univariate Polynomials and Finite Fields

In 1965, James Cooley and John Tukey published a paper that changed the world. They described an algorithm that could compute Fourier transforms in $O(n \log n)$ time instead of $O(n^2)$. This speedup was the difference between impossible and instant. It launched the digital signal processing revolution, enabling everything from MRI machines to JPEG compression.

But they weren't the first.

Years later, historians discovered that Carl Friedrich Gauss had written down the exact same algorithm in 1805, predating Joseph Fourier's foundational work on Fourier analysis by two years. Gauss used it to calculate the orbits of asteroids Pallas and Juno from astronomical observations. He wrote it in Latin in a notebook, but never published it. The algorithm sat dormant for 160 years.

That such a powerful technique could be discovered, forgotten, and rediscovered says something about its naturalness. Once you understand the symmetries of roots of unity, the FFT practically writes itself. And those same symmetries now power zero-knowledge proofs.

This chapter develops the univariate polynomial paradigm: finite fields, roots of unity, and the techniques that make systems like Groth16, PLONK, and STARKs possible. Where Chapter 4 explored multilinear polynomials over the Boolean hypercube, here we explore a single variable of high degree over a very different domain.



## Finite Fields: The Algebraic Foundation

Zero-knowledge proofs live in finite fields. Not the real numbers, not the integers; finite fields, where arithmetic wraps around and every division is exact.

A finite field $\mathbb{F}_p$ consists of the integers $\{0, 1, 2, \ldots, p-1\}$ with arithmetic modulo a prime $p$. Addition and multiplication work as usual, then you take the remainder when dividing by $p$:

$$3 + 5 = 8 \equiv 1 \pmod 7$$
$$3 \times 5 = 15 \equiv 1 \pmod 7$$

The magic is in division. Every nonzero element has a multiplicative inverse: this is guaranteed because $p$ is prime. (More generally, finite fields exist for any prime power $p^k$, but prime fields $\mathbb{F}_p$ are the simplest case.) In $\mathbb{F}_7$, we have $3^{-1} = 5$ because $3 \times 5 = 15 \equiv 1$. You can divide by any nonzero element, and the result is exact (no fractions, no approximations).

This is why we call it a *field*. A *ring* (like the integers $\mathbb{Z}$) lets you add, subtract, and multiply. A *field* lets you also divide. The integers are not a field because $1/2$ isn't an integer. But in $\mathbb{F}_7$, division always works: $1/2 = 1 \cdot 2^{-1} = 1 \cdot 4 = 4$, since $2 \cdot 4 = 8 \equiv 1$.

The nonzero elements $\mathbb{F}_p^* = \{1, 2, \ldots, p-1\}$ form a **cyclic group** under multiplication. This is fundamental: there exists a **generator** $g$ such that every nonzero element is some power of $g$.

**Example in $\mathbb{F}_7$**: The element $3$ generates everything:

| Power | $3^k \mod 7$ |
|-------|--------------|
| $3^1$ | $3$ |
| $3^2$ | $2$ |
| $3^3$ | $6$ |
| $3^4$ | $4$ |
| $3^5$ | $5$ |
| $3^6$ | $1$ |

Every nonzero element appears exactly once. The powers cycle through all of $\mathbb{F}_7^*$ before returning to 1.

For cryptographic applications, we use primes of 256 bits or more. The field is vast, roughly $2^{256}$ elements, making exhaustive search impossible.



## Roots of Unity

Because $\mathbb{F}_p^*$ is cyclic of order $p-1$, it contains subgroups of every order dividing $p-1$. The most useful are the **roots of unity**.

An element $\omega \in \mathbb{F}_p$ is an **$n$-th root of unity** if $\omega^n = 1$. It's a **primitive** $n$-th root if additionally $\omega^k \neq 1$ for any $0 < k < n$: the smallest positive power that gives 1 is exactly $n$.

If $\omega$ is a primitive $n$-th root, the complete set of $n$-th roots is:

$$H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$$

This is a subgroup of order $n$. It's the evaluation domain that powers univariate-based SNARKs.

### Worked Example: Fourth Roots in $\mathbb{F}_{17}$

Take $p = 17$. The multiplicative group has order $16 = 2^4$. Since $4$ divides $16$, fourth roots of unity exist.

Is $\omega = 4$ a primitive fourth root?

$$4^1 = 4$$
$$4^2 = 16 \equiv -1 \pmod{17}$$
$$4^3 = 64 \equiv 13 \equiv -4 \pmod{17}$$
$$4^4 = 256 \equiv 1 \pmod{17}$$

Yes. The fourth roots of unity are:

$$H = \{1, 4, 16, 13\} = \{1, 4, -1, -4\}$$

Notice the structure: $4$ and $-4 = 13$ are negatives of each other, as are $1$ and $-1 = 16$. This is not a coincidence.



## The Symmetries

Roots of unity have two key symmetries that enable fast algorithms.

### Symmetry 1: Squaring Halves the Group

When $n$ is even:

$$\omega^{n/2} = -1$$

**Why is this true?** Start with the defining property: $\omega^n = 1$. Taking the square root of both sides: $(\omega^{n/2})^2 = 1$. So $\omega^{n/2}$ is a square root of 1. In any field, the square roots of 1 are exactly $1$ and $-1$. But $\omega^{n/2} \neq 1$ because $\omega$ is *primitive*: its first power to equal 1 is $\omega^n$, not $\omega^{n/2}$. Therefore $\omega^{n/2} = -1$.

This has a remarkable consequence. If you square every element of $H$:

$$(\omega^k)^2 = \omega^{2k}$$

The squares form the $(n/2)$-th roots of unity. And since $(\omega^{k + n/2})^2 = (\omega^k \cdot \omega^{n/2})^2 = (\omega^k)^2 \cdot 1 = (\omega^k)^2$, each square root of unity appears exactly twice.

**In $\mathbb{F}_{17}$**: Squaring the fourth roots $\{1, 4, 16, 13\}$:

$$1^2 = 1, \quad 4^2 = 16, \quad 16^2 = 1, \quad 13^2 = 16$$

The squares are $\{1, 16\}$: the square roots of unity, each appearing twice.

### Symmetry 2: Opposite Elements are Negatives

Elements half a cycle apart are negatives:

$$\omega^{k + n/2} = \omega^k \cdot \omega^{n/2} = -\omega^k$$

**In $\mathbb{F}_{17}$**:

- $\omega^0 = 1$ and $\omega^2 = 16 = -1$
- $\omega^1 = 4$ and $\omega^3 = 13 = -4$

These two symmetries, squaring halves the group and opposites are negatives, are the engine of the Fast Fourier Transform.

### The DFT Is Polynomial Evaluation

Here is one of those facts that seems almost too good to be true.

The Discrete Fourier Transform (DFT) is defined as a matrix-vector multiplication. Given a vector $(c_0, c_1, \ldots, c_{n-1})$, the DFT produces a new vector whose $k$-th entry is:

$$\sum_{j=0}^{n-1} c_j \cdot \omega^{jk}$$

where $\omega$ is a primitive $n$-th root of unity.

Now look at polynomial evaluation. Given a polynomial $P(X) = c_0 + c_1 X + \cdots + c_{n-1} X^{n-1}$, evaluate it at $\omega^k$:

$$P(\omega^k) = \sum_{j=0}^{n-1} c_j \cdot (\omega^k)^j = \sum_{j=0}^{n-1} c_j \cdot \omega^{jk}$$

They are identical. The DFT of the coefficient vector *is* the evaluation vector at roots of unity. This is not a useful analogy or a computational trick. It is a mathematical identity.

The FFT, then, is not "like" converting between polynomial representations. It *is* converting between polynomial representations. Coefficient form and evaluation form are the two natural bases for the same vector space, and the DFT matrix is the change-of-basis matrix. The FFT is the fast algorithm for this change of basis, made possible by the recursive structure of roots of unity.

This is why the same algorithm appears in signal processing, image compression, and zero-knowledge proofs. They are not merely related applications; they are the same mathematical operation in different disguises.

### Resonance: A Physical Intuition

There's a reason the Fourier transform appears in both signal processing and cryptographic proofs: both are exploiting the same mathematical structure.

In physics, every oscillating system has **natural frequencies**: the resonant modes where energy flows most efficiently. Strike a bell, and it rings at specific pitches. Pluck a string, and it vibrates in harmonics. These aren't arbitrary; they're the **eigenfrequencies** of the system, determined by its physical structure.

Roots of unity are the eigenfrequencies of the multiplicative group $\mathbb{F}_p^*$.

Just as a physical system has modes that "fit" its boundary conditions, the finite field has elements that "fit" its cyclic structure. The $n$-th roots of unity are exactly the elements whose powers repeat with period $n$; they resonate with the group's multiplicative structure.

The FFT is decomposition into eigenmodes. A polynomial is a sum of monomials, and each monomial interacts differently with roots of unity. The FFT separates these interactions, projecting the polynomial onto each eigenmode. Evaluating a polynomial at all $n$-th roots simultaneously is like decomposing a sound into its frequency components: same mathematics, different interpretation.

This is why operations that are hard in one basis become easy in another. Multiplication of polynomials (convolution in coefficient space) becomes pointwise multiplication in evaluation space. The FFT is a change of basis to the eigenbasis, where operations decouple.



## Two Representations of Polynomials

A polynomial of degree less than $n$ can be viewed in two ways.

**Coefficient form**: The polynomial is stored as its coefficients.

$$P(X) = c_0 + c_1 X + c_2 X^2 + \cdots + c_{n-1} X^{n-1}$$

**Evaluation form**: The polynomial is stored as its values at $n$ distinct points. Using the $n$-th roots of unity:

$$[P(1), P(\omega), P(\omega^2), \ldots, P(\omega^{n-1})]$$

These two forms carry exactly the same information. A polynomial of degree less than $n$ is uniquely determined by its values at any $n$ points (this is Lagrange interpolation). The coefficient form and evaluation form are just two different coordinate systems for the same object.

Why care about evaluation form? In zero-knowledge proofs, constraints are naturally expressed as evaluations. Gate $i$ must satisfy some relation; this becomes: the constraint polynomial $C(X)$ must equal zero at $\omega^i$. The evaluation form directly represents these constraints.

### Polynomial Evaluation as Inner Product

Here's a key observation that bridges polynomials and linear algebra: **evaluating a polynomial is computing an inner product**.

In coefficient form:
$$P(z) = c_0 + c_1 z + c_2 z^2 + \cdots + c_{n-1} z^{n-1} = \langle \vec{c}, \vec{z} \rangle$$

where $\vec{c} = (c_0, c_1, \ldots, c_{n-1})$ is the coefficient vector and $\vec{z} = (1, z, z^2, \ldots, z^{n-1})$ is the "powers of $z$" vector.

In evaluation form, the same polynomial can be written via Lagrange interpolation:
$$P(z) = \sum_{i=0}^{n-1} P(\omega^i) \cdot L_i(z) = \langle \vec{P}, \vec{L}(z) \rangle$$

where $\vec{P} = (P(1), P(\omega), \ldots, P(\omega^{n-1}))$ is the evaluation vector and $\vec{L}(z) = (L_0(z), L_1(z), \ldots, L_{n-1}(z))$ is the vector of Lagrange basis evaluations.

Either way, polynomial evaluation is an inner product. This observation is surprisingly powerful: it means that **committing to a polynomial** (in either form) reduces to **committing to a vector**, and **proving an evaluation** reduces to **proving an inner product claim**. We'll exploit this connection extensively in Chapter 9.

**Two ways to commit**: This duality (coefficient form vs evaluation form) manifests directly in polynomial commitment schemes:

- **KZG** (Chapter 9) commits in coefficient form: $C = g^{f(\tau)} = \prod_i (g^{\tau^i})^{c_i}$. The commitment encodes "evaluate the coefficients at a secret point $\tau$."

- **FRI** (Chapter 10) commits in evaluation form: a Merkle tree over $[f(1), f(\omega), \ldots, f(\omega^{n-1})]$. The commitment is a hash of all the evaluations.

The FFT is what makes these equivalent: you can convert between representations in $O(n \log n)$ time. But the choice of representation affects everything: proof size, prover cost, setup requirements, and the algebraic tricks available for verification.



## The Fast Fourier Transform

Converting between coefficient and evaluation form naively takes $O(n^2)$ operations: you'd compute each of $n$ evaluations, each requiring $O(n)$ work.

The **Fast Fourier Transform (FFT)** does it in $O(n \log n)$. This speedup is essential; without it, the polynomials in modern proof systems would be computationally intractable.

The FFT exploits the symmetries of roots of unity through divide-and-conquer.

### The Core Idea

Split a polynomial into its even and odd terms:

$$P(X) = P_{\text{even}}(X^2) + X \cdot P_{\text{odd}}(X^2)$$

where:

- $P_{\text{even}}(Y) = c_0 + c_2 Y + c_4 Y^2 + \cdots$ (even-indexed coefficients)
- $P_{\text{odd}}(Y) = c_1 + c_3 Y + c_5 Y^2 + \cdots$ (odd-indexed coefficients)

Both have half the degree of $P$.

Now, when we square the $n$-th roots of unity, we get the $(n/2)$-th roots (each appearing twice). So to evaluate $P$ at all of $H$, we:

1. Recursively evaluate $P_{\text{even}}$ and $P_{\text{odd}}$ at the $(n/2)$-th roots
2. Combine the results

The combination uses the antisymmetry property:

$$P(\omega^k) = P_{\text{even}}(\omega^{2k}) + \omega^k \cdot P_{\text{odd}}(\omega^{2k})$$
$$P(\omega^{k + n/2}) = P_{\text{even}}(\omega^{2k}) - \omega^k \cdot P_{\text{odd}}(\omega^{2k})$$

Two evaluations of $P$ from one evaluation each of $P_{\text{even}}$ and $P_{\text{odd}}$: the same work computes both, with just an addition versus subtraction.

### Worked Example: 4-Point FFT

Evaluate $P(X) = 5 + 3X + X^2 + 2X^3$ at $H = \{1, 4, 16, 13\}$ in $\mathbb{F}_{17}$.

**Split**:

- $P_{\text{even}}(Y) = 5 + Y$ (coefficients $c_0 = 5$, $c_2 = 1$)
- $P_{\text{odd}}(Y) = 3 + 2Y$ (coefficients $c_1 = 3$, $c_3 = 2$)

**Evaluate on $\{1, 16\}$** (the square roots of unity):

| $Y$ | $P_{\text{even}}(Y) = 5 + Y$ | $P_{\text{odd}}(Y) = 3 + 2Y$ |
|-----|------------------------------|------------------------------|
| $1$ | $6$ | $5$ |
| $16$ | $21 \equiv 4$ | $35 \equiv 1$ |

**Combine** using $\omega^0 = 1$, $\omega^1 = 4$, $\omega^2 = 16$, $\omega^3 = 13$:

$$P(1) = P_{\text{even}}(1) + 1 \cdot P_{\text{odd}}(1) = 6 + 5 = 11$$
$$P(4) = P_{\text{even}}(16) + 4 \cdot P_{\text{odd}}(16) = 4 + 4 = 8$$
$$P(16) = P_{\text{even}}(1) - 1 \cdot P_{\text{odd}}(1) = 6 - 5 = 1$$
$$P(13) = P_{\text{even}}(16) - 4 \cdot P_{\text{odd}}(16) = 4 - 4 = 0$$

**Result**: $[P(1), P(4), P(16), P(13)] = [11, 8, 1, 0]$.

Verification: $P(4) = 5 + 3(4) + 16 + 2(64) = 5 + 12 + 16 + 128 = 161 \equiv 8 \pmod{17}$. Correct.

The inverse FFT, going from evaluations back to coefficients, uses the same algorithm with $\omega^{-1}$ instead of $\omega$ and a factor of $1/n$.



## The Vanishing Polynomial

Here is the central insight of univariate arithmetization.

The **vanishing polynomial** of a set $H$ is:

$$Z_H(X) = \prod_{h \in H}(X - h)$$

For the $n$-th roots of unity, this simplifies dramatically:

$$Z_H(X) = X^n - 1$$

This is because $\omega^n = 1$ for every root of unity $\omega$; they are precisely the roots of $X^n - 1$.

**The key theorem**: A polynomial $C(X)$ vanishes at every point of $H$ if and only if $Z_H(X)$ divides $C(X)$.

This is the compression at the heart of univariate SNARKs:

1. Encode $n$ constraints as: "$C(\omega^i) = 0$ for all $i$"
2. This is equivalent to: "$Z_H(X)$ divides $C(X)$"
3. Which is equivalent to: "There exists $Q(X)$ such that $C(X) = Q(X) \cdot Z_H(X)$"

One polynomial divisibility condition captures $n$ separate constraint checks.



## The Divisibility Check

How do we verify divisibility efficiently?

The prover computes the quotient $Q(X) = C(X) / Z_H(X)$ and commits to it. The verifier picks a random challenge $z \in \mathbb{F}$ and checks:

$$C(z) \stackrel{?}{=} Q(z) \cdot Z_H(z)$$

If $C(X) = Q(X) \cdot Z_H(X)$ as polynomials, this equation holds for all $z$, including the random one.

If $C(X) \neq Q(X) \cdot Z_H(X)$, their difference is a nonzero polynomial. By Schwartz-Zippel, a random $z$ catches this disagreement with probability at least $1 - d/|\mathbb{F}|$, where $d$ is the degree.

One random check. $n$ constraints verified. This is the magic.



## Lagrange Interpolation

Given evaluations at roots of unity, how do we recover the polynomial?

The **Lagrange basis polynomial** $L_i(X)$ equals 1 at $\omega^i$ and 0 at all other roots:

$$L_i(X) = \prod_{j \neq i} \frac{X - \omega^j}{\omega^i - \omega^j}$$

The polynomial passing through points $({\omega^i, y_i})$ is:

$$P(X) = \sum_{i=0}^{n-1} y_i \cdot L_i(X)$$

For roots of unity, the Lagrange basis has a beautiful closed form:

$$L_i(X) = \frac{\omega^i}{n} \cdot \frac{X^n - 1}{X - \omega^i}$$

The factor $\frac{X^n - 1}{X - \omega^i}$ vanishes at all roots except $\omega^i$. The prefactor $\frac{\omega^i}{n}$ normalizes to give $L_i(\omega^i) = 1$.



## Cosets: Shifting the Domain

Sometimes we need evaluation points outside $H$. **Cosets** provide them while preserving structure.

If $k \notin H$ is any nonzero field element, then:

$$k \cdot H = \{k, k\omega, k\omega^2, \ldots, k\omega^{n-1}\}$$

is a coset of $H$. It's a "shifted" copy: $n$ new points, disjoint from $H$.

**Why cosets matter in ZK:** Several proof systems crucially depend on cosets:

- **PLONK's permutation argument**: Uses multiple cosets to encode wire positions. If you have $n$ gates with 3 wires each ($a$, $b$, $c$), PLONK encodes them on $H$, $kH$, and $k^2H$ (three disjoint domains of size $n$ each). This lets the permutation polynomial distinguish "wire $a$ of gate 5" from "wire $b$ of gate 5."

- **FRI's low-degree testing**: The prover evaluates on a domain larger than the polynomial's degree (for "rate" or "blowup"). Using $H \cup kH$ doubles the evaluation domain while maintaining FFT structure.

- **Quotient degree management**: If $C(X)$ has degree $2n$ but we've only committed to evaluations on $H$ (size $n$), we need more points to pin down the quotient. Using $H \cup kH$ gives $2n$ points (enough to determine a polynomial of degree less than $2n$).

The FFT works on cosets too: just multiply each root of unity by $k$ before running the algorithm.



## The Quotient Argument

A fundamental operation: prove that $P(z) = y$ for a committed polynomial $P$.

The **factor theorem** says: $P(z) = y$ if and only if $(X - z)$ divides $P(X) - y$.

The prover computes:

$$Q(X) = \frac{P(X) - y}{X - z}$$

If $P(z) = y$, this is a polynomial. If not, the division has a remainder; $Q$ isn't a polynomial.

The verifier checks the polynomial identity:

$$P(X) - y = Q(X) \cdot (X - z)$$

at a random point. This is the foundation of KZG opening proofs (Chapter 9).



## Univariate vs. Multilinear

We now have two paradigms for polynomial proofs:

| Aspect | Multilinear | Univariate |
|--------|-------------|------------|
| **Variables** | $n$ variables, degree 1 each | 1 variable, degree $N-1$ |
| **Domain** | Boolean hypercube $\{0,1\}^n$ | Roots of unity $H$ |
| **Size** | $N = 2^n$ points | $N$ points |
| **Constraint encoding** | Sum over hypercube | Divisibility by $Z_H$ |
| **Key algorithm** | Recursive halving | FFT |
| **Prover cost** | $O(N)$ (linear) | $O(N \log N)$ (quasi-linear) |
| **Verification** | Sum-check protocol | Random evaluation |
| **Systems** | GKR, Spartan, Lasso | PLONK, Marlin, STARKs |

Both achieve the same essential goal: reduce exponentially many constraint checks to a constant number of random evaluations. They're complementary perspectives on the same phenomenon (the rigidity of low-degree polynomials).

**A note on Groth16**: Groth16 uses univariate polynomials but doesn't require roots of unity; it encodes constraints via QAP (Quadratic Arithmetic Programs) and verifies satisfaction through pairing equations, not divisibility checks at structured domains. Provers *can* use FFT as an optimization for polynomial arithmetic, but it's not fundamental to the protocol. PLONK and STARKs, by contrast, rely structurally on roots of unity: constraints are encoded as "polynomial vanishes on $H$," checked via the divisibility pattern described above.



## Key Takeaways

1. **Finite fields** provide exact arithmetic with every nonzero element invertible. The nonzero elements form a cyclic group.

2. **Roots of unity** are elements with $\omega^n = 1$. They form a subgroup of size $n$ when $n$ divides $p-1$.

3. **The key symmetries**: Squaring halves the group; opposite elements are negatives. These enable the FFT.

4. **Two representations**: Polynomials can be stored as coefficients or evaluations. The FFT converts between them in $O(n \log n)$ time.

5. **The vanishing polynomial** $Z_H(X) = X^n - 1$ captures all roots of unity. A polynomial vanishes on $H$ iff $Z_H$ divides it.

6. **Constraint compression**: $n$ constraints "$C(\omega^i) = 0$" become one divisibility "$Z_H | C$", verified by one random check.

7. **Lagrange interpolation** over roots of unity has a clean closed form exploiting the structure of $Z_H$.

8. **Cosets** extend the domain while preserving FFT-friendliness.

9. **Quotient arguments** prove evaluation claims: to show $P(z) = y$, prove $(X-z)$ divides $P(X) - y$.

10. **The FFT exists because of roots of unity.** The algorithm is a direct consequence of the symmetries $\omega^{n/2} = -1$ and $(\omega^k)^2 = \omega^{2k}$.



\newpage

# Chapter 6: Commitment Schemes: Cryptographic Binding

In 1981, Manuel Blum posed a simple question: can two people play a fair game of coin-flipping over the telephone?

Blum was working on what cryptographers called **Mental Poker**: how can two people play a card game over the phone without a trusted dealer? How do I know you didn't shuffle the Aces to the top of the deck? The coin flip was the atomic unit of this problem. Get that right, and you could build up to full card games.

The problem seems impossible. Alice flips a coin and announces "heads." Bob has no way to verify she actually flipped anything. She might have waited to hear his guess first. Or she might change her answer after hearing his response. Without shared physical reality, without a coin both parties can see, how can either trust the outcome?

Blum's solution introduced one of the most fundamental primitives in cryptography. Alice doesn't announce her flip directly. Instead, she first sends a *commitment*: a cryptographic object that locks in her choice without revealing it. Only after Bob makes his guess does Alice *open* the commitment, proving what she had chosen all along. The commitment is binding (Alice cannot change her answer after sending it) and hiding (Bob learns nothing until the reveal).

This two-phase structure, commit then reveal, turns out to be exactly what our proof systems need. You've designed a protocol where the prover claims a polynomial evaluates to some value, and you want to check this with random queries. But the prover responds *after* seeing your challenge. What stops them from constructing a fake polynomial that happens to pass your spot-checks?

This is the **binding problem**. The verifier's randomness is meant to catch a cheating prover off-guard. But if the prover can adapt their answers after seeing the challenge, they can tailor responses to pass. The polynomial identity testing that underlies our protocols becomes meaningless.

We need a mechanism that forces the prover to fix their polynomial before verification begins.



## The Trust Problem Revisited

Consider the sum-check protocol from Chapter 3. The verifier sends random challenges $r_1, r_2, \ldots$, and the prover responds with univariate polynomials. At the end, the verifier must check that some claimed evaluation matches the actual polynomial. But how does the verifier know the prover didn't just fabricate a polynomial that happens to satisfy the final check?

The issue is subtle. Our soundness proofs assumed the prover is committed to *some* polynomial before the interaction begins. But in a raw interactive protocol, nothing enforces this. A dishonest prover could:

1. Wait to see all the verifier's challenges
2. Work backwards to construct a polynomial that passes
3. Claim they had this polynomial all along

This attack doesn't violate the *information-theoretic* soundness of the protocol; it violates the *execution model*. We assumed a sequential game where the prover moves first; in reality, we need cryptography to enforce this ordering.



## The Commitment Paradigm

A **commitment scheme** solves this problem through a two-phase protocol:

**Phase 1 (Commit)**: The prover publishes a *commitment*, a short, seemingly random string that binds them to a value without revealing it.

**Phase 2 (Reveal)**: Later, the prover can open the commitment by revealing the original value. Anyone can verify that the revealed value matches the original commitment.

**Formal Properties**:

- **Binding**: Once committed, the committer cannot open to a different value. More precisely, no efficient adversary can find two different values that produce the same commitment.

- **Hiding**: The commitment reveals nothing about the committed value. An observer cannot distinguish between commitments to different values.

These properties exist in tension. Perfect binding means each value maps to a unique commitment, but then the commitment might leak information about the value. Perfect hiding means commitments are statistically indistinguishable, but then multiple values might share commitments. Cryptographic schemes typically achieve one property perfectly and the other computationally.



## Pedersen Commitments: The Discrete Log Approach

The most elegant commitment scheme comes from a surprising source: the hardness of computing discrete logarithms in cyclic groups.

**Setup**: Let $G$ be a cyclic group of prime order $q$ (think of an elliptic curve group). Select two generators $g$ and $h$ such that *nobody knows* the discrete logarithm $\log_g h$. The public parameters are $(G, q, g, h)$.

**Commit**: To commit to a value $m \in \mathbb{Z}_q$, the committer:

1. Chooses a random *blinding factor* $r \leftarrow \mathbb{Z}_q$
2. Computes the commitment $C = g^m \cdot h^r$

**Reveal**: To open, the committer reveals $(m, r)$. The verifier checks that $g^m \cdot h^r = C$.

The scheme uses multiplicative notation, but on elliptic curves (the dominant implementation), we write $C = m \cdot G + r \cdot H$ using additive notation.

### Why Binding Holds

Suppose Alice commits $C = g^m h^r$ and later wants to open it as a *different* value $m' \neq m$. She needs to find $r'$ such that:
$$g^m h^r = g^{m'} h^{r'}$$

Rearranging:
$$g^{m - m'} = h^{r' - r}$$

This means:
$$\log_g h = \frac{m - m'}{r' - r}$$

But computing $\log_g h$ is the discrete logarithm problem! If Alice could find such $(m', r')$, she could break DLog in $G$. The binding property holds computationally, as long as discrete log is hard.

### Why Hiding Holds

The commitment $C = g^m h^r$ is **perfectly hiding**. Here's the key insight: since $r$ is uniformly random in $\mathbb{Z}_q$, and $h$ is a generator of $G$, the term $h^r$ is uniformly distributed over all of $G$.

For any message $m$, the commitment $C = g^m \cdot h^r$ is a uniformly random group element. This means:

- $\text{Commitment to } m_1 \sim \text{Uniform}(G)$
- $\text{Commitment to } m_2 \sim \text{Uniform}(G)$

The two distributions are identical: not just computationally indistinguishable, but *statistically* identical. Even an unbounded adversary cannot determine the committed value from the commitment alone.

**The Paint Analogy.** Think of $g^m$ as a specific color of paint (say, blue for $m = 10$). Think of $h^r$ as a random bucket of paint mixed in. Because $h^r$ can be *any* color depending on $r$, adding it to blue produces a mixture that looks essentially random. If you see purple, it could be blue + red, or yellow + violet. Without knowing the exact shade of the random mixer ($r$), the original color ($m$) is completely masked.

### The Independence Requirement

There's a critical subtlety: the generators $g$ and $h$ must be *independently chosen* such that nobody knows $\log_g h$.

If Alice knows that $h = g^x$ for some $x$, she can break binding:
$$C = g^m h^r = g^m (g^x)^r = g^{m + xr}$$

She can open this as $(m', r')$ for any $m'$ by computing $r' = r + (m - m')/x$. The verification passes because:
$$g^{m'} h^{r'} = g^{m'} g^{x(r + (m - m')/x)} = g^{m' + xr + m - m'} = g^{m + xr} = C$$

If Alice knows this relationship $h = g^x$, she holds a **trapdoor**. It allows her to open the commitment to *any* value she wants. This is why trusted setups in SNARKs are so sensitive: if the creator knows the "toxic waste" (the secret exponents used to generate the parameters), they can forge proofs. We prevent this by generating $g$ and $h$ from "nothing-up-my-sleeve" numbers like the digits of $\pi$ or by hashing different strings to curve points, ensuring nobody knows the discrete log relationship.



## Worked Example: Pedersen Commitment in $\mathbb{Z}_{23}^*$

Let's trace through a concrete example using the multiplicative group modulo 23.

**Setup**: Work in $\mathbb{Z}_{23}^*$, which has order $\phi(23) = 22$. Take generators $g = 5$ and $h = 7$. We assume nobody knows $\log_5 7$.

**Commitment to $m = 10$**:

- Choose random blinding factor $r = 3$
- Compute $C = g^m \cdot h^r = 5^{10} \cdot 7^3 \pmod{23}$

Computing $5^{10} \pmod{23}$:

- $5^2 = 25 \equiv 2$
- $5^4 \equiv 4$
- $5^8 \equiv 16$
- $5^{10} = 5^8 \cdot 5^2 \equiv 16 \cdot 2 = 32 \equiv 9$

Computing $7^3 \pmod{23}$:

- $7^2 = 49 \equiv 3$
- $7^3 = 7 \cdot 3 = 21$

So $C = 9 \cdot 21 = 189 \equiv 5 \pmod{23}$.

**Verification**: Given $(m = 10, r = 3)$, the verifier checks:
$$5^{10} \cdot 7^3 \equiv 9 \cdot 21 \equiv 5 \pmod{23} \; \checkmark$$

The commitment opens correctly.



## The Homomorphic Property

Pedersen commitments have a remarkable algebraic property: they are **additively homomorphic**. You can compute on committed values without knowing what they are.

Given two commitments:
$$C_1 = g^{m_1} h^{r_1} \quad \text{and} \quad C_2 = g^{m_2} h^{r_2}$$

Their product is:
$$C_1 \cdot C_2 = g^{m_1} h^{r_1} \cdot g^{m_2} h^{r_2} = g^{m_1 + m_2} h^{r_1 + r_2}$$

This is a valid commitment to $m_1 + m_2$ with blinding factor $r_1 + r_2$!

**Worked Example (continuing)**:

Commit to $m_2 = 4$ with $r_2 = 6$:
$$C_2 = 5^4 \cdot 7^6 \pmod{23}$$

Computing $5^4 \equiv 4$ and $7^6 = (7^3)^2 \equiv 21^2 = 441 \equiv 441 - 19 \cdot 23 = 441 - 437 = 4$.

So $C_2 = 4 \cdot 4 = 16$.

**Homomorphic addition**:
$$C_3 = C_1 \cdot C_2 = 5 \cdot 16 = 80 \equiv 80 - 3 \cdot 23 = 80 - 69 = 11 \pmod{23}$$

This should be a commitment to $m_1 + m_2 = 14$ with blinding factor $r_1 + r_2 = 9$.

**Verification**:
$$5^{14} \cdot 7^9 \pmod{23}$$

For $5^{14} = 5^{10} \cdot 5^4 \equiv 9 \cdot 4 = 36 \equiv 13$.

For $7^9 = 7^6 \cdot 7^3 \equiv 4 \cdot 21 = 84 \equiv 84 - 3 \cdot 23 = 84 - 69 = 15$.

So $5^{14} \cdot 7^9 \equiv 13 \cdot 15 = 195 \equiv 195 - 8 \cdot 23 = 195 - 184 = 11 \pmod{23}$.

It matches $C_3 = 11$.

This property is extraordinarily useful. A verifier can combine multiple commitments, add constants, or compute linear combinations, all without learning the committed values. This enables protocols where computations happen "in the encrypted domain."



## Scalar Multiplication

The homomorphic property extends to scalar multiplication. For a constant $k$:
$$(C)^k = (g^m h^r)^k = g^{km} h^{kr}$$

This is a commitment to $k \cdot m$ with blinding factor $k \cdot r$. The verifier can scale committed values without opening them.



## From Scalar to Vector Commitments

The Pedersen scheme naturally extends from committing to a single value to committing to an entire vector. Given $n$ independent generators $G_1, \ldots, G_n$ and a blinding generator $H$, we can commit to a vector $\vec{m} = (m_1, \ldots, m_n)$:

$$C = \sum_{i=1}^n m_i \cdot G_i + r \cdot H$$

This **Pedersen vector commitment** is still a single group element, regardless of the vector length. The homomorphic property extends: adding two vector commitments yields a commitment to the component-wise sum.

But here's where things get interesting for our purposes. Recall from Chapters 4 and 5 that a polynomial evaluation is just an inner product:
$$f(z) = \sum_{i=0}^{n-1} c_i z^i = \langle \vec{c}, \vec{z} \rangle$$

where $\vec{c} = (c_0, \ldots, c_{n-1})$ are the coefficients and $\vec{z} = (1, z, z^2, \ldots, z^{n-1})$ is the evaluation vector.

If we commit to the coefficient vector using a Pedersen vector commitment, we've effectively committed to the polynomial itself. And thanks to homomorphism, the verifier can compute a commitment to any evaluation $f(z)$ without knowing the coefficients!

This observation, that polynomial evaluation is inner product and inner products interact beautifully with homomorphic commitments, is the conceptual bridge from simple commitments to full polynomial commitment schemes. We'll cross that bridge in Chapter 9.



## Proving Knowledge of an Opening

A commitment alone proves nothing; the prover must eventually reveal the opening to be useful. But what if we want to prove something *about* the committed value without revealing it?

This is where $\Sigma$-protocols (Chapter 16) enter the picture. A prover who knows the opening $(m, r)$ for a commitment $C = g^m h^r$ can convince a verifier they know this opening without revealing $m$ or $r$.

The protocol follows the classic three-move structure:

**Round 1 (Commit to randomness)**: The prover picks random $d, s \leftarrow \mathbb{Z}_q$ and sends $T = g^d h^s$.

**Round 2 (Challenge)**: The verifier sends a random challenge $e \leftarrow \mathbb{Z}_q$.

**Round 3 (Response)**: The prover computes:

- $z_1 = d + e \cdot m$
- $z_2 = s + e \cdot r$

and sends $(z_1, z_2)$.

**Verification**: The verifier checks:
$$g^{z_1} h^{z_2} \stackrel{?}{=} T \cdot C^e$$

**Why it works**: Expanding the right side:
$$T \cdot C^e = (g^d h^s) \cdot (g^m h^r)^e = g^{d + em} h^{s + er} = g^{z_1} h^{z_2}$$

The equation holds if the prover knows $(m, r)$.

**Why it's zero-knowledge**: The values $z_1$ and $z_2$ look random because they're masked by the truly random $d$ and $s$. The verifier learns nothing about $m$ or $r$ beyond the fact that the prover knows them.

**Why it's sound**: A prover who doesn't know $(m, r)$ cannot answer two different challenges $e$ and $e'$ consistently. Given two accepting transcripts with the same $T$ but different challenges, one can extract the witness; this is the "special soundness" property.



## Worked Example: Proof of Knowledge

Continuing our example with $g = 5$, $h = 7$ in $\mathbb{Z}_{23}^*$, suppose the prover committed $C = 5$ and claims to know the opening.

**Prover's commitment**:

- Choose random $d = 8$, $s = 2$
- Compute $T = 5^8 \cdot 7^2 \pmod{23}$
- $5^8 \equiv 16$, $7^2 = 49 \equiv 3$
- $T = 16 \cdot 3 = 48 \equiv 2$

**Verifier's challenge**: $e = 4$

**Prover's response** (recall $m = 10$, $r = 3$):

- $z_1 = d + e \cdot m = 8 + 4 \cdot 10 = 48 \equiv 48 \pmod{22} = 4$ (arithmetic mod group order)
- $z_2 = s + e \cdot r = 2 + 4 \cdot 3 = 14$

**Verification**:

- Left side: $5^4 \cdot 7^{14} \pmod{23}$
  - $5^4 \equiv 4$
  - $7^{14} = 7^{11} \cdot 7^3$ (since $14 \equiv 14 \pmod{22}$)
  - $7^{11} = 7^8 \cdot 7^3$. We have $7^2 \equiv 3$, $7^4 \equiv 9$, $7^8 \equiv 81 \equiv 81 - 3 \cdot 23 = 12$
  - $7^{11} = 12 \cdot 21 = 252 \equiv 252 - 10 \cdot 23 = 22 \equiv -1$
  - $7^{14} = (-1) \cdot 21 = -21 \equiv 2$
  - Left side: $4 \cdot 2 = 8$

- Right side: $T \cdot C^e = 2 \cdot 5^4 \pmod{23}$
  - $5^4 \equiv 4$
  - Right side: $2 \cdot 4 = 8$

Both sides equal 8. The proof verifies.



## Beyond Pedersen: A Landscape of Commitment Schemes

Pedersen commitments are beautiful but not the only option. Different commitment schemes offer different trade-offs:

**Hash-Based Commitments**: Commit as $C = H(m \| r)$ where $H$ is a cryptographic hash. Binding follows from collision resistance; hiding follows from the hash acting as a random oracle. These are simple and quantum-resistant, but they lack the homomorphic property.

**Polynomial Commitments**: The heart of modern SNARKs. Instead of committing to a single value, we commit to an entire polynomial and can later prove evaluations at arbitrary points. Chapter 9 explores KZG (using pairings) and IPA (using discrete log) in depth.

**ElGamal-style Commitments**: Related to encryption, where the commitment can be "decrypted" with a secret key. Useful in some multi-party protocols.

Each scheme involves trade-offs between:

- **Setup**: Does it require a trusted setup?
- **Assumptions**: Discrete log? Pairings? Hashes?
- **Efficiency**: Commitment size, proof size, computation time
- **Properties**: Homomorphic? Additively? Multiplicatively?
- **Quantum resistance**: Will it survive quantum computers?



## Why Commitments Matter for ZK Proofs

We opened this chapter with the binding problem: how do we ensure the prover doesn't cheat by choosing their polynomial after seeing the verifier's challenges?

Commitment schemes provide the answer through the **commit-and-prove** paradigm:

1. **Commit phase**: Before any interaction, the prover commits to their polynomial (or the witness encoding it).

2. **Interaction phase**: The verifier sends challenges, the prover responds. But the prover's polynomial was fixed in step 1.

3. **Opening phase**: At the end, the prover opens relevant parts of their commitment. The verifier checks consistency.

The binding property ensures the prover cannot change their polynomial mid-protocol. The hiding property ensures the commitment itself doesn't leak information about the witness. Every modern SNARK (Groth16, PLONK, STARKs) follows this pattern, varying only in which commitment scheme they use (KZG for Groth16/PLONK, Merkle trees for STARKs).



## The Hiding-Binding Tradeoff

There's a fundamental tension in commitment schemes that deserves attention: you cannot have both *perfect* hiding and *perfect* binding simultaneously.

**Perfect binding** means each commitment corresponds to exactly one value: no two distinct messages ever produce the same commitment. This is an information-theoretic guarantee: even with unlimited computation, opening to a different value is impossible.

**Perfect hiding** means the commitment reveals nothing about the value: all messages produce statistically indistinguishable commitment distributions. Again, this is information-theoretic: even unbounded adversaries learn nothing.

Why can't we have both? Consider what each requires:

- Perfect binding needs the commitment function to be injective (one-to-one). Every value maps to a unique commitment.

- Perfect hiding needs all commitments to look identical regardless of the input. The commitment must be independent of the value.

These requirements conflict. If commitments are independent of values (hiding), multiple values must map to the same commitment (not binding). If every value has a unique commitment (binding), the commitment reveals which value was chosen (not hiding).

**The resolution**: Relax one property to *computational* rather than *information-theoretic*:

- **Perfectly hiding, computationally binding**: Pedersen commitments. As we proved earlier, for any message $m$ there exists an $r$ that produces any given commitment, so an unbounded adversary cannot determine which value is inside. But finding two openings requires solving discrete log, so binding holds against efficient adversaries. Even an all-powerful being cannot tell which value is committed (perfect hiding), but a quantum computer could eventually break the lock (computational binding).

- **Perfectly binding, computationally hiding**: Hash-based commitments $C = H(m \| r)$. A hash function is deterministic: each $(m, r)$ pair maps to exactly one commitment, and collision resistance means you cannot find two pairs that collide. The value is locked in tight (perfect binding). But an unbounded adversary could brute-force all possible inputs to find $(m, r)$ (computational hiding).

This tradeoff shapes the design space. For ZK proofs, we typically want hiding (don't reveal the witness) and accept computational binding (secure against poly-time adversaries). Pedersen commitments are the natural choice: the witness stays perfectly hidden, and binding holds as long as discrete log is hard.



## Looking Ahead

We've established the cryptographic primitive that makes succinct proofs possible. Commitments transform interactive protocols, where timing and ordering are honor-system, into cryptographically enforced games where cheating is computationally infeasible.

In Chapter 9, we'll see how polynomial commitment schemes (KZG, IPA, and FRI) extend these ideas to commit to polynomials and prove evaluations. These are the engines that power modern SNARKs.

But first, we need to understand *what* we're proving. Chapter 7 introduces the GKR protocol, which uses sum-check to verify layered arithmetic circuits. And Chapter 8 shows how arbitrary computations become circuits, which become polynomials. Together, these chapters complete the story of how a computation becomes a succinct proof.



## Key Takeaways

1. **The binding problem**: Interactive proofs need cryptographic enforcement to prevent provers from adapting their answers to verifier challenges.

2. **Commitment = seal**: A commitment locks in a value before revealing it; binding ensures it can't change, hiding ensures it reveals nothing.

3. **Pedersen commitments**: $C = g^m h^r$ achieves perfect hiding (statistically) and computational binding (from discrete log hardness).

4. **Independence is critical**: The generators $g$ and $h$ must have unknown discrete log relationship, or binding fails.

5. **Homomorphic magic**: Pedersen commitments allow addition in the "encrypted domain": $C_1 \cdot C_2$ commits to $m_1 + m_2$.

6. **Vector commitments**: Committing to a coefficient vector effectively commits to a polynomial.

7. **Proof of knowledge**: Sigma protocols let a prover demonstrate they know a commitment's opening without revealing it.

8. **Commit-and-prove paradigm**: The foundation of all modern SNARKs: commit first, then prove properties of the committed values.

9. **Trade-off landscape**: Different commitment schemes offer different balances of setup requirements, assumptions, efficiency, and quantum resistance.

10. **Bridge to polynomial commitments**: The observation that evaluation = inner product connects scalar commitments to the polynomial commitment schemes that power SNARKs.


\newpage

# Chapter 7: The GKR Protocol: Verifying Circuits Layer by Layer

In 2006, Amazon launched AWS, and the world changed. Companies stopped buying servers and started renting "compute" from invisible data centers. It was efficient, but it created a trust gap. If a bank rents a server to calculate interest rates, how do they know the server isn't buggy, or malicious?

Verifying the computation by re-running it defeats the purpose of outsourcing. You want the cloud to do the heavy lifting, and you want to check the work with the effort of a text message.

In 2008, Shafi Goldwasser, Yael Kalai, and Guy Rothblum published a theoretical solution. They proposed a protocol where a supercomputer could prove a massive calculation to a laptop, and the laptop could verify it in seconds. While it took a decade for hardware and cryptographic engineering to catch up to their math, every modern rollup and scaling solution on Ethereum is spiritually a descendant of that 2008 paper.

The sum-check protocol is extraordinary. It transforms exponentially large sums ($2^n$ terms) into verification that runs in $O(n)$ time, logarithmic in the sum size. But every application we've seen (#SAT, triangle counting, matrix multiplication) requires a custom polynomial tailored to that specific problem. Each new computation demands a new arithmetization.

What if we want to verify *any* computation, not just counting problems? The GKR protocol provides a *universal* framework for verifying any computation that can be expressed as an arithmetic circuit (which turns out to be everything). Rather than designing a new protocol for each problem, GKR gives us a machine: feed in a circuit, get out an efficient verification protocol.



## From Sum-Check to General Computation

Let's understand the conceptual leap. The sum-check protocol verifies claims of the form:

$$H = \sum_{x \in \{0,1\}^n} g(x)$$

Given a polynomial $g$, it checks whether the claimed sum $H$ is correct. The polynomial $g$ encodes the problem, and sum-check verifies the encoding.

But computation is more than summation. A real computation involves:

- Input values
- Intermediate calculations (additions, multiplications)
- Data dependencies (the output of one step becomes the input to another)
- A final output

The insight of GKR is that these computations have *layered structure*. A circuit consists of gates organized into layers, where each layer's outputs feed into the next layer's inputs. And crucially, the relationship between adjacent layers can be expressed as a polynomial identity: one that sum-check can verify.

> **Remark (GKR as a chain of sum-checks).** GKR is a sequence of sum-checks, each reducing a claim about layer $i$ to a claim about layer $i+1$. This is a special case of a more general pattern: sum-checks composing into directed graphs, where each sum-check is a node and evaluation claims are edges. GKR's graph is a path (linear chain from output to input). More complex protocols like Spartan (Chapter 19) have branching structure: one outer sum-check spawns multiple inner sum-checks. The graph perspective, where depth determines sequential stages and width enables batching, becomes crucial for understanding prover efficiency in Chapters 19-20.



## Layered Arithmetic Circuits

GKR operates on **layered arithmetic circuits**: directed acyclic graphs (graphs with edges that have direction, and no cycles; you can never follow edges back to where you started) where:

1. **Layers**: Gates are organized into layers $0, 1, \ldots, d$

   - Layer $d$ is the input layer
   - Layer $0$ is the output layer
   - Wires only connect adjacent layers (from layer $i+1$ to layer $i$)

2. **Gate operations**: Each gate performs either addition or multiplication, with exactly two inputs

3. **Indexing**: Gates within each layer are numbered using binary strings
   - If layer $i$ has $S_i$ gates, we use $k_i = \lceil \log_2 S_i \rceil$ bits to index them
   - Gate $j$ in layer $i$ has label $j \in \{0,1\}^{k_i}$

Any circuit can be transformed into this layered form. If a wire spans multiple layers, we insert "pass-through" gates (identity gates that output their input unchanged).

**Example Circuit**: Let's trace through a simple circuit computing $(x_1 + x_2) \cdot x_3$.

```
Layer 2 (Inputs):    x_1      x_2      x_3
                      \       /          |
                       \     /           |
Layer 1 (Middle):      [+]           [pass]
                         \             /
                          \           /
Layer 0 (Output):           [*]
                             |
                          output
```

**Gate labeling**:

- Layer 2 (inputs): $k_2 = 2$ bits needed for 3 gates
  - $x_1 \to (0,0)$, $x_2 \to (0,1)$, $x_3 \to (1,0)$
- Layer 1: $k_1 = 1$ bit for 2 gates
  - Addition gate $\to (0)$, pass-through $\to (1)$
- Layer 0 (output): $k_0 = 1$ bit for 1 gate
  - Multiplication gate $\to (0)$



## The Wiring Predicates

The circuit's structure is encoded by **wiring predicates**: functions that describe which gates connect to which.

For layer $i$, we define:

$$\text{add}_i(a, b, c) = \begin{cases} 1 & \text{if gate } a \text{ in layer } i \text{ is an addition gate with inputs } b, c \text{ from layer } i+1 \\ 0 & \text{otherwise} \end{cases}$$

$$\text{mult}_i(a, b, c) = \begin{cases} 1 & \text{if gate } a \text{ in layer } i \text{ is a multiplication gate with inputs } b, c \text{ from layer } i+1 \\ 0 & \text{otherwise} \end{cases}$$

For our example circuit, look at layer 0. It contains a single multiplication gate, labeled $(0)$. This gate multiplies the outputs of gate $(0)$ (the addition gate computing $x_1 + x_2$) and gate $(1)$ (the pass-through carrying $x_3$) from layer 1. The wiring predicate encodes exactly this:

$$\text{mult}_0(a, b, c) = \begin{cases} 1 & \text{if } a = 0, b = 0, c = 1 \\ 0 & \text{otherwise} \end{cases}$$

Reading this: "Gate $a=0$ in layer 0 is a multiplication gate whose left input comes from gate $b=0$ in layer 1, and whose right input comes from gate $c=1$ in layer 1." The predicate returns 1 only for this specific triple; all other combinations yield 0.

The layer has no addition gates, so $\text{add}_0$ is identically zero.

**The key observation**: These predicates depend only on the *circuit structure*, not on the input values. The verifier, who knows the circuit, can compute these predicates efficiently.

**The Switchboard Analogy.** Think of the wiring predicates $\text{add}_i$ and $\text{mult}_i$ as the circuit's switchboard operators. Gate $a$ in layer 0 shouts: "I need inputs!" The switchboard looks up its directory. "Okay, gate $a$, you are a multiplication gate. I am connecting you to gate $b$ and gate $c$ from the previous layer." In the math, $\text{mult}_i(a, b, c) = 1$ is just the switchboard confirming: "Yes, that connection exists." If you ask about a connection that doesn't exist (say, gate 0 to gates 5 and 7), the switchboard says "0." The sum-check protocol essentially asks the switchboard to verify that all the cables are plugged into the right sockets.



## Gate Values as Polynomials

Let $W_i : \{0,1\}^{k_i} \to \mathbb{F}$ denote the function mapping each gate label in layer $i$ to its output value. The prover, having evaluated the circuit on specific inputs, knows all of $W_0, W_1, \ldots, W_d$.

We extend these to multilinear polynomials $\tilde{W}_i$ over $\mathbb{F}^{k_i}$. Similarly, we extend the wiring predicates to multilinear polynomials $\widetilde{\text{add}}_i$ and $\widetilde{\text{mult}}_i$.

For our example with inputs $x_1 = 2$, $x_2 = 3$, $x_3 = 4$:

**Layer 2 values** (inputs):
$$W_2(0,0) = 2, \quad W_2(0,1) = 3, \quad W_2(1,0) = 4, \quad W_2(1,1) = 0$$

(The fourth entry is padding: we have 3 inputs but need $2^2 = 4$ slots for 2-bit indexing. Unused slots are set to 0.)

The MLE is:
$$\tilde{W}_2(y_1, y_2) = 2(1-y_1)(1-y_2) + 3(1-y_1)y_2 + 4 \cdot y_1(1-y_2)$$

**Layer 1 values**:
$$W_1(0) = x_1 + x_2 = 5, \quad W_1(1) = x_3 = 4$$

The MLE is:
$$\tilde{W}_1(z) = 5(1-z) + 4z = 5 - z$$

**Layer 0 values** (output):
$$W_0(0) = (x_1 + x_2) \cdot x_3 = 20$$

The MLE is:
$$\tilde{W}_0(u) = 20(1-u)$$



## The Layer Reduction Lemma

The heart of GKR is a beautiful algebraic identity that links adjacent layers:

**GKR Lemma**: For any point $z \in \mathbb{F}^{k_i}$:

$$\tilde{W}_i(z) = \sum_{b \in \{0,1\}^{k_{i+1}}} \sum_{c \in \{0,1\}^{k_{i+1}}} f_i(z, b, c)$$

Here $k_{i+1} = \lceil \log_2 S_{i+1} \rceil$ is the number of bits indexing gates in layer $i+1$, so the sum ranges over all $2^{k_{i+1}} \times 2^{k_{i+1}}$ possible pairs of gate indices from that layer. The polynomial $f_i$ is defined as:
$$f_i(z, b, c) = \widetilde{\text{add}}_i(z, b, c) \cdot (\tilde{W}_{i+1}(b) + \tilde{W}_{i+1}(c)) + \widetilde{\text{mult}}_i(z, b, c) \cdot (\tilde{W}_{i+1}(b) \cdot \tilde{W}_{i+1}(c))$$

**Why does this work?** The sum ranges over all possible pairs of input gates $(b, c)$. For most pairs, the wiring predicates are zero: gate $z$ doesn't receive input from those gates. Only the *actual* input pair contributes, and for that pair:

- If $z$ is an addition gate: $\widetilde{\text{add}}_i = 1$, contributing $\tilde{W}_{i+1}(b) + \tilde{W}_{i+1}(c)$
- If $z$ is a multiplication gate: $\widetilde{\text{mult}}_i = 1$, contributing $\tilde{W}_{i+1}(b) \cdot \tilde{W}_{i+1}(c)$

The sum collapses to exactly what gate $z$ should compute.

**The magic**: This identity expresses the output of layer $i$ as a *sum*, and we know how to verify sums efficiently using sum-check!



## The Protocol

The GKR protocol reduces verification of the entire circuit to a single check on the input layer.

**Initial Setup**:

1. The prover evaluates the circuit and sends the claimed output $W_0$ to the verifier
2. The verifier picks a random point $r_0 \in \mathbb{F}^{k_0}$ and computes $V_0 = \tilde{W}_0(r_0)$
3. The goal: verify that $V_0$ is correct

**Layer-by-Layer Reduction** (for $i = 0, 1, \ldots, d-1$):

At the start of round $i$, the verifier holds a claim: "$\tilde{W}_i(r_i) = V_i$"

1. **Invoke sum-check**: Using the Layer Reduction Lemma, the verifier expresses $V_i$ as a sum:
   $$V_i = \sum_{b \in \{0,1\}^{k_{i+1}}} \sum_{c \in \{0,1\}^{k_{i+1}}} f_i(r_i, b, c)$$

   The prover and verifier run sum-check on this polynomial. The number of variables is $2k_{i+1}$.

2. **Sum-check conclusion**: Sum-check runs for $2k_{i+1}$ rounds. In each round, the verifier sends a random field element as a challenge. The first $k_{i+1}$ challenges become $s_b \in \mathbb{F}^{k_{i+1}}$; the next $k_{i+1}$ become $s_c \in \mathbb{F}^{k_{i+1}}$. At the end, the verifier must verify:
   $$f_i(r_i, s_b, s_c) = \widetilde{\text{add}}_i(r_i, s_b, s_c) \cdot (\tilde{W}_{i+1}(s_b) + \tilde{W}_{i+1}(s_c)) + \widetilde{\text{mult}}_i(r_i, s_b, s_c) \cdot (\tilde{W}_{i+1}(s_b) \cdot \tilde{W}_{i+1}(s_c))$$

3. **The problem**: The verifier can compute the wiring predicates (she knows the circuit), but she doesn't know $\tilde{W}_{i+1}(s_b)$ and $\tilde{W}_{i+1}(s_c)$; those depend on intermediate gate values only the prover knows.

4. **Reduce two claims to one**: The prover sends the claimed values $\tilde{W}_{i+1}(s_b)$ and $\tilde{W}_{i+1}(s_c)$. But now the verifier has *two* claims to verify in the next round. To maintain efficiency, we reduce them to one:

   - The verifier picks a fresh random challenge $\alpha \in \mathbb{F}$
   - Define $r_{i+1} = s_b + \alpha(s_c - s_b)$ (a random point on the line $\ell(t) = s_b + t(s_c - s_b)$ through $s_b$ and $s_c$)
   - The prover sends a univariate polynomial $q(t) = \tilde{W}_{i+1}(\ell(t))$ of degree $k_{i+1}$
   - The verifier checks $q(0) = \tilde{W}_{i+1}(s_b)$ and $q(1) = \tilde{W}_{i+1}(s_c)$ against the prover's earlier claims
   - Set $V_{i+1} = q(\alpha)$, which equals $\tilde{W}_{i+1}(r_{i+1})$

   The key insight: restricting a multilinear polynomial to a line yields a low-degree univariate polynomial. The random $\alpha$ serves double duty: (1) it tests consistency (if the prover lied about either $\tilde{W}_{i+1}(s_b)$ or $\tilde{W}_{i+1}(s_c)$, the polynomial $q$ won't pass through both claimed values); (2) it produces a fresh random point $r_{i+1}$ that combines both claims into one for the next round

   *Alternative: random linear combination.* Some implementations (Church-Forbes-Spooner 2017) instead use $V_{i+1} = \alpha_1 \cdot \tilde{W}_{i+1}(s_b) + \alpha_2 \cdot \tilde{W}_{i+1}(s_c)$ for fresh random $\alpha_1, \alpha_2$, verifying via a single combined claim. Both approaches achieve the same goal with similar security.

**Final Check**:

After $d$ reductions, the verifier holds a claim: "$\tilde{W}_d(r_d) = V_d$"

But layer $d$ is the input layer! The verifier knows the inputs. She computes $\tilde{W}_d(r_d)$ herself and checks if it equals $V_d$.



## Worked Example: Verifying $(x_1 + x_2) \cdot x_3$

Let's trace through the protocol with $x_1 = 2$, $x_2 = 3$, $x_3 = 4$.

**Honest computation**:

- Layer 2: $W_2(0,0) = 2$, $W_2(0,1) = 3$, $W_2(1,0) = 4$
- Layer 1: $W_1(0) = 5$, $W_1(1) = 4$
- Layer 0: $W_0(0) = 20$

The prover claims the output is 20.

**Round 0: Reducing Layer 0 to Layer 1**

The verifier picks $r_0 = 7$ (say). Recall from earlier that $\tilde{W}_0(u) = 20(1-u)$ (the MLE of the single output value 20). She computes:
$$V_0 = \tilde{W}_0(7) = 20(1-7) = -120$$

The sum to verify (by the GKR Lemma):
$$-120 = \sum_{b,c \in \{0,1\}} \widetilde{\text{mult}}_0(7, b, c) \cdot (\tilde{W}_1(b) \cdot \tilde{W}_1(c))$$

(The $\widetilde{\text{add}}_0$ term vanishes since layer 0 has no addition gates.)

The wiring predicate's MLE: Since $\text{mult}_0(0, 0, 1) = 1$ and is 0 elsewhere:
$$\widetilde{\text{mult}}_0(u, v, w) = (1-u)(1-v)w$$

At $u = 7$:
$$\widetilde{\text{mult}}_0(7, v, w) = (1-7)(1-v)w = -6(1-v)w$$

The sum becomes:
$$\sum_{b,c \in \{0,1\}} -6(1-b)c \cdot (\tilde{W}_1(b) \cdot \tilde{W}_1(c))$$

**Sum-check on this polynomial** proceeds for 2 rounds (one for $b$, one for $c$). The verifier sends random challenges after each round. Suppose these random challenges result in evaluation points $s_b = 3$ and $s_c = 5$; these are where the verifier needs to know $\tilde{W}_1$.

The prover claims:
$$\tilde{W}_1(s_b) = \tilde{W}_1(3) = 5 - 3 = 2, \quad \tilde{W}_1(s_c) = \tilde{W}_1(5) = 5 - 5 = 0$$

Now the verifier has two claims to verify. To reduce to one, she picks random $\alpha = 2$ and considers the line $\ell(t) = s_b + t(s_c - s_b) = 3 + 2t$ passing through $s_b$ (at $t=0$) and $s_c$ (at $t=1$). The prover sends the univariate polynomial $q(t) = \tilde{W}_1(\ell(t)) = 5 - (3 + 2t) = 2 - 2t$. The verifier checks:

- $q(0) = 2$ matches the claimed $\tilde{W}_1(s_b) = 2$ $\checkmark$
- $q(1) = 0$ matches the claimed $\tilde{W}_1(s_c) = 0$ $\checkmark$

The next round's claim becomes $r_1 = \ell(\alpha) = 3 + 2(2) = 7$ with value $V_1 = q(\alpha) = 2 - 2(2) = -2$.

**Round 1: Reducing Layer 1 to Layer 2**

The verifier now holds the claim: $\tilde{W}_1(7) = -2$.

Using the GKR Lemma for layer 1:
$$\tilde{W}_1(7) = \sum_{b,c \in \{0,1\}^2} \left[\widetilde{\text{add}}_1(7, b, c) \cdot (\tilde{W}_2(b) + \tilde{W}_2(c)) + \widetilde{\text{mult}}_1(7, b, c) \cdot (\tilde{W}_2(b) \cdot \tilde{W}_2(c))\right]$$

Another sum-check reduces this to claims about $\tilde{W}_2$ at random points.

**Final Check (Layer 2)**:

Eventually, the verifier holds a claim about $\tilde{W}_2(r_2)$ for some random $r_2$. She computes:
$$\tilde{W}_2(r_2) = 2(1-r_{2,1})(1-r_{2,2}) + 3(1-r_{2,1})r_{2,2} + 4 \cdot r_{2,1}(1-r_{2,2})$$

using the known inputs $x_1 = 2$, $x_2 = 3$, $x_3 = 4$. If this matches the prover's claim, she accepts.



## Why GKR Works

**Completeness**: If the prover is honest, all polynomials they send in sum-check are correct, and all claimed evaluations are accurate. Every check passes.

**Soundness**: Suppose the prover claims a wrong output. Then $\tilde{W}_0$ is incorrect. By the Layer Reduction Lemma, either:

- The sum-check protocol catches a lie (soundness of sum-check), or
- The prover's claimed values for layer 1 are inconsistent

The lie propagates backward through the layers. By induction, if the original claim is false, either some sum-check fails, or the final claim about the input layer is false (which the verifier catches by direct computation).

The soundness error is bounded by:
$$\epsilon \leq \frac{d \cdot \deg(f)}{|\mathbb{F}|}$$

where $d$ is the circuit depth and $\deg(f)$ is the degree of the sum-check polynomial.



## Efficiency Analysis

**Verifier's work**:

- For each layer, participate in a sum-check with $O(\log S)$ rounds (where $S$ is the layer size)
- Evaluate wiring predicates at random points (depends on circuit structure)
- Final check: compute $\tilde{W}_d(r_d)$ in time $O(n)$ where $n$ is the number of inputs

Total: $O(d \log S + n)$ for a depth-$d$ circuit with layers of size at most $S$.

For circuits with "regular" wiring (like FFT butterflies or matrix multiplication), evaluating wiring predicates takes $O(\log S)$ time. The verifier achieves **polylogarithmic verification** in the circuit size!

**Why structure is the holy grail.** If the circuit is random (spaghetti wiring), the verifier has to store the entire wiring diagram ($O(S)$ work), which defeats the purpose of succinctness. But if the circuit is *structured*, like a matrix multiplication where the same wiring pattern repeats thousands of times, the verifier doesn't need to read a massive list of wires. She can write a tiny loop that *generates* the wiring predicates on the fly. This data parallelism is what makes GKR efficient in practice. It is why modern provers like Lasso and Jolt are so fast: they treat computation not as a random circuit, but as a structured, repeating pattern.

**Prover's work**:

- Must compute the univariate polynomials for each sum-check round
- Requires summing over all gate values in each layer
- Total: $O(S \log S)$ where $S$ is the total number of gates

The prover does work linear in the circuit size: roughly the cost of evaluation itself, with logarithmic overhead.



## The Circuit Model: Power and Limitations

GKR works for any layered arithmetic circuit. This is remarkably general: any polynomial-time computation can be expressed as a polynomial-size arithmetic circuit.

**Why addition and multiplication suffice**: Over a finite field, these two operations generate all polynomial functions. And any Boolean function can be computed by polynomials: represent true as 1, false as 0, then AND becomes multiplication ($a \cdot b$), NOT becomes subtraction from 1 ($1 - a$), and OR follows from De Morgan ($1 - (1-a)(1-b)$). Since Boolean circuits are universal for computation (any Turing machine can be simulated), arithmetic circuits inherit this universality. The overhead is polynomial: a computation with $T$ steps and $S$ space becomes a circuit of size $O(T \cdot S)$.

**What circuits capture well**:

- Numerical computations (matrix operations, polynomial evaluation)
- Field arithmetic (cryptographic operations)
- Regular patterns (FFT, convolutions)

**Challenges**:

- Data-dependent control flow (if-then-else based on inputs) requires unrolling all branches
- Memory access patterns: Random access memory is expensive to arithmetize
- Bit operations: Non-arithmetic operations require special encoding

Chapter 8 will explore **arithmetization**, the art of expressing computations as circuits, in depth. We'll see how R1CS and QAP provide systematic ways to convert programs into the algebraic form that protocols like GKR can verify.



## The Bigger Picture

GKR represents a conceptual leap in verifiable computation. Instead of designing a custom protocol for each problem:

1. Express the computation as a circuit (a general, mechanical process)
2. Apply GKR (a universal verification protocol)
3. Achieve efficient verification (polylogarithmic in circuit size for regular circuits)

This modularity is powerful. The "frontend" (how to express a computation as a circuit) separates from the "backend" (how to verify circuit evaluation). Improvements to either benefit all applications.

But GKR as originally described is an **interactive** protocol. The prover and verifier exchange messages over multiple rounds. For practical applications (blockchain verification, privacy-preserving credentials) we want **non-interactive** proofs that anyone can verify without interaction.

Chapter 11 will show how to compile interactive protocols like GKR into non-interactive SNARKs using polynomial commitment schemes and the Fiat-Shamir transformation. The journey from sum-check to practical zero-knowledge proofs passes through GKR as a crucial waypoint.

**Is GKR actually used?** For years, GKR was primarily of theoretical interest; the prover overhead and circuit structure requirements made pairing-based SNARKs (Groth16, PLONK) more practical. But GKR is experiencing a resurgence. Modern systems like Lasso and Jolt use GKR-style sum-check reductions as their core verification mechanism, achieving state-of-the-art prover performance for certain computations.

The key insight is that GKR's prover is *native*, working directly with the computation's structure rather than reducing to generic polynomial arithmetic. To see why this matters, consider the alternative. In R1CS-based systems (Groth16, Spartan), every computation, no matter how structured, gets flattened into a uniform constraint system: thousands of equations of the form $a \cdot b = c$. A 256-bit multiplication, a hash function, a simple addition: all become rows in the same homogeneous matrix. The prover then does generic linear algebra over this matrix, blind to the original structure.

GKR is different. The prover traverses the actual circuit layer by layer, computing the sum-check polynomials from the wiring predicates and gate values directly. If your circuit has repeated structure, say 1000 copies of the same subcircuit, the prover can exploit that. If a layer is sparse (few gates), the work is proportionally smaller. The algorithm "sees" the computation's shape.

This becomes dramatic for certain operations. Lookup tables, for instance: proving "this value appears in that table" via R1CS requires encoding the entire table as constraints. GKR-based approaches (like Lasso) can instead prove lookups with work proportional to the number of lookups, not the table size. For memory operations, range checks, and other structured primitives, native provers can be orders of magnitude faster.

GKR is also transparent (no trusted setup) and plausibly post-quantum when instantiated with hash-based commitments. The protocol you've learned here isn't a historical curiosity; it's foundational to an active and growing family of proof systems.



## Key Takeaways

1. **GKR generalizes sum-check**: Instead of custom polynomials per problem, GKR handles any layered arithmetic circuit.

2. **Layer-by-layer reduction**: A claim about layer $i$'s output becomes a claim about layer $i+1$'s output, via sum-check.

3. **Wiring predicates encode structure**: The functions $\text{add}_i$ and $\text{mult}_i$ describe which gates connect to which (known to both prover and verifier).

4. **The Layer Reduction Lemma**: $\tilde{W}_i(z)$ equals a sum over products of wiring predicates and next-layer values (perfect for sum-check).

5. **Two claims become one**: Random linear combinations reduce checking two points to checking one, maintaining efficiency.

6. **Final check on inputs**: The chain of reductions terminates at the input layer, which the verifier can evaluate directly.

7. **Polylogarithmic verification**: For regular circuits, the verifier runs in time $O(d \log S + n)$ (exponentially faster than evaluating the circuit).

8. **Prover overhead is modest**: The prover works in time $O(S \log S)$, only logarithmically more than circuit evaluation.

9. **Circuits are universal**: Any polynomial-time computation has a polynomial-size circuit representation.

10. **GKR is interactive**: Achieving non-interactive proofs requires additional machinery (polynomial commitments, Fiat-Shamir), covered in later chapters.



\newpage

# Chapter 8: From Circuits to Polynomials

In 1931, Kurt Gödel shattered the foundations of mathematics. He proved that any formal system powerful enough to express arithmetic is "haunted": it contains true statements that cannot be proven. To establish this, Gödel had to solve a technical nightmare: how do you make math talk about itself?

His solution was Gödel numbering. He assigned a unique integer to every logical symbol ($+$, $=$, $\forall$), turning logical statements into integers and logical proofs into arithmetic relationships between those integers. He turned logic into arithmetic so that arithmetic could reason about logic.

What we do in zero-knowledge proofs is a direct descendant of Gödel's trick. We take the logic of a computer program (loops, jumps, variables) and map it into the rigid algebra of polynomials. This translation process is called **arithmetization**.

But the analogy goes deeper. Once computation is translated into algebra, the verification of that algebra becomes just another computation. And since we can translate any computation into polynomials, we can translate the verifier itself. This closes the loop. Just as Gödel used arithmetic to talk about arithmetic, arithmetization allows ZK proofs to verify ZK proofs. This self-referential capability (recursion) is what allows us to compress hours of computation into a millisecond check. It all starts here, with the translation of thought into number.



## Two Problems, Two Paradigms

Before diving in, we must distinguish two fundamentally different problems:

**Circuit Evaluation**: Given a circuit $C$ and input $x$, prove that $C(x) = y$.

The prover claims they computed the circuit correctly. The verifier could recompute it themselves, but the ZK system just makes verification faster. GKR handles this directly.

**Circuit Satisfiability**: Given a circuit $C$, public input $x$, and output $y$, prove there exists a secret witness $w$ such that $C(x, w) = y$.

The prover claims they *know* a secret input that makes the circuit output the desired value. They reveal nothing about this secret. This is the paradigm behind most real-world ZK applications, and it's what enables privacy.

Note that GKR (Chapter 7) natively handles circuit *evaluation*, not satisfiability: it proves "$C(x) = y$" for public inputs, with no secrets involved. To handle satisfiability, where the prover has a private witness, you need additional machinery: polynomial commitments that hide the witness values, combined with sum-check to verify the computation. Systems like Jolt use GKR-style sum-check reductions but wrap them with commitment schemes that provide zero-knowledge. The distinction matters: "GKR-based" doesn't mean "evaluation only"; it means the verification logic uses sum-check over layered structure, while commitments handle privacy.

**Example: Proving Knowledge of a Hash Preimage**

Suppose $y = \text{SHA256}(w)$ for some secret $w$. The prover wants to demonstrate they know $w$ without revealing it.

- The circuit $C$ implements SHA256
- The public input is (essentially) empty
- The public output is $y$ (the hash)
- The witness is $w$ (the secret preimage)

The prover demonstrates: "I know a value $w$ such that when I run SHA256 on it, I get exactly $y$." The verifier learns nothing about $w$ except that it exists.

This *satisfiability* paradigm underlies almost all practical ZK applications: proving password knowledge, transaction validity, computation integrity, and more.



## Understanding the Witness

The **witness** is central to zero-knowledge proofs. It's what separates a mere computation from a proof of knowledge.

### What Exactly Is a Witness?

A witness is a private input that, together with the public inputs, satisfies the circuit's constraints. In the equation $x^3 + x + 5 = 35$, the witness is $x = 3$. Anyone can verify that $3^3 + 3 + 5 = 35$, but the prover is demonstrating they *know* this solution.

More precisely, for a relation $R$, a witness $w$ for statement $x$ is a value such that $R(x, w) = 1$. The relation encodes the computational problem:

- **Hash preimage**: $R(y, w) = 1$ iff $\text{Hash}(w) = y$
- **Digital signature**: $R((m, \sigma, \text{pk}), \text{sk}) = 1$ iff $\text{Sign}(\text{sk}, m) = \sigma$
- **Sudoku solution**: $R(\text{puzzle}, \text{solution}) = 1$ iff the solution correctly fills the puzzle

**The Sudoku Analogy.** Think of a ZK proof as a solved Sudoku puzzle. The *circuit* is the rules of Sudoku: every row, column, and 3×3 square must contain the digits 1 through 9. The *public input* is the pre-filled numbers printed in the newspaper. The *witness* is the numbers you penciled in to solve it. Verifying the solution is easy: check the rows, columns, and squares (the constraints). You don't need to know the order in which the solver filled the numbers, nor the mental logic they used. You just check that the final grid (witness + public input) satisfies the rules.

### The Witness Vector Structure

In constraint systems like R1CS, the witness takes a specific form. The full **witness vector** $Z$ is a concatenation of three parts:

$$Z = \begin{pmatrix} 1 \\ \text{io} \\ W \end{pmatrix}$$

**The constant 1**: Always the first element. This allows encoding constant additions and multiplications easily. To constrain $x = 5$, we can write $x \times 1 = 5 \times 1$.

**The public inputs/outputs (io)**: Values the verifier already knows and agrees upon. For a hash preimage proof, this is the hash value $y$. For a transaction validity proof, this might include the transaction amount and recipient.

**The private witness (W)**: The secret values only the prover knows. This is what the prover is demonstrating knowledge of without revealing.

### A Concrete Example

For our equation $x^3 + x + 5 = 35$ with $x = 3$:

| Index | Value | Description |
|-------|-------|-------------|
| $Z_0$ | 1 | Constant |
| $Z_1$ | 35 | Public output |
| $Z_2$ | 3 | Private: $x$ |
| $Z_3$ | 9 | Private: $x^2$ |
| $Z_4$ | 27 | Private: $x^3$ |
| $Z_5$ | 30 | Private: $x^3 + x$ |
| $Z_6$ | 35 | Private: $x^3 + x + 5$ |

Notice that the witness includes not just the input $x$, but all intermediate values computed along the way. This is crucial: the constraint system checks that each step was performed correctly.



## The Execution Trace: Witness as Computation History

Modern arithmetization uses a clever insight: instead of building a circuit that *performs* the computation, we build a circuit that *verifies* a claimed execution trace.

### What Is an Execution Trace?

An **execution trace** is a complete record of a computation's execution: every instruction, every intermediate value, every memory access. Think of it as a detailed log file that captures everything that happened during the computation.

**The Key Insight**: Checking that a trace is *valid* is much easier than *producing* the computation.

Why? Because validity checking is *local*. To verify a trace, you only need to check that each step follows from the previous one according to the program's rules. You don't need to understand the whole program's logic, just that each individual transition is correct.

### A Brief Detour: How Computers Execute Programs

Before examining traces, we need a mental model of program execution. A computer at any moment has a **state**: the contents of its memory and a small set of fast storage locations called **registers**. Think of registers as the mathematician's scratch paper, a few variables (typically 8–32) that hold the values currently being manipulated. Memory is the larger workspace, addressed by integers: location 100, location 104, and so on.

The **program counter (PC)** is a special register that holds the address of the current instruction. Each instruction is an **opcode** (the operation: ADD, MUL, LOAD, STORE, JUMP) plus **operands** (which registers or memory addresses to use). Execution proceeds in a loop: fetch the instruction at the PC, execute it, update the PC (usually PC + 1, unless we jumped), repeat.

A LOAD instruction copies a value from memory into a register. A STORE does the reverse. Arithmetic opcodes like ADD or MUL operate on registers. A conditional jump like BEQ ("branch if equal") changes the PC based on a comparison; this is how loops and conditionals are implemented at the machine level.

The key insight for arithmetization: at each time step, the machine's entire state (registers, PC, memory) is just a tuple of field elements. Execution is a sequence of such tuples, and each transition is governed by simple local rules.

### Execution Trace Structure

A trace consists of rows, where each row represents the machine state at one time step:

| Step | PC | Opcode | Operands | Registers | Memory Reads | Memory Writes |
|------|----|---------|-----------|--------------------|--------------|---------------|
| 0 | 0 | LOAD | r1, [100] | r1=0, r2=0, r3=0 | [100]=42 | - |
| 1 | 1 | LOAD | r2, [104] | r1=42, r2=0, r3=0 | [104]=17 | - |
| 2 | 2 | MUL | r3, r1, r2 | r1=42, r2=17, r3=0 | - | - |
| 3 | 3 | STORE | r3, [108] | r1=42, r2=17, r3=714 | - | [108]=714 |

Each row includes:

- **Program Counter (PC)**: Which instruction we're executing
- **Opcode**: What operation is being performed
- **Operands**: Which registers/memory locations are involved
- **Register State**: The values of all registers
- **Memory Operations**: What was read from or written to memory

### The Circuit Doesn't Compute: It Verifies

Here's the paradigm shift: the circuit doesn't actually run the computation. It assumes the prover has already computed the trace (they have; they did the computation) and verifies that:

1. Each transition follows the correct rules
2. The trace starts with the correct initial state
3. The trace ends with the claimed output

The prover does the hard computational work. The circuit does the much easier work of checking consistency.



## What the Circuit Must Check

A trace verification circuit performs two categories of checks:

### Time Consistency (Transition Rules)

For every adjacent pair of rows $(S_t, S_{t+1})$, verify that the state transition follows from the instruction.

The idea is simple: given the current state and the instruction being executed, the next state is completely determined. If the trace claims the machine went from state $A$ to state $B$, we can check whether that transition is legal without needing to know anything about the states before or after.

**Example: Checking an ADD instruction**

If the opcode at step $t$ is ADD with operands r1, r2, r3:

- Check: $\text{PC}_{t+1} = \text{PC}_t + 1$ (we move to the next instruction)
- Check: $r3_{t+1} = r1_t + r2_t$ (the destination register gets the sum)
- Check: All other registers unchanged: $r1_{t+1} = r1_t$, $r2_{t+1} = r2_t$

**Example: Checking a conditional jump (BEQ r1, r2, label)**

- If $r1_t = r2_t$: Check $\text{PC}_{t+1} = \text{label}$ (branch taken)
- If $r1_t \neq r2_t$: Check $\text{PC}_{t+1} = \text{PC}_t + 1$ (branch not taken)
- Check: All registers unchanged

These checks are **local**: they only look at two adjacent rows. This locality is crucial: checking $n$ transitions requires $n$ independent checks, each involving only $O(1)$ values. The circuit applies the same transition-checking logic at every time step, making it uniform and amenable to polynomial encoding.

### Memory Consistency

This is trickier. A read at time $t$ might depend on a write from much earlier. The naive approach, searching backward through the trace for the most recent write, would be expensive.

**The Problem**: Time consistency is local: step $t+1$ depends only on step $t$. But memory breaks this locality. A read at step 1000 might retrieve a value written at step 3. The dependency spans nearly the entire trace.

Consider: step 0 writes value 42 to address 100. Steps 1 through 99 touch other addresses. Step 100 reads from address 100, and it should get 42. How do we check this without searching back through 100 steps?

**The Permutation Trick**:

The solution is to view the same data from a different angle. Imagine the memory operations as a deck of cards, each labeled with (address, time, operation, value). In the execution trace, these cards appear in time order, shuffled from the perspective of memory addresses. But we can *sort* the deck by address, grouping all operations on address 12 together, all operations on address 18 together, and so on.

Here's the insight: in the sorted view, operations on the same address are adjacent. Checking that a read returns the right value becomes a local check: just compare with the previous card in the sorted deck.

The protocol works as follows:

1. Extract all memory operations from the trace: `(address, time, operation, value)`

2. Create two lists:

   - **Time-ordered** (the original sequence of operations)
   - **Address-ordered** (sorted by address, then by time within each address)

3. Prove these lists are permutations of each other (same cards, different order). This uses polynomial fingerprinting: encode each list as a polynomial, and check they have the same "signature" at a random point.

4. In the address-ordered list, checking memory consistency is **local**: each read should match the value from the immediately preceding operation at that address.

**Worked Example**:

Time-ordered operations:
```
t=1: write(addr=18, val=7)
t=2: write(addr=12, val=5)
t=3: read(addr=18) → expects 7
t=4: write(addr=12, val=9)
```

Address-ordered (sorted first by address, then by time):
```
(addr=12, t=2, write, 5)
(addr=12, t=4, write, 9)
(addr=18, t=1, write, 7)
(addr=18, t=3, read, 7)  ← easy to check: matches the previous row at this address
```

In the address-ordered view, operations on the same address are consecutive. The read at $t=3$ for address 18 appears immediately after the write at $t=1$ for address 18. Checking correctness is just comparing adjacent rows, with no searching required.

The permutation check ensures the prover didn't fabricate operations or alter values when "sorting." The local consistency check on the sorted list verifies that memory behaves correctly. Together, they reduce a non-local problem to local checks plus a permutation argument.



## R1CS: The Constraint Language

How do we express these checks algebraically? The classic approach is **Rank-1 Constraint System (R1CS)**.

But first, a question: *why this particular algebraic form?*

The answer traces back to pairings. A bilinear map $e: \mathbb{G}_1 \times \mathbb{G}_2 \to \mathbb{G}_T$ has a remarkable property: it can check *one multiplication* "for free." Given commitments to $a$ and $b$, you can verify $a \cdot b = c$ with a single pairing equation. But pairings are expensive, so you want exactly one multiplication per constraint, no more.

This is why R1CS has its peculiar shape. The system was reverse-engineered from the verification equation: *what constraint format lets pairings check everything in one shot?* The answer is a product of two linear combinations.

An R1CS instance consists of:

- Three matrices $A, B, C$ of dimension $m \times n$
- A witness vector $Z$ of length $n$

The constraint is: for each row $i$,

$$(A_i \cdot Z) \times (B_i \cdot Z) = C_i \cdot Z$$

In words: (linear combination) × (linear combination) = (linear combination).

The matrices encode which wires participate in each constraint; the product structure is the algebraic shape that pairings can verify.

**Why is this form so expressive?** At first glance, "one multiplication per constraint" seems limiting. But here's the key insight: any computation can be broken into steps where each step involves at most one multiplication. Addition is free: you can add as many terms as you want on either side. The constraint $(a + b + c) \times (d + e) = f + g$ is a single R1CS row.

**Why is addition free?** In R1CS, linear combinations happen inside the matrix multiplication. $A \cdot Z$ computes a weighted sum of the witness variables. Since matrix-vector multiplication is just a series of additions, we can represent $a + b + c + d + \ldots$ in a single row of matrix $A$. We only "pay" (incur a constraint) when we need to multiply the result of matrix $A$ by the result of matrix $B$.

The trick is introducing intermediate variables. Suppose you need to compute $a \cdot b \cdot c$. You can't do this in one R1CS constraint (that would require two multiplications), but you can introduce a helper variable $t = a \cdot b$, then write:

- Constraint 1: $a \times b = t$
- Constraint 2: $t \times c = \text{result}$

Two constraints, each with one multiplication. This is the general pattern: any polynomial computation of degree $d$ can be flattened into $O(d)$ R1CS constraints by naming intermediate products. The witness grows to include these intermediate values, but that's fine since the prover knows them.

This decomposition is why R1CS can encode arbitrary arithmetic circuits. Every gate becomes one constraint. The "one multiplication" rule isn't a limitation; it's a *normal form* that any computation can be converted into.

### Basic Gates in R1CS

**Multiplication** ($a \cdot b = c$):

- Row $i$ of $A$ selects $a$ from $Z$
- Row $i$ of $B$ selects $b$ from $Z$
- Row $i$ of $C$ selects $c$ from $Z$
- Constraint: $a \times b = c$

**Addition** ($a + b = c$):

- Set $B$ to select the constant 1
- Row $i$ of $A$ selects both $a$ and $b$ (with coefficients 1, 1)
- Row $i$ of $C$ selects $c$
- Constraint: $(a + b) \times 1 = c$

**Constant multiplication** ($k \cdot a = c$):

- Row $i$ of $A$ selects $a$
- Row $i$ of $B$ selects constant $k$ (or encode $k$ in $A$)
- Row $i$ of $C$ selects $c$



## Worked Example: $x^3 + x + 5 = 35$

Let's arithmetize a complete example. The prover claims to know $x$ such that $x^3 + x + 5 = 35$. (The secret is $x = 3$.)

### Step 1: Flatten to Basic Operations

Break the computation into primitive gates:

```
v1 = x * x        (compute x²)
v2 = v1 * x       (compute x³)
v3 = v2 + x       (compute x³ + x)
v4 = v3 + 5       (compute x³ + x + 5)
assert: v4 = 35   (check the result)
```

### Step 2: Define the Witness Vector

The witness contains:

- The constant 1 (always included)
- The public output 35
- The secret input $x$
- All intermediate values

$$Z = (1, \; 35, \; x, \; v_1, \; v_2, \; v_3, \; v_4)$$

With $x = 3$:
$$Z = (1, \; 35, \; 3, \; 9, \; 27, \; 30, \; 35)$$

### Step 3: Build the Constraint Matrices

Each gate becomes a row in the matrices:

**Gate 1**: $v_1 = x \cdot x$

- $A_1 = (0, 0, 1, 0, 0, 0, 0)$: selects $x$
- $B_1 = (0, 0, 1, 0, 0, 0, 0)$: selects $x$
- $C_1 = (0, 0, 0, 1, 0, 0, 0)$: selects $v_1$

Check: $(A_1 \cdot Z) \times (B_1 \cdot Z) = 3 \times 3 = 9 = C_1 \cdot Z$

**Gate 2**: $v_2 = v_1 \cdot x$

- $A_2 = (0, 0, 0, 1, 0, 0, 0)$: selects $v_1$
- $B_2 = (0, 0, 1, 0, 0, 0, 0)$: selects $x$
- $C_2 = (0, 0, 0, 0, 1, 0, 0)$: selects $v_2$

Check: $9 \times 3 = 27$

**Gate 3**: $v_3 = v_2 + x$

For addition, we use the trick: $(v_2 + x) \times 1 = v_3$

- $A_3 = (0, 0, 1, 0, 1, 0, 0)$: selects $v_2 + x$
- $B_3 = (1, 0, 0, 0, 0, 0, 0)$: selects constant 1
- $C_3 = (0, 0, 0, 0, 0, 1, 0)$: selects $v_3$

Check: $(27 + 3) \times 1 = 30$

**Gate 4**: $v_4 = v_3 + 5$

- $A_4 = (5, 0, 0, 0, 0, 1, 0)$: selects $5 \cdot 1 + v_3$
- $B_4 = (1, 0, 0, 0, 0, 0, 0)$: selects 1
- $C_4 = (0, 0, 0, 0, 0, 0, 1)$: selects $v_4$

Check: $(5 + 30) \times 1 = 35$

**Gate 5**: $v_4 = 35$ (the public output constraint)

- $A_5 = (0, 0, 0, 0, 0, 0, 1)$: selects $v_4$
- $B_5 = (1, 0, 0, 0, 0, 0, 0)$: selects 1
- $C_5 = (0, 35, 0, 0, 0, 0, 0)$: selects $35 \cdot 1$

Check: $35 \times 1 = 35$

All five constraints are satisfied. The R1CS captures the entire computation.



## Two Ways to Prove R1CS

Once we have R1CS constraints, how do we prove they're all satisfied? There are two major approaches.

### Approach 1: QAP (Quadratic Arithmetic Program)

**Historical context**: QAP was introduced by Gennaro, Gentry, Parno, and Rabin in the **Pinocchio** system (2013), one of the first practical SNARKs. Groth16 (2016) refined and optimized this approach, achieving the smallest proof size known for pairing-based systems. Today, QAP is primarily associated with Groth16. Modern systems have moved to other arithmetizations (PLONKish, AIR, sum-check), but QAP remains important for applications where proof size is paramount.

**The Key Idea**: Instead of checking $m$ separate constraints, check one polynomial divisibility.

For each column $j$ of the R1CS matrices, define polynomials $A_j(X), B_j(X), C_j(X)$ that interpolate the column values at points $\{1, 2, \ldots, m\}$. (So $A_j(i)$ equals the entry in row $i$, column $j$ of matrix $A$.)

Now let $\vec{Z} = (Z_0, Z_1, \ldots, Z_n)$ be the **witness vector**, the full assignment including the constant 1, public inputs, and private witness values. Define:
$$A(X) = \sum_j Z_j \cdot A_j(X), \quad B(X) = \sum_j Z_j \cdot B_j(X), \quad C(X) = \sum_j Z_j \cdot C_j(X)$$

Each $Z_j$ is a scalar (from the witness), while $A_j(X)$ is a polynomial. The sum computes a linear combination, exactly mirroring how R1CS constraints are matrix-vector products.

The R1CS is satisfied iff $A(X) \cdot B(X) - C(X) = 0$ at all constraint points $\{1, 2, \ldots, m\}$.

By the Factor Theorem, this means the vanishing polynomial $Z_H(X) = (X-1)(X-2)\cdots(X-m)$ divides $A(X) \cdot B(X) - C(X)$.

**The QAP Check**: Prover exhibits quotient $H(X)$ such that:
$$A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$$

We develop QAP fully in Chapter 12, where Groth16 uses it to achieve the smallest possible pairing-based proofs.

### Approach 2: Sum-Check on Multilinear Extensions (Spartan)

**Historical context**: Spartan was introduced by Setty in 2019, reviving ideas from the GKR protocol (2008) and sum-check literature. While Groth16 uses univariate polynomials and FFTs, Spartan showed that **multilinear extensions** and the **sum-check protocol** could handle R1CS directly, without Lagrange interpolation, without roots of unity, and with optimal prover time. This "sum-check renaissance" led to systems like Lasso, Jolt, and HyperNova.

**The Core Insight**: R1CS constraint satisfaction can be expressed as a polynomial sum equaling zero:

$$\sum_{x \in \{0,1\}^k} \tilde{\text{eq}}(x) \cdot \left[\tilde{A}(x) \cdot \tilde{B}(x) - \tilde{C}(x)\right] = 0$$

where $\tilde{A}(x) = \sum_{y \in \{0,1\}^k} \tilde{A}_{\text{matrix}}(x, y) \cdot \tilde{Z}(y)$ is the MLE of the matrix-vector product.

**Why This Matters**:

1. **Time-optimal proving**: The prover's work is $O(N)$ where $N$ is the number of constraints, just reading the constraints, no FFTs.

2. **Sparsity-preserving**: Multilinear extensions preserve the structure of sparse matrices. In R1CS, most matrix entries are zero. The MLE directly reflects this sparsity.

3. **Natural fit with sum-check**: The sum-check protocol (Chapter 3) is designed exactly for this type of problem.

**Comparing QAP and Spartan**:

| Property | QAP (Groth16) | Spartan |
|----------|---------------|---------|
| Polynomial type | Univariate, high-degree | Multilinear |
| Core technique | Divisibility by $Z_H(X)$ | Sum-check |
| Prover time | $O(N \log N)$ | $O(N)$ |
| Setup | Circuit-specific trusted | Transparent |

**When to use each**:

- **Groth16 (QAP)**: When proof size is the dominant constraint. On-chain verification on Ethereum costs gas proportional to proof size, making Groth16's 128-byte proofs attractive despite the circuit-specific setup. Use when your circuit is stable and you can afford a trusted ceremony.

- **Spartan / sum-check systems**: When prover time matters most. The $O(N)$ prover (vs $O(N \log N)$ for FFT-based systems) becomes significant at scale. Transparent setup avoids trust assumptions entirely. Natural fit for recursive composition and folding schemes (Nova, HyperNova). The tradeoff: larger proofs and more expensive verification.



## PLONKish Arithmetization

R1CS isn't the only way to encode computations. **PLONKish** takes a fundamentally different approach, one that's become so influential it dominates modern ZK applications.

**Historical context**: PLONK (Permutations over Lagrange-bases for Oecumenical Noninteractive arguments of Knowledge) was introduced by Gabizon, Williamson, and Ciobotaru in 2019. It addressed Groth16's main limitation, circuit-specific trusted setup, by providing a **universal** setup: one ceremony works for any circuit up to a given size. PLONK spawned a family of "PLONKish" systems (Halo 2, Plonky2, HyperPlonk) that now power most production ZK applications.

### The Universal Gate Equation

PLONK's core innovation is a single standardized gate equation:

$$Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot a \cdot b + Q_C = 0$$

The $Q$ values are **selectors**, public constants that "program" each gate.

**Addition gate** ($a + b = c$): Set $Q_L = 1, Q_R = 1, Q_O = -1$, rest zero.

**Multiplication gate** ($a \cdot b = c$): Set $Q_M = 1, Q_O = -1$, rest zero.

**Public input** ($a = k$): Set $Q_L = 1, Q_C = -k$, rest zero.

The same equation handles all gate types!

### Copy Constraints: The Permutation Argument

PLONK's gate equation only relates wires *within* a single gate. It doesn't enforce that the output of gate 1 feeds into the input of gate 5.

This is where the **permutation argument** enters. The circuit's wiring defines a permutation $\sigma$ on wire positions. Copy constraints are satisfied if:

$$\text{value at position } i = \text{value at position } \sigma(i)$$

PLONK proves this via a grand product check: with random challenges $\beta, \gamma$, verify:

$$\prod_i \frac{f(i) + \beta \cdot i + \gamma}{f(i) + \beta \cdot \sigma(i) + \gamma} = 1$$

If copy constraints hold, corresponding terms cancel. A mismatch disrupts the product.

### When to Use PLONKish

PLONKish shines when you need **flexibility without sacrificing succinctness**:

- **Universal setup**: One ceremony covers all circuits up to a size bound, so you can deploy new circuits without new ceremonies
- **Custom gates**: Optimize specific operations (hash functions, range checks, elliptic curve arithmetic)
- **Mature tooling**: The PLONKish ecosystem (Halo 2, Plonky2) offers production-ready implementations

The tradeoff versus Groth16: slightly larger proofs (~2-3x), but no circuit-specific ceremony.



## AIR: Algebraic Intermediate Representation

A third constraint format takes yet another path, designed specifically for computations with **repetitive structure**: state machines, virtual machines, and iterative algorithms.

An AIR consists of:

- **Execution trace**: A table where each row represents a "state" and columns hold state variables
- **Transition constraints**: Polynomials that relate row $i$ to row $i+1$ (the local rules)
- **Boundary constraints**: Conditions on specific rows (initial state, final state)

The insight: many computations are naturally described as "apply the same transition rule repeatedly." A CPU executes instructions in a loop. A hash function applies the same round function many times. AIR captures this by encoding the transition rule once and proving it holds for all consecutive row pairs.

**Example**: A simple counter that increments by 1:

- Transition constraint: $s_{i+1} - s_i - 1 = 0$
- Boundary constraint: $s_0 = 0$ (start at zero)

This single transition constraint, applied to $n$ rows, proves correct execution of $n$ steps.

AIR is the native format for **STARKs**, which we develop fully in **Chapter 15**. The combination of AIR's repetitive structure with FRI's hash-based commitments yields transparent, plausibly post-quantum proofs.

### Comparing the Three Formats

| Property | R1CS | PLONKish | AIR |
|----------|------|----------|-----|
| Structure | Sparse matrices | Gates + selectors | Execution trace + transitions |
| Gate flexibility | One mult/constraint | Custom gates | Transition polynomials |
| Best for | Simple circuits | Complex, irregular ops | Repetitive state machines |
| Used by | Groth16, Spartan | PLONK, Halo 2 | STARKs, Cairo |

In practice:

- **R1CS + Groth16**: When proof size dominates (on-chain verification)
- **PLONKish**: When you need flexibility and universal setup
- **AIR + STARKs**: When transparency and post-quantum security matter



## CCS: Unifying the Constraint Formats

We now have three constraint formats (R1CS, PLONKish, AIR) each with distinct strengths. But this proliferation creates fragmentation: tools, optimizations, and folding schemes must be reimplemented for each format.

**Why CCS? The Folding Era.** You might wonder why we need yet another format when we have R1CS and PLONK. The answer is folding (Chapter 21). Newer protocols like Nova and HyperNova work by "folding" two proof instances into one. It turns out that R1CS folds easily, but PLONKish constraints do not. CCS was invented to give us the best of both worlds: the expressiveness of PLONK's custom gates with the foldability of R1CS's matrix structure.

**CCS (Customizable Constraint Systems)** provides a unifying abstraction that captures all three formats without overhead.

### The CCS Framework

A CCS instance consists of:

- **Matrices** $M_1, \ldots, M_t$: sparse matrices over $\mathbb{F}$, encoding constraint structure
- **Constraint specifications**: which matrices combine in each constraint, with what operation

The key insight: any constraint system can be expressed as:

$$\sum_i c_i \cdot \bigcirc_{j \in S_i} M_j \cdot z = 0$$

where:

- $z$ is the witness vector (including public inputs and the constant 1)
- $S_i$ specifies which matrices participate in term $i$
- $\bigcirc$ is the Hadamard (element-wise) product
- $c_i$ are scalar coefficients

**Reading this formula**: Each term $i$ in the sum works as follows:

1. Take some subset of matrices $\{M_j : j \in S_i\}$
2. Multiply each matrix by the witness vector $z$, getting vectors $M_j \cdot z$
3. Hadamard-multiply these vectors together (element-wise): $\bigcirc_{j \in S_i} (M_j \cdot z)$
4. Scale the result by coefficient $c_i$

The constraint is satisfied when all these terms sum to zero.

**Why Hadamard products?** The Hadamard product is what lets CCS express multiplication. In R1CS, the constraint $(A \cdot z) \circ (B \cdot z) = C \cdot z$ involves multiplying two linear combinations element-wise, which is a Hadamard product. In PLONKish, the term $Q_M \cdot a \cdot b$ multiplies wire values, again element-wise across all gates. The Hadamard product is the "multiplication primitive" that CCS builds from.

**Why this generalizes everything**: The formula is a sum of scaled Hadamard products of matrix-vector products. This captures:

- **Linear constraints**: Use a single matrix in $S_i$ (no Hadamard needed)
- **Quadratic constraints**: Hadamard-multiply two matrix-vector products
- **Higher-degree constraints**: Hadamard-multiply more matrices
- **Multiple constraint types**: Different terms $i$ can have different structures

### Recovering Standard Formats

**R1CS as CCS:**

- Three matrices: $M_1 = A$, $M_2 = B$, $M_3 = C$
- Two terms: $S_1 = \{1, 2\}$ (Hadamard of $A$ and $B$), $S_2 = \{3\}$ (just $C$)
- Coefficients: $c_1 = 1$, $c_2 = -1$

The CCS formula becomes:
$$1 \cdot \big((M_1 \cdot z) \circ (M_2 \cdot z)\big) + (-1) \cdot (M_3 \cdot z) = 0$$

which is exactly $(A \cdot z) \circ (B \cdot z) - C \cdot z = 0$, the R1CS equation.

**PLONKish as CCS:**

The PLONK gate equation $Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot a \cdot b + Q_C = 0$ becomes:

- Matrices: $M_a$ (selects wire $a$), $M_b$ (selects wire $b$), $M_c$ (selects wire $c$), $M_{Q_L}$ (selector), $M_{Q_R}$, $M_{Q_O}$, $M_{Q_M}$, $M_{Q_C}$
- Terms map to the gate equation:
  - $Q_L \cdot a$: Hadamard of selector and wire → $S_1 = \{Q_L, a\}$
  - $Q_M \cdot a \cdot b$: Hadamard of three matrices → $S_2 = \{Q_M, a, b\}$
  - ...and so on for each term

The CCS formula becomes:
$$1 \cdot (M_{Q_L} \cdot z) \circ (M_a \cdot z) + 1 \cdot (M_{Q_R} \cdot z) \circ (M_b \cdot z) + \ldots = 0$$

Each term in PLONK's gate equation maps to one term in the CCS sum.

**AIR as CCS:**

A transition constraint like $s_{i+1} = 2 \cdot s_i + 1$ becomes:

- Matrices: $M_{\text{curr}}$ (extracts current-row values), $M_{\text{next}}$ (extracts next-row values), $M_{\text{const}}$ (constant column)
- The constraint $s' - 2s - 1 = 0$ becomes:

$$1 \cdot (M_{\text{next}} \cdot z) + (-2) \cdot (M_{\text{curr}} \cdot z) + (-1) \cdot (M_{\text{const}} \cdot z) = 0$$

Here all terms have $|S_i| = 1$ (no Hadamard products), so the constraint is purely linear in state variables. Quadratic AIR constraints (like $s' = s^2$) would use Hadamard: $(M_{\text{next}} \cdot z) - (M_{\text{curr}} \cdot z) \circ (M_{\text{curr}} \cdot z) = 0$.

### Why CCS Matters

**1. Unified tooling.** Compilers, analyzers, and optimizers can target CCS once. The specific frontend (Circom, Cairo, Noir) produces CCS; the backend (Spartan, Nova, HyperNova) consumes it.

**2. Folding scheme compatibility.** HyperNova folds CCS instances directly. Any constraint format expressible as CCS inherits folding for free, with no separate construction needed.

**3. Format-agnostic optimization.** Matrix sparsity, constraint reordering, and parallel proving apply uniformly regardless of the original constraint format.

**4. Research unification.** Theoretical results about CCS apply to all formats it subsumes.

### CCS in Practice

Modern systems increasingly use CCS as their internal representation:

- **HyperNova**: Folds CCS directly, achieving the benefits of PLONK's flexibility with Nova's efficiency
- **Sonobe**: A folding framework that targets CCS
- **Research prototypes**: Use CCS for cleaner proofs of concept

The constraint format ecosystem is consolidating. R1CS, PLONKish, and AIR remain useful surface-level abstractions, but CCS provides the common substrate beneath.



## Handling Non-Arithmetic Operations

Real programs use operations that aren't native to field arithmetic: comparisons, bitwise operations, conditionals, hash functions. These require careful encoding, and this is where constraint counts explode.

### Bit Decomposition: The Fundamental Technique

The standard technique: represent an integer $a$ as bits $(a_0, a_1, \ldots, a_{W-1})$.

**Enforce "bitness"**: Each $a_i$ must satisfy $a_i \cdot (a_i - 1) = 0$. This polynomial is zero iff $a_i \in \{0, 1\}$.

Why? If $a_i = 0$: $0 \cdot (0-1) = 0$ (satisfied).
If $a_i = 1$: $1 \cdot (1-1) = 0$ (satisfied).
If $a_i = 2$: $2 \cdot (2-1) = 2 \neq 0$ (fails).

**Reconstruct the value**: Verify $a = \sum_{i=0}^{W-1} a_i \cdot 2^i$.

### Constraint Costs: A Reality Check

Here's where things get expensive. Let's count constraints for common operations:

| Operation | Constraints | Notes |
|-----------|-------------|-------|
| Field addition | 0 | Free! Just combine wires |
| Field multiplication | 1 | Native R1CS operation |
| 64-bit decomposition | 64 | One per bit (bitness check) |
| 64-bit reconstruction | 1 | Sum with powers of 2 |
| 64-bit AND | ~130 | Decompose both, multiply bits, reconstruct |
| 64-bit XOR | ~130 | Decompose both, compute XOR per bit |
| 64-bit comparison | ~200 | Decompose, subtract, check sign bit |
| 64-bit range proof | ~65 | Decompose + bitness checks |
| SHA256 hash | ~20,000 | Many bitwise operations |
| Poseidon hash | ~250 | Field-native design |

**The Takeaway**: Bitwise operations are roughly 100x more expensive than field operations. This is why:

- ZK-friendly hash functions (Poseidon, Rescue) exist because they avoid bit operations
- zkVMs are expensive because they must handle arbitrary CPU instructions
- Custom circuits beat general-purpose approaches for specific computations

### Simulating Logic Gates

With bits exposed, we can simulate Boolean logic:

**AND** ($c = a \land b$): For each bit position $i$:
$$c_i = a_i \cdot b_i$$
Cost: 1 multiplication constraint per bit

**OR** ($c = a \lor b$): For each bit position $i$:
$$c_i = a_i + b_i - a_i \cdot b_i$$
Cost: 1 multiplication constraint per bit

**XOR** ($c = a \oplus b$): For each bit position $i$:
$$c_i = a_i + b_i - 2 \cdot a_i \cdot b_i$$
Cost: 1 multiplication constraint per bit

**NOT** ($c = \lnot a$): For each bit position $i$:
$$c_i = 1 - a_i$$
Cost: 0 (just linear combination)

### Range Proofs: Proving $a < 2^k$

To prove a value is within a range $[0, 2^k)$:

1. Decompose into $k$ bits
2. Check each bit satisfies $b_i(b_i - 1) = 0$
3. Verify reconstruction: $a = \sum_{i=0}^{k-1} b_i \cdot 2^i$

Cost: $k$ bitness constraints + 1 reconstruction constraint

### Comparison: Proving $a < b$

To prove $a < b$ for values in range $[0, 2^k)$:

**Approach 1: Subtraction with underflow**

1. Compute $d = b - a + 2^k$ (shifted to avoid underflow)
2. Decompose $d$ into $k+1$ bits
3. Check the most significant bit equals 1 (meaning $b - a \geq 0$, so $b > a$)

Cost: ~$k+1$ constraints for bit decomposition + bitness checks

**Approach 2: Lexicographic comparison**

1. Decompose both $a$ and $b$ into bits
2. Starting from the MSB, find the first position where they differ
3. At that position, check $a_i = 0$ and $b_i = 1$

Cost: More complex, often not better for general comparisons

The pattern is clear: anything involving bits is expensive. For years, circuit designers accepted this cost as unavoidable, until lookup arguments changed everything.



## Lookup Tables: The Modern Approach

Lookup arguments represent the most significant optimization technique in modern ZK systems. They sidestep bit decomposition entirely by replacing computation with table membership.

### The Core Idea

Instead of proving *how* you computed a result, prove *that* the result appears in a precomputed table.

**Example**: To prove XOR of two 8-bit values:

**Traditional approach** (bit decomposition):

1. Decompose both inputs into 8 bits each (16 bitness constraints)
2. Compute XOR per bit: $c_i = a_i + b_i - 2a_i b_i$ (8 multiplication constraints)
3. Reconstruct output (1 constraint)
4. Total: ~25 constraints

**Lookup approach**:

1. Precompute a table of all $256 \times 256 = 65,536$ XOR results: $(a, b, a \oplus b)$
2. Prove the triple $(a, b, c)$ appears in this table
3. Total: ~3 constraints (regardless of operation complexity!)

The savings compound. A 64-bit XOR via bit decomposition costs ~130 constraints. Via lookups on 8-bit chunks: 8 lookups × 3 constraints = 24 constraints, a 5x improvement.

### Why This Isn't Crazy

At first glance, "prove membership in a 65,536-entry table" sounds worse than bit decomposition. Checking 65,536 possibilities naively would be astronomical. The key insight is that we don't check membership directly; we use *polynomial identity testing*.

The table becomes a polynomial. If $T = [t_1, \ldots, t_N]$, encode it as:
$$T(X) = \prod_{i=1}^{N} (X - t_i)$$

A value $v$ is in the table if and only if $T(v) = 0$. But evaluating this polynomial at a random point, or checking divisibility relationships between polynomials, costs $O(\log N)$ work, not $O(N)$.

The magic: polynomials let you reason about *all* table entries simultaneously via a single random evaluation. A table of size $2^{16}$ doesn't require $2^{16}$ checks; it requires one polynomial identity that holds only if every lookup is valid. The Schwartz-Zippel lemma guarantees that a cheating prover gets caught with overwhelming probability.

This is the same principle underlying all polynomial-based SNARKs: compress exponentially many checks into a constant number of random evaluations. Lookups are just a particularly clean application of this principle.

### How Lookup Arguments Work

The prover has a table $T = [t_1, t_2, \ldots, t_N]$ and claims that values $f_1, \ldots, f_m$ all appear in $T$.

**Plookup** (2020, Gabizon and Williamson): Uses a grand product argument. Sort the lookup values and table together, then check that adjacent elements satisfy a relationship that's only possible if every lookup value came from the table.

**LogUp** (2022, Haböck): Reformulates the product check as a sum of logarithmic derivatives:
$$\sum_i \frac{1}{X - f_i} = \sum_j \frac{m_j}{X - t_j}$$
where $m_j$ is the multiplicity of table element $t_j$ among the lookups. This is more efficient for tables with repeated accesses.

**Lasso** (2023, Setty et al.): Combines lookups with sum-check, achieving prover time proportional to the number of lookups rather than the table size. This enables tables of size $2^{128}$ or larger, covering operations like full 64-bit multiplication in a single lookup.

### What Lookups Enable

**Range proofs without bit decomposition**: A table $[0, 1, 2, \ldots, 2^{16}-1]$ proves 16-bit range with one lookup instead of 16 bitness constraints.

**Efficient hash functions**: Even non-ZK-friendly hashes become tractable. SHA-256's bitwise operations can be replaced by table lookups on chunks.

**zkVMs at scale**: Systems like Jolt prove CPU instruction execution via lookups. Each instruction (ADD, XOR, MUL, etc.) becomes a table lookup. The instruction's semantics are "baked into" the table; the circuit just checks membership.

**Memory operations**: Read-write memory can be verified via sorted lookup arguments, proving that memory accesses are consistent without encoding RAM semantics in constraints.

### The Lookup Landscape

| Protocol | Prover Cost | Table Size Limit | Best For |
|----------|-------------|------------------|----------|
| Plookup | $O(N \log N)$ | ~$2^{20}$ | Moderate tables, PLONKish |
| LogUp | $O(N \log N)$ | ~$2^{20}$ | Repeated accesses |
| Lasso | $O(m \log m)$ | ~$2^{128}$ | Huge tables, zkVMs |

Here $N$ is the circuit size and $m$ is the number of lookups.

### Design Implications

Lookups shift circuit design philosophy:

**Before lookups**: Minimize bit operations. Use ZK-friendly primitives. Accept that some operations are inherently expensive.

**After lookups**: Think in terms of table design. Any function with a reasonable domain can become a lookup. The question becomes: what's the optimal table decomposition?

For a 64-bit operation, you might:

- Use 8 lookups into $2^{16}$-entry tables (8-bit chunks, twice per operand)
- Use 4 lookups into $2^{32}$-entry tables (16-bit chunks)
- Use 1 lookup into a $2^{128}$-entry virtual table (Lasso-style)

The optimal choice depends on table construction costs, lookup argument efficiency, and memory constraints.



## The Frontend/Backend Split

This chapter describes **frontends**, compilers that transform high-level programs into arithmetic form. The **backend** is the proof system (GKR, Groth16, PLONK, STARKs) that proves the resulting constraints.

**CPU-style frontends** (Cairo, RISC-Zero, SP1, Jolt):

- Define a virtual machine with a fixed instruction set
- Any program compiles to that instruction set
- The arithmetization verifies instruction execution
- General-purpose but with overhead

**ASIC-style frontends** (Circom, custom circuits):

- Create a specialized circuit for each specific program
- Maximum efficiency for fixed computations
- Poor for general-purpose or data-dependent control flow

**Hybrid approaches**:

- Use custom circuits for the common case
- Fall back to general VM for edge cases
- Example: Specialized hash circuit + general VM for the rest

The choice depends on your use case. Verifying a hash? A custom circuit is fastest. Running arbitrary computation? You need a zkVM. Running the same computation millions of times? The circuit development cost is amortized.



## The Big Picture

We've traced the path from programs to proofs:

1. **Program** → A computation we want to prove

2. **Execution trace** → The witness, capturing every intermediate state (registers, memory, etc.)

3. **Constraint system** → Algebraic rules the trace must satisfy:

   - R1CS: $(A \cdot Z) \circ (B \cdot Z) = C \cdot Z$
   - PLONK: Universal gate + permutation
   - AIR: Transition polynomials (STARKs)

4. **Polynomial representation** → The constraints become polynomial identities:

   - QAP: Divisibility by vanishing polynomial
   - Sum-check: Sum over hypercube equals zero
   - PIOP: Polynomial oracle proofs

5. **Proof system** → Polynomial commitments + algebraic checks verify the identity

Arithmetization is the bridge between computation and algebra. It's where computer science meets cryptography, and where clever encoding can save orders of magnitude in proof cost.



## Key Takeaways

1. **Circuit satisfiability vs. evaluation**: Most applications prove knowledge of a secret witness, not just correct evaluation.

2. **The witness is everything**: It's the complete set of values (public, private, and intermediate) that satisfies the constraints.

3. **Execution trace as witness**: The prover records their entire computation; the circuit verifies the recording.

4. **Time and memory consistency**: The trace must follow transition rules (local checks) and memory rules (permutation checks).

5. **R1CS**: Expresses constraints as $(A \cdot Z) \times (B \cdot Z) = C \cdot Z$. Universal but can be verbose.

6. **Three constraint formats**: R1CS (sparse matrices), PLONKish (gates + selectors), AIR (transition constraints). CCS unifies them all.

7. **Bit decomposition is expensive**: A 64-bit operation costs ~65-200 constraints via traditional encoding.

8. **Lookup arguments changed everything**: Plookup, LogUp, and Lasso replace expensive bit operations with cheap table membership proofs, enabling efficient zkVMs and non-ZK-friendly operations.

9. **Frontend/backend split**: Frontends handle arithmetization; backends handle proving. They can be mixed and matched.

10. **Constraint cost guides design**: Choose field-friendly operations (hashes, curves) over bit-heavy operations.



\newpage

# Chapter 9: Polynomial Commitment Schemes: The Cryptographic Engine

In 2016, six people met in a hotel room to birth the Zcash privacy protocol. Their task: generate a cryptographic secret so dangerous that if even one of them kept a copy, it could forge unlimited fake coins, undetectable forever. They called it "toxic waste."

The ceremony was a paranoid ballet. Participants were scattered across the globe, connected by encrypted channels. One flew to an undisclosed location, computed on an air-gapped laptop, then incinerated the machine and its hard drive. Another broadcast their participation live so viewers could verify no one was coercing them. The randomness they generated was combined through multi-party computation, ensuring that if *any single participant* destroyed their secret, the final parameters would be safe.

Why such extreme measures? Because polynomial commitment schemes, the cryptographic engine that makes SNARKs work, sometimes require a *structured reference string*: public parameters computed from a secret that must then cease to exist. The Zcash ceremony became legendary in cryptography circles, part security protocol, part performance art. It demonstrated both the power and the peril of pairing-based commitments.

This chapter explores that peril and its alternatives. We'll see three approaches to polynomial commitments: **KZG**, which achieves constant-size proofs at the cost of trusted setup; **IPA/Bulletproofs**, which eliminates the toxic waste but pays with linear verification; and **Dory**, which threads the needle with logarithmic verification and no trusted setup. Each represents a different answer to the same question: how do you prove facts about a polynomial without revealing it?

---

Everything we've built (sum-check, GKR, arithmetization) reduces complex claims to polynomial identities. A prover claims that polynomial $p(X)$ has certain properties: it equals another polynomial, it vanishes on a domain, it evaluates to a specific value at a point.

But here's the catch: verifying these claims directly would require the verifier to see the entire polynomial. For a polynomial of degree $n$, that's $n+1$ coefficients, exactly as much data as the original computation. We've achieved nothing.

**Polynomial Commitment Schemes (PCS)** solve this problem. A PCS allows a prover to commit to a polynomial with a short commitment, then later prove claims about the polynomial (its evaluations at specific points) without revealing the polynomial itself. The commitment is binding (the prover can't change the polynomial), and the proofs are succinct (much smaller than the polynomial).

This is where abstract algebra meets cryptography. This chapter explores two fundamental approaches: **KZG** (using pairings) and **IPA/Bulletproofs** (using discrete logarithms).



## The PCS Abstraction

A polynomial commitment scheme consists of three algorithms:

**Commit $(f) \to C$**: Given a polynomial $f(X)$, produce a short commitment $C$.

**Open $(f, z) \to (v, \pi)$**: Given the polynomial $f$, a point $z$, compute the evaluation $v = f(z)$ and a proof $\pi$ that this evaluation is correct.

**Verify $(C, z, v, \pi) \to \{\text{accept}, \text{reject}\}$**: Given the commitment, point, claimed value, and proof, check correctness.

**Properties**:

- **Binding**: A commitment $C$ can only be opened to evaluations consistent with *one* polynomial (computationally)
- **Hiding** (optional): The commitment reveals nothing about the polynomial
- **Succinctness**: Commitments and proofs are much smaller than the polynomial

The key insight: if the prover is bound to a specific polynomial before seeing the verifier's challenge point, and the commitment is much smaller than the polynomial, then we can verify polynomial identities by checking at random points.



## KZG: Constant-Size Proofs from Pairings

The Kate-Zaverucha-Goldberg (KZG) scheme achieves the holy grail: constant-size commitments *and* constant-size evaluation proofs. No matter how large the polynomial, the proof is just one group element.

### The Magic Ingredient: Pairings

A **bilinear pairing** is a map $e: G_1 \times G_2 \to G_T$ between three groups with the property:

$$e(aP, bQ) = e(P, Q)^{ab}$$

for all scalars $a, b$ and group elements $P \in G_1$, $Q \in G_2$.

This seemingly simple equation has profound consequences. It allows us to check multiplicative relationships *in the exponent*. Given commitments $g^a$ and $g^b$, we cannot compute $g^{ab}$ (that would break CDH). But we can *verify* that $g^c = g^{ab}$ by checking:

$$e(g^a, g^b) = e(g^c, g)$$

One multiplication check "for free" in the hidden exponent world. This is exactly what polynomial evaluation needs.

**The Laser Pointer Intuition.** Imagine $G_1$ and $G_2$ as two flashlights with polarized lenses at different angles. You can shine each one on a wall ($G_T$) and see a spot. But if you shine *both* through the same point, the interaction of their polarizations creates a unique interference pattern. Knowing the two individual spots, you can predict what the combined pattern should be. This lets you *verify* multiplicative relationships (did these two beams combine correctly?) even though you can never *extract* the individual beam settings from looking at the wall alone. That one-way verification is the cryptographic leverage that makes KZG possible.

### The Trusted Setup

KZG requires a **structured reference string (SRS)**: a set of public parameters computed from a secret:

1. Choose a random secret $\tau \in \mathbb{F}_p$ (the "toxic waste")
2. Compute the SRS: $(g, g^\tau, g^{\tau^2}, \ldots, g^{\tau^D})$
3. **Destroy** $\tau$

The SRS encodes powers of the secret $\tau$ "in the exponent." Anyone can use these elements without knowing $\tau$ itself.

**The critical security requirement**: If anyone learns $\tau$, they can forge proofs for false statements. The setup must ensure $\tau$ is never known to any party. In practice, this is done via multi-party computation ceremonies where many participants contribute randomness, and security holds as long as *any one* participant is honest.

### Commitment

To commit to a polynomial $f(X) = \sum_{i=0}^{d} c_i X^i$:

$$C = g^{f(\tau)} = g^{\sum c_i \tau^i} = \prod_{i=0}^{d} (g^{\tau^i})^{c_i}$$

The prover computes this using the SRS elements, never learning $\tau$. The result is a single group element: the polynomial "evaluated at the secret point $\tau$, hidden in the exponent."

### Evaluation Proof

To prove $f(z) = v$ for a public point $z$:

1. **The polynomial identity**: If $f(z) = v$, then $(X - z)$ divides $f(X) - v$. Define:
   $$w(X) = \frac{f(X) - v}{X - z}$$
   This quotient $w(X)$ is a valid polynomial of degree $d-1$.

2. **The proof**: Commit to the quotient:
   $$\pi = g^{w(\tau)}$$

3. **Verification**: The verifier checks:
   $$e(\pi, g^\tau \cdot g^{-z}) = e(C \cdot g^{-v}, g)$$

### Why Verification Works

The pairing check verifies that the polynomial identity holds at $\tau$:

$$e(g^{w(\tau)}, g^{\tau - z}) = e(g^{f(\tau) - v}, g)$$

By bilinearity:
$$e(g,g)^{w(\tau)(\tau - z)} = e(g,g)^{f(\tau) - v}$$

This holds iff $w(\tau)(\tau - z) = f(\tau) - v$, which is exactly the polynomial identity $f(X) - v = w(X)(X - z)$ evaluated at $\tau$.

**Why this implies soundness**: Suppose the prover lies; they claim $f(z) = v$ when actually $f(z) \neq v$. Then $f(X) - v$ is *not* divisible by $(X - z)$, so no polynomial $w(X)$ satisfies the identity $f(X) - v = w(X)(X - z)$. Without such a $w(X)$, the prover must instead find some $w'(X)$ where the identity fails as polynomials but happens to hold at $\tau$:

$$w'(\tau)(\tau - z) = f(\tau) - v$$

But the prover doesn't know $\tau$; it's hidden in the SRS. From their perspective, $\tau$ is a random field element. Two distinct degree-$d$ polynomials agree on at most $d$ points (Schwartz-Zippel), so the probability that a "wrong" $w'$ accidentally satisfies the check at the unknown $\tau$ is at most $d/|\mathbb{F}|$ (negligible for large fields).

The logic: if you can pass the check at a *random* point without knowing which point, you must have the correct polynomial identity.



## Worked Example: KZG in Action

Let's trace through a complete example.

**Setup**: Maximum degree $D = 2$, secret $\tau = 5$.

- SRS: $(g, g^5, g^{25})$

**Commit to $f(X) = X^2 + 2X + 3$**:
$$C = g^{f(5)} = g^{25 + 10 + 3} = g^{38}$$

**Prove $f(1) = 6$**:

- Check: $f(1) = 1 + 2 + 3 = 6$
- Quotient: $w(X) = \frac{f(X) - 6}{X - 1} = \frac{X^2 + 2X - 3}{X - 1}$

  Factor: $X^2 + 2X - 3 = (X + 3)(X - 1)$

  So $w(X) = X + 3$

- Proof: $\pi = g^{w(5)} = g^{5 + 3} = g^8$

**Verify**:

- LHS: $e(\pi, g^\tau \cdot g^{-z}) = e(g^8, g^5 \cdot g^{-1}) = e(g^8, g^4) = e(g,g)^{32}$
- RHS: $e(C \cdot g^{-v}, g) = e(g^{38} \cdot g^{-6}, g) = e(g^{32}, g) = e(g,g)^{32}$

Both sides equal. The verification passes.

### Managing Toxic Waste: Powers of Tau Ceremonies

The trusted setup creates a serious practical problem: someone must generate τ, compute the powers, and then *verifiably destroy* τ. How do you convince the world that the toxic waste is truly gone?

The solution is **multi-party computation (MPC) ceremonies**. Instead of trusting a single party, we chain together contributions from many independent participants:

1. **Participant 1** picks secret $\tau_1$, computes $[1]_1, [\tau_1]_1, [\tau_1^2]_1, \ldots$ and destroys $\tau_1$
2. **Participant 2** picks secret $\tau_2$, raises each element to $\tau_2$, getting $[1]_1, [\tau_1\tau_2]_1, [(\tau_1\tau_2)^2]_1, \ldots$ and destroys $\tau_2$
3. Continue for hundreds or thousands of participants...

The final structured reference string encodes powers of $\tau = \tau_1 \cdot \tau_2 \cdot \tau_3 \cdots \tau_n$. The crucial insight: **the setup is secure if *any single participant* destroyed their secret**. This is the "1-of-N" trust model; you only need to trust that *one* honest participant existed among potentially thousands.

**Notable ceremonies**:

- **Zcash Powers of Tau** (2017-2018): 87 participants contributed to a universal phase, followed by circuit-specific ceremonies for Sapling
- **Ethereum KZG Ceremony** (2023): Over 140,000 contributions for the EIP-4844 blob commitments, the largest ceremony ever conducted

**Universal vs. circuit-specific**: Some ceremonies produce parameters usable for any circuit up to a size bound (universal), while others are tailored to specific circuits. KZG setups are inherently universal; the same powers of tau work for any polynomial of degree at most $d$.

The scale of modern ceremonies makes collusion effectively impossible. When 140,000 independent participants contribute, the probability that *all* of them colluded or were compromised approaches zero.

## KZG: Properties and Trade-offs

**Advantages**:

- **Constant commitment size**: One group element, regardless of polynomial degree
- **Constant proof size**: One group element per evaluation
- **Constant verification time**: A few pairings and exponentiations
- **Batch verification**: Multiple evaluations can be verified together

**Disadvantages**:

- **Trusted setup**: The "toxic waste" must be destroyed. If compromised, soundness breaks.
- **Not post-quantum**: Pairing-based cryptography falls to quantum computers
- **Non-universal** (in basic form): The SRS size limits the maximum polynomial degree

### Batch Opening

KZG has a remarkable property: proving evaluations at multiple points is barely more expensive than proving one.

To prove $f(z_1) = v_1, \ldots, f(z_k) = v_k$:

1. Define the vanishing polynomial $Z(X) = \prod_i (X - z_i)$
2. Compute the interpolating polynomial $R(X)$ such that $R(z_i) = v_i$
3. The quotient $w(X) = \frac{f(X) - R(X)}{Z(X)}$ exists iff all evaluations are correct
4. The proof is just $g^{w(\tau)}$ (still one group element!)



## IPA/Bulletproofs: No Trusted Setup

**Historical context**: The Inner Product Argument emerged from a different lineage than KZG. Bootle et al. (2016) introduced the core folding technique for efficient inner product proofs. Bünz et al. (2017) refined this into **Bulletproofs**, originally designed for *range proofs*, proving that a committed value lies in a range $[0, 2^n)$ without revealing it. This was motivated by confidential transactions in cryptocurrencies: prove your balance is non-negative without revealing the amount.

The terminology can be confusing:

- **IPA** (Inner Product Argument) is the *technique*: the recursive folding protocol that proves $\langle \vec{a}, \vec{b} \rangle = c$
- **Bulletproofs** is the *system* that used IPA for range proofs and general arithmetic circuits
- **Halo** (2019, Bowe et al.) showed how to use IPA for polynomial commitments in recursive proof composition, avoiding trusted setup entirely

Today, "IPA" and "Bulletproofs" are often used interchangeably to describe the folding-based polynomial commitment scheme. The key innovation: achieving transparency (no toxic waste) at the cost of logarithmic proofs and linear verification.

### The Key Insight: Polynomial Evaluation as Inner Product

A polynomial evaluation is an inner product:

$$f(z) = \sum_{i=0}^{n-1} c_i z^i = \langle \vec{c}, \vec{z} \rangle$$

where $\vec{c} = (c_0, \ldots, c_{n-1})$ are coefficients and $\vec{z} = (1, z, z^2, \ldots, z^{n-1})$ is the evaluation vector.

If we can prove inner product claims efficiently, we can prove polynomial evaluations!

> **Connection to Chapter 4.** This is the same inner product structure we saw with multilinear extensions. There, evaluating $\tilde{f}(r_1, \ldots, r_n)$ was an inner product between the coefficient table and Lagrange basis weights. The sum-check protocol exploited this structure by reducing the inner product one variable at a time. IPA does something similar: it reduces the inner product by *folding* both vectors with random challenges, halving the dimension each round. The algebraic trick is the same; only the cryptographic wrapping differs.

### Pedersen Vector Commitments

The basic Pedersen vector commitment uses generators $G_0, \ldots, G_{n-1}$ for coefficients and $H$ for blinding:

$$C = \sum_{i=0}^{n-1} c_i \cdot G_i + r \cdot H$$

For polynomial evaluation proofs, we need an additional generator $U$ to encode the claimed inner product value. The full commitment for proving $\langle \vec{c}, \vec{z} \rangle = v$ becomes:

$$P = \langle \vec{c}, \vec{G} \rangle + v \cdot U + r \cdot H$$

This structure is essential: the generator $U$ carries the inner product term through the folding process, allowing the cross-term commitments to properly encode both coefficient and inner product information.

### The Folding Trick

The brilliant idea of IPA is recursive "folding" that shrinks the problem by half each round.

**Setup**: Prover holds coefficient vector $\vec{c}$ of length $n$. They've committed to it as $P = \langle \vec{c}, \vec{G} \rangle + v \cdot U$ where $v = \langle \vec{c}, \vec{z} \rangle$ is the claimed evaluation. (We omit the blinding term $rH$ for clarity.)

**One round of folding**:

1. Split $\vec{c} = (\vec{c}_L, \vec{c}_R)$ into two halves
2. Split $\vec{z} = (\vec{z}_L, \vec{z}_R)$ and $\vec{G} = (\vec{G}_L, \vec{G}_R)$ similarly
3. Prover computes and sends cross-term *commitments*:
   $$L = \langle \vec{c}_L, \vec{G}_R \rangle + \langle \vec{c}_L, \vec{z}_R \rangle \cdot U$$
   $$R = \langle \vec{c}_R, \vec{G}_L \rangle + \langle \vec{c}_R, \vec{z}_L \rangle \cdot U$$

   Note: $L$ commits to the left coefficients using right generators, plus the cross inner product. Similarly for $R$.
4. Verifier sends random challenge $\alpha$
5. **Prover** computes the folded coefficient vector (secretly):
   $$\vec{c}' = \alpha \cdot \vec{c}_L + \alpha^{-1} \cdot \vec{c}_R$$
6. **Both parties** compute (using public information):
   - Folded evaluation vector: $\vec{z}' = \alpha^{-1} \cdot \vec{z}_L + \alpha \cdot \vec{z}_R$
   - Folded generators: $\vec{G}' = \alpha^{-1} \cdot \vec{G}_L + \alpha \cdot \vec{G}_R$
   - Updated commitment: $P' = L^{\alpha^2} \cdot P \cdot R^{\alpha^{-2}}$

**Why this works**: We need to show that $P'$ is a valid commitment to $(\vec{c}', v')$ under the folded generators $\vec{G}'$.

First, expand what $P'$ *should* be if the prover is honest:
$$P'_{\text{honest}} = \langle \vec{c}', \vec{G}' \rangle + v' \cdot U$$

where $v' = \langle \vec{c}', \vec{z}' \rangle$ is the new inner product claim.

Now expand $\langle \vec{c}', \vec{G}' \rangle$ using the folding formulas:
$$\langle \vec{c}', \vec{G}' \rangle = \langle \alpha \vec{c}_L + \alpha^{-1} \vec{c}_R, \, \alpha^{-1} \vec{G}_L + \alpha \vec{G}_R \rangle$$

Distributing the inner product (which is bilinear):
$$= \alpha \cdot \alpha^{-1} \langle \vec{c}_L, \vec{G}_L \rangle + \alpha \cdot \alpha \langle \vec{c}_L, \vec{G}_R \rangle + \alpha^{-1} \cdot \alpha^{-1} \langle \vec{c}_R, \vec{G}_L \rangle + \alpha^{-1} \cdot \alpha \langle \vec{c}_R, \vec{G}_R \rangle$$
$$= \langle \vec{c}_L, \vec{G}_L \rangle + \langle \vec{c}_R, \vec{G}_R \rangle + \alpha^2 \langle \vec{c}_L, \vec{G}_R \rangle + \alpha^{-2} \langle \vec{c}_R, \vec{G}_L \rangle$$

Similarly, expanding the new inner product $v' = \langle \vec{c}', \vec{z}' \rangle$:
$$v' = \langle \vec{c}_L, \vec{z}_L \rangle + \langle \vec{c}_R, \vec{z}_R \rangle + \alpha^2 \langle \vec{c}_L, \vec{z}_R \rangle + \alpha^{-2} \langle \vec{c}_R, \vec{z}_L \rangle = v + \alpha^2 L_{\text{ip}} + \alpha^{-2} R_{\text{ip}}$$

Now look at $P' = L^{\alpha^2} \cdot P \cdot R^{\alpha^{-2}}$ and expand each term:

- $P = \langle \vec{c}_L, \vec{G}_L \rangle + \langle \vec{c}_R, \vec{G}_R \rangle + v \cdot U$
- $L = \langle \vec{c}_L, \vec{G}_R \rangle + L_{\text{ip}} \cdot U$
- $R = \langle \vec{c}_R, \vec{G}_L \rangle + R_{\text{ip}} \cdot U$

So:
$$L^{\alpha^2} \cdot P \cdot R^{\alpha^{-2}} = \alpha^2 L + P + \alpha^{-2} R$$
$$= \alpha^2 (\langle \vec{c}_L, \vec{G}_R \rangle + L_{\text{ip}} \cdot U) + (\langle \vec{c}_L, \vec{G}_L \rangle + \langle \vec{c}_R, \vec{G}_R \rangle + v \cdot U) + \alpha^{-2}(\langle \vec{c}_R, \vec{G}_L \rangle + R_{\text{ip}} \cdot U)$$

Collecting terms:
$$= \underbrace{\langle \vec{c}_L, \vec{G}_L \rangle + \langle \vec{c}_R, \vec{G}_R \rangle + \alpha^2 \langle \vec{c}_L, \vec{G}_R \rangle + \alpha^{-2} \langle \vec{c}_R, \vec{G}_L \rangle}_{= \langle \vec{c}', \vec{G}' \rangle} + \underbrace{(v + \alpha^2 L_{\text{ip}} + \alpha^{-2} R_{\text{ip}})}_{= v'} \cdot U$$

This equals $\langle \vec{c}', \vec{G}' \rangle + v' \cdot U = P'_{\text{honest}}$. The update formula produces exactly the right commitment!

**The recursion**: After $\log_2 n$ rounds, the vectors have length 1. The prover reveals the final scalar, and the verifier checks directly.

### Final Verification: The Endgame

After $\log_2 n$ rounds of folding, the vectors have length 1:

- Prover holds a single scalar $c'$ (the folded coefficient)
- The $z$-vector has folded to $z'$ (known to both parties)
- The commitment has transformed to $P_{\text{final}}$ through all the updates

**The prover reveals**:

- The final coefficient $c' \in \mathbb{F}$
- The final blinding factor $r' \in \mathbb{F}$

The verifier must check: does $c'$ actually correspond to the final commitment?

$$P_{\text{final}} \stackrel{?}{=} c' \cdot G'_1 + (c' \cdot z'_1) \cdot U + r' \cdot H$$

where $z'_1$ is the final folded evaluation point (known to both parties).

**The catch**: What is $G'_1$? It's the result of folding all the generators through all $\log n$ rounds:

$$\vec{G}' = \alpha_1^{-1} \vec{G}_L^{(1)} + \alpha_1 \vec{G}_R^{(1)} \quad \text{(first fold)}$$
$$\vec{G}'' = \alpha_2^{-1} \vec{G}'_L + \alpha_2 \vec{G}'_R \quad \text{(second fold)}$$
$$\vdots$$

**This is the verifier's bottleneck**: Computing the folded generator $G'_1$ requires applying all $\log n$ folding operations to the original $n$ generators. This takes $O(n)$ group operations (linear in the polynomial size!)

**Why can't we avoid this?** The verifier needs to know what commitment value a correctly-folded polynomial *should* produce. Without computing the folded generators, there's no way to check the prover's final claim.

### Worked Example: IPA Verification

Let's trace through a complete IPA proof for a polynomial with 4 coefficients. This requires 2 rounds of folding.

**Setup**:

- Coefficient vector: $\vec{c} = (3, 5, 2, 7)$ (prover's secret)
- Evaluation point: $z = 2$, so $\vec{z} = (1, 2, 4, 8)$ (public)
- Claimed evaluation: $v = \langle \vec{c}, \vec{z} \rangle = 3(1) + 5(2) + 2(4) + 7(8) = 77$
- Generators: $G_1, G_2, G_3, G_4$ (for coefficients), $U$ (for inner product)
- Initial commitment: $P = (3G_1 + 5G_2 + 2G_3 + 7G_4) + 77U$

The verifier knows: $P$, $\vec{z}$, $v = 77$, and all generators. The verifier does *not* know $\vec{c}$.

**Round 1** (reduce from 4 to 2 elements):

*Prover's work* (uses secret $\vec{c}$):

Split: $\vec{c}_L = (3, 5)$, $\vec{c}_R = (2, 7)$

Compute cross inner products:

- $\langle \vec{c}_L, \vec{z}_R \rangle = 3(4) + 5(8) = 52$
- $\langle \vec{c}_R, \vec{z}_L \rangle = 2(1) + 7(2) = 16$

Send commitments to verifier:

- $L_1 = (3G_3 + 5G_4) + 52U$
- $R_1 = (2G_1 + 7G_2) + 16U$

*Verifier's challenge*: $\alpha_1 = 2$

*Both parties compute* (verifier uses only public information):

Folded generators: $\vec{G}' = \alpha_1^{-1} \vec{G}_L + \alpha_1 \vec{G}_R$

- $G'_1 = \frac{1}{2}G_1 + 2G_3$
- $G'_2 = \frac{1}{2}G_2 + 2G_4$

Folded evaluation vector: $\vec{z}' = \alpha_1^{-1} \vec{z}_L + \alpha_1 \vec{z}_R$

- $z'_1 = \frac{1}{2}(1) + 2(4) = 8.5$
- $z'_2 = \frac{1}{2}(2) + 2(8) = 17$

Updated commitment: $P' = L_1^{\alpha_1^2} \cdot P \cdot R_1^{\alpha_1^{-2}} = L_1^4 \cdot P \cdot R_1^{0.25}$

The verifier doesn't know the cross inner products (52 and 16) directly; those are hidden inside $L_1$ and $R_1$. But because $L_1$ and $R_1$ encode them via the $U$ generator, when the verifier computes $P' = L_1^4 \cdot P \cdot R_1^{0.25}$, the $U$-coefficient of $P'$ automatically becomes $v' = 77 + 4(52) + 0.25(16) = 289$.

*Prover also computes* (secretly):

- $\vec{c}' = \alpha_1 \vec{c}_L + \alpha_1^{-1} \vec{c}_R = 2(3,5) + 0.5(2,7) = (7, 13.5)$

Sanity check: $\langle \vec{c}', \vec{z}' \rangle = 7(8.5) + 13.5(17) = 59.5 + 229.5 = 289$ $\checkmark$

**Round 2** (reduce from 2 to 1 element):

*Prover's work*:

Split: $c'_L = 7$, $c'_R = 13.5$, $z'_L = 8.5$, $z'_R = 17$

Compute cross inner products:

- $c'_L \cdot z'_R = 7 \cdot 17 = 119$
- $c'_R \cdot z'_L = 13.5 \cdot 8.5 = 114.75$

Send commitments:

- $L_2 = 7 G'_2 + 119 U$
- $R_2 = 13.5 G'_1 + 114.75 U$

*Verifier's challenge*: $\alpha_2 = 3$

*Both parties compute*:

Folded generator: $G'' = \alpha_2^{-1} G'_1 + \alpha_2 G'_2 = \frac{1}{3}G'_1 + 3G'_2$

Folded evaluation point: $z'' = \alpha_2^{-1} z'_L + \alpha_2 z'_R = \frac{1}{3}(8.5) + 3(17) = 2.83... + 51 = 53.83...$

Updated commitment: $P'' = L_2^9 \cdot P' \cdot R_2^{1/9}$

Again, the $U$-coefficient of $P''$ becomes $v'' = 289 + 9(119) + \frac{1}{9}(114.75) = 1372.75$.

*Prover computes*:

- $c'' = \alpha_2 c'_L + \alpha_2^{-1} c'_R = 3(7) + \frac{1}{3}(13.5) = 21 + 4.5 = 25.5$

Sanity check: $c'' \cdot z'' = 25.5 \times 53.83... = 1372.75$ $\checkmark$

**Final verification**:

Prover reveals: $c'' = 25.5$

Verifier computes the fully folded generator $G''$ in terms of original generators:
$$G'' = \frac{1}{3}G'_1 + 3G'_2 = \frac{1}{3}\left(\frac{1}{2}G_1 + 2G_3\right) + 3\left(\frac{1}{2}G_2 + 2G_4\right) = \frac{1}{6}G_1 + \frac{3}{2}G_2 + \frac{2}{3}G_3 + 6G_4$$

This is the $O(n)$ work: computing a linear combination of all $n$ original generators.

Verifier checks: $P'' \stackrel{?}{=} c'' \cdot G'' + (c'' \cdot z'') \cdot U$

Substituting: $P'' \stackrel{?}{=} 25.5 \cdot \left(\frac{1}{6}G_1 + \frac{3}{2}G_2 + \frac{2}{3}G_3 + 6G_4\right) + 1372.75 \cdot U$

Which equals: $P'' \stackrel{?}{=} 4.25G_1 + 38.25G_2 + 17G_3 + 153G_4 + 1372.75U$

If this holds, the proof is valid. The verifier is convinced that the prover knows $\vec{c}$ such that $\langle \vec{c}, \vec{z} \rangle = 77$, without ever learning $\vec{c}$.

### Efficiency

- **Commitment size**: One group element (same as KZG)
- **Proof size**: $O(\log n)$ group elements (the $L_i, R_i$ cross-terms from each round)
- **Verifier time**: $O(n)$ (must compute folded generators; this is the fundamental limitation)
- **Prover time**: $O(n \log n)$

The verifier's linear work is the main drawback compared to KZG's constant verification. However, IPA requires no trusted setup; the generators can be chosen transparently (e.g., by hashing).

### The Linear Verifier Problem

This $O(n)$ verification cost is a serious limitation. For a polynomial with $N = 2^{20}$ coefficients (about 1 million), the verifier must perform over a million group operations, each involving expensive elliptic curve arithmetic.

**Why is this problematic?** A scalar multiplication on an elliptic curve involves roughly 400 group additions. Each group addition involves 6-12 base field operations. The result: verification can be ~4000× slower than simple field arithmetic.

For interactive proofs where verification happens once, this is acceptable. For applications like blockchains where proofs are verified by thousands of nodes, or for recursive proof composition, linear verification becomes prohibitive.

This limitation motivated the development of schemes like Hyrax and Dory that exploit additional structure to achieve sublinear verification, which we'll explore shortly.



## Comparing KZG and IPA

| Property | KZG | IPA/Bulletproofs |
|----------|-----|------------------|
| Trusted setup | Required | None |
| Commitment size | $O(1)$ | $O(1)$ |
| Proof size | $O(1)$ | $O(\log n)$ |
| Verification time | $O(1)$ | $O(n)$ |
| Prover time | $O(n)$ | $O(n \log n)$ |
| Assumption | Pairings (q-SDH) | DLog only |
| Quantum-safe | No | No |
| Batch verification | Excellent | Good |

**When to use KZG**: When verification efficiency is paramount and a trusted setup is acceptable. Most production SNARKs (Groth16, PLONK with KZG) use this approach.

**When to use IPA**: When trust minimization is critical, or in systems designed for transparent setups (Halo, Pasta curves).

But what if we want both transparency *and* efficient verification? This is where Dory enters the picture.



## Dory: Logarithmic Verification Without Trusted Setup

The IPA scheme's $O(n)$ verification is a fundamental limitation: the verifier must compute folded generators. **Dory** breaks this barrier using pairings in a clever way.

**The core insight is "lazy verification."** In IPA, the verifier diligently recalculates the folded generators at each step, doing $O(n)$ work. Dory's verifier is lazier: instead of checking each step, they accumulate commitments and defer all verification to a single final pairing check. It's like a teacher who doesn't grade homework each night, but assigns problems so cleverly that a single final exam can catch any cheating retroactively. The algebraic structure of pairings makes this possible: the verifier can "absorb" all the folding challenges into target group elements, then verify everything at once.

> **Note:** Dory is one of the more advanced commitment schemes covered in this book. The two-tier structure, pairing-based folding, and binding arguments involve subtle cryptographic reasoning. Don't worry if the details don't click on first reading; the key intuition is that pairings allow verification to happen "in the target group" without the verifier touching the original generators directly.

### Two-Tier Commitment Structure

Dory commits to polynomials using AFGHO commitments (Abe et al.'s structure-preserving commitments) combined with Pedersen commitments.

**Public parameters (SRS):** Generated transparently by sampling random group elements (the notation $\xleftarrow{\$}$ means "sampled uniformly at random from"):
- $\Gamma_1 \xleftarrow{\$} \mathbb{G}_1^{\sqrt{N}}$ — commitment key for row commitments
- $\Gamma_2 \xleftarrow{\$} \mathbb{G}_2^{\sqrt{N}}$ — commitment key for final commitment
- $H_1 \xleftarrow{\$} \mathbb{G}_1$, $H_2 \xleftarrow{\$} \mathbb{G}_2$ — blinding generators (for hiding/zero-knowledge)
- $H_T = e(H_1, H_2)$ — derived blinding generator in $\mathbb{G}_T$

All parameters are **public**. The prover's secrets are the blinding factors $r_i, r_{\text{fin}} \in \mathbb{F}$.

**Tier 1 — Row Commitments ($\mathbb{G}_1$):**

Treat the polynomial coefficients as a $\sqrt{N} \times \sqrt{N}$ matrix $M$. For each row $i$, compute a Pedersen commitment:

$$R_i = \langle M[i], \Gamma_1 \rangle + r_i \cdot H_1 = \sum_{j=0}^{\sqrt{N}-1} M[i][j] \cdot \Gamma_1[j] + r_i \cdot H_1$$

where $r_i \in \mathbb{F}$ is a **secret** blinding factor. This produces $\sqrt{N}$ elements in $\mathbb{G}_1$.

**Tier 2 — Final Commitment ($\mathbb{G}_T$):**

Combine row commitments via pairing with generators $\Gamma_2 \in \mathbb{G}_2^{\sqrt{N}}$:

$$C = \langle \vec{R}, \Gamma_2 \rangle_T + r_{\text{fin}} \cdot H_T = \sum_{i=0}^{\sqrt{N}-1} e(R_i, \Gamma_2[i]) + r_{\text{fin}} \cdot e(H_1, H_2)$$

where $r_{\text{fin}}$ is a final blinding factor. This produces one $\mathbb{G}_T$ element (the commitment).

**Why two tiers?**

| Tier | Purpose |
|------|---------|
| Tier 1 (rows) | Enables streaming: process row-by-row with $O(\sqrt{N})$ memory |
| | Row commitments serve as "hints" for efficient batch opening |
| Tier 2 ($\mathbb{G}_T$) | Provides succinctness: one element regardless of polynomial size |
| | Binding under SXDH assumption in Type III pairings |

The AFGHO commitment is hiding because $r_{\text{fin}} \cdot e(H_1, H_2)$ is uniformly random in $\mathbb{G}_T$. Both tiers are additively homomorphic, which is crucial for the evaluation protocol.

### From Coefficients to Matrix Form

**Why matrices?** A multilinear polynomial evaluation $f(r_1, \ldots, r_n)$ can be written as a vector-matrix-vector product. The evaluation point $(r_1, \ldots, r_n)$ splits into:
- Row coordinates $(r_1, \ldots, r_{n/2})$ — selects which row
- Column coordinates $(r_{n/2+1}, \ldots, r_n)$ — selects which column

This mirrors the coefficient arrangement: $M[i][j] = f(\text{bits of } i \| \text{bits of } j)$.

Each half determines a vector of **Lagrange coefficients** via the equality polynomial:

$$\ell_j = \text{eq}((r_1, \ldots, r_{n/2}), j) = \prod_{i=1}^{\log\sqrt{N}} \left( r_i \cdot j_i + (1 - r_i) \cdot (1 - j_i) \right)$$

$$\rho_j = \text{eq}((r_{n/2+1}, \ldots, r_n), j) = \prod_{i=1}^{\log\sqrt{N}} \left( r_{n/2+i} \cdot j_i + (1 - r_{n/2+i}) \cdot (1 - j_i) \right)$$

where $j_i \in \{0,1\}$ are the bits of index $j$. We use $\ell$ for row (left) and $\rho$ for column (right) coefficients, distinct from the evaluation point $r$.

The evaluation becomes a bilinear form:

$$f(r) = \sum_{i,j} M[i][j] \cdot \ell_i \cdot \rho_j = \vec{\ell}^T M \vec{\rho}$$

**Worked example ($n=2$):** For $f(x_1, x_2) = c_{00}(1-x_1)(1-x_2) + c_{01}(1-x_1)x_2 + c_{10}x_1(1-x_2) + c_{11}x_1x_2$:

$$f(r_1, r_2) = \underbrace{(1-r_1, r_1)}_{\vec{\ell}^T} \begin{pmatrix} c_{00} & c_{01} \\ c_{10} & c_{11} \end{pmatrix} \underbrace{\begin{pmatrix} 1-r_2 \\ r_2 \end{pmatrix}}_{\vec{\rho}}$$

### The Opening Protocol (Dory-Innerproduct)

**The key reduction:** Polynomial evaluation becomes an inner product. Define two vectors:

- $\vec{v}_1 = M \cdot \vec{\rho}$, the matrix times the column Lagrange vector. Each entry $(v_1)_j = \langle M[j], \vec{\rho} \rangle$ is row $j$ evaluated at the column coordinates.
- $\vec{v}_2 = \vec{\ell}$, the row Lagrange vector.

Then $\langle \vec{v}_1, \vec{v}_2 \rangle = \vec{\ell}^T M \vec{\rho} = f(r)$. The inner product of these two vectors *is* the polynomial evaluation.

**Goal:** Prove $\langle \vec{v}_1, \vec{v}_2 \rangle = v$ for committed vectors, which proves $f(r) = v$ for the polynomial.

**The Language:** Dory proves membership in:

$$\mathcal{L}_{n,\Gamma_1,\Gamma_2,H_1,H_2} = \{(C, D_1, D_2) : \exists (\vec{v}_1, \vec{v}_2, r_C, r_{D_1}, r_{D_2}) \text{ s.t.}$$
$$D_1 = \langle \vec{v}_1, \Gamma_2 \rangle + r_{D_1} H_T, \quad D_2 = \langle \Gamma_1, \vec{v}_2 \rangle + r_{D_2} H_T, \quad C = \langle \vec{v}_1, \vec{v}_2 \rangle + r_C H_T\}$$

In words: $D_1$ commits to $\vec{v}_1$ (using $\Gamma_2$), $D_2$ commits to $\vec{v}_2$ (using $\Gamma_1$), and $C$ commits to their inner product. The protocol proves these three commitments are consistent, that the same vectors appear in all three.

### How Verification Works (The Key Insight)

**The question:** The prover knows $\vec{\ell}$, $\vec{\rho}$, and $M$. The verifier can compute $\vec{\ell}$ and $\vec{\rho}$ from the evaluation point, but doesn't know $M$. How can the verifier check $f(r) = v$ without the matrix?

**The answer:** The verifier never needs $M$ directly. Instead:

**Step 1 — The verifier has:** The commitment $C$ (which encodes $M$ cryptographically) and the claimed evaluation $v$.

**Step 2 — The prover sends a VMV message:** $(C_{\text{vmv}}, D_2, E_1)$ where:

- $C_{\text{vmv}} = e(\langle \vec{R}, \vec{v}_1 \rangle, H_2)$
- $D_2 = e(\langle \Gamma_1, \vec{v}_1 \rangle, H_2)$
- $E_1 = \langle \vec{R}, \vec{\ell} \rangle$ (row commitments combined with row Lagrange coefficients)

Recall $\vec{v}_1 = M \cdot \vec{\rho}$ from earlier. This is the non-hiding variant; the row commitments $\vec{R}$ already contain blinding from tier 1.

**Step 3 — First verification check:** The verifier checks:

$$e(E_1, H_2) \stackrel{?}{=} D_2$$

**Why this works:** By Pedersen linearity:

$$E_1 = \langle \vec{R}, \vec{\ell} \rangle = \sum_i \ell_i \cdot R_i = \sum_i \ell_i \cdot \langle M[i], \Gamma_1 \rangle = \langle \vec{\ell}^T M, \Gamma_1 \rangle$$

Note that $\vec{\ell}^T M$ is a row vector, while $\vec{v}_1 = M \cdot \vec{\rho}$ is a column vector. However, both represent "partial evaluations" of the matrix. The key point: $E_1$ is determined by the row commitments and Lagrange coefficients. The check $e(E_1, H_2) = D_2$ verifies that the prover's $D_2$ is consistent with the row commitments $\vec{R}$. This binds the prover's intermediate computation to the committed polynomial.

**Step 4 — The verifier computes $E_2 = H_2 \cdot v$** (not from the prover).

The verifier computes this themselves from the claimed evaluation $v$. This is how the claimed value enters the protocol: it's bound to the blinding generator $H_2$. If the prover lied about $v = f(r)$, then $E_2$ won't match the prover's internal computation, and the final check will fail.

**Step 5 — Initialize verifier state:**

- $C \leftarrow C_{\text{vmv}}$ (from VMV message)
- $D_1 \leftarrow$ the polynomial commitment (the tier-2 commitment the verifier already has)
- $D_2 \leftarrow$ from VMV message
- $E_1, E_2$ as computed above

**What remains to prove:** The prover must demonstrate that $\langle \vec{v}_2, \vec{v}_1 \rangle = v$. That is, the intermediate vector $\vec{v}_1$ (committed implicitly via the consistency check) inner-producted with $\vec{v}_2 = \vec{\ell}$ yields the claimed evaluation. This is where Dory-Reduce takes over.

### The Folding Protocol (Dory-Reduce)

Each round halves the problem size. Given vectors of length $2m$, the round uses two challenges ($\beta$, then $\alpha$) and two prover messages:

**First message** (before any challenge):

- $D_{1L} = \langle \vec{v}_{1L}, \Gamma_2' \rangle$, $D_{1R} = \langle \vec{v}_{1R}, \Gamma_2' \rangle$ (cross-pairings of $\vec{v}_1$ halves with generator halves)
- $D_{2L} = \langle \Gamma_1', \vec{v}_{2L} \rangle$, $D_{2R} = \langle \Gamma_1', \vec{v}_{2R} \rangle$ (cross-pairings of $\vec{v}_2$ halves with generator halves)

**Verifier sends first challenge** $\beta \stackrel{\$}{\leftarrow} \mathbb{F}$

**Prover updates vectors**:

- $\vec{v}_1 \leftarrow \vec{v}_1 + \beta \cdot \Gamma_1$
- $\vec{v}_2 \leftarrow \vec{v}_2 + \beta^{-1} \cdot \Gamma_2$

**Second message** (computed with $\beta$-modified vectors):

- $C_+ = \langle \vec{v}_{1L}, \vec{v}_{2R} \rangle$, $C_- = \langle \vec{v}_{1R}, \vec{v}_{2L} \rangle$ (cross inner products of modified vectors)

**Verifier sends second challenge** $\alpha \stackrel{\$}{\leftarrow} \mathbb{F}$

**Prover folds vectors:**

- $\vec{v}_1' = \alpha \vec{v}_{1L} + \vec{v}_{1R}$
- $\vec{v}_2' = \alpha^{-1} \vec{v}_{2L} + \vec{v}_{2R}$

**Verifier updates accumulators** (no pairing checks, just $\mathbb{G}_T$ arithmetic):

- $C' = C + \chi_k + \beta D_2 + \beta^{-1} D_1 + \alpha C_+ + \alpha^{-1} C_-$
- $D_1' = \alpha D_{1L} + D_{1R}$
- $D_2' = \alpha^{-1} D_{2L} + D_{2R}$

where $\chi_k = e(\Gamma_1[0..2^k], \Gamma_2[0..2^k])$ is a **precomputed SRS value** (the pairing of generator prefixes at round $k$).

**Recurse** with vectors of length $m$.

After $\log(\sqrt{N})$ rounds, vectors have length 1.

**Final pairing check:** After all rounds:

$$e(E_1' + d \cdot \Gamma_{1,0}, E_2' + d^{-1} \cdot \Gamma_{2,0}) = C' + \chi_0 + d \cdot D_2' + d^{-1} \cdot D_1'$$

where primes denote folded values, and $d$ is a final challenge.

**The invariant:** Throughout folding, $(C, D_1, D_2)$ satisfy:

- $C = \langle \vec{v}_1, \vec{v}_2 \rangle$ (inner product commitment)
- $D_1 = \langle \vec{v}_1, \Gamma_2 \rangle$, $D_2 = \langle \Gamma_1, \vec{v}_2 \rangle$ (commitments to each vector)

The verifier does no per-round pairing checks, only accumulator updates. Soundness comes from the final check verifying this invariant for the length-1 vectors.

The verifier does no per-round pairing checks, only accumulator updates. Soundness comes entirely from the final check, which verifies this invariant holds for the length-1 vectors.

### Why Binding Works

The prover provides row commitments $\vec{R}$ alongside the tier-2 commitment. Why can't the prover cheat by providing fake rows?

1. **Tier 2 constrains Tier 1:** The tier-2 commitment $C = \langle \vec{R}, \Gamma_2 \rangle_T + r_{\text{fin}} H_T$ is a deterministic function of the row commitments. Changing any $R_i$ changes $C$.

2. **Tier 1 constrains the data:** Each $R_i = \langle M[i], \Gamma_1 \rangle + r_i H_1$ is a Pedersen commitment. Under discrete log hardness, the prover cannot find two different row vectors that produce the same $R_i$.

3. **No trapdoor:** The SRS generators are sampled randomly. Without their discrete logs, the prover is computationally bound to the original coefficients.

If the Dory proof verifies, then with overwhelming probability (under SXDH), the prover knew valid openings for all original commitments.

### Dory: Properties and Trade-offs

| Property | Dory |
|----------|------|
| Trusted setup | **None (Transparent)** |
| Commitment size | $O(1)$ (one $\mathbb{G}_T$ element) |
| Proof size | $O(\log N)$ group elements |
| Verification time | **$O(\log N)$** (the key improvement!) |
| Prover time | $O(N)$ for commitment, $O(\sqrt{N})$ per opening |
| Assumption | SXDH (on Type III pairings) |
| Quantum-safe | No (uses pairings) |

Dory uses pairings (like KZG) but achieves transparency (like IPA). It gets logarithmic verification (better than IPA's linear) at the cost of more complex pairing machinery. This makes Dory particularly attractive for systems with many polynomial openings that can be batched (like Jolt's zkVM), where the amortized cost per opening becomes very small.

Implementations like Jolt store row commitments $\vec{R} \in \mathbb{G}_1^{\sqrt{N}}$ as "opening hints." This increases proof size by $O(\sqrt{N})$ per polynomial but enables efficient batch opening without recomputing expensive MSMs. For Jolt's ~26 committed polynomials with $N = 2^{20}$, this means ~26 KB of hints instead of ~800 bytes, but saves massive computation during batch verification.

Batching multiple polynomials exploits Pedersen's homomorphism. When batching $k$ polynomials with random linear combination coefficient $\gamma$, we combine corresponding rows across all polynomials:

$$R^{(\text{joint})}_j = \sum_{i=1}^{k} \gamma^i \cdot R^{(i)}_j$$

Row $j$ of $f_{\text{joint}} = \sum_i \gamma^i f_i$ has coefficients $M_{\text{joint}}[j] = \sum_i \gamma^i M_i[j]$. By linearity of Pedersen commitments, $\langle M_{\text{joint}}[j], \Gamma_1 \rangle = \sum_i \gamma^i R^{(i)}_j = R^{(\text{joint})}_j$. The joint row commitments feed directly into Dory-Reduce, avoiding $k \cdot \sqrt{N}$ expensive MSM recomputations.

Why does Dory achieve logarithmic verification while IPA requires linear time? IPA's linear cost comes from computing folded generators. Dory sidesteps this entirely: the verifier works with commitments in $\mathbb{G}_T$, updating accumulators each round without touching generators. The algebraic structure of pairings ($e(aG_1, bG_2) = e(G_1, G_2)^{ab}$) lets the verifier "absorb" folding challenges into commitments. The precomputed $\chi_k$ values handle the generator contributions.



## Multilinear Polynomial Commitments

Dory, as presented above, is natively a multilinear PCS: it commits to multilinear polynomials represented as coefficient matrices, and the opening protocol exploits the tensor structure of Lagrange basis evaluations.

The other schemes extend to the multilinear setting as well:

**Multilinear KZG** uses an SRS encoding Lagrange basis polynomials at a secret point. Opening proofs require $\ell$ commitments (one witness polynomial per variable), with verification using $\ell + 1$ pairings. Proof size grows linearly with the number of variables, not exponentially with coefficient count.

**Multilinear IPA** exploits the tensor structure of multilinear extensions. The evaluation vector has product structure that folding can exploit systematically, achieving logarithmic proof size with linear verification time.



## The Role of PCS in SNARKs

Polynomial commitment schemes are the cryptographic core that transforms interactive protocols into succinct, non-interactive proofs.

**The recipe**:

1. **Arithmetization**: Convert computation to polynomial constraints
2. **IOP**: Define an interactive protocol where the prover sends polynomials (abstractly)
3. **PCS**: Compile the IOP using a polynomial commitment scheme
4. **Fiat-Shamir**: Make non-interactive by deriving challenges from transcript hashes

The PCS handles the "oracle" aspect of IOPs. Instead of the verifier having oracle access to polynomials, the prover commits to them, and later provides evaluation proofs at queried points.

Different PCS choices lead to different SNARK properties:

- KZG → Groth16, PLONK (trusted setup, constant proofs)
- IPA → Halo (transparent, larger proofs, linear verification)
- Dory → Jolt (transparent, logarithmic verification)
- FRI (Chapter 10) → STARKs (transparent, post-quantum)



## The Complete PCS Landscape

Now that we've seen three commitment schemes in depth, let's compare them systematically:

| Property | KZG | IPA/Bulletproofs | Dory | FRI (Ch. 10) |
|----------|-----|------------------|------|--------------|
| **Trusted setup** | Required | None | None | None |
| **Commitment size** | $O(1)$ | $O(1)$ | $O(1)$ | $O(1)$ |
| **Proof size** | $O(1)$ | $O(\log N)$ | $O(\log N)$ | $O(\log^2 N)$ |
| **Verification time** | $O(1)$ | $O(N)$ | $O(\log N)$ | $O(\log^2 N)$ |
| **Prover time** | $O(N)$ | $O(N \log N)$ | $O(N)$ | $O(N \log N)$ |
| **Assumption** | q-SDH + Pairings | DLog only | DLog + Pairings | Hash collision |
| **Post-quantum** | No | No | No | **Yes** |
| **Batching** | Excellent | Good | Very good | Good |

**How to read this table**:

- **Fastest verification**: KZG ($O(1)$), but requires trust
- **Best transparency**: IPA, Dory, or FRI (no trusted setup needed)
- **Best of both worlds**: Dory gets logarithmic verification with transparency
- **Post-quantum ready**: Only FRI (Chapter 10) survives quantum computers

**Practical guidance**:

- **Ethereum L1**: KZG (verification cost is critical, trusted setup is acceptable)
- **Privacy coins**: Dory or IPA (trust minimization matters)
- **Long-term security**: FRI/STARKs (quantum resistance)
- **zkVMs with batching**: Dory (amortizes opening costs across many polynomials)



## Key Takeaways

### The Core Abstraction

1. **Polynomial commitments bridge theory and practice.** Interactive proofs reduce complex claims to polynomial identities, but verifying those identities directly requires seeing the entire polynomial. A PCS lets the prover commit to a polynomial with a short commitment, then prove evaluations at specific points without revealing anything else.

2. **The interface is simple: Commit, Open, Verify.** Binding ensures the prover can't change the polynomial after committing. Succinctness ensures commitments and proofs are much smaller than the polynomial itself. These two properties are what make succinct proofs possible.

3. **Polynomial evaluation reduces to inner product.** For a polynomial $f(X) = \sum c_i X^i$, the evaluation $f(z) = \langle \vec{c}, (1, z, z^2, \ldots) \rangle$. This connection underlies both IPA (which proves inner products directly) and Dory (which exploits tensor structure for multilinear polynomials).

### The Three Paradigms

4. **KZG achieves constant-size proofs via pairings.** The key insight: if $(X - z)$ divides $f(X) - v$, then $f(z) = v$. The prover commits to the quotient; the verifier checks divisibility at a secret point $\tau$ using one pairing equation. No matter the polynomial's size, the proof is one group element.

5. **KZG requires trusted setup.** The structured reference string encodes powers of a secret $\tau$. If anyone learns $\tau$, they can forge proofs. Multi-party ceremonies with thousands of participants ensure security under the "1-of-N" trust model: security holds if any single participant was honest.

6. **IPA eliminates trusted setup via recursive folding.** Each round halves the problem size by combining left and right halves with a random challenge. After $\log n$ rounds, the prover reveals a single scalar. The verifier checks consistency by tracking commitment updates through all rounds.

7. **IPA's bottleneck is linear verification.** The verifier must compute folded generators, requiring $O(n)$ group operations. This is acceptable for single proofs but prohibitive for recursive composition or blockchain verification where proofs are checked thousands of times.

8. **Dory achieves logarithmic verification without trusted setup.** The two-tier structure (Pedersen rows in $\mathbb{G}_1$, AFGHO commitment in $\mathbb{G}_T$) lets the verifier work entirely with commitments, updating accumulators each round without touching generators. Pairings absorb the folding challenges algebraically.

### Practical Considerations

9. **Batching amortizes costs across many polynomials.** KZG batches evaluations at multiple points into one proof. Dory batches multiple polynomials via Pedersen homomorphism, combining row commitments with random linear combinations. For systems like Jolt with dozens of committed polynomials, batching dominates the cost savings.

10. **The choice of PCS determines SNARK properties.** KZG gives constant verification with trusted setup (Groth16, PLONK). IPA gives transparency with linear verification (Halo). Dory gives transparency with logarithmic verification (Jolt). FRI (next chapter) gives post-quantum security. The right choice depends on whether you prioritize verification speed, trust minimization, or quantum resistance.





\newpage

# Chapter 10: Hash-Based Commitments and FRI: The Transparent Alternative

In 2016, the National Institute of Standards and Technology issued a warning that sent cryptographers scrambling. Quantum computers were coming, and they would break everything built on elliptic curves: RSA, Diffie-Hellman, ECDSA. This included every SNARK that existed. Groth16, the darling of the blockchain world, would become worthless the day a sufficiently powerful quantum computer came online.

The "toxic waste" problem of trusted setups was bad. The "quantum apocalypse" was existential.

This urgency drove the creation of a new kind of proof system. The goal was not just to remove the trusted setup; it was to build on the only cryptographic foundation that quantum computers cannot break: hash functions. When you use FRI, you are not just verifying a computation. You are future-proofing it against physics itself.

The answer came from Eli Ben-Sasson and collaborators: FRI (2017) and STARKs (2018). These are proof systems where "transparency" is not marketing but a technical property. No secrets. No ceremonies. No trapdoors that could compromise the system if they leaked, because no trapdoors exist at all.

---



## The Merkle Tree: Committing to Evaluations

The foundation of hash-based commitments is the **Merkle tree**. It lets us commit to a large dataset with a single hash value, then later prove any element is in the dataset.

**Construction**:

1. Place the data elements as leaves of a binary tree
2. Each internal node is the hash of its two children
3. The root is a commitment to the entire dataset

**Opening a value**: To prove that element $x$ is at position $i$:

1. Provide $x$ and the $\log n$ nodes along the path from $x$ to the root (the "authentication path")
2. The verifier recomputes hashes from leaf to root, checking the result matches the committed root

**Properties**:

- Commitment size: One hash (32 bytes typically)
- Opening proof size: $O(\log n)$ hashes
- Binding: Changing any leaf changes the root (collision-resistance of hash)

For polynomial commitments, we commit to the polynomial's evaluations over a domain. The Merkle root becomes the polynomial commitment.



## The Core Problem: Low-Degree Testing

Suppose the prover commits to a function $f: D \to \mathbb{F}$ by Merkle-committing its evaluations on a domain $D$ of size $n$. The prover claims $f$ is a low-degree polynomial (say degree less than $d$).

**The key mental model: a polynomial evaluation vector IS a Reed-Solomon codeword.** If you have a polynomial $f(X)$ of degree $d-1$ and you evaluate it at $n$ points (where $n > d$), the resulting vector $(f(x_1), f(x_2), \ldots, f(x_n))$ is a codeword of the Reed-Solomon code with parameters $[n, d]$. The polynomial's coefficients are the "message"; its evaluations are the "codeword." The extra evaluations beyond the $d$ needed to specify the polynomial are the "redundancy" that lets us detect errors. FRI is fundamentally a test that asks: does this committed vector look like a valid codeword, or has it been corrupted?

**Concrete example**: Say $f(X) = 3 + 2X + 5X^2$ over $\mathbb{F}_{17}$, and we choose domain $D = \{1, 2, 4, 8\}$ (powers of 2 mod 17). The prover evaluates $f$ at each point:

| $x$   | 1  | 2  | 4   | 8   |
|-------|----|----|-----|-----|
| $f(x)$| 10 | 27 ≡ 10 | 91 ≡ 6  | 339 ≡ 16 |

These four field elements become the leaves of a Merkle tree. Hash each leaf: $h_1 = H(10), h_2 = H(10), h_3 = H(6), h_4 = H(16)$. Then build the tree upward: $h_{12} = H(h_1 \| h_2)$, $h_{34} = H(h_3 \| h_4)$, and finally the root $r = H(h_{12} \| h_{34})$. This 32-byte root $r$ is the commitment to $f$.

To open at $x = 4$, the prover reveals the evaluation $f(4) = 6$ along with the Merkle path: $(h_4, h_{12})$. The verifier recomputes $H(6) \stackrel{?}{=} h_3$, then $H(h_3 \| h_4) \stackrel{?}{=} h_{34}$, then $H(h_{12} \| h_{34}) \stackrel{?}{=} r$. If all checks pass, the verifier is convinced that 6 was indeed the value committed at position 3 (the leaf for $x=4$).

How can the verifier check this without reading all $n$ values?

**The naive approach fails**: Checking random points doesn't help much. A function that agrees with a degree-$d$ polynomial on all but one point would pass most spot-checks but isn't low-degree.

**The Reed-Solomon perspective**: View a degree-$d$ polynomial evaluated on $n \gg d$ points as a codeword. Low-degree polynomials form a sparse subset of all possible functions; they're error-correcting codes with high minimum distance.

A function that's *not* a low-degree polynomial must differ from every codeword in many positions. FRI exploits this structure to catch deviations with high probability.

**Proximity, not exactness.** Strictly speaking, FRI does not prove that $f$ *is* a low-degree polynomial. It proves that $f$ is *close* to a low-degree polynomial, meaning it differs from some valid codeword in at most a small fraction of positions (say, 10%). This distinction matters because a cheater could take a valid polynomial and change just one evaluation point. FRI might miss that single corrupted point on any given query.

This is why we rely on the *soundness error*. We tune the parameters (rate, number of queries) so that being "close" is good enough for our application, or so that the probability of missing the difference is cryptographically negligible (e.g., $2^{-128}$). In practice, the gap between "is low-degree" and "is close to low-degree" vanishes into the security parameter.



## The FRI Insight: Split and Fold

FRI transforms the low-degree testing problem through a beautiful recursive technique.

**The key observation**: Any polynomial $f(X)$ can be decomposed into even and odd parts:

$$f(X) = f_E(X^2) + X \cdot f_O(X^2)$$

where:

- $f_E(Y)$ contains the even-power coefficients: $c_0 + c_2 Y + c_4 Y^2 + \cdots$
- $f_O(Y)$ contains the odd-power coefficients: $c_1 + c_3 Y + c_5 Y^2 + \cdots$

**Crucial property**: If $\deg(f) < d$, then both $\deg(f_E) < d/2$ and $\deg(f_O) < d/2$.

**The folding step**: Given a random challenge $\alpha$ from the verifier, define:

$$f_1(Y) = f_E(Y) + \alpha \cdot f_O(Y)$$

This is a new polynomial of degree $< d/2$. The claim "f has low degree" reduces to "$f_1$ has low degree": a strictly smaller problem!

Where do Merkle trees fit in? Each round, the prover commits to the new folded polynomial's evaluations via a fresh Merkle tree, then receives the next random challenge. The hash-based commitment binds the prover *before* seeing the challenge; this is what makes cheating hard. We'll see the full protocol shortly; first, let's trace through the algebra.



## Worked Example: One Round of FRI

Let's trace through folding in $\mathbb{F}_{17}$.

**Setup**:

- Initial polynomial: $f_0(X) = X^3 + 2X + 5$ (degree 3, so $d = 4$)
- Domain $D_0$: The subgroup of order 8 generated by $\omega = 9$

  $D_0 = \{1, 9, 13, 15, 16, 8, 4, 2\}$

**Step 1: Decompose into even and odd parts**

Coefficients: $(c_3, c_2, c_1, c_0) = (1, 0, 2, 5)$

- Even part: $f_{0,E}(Y) = c_2 Y + c_0 = 0 \cdot Y + 5 = 5$
- Odd part: $f_{0,O}(Y) = c_3 Y + c_1 = Y + 2$

Verify: $f_0(X) = 5 + X(X^2 + 2)$

**Step 2: Receive challenge and fold**

Verifier sends $\alpha_0 = 3$.

$$f_1(Y) = f_{0,E}(Y) + \alpha_0 \cdot f_{0,O}(Y) = 5 + 3(Y + 2) = 3Y + 11$$

**Result**: We've reduced proving $\deg(f_0) < 4$ to proving $\deg(f_1) < 2$.

**Step 3: New domain**

The new domain $D_1$ consists of the squares of elements in $D_0$:

$D_1 = \{1^2, 9^2, 13^2, 15^2\} = \{1, 13, 16, 4\}$ (size 4)

The prover evaluates $f_1$ on $D_1$:

- $f_1(1) = 3(1) + 11 = 14$
- $f_1(13) = 3(13) + 11 = 50 \equiv 16 \pmod{17}$
- $f_1(16) = 3(16) + 11 = 59 \equiv 8 \pmod{17}$
- $f_1(4) = 3(4) + 11 = 23 \equiv 6 \pmod{17}$

**Repeat**: Another round with challenge $\alpha_1 = 7$:

$$f_2(Z) = 11 + 7 \cdot 3 = 11 + 21 = 32 \equiv 15 \pmod{17}$$

$f_2$ is a constant! The recursion terminates. The prover sends the constant $15$ in the clear.



## The Folding Paradigm

FRI's "split and fold" is not an isolated trick; it's an instance of one of the most powerful patterns in zero-knowledge proofs. Now that we've seen it concretely, let's step back and recognize where we've encountered it before.

**The pattern**: Use a random challenge to collapse two objects into one, halving the problem size while preserving the ability to detect cheating.

More precisely:

1. You have a claim about a "large" object (size $n$, degree $d$, dimension $k$)
2. Split the object into two "halves"
3. Receive a random challenge $\alpha$
4. Combine the halves via weighted sum: $\text{new} = \text{left} + \alpha \cdot \text{right}$
5. The claim about the original reduces to a claim about the folded object (size $n/2$, degree $d/2$, dimension $k-1$)
6. Repeat until trivial

**Why does randomness make this work?** If the original object was "bad" (not low-degree, not satisfying a constraint), the two halves encode this badness. A cheater would need the errors in left and right to cancel: $\text{error}_L + \alpha \cdot \text{error}_R = 0$. But they committed to both halves *before* seeing $\alpha$, so this requires $\alpha = -\text{error}_L / \text{error}_R$ (a single value out of the entire field). Probability $\leq d/|\mathbb{F}|$.

**Where we've seen folding**:

- **MLE streaming evaluation (Chapter 4)**: Fold a table of $2^n$ values down to one. Each step combines $(T(0, \ldots), T(1, \ldots))$ with weights $(1-r, r)$.

- **Sum-check (Chapter 3)**: Each round folds the hypercube in half. A claim "$\sum_{b \in \{0,1\}^n} g(b) = H$" becomes "$\sum_{b \in \{0,1\}^{n-1}} g(r_1, b) = V_1$".

- **FRI (this chapter)**: Fold the polynomial's coefficient space. A degree-$d$ polynomial becomes degree-$d/2$ via $f_E + \alpha \cdot f_O$.

- **IPA/Bulletproofs (Chapter 9)**: Fold the commitment vector. Two group elements become one: $C' = C_L^{\alpha^{-1}} \cdot C_R^{\alpha}$.

**The deep insight**: Folding is *dimension reduction via randomness*. High-dimensional objects are hard to verify directly; you'd need to check exponentially many conditions. But each random fold projects away one dimension while preserving the distinction between valid and invalid objects (with overwhelming probability). After $\log n$ folds, you're left with a trivial claim.

And yet the structure persists. At each level, the polynomial is smaller but the relationships that matter (the algebraic constraints, the divisibility conditions, the distance from invalidity) all survive the descent. You're looking at a different polynomial in a smaller domain, but it's recognizably the same *kind* of object, facing the same *kind* of test. The recursion doesn't change the nature of the problem, only its scale.

**Why this works algebraically**: The objects being folded have low-degree polynomial structure. Schwartz-Zippel guarantees that distinct low-degree polynomials disagree almost everywhere. A random linear combination of two distinct polynomials is still distinct from the "honest" combination; you can't make errors cancel without predicting the randomness.

**Folding as the algorithmic Schwartz-Zippel**: One way to test if a polynomial is zero: evaluate at a random point. Folding is this idea applied recursively with structure. Each fold is a random evaluation in disguise, and the structure ensures that evaluations compose coherently across rounds.

This paradigm extends beyond what we cover here. *Nova* and *folding schemes* (Chapter 22) fold entire R1CS instances: not polynomials, but constraint systems. The same principle applies: random linear combination of two instances yields a "relaxed" instance that's satisfiable iff both originals were.



## The FRI Folding Process: Visual Overview

```
+----------------------------------------------------------------------+
|                      FRI RECURSIVE FOLDING                           |
+----------------------------------------------------------------------+
|                                                                      |
|  ROUND 0: f_0(X) has degree < d, evaluated on domain D_0 (size n)    |
|                                                                      |
|     f_0(X) = f_{0,E}(X^2) + X * f_{0,O}(X^2)                         |
|              '---even---'     '---odd---'                            |
|                    |            |                                    |
|                    '-----+------'                                    |
|                          v                                           |
|                    f_1(Y) = f_{0,E}(Y) + a_0 * f_{0,O}(Y)            |
|                                    ^                                 |
|                         random challenge from verifier               |
|                                                                      |
|  RESULT: f_1 has degree < d/2, evaluated on D_1 (size n/2)           |
+----------------------------------------------------------------------+
|                                                                      |
|  ROUND 1: Repeat with f_1                                            |
|                                                                      |
|     f_1(Y) = f_{1,E}(Y^2) + Y * f_{1,O}(Y^2)                         |
|                    |            |                                    |
|                    '-----+------'                                    |
|                          v                                           |
|                    f_2(Z) = f_{1,E}(Z) + a_1 * f_{1,O}(Z)            |
|                                                                      |
|  RESULT: f_2 has degree < d/4, evaluated on D_2 (size n/4)           |
+----------------------------------------------------------------------+
|                                                                      |
|                        ... log(d) rounds ...                         |
|                                                                      |
+----------------------------------------------------------------------+
|                                                                      |
|  FINAL ROUND: f_k is a CONSTANT                                      |
|                                                                      |
|     degree < d/2^k = 1  ->  f_k = c  (prover sends c directly)       |
|                                                                      |
+----------------------------------------------------------------------+

DOMAIN SHRINKAGE:    n → n/2 → n/4 → ... → constant
DEGREE SHRINKAGE:    d → d/2 → d/4 → ... → 1

Each round: Prover commits via Merkle tree, receives random α
```


## The Full FRI Protocol

FRI consists of two phases: **Commit** and **Query**.

### Commit Phase

The prover and verifier engage in $\log_2(d)$ rounds:

**Round $i$**:

1. Prover computes evaluations of $f_i$ on domain $D_i$
2. Prover commits to these evaluations via Merkle tree, sends root to verifier
3. Verifier sends random challenge $\alpha_i$
4. Prover computes $f_{i+1}$ using the folding formula

**Final round**: When the polynomial reaches constant degree, the prover sends the constant value $c$ directly (no Merkle commitment, just the raw field element). At this point the verifier holds:

- $\log_2(d)$ Merkle roots (one per folding round)
- The random challenges $\alpha_0, \ldots, \alpha_{\log d - 1}$
- A claimed final constant $c$

But wait: how does the verifier know the prover didn't just make up a convenient constant? This is where the query phase becomes crucial.

### Query Phase

The verifier must check that the prover didn't cheat during folding. The key insight: *the final constant must be consistent with all the committed codewords*. If the prover lies about $c$, that lie must propagate backward through every round, creating inconsistencies that random queries will catch.

1. **Pick random query position** in the final domain

2. **Unfold** to find corresponding positions in earlier domains:
   - Each point $y$ in $D_{i+1}$ has two "preimages" in $D_i$: the values $x$ and $-x$ such that $x^2 = y$
   - The verifier traces back through all rounds

   **Why pairs?** In the domain $D_0$, the points come in pairs $\{x, -x\}$ that both square to the same value $x^2$. This is a property of multiplicative subgroups: if $\omega$ generates $D_0$, then $-1 = \omega^{n/2}$, so $-x$ is also in the group whenever $x$ is. This means the folding structure is perfectly aligned: we always fold $f(x)$ and $f(-x)$ together to get the value at $x^2$ in the next domain. The pairing is not a coincidence; it is why FRI works over multiplicative subgroups.

3. **Query the prover**: Request evaluations at these positions from each committed codeword, with Merkle proofs

4. **Verify consistency**: Check that the folding relationship holds at each round:

   $$f_{i+1}(y) = \frac{f_i(x) + f_i(-x)}{2} + \alpha_i \cdot \frac{f_i(x) - f_i(-x)}{2x}$$

   Crucially, this check *includes* the final round: the verifier computes what $f_k(y)$ *should* be from the last committed codeword $f_{k-1}$, and checks that it equals the claimed constant $c$. If the prover lied about $c$, this check will fail (with high probability over the random query point).

5. **Repeat** with multiple random queries for amplified security

Each query traces a path from the claimed constant all the way back to the original commitment, checking consistency at every step. With $\lambda$ queries, the probability of a cheating prover escaping is roughly $\rho^\lambda$ where $\rho < 1$ depends on the code rate.

### Worked Example: Query Phase Verification

Let's continue our earlier example and trace through a complete query. Recall:

- $f_0(X) = X^3 + 2X + 5$ over $\mathbb{F}_{17}$
- Domain $D_0 = \{1, 9, 13, 15, 16, 8, 4, 2\}$ (8 elements)
- Challenge $\alpha_0 = 3$ produced $f_1(Y) = 3Y + 11$
- Domain $D_1 = \{1, 13, 16, 4\}$ (4 elements)
- Challenge $\alpha_1 = 7$ produced $f_2 = 15$ (constant)

The prover has committed to codewords (evaluations of $f_0$ on $D_0$ and $f_1$ on $D_1$) via Merkle trees, then sent the constant 15.

**Step 1: Verifier picks a random query point**

The verifier chooses a random position in $D_1$, say $y = 13$.

**Step 2: Unfold to find preimages**

What points in $D_0$ square to 13? We need $x$ such that $x^2 \equiv 13 \pmod{17}$.

Checking: $9^2 = 81 \equiv 13$ and $(-9)^2 = 8^2 = 64 \equiv 13$. $\checkmark$

So the preimages are $x = 9$ and $-x = 8$.

**Step 3: Query the prover**

The verifier requests:

- $f_0(9)$ and $f_0(8)$ from the first Merkle tree
- $f_1(13)$ from the second Merkle tree

The prover supplies these values with Merkle authentication paths. Let's compute:

- $f_0(9) = 9^3 + 2(9) + 5 = 729 + 18 + 5 \equiv 15 + 1 + 5 = 21 \equiv 4 \pmod{17}$
- $f_0(8) = 8^3 + 2(8) + 5 = 512 + 16 + 5 \equiv 2 + 16 + 5 = 23 \equiv 6 \pmod{17}$
- $f_1(13) = 3(13) + 11 = 50 \equiv 16 \pmod{17}$

**Step 4: Verify consistency (Round 0 → 1)**

The verifier checks: does $f_1(13)$ equal the folded value from $f_0(9)$ and $f_0(8)$?

The consistency formula recovers the even and odd parts from evaluations at $x$ and $-x$:
$$f_{0,E}(y) = \frac{f_0(x) + f_0(-x)}{2}, \quad f_{0,O}(y) = \frac{f_0(x) - f_0(-x)}{2x}$$

With $x = 9$, $-x = 8$, $y = x^2 = 13$:

$$f_{0,E}(13) = \frac{4 + 6}{2} = \frac{10}{2} = 5$$

For the odd part, note that $2x = 18 \equiv 1 \pmod{17}$:
$$f_{0,O}(13) = \frac{4 - 6}{1} = -2 \equiv 15 \pmod{17}$$

Now apply the folding with $\alpha_0 = 3$:
$$f_1(13) \stackrel{?}{=} f_{0,E}(13) + \alpha_0 \cdot f_{0,O}(13) = 5 + 3 \cdot 15 = 5 + 45 = 50 \equiv 16 \pmod{17}$$

$\checkmark$ The Round 0 → 1 consistency check passes.

**Step 5: Verify consistency (Round 1 → 2)**

Now check: does the claimed constant $c = 15$ match what we'd get from folding $f_1$?

For the final round, the "domain" $D_2$ has collapsed to a single point. The verifier checks:
$$c \stackrel{?}{=} \frac{f_1(y) + f_1(-y)}{2} + \alpha_1 \cdot \frac{f_1(y) - f_1(-y)}{2y}$$

We have $y = 13$, so $-y = -13 \equiv 4 \pmod{17}$.

We need $f_1(4)$. From the Merkle commitment: $f_1(4) = 3(4) + 11 = 23 \equiv 6 \pmod{17}$.

$$\frac{f_1(13) + f_1(4)}{2} = \frac{16 + 6}{2} = \frac{22}{2} = 11$$

For the second term, we need $(2 \cdot 13)^{-1} = 26^{-1} = 9^{-1} \equiv 2 \pmod{17}$:
$$\frac{f_1(13) - f_1(4)}{2 \cdot 13} = \frac{16 - 6}{26} = \frac{10}{9} = 10 \cdot 2 = 20 \equiv 3 \pmod{17}$$

$$c \stackrel{?}{=} 11 + 7 \cdot 3 = 11 + 21 = 32 \equiv 15 \pmod{17}$$

$\checkmark$ **The query passes.** Both consistency checks hold, confirming that (at this query point) the prover's commitments are consistent with honest folding.

If the prover had lied about the constant, say claimed $c = 10$ instead of 15, this final check would fail: $11 + 21 = 32 \equiv 15 \neq 10$.

The verifier repeats this process at multiple random query points. Each independent query that passes increases confidence that the prover's polynomial truly has low degree.



## Why FRI Works: Security Intuition

**The Tuning Fork Analogy.** Imagine you have a metal bar. You want to know if it is pure gold (a valid low-degree polynomial) or gold-plated lead (an invalid function pretending to be low-degree). You cannot drill into it to read all its coefficients directly. But you can *strike* it with a tuning fork (fold it with a random challenge).

A pure gold bar will ring with a pure tone (stay low-degree) no matter where you strike it. A plated bar might sound okay at first, but as you keep striking it in random places (random $\alpha$ values), the hidden flaws (high-degree terms) will cause the tone to distort. FRI is essentially striking the polynomial repeatedly. If it keeps "ringing true" after $\log d$ random strikes, it must be pure.

**Honest prover**: Starts with a genuine low-degree polynomial. Every folded polynomial remains low-degree. All consistency checks pass perfectly.

**Dishonest prover** (claiming a non-low-degree function is low-degree):

- **Option 1**: Fold honestly. The folded functions remain "far" from low-degree, eventually producing a non-constant at the final round (caught!).

- **Option 2**: Commit to fake low-degree polynomials that don't match the folding. The consistency checks will fail at random query points with high probability.

The soundness comes from the distance properties of Reed-Solomon codes. A function far from any low-degree polynomial must disagree at many positions. Random queries will catch these disagreements.

### Soundness and DEEP-FRI

The original FRI analysis (Ben-Sasson et al. 2018) established soundness but with somewhat pessimistic bounds. Achieving 128-bit security required many queries, increasing proof size.

**DEEP-FRI** (Ben-Sasson et al. 2019) improves soundness by sampling *outside* the evaluation domain. The idea: after the prover commits to the polynomial $f$, the verifier picks a random point $z$ outside $D$ and asks the prover to reveal $f(z)$. This "out-of-domain" sample provides additional security because a cheating prover can't anticipate which external point will be queried.

The name stands for **D**omain **E**xtending for **E**liminating **P**retenders. The technique achieves tighter soundness bounds, reducing the number of queries needed for a given security level.

**Recent advances**: STIR (2024) achieves query complexity $O(\log d + \lambda \log \log d)$ compared to FRI's $O(\lambda \log d)$, where $\lambda$ is the security parameter and $d$ is the degree bound. WHIR (2024) further improves verification time to a few hundred microseconds. These protocols maintain FRI's core split-and-fold structure while optimizing the recursion.



## FRI as a Polynomial Commitment Scheme

So far we've shown how FRI proves that a function is close to a low-degree polynomial. But a polynomial commitment scheme needs to prove *evaluation claims*: "my committed polynomial $f$ satisfies $f(z) = v$." How do we bridge this gap?

The answer uses the **divisibility trick** from earlier chapters.

### Applying the Divisibility Trick

Recall that $f(z) = v$ if and only if $(X - z)$ divides $f(X) - v$. When the claim is true, the quotient $q(X) = \frac{f(X) - v}{X - z}$ is a polynomial of degree $\deg(f) - 1$. When the claim is false, this "quotient" has a pole at $z$; it's not a polynomial at all.

This transforms evaluation proofs into degree bounds:

| If... | Then the quotient $q(X) = \frac{f(X) - v}{X - z}$... |
|-------|------------------------------------------------------|
| $f(z) = v$ (honest) | is a polynomial of degree $\deg(f) - 1$ |
| $f(z) \neq v$ (cheating) | has a pole at $z$; not a polynomial at all |

**The protocol idea**: To prove $f(z) = v$, prove that $q(X)$ is low-degree. If FRI accepts, the quotient is (close to) a polynomial, which means the division was clean, which means $f(z) = v$.

### The Full Protocol

**Commit $(f)$**: Evaluate $f$ on the domain $D$, build a Merkle tree over the evaluations, output the root.

**Open $(f, z, v)$**: To prove $f(z) = v$:

1. Compute $q(x) = \frac{f(x) - v}{x - z}$ for each $x \in D$
2. Commit to $q$ via Merkle tree
3. Run FRI on $q$ to prove $\deg(q) < \deg(f)$
4. The verifier spot-checks the relationship $f(x) - v = (x - z) \cdot q(x)$ at the FRI query points

**Verify**:

- Run FRI verification on $q$
- At each queried point $x$, check that $f(x) - v = (x - z) \cdot q(x)$

### Why the Spot-Checks Matter

The FRI proof only shows that $q$ is low-degree. But a cheating prover could commit to *any* low-degree polynomial as "$q$", not necessarily the one derived from $f$. The spot-checks tie $q$ back to $f$:

At random query points $x_1, \ldots, x_\lambda$, the verifier requests $f(x_i)$ and $q(x_i)$ (with Merkle proofs), then checks:
$$f(x_i) - v \stackrel{?}{=} (x_i - z) \cdot q(x_i)$$

If the prover committed to genuine evaluations of $f$ and the correct quotient $q$, these checks pass. If the prover lied, using a $q$ that doesn't equal $(f - v)/(X - z)$, the identity will fail at most queried points.

### Batching

Multiple polynomials and evaluation points can be combined into a single FRI proof:

1. Use random linear combinations to merge multiple quotient polynomials
2. Run one FRI proof on the combined polynomial
3. Include spot-checks for each original claim

This amortizes the FRI cost over many opening proofs.


## Practical Considerations

### The Blow-up Factor

FRI evaluates polynomials on a domain much larger than their degree. If a polynomial has degree $d$, the evaluation domain has size $n = \rho^{-1} \cdot d$ where $\rho < 1$ is the **rate**.

Typical choices: $\rho = 1/4$ to $1/16$ (blow-up factor 4x to 16x).

**Trade-off**: Lower rate (more redundancy) means:

- Larger initial commitment (more evaluations)
- But stronger soundness per query (fewer queries needed)
- Net effect often neutral on total proof size

### Coset Domains

Rather than using subgroups directly, FRI typically uses **cosets**: sets of the form $g \cdot H$ where $H$ is a multiplicative subgroup.

This avoids potential algebraic attacks exploiting the structure of subgroups (like $x^n = 1$).

### Hash Function Choice

STARKs using FRI rely on collision-resistant hash functions:

- Traditional: SHA-256, Keccak
- SNARK-friendly: Poseidon, Rescue (fewer constraints when verified in-circuit)

The hash function determines concrete security. If the hash has 256-bit output, and we assume collision-resistance, FRI inherits 128-bit security (birthday bound).


## Comparing FRI to Algebraic PCS

| Property        | FRI                       | KZG             | IPA           |
|-----------------|---------------------------|-----------------|---------------|
| Trusted setup   | None                      | Required        | None          |
| Assumption      | Hash collision-resistance | Pairings + DLog | DLog          |
| Post-quantum    | Yes                       | No              | No            |
| Commitment size | $O(1)$                    | $O(1)$          | $O(1)$        |
| Proof size      | $O(\lambda \log^2 d)$     | $O(1)$          | $O(\log d)$   |
| Verifier time   | $O(\lambda \log^2 d)$     | $O(1)$          | $O(d)$        |
| Prover time     | $O(d \log d)$             | $O(d)$          | $O(d \log d)$ |

**When to use FRI**:

- Trust minimization is critical (no setup ceremony)
- Post-quantum security is required
- Larger proofs are acceptable (still polylogarithmic)

**When to avoid FRI**:

- Proof size must be constant (KZG better)
- On-chain verification cost is critical (pairing checks cheaper than FRI verification)



## FRI in the Wild: STARKs

FRI is the cryptographic backbone of **STARKs** (Scalable Transparent ARguments of Knowledge):

1. **Arithmetization**: Convert computation to polynomial constraints (AIR format)
2. **Low-degree extension**: Encode computation trace as polynomial evaluations
3. **Constraint checking**: Combine with composition polynomial
4. **FRI**: Prove the composed polynomial is low-degree

The "T" in STARK stands for "Transparent": no trusted setup, enabled by FRI.
The "S" stands for "Scalable": prover time is quasi-linear, enabled by FFT and the recursive structure of FRI.

Modern systems like **Plonky2** and **Plonky3** combine PLONK's flexible arithmetization with FRI-based commitments, getting the best of both worlds.


## Key Takeaways

1. **Hash-based foundations**: Merkle trees let us commit to large datasets with a single hash root.

2. **Low-degree testing**: The core FRI problem is checking whether a committed function is "close to" a low-degree polynomial.

3. **Split-and-fold**: Decompose $f(X) = f_E(X^2) + X \cdot f_O(X^2)$, then fold with random challenge to halve the degree.

4. **Commit phase**: $\log d$ rounds of folding, each producing a Merkle commitment.

5. **Query phase**: Random consistency checks verify folding was honest.

6. **Soundness**: Based on Reed-Solomon distance; functions far from low-degree disagree at many points.

7. **Divisibility encodes evaluation**: $f(z) = v$ iff $(X - z)$ divides $f(X) - v$. Prove evaluation claims by showing the quotient $(f(X) - v)/(X - z)$ is low-degree.

8. **Transparency**: No secrets, no trusted setup, anyone can verify.

9. **Post-quantum**: Based on hash functions, resistant to quantum algorithms.

10. **Trade-off**: Larger proofs than KZG, but no trust assumptions beyond hash security.



\newpage

# Chapter 11: The SNARK Recipe: Assembling the Pieces

Before 1913, building a car was a bespoke craft. Mechanics hand-fitted gears, engines, and chassis. It was slow, expensive, and inconsistent. Then Henry Ford introduced the assembly line. He realized that if you standardized the parts and the process, you could build complex machines at scale.

For the first 30 years of zero-knowledge (1985–2015), protocols were bespoke. A cryptographer would hand-craft a protocol for Graph Isomorphism, then start from scratch to build one for Hamiltonian Cycles. Each proof system was a custom creation, and expertise in one barely transferred to another.

Then came the realization: we don't need bespoke proofs. We need an assembly line. We need a standardized way to take *any* computation, feed it into a machine, and get a proof out the other side. This chapter describes that machine. It is the recipe that powers every modern SNARK, from Groth16 to Halo 2 to STARKs. It turns the art of cryptography into engineering.

Modern SNARKs decompose into three layers, each with a distinct role. Understanding this decomposition is more valuable than memorizing any particular system; it provides the conceptual vocabulary to navigate the entire landscape.



## The Three-Layer Architecture

Every modern SNARK follows the same structural pattern:

```
┌───────────────────────────────────────────────────────────────────────┐
│                    THE SNARK CONSTRUCTION PIPELINE                     │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   ┌─────────────────────────────────────────────────────────────┐    │
│   │  COMPUTATION                                                 │    │
│   │  "I know x such that f(x) = y"                              │    │
│   └───────────────────────────────┬─────────────────────────────┘    │
│                                   │                                   │
│                                   ▼  Arithmetization                  │
│   ┌─────────────────────────────────────────────────────────────┐    │
│   │  POLYNOMIAL CONSTRAINTS                                      │    │
│   │  R1CS, PLONK gates, AIR, etc.                               │    │
│   └───────────────────────────────┬─────────────────────────────┘    │
│                                   │                                   │
│                                   ▼                                   │
│  ╔═════════════════════════════════════════════════════════════════╗ │
│  ║  LAYER 1: Interactive Oracle Proof (IOP)                        ║ │
│  ║                                                                  ║ │
│  ║  • Prover sends polynomials (abstractly)                        ║ │
│  ║  • Verifier queries evaluations at random points                ║ │
│  ║  • Protocol logic: what to check, how to challenge              ║ │
│  ║                                                                  ║ │
│  ║  Examples: Sum-check, PLONK IOP, GKR                            ║ │
│  ╚══════════════════════════════════╤══════════════════════════════╝ │
│                                     │                                 │
│                                     ▼                                 │
│  ╔═════════════════════════════════════════════════════════════════╗ │
│  ║  LAYER 2: Polynomial Commitment Scheme (PCS)                    ║ │
│  ║                                                                  ║ │
│  ║  • Commit: polynomial → short commitment                        ║ │
│  ║  • Open: prove evaluation at a point                            ║ │
│  ║  • Binding: can't change polynomial after commit                ║ │
│  ║                                                                  ║ │
│  ║  Options: KZG (trusted), IPA (transparent), FRI (post-quantum)  ║ │
│  ╚══════════════════════════════════╤══════════════════════════════╝ │
│                                     │                                 │
│                                     ▼                                 │
│  ╔═════════════════════════════════════════════════════════════════╗ │
│  ║  LAYER 3: Fiat-Shamir Transformation                            ║ │
│  ║                                                                  ║ │
│  ║  • Replace verifier randomness with hash outputs                ║ │
│  ║  • Challenge = Hash(transcript so far)                          ║ │
│  ║  • Interactive → Non-interactive                                ║ │
│  ║                                                                  ║ │
│  ║  Security: Random Oracle Model                                  ║ │
│  ╚══════════════════════════════════╤══════════════════════════════╝ │
│                                     │                                 │
│                                     ▼                                 │
│   ┌─────────────────────────────────────────────────────────────┐    │
│   │  RESULT: Non-Interactive Zero-Knowledge Argument (SNARK)    │    │
│   │                                                              │    │
│   │  • Proof: ~100 bytes to ~100 KB depending on choices        │    │
│   │  • Verification: milliseconds, independent of circuit size  │    │
│   │  • Properties: succinct, sound, (optionally) zero-knowledge │    │
│   └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
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

**The Time Travel Intuition.** In an interactive proof, the verifier sends a random challenge *after* the prover commits. The prover cannot change the past. In a non-interactive proof, the prover generates the challenge themselves. What stops them from cheating?

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



\newpage

# Chapter 12: Groth16: The Pairing-Based Optimal

In 2016, when Zcash was preparing to launch, they faced a practical problem. Blockchain transactions are expensive. Every byte costs money. The existing SNARKs (Pinocchio and its descendants) required proofs of nearly 300 bytes. It was workable, but clunky.

Then Jens Groth published a paper that seemed to violate the laws of physics. He shaved the proof down to 128 bytes on BN254. To demonstrate just how small this was, developers realized they could fit an entire zero-knowledge proof, verifying a computation of millions of steps, into a single tweet:

`[Proof: 0x1a2b3c...] #Zcash`

This was not just optimization. It was perfection. Groth proved mathematically that for pairing-based systems, you literally cannot get smaller than 3 group elements. He had found the floor.

The paper, "On the Size of Pairing-based Non-interactive Arguments," became the most deployed SNARK in history. When Zcash launched its Sapling upgrade in 2018, it used Groth16. When Tornado Cash and dozens of other privacy applications needed succinct proofs, they used Groth16. The answer to "what's the smallest possible proof?" turned out to be the answer the entire field needed.

---

The SNARKs we've studied follow a common pattern: construct an IOP, compile it with a polynomial commitment scheme, apply Fiat-Shamir. This modular approach yields flexible systems (swap the PCS, change the trust assumptions) but it leaves efficiency on the table.

Groth16 takes a different path. Rather than instantiating a generic framework, it was designed from first principles to minimize one specific metric: proof size. The result is a proof consisting of exactly three group elements (roughly 128 bytes on standard curves). Verification requires three pairing operations. Nothing smaller exists within the pairing-based paradigm; Groth16 sits at the theoretical minimum for systems of its class.

This optimality comes with constraints. The trusted setup is circuit-specific: change a single gate and you need a new ceremony. The prover cannot be made faster than $O(n \log n)$ without giving up something else. Zero-knowledge requires careful blinding that's woven into the protocol's fabric rather than layered on top.

Understanding Groth16 requires thinking at a different level of abstraction. The three-layer IOP/PCS/Fiat-Shamir decomposition still applies, but the layers are fused: optimized as a unit rather than composed as modules. What we gain is unmatched succinctness. What we pay is inflexibility.



## From R1CS to Polynomial Identity

Chapter 8 introduced R1CS: the prover demonstrates knowledge of a witness vector $Z$ satisfying

$$(A \cdot Z) \circ (B \cdot Z) = C \cdot Z$$

where $A$, $B$, $C$ are matrices encoding the circuit and $\circ$ denotes the Hadamard (element-wise) product. Each row enforces one constraint of the form $(a \cdot Z)(b \cdot Z) = c \cdot Z$.

Groth16's first move is to transform this system of $m$ constraints into a single polynomial identity.

### The QAP Transformation

Fix a set of $m$ distinct evaluation points $\omega_1, \ldots, \omega_m$ in the field $\mathbb{F}$. For each column $j$ of the matrices, define polynomials $A_j(X)$, $B_j(X)$, $C_j(X)$ by Lagrange interpolation:

$$A_j(\omega_i) = A_{ij}, \quad B_j(\omega_i) = B_{ij}, \quad C_j(\omega_i) = C_{ij}$$

These are the **basis polynomials**: one for each wire in the circuit. They encode the circuit's structure: which wires participate in which constraints, with what coefficients.

Given witness $Z = (z_0, z_1, \ldots, z_{n-1})$, form the **witness polynomials**:

$$A(X) = \sum_{j=0}^{n-1} z_j \cdot A_j(X), \quad B(X) = \sum_{j=0}^{n-1} z_j \cdot B_j(X), \quad C(X) = \sum_{j=0}^{n-1} z_j \cdot C_j(X)$$

The construction ensures that at each evaluation point $\omega_i$, the witness polynomial $A(\omega_i)$ equals the dot product $A_i \cdot Z$: exactly the value appearing in the $i$-th constraint. The polynomial encapsulates all constraints simultaneously.

**The R1CS Condition Becomes a Polynomial Vanishing Condition**

The R1CS is satisfied if and only if:

$$A(\omega_i) \cdot B(\omega_i) - C(\omega_i) = 0 \quad \text{for all } i \in \{1, \ldots, m\}$$

This says the polynomial $P(X) = A(X) \cdot B(X) - C(X)$ vanishes at every $\omega_i$. By the factor theorem, $P(X)$ must be divisible by the **vanishing polynomial**:

$$Z_H(X) = \prod_{i=1}^{m} (X - \omega_i)$$

The R1CS is satisfied if and only if there exists a polynomial $H(X)$, the **quotient** or **cofactor**, such that:

$$A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$$

This is the **QAP (Quadratic Arithmetic Program) identity**. It compresses $m$ constraint checks into one polynomial divisibility claim.

### Worked Example: Continuing $x^3 + x + 5 = 35$

From Chapter 8, we have 5 constraints and 7 witness positions. Let the evaluation points be $\{1, 2, 3, 4, 5\}$.

The witness is $Z = (1, 35, 3, 9, 27, 30, 35)$ representing $(1, \text{output}, x, x^2, x^3, x^3+x, x^3+x+5)$.

For the second column (corresponding to variable $x$), the column vector in $A$ is $(1, 0, 1, 0, 0)$, representing that $x$ appears in constraints 1 and 3. The basis polynomial $A_2(X)$ interpolates through points $(1, 1), (2, 0), (3, 1), (4, 0), (5, 0)$:

$$A_2(X) = 1 \cdot L_1(X) + 1 \cdot L_3(X)$$

where $L_i(X)$ is the $i$-th Lagrange basis polynomial.

After computing all basis polynomials and forming the witness polynomials, the quotient $H(X)$ exists and has degree $\deg(A \cdot B) - \deg(Z_H) = 2(m-1) - m = m - 2$.

## The Core Protocol Idea

Verifying the QAP identity directly requires evaluating polynomials of degree $O(m)$, far too expensive for succinctness. The Schwartz-Zippel approach suggests evaluating at a random point $\tau$: if $A(\tau) \cdot B(\tau) - C(\tau) = H(\tau) \cdot Z_H(\tau)$, then the identity holds with overwhelming probability.

But the witness polynomials encode the secret witness. We cannot simply send $A(\tau)$ to the verifier.

Groth16 solves this with three ideas working in concert:

1. **Homomorphic hiding**: Evaluate in the exponent. Send $g^{A(\tau)}$ instead of $A(\tau)$.

2. **Pairing verification**: Check multiplication via bilinear pairing. The equation $e(g^a, g^b) = e(g, g)^{ab}$ lets the verifier check multiplicative relations on hidden values.

3. **Structured randomness**: Embed the check into the trusted setup. The verifier never sees $\tau$; they receive encoded values that enable verification without knowing the secret.

### Linear PCPs: The Abstraction

Groth16 is best understood through the lens of **Linear PCPs** (Probabilistically Checkable Proofs where the proof is a linear function).

In a standard PCP, the verifier queries specific positions of a proof string. In a Linear PCP, the "proof" is a linear function $\pi: \mathbb{F}^k \to \mathbb{F}$, and the verifier queries $\pi(q)$ for chosen query vectors $q$.

**The Shadow Puppet Intuition.** Imagine you want to prove your hands are tied in a specific knot, but you cannot show your hands directly (zero-knowledge). In a Linear PCP, the trusted setup is a light source placed at a very specific, secret angle ($\tau$). You hold up your "polynomial" hands. The verifier only sees the shadow on the wall (the group elements).

Because the light source is fixed and secret, you cannot fake the shadow. If the shadow looks like a knot, your hands must be tied. The linearity comes from the fact that you can move your fingers (add group elements), and the shadow moves exactly in sync. But you cannot create shadows that don't correspond to real hand positions.

The critical insight: if the prover must respond with $\pi(q)$ for a linear function $\pi$, and the queries are encrypted as $g^q$, then the response $g^{\pi(q)}$ can be computed homomorphically without knowing $q$.

Groth16's trusted setup embeds carefully chosen query vectors into group elements. The prover computes responses using only scalar multiplication: linear operations on the encrypted queries. The verifier checks a quadratic relation using a single pairing equation.

This is why the proof has exactly three elements: the protocol is optimized around one pairing check (which is quadratic in its inputs), requiring one element from each source group to achieve non-linearity.

## The Trusted Setup

Groth16 requires a **Structured Reference String (SRS)** generated by a trusted ceremony. The ceremony has two phases with fundamentally different properties.

### Phase 1: Powers of Tau (Universal)

A secret random value $\tau \in \mathbb{F}^*$ is chosen. The ceremony outputs encrypted powers:

$$\{g_1, g_1^{\tau}, g_1^{\tau^2}, \ldots, g_1^{\tau^{d}}\} \quad \text{and} \quad \{g_2, g_2^{\tau}, g_2^{\tau^2}, \ldots, g_2^{\tau^{d}}\}$$

where $d$ is large enough to support circuits up to a certain size.

This phase is **universal**: the same Powers of Tau can be used for any circuit within the size bound. Public ceremonies like "Perpetual Powers of Tau" provide reusable parameters.

The ceremony is a multi-party computation (MPC) with a **1-of-N trust model**. Each participant $i$ chooses secret $t_i$, updates the running parameters by raising to the $t_i$-th power, and deletes $t_i$. The final $\tau = t_1 \cdot t_2 \cdots t_N$ is unknown to everyone provided at least one participant was honest.

### Phase 2: Circuit-Specific Secrets

Phase 2 generates additional secrets $\alpha, \beta, \gamma, \delta \in \mathbb{F}^*$ that are specific to the circuit being proven. These secrets serve structural roles:

**$\alpha$ and $\beta$ (Cross-term cancellation)**: When the prover constructs their proof elements, the verification equation produces "cross-terms" like $\alpha \cdot B(\tau)$. The $\alpha, \beta$ blinding ensures these terms cancel correctly without revealing the witness.

**$\gamma$ (Public input binding)**: Separates public from private inputs in the verification equation. The verifier computes a commitment to the public inputs and checks it against the $\gamma$-scaled portion of the SRS.

**$\delta$ (Private witness binding)**: Forces the prover to use consistent values across the $A$, $B$, and $C$ polynomials. Without $\delta$, the prover could use different witnesses for different polynomials (a completeness attack).

### Why Phase 2 Cannot Be Universal

The Phase 2 parameters are not generic encrypted powers; they are **circuit-specific combinations** like:

$$g_1^{\frac{\beta \cdot A_j(\tau) + \alpha \cdot B_j(\tau) + C_j(\tau)}{\delta}}$$

These encode the basis polynomials $A_j, B_j, C_j$ directly. Change the circuit, change the basis polynomials, and these elements no longer make cryptographic sense.

More fundamentally: computing these elements requires knowing $\alpha, \beta, \gamma, \delta$ in the clear. After the ceremony, these secrets are destroyed. They cannot be recovered to compute new circuit-specific values.

This is Groth16's central tradeoff. The circuit-specific encoding enables the minimal proof size. It also mandates a new ceremony for every circuit.


## Protocol Specification

With setup complete, we specify the prover and verifier algorithms.

### Common Reference String

The **Proving Key** $\text{pk}$ contains:

- Encrypted powers: $\{g_1^{\tau^i}\}$, $\{g_2^{\tau^i}\}$
- Blinding elements: $g_1^{\alpha}$, $g_1^{\beta}$, $g_2^{\beta}$, $g_1^{\delta}$, $g_2^{\delta}$
- Basis polynomial commitments: $\{g_1^{A_j(\tau)}\}$, $\{g_1^{B_j(\tau)}\}$, $\{g_2^{B_j(\tau)}\}$
- Consistency check elements for private inputs:

  $$\left\lbrace g_1^{\frac{\beta \cdot A_j(\tau) + \alpha \cdot B_j(\tau) + C_j(\tau)}{\delta}} \right\rbrace_{j \in \text{private}}$$

- Quotient polynomial support: $\{g_1^{\tau^i \cdot Z_H(\tau) / \delta}\}$

The **Verification Key** $\text{vk}$ contains:

- Pairing elements: $g_1^{\alpha}$, $g_2^{\beta}$, $g_2^{\gamma}$, $g_2^{\delta}$
- Public input consistency elements:

  $$\left\lbrace g_1^{\frac{\beta \cdot A_j(\tau) + \alpha \cdot B_j(\tau) + C_j(\tau)}{\gamma}} \right\rbrace_{j \in \text{public}}$$

### Prover Algorithm

Given witness $Z = (1, \text{io}, W)$ where $\text{io}$ are public inputs and $W$ is the private witness:

1. **Compute witness polynomials**: Form $A(X), B(X), C(X)$ from the witness.

2. **Compute quotient**: Calculate $H(X) = \frac{A(X) \cdot B(X) - C(X)}{Z_H(X)}$.

3. **Generate randomness**: Sample fresh $r, s \leftarrow \mathbb{F}$.

4. **Construct proof elements**:

$$\pi_A = g_1^{\alpha + A(\tau) + r\delta}$$

$$\pi_B = g_2^{\beta + B(\tau) + s\delta}$$

$$\pi_C = g_1^{\frac{\sum_{j \in \text{priv}} z_j (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau))}{\delta} + \frac{H(\tau) \cdot Z_H(\tau)}{\delta} + s(\alpha + A(\tau) + r\delta) + r(\beta + B(\tau) + s\delta) - rs\delta}$$

The prover outputs $\pi = (\pi_A, \pi_B, \pi_C) \in \mathbb{G}_1 \times \mathbb{G}_2 \times \mathbb{G}_1$.

### Proof Size

On the BN254 curve:

- $\pi_A \in \mathbb{G}_1$: 32 bytes (compressed)
- $\pi_B \in \mathbb{G}_2$: 64 bytes (compressed)
- $\pi_C \in \mathbb{G}_1$: 32 bytes (compressed)

**Total: 128 bytes.**

This is the smallest proof size achieved by any pairing-based SNARK. The paper proves a lower bound: any SNARK in this model requires at least two group elements. Groth16's three elements are close to optimal.

### Verifier Algorithm

Given public inputs $\text{io} = (z_0, z_1, \ldots, z_\ell)$ where $z_0 = 1$:

1. **Compute public input combination**:
   $$\text{vk}_x = \sum_{j=0}^{\ell} z_j \cdot (\text{vk}_{IC})_j$$
   where $(\text{vk}_{IC})_j = g_1^{\frac{\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)}{\gamma}}$

2. **Check pairing equation**:
   $$e(\pi_A, \pi_B) \stackrel{?}{=} e(g_1^{\alpha}, g_2^{\beta}) \cdot e(\text{vk}_x, g_2^{\gamma}) \cdot e(\pi_C, g_2^{\delta})$$

The verifier accepts if the equation holds, rejects otherwise.

### Verification Cost

The verification requires:

- One multi-scalar multiplication in $\mathbb{G}_1$ (size proportional to public input count)
- Four pairing computations (or three pairings after rearrangement)

Pairings are expensive: roughly 2-3ms each on modern hardware. But the cost is independent of circuit size. A circuit with a million constraints verifies as fast as one with a hundred.

## Why the Verification Equation Works

The pairing equation encodes the QAP identity in a way that cancels blinding terms while checking the core constraint.

### Expanding the Left-Hand Side

$$e(\pi_A, \pi_B) = e(g_1^{\alpha + A(\tau) + r\delta}, g_2^{\beta + B(\tau) + s\delta})$$

Using bilinearity, the exponent in $\mathbb{G}_T$ is:

$$(\alpha + A(\tau) + r\delta)(\beta + B(\tau) + s\delta)$$

Expanding:

$$= \alpha\beta + \alpha B(\tau) + \alpha s\delta + \beta A(\tau) + A(\tau)B(\tau) + A(\tau)s\delta + r\beta\delta + r B(\tau)\delta + rs\delta^2$$

This contains the desired term $A(\tau)B(\tau)$ mixed with cross-terms involving the secrets.

### Expanding the Right-Hand Side

**Term 1**: $e(g_1^{\alpha}, g_2^{\beta})$ contributes exponent $\alpha\beta$.

**Term 2**: $e(\text{vk}_x, g_2^{\gamma})$ contributes:

$$\sum_{j \in \text{public}} z_j \cdot (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau))$$

after the $\gamma$ cancels.

**Term 3**: $e(\pi_C, g_2^{\delta})$ contributes the private witness consistency check plus:

$$H(\tau) \cdot Z_H(\tau) + s\alpha\delta + sA(\tau)\delta + r\beta\delta + rB(\tau)\delta + rs\delta^2$$

after the $\delta$ cancels from the private terms.

### The Cancellation

Combining public and private terms:

$$\sum_{\text{all } j} z_j \cdot (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)) = \beta A(\tau) + \alpha B(\tau) + C(\tau)$$

The RHS exponent becomes:

$$\alpha\beta + \beta A(\tau) + \alpha B(\tau) + C(\tau) + H(\tau)Z_H(\tau) + \alpha s\delta + A(\tau)s\delta + \beta r\delta + B(\tau)r\delta + rs\delta^2$$

Setting LHS = RHS and canceling matching terms (where the following cancel out):

- $\alpha\beta$ cancels
- $\alpha B(\tau)$ cancels
- $\beta A(\tau)$ cancels
- All $r, s$ terms cancel

What remains:

$$A(\tau)B(\tau) = C(\tau) + H(\tau)Z_H(\tau)$$

This is exactly the QAP identity. The elaborate construction of $\pi_C$ exists precisely to provide terms that cancel the blinding while preserving the core check.

## Security and the Generic Group Model

Groth16's security proof relies on the **Generic Bilinear Group Model**: an idealization where the adversary can only perform group operations without exploiting the specific structure of the underlying curve.

### The Model

In this model, group elements are represented by opaque handles. The adversary can:

- Add/subtract group elements
- Check equality
- Compute pairings

The adversary cannot:

- Look inside a group element to see its discrete log
- Exploit number-theoretic structure of the curve

### What the Model Implies

Under this model, Groth16 is **knowledge-sound**: any adversary that produces a valid proof must "know" a valid witness. More precisely, there exists an extractor that, given the adversary's state, can produce a witness.

The model also implies the proof is **zero-knowledge**: the proof reveals nothing about the witness beyond what follows from the public statement.

### The Assumption's Strength

The generic group model is non-standard. Real elliptic curves have algebraic structure; real adversaries might exploit it. No attacks are known against Groth16 on standard curves, but the security proof doesn't rule out structure-dependent attacks.

This is the price of efficiency. Schemes provable under weaker assumptions (discrete log, CDH) typically have larger proofs. Groth16 achieves optimal size by assuming more.

### Concrete Assumptions

At a technical level, security reduces to the following assumptions:

- **q-Strong Diffie-Hellman (q-SDH)**: Given $\{g^{\tau^i}\}_{i=0}^{q}$, it's hard to produce $(c, g^{1/(\tau + c)})$ for any $c$.
- **Knowledge of Exponent**: If an adversary outputs $(g^a, g^{ab})$, they must "know" $a$.

These are strong but well-studied assumptions on pairing groups.

### Proof Malleability

Groth16 proofs are **malleable**: given a valid proof $(\pi_A, \pi_B, \pi_C)$, the tuple $(-\pi_A, -\pi_B, \pi_C)$ is also valid for the same statement. This follows from the verification equation; negating both $\pi_A$ and $\pi_B$ preserves the pairing product since $e(-\pi_A, -\pi_B) = e(\pi_A, \pi_B)$.

**Malleability is not forgery.** This distinction is important. Malleability allows an attacker to change the *appearance* of a valid proof (flipping signs), but not the *content*. They cannot change the public inputs or the witness. It is like taking a valid check and folding it in half: it is still a valid check for the same amount, but the physical object has changed. This matters for transaction IDs (which often hash the proof), but not for the validity of the statement itself.

This matters for applications that use proofs as unique identifiers or assume proof uniqueness (e.g., preventing double-spending by rejecting duplicate proofs). Mitigations include hashing the proof into the transaction identifier, or requiring proof elements to lie in a specific half of the group.

## Trusted Setup: Practical Considerations

The circuit-specific setup is Groth16's most significant operational constraint.

### What "Toxic Waste" Means

The secrets $\tau, \alpha, \beta, \gamma, \delta$ must be destroyed after the ceremony. If any participant retains them:

- Knowing $\tau$ breaks binding: allows computing arbitrary polynomial evaluations
- Knowing $\alpha, \beta, \delta$ allows forging proofs for false statements

The secrets are called "toxic waste" because their existence post-ceremony compromises all proofs using that SRS.

### Multi-Party Ceremonies

Production deployments (Zcash, Tornado Cash) run MPC ceremonies with many participants:

1. Participant $i$ receives current parameters
2. Generates random $t_i$, updates parameters by raising to power $t_i$
3. Publishes updated parameters
4. Proves they performed the update correctly (via a proof of knowledge)
5. Deletes $t_i$

The final secrets are products of all participants' contributions. Security holds if any participant was honest.

The ceremonies themselves became rituals of paranoid care. In the original Zcash "Powers of Tau" ceremony (2017-2018), participants generated randomness from radioactive decay, atmospheric noise, and the movements of lava lamps. One contributor drove through the Canadian wilderness to avoid network surveillance while computing their contribution on an air-gapped laptop. Another broadcast their parameters from a remote location and then physically destroyed the hard drive on video. The ceremonies were not theater (or not *only* theater). The security guarantee depends on at least one participant successfully destroying their secret. Every act of destruction was an attempt to make the toxic waste irrecoverable by any means: forensic, computational, or coercive.

### Phase 2 Complexity

Phase 1 (Powers of Tau) is performed once per maximum circuit size and reused indefinitely.

Phase 2 requires:

- Computing circuit-specific elements for every wire
- MPC ceremony among willing participants
- Verification that each contribution was correct

**The DNA Mixer.** Think of Phase 2 as mixing the circuit's DNA into the randomness. Every wire in the circuit needs its own specific $\tau$-powered handle so the prover can "grab" it during proof generation. If the circuit has 10,000 wires, the setup must produce 10,000 specific handles: one for each wire's contribution to the $A$, $B$, and $C$ polynomials. This is why the setup grows linearly with circuit size; you are baking the circuit's structure into the cryptographic parameters.

For a circuit with $n$ wires, Phase 2 generates $O(n)$ group elements. Large circuits require large ceremonies.

### When Circuit-Specific Setup Is Acceptable

Groth16 makes sense when:

1. **The circuit is fixed**: Same computation proved repeatedly (e.g., confidential transactions)
2. **Proof size dominates costs**: On-chain verification where bytes are expensive
3. **Verification speed is critical**: Applications requiring <10ms verification
4. **Trust model is manageable**: Established communities can coordinate ceremonies

It makes less sense when:

1. **Circuits change frequently**: Development, iteration, bug fixes
2. **Many different circuits needed**: General-purpose computation
3. **No trusted community exists**: Public good infrastructure without coordination

## Comparison with Universal SNARKs

Since 2016, the field has developed universal SNARKs: systems with a single trusted setup reusable across circuits.

### PLONK (Chapter 13)

- **Setup**: Universal, updatable
- **Proof size**: ~400-500 bytes (with KZG)
- **Verification**: ~10ms (several pairings)
- **Prover**: Comparable to Groth16

PLONK trades 3-4x larger proofs for the ability to prove any circuit without new ceremonies.

### Marlin/Sonic

These are universal SNARKs that emerged around the same time as PLONK. **Sonic** (2019) pioneered the "universal and updateable" trusted setup: a single ceremony works for any circuit up to a size bound, and users can add their own randomness to strengthen trust. **Marlin** (2020) keeps R1CS arithmetization (like Groth16) but achieves universality through algebraic holographic proofs. Both have similar proof sizes to PLONK (~500 bytes) but different verification costs and prover trade-offs. In practice, PLONK's flexibility and ecosystem support led to wider adoption.

### STARKs (Chapter 15)

- **Setup**: Transparent (no trusted setup)
- **Proof size**: ~100 KB
- **Verification**: ~10-50ms (hash-based)
- **Prover**: Faster than pairing-based systems

STARKs eliminate trust assumptions entirely but with much larger proofs.

### The Trade-Off Summary

| System | Setup | Proof Size | Verification | Security Model |
|--------|-------|------------|--------------|----------------|
| Groth16 | Circuit-specific | 128 bytes | 3 pairings | Generic Group |
| PLONK+KZG | Universal | ~500 bytes | ~10 pairings | q-SDH |
| PLONK+IPA | Transparent | ~10 KB | O(n) | DLog |
| STARKs | Transparent | ~100 KB | O(log²n) | Hash collision |

Groth16 remains optimal when proof size is the binding constraint and circuit stability justifies the setup cost.

## Implementation Considerations

### Curve Selection

Groth16 requires pairing-friendly curves. Common choices:

**BN254 (alt_bn128)**:

- 254-bit prime field
- Fast pairing computation
- Ethereum precompiles at addresses 0x06, 0x07, 0x08
- ~100 bits of security (debated; some analyses suggest less)

**BLS12-381**:

- 381-bit prime field
- Higher security (~120 bits)
- Slower pairings
- Used by Zcash Sapling, Ethereum 2.0 BLS signatures

### Prover Complexity

The prover performs:

- $O(n)$ scalar multiplications to form witness polynomials from basis polynomials
- $O(n \log n)$ operations for polynomial multiplication and division (computing $H(X)$)
- Multi-scalar multiplications (MSM) to compute proof elements

The MSM dominates for large circuits. Significant engineering effort goes into MSM optimization: Pippenger's algorithm, parallelization, GPU acceleration.

### On-Chain Verification

Ethereum's precompiled contracts enable efficient Groth16 verification:

- `ecAdd` (0x06): Elliptic curve addition in $\mathbb{G}_1$
- `ecMul` (0x07): Scalar multiplication in $\mathbb{G}_1$
- `ecPairing` (0x08): Multi-pairing check

A typical Groth16 verifier contract:

1. Computes $\text{vk}_x$ via ecMul and ecAdd for each public input
2. Calls ecPairing with four pairs: $(-\pi_A, \pi_B), (vk_\alpha, vk_\beta), (vk_x, vk_\gamma), (\pi_C, vk_\delta)$
3. Returns true if the pairing product equals 1

Gas cost: ~200,000-300,000 gas depending on public input count.

## Historical Significance

Groth16 was published in 2016, building on a decade of SNARK research.

**Predecessors**:

- Pinocchio (2013): First practical SNARK, 8 group elements, 11 pairings
- GGPR13: Quadratic span programs, similar approach
- BCTV14: Linear PCPs, precursor to Groth16's analysis

**Groth16's Innovations**:

1. Reduced proof to 3 elements (from 8)
2. Reduced verification to 3 pairings (from 11)
3. Proved near-optimality via lower bounds
4. Refined Linear PCP analysis

**Impact**:

- Deployed in Zcash (Sapling upgrade, 2018)
- Standard for blockchain applications requiring minimal proof size
- Baseline against which new systems are compared

The paper's title, "On the Size of Pairing-based Non-interactive Arguments," reflects its focus on the theoretical question: how small can proofs be?



## Worked Example: Complete Trace

Let's trace through a minimal example: proving knowledge of $x$ such that $x^2 = 9$.

### Setup

**Circuit**: One multiplication gate: $x \times x = 9$

**Witness structure**: $Z = (1, 9, x)$ where $z_0 = 1$ (constant), $z_1 = 9$ (public output), $z_2 = x$ (private input)

**R1CS** (single constraint):

- $A = (0, 0, 1)$, selects $x$
- $B = (0, 0, 1)$, selects $x$
- $C = (0, 1, 0)$, selects output

**Evaluation point**: $\omega_1 = 1$

**Basis polynomials** (constants, since only one constraint):

- $A_0(X) = 0$, $A_1(X) = 0$, $A_2(X) = 1$
- $B_0(X) = 0$, $B_1(X) = 0$, $B_2(X) = 1$
- $C_0(X) = 0$, $C_1(X) = 1$, $C_2(X) = 0$

**Vanishing polynomial**: $Z_H(X) = X - 1$

### Prover Computation (with $x = 3$)

**Witness**: $Z = (1, 9, 3)$

**Witness polynomials**:

- $A(X) = z_2 \cdot A_2(X) = 3 \cdot 1 = 3$
- $B(X) = z_2 \cdot B_2(X) = 3 \cdot 1 = 3$
- $C(X) = z_1 \cdot C_1(X) = 9 \cdot 1 = 9$

**QAP check**: $A(X) \cdot B(X) - C(X) = 9 - 9 = 0$

The polynomial is identically zero, so $H(X) = 0$.

**Proof elements** (with random $r, s$):

- $\pi_A = g_1^{\alpha + 3 + r\delta}$
- $\pi_B = g_2^{\beta + 3 + s\delta}$
- $\pi_C = g_1^{\frac{3(\beta + \alpha)}{\delta} + s(\alpha + 3 + r\delta) + r(\beta + 3 + s\delta) - rs\delta}$

### Verification

**Public input**: $z_1 = 9$

**Compute $\text{vk}_x$**: The verification key contains public input consistency elements $(\text{vk}_{IC})_j = g_1^{(\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau))/\gamma}$ for each public index $j$. In our circuit, $j = 0$ (constant) and $j = 1$ (public output). Since $A_0 = A_1 = B_0 = B_1 = C_0 = 0$ and $C_1 = 1$:

$$\text{vk}_x = (\text{vk}_{IC})_0 + z_1 \cdot (\text{vk}_{IC})_1 = g_1^{0/\gamma} + 9 \cdot g_1^{1/\gamma} = g_1^{9/\gamma}$$

**Pairing check**: The verifier computes four pairings and confirms their product equals 1 in $\mathbb{G}_T$.

If $x \neq \pm 3$, the QAP would not hold, $H(X)$ would not exist as a polynomial, and the pairing check would fail.



## Key Takeaways

### Architecture

1. **Optimal proof size.** Three group elements: 128 bytes on BN254. This is the theoretical minimum for pairing-based SNARKs; Groth proved no system in this model can do better.

2. **QAP transformation.** R1CS constraints become a polynomial divisibility condition: $A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$. Satisfiability at $m$ evaluation points becomes divisibility by the vanishing polynomial.

3. **Pairing verification.** One pairing equation checks the entire polynomial identity homomorphically. Verification is $O(1)$: constant time regardless of circuit size.

4. **Linear PCP foundation.** The prover's messages are linear combinations of SRS elements. This linearity constraint is what enables the 3-element proof: the prover can only compute what the setup allows.

### Setup and Trust

5. **Circuit-specific setup.** Phase 1 (powers of tau) is universal; Phase 2 embeds the circuit's basis polynomials into the SRS. Changing a single gate invalidates the entire Phase 2.

6. **Trust model.** 1-of-N honesty: if any participant in the ceremony destroys their toxic waste, the setup is secure. Multi-party computation makes this practical; Zcash's ceremony had hundreds of participants.

### Security Properties

7. **Blinding for zero-knowledge.** Random scalars $r, s$ and setup secrets $\alpha, \beta, \delta$ blind the proof elements. The blinding is algebraically woven into the protocol, not layered on top.

8. **Generic group model.** Security assumes adversaries cannot exploit the group's structure beyond the allowed operations. This is a stronger assumption than standard models, but enables maximum efficiency.

### Context and Deployment

9. **Ecosystem role.** The standard choice when proof size dominates cost: on-chain verification (gas costs scale with proof size), bandwidth-constrained settings, and applications requiring constant-size proofs.

10. **Historical milestone.** Published 2016, deployed in Zcash Sapling 2018. Established the benchmark against which all subsequent SNARKs are measured. Still the smallest proof size achievable without changing the cryptographic model.



\newpage

# Chapter 13: PLONK: Universal SNARKs and the Permutation Argument

By 2018, Zcash had proven SNARKs worked, but at a terrible logistical cost.

Every time they wanted to upgrade the protocol, they had to run a new Trusted Setup Ceremony. This meant renting secure facilities, coordinating participants across continents, and asking each one to generate randomness, contribute to a multi-party computation, then physically destroy their hardware. The "Powers of Tau" ceremony for the Sapling upgrade involved 87 participants over 10 months. One participant literally put his laptop in a blender. The process worked, but it didn't scale. The cryptographic world needed a setup you could perform once and use forever.

Ariel Gabizon, Zachary Williamson, and Oana Ciobotaru found the path. Their insight was *permutations*: instead of encoding circuit structure directly into the setup, separate two concerns: what each gate computes (local) and how gates connect (global). The wiring could be encoded as a permutation, checked with a polynomial argument that worked identically for any circuit.

The result was PLONK (2019): **P**ermutations over **L**agrange-bases for **O**ecumenical **N**oninteractive arguments of **K**nowledge. "Oecumenical" signals universality: one ceremony suffices for all circuits up to a maximum size. The setup is also **updatable**: new participants can strengthen its security at any time, without coordination with previous contributors.

PLONK's modularity extends to the commitment scheme. The core is a **Polynomial IOP**: an interactive protocol where the prover sends polynomials and the verifier queries evaluations. Compile it with KZG for constant-size proofs with trusted setup. Compile with FRI for larger proofs without trust assumptions. The IOP is unchanged; only the cryptographic layer differs.

The cost of universality is larger proofs (~400-500 bytes versus 128) and more verification work (~10 pairings versus 3). For most applications, this is an acceptable trade. The ecosystem has voted: PLONK and its descendants dominate production deployments.

## Architecture: Gates and Copy Constraints

PLONK's arithmetization differs fundamentally from R1CS. Where R1CS flattens the entire computation into a single witness vector with implicit wiring, PLONK separates two concerns:

**Gate constraints**: Each gate satisfies a polynomial equation relating its input and output wires.

**Copy constraints**: Wires at different positions carry equal values when the circuit's topology demands it.

This separation has profound consequences. Gate logic becomes uniform: one equation for all gates. Wiring becomes explicit: a permutation argument proves all copy constraints simultaneously. The result is a cleaner architecture that generalizes naturally to custom gates and lookup arguments.

### The Gate Equation

Every gate in PLONK has three wires: left input $a_i$, right input $b_i$, output $c_i$. The gate's behavior is specified by **selectors**: public field elements fixed at circuit compilation.

The universal gate equation:

$$Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot ab + Q_C = 0$$

Different selector values program different operations:

**Addition** $(a + b = c)$: Set $Q_L = 1$, $Q_R = 1$, $Q_O = -1$, others zero.

- Check: $1 \cdot a + 1 \cdot b + (-1) \cdot c + 0 + 0 = a + b - c = 0$

**Multiplication** $(ab = c)$: Set $Q_M = 1$, $Q_O = -1$, others zero.

- Check: $0 + 0 + (-1) \cdot c + 1 \cdot ab + 0 = ab - c = 0$

**Constant assignment** $(a = k)$: Set $Q_L = 1$, $Q_C = -k$, others zero.

- Check: $1 \cdot a + 0 + 0 + 0 + (-k) = a - k = 0$

The equation's generality is its power. One algebraic form handles arbitrary gate types. Modern variants extend to more wires (5+ instead of 3) and higher-degree terms ($a^5$ for Poseidon S-boxes).

### From Discrete Checks to Polynomial Identity

The circuit has $n$ gates. We want to verify all $n$ gate equations simultaneously.

Define a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$ where $\omega$ is a primitive $n$-th root of unity. The $i$-th gate corresponds to domain point $\omega^i$.

**Selector polynomials**: For each selector (e.g., $Q_L$), interpolate its values across gates to obtain polynomial $Q_L(X)$ satisfying $Q_L(\omega^i) = Q_{L,i}$.

**Witness polynomials**: Interpolate wire values. Polynomial $a(X)$ satisfies $a(\omega^i) = a_i$ (the left input at gate $i$).

**Witness structure differs from R1CS.** In R1CS (Chapter 7), the witness is a single flattened vector $Z = (1, \text{public inputs}, \text{private inputs}, \text{intermediate values})$. Each wire has exactly one index in $Z$. When two constraints reference the same wire, they use the same index; wiring is implicit in the indexing scheme.

PLONK structures the witness differently: three separate vectors $(a, b, c)$, each of length $n$ (the number of gates). Entry $a_i$ is gate $i$'s left input; $b_i$ is its right input; $c_i$ is its output. When the same value appears in multiple positions (say, a variable feeding two different gates) it occupies multiple slots in these vectors. This has a crucial consequence: PLONK needs explicit "copy constraints" to enforce that slots holding the same logical wire actually contain the same value. We'll see how this works shortly.

**Concrete example: the same circuit in both formats.** Consider $y = (x + z) \cdot z$ with $x = 3$, $z = 2$, so $y = 10$.

*R1CS representation* (2 constraints, 5 wires):

Witness vector: $Z = (1, x, z, v_1, y) = (1, 3, 2, 5, 10)$ where $v_1 = x + z$.

$$A = \begin{pmatrix} 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 0 \end{pmatrix}, \quad B = \begin{pmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \end{pmatrix}, \quad C = \begin{pmatrix} 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \end{pmatrix}$$

(Columns correspond to $x, z, v_1, y$; we omit the constant column for brevity.)

Row 1: 

$(1 \cdot x + 1 \cdot z) \times (1) = v_1$ checks $x + z = v_1$.

Row 2:

$(1 \cdot z) \times (1 \cdot v_1) = y$ checks $z \cdot v_1 = y$.

The matrices encode *which wires participate in which constraints*. Wire $z$ (column 2) appears in both rows; the matrix structure encodes this sharing.

*PLONK representation* (2 gates):

| Gate | $a$ | $b$ | $c$ | $Q_L$ | $Q_R$ | $Q_O$ | $Q_M$ | $Q_C$ |
|------|-----|-----|-----|-------|-------|-------|-------|-------|
| 1    | 3   | 2   | 5   | 1     | 1     | -1    | 0     | 0     |
| 2    | 5   | 2   | 10  | 0     | 0     | -1    | 1     | 0     |

Witness vectors: $a = (3, 5)$, $b = (2, 2)$, $c = (5, 10)$.

Gate 1:

$1 \cdot 3 + 1 \cdot 2 + (-1) \cdot 5 + 0 + 0 = 0$ $\checkmark$ (addition)

Gate 2:

$0 + 0 + (-1) \cdot 10 + 1 \cdot 5 \cdot 2 + 0 = 0$ $\checkmark$ (multiplication)

Notice: $z = 2$ appears twice ($b_1$ and $b_2$), and $v_1 = 5$ appears twice ($c_1$ and $a_2$). The gate equations don't enforce $b_1 = b_2$ or $c_1 = a_2$; a cheating prover could use different values. Copy constraints will enforce these equalities.

**The structural difference**: R1CS has matrices that *select* from a shared witness vector (same wire, same column, automatic equality). PLONK has vectors where each gate slot is independent (same value, different slots, explicit copy constraints needed).

**Contrast with QAP (Chapter 12)**: QAP interpolates *column-wise*: for each wire $j$, create polynomials encoding how that wire participates across all constraints. The witness appears as coefficients weighting basis polynomials. PLONK interpolates *row-wise*: wire values are directly the polynomial evaluations, and selectors are separate polynomials encoding gate types. This is why QAP bakes circuit structure into the SRS (changing the circuit changes the basis polynomials), while PLONK's SRS is universal (selectors are just committed data, independent of the setup).

The gate equation becomes a polynomial identity:

$$Q_L(X) \cdot a(X) + Q_R(X) \cdot b(X) + Q_O(X) \cdot c(X) + Q_M(X) \cdot a(X) \cdot b(X) + Q_C(X) = 0$$

for all $X \in H$.

If this holds on $H$, the vanishing polynomial $Z_H(X) = X^n - 1$ divides the left side. There exists quotient $t(X)$ with:

$$Q_L(X)a(X) + Q_R(X)b(X) + Q_O(X)c(X) + Q_M(X)a(X)b(X) + Q_C(X) = Z_H(X) \cdot t(X)$$

The prover demonstrates this divisibility: a single polynomial identity encoding all gate constraints.

## The Copy Constraint Problem

Gate equations ensure internal consistency: the output of each gate equals the specified function of its inputs. They say nothing about how gates connect.

Consider a circuit computing $y = (x + z) \cdot z$:

- Gate 1: Addition, output $c_1 = a_1 + b_1$
- Gate 2: Multiplication, output $c_2 = a_2 \cdot b_2$

The wiring requires $c_1 = a_2$ (Gate 1's output feeds Gate 2's left input) and $b_1 = b_2$ (variable $z$ feeds both gates).

Because PLONK's witness consists of three separate vectors $(a, b, c)$, nothing in the gate equation relates $c_1$ to $a_2$; they're independent entries. A cheating prover could satisfy all gate equations with disconnected, inconsistent values. The circuit would "verify" despite computing garbage.

**Copy constraints** are the explicit assertions: wire $i$ equals wire $j$. The challenge is proving all copy constraints efficiently (potentially thousands of equality assertions) without enumerating them individually.

**A note on terminology**: The name "copy constraint" is slightly misleading. We aren't copying data from one location to another. We are enforcing *equality*: two wire slots that happen to hold the same logical variable must contain identical values. Think of it as a wormhole connecting two distant parts of the circuit instantaneously. The value at $c_1$ doesn't "flow" to $a_2$; rather, they are the same point in the circuit's logical topology, temporarily given different addresses for bookkeeping. The permutation argument detects whether these "same points" actually hold the same value.

## The Permutation Argument

PLONK's central innovation is reducing all copy constraints to a single polynomial identity via a **permutation argument**, building on techniques from Bayer and Groth (Eurocrypt 2012).

### From Gates to Cycles: The Conceptual Shift

Before diving into the mechanism, understand the key mental shift. So far, we've thought of circuits as *gates*: local computational units that take inputs and produce outputs. Copy constraints seem like *connections between gates*: wire $c_1$ connects to wire $a_2$.

The permutation argument reframes this. Instead of "connections," think of *equivalence classes*. All wires that should hold the same value belong to the same class. Within each class, the wires form a *cycle* under a permutation: $c_1 \to a_2 \to c_1$ (a 2-cycle), or longer chains like $a_1 \to b_3 \to c_5 \to a_1$ (a 3-cycle). Wires with no copy constraints form trivial 1-cycles (fixed points).

The grand product argument then asks: if we traverse each cycle, do all the values match? If wire $c_1$ maps to wire $a_2$ and they share the same value, their contributions to the product cancel. If every cycle closes properly (all values match within the equivalence class), the entire product equals 1.

This shift from "gates and wires" to "values and cycles" is why the permutation argument works. We're not checking connections one by one; we're verifying that the entire wiring topology is consistent in one algebraic stroke.

### Representing Wiring as a Permutation

Give each wire slot a unique identity (think of it as an "index" or "address"):

- Gate $i$'s left wire: $\text{id}(a_i) = \omega^i$
- Gate $i$'s right wire: $\text{id}(b_i) = k_1 \omega^i$
- Gate $i$'s output wire: $\text{id}(c_i) = k_2 \omega^i$

where $k_1, k_2$ are distinct constants separating the three wire "columns." The identity function $\text{id}$ maps wire slots to field elements; it's just a naming scheme.

The circuit's wiring defines a permutation $\sigma$ on wire identities. If wire $c_1$ connects to wire $a_2$, then $\sigma$ maps $c_1$'s identity to $a_2$'s identity (and vice versa; connected wires form cycles under $\sigma$). Unconnected wires map to themselves.

**Example**: For our circuit $y = (x + z) \cdot z$ with 2 gates, label the 6 wire slots as $a_1, b_1, c_1, a_2, b_2, c_2$. The copy constraints are $c_1 = a_2$ (output of gate 1 feeds gate 2) and $b_1 = b_2$ (variable $z$ used twice). The permutation $\sigma$ encodes this: $\sigma(c_1) = a_2$, $\sigma(a_2) = c_1$ (a 2-cycle), and $\sigma(b_1) = b_2$, $\sigma(b_2) = b_1$ (another 2-cycle). Wires $a_1$ and $c_2$ aren't copied anywhere, so $\sigma(a_1) = a_1$ and $\sigma(c_2) = c_2$ (fixed points).

**The key insight**: All copy constraints hold if and only if every wire's value equals the value at its connected position. Here $\sigma(w)$ denotes the *position* that wire $w$ is connected to (not a transformed value):

$$\text{value at position } w = \text{value at position } \sigma(w) \quad \forall w$$

### The Grand Product Check

How do we verify this equality-under-permutation efficiently?

Consider two multisets: the wire values $\{v_1, v_2, \ldots, v_{3n}\}$ and the same values permuted according to $\sigma$. If copy constraints hold, these multisets are identical; they contain the same elements, just in different order.

Testing multiset equality via products fails: $\{1, 6\}$ and $\{2, 3\}$ have equal products but differ. A randomized check succeeds with overwhelming probability.

Given random challenge $\gamma$:

$$\prod_{i=1}^{3n} (v_i + \gamma) = \prod_{i=1}^{3n} (v_{\sigma(i)} + \gamma)$$

By Schwartz-Zippel, equality at random $\gamma$ implies the multisets match.

### Binding Values to Locations

The multiset check has a flaw. A cheating prover could satisfy copy constraints on some wires by *violating* them on others, as long as they swap equal amounts. The overall multiset remains unchanged even though specific equalities fail.

**Example**: Circuit requires $c_1 = a_2$. Honest values: $c_1 = 5$, $a_2 = 5$. Cheating prover sets $c_1 = 5$, $a_2 = 99$, but compensates by swapping some other wire that should be $99$ to $5$. The multiset of all values is preserved.

**The ID Badge Analogy.** Imagine a room full of people (values) wearing ID badges (locations). You want to check that everyone is present after they swap seats according to a seating chart (the permutation). If you only check names, people could swap identities. But if each person's badge is permanently fused to their chair number, any swap becomes detectable. The value "5" at position $c_1$ wears a badge reading "5 at $c_1$"; after permutation, it should match "5 at $a_2$." If the values differ, the badges don't match, and the product check fails.

The fix: bind each value to its **location** using a second challenge $\beta$:

$$\text{randomized value} = v_i + \beta \cdot \text{id}_i + \gamma$$

where $\text{id}_i$ is the wire's identity (its domain point).

The grand product check becomes:

$$\prod_{w \in \text{wires}} \left( \text{value}(w) + \beta \cdot \text{id}(w) + \gamma \right) = \prod_{w \in \text{wires}} \left( \text{value}(w) + \beta \cdot \sigma(\text{id}(w)) + \gamma \right)$$

**Why this works (mini-example)**: Suppose we have just two wires that should be equal: wire $A$ at position 1 with value $v$, and wire $B$ at position 2 with value $v$. The permutation swaps their positions: $\sigma(1) = 2$, $\sigma(2) = 1$. Left side: $(v + \beta \cdot 1 + \gamma)(v + \beta \cdot 2 + \gamma)$. Right side: $(v + \beta \cdot 2 + \gamma)(v + \beta \cdot 1 + \gamma)$. Same factors, just reordered; products match. But if wire $B$ had value $v' \neq v$, the right side would be $(v + \beta \cdot 2 + \gamma)(v' + \beta \cdot 1 + \gamma)$; different factors, products don't match. The $\beta$ term "tags" each value with its location, so swapping positions only works if the values actually match.

The left side combines each wire's value with its own identity. The right side combines each wire's value with its *permuted* identity.

If $c_1 = a_2$ (copy constraint holds), the term for $c_1$ on the right equals the term for $a_2$ on the left; they cancel in the product. If $c_1 \neq a_2$, no cancellation occurs; the products differ.

### The Accumulator Polynomial

Computing a product over $3n$ terms naively requires $O(n)$ work per verification query, which is not succinct. PLONK encodes the product as a polynomial.

Define the **accumulator polynomial** $Z(X)$ recursively:

**Initialization**: $Z(\omega) = 1$

**Recursion**: For domain points $\omega^i$:

$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{(a_i + \beta \omega^i + \gamma)(b_i + \beta k_1\omega^i + \gamma)(c_i + \beta k_2\omega^i + \gamma)}{(a_i + \beta S_{\sigma_1}(\omega^i) + \gamma)(b_i + \beta S_{\sigma_2}(\omega^i) + \gamma)(c_i + \beta S_{\sigma_3}(\omega^i) + \gamma)}$$

where $S_{\sigma_1}, S_{\sigma_2}, S_{\sigma_3}$ are **permutation polynomials** encoding $\sigma$ for the three wire columns.

The accumulator starts at 1 and multiplies through all gates. Each step contributes: numerator terms for "original" identities, denominator terms for "permuted" identities. If copy constraints hold, terms cancel across the cycle, and the accumulator returns to 1 at the end.

**The permutation constraints**:

1. **Initialization**: $Z(\omega) = 1$

   Enforced by: $(Z(X) - 1) \cdot L_1(X) = 0$ where $L_1(X)$ is the first Lagrange basis polynomial.

2. **Recursion**: The step-by-step product relation holds across the domain.

   Enforced by a polynomial identity involving $Z(X)$ and $Z(X\omega)$ (the "shifted" evaluation).

Both constraints, like the gate constraint, reduce to divisibility by $Z_H(X)$.


## Worked Example: The Permutation Argument in Action

The abstraction clarifies; the concrete convinces. Let's trace through the permutation argument on a minimal circuit: proving $z = (x + y) \cdot y$ for inputs $x = 2$, $y = 3$.

### The Circuit

**Gate 1** (addition): $c_1 = a_1 + b_1$
**Gate 2** (multiplication): $c_2 = a_2 \cdot b_2$

**Witness assignment** (for $x=2$, $y=3$, $z=15$):

- Gate 1: $a_1 = 2$, $b_1 = 3$, $c_1 = 5$
- Gate 2: $a_2 = 5$, $b_2 = 3$, $c_2 = 15$

**Copy constraints**:

- $c_1 = a_2$ (the intermediate value 5 feeds from Gate 1's output to Gate 2's left input)
- $b_1 = b_2$ (the input $y=3$ is used in both gates)

### Wire Identities

With domain $H = \{1, \omega\}$ (two gates) and constants $k_1, k_2$:

| Wire | Identity | Value |
|------|----------|-------|
| $a_1$ | $1$ | $2$ |
| $b_1$ | $k_1$ | $3$ |
| $c_1$ | $k_2$ | $5$ |
| $a_2$ | $\omega$ | $5$ |
| $b_2$ | $k_1\omega$ | $3$ |
| $c_2$ | $k_2\omega$ | $15$ |

### The Permutation $\sigma$

The wiring groups wire identities into cycles:

**Cycle 1** (the $y$ input): $b_1 \leftrightarrow b_2$
$$\sigma(k_1) = k_1\omega, \quad \sigma(k_1\omega) = k_1$$

**Cycle 2** (the intermediate value): $c_1 \leftrightarrow a_2$
$$\sigma(k_2) = \omega, \quad \sigma(\omega) = k_2$$

**Fixed points** (unconnected wires):
$$\sigma(1) = 1, \quad \sigma(k_2\omega) = k_2\omega$$

### Permutation Polynomials

The polynomials $S_{\sigma_1}(X)$, $S_{\sigma_2}(X)$, $S_{\sigma_3}(X)$ encode $\sigma$ for each wire column.

**$S_{\sigma_1}(X)$** (the $a$ wires):

- $S_{\sigma_1}(1) = \sigma(1) = 1$ (wire $a_1$ is a fixed point)
- $S_{\sigma_1}(\omega) = \sigma(\omega) = k_2$ (wire $a_2$ connects to $c_1$)

**$S_{\sigma_2}(X)$** (the $b$ wires):

- $S_{\sigma_2}(1) = \sigma(k_1) = k_1\omega$ (wire $b_1$ connects to $b_2$)
- $S_{\sigma_2}(\omega) = \sigma(k_1\omega) = k_1$ (wire $b_2$ connects to $b_1$)

**$S_{\sigma_3}(X)$** (the $c$ wires):

- $S_{\sigma_3}(1) = \sigma(k_2) = \omega$ (wire $c_1$ connects to $a_2$)
- $S_{\sigma_3}(\omega) = \sigma(k_2\omega) = k_2\omega$ (wire $c_2$ is a fixed point)

These evaluations uniquely determine the permutation polynomials (degree at most 1 over a domain of size 2).

### The Accumulator Trace

Let random challenges be $\beta$ and $\gamma$. The accumulator $Z(X)$ computes a running product.

**Initialization**: $Z(1) = 1$

**Step at $X = 1$** (processing Gate 1):

$$Z(\omega) = Z(1) \cdot \frac{(a_1 + \beta \cdot 1 + \gamma)(b_1 + \beta \cdot k_1 + \gamma)(c_1 + \beta \cdot k_2 + \gamma)}{(a_1 + \beta \cdot S_{\sigma_1}(1) + \gamma)(b_1 + \beta \cdot S_{\sigma_2}(1) + \gamma)(c_1 + \beta \cdot S_{\sigma_3}(1) + \gamma)}$$

Substituting values:

**Numerator** = $(2 + \beta + \gamma)(3 + \beta k_1 + \gamma)(5 + \beta k_2 + \gamma)$

**Denominator** = $(2 + \beta \cdot 1 + \gamma)(3 + \beta \cdot k_1\omega + \gamma)(5 + \beta \cdot \omega + \gamma)$

The $a_1$ term $(2 + \beta + \gamma)$ appears in both numerator and denominator; it cancels (wire $a_1$ is a fixed point).

The $b_1$ numerator term is $(3 + \beta k_1 + \gamma)$; the denominator has $(3 + \beta k_1\omega + \gamma)$.

The $c_1$ numerator term is $(5 + \beta k_2 + \gamma)$; the denominator has $(5 + \beta\omega + \gamma)$.

**Step at $X = \omega$** (processing Gate 2):

$$Z(\omega^2) = Z(\omega) \cdot \frac{(a_2 + \beta\omega + \gamma)(b_2 + \beta k_1\omega + \gamma)(c_2 + \beta k_2\omega + \gamma)}{(a_2 + \beta \cdot S_{\sigma_1}(\omega) + \gamma)(b_2 + \beta \cdot S_{\sigma_2}(\omega) + \gamma)(c_2 + \beta \cdot S_{\sigma_3}(\omega) + \gamma)}$$

Substituting:

**Numerator** = $(5 + \beta\omega + \gamma)(3 + \beta k_1\omega + \gamma)(15 + \beta k_2\omega + \gamma)$

**Denominator** = $(5 + \beta k_2 + \gamma)(3 + \beta k_1 + \gamma)(15 + \beta k_2\omega + \gamma)$

### The Cancellation

Now examine the full product $Z(\omega^2) = Z(1) \cdot [\text{fraction}_1] \cdot [\text{fraction}_2]$.

The copy constraint $c_1 = a_2 = 5$ means:

- Numerator of fraction 1 contains $(5 + \beta k_2 + \gamma)$
- Denominator of fraction 2 contains $(5 + \beta k_2 + \gamma)$

These cancel.

The copy constraint $b_1 = b_2 = 3$ means:

- Numerator of fraction 1 contains $(3 + \beta k_1 + \gamma)$
- Denominator of fraction 2 contains $(3 + \beta k_1 + \gamma)$

These cancel.

And conversely:

- Denominator of fraction 1 contains $(5 + \beta\omega + \gamma)$
- Numerator of fraction 2 contains $(5 + \beta\omega + \gamma)$

These cancel.

- Denominator of fraction 1 contains $(3 + \beta k_1\omega + \gamma)$
- Numerator of fraction 2 contains $(3 + \beta k_1\omega + \gamma)$

These cancel.

**Every term in the numerator has a matching term in the denominator across the full cycle.** The product collapses to $Z(\omega^2) = 1$.

Since $\omega^2 = 1$ for $n = 2$, we have $Z(1) = 1$ as required. The accumulator returns to its starting value, confirming all copy constraints hold.

### What If a Constraint Were Violated?

Suppose the prover cheats: sets $a_2 = 7$ instead of $5$ (breaking $c_1 = a_2$).

The term $(5 + \beta k_2 + \gamma)$ from $c_1$ no longer matches $(7 + \beta k_2 + \gamma)$ from the fraudulent $a_2$. No cancellation occurs. The accumulator ends at a value $\neq 1$, and the constraint $(Z(X) - 1) \cdot L_n(X) = 0$ fails.

The random challenges $\beta, \gamma$ ensure this failure is detectable with overwhelming probability.

## The Full Protocol

We now specify the complete PLONK protocol with KZG commitments.

### Preprocessed Data (Circuit-Specific)

Fixed at circuit compilation:

- Selector polynomial commitments: $[Q_L]_1, [Q_R]_1, [Q_O]_1, [Q_M]_1, [Q_C]_1$
- Permutation polynomial commitments: $[S_{\sigma_1}]_1, [S_{\sigma_2}]_1, [S_{\sigma_3}]_1$

### Common Reference String (Universal)

The SRS, shared across all circuits up to size $n$:

- $\{[1]_1, [\tau]_1, [\tau^2]_1, \ldots, [\tau^{n+5}]_1\}$
- $[\tau]_2$

The prover needs the full $\mathbb{G}_1$ sequence. The verifier needs only $[\tau]_2$, an asymmetry that enables efficient verification.

### Round 1: Commit to Witness

The prover:

1. Computes witness polynomials $a(X), b(X), c(X)$ by interpolating wire values
2. **Blinds** each polynomial for zero-knowledge: $a(X) \leftarrow a(X) + (b_1 X + b_2) Z_H(X)$, where $b_1, b_2$ are random field elements
3. Commits: sends $[a]_1, [b]_1, [c]_1$

**Why blinding works**: The term $(b_1 X + b_2) Z_H(X)$ is zero on $H$ (since $Z_H(\omega^i) = 0$ for all $\omega^i \in H$), so adding it doesn't change the polynomial's values at gate positions; correctness is preserved. But outside $H$, this random term "scrambles" the polynomial, hiding information about the original witness values. The verifier will later query the polynomial at a random point $\zeta \notin H$; without blinding, these evaluations could leak witness information.

### Round 2: Commit to Accumulator

The prover:

1. Derives challenges $\beta, \gamma$ via Fiat-Shamir (hash of transcript including Round 1 commitments)
2. Computes accumulator polynomial $Z(X)$ from the recursive definition
3. Blinds with higher-degree term (three random scalars, since $Z$ is checked at two points: $z$ and $z\omega$)
4. Commits: sends $[Z]_1$

### Round 3: Compute Quotient

The prover:

1. Derives challenge $\alpha$ via Fiat-Shamir
2. Forms the combined constraint polynomial using $\alpha$ for random linear combination:

$$P(X) = \text{(gate constraint)} + \alpha \cdot \text{(permutation recursion)} + \alpha^2 \cdot \text{(permutation initialization)}$$

   The **permutation recursion** is the constraint that forces the accumulator to update correctly at each step: the polynomial form of "$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{\text{numerator}}{\text{denominator}}$" from the grand product. The **permutation initialization** is the boundary condition: the accumulator must start at 1, encoded as $(Z(X) - 1) \cdot L_1(X)$ where $L_1$ is the Lagrange polynomial that equals 1 at $\omega$ and 0 elsewhere.

3. Computes quotient: $t(X) = P(X) / Z_H(X)$
4. Splits $t(X)$ into lower-degree pieces for commitment (since $\deg(t) > n$)
5. Commits to quotient pieces

### Round 4: Evaluate and Open

The prover:

1. Derives evaluation point $\zeta$ via Fiat-Shamir
2. Evaluates all relevant polynomials at $\zeta$:

   - Witness: $a(\zeta), b(\zeta), c(\zeta)$
   - Accumulator: $Z(\zeta)$, and crucially $Z(\zeta\omega)$ (the shifted evaluation)
   - Permutation: $S_{\sigma_1}(\zeta), S_{\sigma_2}(\zeta)$
3. Sends evaluations to verifier
4. Computes batched opening proofs (linearization optimization)

### Round 5: Batched Opening Proofs

The prover:

1. Derives batching challenge $v$ via Fiat-Shamir
2. Constructs opening proof for all evaluations at $\zeta$ (batched)
3. Constructs opening proof for evaluation at $\zeta\omega$ (the shifted point)
4. Sends two KZG proofs

### Verification

The verifier performs the following steps:

**1. Reconstruct Challenges**

From the transcript (all prover commitments), derive:

- $\beta, \gamma$ from Round 1 commitments (for permutation argument)
- $\alpha$ from Round 2 commitments (for constraint aggregation)
- $\zeta$ from Round 3 commitments (evaluation point)
- $v$ from Round 4 evaluations (batching challenge)

All challenges are deterministic functions of the transcript via Fiat-Shamir.

**2. Compute the Linearization Polynomial Commitment**

The verifier computes a commitment $[r]_1$ to the "linearization polynomial": a carefully constructed combination that, when evaluated at $\zeta$, should equal zero if all constraints hold.

The linearization includes:

- **Gate constraint**: $[Q_L]_1 \cdot a(\zeta) + [Q_R]_1 \cdot b(\zeta) + [Q_O]_1 \cdot c(\zeta) + [Q_M]_1 \cdot a(\zeta)b(\zeta) + [Q_C]_1$
- **Permutation recursion** (scaled by $\alpha$): Terms involving $[Z]_1$, the permutation polynomials, and the evaluated witness values
- **Permutation initialization** (scaled by $\alpha^2$): $(Z(\zeta) - 1) \cdot L_1(\zeta)$

The key insight: most terms are linear combinations of known evaluations and committed polynomials. The verifier can compute $[r]_1$ using only the commitments received from the prover and the evaluation values.

**3. Compute the Expected Evaluation**

The verifier computes what $r(\zeta)$ *should* equal if the prover is honest. This involves:

- The quotient polynomial contribution: $t(\zeta) \cdot Z_H(\zeta)$
- Witness polynomial contributions at $\zeta$

**4. Batched Opening Verification**

The verifier checks two batched KZG opening proofs:

**Opening at $\zeta$**: All polynomials evaluated at $\zeta$ are batched using challenge $v$:
$$[F]_1 = [r]_1 + v[a]_1 + v^2[b]_1 + v^3[c]_1 + v^4[S_{\sigma_1}]_1 + v^5[S_{\sigma_2}]_1$$

The verifier checks that $[F]_1$ opens to the batched evaluation:
$$F(\zeta) = r(\zeta) + v \cdot a(\zeta) + v^2 \cdot b(\zeta) + \ldots$$

**Opening at $\zeta\omega$**: The accumulator's shifted evaluation:
$$e([Z]_1 - [Z(\zeta\omega)]_1, [\tau]_2) \stackrel{?}{=} e([W_{\zeta\omega}]_1, [\tau - \zeta\omega]_2)$$

where $[W_{\zeta\omega}]_1$ is the KZG opening proof for evaluation at $\zeta\omega$.

**5. Pairing Check**

The final verification reduces to two pairing equations (often combined into one via random linear combination):

$$e([W_\zeta]_1 + u \cdot [W_{\zeta\omega}]_1, [\tau]_2) = e(\zeta \cdot [W_\zeta]_1 + u\zeta\omega \cdot [W_{\zeta\omega}]_1 + [F]_1 - [E]_1, [1]_2)$$

where $u$ is a random challenge for batching the two opening proofs, and $[E]_1$ is the commitment to the expected evaluations.

**Verification Cost**

| Operation | Count |
|-----------|-------|
| Scalar multiplications in $\mathbb{G}_1$ | ~15-20 |
| Field multiplications | ~30-50 |
| Pairing computations | 2 |

Total verification time: ~5-10ms on commodity hardware, independent of circuit size.

## Proof Size Analysis

With KZG over BN254:

| Element | Size | Count | Total |
|---------|------|-------|-------|
| $\mathbb{G}_1$ commitments | 32 bytes | ~10 | 320 bytes |
| $\mathbb{G}_1$ opening proofs | 32 bytes | 2 | 64 bytes |
| Field element evaluations | 32 bytes | ~7 | 224 bytes |

**Total: ~600 bytes** (varies with optimizations)

This is 4-5× larger than Groth16's 128 bytes. The cost buys universality: one setup ceremony, any circuit.

## Why Roots of Unity?

PLONK's use of roots of unity (multiplicative subgroup of order $2^k$) is not arbitrary.

**FFT efficiency**: Polynomial operations (interpolation, multiplication, division) run in $O(n \log n)$ via FFT. Without roots of unity, these operations cost $O(n^2)$.

**Simple vanishing polynomial**: $Z_H(X) = X^n - 1$. Compact representation, efficient evaluation.

**Shift structure**: The accumulator's recursive relation compares $Z(X)$ and $Z(X\omega)$. Multiplication by $\omega$ shifts through the domain cyclically. This algebraic structure is essential for encoding the step-by-step product check.

Groth16 uses an arithmetic progression $\{1, 2, \ldots, m\}$ because its prover doesn't interpolate; it computes linear combinations of precomputed basis polynomials. The FFT advantage doesn't apply.

## Comparison: PLONK vs. Groth16

The systems embody different engineering philosophies.

### Witness Treatment

**Groth16**: Witness values are *coefficients*. The setup computes basis polynomials $A_j(X), B_j(X), C_j(X)$ for each wire. The prover forms $A(X) = \sum_j z_j A_j(X)$ as a linear combination.

**PLONK**: Witness values are *evaluations*. The prover interpolates to find polynomials passing through $(ω^i, a_i)$ for each gate.

This distinction explains why Groth16's setup is circuit-specific (it precomputes basis polynomials for the specific circuit) while PLONK's is universal (the prover does interpolation at proving time using generic powers of $\tau$).

### Wiring Mechanism

**Groth16**: Copy constraints are implicit. The R1CS matrices reference the same witness index for connected wires. No separate mechanism needed.

**PLONK**: Copy constraints are explicit via the permutation argument. This separation enables the universal setup: wiring information lives in circuit-specific preprocessed polynomials, not in the SRS.

### Constraint Expressiveness

**Groth16/R1CS**: Each constraint has form $(a \cdot w)(b \cdot w) = c \cdot w$, a single multiplication with linear combinations. High fan-in additions compress into one constraint.

**PLONK**: The gate equation handles one multiplication or addition per gate. But custom gates and lookup arguments extend expressiveness far beyond R1CS for complex operations.

### Trade-off Summary

| Aspect | Groth16 | PLONK |
|--------|---------|-------|
| Setup | Circuit-specific | Universal |
| Proof size | 128 bytes | ~500 bytes |
| Verification | 3 pairings | ~10 pairings |
| Prover work | MSM-dominated | FFT + MSM |
| Extensibility | Fixed | Custom gates, lookups |


## Custom Gates and Extensions

PLONK's gate equation generalizes naturally.

### More Wires

Modern systems (Halo2, UltraPLONK) use 5+ wires per gate:

$$\sum_{i=1}^{5} Q_i \cdot w_i + Q_{M_{12}} w_1 w_2 + Q_{M_{34}} w_3 w_4 + \cdots = 0$$

More wires mean fewer gates for complex operations.

### Higher-Degree Terms

The Poseidon hash uses $x^5$ in its S-box. A custom gate term $Q_{\text{pow5}} \cdot a^5$ computes this in one gate rather than five multiplications.

### Non-Native Arithmetic

A major driver for custom gates is *non-native arithmetic*: computing over a field different from the proof system's native field. PLONK (with BN254) operates over a ~254-bit prime field. But many applications require arithmetic over other fields: Bitcoin uses secp256k1's scalar field, Ethereum signatures use different curve parameters, and recursive proof verification requires operating over the "inner" proof's field.

Without custom gates, non-native field multiplication requires decomposing elements into limbs, performing schoolbook multiplication with carries, and range-checking intermediate results. A single non-native multiplication can cost 50+ native gates. Custom gates can batch these operations, reducing the cost by 5-10×. This is why efficient ECDSA verification (for Ethereum account abstraction or Bitcoin bridge verification) demands sophisticated custom gate design.

### Boolean Constraints

Enforcing $x \in \{0, 1\}$ requires $x(x-1) = 0$, equivalently $x^2 - x = 0$. With selector $Q_{\text{bool}}$:

$$Q_{\text{bool}} \cdot (a^2 - a) = 0$$

One gate, one constraint.

### Lookup Arguments

The most powerful extension. Rather than computing a function in gates, prove that (input, output) pairs appear in a precomputed table.

**Example**: Range check. Proving $x \in [0, 2^{16})$ via bit decomposition costs 16 gates. A lookup into a table of $\{0, 1, \ldots, 2^{16}-1\}$ costs ~3 constraints.

Chapter 14 develops lookup arguments in detail.


## UltraPLONK

"UltraPLONK" denotes PLONK variants combining custom gates and lookup arguments. These systems achieve dramatic efficiency gains for real-world circuits.

**Composite gates**: A single gate encoding multiple operations (e.g., $a + b = c$ AND $d \cdot e = f$ simultaneously).

**Lookup integration**: The permutation argument extends to prove set membership in lookup tables.

**Optimized hashing**: Poseidon-specific gates reduce hash computation by 10-20× compared to vanilla PLONK.

The architecture remains: polynomial IOP compiled with KZG (or alternatives). The IOP grows more sophisticated, but the verification structure persists.

**Aztec's evolution**: Aztec Labs, co-founded by Zac Williamson (one of PLONK's creators), developed UltraPLONK in their Barretenberg library. Their system has since evolved to **Honk**, which replaces the univariate polynomial IOP with sum-check over multilinear polynomials (similar to Spartan's approach). Honk retains PLONKish arithmetization but gains the memory efficiency of sum-check. For on-chain verification, Aztec compresses Honk proofs into UltraPLONK proofs; UltraPLONK's simpler verifier (fewer selector polynomials, no multilinear machinery) reduces gas costs. Their **Goblin PLONK** technique further optimizes recursive proof composition by deferring expensive elliptic curve operations rather than computing them at each recursion layer.


## Security Considerations

### Trusted Setup

PLONK's universality doesn't eliminate trust; it redistributes it.

The SRS still encodes secret $\tau$. If known, proofs can be forged. The advantage is logistical: one ceremony covers all circuits. Updates strengthen security without coordination.

Production deployments (Aztec, zkSync, Scroll) run multi-party ceremonies with hundreds of participants. The 1-of-N trust model, where security holds if any participant is honest, provides strong guarantees.

### Random Oracle Model

Fiat-Shamir security assumes hash functions behave as random oracles. Real hash functions are deterministic algorithms with structure.

No practical attacks are known. The gap between model and reality is a persistent concern across all Fiat-Shamir-compiled protocols.

### Soundness Assumptions

With KZG:

- **q-SDH**: Given powers of $\tau$, cannot produce $(c, g^{1/(\tau+c)})$
- **Discrete log**: Cannot compute $\tau$ from $g^\tau$

Without KZG (FRI compilation):

- **Collision resistance**: Hash function security

The assumption stack is well-studied. Pairing-based systems carry more algebraic structure (and assumption weight) than hash-based alternatives.


## Worked Example: Three-Gate Circuit

Consider proving knowledge of $x$ such that $(x + 1) \cdot x = 6$.

**Circuit**:

- Gate 1: Constant assignment, $b_1 = 1$
- Gate 2: Addition, $c_2 = a_2 + b_2$
- Gate 3: Multiplication, $c_3 = a_3 \cdot b_3$, constrained to equal 6

**Witness** (with $x = 2$):

- Gate 1: $a_1 = 0$, $b_1 = 1$, $c_1 = 0$ (unused output)
- Gate 2: $a_2 = 2$, $b_2 = 1$, $c_2 = 3$
- Gate 3: $a_3 = 3$, $b_3 = 2$, $c_3 = 6$

**Copy constraints**:

- $b_1 = b_2$ (constant 1 reused)
- $a_2 = b_3$ (input $x$ reused)
- $c_2 = a_3$ (addition output feeds multiplication)

**Permutation**:
Wires $b_1$ and $b_2$ form a cycle. Wires $a_2$ and $b_3$ form a cycle. Wires $c_2$ and $a_3$ form a cycle. Remaining wires are fixed points.

**Selector polynomials**: Interpolate selector values over domain $H = \{1, \omega, \omega^2\}$.

**Witness polynomials**: Interpolate $(a_1, a_2, a_3)$, $(b_1, b_2, b_3)$, $(c_1, c_2, c_3)$.

**Accumulator**: Starts at 1. After processing all gates, if copy constraints hold, returns to 1.

**Verification**: Evaluate combined constraint polynomial at random $\zeta$. If constraints satisfied, the evaluation is zero. Verify via KZG opening proofs.



## Key Takeaways

1. **Universal setup**: One ceremony, all circuits up to a size bound. Updateable security model.

2. **Separation of concerns**: Gate constraints (local correctness) separate from copy constraints (global wiring). Each has its own polynomial mechanism.

3. **The permutation argument**: Reduces all copy constraints to one polynomial identity via randomized grand product check.

4. **Witness as evaluations**: PLONK interpolates witness values. Groth16 uses them as coefficients. This architectural choice enables universality.

5. **Roots of unity**: FFT efficiency for polynomial operations. Shift structure for accumulator recursion. Not cosmetic but essential.

6. **Custom gates**: The framework generalizes. More wires, higher degrees, specialized operations. UltraPLONK extends vanilla PLONK dramatically.

7. **Lookup arguments**: Prove table membership instead of computation. Game-changing for non-arithmetic operations.

8. **Proof size trade-off**: ~500 bytes vs. Groth16's 128. Universality has a cost.

9. **Verification structure**: Two batched KZG proofs. Constant work regardless of circuit size.

10. **Ecosystem dominance**: PLONK derivatives power most production ZK systems. The universal setup won the deployment battle.



\newpage

# Chapter 14: Lookup Arguments

In 2019, ZK engineers hit a wall.

They wanted to verify standard computer programs, things like SHA-256 or ECDSA signatures, but the circuits were exploding in size. The culprit was the *bitwise operation*. In a silicon CPU, checking `a XOR b` takes one cycle. In R1CS arithmetic, it took roughly 30 constraints to decompose the numbers into bits, check the bits, and reassemble them. Trying to verify a 64-bit CPU instruction set was like trying to simulate a Ferrari using only gears made of wood.

Ariel Gabizon and Zachary Williamson realized they didn't need to simulate the gears. They just needed to check the answer key. This realization, that you can replace *computation* with *table lookups*, broke the 64-bit wall. It allowed circuits to stop "thinking" about XORs and start "remembering" them.

The insight built on earlier work (Bootle et al.'s 2018 "Arya" paper had explored lookup-style arguments), but Plookup made it practical by repurposing PLONK's permutation machinery. The 65,536 valid 16-bit integers become a table. The $2^{16}$ XOR triples become a table. Membership in these tables costs three constraints, regardless of what the table encodes. The architecture shifted, and complexity moved from constraint logic to precomputed data.

The field accelerated. Haböck's **LogUp** (2022) replaced grand products with sums of logarithmic derivatives, eliminating sorting overhead and enabling cleaner multi-table arguments. Setty, Thaler, and Wahby's **Lasso** (2023) achieved prover costs scaling with lookups performed rather than table size, enabling tables of size $2^{128}$, large enough to hold the evaluation table of any 64-bit instruction. The "lookup singularity" emerged: a vision of circuits that do nothing but look things up in precomputed tables.

Today, every major zkVM relies on lookups. Cairo, RISC-Zero, SP1, and Jolt prove instruction execution not by encoding CPU semantics in constraints, but by verifying that each instruction's behavior matches its entry in a precomputed table. The paradigm shift is complete: **from logic to data**.

---

## The Lookup Problem

Chapter 13 introduced the **grand product argument** for copy constraints in PLONK. The idea: to prove that wire values at positions related by permutation $\sigma$ are equal, compute $\prod_i \frac{a_i + \beta \cdot i + \gamma}{a_i + \beta \cdot \sigma(i) + \gamma}$. If the permutation constraint is satisfied (values at linked positions match), this product telescopes to 1. Lookup arguments generalize this technique from equality to containment, proving not that two multisets are the same, but that one is contained in another.

The formal problem:

Given a multiset $f = \{f_1, \ldots, f_n\}$ of witness values (the "lookups") and a public multiset $t = \{t_1, \ldots, t_d\}$ (the "table"), prove $f \subseteq t$.

**Why "lookup"?** Imagine you're proving a circuit that computes XOR. The table $t$ contains all valid XOR triples: $(0,0,0), (0,1,1), (1,0,1), (1,1,0)$. Your circuit claims $a \oplus b = c$ for some witness values. Rather than encoding XOR algebraically, you "look up" the triple $(a,b,c)$ in the table. If it's there, the XOR is correct. The multiset $f$ collects all the triples your circuit needs to verify; the subset claim $f \subseteq t$ says every lookup found a valid entry.

**The Dictionary Analogy.** Imagine you want to prove you spelled "Cryptography" correctly. The *arithmetic approach* would be to write down the rules of English grammar and phonetics, then derive the spelling from first principles. Slow, complex, error-prone. The *lookup approach* would be to open the Oxford English Dictionary to page 412, point to the word "Cryptography," and say "there." The lookup argument is simply proving that your tuple (the word you claim) exists in the set (all valid English words). You don't need to understand *why* it's valid; you just need to show it's in the book.

A naive approach might compare products: if $\prod (f_i + \gamma) = \prod (t_j + \gamma)$, the multisets are equal. But subset is weaker than equality, since $f$ may use only some table entries, possibly with repetition.

Different lookup protocols solve this problem in different ways. We'll detail **Plookup**'s approach first because it builds directly on PLONK's permutation machinery from Chapter 13. Later sections cover alternatives: LogUp uses logarithmic derivatives (sums instead of products), Lasso exploits table decomposition for sublinear prover costs.

**Plookup's insight**: Transform the subset claim into a permutation claim. The construction involves three objects:

- **$f$**: the lookup values (what you're looking up, your witness data)
- **$t$**: the table (all valid values, public and precomputed)
- **$s$**: the sorted merge of $f$ and $t$ (auxiliary, constructed by prover)

The key is that $s$ encodes *how* $f$ fits into $t$. If every $f_i$ is in $t$, then $s$ is just $t$ with duplicates inserted at the right places.

### Plookup's Sorted Vector $s$

Define $s = \text{sort}(f \cup t)$, the concatenation of lookup values and table values, sorted.

If $f \subseteq t$, then every element of $f$ appears somewhere in $t$. In the sorted vector $s$, elements from $f$ "slot in" next to their matching elements from $t$.

**Key observation**: For every adjacent pair $(s_i, s_{i+1})$ in $s$, either:

1. $s_i = s_{i+1}$ (a repeated value, meaning some $f_j$ was inserted next to its matching $t_k$), or
2. $(s_i, s_{i+1})$ is also an adjacent pair in the sorted table $t$

If some $f_j \notin t$, then $s$ contains a transition that doesn't exist in $t$, and the check fails.

**Example**:

- Lookups: $f = \{2, 5\}$
- Table: $t = \{0, 1, 2, 3, 4, 5, 6, 7\}$
- Sorted: $s = \{0, 1, 2, 2, 3, 4, 5, 5, 6, 7\}$

Adjacent pairs in $s$: $(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$

The pairs $(2,2)$ and $(5,5)$ are repeats; these correspond to the lookups. All other pairs appear as adjacent pairs in $t$. The subset claim holds.

If instead $f = \{2, 9\}$:

- Sorted: $s = \{0, 1, 2, 2, 3, 4, 5, 6, 7, 9\}$
- The pair $(7, 9)$ is not an adjacent pair in $t$
- The subset claim fails

### Plookup's Grand Product Check

The adjacent-pair property translates to a polynomial identity via a grand product. The construction is clever, so let's build it step by step.

**The core idea**: Encode each adjacent pair $(s_i, s_{i+1})$ as a single field element $\gamma(1+\beta) + s_i + \beta s_{i+1}$. The term $\beta$ acts as a "separator": different pairs map to different field elements (with high probability over random $\beta$). If we multiply all these pair-encodings together, we get a fingerprint of the multiset of adjacent pairs.

**$G(\beta, \gamma)$**, the fingerprint of $s$'s adjacent pairs:

$$G(\beta, \gamma) = \prod_{i=1}^{n+d-1} (\gamma(1 + \beta) + s_i + \beta s_{i+1})$$

This is just the product of all adjacent-pair encodings in the sorted vector $s$.

**$F(\beta, \gamma)$**, the fingerprint we *expect* if $f \subseteq t$:

$$F(\beta, \gamma) = (1 + \beta)^n \cdot \prod_{i=1}^{n} (\gamma + f_i) \cdot \prod_{i=1}^{d-1} (\gamma(1 + \beta) + t_i + \beta t_{i+1})$$

Where does this come from? Think about what $s$ looks like when $f \subseteq t$. The sorted merge contains the table $t$ as a "backbone," with lookup values from $f$ inserted as duplicates next to their matches. So the adjacent pairs in $s$ fall into two categories:

1. **Pairs from $t$**: The $d-1$ consecutive pairs $(t_i, t_{i+1})$ from the original table. These appear in $s$ regardless of what $f$ contains; they're the skeleton that $f$ gets merged into.

2. **Repeated pairs from inserting $f$**: When a lookup value $f_j$ slots into $s$ next to its matching table entry, we get a repeated pair $(f_j, f_j)$. The encoding of $(v, v)$ is $\gamma(1+\beta) + v + \beta v = (\gamma + v)(1+\beta)$. So each valid lookup contributes $(\gamma + f_j)$ and $(1+\beta)$ to the product.

$F$ is the fingerprint of *exactly these pairs*, the table backbone plus $n$ valid duplicate insertions. If $G$ (the actual fingerprint of $s$) equals $F$, then $s$ has the right structure: no "bad" transitions like $(7, 9)$ that would appear if some $f_j \notin t$.

**Tiny example**: Let's use a 3-element table to see the algebra concretely.

- Table: $t = \{0, 1, 2\}$ (so $d = 3$)
- Lookups: $f = \{1\}$ (so $n = 1$)
- Sorted merge: $s = \{0, 1, 1, 2\}$

**Computing $G$** (fingerprint of $s$'s adjacent pairs):

The pairs in $s$ are: $(0,1), (1,1), (1,2)$. Encode each:

$$G = (\gamma(1+\beta) + 0 + \beta \cdot 1) \cdot (\gamma(1+\beta) + 1 + \beta \cdot 1) \cdot (\gamma(1+\beta) + 1 + \beta \cdot 2)$$
$$= (\gamma(1+\beta) + \beta) \cdot (\gamma(1+\beta) + 1 + \beta) \cdot (\gamma(1+\beta) + 1 + 2\beta)$$

**Computing $F$** (expected fingerprint):

- Table pairs $(t_i, t_{i+1})$: $(0,1)$ and $(1,2)$
- Lookup duplicate: $f_1 = 1$ contributes $(\gamma + 1)(1+\beta)$

$$F = (1+\beta)^1 \cdot (\gamma + 1) \cdot (\gamma(1+\beta) + 0 + \beta \cdot 1) \cdot (\gamma(1+\beta) + 1 + \beta \cdot 2)$$
$$= (1+\beta)(\gamma + 1) \cdot (\gamma(1+\beta) + \beta) \cdot (\gamma(1+\beta) + 1 + 2\beta)$$

**Why $F = G$?** Notice that the pair $(1,1)$ in $G$ encodes as $\gamma(1+\beta) + 1 + \beta = (\gamma + 1)(1 + \beta)$. This factors! So $G$'s middle term equals $F$'s $(1+\beta)(\gamma+1)$ term. The other two terms match directly. The products are identical.

**Claim (Plookup)**: $F \equiv G$ if and only if $f \subseteq t$ and $s$ is correctly formed.

The logic: if every $f_j$ is in $t$, then $s$ is just $t$ with duplicates inserted, and the multiset of adjacent pairs in $s$ equals exactly what $F$ encodes. If some $f_j \notin t$, it creates a "bad" pair in $s$ that doesn't appear in $F$, and the products differ.

## The Plookup Protocol

The grand product machinery above is **Plookup**, the 2020 protocol by Gabizon and Williamson that launched the lookup paradigm. It's not the only way to build lookup arguments. LogUp replaces grand products with logarithmic derivatives (sums instead of products), eliminating the need for the sorted vector $s$ and enabling cleaner multi-table arguments. Lasso restructures the problem entirely, achieving prover costs that scale with lookups performed rather than table size. We focus on Plookup because it builds directly on PLONK's permutation machinery from Chapter 13, making the connection between copy constraints and lookup arguments explicit.

We now formalize Plookup as integrated with PLONK.

### Setup

**Public table**: Polynomial $t(X)$ encoding table values, preprocessed into selector commitments.

**Witness values**: The prover has values $\{f_1, \ldots, f_n\}$ to look up.

### Prover Computation

1. **Construct $s$**: Sort $f \cup t$ to obtain the $(f,t)$-sorted vector.

2. **Split $s$ into $h_1, h_2$**: The sorted vector $s$ has length $n + d$ (lookups plus table), but PLONK's domain has size $n$. We can't fit $s$ into a single polynomial over this domain. So split $s$ into two halves: $h_1$ encodes the first half, $h_2$ the second. The constraint system will check adjacent pairs *within* each half and *across* the boundary where they meet.

3. **Commit**: Send $[h_1]_1, [h_2]_1$ to the verifier.

4. **Receive challenges**: After Fiat-Shamir, obtain $\beta, \gamma$.

5. **Build accumulator**: Construct $Z(X)$ satisfying:
   - $Z(\omega) = 1$
   - Recursive relation linking $Z(X\omega)$ to $Z(X)$ via the $F/G$ terms

6. **Commit**: Send $[Z]_1$.

### Constraints

The following polynomial identities are added to the PLONK quotient polynomial:

**Accumulator initialization**:
$$(Z(X) - 1) \cdot L_1(X) = 0$$

**Accumulator recursion**:
$$Z(X\omega) \cdot \prod_{j \in \{1,2\}} (\gamma(1+\beta) + h_j(X) + \beta h_j(X\omega))$$
$$= Z(X) \cdot (1+\beta)^m \cdot (\gamma + f(X)) \cdot (\gamma(1+\beta) + t(X) + \beta t(X\omega))$$

where $m$ depends on how many lookups occur per gate (typically 1 or 2).

**Accumulator finalization**: The accumulator returns to 1 at the end of the domain (enforced implicitly by the product structure).

**Permutation check**: $h_1$ and $h_2$ contain exactly the elements of $f \cup t$, verified via a standard PLONK permutation argument.

**Sorting check**: Adjacent elements of $s$ satisfy $s_{i+1} \geq s_i$, typically enforced via a small range check on differences.

**Wait, why isn't sorting enough?** If $s$ is sorted, doesn't that prove $f \subseteq t$? Not quite. We also need to prove that $s$ contains *exactly* the elements of $f$ and $t$, no more, no less. This is the role of the permutation argument.

The complete logic is:

1. $s$ is a permutation of $(f \cup t)$. (So no new numbers appeared out of thin air.)
2. $s$ is sorted. (So duplicates are adjacent.)
3. Every adjacent pair in $s$ is valid (either a repeat, or a step that exists in the table).

If all three hold, then every element in $f$ must have found a matching buddy in $t$. A cheating prover cannot slip in a value that's not in the table, because it would create an invalid adjacent pair that neither repeats nor exists as a table step.

### Verification

The verifier checks the batched PLONK constraints. No table-size-dependent work: verification cost is independent of $d$.


## Worked Example: Plookup 3-Bit Range Check

Let's trace through a complete Plookup proof.

**Statement**: Prover knows $f_1 = 2$ and $f_2 = 5$, both in $[0, 7]$.

**Table**: $t = \{0, 1, 2, 3, 4, 5, 6, 7\}$, size $d = 8$.

**Lookups**: $f = \{2, 5\}$, size $n = 2$.

### Step 1: Construct $s$

$$s = \text{sort}(\{2, 5\} \cup \{0, 1, 2, 3, 4, 5, 6, 7\}) = \{0, 1, 2, 2, 3, 4, 5, 5, 6, 7\}$$

Length: $n + d = 10$.

### Step 2: Adjacent Pairs

Pairs in $s$:
$(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$

Nine pairs total.

Pairs in sorted $t$:
$(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,7)$

Seven pairs.

The pairs $(2,2)$ and $(5,5)$ are repeats from inserting $f$ values. All others match $t$.

### Step 3: Grand Product Identity

Using challenges $\beta, \gamma$:

**$F(\beta, \gamma)$**, the expected fingerprint:

$$F = (1+\beta)^2 \cdot (\gamma + 2)(\gamma + 5) \cdot \prod_{i=0}^{6} (\gamma(1+\beta) + t_i + \beta t_{i+1})$$

The three parts: $(1+\beta)^2$ for two lookups, $(\gamma + 2)(\gamma + 5)$ for the lookup values, and the seven table pairs $(0,1), (1,2), \ldots, (6,7)$.

**$G(\beta, \gamma)$**, the actual fingerprint of $s$'s nine adjacent pairs:

$$G = \prod_{i=0}^{8} (\gamma(1+\beta) + s_i + \beta s_{i+1})$$

Writing out the pairs from $s = \{0,1,2,2,3,4,5,5,6,7\}$:

$$(0,1), (1,2), (2,2), (2,3), (3,4), (4,5), (5,5), (5,6), (6,7)$$

The key observation: the repeated pairs $(2,2)$ and $(5,5)$ factor specially.

- $(2,2)$ encodes as $\gamma(1+\beta) + 2 + 2\beta = \gamma(1+\beta) + 2(1+\beta) = (\gamma + 2)(1+\beta)$
- $(5,5)$ encodes as $(\gamma + 5)(1+\beta)$

So $G$ contains the factors $(\gamma + 2)(1+\beta) \cdot (\gamma + 5)(1+\beta) = (1+\beta)^2 (\gamma+2)(\gamma+5)$.

The remaining seven pairs in $G$, namely $(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,7)$, are exactly the table pairs in $F$.

Therefore $F = G$. The lookup succeeds.

### Step 4: Accumulator Trace

The accumulator $Z(X)$ starts at 1 and processes one fraction per domain point.

At each step:
$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{\text{$F$ terms at position $i$}}{\text{$G$ terms at position $i$}}$$

If $f \subseteq t$, the numerator and denominator terms are permutations of each other across the full domain. The product telescopes to 1.

### Code: Plookup Grand Product Check

The following Python demonstrates the core Plookup identity. When lookups are valid, $F = G$. When a lookup is invalid, the fingerprints diverge.

```python
def encode_pair(a, b, beta, gamma):
    """Encode adjacent pair (a, b) as a field element."""
    return gamma * (1 + beta) + a + beta * b

def plookup_check(lookups, table, beta=2, gamma=5):
    """
    Verify lookups is a subset of table via Plookup grand product.

    Args:
        lookups: List of values being looked up
        table: Sorted list of valid table entries

    Returns: (F, G, valid) where F and G are the fingerprints
    """
    # Construct the sorted merge s = sort(lookups union table)
    s = sorted(lookups + table)

    # G: fingerprint of s's adjacent pairs
    G = 1
    for i in range(len(s) - 1):
        G *= encode_pair(s[i], s[i+1], beta, gamma)

    # F: expected fingerprint if lookups subset of table
    # F = (1+beta)^n * product of (gamma + f_i) * product of table pairs
    n = len(lookups)
    F = (1 + beta) ** n

    for f in lookups:
        F *= (gamma + f)

    for i in range(len(table) - 1):
        F *= encode_pair(table[i], table[i+1], beta, gamma)

    return F, G, (F == G)

# Example 1: Valid lookups {2, 5} into table {0,1,2,3,4,5,6,7}
F, G, valid = plookup_check([2, 5], list(range(8)))
print(f"Valid lookups:   F={F}, G={G}, F==G: {valid}")

# Example 2: Invalid lookup (9 not in table)
F, G, valid = plookup_check([2, 9], list(range(8)))
print(f"Invalid lookups: F={F}, G={G}, F==G: {valid}")

# Example 3: Repeated valid lookups
F, G, valid = plookup_check([3, 3, 3], list(range(8)))
print(f"Repeated valid:  F={F}, G={G}, F==G: {valid}")
```

Output:
```
Valid lookups:   F=563374005, G=563374005, F==G: True
Invalid lookups: F=614965890, G=447828498, F==G: False
Repeated valid:  F=12754584, G=12754584, F==G: True
```

The identity holds for valid lookups (including repetitions) and fails for invalid ones. In the real protocol, the check happens via polynomial commitments over a finite field, but the algebraic structure is identical.


## Plookup Cost Analysis

**Without lookups** (bit decomposition for two 3-bit range checks):

- 6 bitness constraints + 2 reconstruction = 8 constraints

**With lookups**:

- 2 lookups, each ~3 constraints (the Plookup overhead)
- Table of size 8 adds no verification cost

For small ranges, the savings are modest. The power appears at scale.

**16-bit range check**:

- Without: 17 constraints per check
- With: ~3 constraints per check

**8-bit XOR**:

- Without: ~25 constraints
- With: ~3 constraints (one lookup into a $256 \times 256$ table)

The table size ($65,536$ entries for 16-bit range or 8-bit XOR) is precomputed and committed once. Lookups against it are cheap.


## Multiple Tables and Structured Lookups

Real circuits need multiple lookup tables:

- Range tables of various sizes
- XOR tables for different bit widths
- Opcode tables for VM verification
- Custom function tables (e.g., $\sin$, $\exp$ approximations)

**Multi-table extensions**: Modern systems (cq, Halo2 lookups) support multiple tables efficiently. The prover specifies which table each lookup targets; the grand product extends to handle the multiplexing.

**Structured tables**: Some tables have algebraic structure (e.g., $\{0, 1, \ldots, 2^{16}-1\}$ is an arithmetic sequence). Specialized arguments exploit this structure for better performance.


## Comparison: Custom Gates vs. Lookup Tables

Both mechanisms extend PLONK beyond vanilla gates. They address different problems.

### Custom Gates

A custom gate adds terms to the universal gate equation:

$$Q_L a + Q_R b + Q_O c + Q_M ab + Q_{\text{pow5}} a^5 + Q_C = 0$$

The new selector $Q_{\text{pow5}}$ enables efficient fifth-power computation (useful for Poseidon S-boxes).

**Strengths**:

- No table precomputation
- No additional polynomial commitments
- Native for algebraic relations

**Limitations**:

- The relation must be low-degree
- A degree-$2^{16}$ polynomial for range checks is infeasible

**Best for**: Compact algebraic operations such as boolean checks ($x^2 - x = 0$), elliptic curve point operations, and specialized hash function components.

### Lookup Tables

A lookup table is a separate mechanism:

- Precompute valid tuples
- Prove witness tuples appear in the table

**Strengths**:

- Handles non-algebraic operations
- Table size is independent of verification cost
- One table serves all lookups against it

**Limitations**:

- Adds polynomial commitments to the proof
- Requires sorting and permutation checks
- Tables must fit in memory

**Best for**: Range checks, bitwise operations, state machine transitions, arbitrary function approximations.

### When to Use Which

| Problem | Custom Gate | Lookup Table |
|---------|-------------|--------------|
| Boolean check ($x \in \{0,1\}$) | Ideal | Overkill |
| 8-bit range check | Possible | Efficient |
| 64-bit range check | Impractical | Essential |
| XOR/AND/OR operations | Complex | Clean |
| Poseidon $x^5$ | One gate | Unnecessary |
| Valid opcode check | Complex | Direct |

Modern systems use both. UltraPLONK combines custom gates (for algebraic primitives) with lookup tables (for non-algebraic constraints).



## Alternative Lookup Protocols

Plookup was seminal but not unique. Several alternatives offer different trade-offs.

### LogUp: The Logarithmic Derivative Approach

LogUp represents a significant evolution from Plookup. Instead of grand products, it uses the identity:

$$\sum_{i=1}^{n} \frac{1}{\gamma + f_i} = \sum_{j=1}^{d} \frac{m_j}{\gamma + t_j}$$

where $m_j$ is the multiplicity, counting how many times table entry $t_j$ appears in the lookups $f$.

**The key insight**: If $f \subseteq t$ with multiplicities, then summing the reciprocals of $(\gamma + f_i)$ over all lookups must equal summing $m_j / (\gamma + t_j)$ over table entries. The multiplicity $m_j$ counts how many lookups reference $t_j$.

**Why this matters**:

1. **No sorting required.** Plookup requires constructing and committing to the sorted vector $s$. LogUp skips this entirely: no sorted polynomial, no sorting constraints.

2. **Additive structure.** Products become sums of fractions. This enables:

   - Simpler multi-table handling (just add the sums)
   - Natural integration with sum-check protocols
   - Easier batching of multiple lookup arguments

3. **Better cross-table lookups.** When a circuit uses multiple tables (range, XOR, opcodes), LogUp handles them in a unified sum rather than separate grand products.

**LogUp-GKR**: Combines LogUp with the GKR protocol for even greater efficiency. The multiplicities $m_j$ are verified via sum-check rather than explicit commitment, reducing prover work for large tables.

**The equation in protocol form**:

Define:
$$h(X) = \sum_{i: f(\omega^i) = f_i} \frac{1}{\gamma + f(\omega^i)} - \sum_{j} \frac{m_j}{\gamma + t_j}$$

If the lookup is valid, $h(X)$ sums to zero over the domain. This is verified via sum-check or a grand sum argument.

### cq (Cached Quotients)

A refinement of the logarithmic derivative approach optimized for repeated lookups.

**Advantages**: Pre-computes quotient polynomials for the table. Amortizes table processing across multiple lookup batches.

**Trade-offs**: Setup overhead; benefits emerge with many lookups against the same table.

### Caulk and Caulk+

Caulk (2022) asked a different question: what if the table is *huge* but you only perform a few lookups? Plookup's prover work scales linearly with table size, making it impractical for tables of size $2^{30}$ or larger.

**The insight**: Preprocess the table into a KZG commitment. When the prover looks up values, they prove the lookup values exist in the committed table *without* touching the entire table during proving.

**How it works**: The table polynomial $t(X)$ is committed during setup. For each lookup, the prover constructs a "witness" polynomial that proves the lookup value is a root of a polynomial derived from $t$. The key is using the structure of KZG to make these proofs small and fast.

**Complexity**: Prover work is $O(m^2 + m \log N)$ for $m$ lookups into a table of size $N$, sublinear in $N$ when $m \ll N$.

**Trade-off**: Requires trusted setup (KZG). More complex than Plookup. The quadratic term in $m$ limits scalability for many lookups.

**Caulk+** refined this to $O(m^2)$ prover complexity, removing the $\log N$ term entirely. The table size effectively disappears from prover cost.

### Halo2 Lookups

Halo2, developed by the Electric Coin Company (Zcash), integrates lookups natively with a "permutation argument" variant rather than Plookup's grand product.

**The approach**: Instead of sorting and checking adjacent pairs, Halo2 uses a *shuffle argument*. The prover demonstrates that the multiset of lookups (with multiplicities) is a permutation of a subset of the table (with appropriate multiplicities).

**Key differences from Plookup**:

- No explicit sorted vector $s$
- Multiplicities are handled via a separate "permutation" polynomial
- Tighter integration with Halo2's recursive verification model

**In practice**: Halo2's lookup API lets developers define tables declaratively. The proving system handles the constraint generation automatically. This made Halo2 popular for application circuits: you specify *what* to look up, not *how* the lookup argument works.

**Ecosystem**: Scroll, Taiko, and other L2s built on Halo2 rely on its lookup system for zkEVM implementation.

### The Memory Bottleneck

All the protocols above share a fundamental limitation: **the prover must commit to polynomials whose degree scales with table size**.

For Plookup, the sorted vector $s$ has length $n + d$ (lookups plus table). For LogUp, the multiplicity polynomial has degree $d$. For Caulk, the table polynomial $t(X)$ must be committed during setup. In every case, a table of size $2^{20}$ means million-coefficient polynomials. A table of size $2^{64}$ means polynomials with more coefficients than atoms in a grain of sand.

This is the memory bottleneck. It's not just "expensive"; it's a hard wall. The evaluation table of a 64-bit ADD instruction has $2^{128}$ entries. No computer can store that polynomial, let alone commit to it.

Early zkVMs worked around this by using small tables (8-bit or 16-bit operations) and paying the cost in constraint complexity for larger operations. A 64-bit addition became a cascade of 8-bit additions with carry propagation. It worked, but it was slow.

Lasso breaks through this wall entirely.

### Lasso and Jolt

Lasso (2023, Setty-Thaler-Wahby) represents the solution to the memory bottleneck: prover costs that scale with *lookups performed* rather than *table size*.

**Read-Only vs. Read-Write.** Before diving into the mechanism, distinguish two types of lookups:

*Static tables (read-only)*: Fixed functions like XOR, range checks, or AES S-boxes. The table never changes during execution. Plookup, LogUp, and Lasso excel here.

*Dynamic tables (read-write)*: Simulating RAM (random access memory). The table starts empty and fills up as the program runs. This requires different techniques (like memory-checking arguments or timestamp-based permutation checks) because the table itself is witness-dependent. Jolt uses specialized protocols called Twist and Shout for this.

Lasso focuses on static tables, but its decomposition insight is what makes truly large tables tractable.

**Lasso's insight**: *Decomposable tables*. Many tables have structure: their MLE (multilinear extension) can be written as a weighted sum of smaller subtables:

$$\tilde{T}(y) = \sum_{j=1}^{\alpha} c_j \cdot \tilde{T}_j(y_{S_j})$$

Each subtable $\tilde{T}_j$ looks at only a small chunk of the total input $y$. This "Structure of Sums" (SoS) property enables dramatic efficiency gains.

**Example: 64-bit AND.** The conceptual table has $2^{128}$ entries (all pairs of 64-bit inputs). But bitwise AND decomposes perfectly: split inputs into sixteen 4-bit chunks, perform 16 lookups into a tiny 256-entry `AND_4` table, concatenate results. The prover never touches the $2^{128}$-entry table.

**The technical machinery**: Lasso builds on **Spark**, a commitment scheme for sparse polynomials from the Spartan protocol. The key insight: a lookup trace is a *sparse* "hit" vector. If you perform $m$ lookups into a table of size $N$, you access only $m$ entries. Lasso represents this sparse access pattern using Spark, then proves correctness via sum-check.

The prover's witnesses are:

- **$\tilde{E}(y)$**: The "existence" polynomial (1 if index $y$ was accessed, 0 otherwise)
- **$\tilde{a}(y)$**: The values looked up at each accessed index
- **$\{\tilde{M}_{V,j}\}$**: Coefficient polynomials that correctly wire subtable results together

The verifier never sees the full table. For structured tables, she can evaluate $\tilde{T}(r)$ at a random challenge point in $O(\log N)$ time using the table's algebraic formula.

**Prover costs**: For $m$ lookups into a table decomposed into $c$ chunks with subtables of size $N^{1/c}$:

$$\text{Committed elements} \approx 3cm + \alpha N^{1/c}$$

Crucially, most committed values are *small integers* (counts in $\{0, \ldots, m\}$). Committing to small scalars is dramatically faster than random field elements; this is Lasso's performance breakthrough.

---

**Jolt** applies Lasso to build a complete zkVM for RISC-V. The philosophy: replace arithmetization of instruction semantics with lookups.

Consider the `JOLT_V` table, the evaluation table of the entire RISC-V instruction set:

$$\text{JOLT\_V}(\text{opcode}, a, b) = f_{\text{op}}(a, b)$$

For a 64-bit machine with 256 opcodes, this table has $2^{136}$ entries. Storing it is physically impossible.

**Jolt's insight**: This giant table is *decomposable*. A 64-bit ADD decomposes into 16 lookups into 4-bit addition subtables. A 64-bit XOR decomposes into 16 independent 4-bit XOR lookups. The subtables are tiny (256 entries each), pre-computed once, and reused for every instruction.

**Jolt's architecture**:

1. **Lasso for instruction semantics**: Proves that each instruction's output matches its subtable lookups. No arithmetization of CPU logic.
2. **Spartan (R1CS) for wiring**: Proves the simple algebraic relationships (program counter updates, register consistency, data flow between components)
3. **Specialized memory protocols**: **Twist** handles RAM consistency (LOAD/STORE); **Shout** ensures instructions are fetched from the committed bytecode

**Why this hybrid?** Arithmetizing a 64-bit XOR in R1CS requires 64+ constraints (bit decomposition, per-bit logic). Jolt proves it with 16 cheap lookups. But simple wiring constraints ("this value flows from register to ALU") are trivial in R1CS. Use each tool where it excels.

**Performance**: Jolt achieves roughly 50,000 cycles per RISC-V instruction, orders of magnitude faster than prior zkVMs. The "lookup singularity" becomes real: proving a VM is just proving structured table lookups.

**Trade-offs**: Requires decomposable table structure. Arbitrary tables (like SHA-256, which is intentionally non-linear) don't benefit. But for CPU instruction sets, the structure is natural: most operations are bitwise or arithmetic with clean chunk decompositions.

The field continues evolving. The core insight (reducing set membership to polynomial identity) admits many instantiations, each optimizing for different table sizes, structures, and use cases.



## Integration with STARKs

Lookup arguments aren't exclusive to PLONK. STARK-based systems integrate them via the AIR (Algebraic Intermediate Representation) framework.

In AIR terms:

- The lookup table becomes a public column in the trace
- Witness values to be looked up appear in other columns
- A running product column accumulates the grand product
- Transition constraints enforce the recursive relation

The conceptual structure is identical; the implementation adapts to the STARK trace model rather than PLONK's polynomial commitments.

Modern STARK systems (Cairo, RISC0, SP1) rely heavily on lookup arguments for efficient VM verification.



## The Role in zkVMs

Lookup arguments are foundational for zero-knowledge virtual machines.

A zkVM proves correct execution of arbitrary programs. The "table" encodes valid instruction semantics:

- Opcode validity
- Memory read/write consistency
- Bitwise operation results
- Range checks on registers

Without lookups, encoding these constraints algebraically would explode the circuit size. With lookups, each instruction verification reduces to a few table membership proofs.

**Example**: Verifying a RISC-V ADD instruction.

- Without lookups: Decompose 32-bit operands, verify carry propagation, reconstruct result (dozens of constraints).
- With lookups: Single lookup proving $(a, b, a+b \mod 2^{32})$ is in the addition table (3 constraints).

The efficiency gain is multiplicative across millions of instructions. zkVMs would be impractical without lookup arguments.



## Key Takeaways

**General principles** (apply to all lookup arguments):

1. **Lookup arguments shift complexity from logic to data**: Precompute valid tuples; prove membership rather than computation. This is the core insight shared by Plookup, LogUp, Lasso, and all variants.

2. **The formal problem**: Given lookups $f$ and table $t$, prove $f \subseteq t$. Different protocols reduce this multiset inclusion to different polynomial identities.

3. **Cost structure**: Lookup-based proofs achieve roughly constant cost per lookup, independent of the logical complexity of what the table encodes. A 16-bit range check or an 8-bit XOR costs the same as a simple membership test.

4. **Complements custom gates**: Lookups handle non-algebraic constraints; custom gates handle algebraic primitives. Modern systems (UltraPLONK, Halo2) use both.

5. **zkVM foundation**: Without lookup arguments, verifying arbitrary computation at scale would be infeasible. Every major zkVM relies on lookups for instruction semantics.

**Plookup-specific mechanics** (the sorted-merge approach from Section 2):

6. **Sorted vector reduction**: Plookup transforms $f \subseteq t$ into a claim about the sorted merge $s = \text{sort}(f \cup t)$.

7. **Adjacent pair property**: In Plookup, every consecutive pair in $s$ is either a repeat (from $f$ slotting in) or exists as adjacent in $t$.

8. **Grand product identity**: The polynomial identity $F \equiv G$ encodes Plookup's adjacent-pair check. The accumulator $Z(X)$ enforces this recursively, integrating with PLONK's permutation machinery.

**Alternative approaches** (different trade-offs):

9. **LogUp** replaces products with sums of logarithmic derivatives: no sorting, cleaner multi-table handling, natural sum-check integration.

10. **Lasso** achieves prover costs scaling with lookups performed rather than table size, enabling tables of size $2^{128}$ via decomposition into small subtables.



\newpage

# Chapter 15: STARKs

While Gabizon and Williamson were building PLONK, a parallel revolution was underway.

Eli Ben-Sasson had been thinking about proofs for two decades. As a theoretical computer scientist, he'd worked on probabilistically checkable proofs (PCPs) since the early 2000s, the remarkable discovery that any mathematical proof can be encoded so that a verifier need only spot-check a few random bits to detect errors. PCPs had transformed complexity theory but remained a theoretical curiosity. The constructions were galactic: asymptotically efficient, practically useless.

Then came the blockchain era. Suddenly there was demand for proofs that were not only short and easy to verify, but *trustless*. The SNARKs emerging in 2013-2016 (Pinocchio, Groth16) achieved remarkable succinctness using pairing-based cryptography. But they required trusted setup: someone generated secret parameters, hopefully destroyed them, and everyone trusted the ceremony worked. PLONK (2019) would make the setup universal and updatable, but couldn't eliminate it entirely. The "toxic waste" remained.

Ben-Sasson asked a different question: could you build proof systems using *nothing but hash functions*?

In 2018, the same year PLONK was taking shape, Ben-Sasson and colleagues (Iddo Bentov, Yinon Horesh, and Michael Riabzev) published "Scalable, Transparent, and Post-quantum Secure Computational Integrity." The acronym spelled **STARK**: Scalable Transparent ARgument of Knowledge. The key words were *transparent* (no trusted setup, no toxic waste, no ceremonies) and *post-quantum* (secure against quantum computers). Where PLONK optimized pairing-based cryptography, STARKs abandoned it entirely.

The theoretical foundations weren't new. Interactive Oracle Proofs (IOPs), the FRI protocol (Fast Reed-Solomon Interactive Oracle Proof of Proximity), the ALI protocol (Algebraic Linking IOP): these had been developed over the preceding years, often by the same researchers. What the 2018 paper achieved was synthesis: a complete system that could prove arbitrary computations with practical efficiency, security based only on collision-resistant hashing.

Ben-Sasson founded StarkWare the same year to commercialize the technology. By 2020, StarkEx was processing transactions on Ethereum, around the same time Plookup was solving the lookup problem for PLONK-based systems. Other teams followed: Polygon (formerly Matic) developed their own STARK implementation, RISC Zero built a STARK-based zkVM, and the open-source ecosystem grew.

The two paradigms, pairing-based (Groth16, PLONK) and hash-based (STARKs), now coexist in production, each with distinct trade-offs. This chapter develops the STARK paradigm: how hash-based polynomial commitments (Chapter 10's FRI) combine with a state-machine model of computation to yield proofs that are transparent, scalable, and quantum-resistant, at the cost of larger proof sizes than their pairing-based cousins.

---

## Why Not Pairings?

The most efficient SNARKs in Chapters 12-13 rely on pairing-based polynomial commitments. Groth16 builds pairings directly into its verification equation. PLONK is a polynomial IOP, agnostic to the commitment scheme, but achieves its smallest proofs when compiled with KZG, which requires pairings. The bilinear map $e: \mathbb{G}_1 \times \mathbb{G}_2 \to \mathbb{G}_T$ is what enables constant-size proofs and $O(1)$ verification.

This foundation is remarkably productive. But it carries costs that grow heavier with scrutiny.

**The first cost is trust.** A KZG commitment scheme requires a structured reference string: powers of a secret $\tau$ encoded in the group. Someone generated that $\tau$. If they kept it, they can forge proofs. The elaborate ceremonies of Chapter 12 (the multi-party computations, the public randomness beacons, the trusted participants) exist to distribute this trust. But distributed trust is still trust. The ceremony could fail. Participants could collude. The procedures could contain subtle flaws discovered years later.

**The second cost is quantum vulnerability.** Shor's algorithm solves discrete logarithms in polynomial time on a quantum computer. The security of KZG, Groth16, and IPA all rest on the hardness of discrete log in elliptic curve groups. Pairings add structure on top of this assumption but don't change the underlying vulnerability. When a sufficiently large quantum computer exists, all these schemes break. When that day comes is uncertain. That it will come seems increasingly likely. A proof verified today may need to remain trusted for decades.

**The third cost is algebraic rigidity.** Pairings require carefully chosen curves with embedding degree constraints, specific field characteristics, and compatible subgroups. The curves must support efficient pairing computation while remaining cryptographically secure, a delicate balance that has produced a small family of "pairing-friendly" curves, each with its own quirks and potential weaknesses.

STARKs abandon elliptic curves entirely. They ask a more primitive question: *what can we prove using only hash functions?*



## The Hash Function Gambit

A collision-resistant hash function is perhaps the most conservative cryptographic assumption we have. SHA-256, Blake3, Keccak: these primitives are analyzed relentlessly, deployed universally, and trusted implicitly. They offer no algebraic structure, no homomorphisms, no elegant equations. Just a box that takes input and produces output, where finding two inputs with the same output is computationally infeasible.

The quantum story here is fundamentally different from discrete log. Grover's algorithm provides a quadratic speedup for unstructured search, reducing the security of a 256-bit hash from $2^{256}$ to $2^{128}$ operations. This is manageable: use a larger hash output and security is restored. Contrast this with Shor's exponential speedup against discrete log, which breaks the problem entirely rather than merely weakening it.

This seems like a step backward. Algebraic structure is what made polynomial commitments possible. KZG works because $g^{p(\tau)}$ preserves polynomial relationships, because the commitment scheme respects the algebra of the underlying object. A hash function respects nothing. $H(a + b) \neq H(a) + H(b)$. The hash of a polynomial evaluation tells you nothing about the polynomial.

Yet hash functions offer something pairings cannot: a Merkle tree. Chapter 10 developed this machinery in detail; here we summarize the key ideas before showing how STARKs compose them into a complete proof system.

Commit to a sequence of values by hashing them into a binary tree. The root is the commitment. To open any leaf, provide the authentication path, the $O(\log n)$ hashes connecting that leaf to the root. The binding property is information-theoretic within the random oracle model: changing any leaf changes the root. No trapdoors, no toxic waste, no ceremonies.

The problem is that a Merkle commitment is too strong in one sense and too weak in another. Too strong: opening a position requires $O(\log n)$ hash values, not $O(1)$ like KZG. Too weak: there's no way to prove anything *about* the committed values without opening them. A KZG commitment to a polynomial $p$ lets you prove $p(z) = v$ with a single group element. A Merkle commitment to the evaluations of $p$ on a domain lets you prove $p(z) = v$ only if $z$ happens to be one of the committed points, and only by opening that point explicitly.

The insight behind STARKs is that these limitations can be overcome by a shift in perspective. Instead of proving polynomial identities directly, we prove that a committed function is *close to* a low-degree polynomial. This is the domain of coding theory, not algebra. And coding theory has powerful tools for detecting errors through random sampling.

## The Reed-Solomon Lens

The key insight comes from an unexpected source: a 1960 paper by Irving Reed and Gustave Solomon, written not for cryptography but for sending data to spacecraft.

The problem they faced was corruption. Radio signals degrade over interplanetary distances. Cosmic rays flip bits. Antenna interference scrambles transmissions. If you beam raw data to a satellite, any corruption destroys information irretrievably. Reed and Solomon asked: can we encode messages so that errors become *visible*, so corrupted data announces itself as corrupted?

Their answer was polynomials.

**The encoding trick.** To protect $k$ symbols, interpret them as coefficients of a degree-$(k-1)$ polynomial $p(X)$. Then evaluate $p$ at $n \gg k$ points. Send these $n$ evaluations instead of the original $k$ symbols. This is deliberate redundancy, more data than strictly necessary.

Why does this help? Because polynomials are rigid objects. A degree-$(k-1)$ polynomial is completely determined by any $k$ of its evaluations (Lagrange interpolation). The remaining $n - k$ evaluations add no new information; they're mathematically implied by the first $k$. But they add *constraints*. Every evaluation must be consistent with a single underlying polynomial.

**The beautiful consequence.** Corrupt even one evaluation, and the spell breaks. The corrupted sequence no longer lies on *any* degree-$(k-1)$ polynomial. The error doesn't hide; it creates a global inconsistency. This is the magic that makes Reed-Solomon codes work on CDs, DVDs, QR codes, and the Voyager spacecraft still transmitting from interstellar space.

Think of it this way: a polynomial is like a crystal lattice. Every atom's position is determined by the structure as a whole. You cannot move one atom without shattering the crystal (or rather, you can move it, but what remains is no longer a crystal of the same type). It's a defect, and the defect is visible from almost any angle. A forger trying to fake a polynomial faces this crystalline rigidity. They can change one point, but they cannot make the change local. The alteration propagates, disrupts the global pattern, and announces itself to anyone who checks a random position.

**The distance property.** How different is a corrupted codeword from valid ones? Dramatically. Two distinct degree-$(k-1)$ polynomials agree on at most $k-1$ points (their difference is a degree-$(k-1)$ polynomial with at most $k-1$ roots). So any two valid codewords differ in at least $n - k + 1$ positions. Errors don't cluster; they spread across most of the codeword. Random sampling finds them.

**The connection to STARKs.** The prover commits to function evaluations via Merkle tree. They claim these evaluations correspond to a low-degree polynomial. If they're lying (if the committed function isn't actually low-degree) it disagrees with *every* low-degree polynomial on at least $n - k + 1$ points. Random queries find these disagreements with high probability.

This is the leverage STARKs exploit. The verifier doesn't need to check all $n$ evaluations. A random sample suffices. If the committed function deviates from any low-degree polynomial (if the prover is cheating) the deviations are spread across most of the domain. Random queries expose the lie.

The **FRI protocol** (Chapter 10) formalizes this. Given a Merkle commitment to function evaluations, FRI proves the function is close to a polynomial of bounded degree. The prover cannot commit to garbage and claim it's low-degree; the random queries expose the lie.

But FRI alone proves only that *some* polynomial is committed. We need to prove the *right* polynomial, one whose low-degree-ness implies validity of the original computation.



## Computation as State Evolution

The proof systems of previous chapters represent computation as circuits: directed acyclic graphs where wires carry values and gates impose constraints. This is a natural model for expressing single computations, but it handles iteration awkwardly. A loop executing $n$ times becomes $n$ copies of the loop body, each a separate subcircuit. The structure that made the loop simple to write (the repetition of identical operations) is obscured in the flattened graph.

STARKs adopt a different model: the **state machine**.

Think of a computation as a **flip book animation**. In the circuit model, you tear out every page, lay them flat on the floor, and wire them together with string showing which drawings connect to which. The result is a sprawling diagram where the sequential flow is lost in a web of connections. In the state machine model, you keep the book bound. Each page is a complete snapshot (the state at one moment), and you write down one rule of physics that governs how any page transforms into the next. The rule is the same for every page flip. To verify the animation, you don't need to trace all the strings; you just check that each pair of adjacent pages obeys the physics. A computation is a sequence of states $S_0, S_1, \ldots, S_{T-1}$ evolving over discrete time. Each state is a tuple of register values. A transition function $f$ maps $S_i$ to $S_{i+1}$. The function $f$ is fixed, the same at every timestep. Only the register values change.

This model fits iterative computation like a glove. A hash function running for $n$ rounds is $n$ applications of the same round function. A CPU executing $n$ instructions is $n$ applications of the same instruction-processing logic (with the instruction itself read from a register). The uniformity across timesteps isn't merely notational convenience. It's the key to efficient proofs.

Consider a circuit representation of $n$ loop iterations. Each iteration contributes its own gates and constraints. The total constraint count scales with $n$. Now consider a state machine representation. The transition constraints describe one step: "if the current state satisfies certain conditions, the next state must satisfy certain other conditions." This description has fixed size, independent of $n$. The same constraints apply at every timestep.

**A tiny example.** Suppose we want to prove we computed $3^8 = 6561$. The state machine has two registers: a counter $c$ and an accumulator $a$. The transition rule: $c' = c + 1$ and $a' = a \cdot 3$. The trace:

| Step | $c$ | $a$ |
|------|-----|------|
| 0    | 0   | 1    |
| 1    | 1   | 3    |
| 2    | 2   | 9    |
| 3    | 3   | 27   |
| 4    | 4   | 81   |
| 5    | 5   | 243  |
| 6    | 6   | 729  |
| 7    | 7   | 2187 |
| 8    | 8   | 6561 |

The transition constraint ("next accumulator equals current accumulator times 3") is the same at every row. We don't need 8 separate multiplication gates; we need one constraint that holds 8 times. The prover commits to the entire trace, then proves the constraint holds everywhere. For $3^{1000000}$, the constraint is still just one equation; only the trace grows longer.

The table above *is* a trace. The "Step" column is just a label; the actual trace is the $c$ and $a$ columns, a matrix with $w = 2$ registers and $T = 9$ rows. Each row captures the complete state at one moment; each column tracks one register's journey through time. Reading across tells you what happened at step 4. Reading down tells you how the accumulator evolved.

This is the conceptual shift from circuits to state machines. The witness changes from a circuit-wide assignment to a **trace**, a matrix where row $i$ is the state $S_i$ and each column is a register's evolution over time. Proving the computation is valid means proving that every adjacent pair of rows $(S_i, S_{i+1})$ satisfies the transition constraints.



## Algebraic Intermediate Representation

An **AIR** (Algebraic Intermediate Representation) encodes this structure in polynomial form.

The trace is a matrix with $w$ columns (registers) and $T$ rows (timesteps). Each column, viewed as a sequence of $T$ field elements, becomes a polynomial via interpolation. Choose a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{T-1}\}$ where $\omega$ is a primitive $T$-th root of unity. The column polynomial $P_j(X)$ is the unique polynomial of degree less than $T$ satisfying $P_j(\omega^i) = \text{trace}[i][j]$.

**Returning to our example.** In the $3^8$ trace, we have two registers: $c$ (the counter) and $a$ (the accumulator). These become two column polynomials:

- $P_c(X)$: the unique degree-8 polynomial passing through $(1, 0), (\omega, 1), (\omega^2, 2), \ldots, (\omega^8, 8)$
- $P_a(X)$: the unique degree-8 polynomial passing through $(1, 1), (\omega, 3), (\omega^2, 9), \ldots, (\omega^8, 6561)$

The transition constraint "next accumulator = current accumulator × 3" becomes: $P_a(\omega X) = 3 \cdot P_a(X)$. At $X = \omega^2$, this says $P_a(\omega^3) = 3 \cdot P_a(\omega^2)$, i.e., $27 = 3 \cdot 9$. The polynomial identity encodes all 8 transition checks at once.

**The general pattern.** If the transition function requires that register $r_0$ at step $i+1$ equals $r_0^3 + r_1$ at step $i$, this becomes:

$$P_0(\omega X) = P_0(X)^3 + P_1(X)$$

The left side is the "next-step" value of register 0: $P_0(\omega \cdot \omega^i) = P_0(\omega^{i+1})$. The right side is the required function of current-step values.

This identity must hold at every transition. When $X = \omega^i$, the left side becomes $P_0(\omega^{i+1})$ (next-step value) and the right side uses $P_0(\omega^i), P_1(\omega^i)$ (current-step values). So $X \in \{1, \omega, \ldots, \omega^{T-2}\}$ checks steps $0 \to 1$, $1 \to 2$, ..., $(T-2) \to (T-1)$, covering all $T-1$ transitions. Define the constraint polynomial:

$$C(X) = P_0(\omega X) - P_0(X)^3 - P_1(X)$$

If the trace is valid, $C(X)$ vanishes on $H' = \{1, \omega, \ldots, \omega^{T-2}\}$. By the factor theorem, $C(X)$ is divisible by the vanishing polynomial $Z_{H'}(X) = \prod_{h \in H'}(X - h)$. The quotient:

$$Q(X) = \frac{C(X)}{Z_{H'}(X)}$$

is a polynomial of known degree. If $C(X)$ doesn't vanish on $H'$ (if the trace violates the transition constraint somewhere) then $Q(X)$ isn't a polynomial. It's a rational function with poles at the violation points.

> **Why Constraint Degree Matters**
>
> The degree of the constraint polynomial $C(X)$ directly impacts prover cost. If a transition constraint involves $P_0(X)^3$, that term has degree $3(T-1)$ (since $P_0$ has degree $T-1$). The composition polynomial inherits this: $\deg(\text{Comp}) \approx \deg(\text{constraint}) \times T$. The prover must commit to this polynomial over the LDE domain, and FRI must prove its degree bound.
>
> This creates a fundamental trade-off. Higher-degree constraints let you express more complex transitions in a single step, but they blow up the prover's work. A degree-8 constraint over a million-step trace produces a composition polynomial of degree ~8 million, requiring proportionally more commitment and FRI work. Most practical AIR systems keep constraint degree between 2 and 4, accepting more trace columns (more registers) to avoid high-degree terms. The art of AIR design is balancing expressiveness against this degree bottleneck.

**Boundary constraints** pin down the inputs and outputs. Transition constraints say "each step follows the rules"; boundary constraints say "we started here and ended there." In our $3^8$ example:

- **Input**: $P_a(1) = 1$ (accumulator starts at 1)
- **Output**: $P_a(\omega^8) = 6561$ (accumulator ends at $3^8$)

Each becomes a divisibility check. If the input requires register 0 to equal 5 at step 0, the constraint $P_0(1) = 5$ becomes $P_0(X) - 5$ vanishing at $X = 1$, quotient $(P_0(X) - 5)/(X - 1)$.

**Batching via random linear combination.** We have multiple constraints: transition constraints (one quotient $Q_{\text{trans}}$), and boundary constraints (quotients $Q_{\text{in}}, Q_{\text{out}}$, possibly more). Rather than prove each separately, we batch them into a single polynomial using random challenges $\alpha_1, \alpha_2, \ldots$ (derived via Fiat-Shamir):

$$\text{Comp}(X) = \alpha_1 Q_{\text{trans}}(X) + \alpha_2 Q_{\text{in}}(X) + \alpha_3 Q_{\text{out}}(X) + \ldots$$

Why does this work? If all quotients are polynomials, their linear combination is a polynomial. If any quotient has a pole (from a violated constraint), the random combination almost certainly preserves that pole: the $\alpha_i$ values would need to be precisely chosen to cancel it, which happens with negligible probability over a large field.

This batching trick is ubiquitous: it reduces "prove $n$ things" to "prove 1 thing" with only a single random challenge per claim. The verifier's work stays constant regardless of constraint count.

**The complete picture.** A STARK proves three things simultaneously:

1. **Transition constraints**: the quotient $Q_{\text{trans}}(X) = C(X) / Z_{H'}(X)$ is a polynomial (each step follows the rules)
2. **Input boundary**: $(P_a(1) - 1)/(X - 1)$ is a polynomial (accumulator starts at 1)
3. **Output boundary**: $(P_a(\omega^8) - 6561)/(X - \omega^8)$ is a polynomial (accumulator ends at 6561)

All three get batched into one composition polynomial. If any constraint fails (wrong transition, wrong input, wrong output) the composition polynomial has a pole, and FRI rejects it as non-low-degree.

The STARK protocol reduces to: the prover commits to the trace polynomials, derives challenges, computes the composition polynomial (batching transition and boundary quotients), and proves (via FRI) that it's low-degree.



## The Low-Degree Extension

Here is where the Merkle/FRI machinery enters.

The trace polynomials $P_j(X)$ have degree less than $T$ (the number of timesteps, 9 in our $3^8$ example). The trace domain $H = \{1, \omega, \ldots, \omega^{T-1}\}$ has exactly $T$ points, so the polynomial fits perfectly: $T$ points determine a degree-$(T-1)$ polynomial.

The prover evaluates them not on $H$ alone, but on a larger domain $D \supset H$, typically 4 to 16 times larger. This is the **low-degree extension (LDE)**.

Why extend beyond $H$? Not because we need more space (the polynomial already fits $H$ exactly). We extend for *redundancy*, the same reason Reed-Solomon codes evaluate beyond the message length. The key insight is that **if you only check points in $H$, the prover can cheat by committing to any function that happens to match the "right" values on $H$, regardless of whether it's a low-degree polynomial.**

**A tiny example.** Suppose the honest trace polynomial is $P(X) = X$ (degree 1), evaluated on $H = \{1, 2\}$: values are $P(1) = 1, P(2) = 2$. A cheating prover wants to claim a different trace, say values $1, 5$ on $H$. They commit to some function $f$ with $f(1) = 1, f(2) = 5$.

If the verifier only checks points in $H$, the cheater wins: $f$ gives the "right" answers on $H$ by construction. But there's no degree-1 polynomial through $(1, 1)$ and $(2, 5)$ that equals the honest $P(X) = X$.

Now extend to $D = \{1, 2, 3, 4\}$. The honest polynomial $P(X) = X$ extends to $P(3) = 3, P(4) = 4$. The cheater's function $f$, whatever it is, must give *some* values at 3 and 4. If $f$ is the degree-1 polynomial through $(1,1)$ and $(2,5)$, that's $f(X) = 4X - 3$, so $f(3) = 9, f(4) = 13$.

**But what check catches this?** The verifier doesn't know the "honest" values; they're trying to determine if the prover is honest. The answer: the verifier checks *constraints*. The trace must satisfy some relation, say $P(2) = 2 \cdot P(1)$ (doubling). The honest trace $(1, 2)$ satisfies this. The cheater's trace $(1, 5)$ doesn't: $5 \neq 2 \cdot 1$.

This constraint failure propagates. The constraint polynomial $C(X) = P(2X) - 2P(X)$ should vanish on $H$. For the cheater, it doesn't, so $C(X)/Z_H(X)$ has a pole. It's not a polynomial. When the verifier runs FRI on this "quotient," they're testing whether a non-polynomial is low-degree. FRI queries random points in $D$, and at most of them, the non-polynomial disagrees with every actual low-degree polynomial. Extension doesn't just spread the trace; it spreads the *evidence of constraint violation*.

With larger extension factors (say $|D| = 8|H|$), FRI's random queries land outside $H$ with probability 7/8, catching the fraud almost always.

The prover commits to the LDE evaluations via Merkle tree. Each leaf is $P_j(x)$ for some $x \in D$. The root is the commitment. Once committed, the prover cannot change evaluations without breaking the Merkle binding.

Now suppose the prover cheated on the trace at row $i$. The constraint polynomial $C(X)$ doesn't vanish at $\omega^i$. The quotient $Q(X)$ has a pole there, so it's not a polynomial. The composition polynomial inherits this non-polynomiality. When evaluated on $D$, this "polynomial" disagrees with every actual low-degree polynomial at a constant fraction of points (the Reed-Solomon distance property). FRI's random queries detect this with overwhelming probability.



## The Complete Protocol

**Prover's Algorithm:**

1. Execute the computation, producing the execution trace.

2. Interpolate each trace column to obtain polynomials $P_1(X), \ldots, P_w(X)$ over domain $H$.

3. Evaluate these polynomials on the LDE domain $D$. Commit via Merkle tree. Output `trace_root`.

4. Derive random challenges $\alpha_1, \alpha_2, \ldots$ by hashing the transcript (Fiat-Shamir).

5. Compute constraint polynomials, form quotients, combine into the composition polynomial.

6. Evaluate the composition polynomial on $D$. Commit via Merkle tree. Output `composition_root`.

7. Run FRI on the composition polynomial, proving it has degree less than the known bound.

8. Derive query points $x_1, \ldots, x_k$ by hashing the transcript (Fiat-Shamir). For each $x_i$: open the trace polynomials and composition polynomial, providing Merkle authentication paths.

**How many queries?** Each query catches a cheater with probability roughly $1 - 1/\rho$, where $\rho$ is the blowup factor (size of $D$ divided by size of $H$). With $k$ queries, soundness error is roughly $(1/\rho)^k$. For 128-bit security with blowup factor 8, around 45 queries suffice.

**Verifier's Algorithm:**

1. Receive `trace_root`, `composition_root`, FRI commitments, and query responses.

2. Derive all Fiat-Shamir challenges from the transcript.

3. Verify FRI: check that the committed function is close to a low-degree polynomial.

4. For each query point $x$:
   - Verify the Merkle paths for trace openings.
   - Using the opened trace values at $x$, locally compute what the composition polynomial should equal at $x$.
   - Check that this matches the FRI-verified composition value.

5. Accept if all checks pass.

The last step, the **AIR-FRI link**, is crucial and often underappreciated. Consider what FRI actually proves: the committed function is close to *some* low-degree polynomial. That's it. FRI doesn't know about constraints, traces, or computations; it just tests degree.

A cheating prover could commit to the polynomial $P(X) = 0$, run FRI (which passes, since zero is certainly low-degree), and hope the verifier is satisfied. The AIR-FRI link closes this gap.

At each query point $x$, the verifier has:

- The trace values $P_1(x), \ldots, P_w(x)$ (opened via Merkle proof)
- The composition value $C(x)$ (verified by FRI)

The verifier *locally recomputes* what $C(x)$ should be: plug the trace values into the constraint equations, form the quotients, apply the random batching coefficients. This computation doesn't require the full polynomials, just the values at $x$. If the prover's committed composition matches this recomputation at all $k$ query points, the verifier accepts.

Why does this work? The prover committed to the trace *before* learning the query points (Fiat-Shamir). If the trace violates any constraint, the composition "polynomial" isn't actually low-degree; it has poles. FRI catches this. If the trace is valid but the prover committed to a *different* composition, the two disagree at most points (Schwartz-Zippel). The random queries catch this.

The AIR-FRI link is where the abstract (FRI proves low-degree) meets the concrete (this specific polynomial encodes this specific computation).

> **DEEP-FRI vs. Standard FRI**
>
> The protocol described here uses the **DEEP method** (Domain Extension for Eliminating Pretenders). In standard FRI, the verifier queries the composition polynomial only at points in the LDE domain $D$. A subtle attack exists: a cheating prover could commit to a function that's low-degree *on $D$* but encodes the wrong trace values. DEEP closes this gap by having the verifier sample a random point $z$ *outside* $D$ and requiring the prover to open trace polynomials there. Since honest trace polynomials are globally low-degree, they can be evaluated anywhere; a cheater who faked values only on $D$ cannot consistently answer queries at $z$. The "domain extension" refers to this expansion beyond $D$; "eliminating pretenders" refers to catching cheaters whose polynomials only *pretend* to be correct within the original domain.



## A Concrete Example: Fibonacci

Let's trace the protocol on a minimal computation: proving knowledge of the 7th Fibonacci number.

**The claim:** Starting from $F_0 = 1, F_1 = 1$, the sequence satisfies $F_6 = 13$.

**The trace:** Two registers $(a, b)$ representing consecutive Fibonacci numbers. We need 6 rows (steps 0-5) to compute $F_6$.

| Step | $a$ | $b$ |
|------|-----|-----|
| 0 | 1 | 1 |
| 1 | 1 | 2 |
| 2 | 2 | 3 |
| 3 | 3 | 5 |
| 4 | 5 | 8 |
| 5 | 8 | 13 |

**Transition constraints:** At each step $i \in \{0, \ldots, 4\}$:

- $a_{i+1} = b_i$ (the next $a$ is the current $b$)
- $b_{i+1} = a_i + b_i$ (the next $b$ is the sum)

**Boundary constraints:**

- $a_0 = 1$ (initial condition)
- $b_0 = 1$ (initial condition)
- $b_5 = 13$ (the claimed output $F_6$)

**Polynomials:** Let $\omega$ be a primitive 6th root of unity. Interpolate the $a$-column to get $A(X)$ with $A(\omega^i) = a_i$. Similarly for $B(X)$.

**Constraint polynomials:** The key trick: multiplying the input by $\omega$ shifts to the next row. Since $A(\omega^i) = a_i$, we have $A(\omega \cdot \omega^i) = A(\omega^{i+1}) = a_{i+1}$. So $A(\omega X)$ evaluated at $X = \omega^i$ gives the *next* value.

This lets us express "next step" constraints as polynomial identities:

- $C_1(X) = A(\omega X) - B(X)$: "next $a$" minus "current $b$" (should be zero)
- $C_2(X) = B(\omega X) - A(X) - B(X)$: "next $b$" minus "current $a$ + current $b$" (should be zero)
- $C_{B1}(X) = A(X) - 1$, vanishing at $X = 1$
- $C_{B2}(X) = B(X) - 1$, vanishing at $X = 1$
- $C_{B3}(X) = B(X) - 13$, vanishing at $X = \omega^5$

**Quotients:** Each constraint polynomial is divided by the appropriate vanishing polynomial. The transition constraints must hold at steps 0-4, so they're divided by $Z_5(X) = (X^6 - 1)/(X - \omega^5)$.

**Composition:** With random challenges $\alpha_1, \ldots, \alpha_5$:
$$\text{Comp}(X) = \alpha_1 \frac{C_1(X)}{Z_5(X)} + \alpha_2 \frac{C_2(X)}{Z_5(X)} + \alpha_3 \frac{C_{B1}(X)}{X-1} + \ldots$$

If the trace is valid (and it is) this composition is a polynomial of degree roughly $\deg(A) + \deg(B) - 5 \approx 5$. FRI proves this.

**What the verifier actually computes.** Suppose the verifier queries at $x = \omega^{10}$ (some point in $D$ outside $H$). The prover opens $A(\omega^{10}) = 17$ and $B(\omega^{10}) = 42$ (hypothetical values from the LDE). The verifier now locally checks:

1. Compute transition constraint values:
   - $C_1(\omega^{10}) = A(\omega^{11}) - B(\omega^{10})$, but wait, the verifier needs $A(\omega^{11})$ too!

This reveals an important detail: queries come in *pairs* (or larger groups). To check $C_1(x) = A(\omega x) - B(x)$, the verifier needs both $A(\omega x)$ and $B(x)$. So the prover opens trace values at $x$ *and* $\omega x$ together.

2. With both openings, the verifier computes each constraint polynomial at $x$, divides by the vanishing polynomial evaluated at $x$, applies the $\alpha$ weights, and sums to get $\text{Comp}(x)$.

3. Compare to the opened composition value. If they match at all query points, accept.

The verifier never sees the full trace, just $k$ random openings (perhaps 45 pairs for 128-bit security). But those openings, combined with the FRI proof, suffice to guarantee the entire computation was correct.

**What FRI checks look like.** The composition polynomial $\text{Comp}(X)$ has degree roughly 5 (from our 6-step trace). The prover commits to $\text{Comp}$ evaluated over the LDE domain $D$ (say, 48 points with blowup factor 8). FRI proves this committed function is close to a degree-5 polynomial.

FRI works by folding. The verifier sends a random $\beta$. The prover constructs:
$$\text{Comp}^{(1)}(Y) = \frac{\text{Comp}(Y) + \text{Comp}(-Y)}{2} + \beta \cdot \frac{\text{Comp}(Y) - \text{Comp}(-Y)}{2Y}$$

This halves the degree and domain size. For our degree-5 polynomial over 48 points, after one fold we get a degree-2 polynomial over 24 points. Another fold: degree-1 over 12 points. One more: a constant over 6 points. The prover sends this final constant directly.

At each fold, the verifier spot-checks consistency. Pick a random $y \in D$. The prover opens $\text{Comp}(y)$ and $\text{Comp}(-y)$. The verifier computes what $\text{Comp}^{(1)}(y^2)$ should be from these values, then checks it matches the next layer's commitment. This continues down the FRI layers.

For our tiny example: 3 folding rounds, ~45 queries per round, checking that each layer is consistent with the previous. If the original wasn't low-degree, the folded versions won't be consistent: the prover would need to commit to polynomials that don't match the folding relation, and random queries will catch this.

**Query overlap.** The same query points serve both purposes. When the verifier queries at $y$, the prover opens:

- Trace values $A(y), B(y), A(\omega y), B(\omega y)$: for the AIR consistency check
- Composition value $\text{Comp}(y)$ and $\text{Comp}(-y)$: for the first FRI fold

The verifier uses the trace openings to locally recompute $\text{Comp}(y)$, confirms it matches the opened value, and simultaneously uses $\text{Comp}(y), \text{Comp}(-y)$ to verify the fold. One query, two checks. The total query count is determined by the security requirement (each query gives ~$\log_2(\text{blowup})$ bits of security), and those queries are reused across AIR and FRI.


## The Trust and Size Trade-off

STARKs achieve transparency at a cost: proof size.

| Property | Groth16 | PLONK (KZG) | STARKs |
|----------|---------|-------------|--------|
| Trusted setup | Per-circuit | Universal | **None** |
| Proof size | **128 bytes** | ~500 bytes | **20-100 KB** |
| Verification | **O(1)** | O(1) | O(polylog $n$) |
| Post-quantum | No | No | **Yes** |
| Assumptions | Pairing-based | q-SDH | **Hash function** |

The gap is stark: two orders of magnitude in proof size, from hundreds of bytes to tens of kilobytes. For on-chain verification, where every byte costs gas, this matters enormously. A Groth16 proof costs perhaps 200K gas to verify on Ethereum. A raw STARK proof would cost millions.

But the size gap has motivated clever engineering. STARK proofs can be *wrapped* in SNARKs: use a STARK to prove the bulk of the computation (transparently, with the state machine model's natural fit for VMs), then use a Groth16 proof to attest "I verified a valid STARK proof." The SNARK verification circuit is fixed-size and small. The on-chain cost is the cost of verifying Groth16, regardless of the original computation's size.

This hybrid architecture, STARK for proving and SNARK for on-chain verification, is deployed in production systems: StarkNet, zkSync, Polygon zkEVM. The bulk of the security relies on hash functions. Only the final compression step uses pairings, and that step verifies a fixed, auditable circuit.

## The State Machine Advantage

For certain computations, the state machine model isn't just equivalent to circuits; it's strictly better.

Consider a virtual machine executing arbitrary programs. In the circuit model, you'd need a different circuit for each program. In the state machine model, the transition constraints encode the VM's instruction set once. The trace varies with the program; the constraints don't. Proving "this VM executed this program correctly" requires the same constraint system for all programs.

This is the architecture of **zkVMs**: zero-knowledge virtual machines that prove correct execution of arbitrary code. The VM's state includes program counter, registers, memory, and stack. The transition constraints encode fetch-decode-execute. Given any program, the prover generates an execution trace and proves it satisfies the constraints.

In practice, zkVMs combine two mechanisms: an **execution trace** (state evolution over time) and **lookup arguments** (Chapter 14) to verify that each instruction's behavior matches a precomputed table. The trace captures *what happened*; lookups verify *each step was valid*. Different zkVMs use different proof backends: Cairo and RISC-Zero use AIR constraints over the trace, while Jolt uses sum-check and Lasso lookups without AIR. The architectural insight (uniform constraints for all programs, with lookups for instruction semantics) is shared across both approaches.

The STARK model, with its uniform constraints across timesteps, its trace-based witness representation, and its hash-based commitments, is natural for this application. The circuit model would require "unrolling" the VM for a fixed number of steps, losing generality. The state machine model handles arbitrary-length execution with fixed constraint complexity.


## Circle STARKs and Small-Field Proving

Traditional STARKs require a multiplicative subgroup of size $2^k$ for FFT. This constraint dictates field choice: primes $p$ where $p - 1$ is divisible by a large power of 2. Fields like Goldilocks ($2^{64} - 2^{32} + 1$) and BabyBear ($2^{31} - 2^{27} + 1$) are carefully constructed to meet this requirement.

**Circle STARKs** remove this constraint by working over a different algebraic structure: the circle group.

### The Circle Group

Consider a prime $p$ and the set of points $(x, y)$ satisfying $x^2 + y^2 = 1$ over $\mathbb{F}_p$. This is an algebraic curve, specifically a "circle" over a finite field.

For Mersenne primes like $p = 2^{31} - 1$, the circle group has particularly nice structure:

- The group has order $p + 1 = 2^{31}$, a perfect power of 2
- This enables FFT-like algorithms directly, without the $(p-1)$ divisibility constraint
- Mersenne primes have extremely fast modular arithmetic (reduction is just addition and shift)

The group operation on the circle is defined via the "complex multiplication" formula:
$$(x_1, y_1) \cdot (x_2, y_2) = (x_1 x_2 - y_1 y_2, x_1 y_2 + x_2 y_1)$$

This is the standard multiplication formula for complex numbers $z = x + iy$ restricted to the unit circle. Over $\mathbb{F}_p$, it's well-defined and creates a cyclic group.

### The M31 Advantage

The Mersenne prime $M_{31} = 2^{31} - 1$ deserves special attention. Its arithmetic is uniquely fast:

**Reduction by addition.** For any product $a \cdot b < 2^{62}$, split the result into low and high 31-bit parts: $ab = \text{lo} + \text{hi} \cdot 2^{31}$. Then $ab \equiv \text{lo} + \text{hi} \pmod{M_{31}}$, because $2^{31} \equiv 1 \pmod{M_{31}}$. Modular reduction becomes a single addition plus a conditional subtraction, with no division or extended multiplication.

**32-bit native operations.** Field elements fit in a single 32-bit word. CPUs handle 32-bit arithmetic natively; SIMD instructions process 4-8 elements per cycle on modern hardware. Compare to 64-bit Goldilocks (needs 64-bit multiplies, harder to vectorize) or 254-bit BN254 (requires multi-precision arithmetic, ~10× slower per operation).

**The speedup is substantial.** StarkWare's Stwo prover using M31 Circle STARKs achieves approximately 100× faster hash evaluations compared to their previous Stone prover over larger fields. The combination of faster field arithmetic and better vectorization compounds multiplicatively.

### Why This Matters

**Smaller fields, faster arithmetic.** Mersenne-31 has 31-bit elements instead of 64-bit (Goldilocks) or 254-bit (BN254). Each field operation is faster. Vectorization (SIMD) handles more elements per instruction.

**Perfect power-of-2 domains.** The domain size is $2^{31}$, with no wasted bits or awkward padding. Trace lengths of $2^{20}$ or $2^{25}$ divide evenly.

**Same security model.** Circle STARKs still rely only on hash functions. The algebraic curve structure is used for FFTs, not for cryptographic assumptions.

### The Trade-off

Circle STARKs require adapting the polynomial machinery:

- Polynomials are defined over the circle group, not a multiplicative subgroup
- FRI folding uses the circle structure
- Some constraint types require reformulation

The implementation complexity is higher. But for systems targeting maximum prover speed, particularly zkVMs where prover time dominates, Circle STARKs offer a path to significant performance improvements.

### The Broader Lesson

Circle STARKs exemplify a general principle: *match the algebraic structure to hardware capabilities*. Traditional STARKs chose fields for mathematical convenience (large primes with smooth multiplicative order). Circle STARKs choose fields for computational efficiency (Mersenne primes with fast reduction), then build the necessary mathematical structure (the circle group) around that choice.

This same principle appears in Binius (Chapter 25), which uses binary tower fields where addition is XOR, a single CPU instruction. The trend is clear: as proof systems mature, field choice increasingly reflects hardware realities rather than purely mathematical aesthetics.

### Current Deployment

StarkWare's Stwo prover implements Circle STARKs over Mersenne-31. Polygon's research explores similar directions. As of 2025, Circle STARKs are transitioning from research to production, with benchmarks showing ~100× speedups over traditional STARK provers for hash-heavy workloads.


## Key Takeaways

1. **STARKs eliminate trusted setup** by building on hash functions rather than pairings. Merkle trees provide binding commitments; FRI proves low-degree properties.

2. **The state machine model** represents computation as state evolution over time. Transition constraints describe one step; the same constraints apply uniformly across all timesteps.

3. **The execution trace** is the witness: a matrix of register values over timesteps. Columns interpolate to trace polynomials over a root-of-unity domain $H$.

4. **The $\omega X$ trick encodes "next step."** Since $P(\omega^i) = p_i$, evaluating $P(\omega \cdot \omega^i) = P(\omega^{i+1}) = p_{i+1}$. Transition constraints like $P(\omega X) - Q(X) = 0$ relate consecutive rows algebraically.

5. **Quotient polynomials** encode constraint satisfaction. $C(X)/Z_H(X)$ is a polynomial iff $C$ vanishes on $H$, iff the constraint holds at every step.

6. **The composition polynomial** combines all quotients via random $\alpha$-weights (Fiat-Shamir derived). Low-degree composition implies all constraints satisfied.

7. **Low-degree extension** amplifies errors. Evaluating trace polynomials over a larger domain $D \supset H$ spreads any constraint violation across most of $D$.

8. **The AIR-FRI link.** The verifier opens trace values at query points, locally recomputes the composition, and checks it matches the committed value. Same queries feed into FRI consistency checks: one query, two purposes.

9. **zkVMs use traces plus lookups.** AIR-based systems (Cairo, RISC-Zero) verify trace evolution; sum-check systems (Jolt) use Lasso lookups. Both combine execution traces with lookup tables for instruction semantics.

10. **The STARK trade-off**: Post-quantum security and transparency (no trusted setup) at the cost of larger proofs (tens of kilobytes versus hundreds of bytes). Hybrid STARK+SNARK architectures compress for on-chain verification.




\newpage

# Chapter 16: Sigma-Protocols: The Simplest Zero-Knowledge Proofs

In 1989, a Belgian cryptographer named Jean-Jacques Quisquater faced an unusual challenge: explaining zero-knowledge proofs to his children.

The mathematics was forbidding. Goldwasser, Micali, and Rackoff had formalized the concept four years earlier, but their definitions involved Turing machines, polynomial-time simulators, and computational indistinguishability. Quisquater wanted something a six-year-old could grasp.

So he invented a cave.

> **The Children's Story**
>
> In Quisquater's tale, Peggy (the Prover) wants to prove to Victor (the Verifier) that she knows the magic word to open a door deep inside a cave. The cave splits into two paths (Left and Right) that reconnect at the magic door.
>
> Peggy enters the cave and takes a random path while Victor waits outside. Victor then walks to the fork and shouts: "Come out the Left path!"
>
> If Peggy knows the magic word, she can always comply. If she originally went Left, she walks out. If she went Right, she opens the door with the magic word and exits through the Left. Either way, Victor sees her emerge from the Left.
>
> If Peggy *doesn't* know the word, she's trapped. Half the time, Victor shouts for the path she's already on (she succeeds). Half the time, he shouts for the other side (she fails, stuck behind a locked door).
>
> They repeat this 20 times. A faker has a $(1/2)^{20}$ ≈ one-in-a-million chance of consistently appearing from the correct side. But someone who knows the word succeeds every time.
>
> This story, published as "How to Explain Zero-Knowledge Protocols to Your Children," captures the essence of what we now call a $\Sigma$-protocol: **Commitment** (entering the cave), **Challenge** (Victor shouting), **Response** (appearing from the correct side). Almost all modern cryptography, from your credit card chip to your blockchain wallet, is a mathematical version of this cave.

The paper became a classic. The cave analogy appears in nearly every introductory cryptography course. What makes it so powerful is that it captures the *structure* of zero-knowledge: the prover commits to a position before knowing the challenge, then demonstrates knowledge by responding correctly.

This chapter develops the mathematics behind the cave. A prover commits to something random. A verifier challenges with something random. The prover responds with something that combines both randomnesses with their secret. The verifier checks a simple algebraic equation. If it holds, accept; if not, reject.

This is a $\Sigma$-protocol. The name comes from the shape of the message flow: three arrows forming the Greek letter $\Sigma$ when drawn between prover and verifier. The structure is so fundamental that it appears everywhere cryptography touches authentication: digital signatures, identification schemes, credential systems, and as building blocks within the complex SNARKs we've studied.

Why study something so simple after the machinery of Groth16 and STARKs?

Because $\Sigma$-protocols crystallize the *essential* ideas of zero-knowledge. The simulator that we'll construct, picking the response first then computing what the commitment "must have been," is the archetype of all simulation arguments. The special soundness property (that two accepting transcripts with different challenges allow witness extraction) is the template for proofs of knowledge everywhere. And the Fiat-Shamir transform, which converts interaction into non-interaction, was developed precisely for $\Sigma$-protocols.

Understand $\Sigma$-protocols, and the zero-knowledge property itself becomes clear. This chapter prepares the ground for Chapter 17, where we formalize what "zero-knowledge" means. Here, we see it in its simplest form.

## The Discrete Logarithm Problem

We return to familiar ground. Chapter 6 introduced the discrete logarithm problem as the foundation for Pedersen commitments. Now it serves a different purpose: enabling proofs of knowledge.

The setting is a cyclic group $\mathbb{G}$ of prime order $q$ with generator $g$. Every element $h \in \mathbb{G}$ can be written as $h = g^w$ for some $w \in \mathbb{Z}_q$. This $w$ is the *discrete logarithm* of $h$ with respect to $g$. Computing $w$ from $h$ is hard; computing $h$ from $w$ is easy. This asymmetry, the one-wayness that made Pedersen commitments binding, now enables something new.

The prover *knows* $w$. The verifier sees $h$ but cannot compute $w$ directly. The prover wants to convince the verifier that they know $w$ without revealing what $w$ is.

The naive approach fails immediately. If the prover just sends $w$, the verifier can check $g^w = h$, but the secret is exposed. If the prover sends nothing, the verifier has no basis for belief. There seems to be no middle ground.

Interactive proofs create that middle ground.

## Schnorr's Protocol

Claus Schnorr discovered the canonical solution in 1989. The protocol is three messages, two exponentiations for the prover, two exponentiations for the verifier. It is as close to optimal as plausible.

**Public information:** Group $\mathbb{G}$, generator $g$, target element $h$.

**Private information (prover only):** Witness $w$ such that $h = g^w$.

**The protocol:**

1. **Commitment.** The prover samples a random $r \leftarrow \mathbb{Z}_q$ and computes $a = g^r$. The prover sends $a$ to the verifier.

2. **Challenge.** The verifier samples a random $e \leftarrow \mathbb{Z}_q$ and sends $e$ to the prover.

3. **Response.** The prover computes $z = r + w \cdot e \mod q$ and sends $z$ to the verifier.

4. **Verification.** The verifier checks whether $g^z = a \cdot h^e$. Accept if yes, reject otherwise.


That's the entire protocol. Let's understand why it works.

> **The Equation of a Line**
>
> Schnorr's protocol is secretly proving you know the equation of a line. In $z = r + w \cdot e$, think of $w$ as the slope and $r$ as the y-intercept. The prover commits to the intercept ($r$, hidden as $a = g^r$). The verifier picks an x-coordinate ($e$). The prover reveals the y-coordinate ($z$). One point on a line doesn't reveal the slope, but two points would. That's why the protocol must be run once per challenge: a single $(e, z)$ pair is consistent with infinitely many slopes, but two pairs with the same intercept uniquely determine $w$.

**Completeness.** An honest prover with the correct $w$ always passes verification:
$$g^z = g^{r + we} = g^r \cdot g^{we} = g^r \cdot (g^w)^e = a \cdot h^e$$

The algebra is straightforward. The commitment $a = g^r$ hides $r$; the response $z = r + we$ reveals a linear combination of $r$ and $w$; but one equation in two unknowns doesn't determine either.

**Soundness.** A prover who doesn't know $w$ can cheat only by guessing the challenge $e$ before committing. Once they send $a$, they're locked in. For a random $e$, there's exactly one $z$ that satisfies the verification equation (namely $z = r + we$). A cheating prover who doesn't know $w$ cannot compute this $z$.

More precisely: suppose a cheater could answer two different challenges $e_1$ and $e_2$ for the same commitment $a$. Then we'd have:
$$g^{z_1} = a \cdot h^{e_1} \quad \text{and} \quad g^{z_2} = a \cdot h^{e_2}$$

Dividing these equations:
$$g^{z_1 - z_2} = h^{e_1 - e_2}$$

Taking discrete logarithms (which the extractor can do symbolically, as both exponents are known):
$$w = \frac{z_1 - z_2}{e_1 - e_2} \mod q$$

A cheater who could answer two challenges *must* know $w$. This is **special soundness**: two accepting transcripts with different challenges allow extracting the witness.

> **The Rewinding Lemma**
>
> How do we get two transcripts with the same commitment $a$ but different challenges? In real life, we cannot. The prover sends $a$ only once, receives one challenge, and responds.
>
> But in a thought experiment, we can *rewind time*. We let the prover send $a$, we send challenge $e_1$, and receive response $z_1$. Then we press "rewind," return to the moment after they sent $a$, and send a *different* challenge $e_2$. If the prover can answer both, we solve the system of equations to extract $w$.
>
> This "rewinding" argument is the mathematical foundation of proofs of knowledge. It's why $\Sigma$-protocols prove you *know* something, not merely that something exists. An extractor with rewind powers could pry the secret from any successful prover.

**Zero-knowledge (honest verifier).** Here is where things become subtle. Consider a simulator that doesn't know $w$ but wants to produce a valid-looking transcript $(a, e, z)$. The simulator proceeds *backwards*:

1. Sample $e \leftarrow \mathbb{Z}_q$ (the challenge first!)
2. Sample $z \leftarrow \mathbb{Z}_q$ (the response, uniform and independent)
3. Compute $a = g^z \cdot h^{-e}$ (the commitment that *makes* the equation hold)

> **The Simulator's Time Machine**
>
> In real execution, events unfold: Commitment → Challenge → Response. The simulator cheats time. It picks the answer first ($z$), invents a question that fits ($e$), then back-calculates what the commitment "must have been" ($a = g^z h^{-e}$). This temporal reversal is invisible in the final transcript. Anyone looking at $(a, e, z)$ cannot tell whether it was produced forward (by someone who knows $w$) or backward (by someone who cheated time). This is the heart of zero-knowledge: if a transcript can be faked without the secret, then having the secret cannot be what makes the transcript convincing. The transcript itself carries no information about $w$.

Check: $g^z = a \cdot h^e = g^z h^{-e} \cdot h^e = g^z$.

The transcript $(a, e, z)$ is valid. And its distribution is identical to a real transcript:

- In a real transcript: $e$ is uniform (verifier's randomness), $z = r + we$ is uniform (because $r$ is uniform), and $a = g^r$ is determined.
- In a simulated transcript: $e$ is uniform (simulator's choice), $z$ is uniform (simulator's choice), and $a = g^z h^{-e}$ is determined.

Both distributions have $e$ and $z$ uniform and independent, with $a$ determined by the verification equation. They are identical.

This is **honest-verifier zero-knowledge (HVZK)**: if the verifier samples $e$ honestly (uniformly at random), the transcript reveals nothing about $w$ that the verifier couldn't have generated alone.



## A Concrete Computation

Let's trace through Schnorr's protocol with actual numbers. Working in a small group makes the arithmetic visible.

**Setup.** Take the multiplicative group $\mathbb{Z}_{11}^* = \{1, 2, 3, \ldots, 10\}$, which has order 10. Let $g = 2$ (a generator).

**Secret.** The prover knows $w = 6$. The public value is:
$$h = g^w = 2^6 = 64 \equiv 9 \pmod{11}$$

**Round 1 (Commitment).** The prover samples $r = 4$ and computes:
$$a = g^r = 2^4 = 16 \equiv 5 \pmod{11}$$
The prover sends $a = 5$.

**Round 2 (Challenge).** The verifier samples $e = 7$ and sends it.

**Round 3 (Response).** The prover computes:
$$z = r + w \cdot e = 4 + 6 \cdot 7 = 4 + 42 = 46 \equiv 6 \pmod{10}$$
(Note: we reduce modulo 10, the group order, not modulo 11.)
The prover sends $z = 6$.

**Verification.** The verifier checks $g^z = a \cdot h^e$:

- Left side: $g^z = 2^6 = 64 \equiv 9 \pmod{11}$
- Right side: $a \cdot h^e = 5 \cdot 9^7 \pmod{11}$

To compute $9^7 \pmod{11}$: Note $9 \equiv -2 \pmod{11}$, so $9^7 = (-2)^7 = -128 \equiv -128 + 132 = 4 \pmod{11}$.

Thus $a \cdot h^e = 5 \cdot 4 = 20 \equiv 9 \pmod{11}$.

Both sides equal 9. The proof verifies.



## Why the Order Matters: Commitment Before Challenge

The protocol's security rests entirely on the *order* of messages. The prover commits to $a$ before seeing $e$. This temporal ordering is crucial.

Consider what happens if the order is reversed. Suppose the verifier sends $e$ first, then the prover responds with $(a, z)$. A cheating prover, without knowing $w$, could:

1. Receive $e$
2. Choose any $z$
3. Compute $a = g^z h^{-e}$ (which satisfies the verification equation)
4. Send $(a, z)$

This always passes verification! The protocol would have no soundness at all.

Commitment before challenge forces the prover to "bet" on a strategy before knowing what will be tested. A prover without the witness bets blind; a prover with the witness can always respond correctly.

This is the essence of interactive proof security: randomness forces the prover's hand.

## Pedersen Commitments and $\Sigma$-Protocols

Chapter 6 introduced Pedersen commitments: $C = g^m h^r$ commits to message $m$ with blinding factor $r$, where $g, h$ are generators with unknown discrete log relation. Now we complete the picture: $\Sigma$-protocols let you *prove things* about committed values.

The connection runs deeper than mere compatibility. Schnorr's protocol and Pedersen commitments are algebraically the same construction. In Schnorr, the prover commits to $a = g^r$ and later reveals $z = r + we$ (a linear combination of the randomness and the secret). In Pedersen, the committer computes $C = g^m h^r$ (a linear combination of two generators weighted by the message and randomness). Both rely on the same hardness assumption; both achieve the same hiding property.

Recall from Chapter 6: a Pedersen commitment $C = g^m h^r$ is perfectly hiding (reveals nothing about $m$) and computationally binding (opening to a different value requires solving discrete log). The additive homomorphism $C_1 \cdot C_2 = g^{m_1+m_2} h^{r_1+r_2}$ lets us compute on committed values.

What Chapter 6 couldn't address: how does a prover demonstrate they *know* the opening $(m, r)$ without revealing it? This is precisely what $\Sigma$-protocols provide.


## Proving Knowledge of Openings

Schnorr's protocol proves knowledge of one discrete log: given $h = g^w$, prove you know $w$. Pedersen commitments involve *two* exponents: $C = g^m h^r$. To prove you know the opening $(m, r)$, we need the two-dimensional generalization.

**Statement.** Given a Pedersen commitment $C$, prove knowledge of $(m, r)$ such that $C = g^m h^r$.

The structure mirrors Schnorr exactly (commit, challenge, respond) but now with two secrets handled in parallel.

**The protocol:**

1. **Commitment.** Prover samples $d, s \leftarrow \mathbb{Z}_q$ and sends $a = g^d h^s$.

2. **Challenge.** Verifier sends random $e \leftarrow \mathbb{Z}_q$.

3. **Response.** Prover sends $z_1 = d + m \cdot e$ and $z_2 = s + r \cdot e$.

4. **Verification.** Check $g^{z_1} h^{z_2} = a \cdot C^e$.

This is just two Schnorr protocols glued together. One proves knowledge of the message part ($m$, committed via $g^m$), the other proves knowledge of the randomness part ($r$, committed via $h^r$). The same challenge $e$ binds them, ensuring the prover cannot mix-and-match unrelated values.

The analysis parallels Schnorr's protocol:

**Completeness.**
$$g^{z_1} h^{z_2} = g^{d + me} h^{s + re} = g^d h^s \cdot (g^m h^r)^e = a \cdot C^e \checkmark$$

**Special soundness.** Two transcripts with the same $a$ but different challenges $e_1, e_2$ yield:
$$g^{z_1^{(1)} - z_1^{(2)}} h^{z_2^{(1)} - z_2^{(2)}} = C^{e_1 - e_2}$$
From which both $m$ and $r$ can be extracted.

**Zero-knowledge (honest verifier).** Simulator picks $e, z_1, z_2$ uniformly, sets $a = g^{z_1} h^{z_2} \cdot C^{-e}$.

The prover demonstrates knowledge of the commitment opening without revealing what that opening is.



## Proving Relations on Committed Values

The homomorphic property enables something remarkable: proving statements about committed values without revealing them.

**Proving addition.** Given commitments $C_1, C_2, C_3$, prove that the committed values satisfy $m_1 + m_2 = m_3$.

Consider the product $C_1 \cdot C_2 \cdot C_3^{-1}$. Expanding the Pedersen structure:

$$C_1 \cdot C_2 \cdot C_3^{-1} = g^{m_1} h^{r_1} \cdot g^{m_2} h^{r_2} \cdot g^{-m_3} h^{-r_3} = g^{m_1 + m_2 - m_3} \cdot h^{r_1 + r_2 - r_3}$$

If the relation $m_1 + m_2 = m_3$ holds, the $g$ exponent vanishes:

$$C_1 \cdot C_2 \cdot C_3^{-1} = g^0 \cdot h^{r_1 + r_2 - r_3} = h^{r_1 + r_2 - r_3}$$

The combined commitment collapses to a pure power of $h$. To prove the relation holds, the prover demonstrates knowledge of this exponent $r_1 + r_2 - r_3$ (a single Schnorr proof with base $h$ and public element $C_1 \cdot C_2 \cdot C_3^{-1}$).

**Proving multiplication.** This is harder. Pedersen commitments aren't multiplicatively homomorphic. Given $C_1 = g^{m_1} h^{r_1}$, $C_2 = g^{m_2} h^{r_2}$, $C_3 = g^{m_3} h^{r_3}$, how do we prove $m_1 \cdot m_2 = m_3$?

The key insight is to change bases. Observe that:
$$g^{m_3} = g^{m_1 \cdot m_2} = (g^{m_1})^{m_2}$$

If $C_3 = g^{m_1 m_2} h^{r_3}$, then $C_3$ can also be viewed as:
$$C_3 = (g^{m_1})^{m_2} h^{r_3}$$

Now substitute $g^{m_1} = C_1 \cdot h^{-r_1}$:
$$C_3 = (C_1 \cdot h^{-r_1})^{m_2} h^{r_3} = C_1^{m_2} \cdot h^{r_3 - r_1 m_2}$$

This expresses $C_3$ as a "Pedersen commitment with base $C_1$" to the value $m_2$ with blinding factor $r_3 - r_1 m_2$.

The prover runs three parallel $\Sigma$-protocols:

1. Prove knowledge of $(m_1, r_1)$ opening $C_1$ (standard Pedersen opening)
2. Prove knowledge of $(m_2, r_2)$ opening $C_2$ (standard Pedersen opening)
3. Prove knowledge of $(m_2, r_3 - r_1 m_2)$ opening $C_3$ with respect to bases $(C_1, h)$

The third proof *links* to the second because the same $m_2$ appears. This linking requires careful protocol design, but the core technique is $\Sigma$-protocol composition with shared secrets.



## Fiat-Shamir: From Interaction to Non-Interaction

Interactive proofs are impractical for many applications. A signature scheme cannot require real-time communication with every verifier. A blockchain proof must be verifiable by anyone, at any time, without the prover present.

The **Fiat-Shamir transform** removes interaction. The idea is elegant: replace the verifier's random challenge with a hash of the transcript.

In Schnorr's protocol:

1. Prover computes $a = g^r$
2. Instead of waiting for verifier's $e$, prover computes $e = H(a)$ (or $H(g, h, a)$ for domain separation)
3. Prover computes $z = r + we$
4. Proof is $(a, z)$

Verification:

1. Recompute $e = H(a)$
2. Check $g^z = a \cdot h^e$

The transform works because $H$ is modeled as a **random oracle**: a function that returns uniformly random output for each new input. The prover cannot predict $H(a)$ before choosing $a$. Once $a$ is fixed, the hash determines $e$ deterministically. The prover faces a random challenge, just as in the interactive version.

In practice, $H$ is a cryptographic hash function like SHA-256. The random oracle model is an idealization (hash functions aren't truly random functions) but the heuristic is empirically robust for well-designed protocols.

**Schnorr signatures** are the direct application. Given secret key $w$ and public key $h = g^w$:

- **Sign message $M$:** Compute $a = g^r$, $e = H(h, a, M)$, $z = r + we$. Signature is $(a, z)$.
- **Verify:** Check $g^z = a \cdot h^e$ where $e = H(h, a, M)$.

This is the foundation of EdDSA (Ed25519), now standard in TLS, SSH, and cryptocurrency systems. Bitcoin adopted Schnorr signatures in the 2021 Taproot upgrade.

**Why Schnorr beats ECDSA.** The equation $z = r + we$ is *linear*. This linearity enables:

- **Batch verification**: Check many signatures faster than individually by taking random linear combinations (Schwartz-Zippel ensures invalid signatures can't cancel)
- **Native aggregation**: Multiple signers can combine signatures into one. MuSig2 produces a single 64-byte signature for $n$ parties that verifies against an aggregate public key
- **ZK-friendliness**: No modular inversions (unlike ECDSA's $s = k^{-1}(H(m) + rx)$), so Schnorr verification is cheap inside circuits

Compare to ECDSA: the $k^{-1}$ term makes the equation non-linear. You cannot simply add ECDSA signatures; the inverses don't combine. This algebraic accident kept Bitcoin on ECDSA for a decade.



## Composition: AND and OR

$\Sigma$-protocols compose cleanly, enabling proofs of complex statements from simple building blocks.

**AND composition.** To prove "I know $w_1$ such that $h_1 = g^{w_1}$ AND $w_2$ such that $h_2 = g^{w_2}$":

1. Run both protocols in parallel with independent commitments
2. Use the same challenge $e$ for both
3. Check both verification equations

If the prover knows both witnesses, they can respond to any challenge. If they lack either witness, they can't respond correctly.

**OR composition.** To prove "I know $w_1$ OR $w_2$" (without revealing which):

> **The Card Trick Analogy**
>
> Imagine a magician holding two decks of cards. They claim: "I know the order of Deck A OR the order of Deck B." You shuffle one deck and ask them to name the top card.
>
> If the magician knows that deck's order, they answer instantly. If they don't, they use sleight of hand: they "force" the right card to the top, making it look like they predicted it all along.
>
> In an OR-proof, the prover plays the magician. For the secret they know, they answer honestly. For the secret they don't know, they use the Simulator (the "sleight of hand") to produce a transcript that looks legitimate. The verifier sees two correct answers and cannot tell which was genuine knowledge and which was mathematical magic.

1. For the witness you *don't* know, simulate a transcript $(a_i, e_i, z_i)$ (using the honest-verifier simulator from the zero-knowledge property)
2. For the witness you *do* know, commit honestly to $a_j$
3. When you receive the verifier's challenge $e$, set $e_j = e - e_i$
4. Respond honestly to $e_j$ using your witness

The verifier checks:

- Both verification equations hold
- $e_1 + e_2 = e$

**Concrete example.** Alice knows the discrete log of $h_1 = g^{w_1}$ but not $h_2$. She wants to prove she knows at least one of them.

1. **Simulate the unknown:** Alice picks $e_2 = 7$ and $z_2 = 13$ at random, then computes $a_2 = g^{z_2} h_2^{-e_2} = g^{13} h_2^{-7}$. This is a valid-looking transcript for $h_2$.

2. **Commit honestly for the known:** Alice picks $r_1 = 5$ and computes $a_1 = g^{r_1} = g^5$.

3. **Send commitments:** Alice sends $(a_1, a_2)$ to the verifier.

4. **Receive challenge:** The verifier sends $e = 19$.

5. **Split the challenge:** Alice sets $e_1 = e - e_2 = 19 - 7 = 12$. Now she must respond to challenge 12 for $h_1$.

6. **Respond honestly:** Alice computes $z_1 = r_1 + w_1 \cdot e_1 = 5 + w_1 \cdot 12$.

7. **Send responses:** Alice sends $(e_1, z_1, e_2, z_2) = (12, z_1, 7, 13)$.

The verifier checks $g^{z_1} = a_1 \cdot h_1^{e_1}$ and $g^{z_2} = a_2 \cdot h_2^{e_2}$, plus $e_1 + e_2 = 19$. Both equations hold. The verifier cannot tell which transcript was simulated; the simulated $(a_2, e_2, z_2)$ is statistically identical to an honest execution.

The prover can always succeed by simulating one protocol and honestly executing the other. The verifier cannot tell which is which; the simulated transcript is indistinguishable from a real one.

This is remarkable: you can prove you know one of two secrets without revealing which. Ring signatures, anonymous credentials, and many privacy-preserving constructions build on this technique.

## Connection to Larger Systems

$\Sigma$-protocols appear as components within the complex proof systems of earlier chapters.

**The inner product argument** (Chapter 9) is a recursive $\Sigma$-protocol. Each round (commit to cross-terms $L, R$; receive challenge $u$; fold the vectors) follows the three-move structure. The recursion terminates when the vectors shrink to single elements, yielding logarithmic proof size.

**Bulletproofs** generalize the IPA to prove range statements and circuit satisfiability. The construction is layered: Pedersen vector commitments at the base, IPA for compression, $\Sigma$-protocols for linking claims. The entire system inherits honest-verifier zero-knowledge from its $\Sigma$-protocol core.

**Polynomial commitment openings** in KZG can be viewed through this lens too. The pairing check $e(C - g^v, g) = e(\pi, g^\tau - g^z)$ proves that the committed polynomial evaluates correctly at $z$. It's not a three-move protocol per se, but it shares the algebraic structure: commitment (the polynomial commitment $C$), challenge (the evaluation point $z$), and verification equation (the pairing check).

Understanding $\Sigma$-protocols provides the vocabulary for understanding zero-knowledge more broadly. The simulator, the extractor, the honest-verifier assumption: these concepts appear in precisely the same form in systems a hundred times more complex.



## Elliptic Curve Notation

Modern implementations use elliptic curves, where the group operation is written additively rather than multiplicatively:

| Multiplicative | Additive |
|----------------|----------|
| $g^w$ | $w \cdot G$ |
| $g^r \cdot g^s = g^{r+s}$ | $r \cdot G + s \cdot G = (r+s) \cdot G$ |
| $h = g^w$ | $H = w \cdot G$ |

The Schnorr verification equation becomes:
$$z \cdot G = A + e \cdot H$$

The mathematics is identical. The notation change reflects the underlying group structure: elliptic curve groups are abelian, naturally written additively. Every $\Sigma$-protocol translates directly; only the symbols change.



## Key Takeaways

1. **Three messages suffice** for zero-knowledge proofs of knowledge. Commit → Challenge → Response. The temporal ordering (commitment before challenge) is essential for soundness.

2. **Special soundness** means two accepting transcripts with different challenges enable witness extraction. This makes $\Sigma$-protocols *proofs of knowledge*, not merely proofs of existence.

3. **Zero-knowledge via simulation**: pick the challenge and response first, compute what the commitment must have been. The simulated transcript is indistinguishable from a real one, proving the verifier learns nothing beyond the statement's truth.

4. **Schnorr's protocol** proves knowledge of a discrete logarithm: you know $w$ such that $h = g^w$. Verification: $g^z = a \cdot h^e$. It is the archetype.

5. **Proving Pedersen openings** extends Schnorr to two dimensions. To prove knowledge of $(m, r)$ such that $C = g^m h^r$, commit to both exponents and respond with linear combinations.

6. **Relations on committed values** reduce to simpler proofs. Addition: the product $C_1 \cdot C_2 \cdot C_3^{-1}$ collapses to $h^{r_1+r_2-r_3}$ when $m_1 + m_2 = m_3$, requiring only a single Schnorr proof. Multiplication requires base-changing tricks.

7. **Fiat-Shamir** removes interaction: hash the commitment to derive the challenge. This yields Schnorr signatures (linear, aggregatable, ZK-friendly) and non-interactive proofs.

8. **Composition** builds complex proofs from simple ones. AND runs protocols in parallel with a shared challenge. OR uses simulation for the unknown witness; the verifier cannot tell which branch was real.

9. **Connection to SNARKs**: The inner product argument (Bulletproofs), KZG opening proofs, and recursive protocols all inherit the three-move structure and simulation-based security of $\Sigma$-protocols.

10. **Minimal assumptions**: $\Sigma$-protocols require only the discrete logarithm assumption. No pairings, no trusted setup, no hash functions beyond Fiat-Shamir.




\newpage

# Chapter 17: The Zero-Knowledge Property

Imagine a child's puzzle book: *Where's Waldo?*, with its massive, crowded scenes hiding a single striped figure. You claim you found Waldo. Your friend doesn't believe you. You want to prove you found him without revealing his location (so your friend can still enjoy the puzzle).

How?

> **The Where's Waldo Proof**
>
> You take a large sheet of cardboard with a small hole cut in the middle. You place the puzzle page behind the cardboard, sliding it around until Waldo is visible through the hole. You invite your friend to look.
>
> They see Waldo. They are convinced you know where he is. But because the cardboard blocks the context (the trees, the crowd, the hot dog stands), they have no idea where on the page he is located. The surrounding scene, which would reveal the coordinates, is hidden.
>
> This is the essence of Zero Knowledge. You prove the statement ("I found Waldo") while hiding the witness ("He's at coordinates (342, 891)").

This analogy, invented by Moni Naor and adapted by cryptographers since, captures the paradox at the heart of zero-knowledge proofs. A proof, by its nature, is a demonstration: an argument that convinces by showing. The verifier sees the proof and becomes convinced. How can seeing suffice for conviction while simultaneously revealing nothing?

The answer lies in distinguishing *what* the verifier learns from *what* the verifier sees. The verifier sees a transcript: a sequence of messages exchanged with the prover. The verifier learns (ideally) one bit: the statement is true. The zero-knowledge property formalizes the claim that nothing more than this single bit leaks.

Consider the stakes. You hold a private key that controls valuable assets. You want to prove you possess this key (to authenticate to a service, to sign a transaction, to unlock a system) without exposing the key itself. A naive proof ("here is the key") achieves authentication but destroys privacy. A zero-knowledge proof achieves both: the verifier becomes certain you know the key, yet learns nothing that would help them compute it.

This chapter develops the formal definition of zero-knowledge and explores its subtleties. The definition turns on a beautiful thought experiment: what if the verifier could have generated the entire proof transcript by themselves, without any prover present? If so, the transcript cannot have leaked anything; there's nothing in it the verifier couldn't have produced alone.

## The Simulation Argument

Chapter 16 introduced the Schnorr protocol simulator. The idea was almost too simple: to produce a valid transcript $(a, e, z)$ without knowing the witness $w$, pick $e$ and $z$ first (both uniformly random), then compute $a = g^z h^{-e}$. The transcript satisfies the verification equation by construction, and its distribution matches a real transcript exactly.

This is the **simulation paradigm**: a proof system is zero-knowledge if a simulator (an efficient algorithm with no access to the witness) can produce transcripts indistinguishable from real protocol executions.

Why does simulation imply privacy? Suppose the verifier could extract some information $I$ about the witness from a real transcript. Consider the simulator's output. The simulator doesn't know the witness, so its transcript cannot possibly encode $I$. But the simulator's transcript is indistinguishable from the real one. If the verifier can extract $I$ from real transcripts, they should also extract $I$ from simulated ones; yet simulated transcripts don't contain $I$. Contradiction. Therefore, real transcripts don't leak $I$ either.

The logic is subtle: we prove that real transcripts leak nothing by showing they're indistinguishable from transcripts that *obviously* leak nothing (because the simulator never had the secret).

There is something strange here. The proof is convincing precisely because it could have been fabricated. The simulator (who knows nothing) produces output identical to the prover who knows everything. This indistinguishability is not a flaw to be patched; it is the definition of success. The guarantee of privacy *is* the guarantee that a fake would be undetectable.


## The Graph Non-Isomorphism Protocol

The Schnorr protocol is too simple to fully illustrate simulation; the simulator's trick (compute $a$ from $e, z$) might seem like algebraic coincidence. Let's examine a more intuitive example: the Graph Non-Isomorphism protocol from Chapter 1.

**The setting.** Two graphs $G_0$ and $G_1$ are claimed to be non-isomorphic: no relabeling of vertices makes them identical. There's no obvious short certificate for this claim. The negative claim seems to require checking all $n!$ possible relabelings.

**The protocol.** The verifier picks a secret bit $b \in \{0, 1\}$, applies a random permutation $\pi$ to $G_b$, and sends $H = \pi(G_b)$ to the prover. The prover's task: identify which graph $H$ came from. If the graphs are truly non-isomorphic, they have different structural invariants (triangle counts, eigenvalue spectra, degree distributions). An unbounded prover computes these invariants and determines $b$ with certainty. The prover sends back $b' = b$.

**What does the verifier see?** After a successful execution:

- The challenge $H$ that she generated herself
- The bit $b'$ that matches her secret $b$

But wait: $b$ was her own random choice. $H$ was her own computation. The prover's response $b' = b$ just echoes her own randomness back. The transcript $(H, b')$ contains nothing the verifier didn't already know.

**The simulator.** Given only the graphs $G_0, G_1$ (not the prover's ability to distinguish them):

1. Pick $b \leftarrow \{0, 1\}$ uniformly at random
2. Pick $\pi$ uniformly from permutations of the vertex set
3. Compute $H = \pi(G_b)$
4. Output the transcript $(H, b)$

This is exactly what an honest verifier would see in a real execution. The simulator "plays both roles," generating both the verifier's message and the prover's response, and produces an identical distribution.

**Perfect zero-knowledge.** The simulated and real distributions are not merely close; they're identical. This is **perfect zero-knowledge**: the statistical distance between real and simulated transcripts is exactly zero.

### From Graphs to Polynomials: The Same Simulation Pattern

The Graph Non-Isomorphism protocol might seem disconnected from the polynomial machinery we've been building. But the simulation pattern is identical.

In Schnorr's protocol (Chapter 16), the real prover commits to $a = g^r$, receives challenge $e$, and responds with $z = r + we$. The simulator reverses this: picks $e$ and $z$ first, then computes $a = g^z h^{-e}$.

In polynomial commitment protocols, the pattern is the same. Consider a prover who commits to a polynomial $p(X)$, then must open it at a verifier-chosen point $z$. The simulator picks the evaluation point $z$ and the claimed value $v$ first, then constructs a commitment that is consistent with these choices. The commitment "could have been" a commitment to any polynomial that evaluates to $v$ at $z$.

The key insight: simulation works because *one point doesn't determine a polynomial*. Just as one $(e, z)$ pair in Schnorr is consistent with infinitely many secrets $w$, one evaluation $(z, v)$ is consistent with infinitely many polynomials. The simulator exploits this freedom. The real prover is bound by their earlier commitment; the simulator is free to work backward from the challenge.

This is why FRI queries work at random points, why KZG requires the verifier to choose $z$ *after* the commitment, and why Fiat-Shamir hashes the commitment before deriving challenges. The temporal ordering (commit → challenge → respond) is what separates live proofs from simulated transcripts.

## Formal Definition

Let $(\mathcal{P}, \mathcal{V})$ be an interactive proof system for a language $\mathcal{L}$. On input $x \in \mathcal{L}$, the prover $\mathcal{P}$ holds a witness $w$; the verifier $\mathcal{V}$ sees only $x$.

**The verifier's view** consists of:

1. The statement $x$
2. The verifier's random coins $r$
3. All messages received from the prover

We write $\text{View}_{\mathcal{V}}(\mathcal{P}(w) \leftrightarrow \mathcal{V})(x)$ for this random variable.

**Definition (Zero-Knowledge).** The proof system is **zero-knowledge** if there exists a probabilistic polynomial-time algorithm $\mathcal{S}$ (the simulator) such that for all $x \in \mathcal{L}$:

$$\text{View}_{\mathcal{V}}(\mathcal{P}(w) \leftrightarrow \mathcal{V})(x) \approx \mathcal{S}(x)$$

The symbol $\approx$ denotes indistinguishability; its precise meaning yields three flavors.



## Three Flavors of Zero-Knowledge

**Perfect zero-knowledge (PZK).** The distributions are identical:
$$\text{View}_{\mathcal{V}} \equiv \mathcal{S}(x)$$

No adversary, even with unlimited computational power, can distinguish real from simulated transcripts. The two distributions have zero statistical distance.

This is the strongest notion. The Schnorr protocol (Chapter 16) achieves PZK against honest verifiers: the simulator's output $(a, e, z)$ has exactly the same distribution as a real transcript.

**Statistical zero-knowledge (SZK).** The distributions are statistically close:
$$\Delta(\text{View}_{\mathcal{V}}, \mathcal{S}(x)) \leq \text{negl}(\lambda)$$

The statistical distance is negligible in the security parameter $\lambda$. An unbounded adversary might distinguish the distributions, but only with probability $2^{-\Omega(\lambda)}$ (effectively never).

SZK allows for protocols where perfect simulation is impossible but the gap is cryptographically small. Many commitment-based protocols achieve SZK.

**Computational zero-knowledge (CZK).** No efficient algorithm can distinguish the distributions:
$$\text{View}_{\mathcal{V}} \stackrel{c}{\approx} \mathcal{S}(x)$$

The distributions might be statistically far apart, but every polynomial-time distinguisher's advantage is negligible. Security relies on computational hardness; an unbounded adversary could distinguish.

CZK is the weakest but most practical notion. Modern SNARKs typically achieve CZK. The simulator might use pseudorandom values where the real protocol uses true randomness; distinguishing requires breaking the underlying assumption.


## Honest Verifiers and Malicious Verifiers

The definition above assumes the verifier follows the protocol honestly. What if she doesn't?

**Honest-verifier zero-knowledge (HVZK).** The simulator produces indistinguishable output when the verifier $\mathcal{V}$ follows the protocol specification exactly; in particular, it samples challenges uniformly at random.

This is what Schnorr's protocol achieves. The simulator works because it knows the honest verifier will choose $e$ uniformly. If the verifier could choose $e$ adversarially, based on the prover's commitment $a$, the simulator's technique breaks.

**Malicious-verifier zero-knowledge.** The simulator must produce indistinguishable output against *any* efficient verifier strategy $\mathcal{V}^*$, including:

- Adversarial challenge selection
- Auxiliary information from other sources
- Arbitrary protocol deviations

Consider the Graph Non-Isomorphism protocol again. An honest verifier sends $H = \pi(G_b)$ for her secret $b$. But a malicious verifier could send some other graph $H'$ (perhaps one she suspects is isomorphic to $G_0$ but isn't sure). The all-powerful prover will correctly identify whether $H'$ matches $G_0$, $G_1$, or neither. The verifier learns something she couldn't efficiently compute herself!

The protocol is HVZK but not malicious-verifier ZK. The prover, dutifully answering whatever question is posed, inadvertently becomes an oracle for graph isomorphism.

**Closing the gap.** Transforming HVZK protocols into malicious-verifier ZK requires additional machinery:

- *Coin-flipping protocols* force the verifier to commit to her randomness before seeing the prover's messages. The verifier's challenges become unpredictable even to her.
- *Trapdoor commitments* let the simulator "equivocate": commit to one value, then open to another after seeing the verifier's behavior.
- *The Fiat-Shamir transform* eliminates interaction entirely. With no verifier messages, there's no room for malicious behavior. The simulator controls the random oracle and programs it as needed.

Non-interactive proofs (after Fiat-Shamir) largely dissolve the HVZK/malicious distinction. The "verifier" merely checks a static proof string.


## The Simulator's Superpower: Rewinding

How can a simulator, without the witness, produce valid-looking transcripts? The answer involves a capability the real prover lacks: **rewinding**.

In a real protocol execution, time moves forward. The prover commits to $a$, then receives challenge $e$, then computes response $z$. The commitment precedes the challenge. The prover cannot see $e$ before sending $a$.

The simulator isn't bound by temporal order. It produces a transcript (a static object) not a live interaction. It can:

1. Choose $e$ first (pretending to know the future)
2. Compute $z$ however convenient
3. Work backward to find $a$ consistent with both

This is precisely what the Schnorr simulator does: pick $e, z$ first, compute $a = g^z h^{-e}$. The transcript $(a, e, z)$ looks like a real interaction, but it was computed backward.

For more complex protocols, the simulator may need to "run" the verifier multiple times, recording responses to different challenges and picking the right one. This is **rewinding**: the simulator rewinds the verifier to an earlier state and tries again with different randomness.

Rewinding is a proof technique, not a real capability. It demonstrates that the transcript could have been generated without the witness. Real provers cannot rewind real verifiers; they face a single, forward-moving timeline. But the simulator's ability to rewind shows that the information content of the transcript is not tied to the witness.

## The Central Confusion

Students encountering zero-knowledge often stumble on this point: *if the simulator can produce valid transcripts without the witness, what stops a cheater from doing the same?*

> **The Green Screen Analogy**
>
> Think of a ZK proof as a video of someone walking on the moon.
>
> **Real Interaction**: The astronaut actually flew to the moon, filmed in real time.
>
> **Simulation**: A special effects artist used a green screen to create a video that looks identical to the moon landing.
>
> If the special effects are perfect (indistinguishable from reality), then watching the video *alone* proves nothing about whether the moon landing happened. The video itself contains zero knowledge about whether it's real.
>
> So why do we trust the astronaut? Because they're not making a movie offline; they're performing *live*. They can't use a green screen because they don't know what the lunar terrain (the challenge) will look like until the split second they land. The simulator has the luxury of post-production; the real prover faces live broadcast.

The answer is subtle but crucial.

A cheating prover and a simulator operate under different rules:

| Cheating Prover | Simulator |
|----------------|-----------|
| Interacts in real time | Produces a transcript offline |
| Commits before seeing challenge | Can choose challenge first |
| Cannot rewind the verifier | Can run the verifier many times |
| Must work for false statements | Only needs to work for true statements |

The cheating prover faces a live verifier who sends unpredictable challenges. The prover commits to $a$, then receives $e$, then must produce $z$. Without the witness, the prover cannot know in advance which $e$ will come. They must commit to a strategy that works for *all* (or most) possible challenges; by soundness, this is impossible for false statements.

The simulator faces a different task: produce a single transcript that *looks* like a real interaction. It can pick the challenge first, then reverse-engineer the commitment. This works precisely because the simulator knows the statement is true (simulation is only required for $x \in \mathcal{L}$).

**Soundness is about real interaction.** Zero-knowledge is about information content. The simulator's success shows the transcript contains no extractable information about the witness. It doesn't help a cheating prover because the cheater faces a different game: one where they can't rewind, can't choose challenges, and must work on false statements.


## The Limits of Zero-Knowledge

Perfect and statistical zero-knowledge seem strictly stronger than computational. Are they always preferable?

No. There are fundamental limits.

**Theorem (Fortnow, Aiello-Håstad).** Any language with a statistical zero-knowledge proof lies in $\text{AM} \cap \text{coAM}$.

The class $\text{AM}$ (Arthur-Merlin) is roughly IP with public coins. The class $\text{AM} \cap \text{coAM}$ is believed to be much smaller than NP. In particular, it likely contains no NP-complete problems.

**Implication.** If you want statistical zero-knowledge proofs for NP-complete problems, you're out of luck (assuming standard complexity-theoretic conjectures).

The way forward is to relax both soundness and zero-knowledge:

- **Computational soundness (arguments):** Security against cheating provers who are computationally bounded.
- **Computational zero-knowledge:** Security against distinguishers who are computationally bounded.

Modern SNARKs take both paths. They are *arguments* (computationally sound) with *computational zero-knowledge*. This combination enables practical ZK proofs for arbitrary computations, including NP-complete problems and beyond.

> **Witness Indistinguishability**
>
> Sometimes, full zero-knowledge is too expensive or impossible to achieve. A weaker but often sufficient property is **Witness Indistinguishability (WI)**. This guarantees that if there are multiple valid witnesses (e.g., two different private keys that both sign the same message, or two different paths through a maze), the verifier cannot tell which one the prover used.
>
> WI doesn't promise that the verifier learns *nothing*; it only promises they can't distinguish *which* witness was used. For many privacy applications (anonymous credentials, ring signatures), WI suffices and is easier to achieve than full ZK.

## Zero-Knowledge in the Wild: Sum-Check

Let's ground this in the core protocol of the book. The sum-check protocol proves:

$$H = \sum_{b \in \{0,1\}^n} g(b)$$

In each round, the prover sends a univariate polynomial $g_i(X_i)$, the restriction of $g$ to a partial evaluation. The verifier checks degree bounds and eventually evaluates $g$ at a random point.

**Is sum-check zero-knowledge?** Not inherently. The univariate polynomials $g_i$ reveal partial information about $g$. If $g$ encodes secret witness data, this information leaks.

For applications where $g$ is derived from public inputs (verifiable computation on public data), this leakage is harmless. For private-witness applications, we need modifications.

**Masking techniques** (Chapter 18) add zero-knowledge to sum-check:

- Add random low-degree polynomials that cancel in the sum
- Commit to intermediate values instead of revealing them
- Use randomization to hide the structure of $g$

The key insight: zero-knowledge is a *system-level* property, not a per-protocol property. We can compose non-ZK building blocks (sum-check, FRI, polynomial commitments) into ZK systems by carefully controlling what the verifier sees.


## Proofs of Knowledge

Zero-knowledge concerns what the verifier learns. A related but distinct property concerns what the prover demonstrates.

**Proof of existence:** "There exists $w$ such that $R(x, w) = 1$."

The prover demonstrates the statement is true (a witness exists) without necessarily revealing or even knowing the witness.

**Proof of knowledge:** "I know $w$ such that $R(x, w) = 1$."

The prover demonstrates not just existence but *possession*. This requires an additional property: **knowledge extraction**.

**Definition.** A proof system has knowledge extraction if there exists an efficient extractor $\mathcal{E}$ such that: whenever a (possibly cheating) prover $\mathcal{P}^*$ convinces the verifier, $\mathcal{E}^{\mathcal{P}^*}$ (with oracle access to $\mathcal{P}^*$) extracts a valid witness $w$.

The extractor typically works by rewinding. It runs the prover once, records the response to challenge $e_1$, rewinds, gives challenge $e_2$, and extracts the witness from the two transcripts. This is exactly what special soundness (Chapter 16) provides for $\Sigma$-protocols.

**Zero-knowledge proofs of knowledge** combine both properties. The prover demonstrates possession of a secret without revealing it. This is the foundation of digital signatures (prove you know the signing key), anonymous credentials (prove you possess a valid credential), and confidential transactions (prove you know the secret amounts that balance).



## Auxiliary Input

Composition complicates things. When a ZK proof is used as a subroutine in a larger protocol, the "verifier" in the subroutine may have learned information from earlier stages.

**The intuition:** Auxiliary input handles the case where the verifier already knows something about you. Maybe they know your IP address, or they've seen previous proofs you submitted, or they have partial information about your secret from another source. A secure ZK protocol must ensure that even with this extra context, the proof leaks nothing *new*.

**Definition (Auxiliary-Input ZK).** A protocol is auxiliary-input zero-knowledge if for every efficient verifier $\mathcal{V}^*$ with auxiliary input $z$:

$$\text{View}_{\mathcal{V}^*(z)}(\mathcal{P}(w) \leftrightarrow \mathcal{V}^*(z))(x) \approx \mathcal{S}(x, z)$$

The simulator receives the same auxiliary input $z$ as the verifier. The key requirement: whatever the verifier knew beforehand, the proof adds nothing to it.

This definition handles composed protocols. Even if the verifier has side information about the statement or witness, the proof reveals nothing new. The simulator, given the same side information, produces indistinguishable transcripts.

Auxiliary-input ZK is essential for security in complex systems where many proofs interleave.


## Key Takeaways

1. **Zero-knowledge** means existence of a simulator: an efficient algorithm that produces transcripts indistinguishable from real executions, without access to the witness.

2. **The simulation argument** shows that if real and simulated transcripts are indistinguishable, real transcripts leak nothing; they contain no information the verifier couldn't generate alone.

3. **Three flavors**: Perfect (identical distributions), Statistical (negligible statistical distance), Computational (no efficient distinguisher).

4. **HVZK vs. malicious-verifier ZK**: HVZK only protects against honest verifiers; malicious-verifier ZK protects against adversarial verifier strategies. Non-interactive proofs largely collapse this distinction.

5. **The simulator's superpower is rewinding**: choosing challenges before commitments, trying multiple paths. Real provers cannot rewind; this is why simulation doesn't break soundness.

6. **The central confusion resolved**: Simulators and cheating provers play different games. The simulator works offline on true statements; the cheating prover faces live interaction on false statements.

7. **Limits of SZK**: Statistical zero-knowledge proofs exist only for languages in AM ∩ coAM, likely not NP-complete problems. Computational ZK sidesteps this barrier.

8. **Proofs of knowledge** add extraction: the prover demonstrates possession, not just existence. Zero-knowledge proofs of knowledge enable proving you know a secret without revealing it.

9. **Sum-check isn't inherently ZK**: The intermediate polynomials leak information. Masking techniques (Chapter 18) restore privacy.

10. **Auxiliary-input ZK** handles composed protocols where the verifier has side information. The simulator receives the same auxiliary input and still produces indistinguishable transcripts.




\newpage

# Chapter 18: Making Proofs Zero-Knowledge

A proof convinces by revealing structure. The verifier sees patterns, checks relationships, follows chains of reasoning. Each step makes the conclusion more certain. This is the nature of proof: to show is to know.

Zero-knowledge inverts this. The proof convinces by *concealing* structure: by showing that patterns exist without showing what they are, that relationships hold without revealing the terms, that chains of reasoning connect without exposing the links. The verifier becomes certain of one bit (the statement is true) while learning nothing else.

This sounds impossible. It isn't, but it requires care.

> **The Retrofit Problem**
>
> Most proof systems were designed for a different era. The early interactive proofs of the 1980s and 1990s were built for one purpose: making verification cheap. Researchers like Goldwasser, Micali, Babai, and Lund asked how a weak verifier could check claims made by a powerful prover. Privacy was an afterthought, when it was a thought at all. The sum-check protocol, GKR, and the algebraic machinery underlying modern SNARKs all emerged from complexity theory, where the goal was efficient verification, not confidential computation. Only later, as these tools migrated from theory to practice, did privacy become essential. Blockchain applications, private credentials, and confidential transactions all demand that proofs reveal nothing beyond validity. So the field faced a retrofit problem: how do you take elegant machinery built for transparency and make it opaque?

We've defined zero-knowledge in Chapter 17. We've seen it in $\Sigma$-protocols. But proof systems aren't born zero-knowledge; they're made that way. Strip the blinding from Groth16 and you still have a valid SNARK: sound, succinct, verifiable. But the proof elements would leak information about the witness. The random values $r, s$ we saw in Chapter 12 exist precisely to prevent this. Similarly, PLONK without its blinding polynomials $(b_1 X + b_2) Z_H(X)$ would verify correctly but expose witness-dependent evaluations.

The same is true everywhere. Sum-check sends univariate polynomials derived from the witness (information leaks). GKR reveals layer values computed from the witness (information leaks). Raw STARKs expose trace polynomial evaluations (information leaks). Without deliberate masking, every proof system betrays its secrets.

This chapter develops the general theory behind what we already saw applied in Groth16 and PLONK. How do we take a working proof system, one designed for succinctness and soundness, and add the layer that makes it reveal nothing?

Two techniques have emerged as the workhorses for adding zero-knowledge:

**Commit-and-prove**: Encrypt everything under hiding commitments, then prove in zero-knowledge that the hidden values satisfy the required relations. This is the brute-force approach: powerful, general, but expensive.

**Masking polynomials**: Add carefully constructed random polynomials that hide the witness while preserving validity. This is the elegant approach: efficient when it applies, but requiring algebraic care.

Both achieve the same end through different means. Understanding when to use which, and how they interact with succinctness, is essential for designing practical ZK systems.

## The Leakage Problem

Let's be concrete about what leaks. Consider the sum-check protocol proving:

$$H = \sum_{b \in \{0,1\}^n} g(b)$$

The verifier doesn't know $g$ directly (that's the point). The polynomial $g$ encodes the witness: it's built from the prover's secret values. In a proper ZK protocol, the verifier would only learn $g(r)$ at a single random point $r$ at the end (via a commitment opening), not the polynomial itself. But sum-check requires the prover to send intermediate polynomials.

In round $i$, the prover sends a univariate polynomial representing the partial sum with variable $X_i$ free:

$$g_i(X_i) = \sum_{b_{i+1}, \ldots, b_n \in \{0,1\}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

This polynomial depends on $g$. Its coefficients encode information about the witness.

**A concrete leak.** Suppose $g$ encodes a computation with secret witness values $(w_1, w_2, w_3)$:

$$g(X_1, X_2) = w_1 X_1 + w_2 X_2 + w_3 X_1 X_2$$

The verifier doesn't know this polynomial; if they did, they'd already know the witness. They only know they're verifying a sum. But watch what happens during the protocol.

The first round polynomial is:
$$g_1(X_1) = g(X_1, 0) + g(X_1, 1) = w_1 X_1 + (w_1 X_1 + w_2 + w_3 X_1) = (2w_1 + w_3) X_1 + w_2$$

The prover sends this polynomial to the verifier. The constant term is exactly $w_2$. The coefficient of $X_1$ is $2w_1 + w_3$. The verifier learns linear combinations of the secrets directly from the protocol message.

**Why this matters.** The algebra might seem abstract, so consider what these witness values could represent. Suppose you're proving eligibility for a loan without revealing your finances. Your witness might encode: $w_1$ = your salary, $w_2$ = your social security number, $w_3$ = your total debt. The computation verifies that your debt-to-income ratio meets some threshold. But from that single round polynomial, the verifier learns your SSN directly (it's the constant term) and a linear combination of your salary and debt. They didn't need to learn any of this to verify your eligibility. The protocol leaked it anyway.

This isn't zero-knowledge. We need to hide these coefficients while still allowing verification.


## Technique 1: Commit-and-Prove

The commit-and-prove approach is conceptually simple: never send a value in the clear. Always send a commitment, then prove the committed values satisfy the required relations.

### The Paradigm

For any protocol that sends witness-dependent values:

1. **Replace values with commitments.** Instead of sending $v$, send $C(v) = g^v h^r$ (a Pedersen commitment with random blinding $r$).

2. **Prove relations in zero-knowledge.** For each algebraic relation the original protocol checks (e.g., "this value equals that value," "this is the product of those two"), run a $\Sigma$-protocol on the committed values.

The verifier never sees actual values. They see commitments (opaque group elements that reveal nothing about the committed data). The $\Sigma$-protocols convince them the data satisfies the required structure.

### Pedersen's Homomorphism as Leverage

Recall from Chapter 6 that Pedersen commitments are additively homomorphic:

$$C(a) \cdot C(b) = g^a h^{r_a} \cdot g^b h^{r_b} = g^{a+b} h^{r_a + r_b} = C(a+b)$$

This means **addition is free**. The verifier can check that committed values add correctly without any interaction:

- Given commitments $C(a)$, $C(b)$, $C(c)$
- Check whether $C(c) = C(a) \cdot C(b)$
- If so, the committed values satisfy $c = a + b$

No $\Sigma$-protocol needed. The algebraic structure of the commitment scheme does the work.

**Multiplication costs.** Checking $c = a \cdot b$ on committed values requires a $\Sigma$-protocol. The prover must convince the verifier that the committed values are multiplicatively related without revealing them. This takes three group elements and three field elements per multiplication gate.

### Applying to Circuits

Consider an arithmetic circuit with:

- Public inputs $x_1, \ldots, x_k$
- Private witness values $w_1, \ldots, w_n$
- Intermediate wires $z_1, \ldots, z_m$
- Addition and multiplication gates

**The commit-and-prove protocol:**

1. **Commitment phase.** The prover sends:

   - $C(w_i)$ for each witness value
   - $C(z_j)$ for each intermediate wire

2. **Relation-proving phase.** For each gate:

   - *Addition gate* $z_k = z_i + z_j$: Verifier checks $C(z_k) = C(z_i) \cdot C(z_j)$ (free)
   - *Multiplication gate* $z_k = z_i \cdot z_j$: Prover runs a $\Sigma$-protocol for committed multiplication

3. **Output check.** The output wire's commitment must match the public output. The prover opens $C(z_{\text{out}})$ or proves in ZK that it commits to the expected value.

**Complexity.** The proof size scales with the number of multiplication gates $M$:

- $M$ $\Sigma$-protocol transcripts, each ~3 group elements
- Verification requires $O(M)$ multi-exponentiations (one per $\Sigma$-protocol check)

This isn't succinct. A circuit with a million multiplications produces a proof with millions of group elements. But it achieves *perfect* zero-knowledge: the simulator can produce indistinguishable transcripts by simulating each $\Sigma$-protocol independently.

### Recovering Succinctness: Proof on a Proof

Here's the key insight that makes commit-and-prove practical for large computations.

We can't afford to run commit-and-prove on a circuit with $n$ gates. But what about a circuit with $\log n$ gates? That's affordable.

The trick: use an efficient interactive proof (GKR, sum-check) to reduce the verification of the big circuit to a small check, then apply commit-and-prove only to that small check.

**The construction:**

1. Run GKR on the original circuit $C$. This produces a transcript: prover messages, verifier challenges, and a final claim about a polynomial evaluation.

2. The GKR verifier is itself a small circuit $V_{\text{GKR}}$. Given the transcript, it outputs accept/reject. This circuit has size $O(\text{polylog}(|C|))$ (polylogarithmic in the original circuit).

3. Apply commit-and-prove to $V_{\text{GKR}}$. The prover commits to all transcript values (which include witness-derived quantities), then proves in ZK that these commitments would make $V_{\text{GKR}}$ accept.

**What about public inputs and outputs?** The verifier still needs to know that the computation used the correct public inputs and produced the claimed public outputs. These aren't hidden; they're part of the statement being proved. The commit-and-prove layer proves: "the committed transcript is valid AND the public input/output wires match the claimed values." The $\Sigma$-protocols can handle this: prove that a commitment opens to a specific public value, or prove equality between a committed value and a known constant.

**What does the verifier learn?** They see the public inputs and outputs (which are part of the statement). They see commitments to everything else in the GKR transcript. They verify (via $\Sigma$-protocols) that these commitments represent a valid accepting transcript consistent with the public I/O. They never see the actual witness values.

**A toy example.** Suppose Alice wants to prove she knows a secret $w$ such that $f(w, x) = y$, where $x$ is a public input and $y$ is a public output.

**Step 1: Run GKR (not zero-knowledge).** Alice runs the GKR protocol on the circuit computing $f$. This produces a transcript $T$ containing:

- Prover messages: polynomials whose coefficients depend on $w$
- Verifier challenges: random field elements

If Alice sent $T$ directly to the verifier, the verifier could check it and be convinced that $f(w, x) = y$. But $T$ leaks information about $w$; every polynomial coefficient is derived from the witness.

**Step 2: Hide the transcript behind commitments.** Instead of sending $T$ in the clear, Alice commits to each leaky value using Pedersen commitments:

- Each polynomial coefficient $c_j$ becomes a commitment $C_j = g^{c_j} h^{r_j}$
- The verifier sees only the commitments, not the values

Now nothing leaks, but the verifier has no idea if the committed values form a valid GKR transcript.

**Step 3: Prove the commitments encode a valid transcript.** What does GKR verification actually check? Looking at Chapter 7, the verifier performs these arithmetic operations on transcript values:

1. **Sum-check round consistency.** For each round polynomial $g_j(X) = a_0 + a_1 X + a_2 X^2 + \ldots$, check that $g_j(0) + g_j(1)$ equals the previous claim. Since $g_j(0) = a_0$ and $g_j(1) = a_0 + a_1 + a_2 + \ldots$, this is: $2a_0 + a_1 + a_2 + \ldots = v_{j-1}$. Pure addition.

2. **Layer transition.** At each layer boundary, check:
$$v_{\text{final}} = \widetilde{\text{add}}_i(r, s_b, s_c) \cdot (u + v) + \widetilde{\text{mult}}_i(r, s_b, s_c) \cdot u \cdot v$$
where $u, v$ are the prover's claimed next-layer evaluations and the wiring predicates are public constants. This involves one multiplication ($u \cdot v$) plus additions.

3. **Line polynomial consistency.** Check $q(0) = u$ and $q(1) = v$ where $q(t)$ is the line polynomial. These are linear combinations of $q$'s coefficients.

4. **Boundary conditions.** The initial claim must equal $y$ (public output). The final evaluation must match $\tilde{W}_d(r_d)$ computed from public input $x$.

Alice proves all these relations hold on the *committed* values using $\Sigma$-protocols:

- Addition checks are free (Pedersen homomorphism)
- Multiplication checks (one per layer) need $\Sigma$-protocols

**Why this is efficient.** A circuit with $n$ gates has depth $d = O(\log n)$ for typical structured circuits. The GKR verifier only performs $O(d)$ multiplications (one per layer). So commit-and-prove on the verifier circuit requires only $O(\log n)$ $\Sigma$-protocols, not $O(n)$. This is the "proof on a proof" payoff: we couldn't afford commit-and-prove on the original $n$-gate circuit, but we can easily afford it on the $O(\log n)$-multiplication verifier.

**What the verifier sees:**

- Public I/O: $(x, y)$
- Commitments: $C_1, C_2, \ldots$ (opaque group elements)
- $\Sigma$-protocol transcripts proving the committed values satisfy GKR verification

**Where did $w$ go?** The witness information is still there; it's encoded in the polynomial coefficients. The chain is:

$$w \longrightarrow \text{gate values} \longrightarrow \text{layer MLEs } \tilde{W}_i \longrightarrow \text{sum-check polynomials} \longrightarrow \text{coefficients } c_j$$

The coefficients $c_j$ are deterministic functions of $w$. If you saw them, you could (in principle) recover information about $w$. But now they're hidden inside Pedersen commitments $C_j = g^{c_j} h^{r_j}$.

**Why doesn't the $\Sigma$-protocol layer leak $w$?** The commit-and-prove circuit doesn't operate on $w$ at all. Its witness is the *GKR transcript*: the coefficients $c_j$ and their blinding factors $r_j$. The $\Sigma$-protocols prove arithmetic relations like "$c_1 + c_2 = c_3$" or "$c_4 \cdot c_5 = c_6$"; they never reference the original circuit's structure or the meaning of these values.

The verifier sees:

- Commitments $C_j$ (random-looking group elements)
- $\Sigma$-protocol proofs that the committed values satisfy GKR verification equations

The verifier learns that *some* values inside the commitments form a valid GKR transcript for a computation with output $y$. But which values? The commitments are perfectly hiding; every valid witness $w$ that produces output $y$ would yield commitments with the same distribution. The verifier cannot distinguish which $w$ Alice used.

**The laundering, precisely:** The original witness $w$ is encoded in the transcript coefficients. But the commit-and-prove layer only proves *structural* facts about those coefficients (they satisfy certain arithmetic relations), not *semantic* facts (what they represent in the original computation). The meaning is laundered away; only validity remains.



## Technique 2: Masking Polynomials

Masking polynomials achieve zero-knowledge through a different mechanism: randomization that preserves validity.

### The Core Idea

Suppose the prover must send a polynomial $g(X)$ derived from the witness. Instead, they send:

$$f(X) = g(X) + \rho \cdot p(X)$$

where $p(X)$ is a random polynomial (committed in advance) and $\rho$ is a random scalar from the verifier.

What does the verifier see? They see $f(X)$, which is $g(X)$ plus random noise. Since $p$ is random and $\rho$ is chosen after the commitment, the combination $\rho \cdot p(X)$ acts like a one-time pad for the polynomial $g$.

The verifier cannot extract $g$ from $f$ without knowing both $p$ and the relationship between $f$ and $g$. Zero-knowledge is achieved.

### But What About Soundness?

Here's the subtle part. The original protocol verified something about $g$ (say, that $\sum_{b} g(b) = H$). Now the verifier sees $f = g + \rho p$ instead. What's being verified?

$$\sum_b f(b) = \sum_b g(b) + \rho \cdot \sum_b p(b) = H + \rho \cdot P$$

where $P = \sum_b p(b)$ is computable from the commitment to $p$.

The masked protocol verifies $\sum_b f(b) = H + \rho P$. If the prover claims a false $H'$:

$$\sum_b f(b) = H' + \rho P \neq H + \rho P = \sum_b g(b) + \rho \cdot \sum_b p(b)$$

The inequality holds for all $\rho$ (it's a non-zero constant, not depending on $\rho$). False claims remain false under masking.

**Key observation:** Masking adds noise but doesn't change the "essence" of what's being verified. A true statement stays true; a false statement stays false. Only the representation is randomized.

### Constructing the Masking Polynomial

The masking polynomial $p(X)$ must satisfy:

1. **Same degree structure as $g$.** If $g$ is multilinear, $p$ should be multilinear. Otherwise $f = g + \rho p$ would have higher degree than expected, and the verifier's degree checks would fail.

2. **Known aggregate properties.** The verifier needs $P = \sum_b p(b)$ to adjust the verification equation. Without knowing $P$, the verifier couldn't check that $\sum_b f(b) = H + \rho P$.

3. **Genuinely random coefficients.** The randomness is what provides hiding. If $p$'s coefficients were predictable, the masking $\rho \cdot p$ wouldn't hide $g$.

**Protocol flow:**

1. Before the main protocol, the prover commits to a random masking polynomial $p$ and sends its sum $P = \sum_b p(b)$.
2. The verifier sends a random $\rho$.
3. The prover runs sum-check on $f = g + \rho p$, sending masked round polynomials.
4. The verifier checks that round polynomials sum correctly to $H + \rho P$ (the adjusted claim).

**Worked example.** Suppose the prover wants to prove $\sum_{x \in \{0,1\}} g(x) = 7$ where $g(X) = 2 + 3X$. Check: $g(0) + g(1) = 2 + 5 = 7$. $\checkmark$

1. **Prover commits to masking polynomial.** Choose random $p(X) = 4 + X$ (same degree as $g$). Compute $P = p(0) + p(1) = 4 + 5 = 9$. Send $(P, \text{Com}(p))$ to the verifier, where $\text{Com}(p)$ is a hiding commitment to the polynomial (e.g., Pedersen commitments to its coefficients, or a polynomial commitment).

2. **Verifier sends $\rho = 6$.**

3. **Prover computes and sends the masked polynomial.** $f(X) = g(X) + \rho \cdot p(X) = (2 + 3X) + 6(4 + X) = 26 + 9X$.

4. **Verifier checks the masked sum.** They verify $\sum_x f(x) = H + \rho P = 7 + 6 \cdot 9 = 61$. Indeed: $f(0) + f(1) = 26 + 35 = 61$. $\checkmark$

**Why it hides.** The verifier sees the masked polynomial $f(X) = 26 + 9X$. They know $f = g + \rho p$, and they know $\rho = 6$. But they only have a commitment to $p$, not $p$ itself. Without knowing $p(X) = 4 + X$, they cannot compute $g(X) = f(X) - \rho \cdot p(X)$. The commitment is hiding; it reveals nothing about $p$'s coefficients.

Different masking polynomials produce different $f$. For any degree-1 polynomial the verifier might guess for $g$, there exists a $p$ that would produce the observed $f$. Without the commitment opening, all such guesses are equally plausible.

This is the polynomial analogue of the one-time pad. In classical cryptography, adding a truly random string to a message produces ciphertext that reveals nothing about the message: every possible plaintext is equally consistent with the observed ciphertext. Here, adding a random polynomial to the witness polynomial produces a masked polynomial that reveals nothing about the witness: every possible witness polynomial is equally consistent with what the verifier sees. The commitment to $p$ ensures the randomness is fixed before it's used, preventing the prover from cheating, while still keeping the actual random values hidden.

**The multivariate case.** In real sum-check with $n$ variables, the same principle applies: the prover commits to a multivariate masking polynomial $p(X_1, \ldots, X_n)$ with the same structure as $g$. Each round polynomial derived from $f = g + \rho p$ is masked, hiding the witness-dependent coefficients. The verifier checks adjusted sums against $H + \rho P$ and remains convinced of the original claim without learning the intermediate structure.

But there's a catch. At the end of sum-check, the prover must open $g(r_1, \ldots, r_n)$ at the random point (typically via a polynomial commitment). This final evaluation reveals information about the witness polynomial!

### Masking the Final Evaluation

Think of invisible ink that appears only under certain conditions. You write a message that's visible in normal light, then add invisible ink marks that show up only under UV light. Anyone reading the paper in normal light sees just the original message. But if they examine it under UV, they see a jumble of the message plus the invisible marks.

The mathematical version works similarly. The prover adds random terms that are "invisible" on the Boolean hypercube (where the computation actually happens) but become visible when the verifier queries at a random point outside the hypercube.

The solution is elegant. Instead of committing to the "bare" witness polynomial $W(X)$, the prover commits to a randomized extension:

$$\tilde{W}(X_1, \ldots, X_n) = W(X_1, \ldots, X_n) + \sum_{i=1}^n c_i \cdot X_i(1 - X_i)$$

where $c_1, \ldots, c_n$ are random field elements.

**The magic:** The terms $X_i(1 - X_i)$ vanish on the Boolean hypercube $\{0, 1\}^n$. When any $X_i \in \{0, 1\}$, we have $X_i(1 - X_i) = 0$.

So on the hypercube:
$$\tilde{W}(b) = W(b) + \sum_i c_i \cdot 0 = W(b)$$

The randomized extension agrees with the witness on all Boolean inputs (exactly where the circuit is evaluated).

But at a random point $z \notin \{0, 1\}^n$, which is where the verifier queries after sum-check, the evaluation becomes:

$$\tilde{W}(z) = W(z) + \sum_i c_i \cdot z_i(1 - z_i)$$

The random $c_i$ terms contribute. The verifier learns $\tilde{W}(z)$, which is a random function of the hidden $c_i$ values. They cannot extract $W(z)$.

**Worked example.** Let $W(X) = 3X$ be a single-variable witness. Randomize with $c = 7$:

$$\tilde{W}(X) = 3X + 7 \cdot X(1 - X) = 3X + 7X - 7X^2 = 10X - 7X^2$$

On the hypercube:

- $\tilde{W}(0) = 0 = W(0)$
- $\tilde{W}(1) = 10 - 7 = 3 = W(1)$

At a random point $z = 0.5$:

- $W(0.5) = 1.5$ (would leak information)
- $\tilde{W}(0.5) = 5 - 1.75 = 3.25$ (masked by the random $c = 7$)

Different random $c$ values produce different evaluations at $z = 0.5$, hiding the structure of $W$.

## Zero-Knowledge in Groth16

Groth16 takes a different approach: it bakes zero-knowledge into the algebraic structure of the proof itself.

### The Big Picture

The masking polynomial technique from the previous section adds randomness *to the polynomials*; you send $f = g + \rho p$ instead of $g$. Groth16's approach is different: it adds randomness *to the proof elements directly*.

**The core heuristic:** A Groth16 proof is three group elements. If those elements were deterministic functions of the witness, the proof would leak: same witness means same proof, and structural relationships between proofs might reveal witness relationships. The fix is to randomize each proof element while preserving the verification equation.

This is conceptually similar to how Pedersen commitments work. A commitment $C = g^m h^r$ hides $m$ because the random $r$ makes $C$ uniformly distributed. Groth16 does something analogous: random scalars $(r, s)$ make the proof elements uniformly distributed (in an appropriate sense) while the algebraic structure ensures verification still works.

### The Blinding Mechanism

Recall from Chapter 12 that Groth16 proofs consist of three group elements $(\pi_A, \pi_B, \pi_C)$. Without blinding, these would be deterministic functions of the witness (same witness, same proof). Anyone could check if two proofs used the same witness by comparing them.

To achieve zero-knowledge, the prover samples fresh random scalars $r, s \in \mathbb{F}$ and incorporates them:

$$\pi_A = g_1^{\alpha + A(\tau) + r\delta}$$
$$\pi_B = g_2^{\beta + B(\tau) + s\delta}$$

The $r\delta$ and $s\delta$ terms add randomness. But where do they go? They'd break the verification equation unless compensated. The construction of $\pi_C$ absorbs them:

$$\pi_C = g_1^{\frac{\text{private terms}}{\delta} + \frac{H(\tau)Z_H(\tau)}{\delta} + s(\alpha + A(\tau) + r\delta) + r(\beta + B(\tau)) - rs\delta}$$

The terms $sA(\tau)$, $s\alpha$, $rB(\tau)$, $r\beta$, and $rs\delta$ in $\pi_C$ exactly cancel the cross-terms that appear when expanding $e(\pi_A, \pi_B)$.

### Why This Works

The verification equation checks:
$$e(\pi_A, \pi_B) = e(g_1^\alpha, g_2^\beta) \cdot e(\text{vk}_x, g_2^\gamma) \cdot e(\pi_C, g_2^\delta)$$

Expanding $e(\pi_A, \pi_B)$ with blinding:
$$e(g_1^{\alpha + A(\tau) + r\delta}, g_2^{\beta + B(\tau) + s\delta})$$

The exponent becomes $(\alpha + A + r\delta)(\beta + B + s\delta)$, which expands to include cross-terms: $\alpha s\delta$, $A s\delta$, $r\beta\delta$, $rB\delta$, $rs\delta^2$.

The $\pi_C$ construction is designed so that when paired with $g_2^\delta$, it produces exactly these cross-terms (plus the core QAP check). Everything cancels except the QAP identity $A(\tau)B(\tau) = C(\tau) + H(\tau)Z_H(\tau)$.

**The result:** Different $(r, s)$ produce different valid proofs for the same witness. The proof elements are randomized, but the verification equation still holds.

### The Role of $\delta$

The setup secret $\delta$ is crucial. The prover has access to $g_1^\delta$ and $g_2^\delta$ (in the proving key), but not to $\delta$ as a field element.

This matters because the blinding terms $r\delta$ and $s\delta$ appear in the exponent. The prover computes $g_1^{r\delta}$ as $(g_1^\delta)^r$ (scalar multiplication of a known group element). But without knowing $\delta$, they cannot predict how this blinding "looks" in the algebraic structure.

From the verifier's perspective, the proof elements could have come from any witness that satisfies the public constraints. The randomization by $(r, s)$ makes proofs for different witnesses indistinguishable from proofs for the same witness with different randomness.

This is why Groth16's trusted setup cannot be eliminated without changing the proof system fundamentally; the $\delta$ secret is essential to the blinding mechanism.



## Zero-Knowledge in PLONK

PLONK commits to polynomials representing the witness and constraint satisfaction. Each commitment potentially leaks information. The solution: add vanishing polynomial multiples.

### The Big Picture

PLONK's zero-knowledge strategy exploits a fundamental feature of its architecture: constraints are checked only on a specific domain $H$, but the verifier queries polynomials at a random point $\zeta$ outside $H$.

**The core heuristic:** If a polynomial $p(X)$ matters only for its values on $H$, then adding any multiple of $Z_H(X)$ (the vanishing polynomial) doesn't change those values, but it does change what the verifier sees at $\zeta$. The blinding is "invisible" where it matters and "visible" where the verifier looks.

This is a beautiful instance of *locality*: the constraint domain and the query domain are disjoint. Randomness that affects one need not affect the other. The prover adds random multiples of $Z_H$ that preserve correctness on $H$ while making evaluations at $\zeta$ statistically independent of the witness.

**Contrast with Groth16:** Groth16 randomizes the proof elements themselves. PLONK randomizes the polynomials before committing. The effect is similar (the verifier sees randomized values) but the mechanism is different. PLONK's approach is more modular: the blinding is applied at the polynomial level, independent of the commitment scheme.

### The Vanishing Polynomial Trick

The constraint checks in PLONK occur on a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$ where $\omega$ is a primitive $n$th root of unity.

The vanishing polynomial is $Z_H(X) = X^n - 1 = \prod_{i=0}^{n-1}(X - \omega^i)$. By definition, $Z_H(\omega^i) = 0$ for all $i$.

To blind a witness polynomial $w(X)$, add a random low-degree polynomial times $Z_H$:

$$\tilde{w}(X) = w(X) + (b_1 X + b_2) \cdot Z_H(X)$$

where $b_1, b_2$ are random field elements.

On the constraint-check domain:
$$\tilde{w}(\omega^i) = w(\omega^i) + (b_1 \omega^i + b_2) \cdot 0 = w(\omega^i)$$

The blinded polynomial equals the original at all points where constraints are checked. But at any point outside $H$, which is where the verifier queries after Fiat-Shamir, the random blinding term contributes.

**Why a polynomial, not just a scalar?** The verifier queries at a random point $\zeta$, receiving $\tilde{w}(\zeta)$. A single scalar $b$ would add the fixed value $b \cdot Z_H(\zeta)$, which might not provide enough entropy depending on what else the verifier learns. Using $(b_1 X + b_2)$ ensures sufficient randomness for simulation arguments.

### Blinding the Accumulator

PLONK's permutation argument uses an accumulator polynomial $Z(X)$ that tracks whether wire values are correctly copied. This polynomial also reveals structure.

The accumulator is checked at two points: $\zeta$ and $\zeta\omega$ (the "shifted" evaluation). To mask both, use three random scalars:

$$\tilde{Z}(X) = Z(X) + (c_1 X^2 + c_2 X + c_3) \cdot Z_H(X)$$

The boundary condition $Z(1) = 1$ and the recursive multiplicative relation are preserved on $H$. Outside $H$, both $\tilde{Z}(\zeta)$ and $\tilde{Z}(\zeta\omega)$ are randomized.

### Quotient Polynomial

The quotient polynomial $t(X)$ encodes constraint satisfaction:

$$\text{constraint polynomial}(X) = t(X) \cdot Z_H(X)$$

For degree reasons, $t(X)$ must be split into pieces and committed separately. Each piece can be blinded with low-order random terms that don't affect the high-degree constraint.

The details are technical, but the principle is the same: add randomness that vanishes where it matters and randomizes where the verifier looks.

### The Unifying Principle

Both Groth16 and PLONK achieve zero-knowledge through the same underlying idea: **randomize what the verifier sees while preserving what the verifier checks.**

In Groth16, the verifier checks a pairing equation. The prover adds random terms $(r, s)$ that cancel in the pairing; the verification equation is unchanged, but the proof elements are randomized.

In PLONK, the verifier checks polynomial constraints on domain $H$ and queries at random point $\zeta$. The prover adds random multiples of $Z_H$ that are zero on $H$; the constraints are unchanged, but the evaluation at $\zeta$ is randomized.

The pattern: find the "null space" of the verification procedure (transformations that don't affect the outcome) and inject randomness there. This is exactly the simulation paradigm from Chapter 17: the simulator can produce valid-looking transcripts because it can choose the randomness to make everything work out.



## Comparing the Techniques

| Aspect | Commit-and-Prove | Masking Polynomials |
|--------|-----------------|---------------------|
| **Generality** | Works for any public-coin protocol | Specialized for polynomial protocols |
| **Overhead** | $O(M)$ $\Sigma$-protocols for $M$ multiplications | $O(1)$ additional commitments |
| **Succinctness** | Requires "proof on a proof" | Naturally preserves succinctness |
| **Post-quantum** | No (relies on discrete log) | Yes (with hash-based PCS) |
| **Complexity** | Conceptually straightforward | Requires algebraic design |

> **A Dimensionality Distinction**
>
> These two techniques operate at different levels of abstraction. Commit-and-prove works on *scalars*: individual field elements like wire values and coefficients. Each value gets its own commitment, and relations between values are proved one at a time. Masking polynomials works on *functions*: entire polynomials representing the witness. A single random polynomial masks all coefficients at once. This is why their costs differ so dramatically. Hiding $n$ scalars with commit-and-prove requires $n$ commitments; hiding an $n$-coefficient polynomial with masking requires one random polynomial. The jump from scalar to function is what makes masking efficient for polynomial-based protocols.

**When to use commit-and-prove:**

- The underlying protocol isn't polynomial-based
- You need perfect ZK (masking achieves computational ZK)
- You're composing with $\Sigma$-protocols for other purposes

**When to use masking:**

- The protocol is polynomial-based (sum-check, PLONK, STARKs)
- Succinctness matters
- The algebraic structure permits clean masking

Most production systems use masking for the main protocol body and commit-and-prove for auxiliary statements (range proofs, committed value equality, etc.).



## The Simulator for Masked Protocols

Let's construct an explicit simulator for a masked sum-check, demonstrating that the masking actually achieves zero-knowledge.

**Real protocol:**

1. Prover commits to random masking polynomial $p$
2. Verifier sends random $\rho$
3. Parties execute sum-check on $f = g + \rho p$
4. Prover opens $g(z)$ and $p(z)$ at random point $z$

**Simulator (no access to witness):**

1. Commit to random polynomial $p$
2. Choose random polynomial $q$ (standing in for $g$)
3. "Execute" sum-check on $f' = q + \rho p$
4. Open $q(z)$ and $p(z)$

**Why indistinguishable?**

The verifier sees:

- A commitment to $p$ (random in both cases)
- Sum-check messages derived from $f = g + \rho p$ (real) or $f' = q + \rho p$ (simulated)
- Evaluations at a random point

Since $g$ is masked by $\rho p$ and $\rho$ is chosen after the commitment to $p$, the messages $f(z)$ are uniformly distributed regardless of $g$. The simulator's $q$ produces identically distributed messages.

The distributions are the same. Zero-knowledge holds.



## Key Takeaways

1. **Proof systems aren't born zero-knowledge; they're made that way.** Soundness and succinctness come first; privacy requires deliberate design. Without masking, every protocol leaks witness information through its intermediate values.

2. **The unifying principle: randomize what the verifier sees, preserve what the verifier checks.** Every ZK technique finds a "null space" in the verification procedure (transformations that don't affect the outcome) and injects randomness there.

3. **Two main techniques.** *Commit-and-prove* hides values behind commitments and proves relations via $\Sigma$-protocols. *Masking polynomials* add random noise that cancels where verification happens. Both achieve the same goal through different means.

4. **Commit-and-prove is general but expensive.** It works for any public-coin protocol, but proof size scales with multiplication count. The "proof on a proof" trick recovers succinctness: apply commit-and-prove to the $O(\log n)$ verifier circuit, not the $O(n)$ original computation.

5. **Masking polynomials preserve succinctness naturally.** Add $\rho \cdot p(X)$ where $p$ is committed before $\rho$ is chosen. The verifier adjusts their check accordingly. Soundness survives because false claims produce inconsistencies that persist under any masking.

6. **Final evaluations need separate treatment.** Masking the intermediate polynomials isn't enough; the verifier still queries the witness polynomial at a random point. Solution: extend with terms like $\sum_i c_i X_i(1-X_i)$ that vanish on the Boolean hypercube but randomize elsewhere.

7. **Groth16 randomizes proof elements directly.** Fresh scalars $(r, s)$ combined with the setup secret $\delta$ produce randomized group elements. The verification equation still holds because $\pi_C$ absorbs the cross-terms. This is why Groth16 needs a trusted setup for ZK, not just for soundness.

8. **PLONK exploits domain separation.** Constraints are checked on domain $H$; the verifier queries at random $\zeta \notin H$. Adding random multiples of $Z_H(X)$ is invisible on $H$ but randomizes evaluations at $\zeta$. The constraint domain and query domain are disjoint; randomness in one doesn't affect the other.

9. **Simulation is the proof that ZK works.** A simulator without the witness produces transcripts indistinguishable from real executions. For masked protocols, the simulator just picks random polynomials; the masking makes them look identical to honest transcripts.

10. **Production systems blend both approaches.** Masking handles the core polynomial protocol efficiently. Commit-and-prove handles auxiliary statements (range proofs, equality of committed values) that don't fit the polynomial structure.




\newpage

# Chapter 19: Fast Sum-Check Proving

> *Most chapters in this book can be read with pencil and paper. This one assumes you've already internalized the sum-check protocol (Chapter 3) and multilinear extensions (Chapter 4), not as definitions to look up, but as tools you can wield. If those still feel foreign, consider this chapter a preview of where the road leads, and return when the foundations feel solid.*

In 1992, the sum-check protocol solved the problem of succinct verification. Lund, Fortnow, Karloff, and Nisan had achieved something that sounds impossible: verifying a sum over $2^n$ terms while the verifier performs only $O(n)$ work. Exponential compression in verification time. The foundation of succinct proofs.

Then, for three decades, almost nobody used it.

Why? Because everyone thought it was too slow. A naive reading of the protocol suggests the prover performs $O(n \cdot 2^n)$ operations, worse than just computing the sum directly. For $n = 30$, that's over 30 billion operations per proof. Researchers chased other paths: PCPs, pairing-based SNARKs, trusted setups. Groth16 and PLONK took univariate polynomials, quotient-based constraints, FFT-driven arithmetic. Sum-check remained a theoretical marvel, admired in complexity circles but dismissed as impractical.

They were wrong.

It turned out that a simple algorithmic trick, available since the 90s but overlooked, made the prover linear time. With the right algorithms, sum-check proving runs in $O(2^n)$ time, linear in the number of terms. For sparse sums where only $T \ll 2^n$ terms are non-zero, prover time drops to $O(T)$. These are not approximations or heuristics; they're exact algorithms exploiting algebraic structure that was always present.

When this was rediscovered and popularized by Justin Thaler in the late 2010s, it triggered a revolution. The field realized it had been sitting on the "Holy Grail" of proof systems for three decades without noticing. This chapter explains the trick that woke up the giant, and then shows how it enables Spartan, the SNARK that proved sum-check alone suffices for practical zero-knowledge proofs. No univariate encodings. No pairing-based trusted setup. Just multilinear polynomials, sum-check, and a commitment scheme.

### Why This Matters: The zkVM Motivation

The techniques in this chapter find their most compelling application in *zkVMs* (zero-knowledge virtual machines). A zkVM proves correct execution of arbitrary programs without requiring a new circuit for each program.

The idea is simple in principle. Take an instruction set architecture like RISC-V. Write a SNARK that proves: "given this program and this input, the CPU executed correctly and produced this output." The circuit encodes the CPU's transition function: fetch instruction, decode, execute, update registers and memory, repeat. Any program compiles to RISC-V; the same circuit proves them all.

The scale is staggering. A modest program might execute millions of CPU cycles. Each cycle involves dozens of constraints: register reads, ALU operations, memory accesses, program counter updates. A million cycles at 50 constraints each yields 50 million constraints. And that's a *small* program.

At this scale, constant factors matter. The difference between $O(n \log n)$ and $O(n)$ proving time is the difference between minutes and seconds. The difference between $5n$ and $2n$ operations is the difference between a practical system and an impractical one.

This is why fast sum-check proving isn't an academic curiosity. It's the foundation that makes zkVMs possible.

> **Remark (Sum-checks compose into graphs).** A zkVM doesn't run one sum-check; it runs dozens. Each sum-check ends with an evaluation claim ("prove $\tilde{f}(r) = v$"). If $\tilde{f}$ is committed, open it. If $\tilde{f}$ is *virtual*, defined in terms of other polynomials, another sum-check proves that evaluation, producing its own claims. The structure is a directed acyclic graph: sum-checks as nodes, claims as edges. The prover traverses this graph, and the graph's structure determines proof efficiency.
>
> Two dimensions matter. *Depth* (longest path through the graph) determines the minimum number of sequential *stages*, meaning sum-checks that depend on each other's outputs. *Width* (sum-checks at the same depth) allows *batching*, combining independent sum-checks via random linear combination into a single sum-check. A well-designed protocol minimizes depth and maximizes batching at each stage. We'll develop this perspective fully in Chapter 20; for now, just note that fast sum-check proving matters not just once, but dozens of times per proof.

## The Prover's Apparent Problem

Let's examine the naive prover cost more carefully.

The sum-check protocol proves:
$$H = \sum_{b \in \{0,1\}^n} g(b)$$

In round $i$, the prover sends a univariate polynomial capturing the partial sum with $X_i$ left as a formal variable:

$$s_i(X_i) = \sum_{(b_{i+1}, \ldots, b_n) \in \{0,1\}^{n-i}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

If $g$ has individual degree $d$ in each variable, then $s_i$ has degree $d$ in $X_i$. The prover specifies $s_i$ by sending $d+1$ evaluations.

**The apparent cost:** Computing $s_i(t)$ for a single value $t$ requires summing over $2^{n-i}$ terms. Computing $s_i(0), s_i(1), \ldots, s_i(d)$ requires $(d+1) \cdot 2^{n-i}$ evaluations of $g$.

Across all $n$ rounds:
$$\sum_{i=1}^n (d+1) \cdot 2^{n-i} = (d+1)(2^{n-1} + 2^{n-2} + \cdots + 1) = (d+1)(2^n - 1)$$

This is $O(d \cdot 2^n)$, linear in the table size when $d$ is constant. But the naive approach computes this by brute force, re-evaluating $g$ at the same points multiple times across rounds.

The insight is that we don't need to recompute from scratch each round. The work halves with each round, and we can reuse intermediate results.

## The Halving Trick

Consider the most important case: $g(x) = \tilde{a}(x) \cdot \tilde{b}(x)$ where $\tilde{a}$ and $\tilde{b}$ are multilinear polynomials (the multilinear extensions of some tables $a$ and $b$).

Since multilinear polynomials have degree at most 1 in each variable, their product has degree at most 2. So $d = 2$, and each round the prover sends three field elements: $s_i(0), s_i(1), s_i(2)$.

### The Key Algebraic Fact

For any multilinear polynomial $\tilde{a}(x_1, x_2, \ldots, x_n)$ and field element $r_1$:

$$\tilde{a}(r_1, x_2, \ldots, x_n) = (1 - r_1) \cdot \tilde{a}(0, x_2, \ldots, x_n) + r_1 \cdot \tilde{a}(1, x_2, \ldots, x_n)$$

This follows from the definition of multilinear: linear in each variable separately. The function $\tilde{a}(X_1, x_2, \ldots)$ is linear in $X_1$, so it's determined by its values at $X_1 = 0$ and $X_1 = 1$. (This is exactly the streaming evaluation formula from Chapter 4, where we used it to evaluate MLEs efficiently.)

This fact enables **folding**: after receiving challenge $r_1$, we can compute the restricted polynomial $\tilde{a}(r_1, x_2, \ldots, x_n)$ from the unrestricted polynomial $\tilde{a}$ in linear time.

### The Algorithm

Recall from Chapter 3: in round $i$ of sum-check, the prover sends a univariate polynomial $s_i(X_i)$ representing the partial sum with $X_i$ left as a formal variable. Since $g = \tilde{a} \cdot \tilde{b}$ has degree 2 in each variable, $s_i$ is degree-2, requiring three evaluations $s_i(0), s_i(1), s_i(2)$ to specify.

**Initialization.** Store all $2^n$ evaluations $\tilde{a}(b)$ and $\tilde{b}(b)$ for $b \in \{0,1\}^n$ in arrays $A[b]$ and $B[b]$.

**Round 1.** Compute three evaluations of $s_1(X_1) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} \tilde{a}(X_1, b_2, \ldots, b_n) \cdot \tilde{b}(X_1, b_2, \ldots, b_n)$:

- $s_1(0) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(0, b_2, \ldots, b_n)] \cdot B[(0, b_2, \ldots, b_n)]$
- $s_1(1) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(1, b_2, \ldots, b_n)] \cdot B[(1, b_2, \ldots, b_n)]$
- $s_1(2) = \sum_{(b_2, \ldots, b_n) \in \{0,1\}^{n-1}} A[(2, b_2, \ldots, b_n)] \cdot B[(2, b_2, \ldots, b_n)]$

For $s_1(0)$ and $s_1(1)$, we read values directly from the stored arrays (these are Boolean points). For $s_1(2)$, the point $X_1 = 2$ isn't in our table, but since $\tilde{a}$ is linear in $X_1$, we interpolate. A line through $(0, y_0)$ and $(1, y_1)$ has the form $y_0 + (y_1 - y_0) \cdot X$, which at $X = 2$ gives $y_0 + 2(y_1 - y_0) = -y_0 + 2y_1$. So $A[(2, b_2, \ldots, b_n)] = -A[(0, b_2, \ldots, b_n)] + 2 \cdot A[(1, b_2, \ldots, b_n)]$. Similarly for $B$.

Send $(s_1(0), s_1(1), s_1(2))$. This takes $O(2^{n-1})$ operations.

**Fold after round 1.** Receive challenge $r_1$. Create a new array $A'$ of size $2^{n-1}$, indexed by $(b_2, \ldots, b_n) \in \{0,1\}^{n-1}$:
$$A'[(b_2, \ldots, b_n)] = (1 - r_1) \cdot A[(0, b_2, \ldots, b_n)] + r_1 \cdot A[(1, b_2, \ldots, b_n)] = \tilde{a}(r_1, b_2, \ldots, b_n)$$

Discard the old array and rename $A' \to A$. The array now stores the restricted polynomial $\tilde{a}(r_1, x_2, \ldots, x_n)$ evaluated on the $(n-1)$-dimensional hypercube. Similarly fold $B$.

**Subsequent rounds.** Repeat: compute $s_i$ from the current arrays, send it, fold the arrays using $r_i$.

**Complexity.** Round $i$ operates on arrays of size $2^{n-i+1}$, then folds to size $2^{n-i}$:
$$O(2^{n-1}) + O(2^{n-2}) + \cdots + O(1) = O(2^n)$$

The total prover work is $O(2^n)$, down from the naive $O(n \cdot 2^n)$ analysis at the start of this chapter. This is optimal: any algorithm proving a claim about a sum over $2^n$ terms must read all $2^n$ inputs at least once, so $\Omega(2^n)$ is an information-theoretic lower bound.

**Why the speedup works.** The core insight is simple once you see it.

*Naive approach*: In each of the $n$ rounds, re-evaluate the polynomial at all necessary points from scratch. Round 1 touches $O(2^n)$ terms. Round 2 touches $O(2^{n-1})$ terms, but computes each by going back to the original tables. Round 3 the same. Each round performs a fresh evaluation, and "fresh evaluation" costs the full table size for that round. Total: $n$ separate evaluations, giving $O(n \cdot 2^n)$.

*Folding approach*: Evaluate once at the start, storing results in a table. Then, after each challenge $r_i$, *update* the table rather than re-evaluate. The update is cheap: just a linear combination of adjacent entries. No re-evaluation from scratch, ever. The table shrinks by half each round, and we touch each entry exactly once.

> **The Origami Analogy**
>
> Imagine a long strip of paper with numbers written on it. You want to compute a weighted sum.
>
> *Naive approach*: Walk down the strip, reading numbers and adding them up. For the next round, walk down the strip again.
>
> *Folding approach*: Fold the paper in half. Where the paper overlaps, mix the two numbers together based on the random challenge. Now you have a strip half as long. Throw away the original.
>
> By the end, you have folded the paper into a single square containing one number. You never had to walk back and forth. This is why the prover achieves $O(N)$ total work instead of $O(N \log N)$: each number is touched exactly once, during the fold that eliminates its dimension.

The naive prover asks "what is $\tilde{a}(r_1, \ldots, r_i, x_{i+1}, \ldots)$?" afresh each round. The folding prover asks "given what I already computed, how does fixing $x_i = r_i$ change the table?" The former is $O(2^{n-i})$ per round times $n$ rounds. The latter is $O(2^{n-i})$ per round, summing to a geometric series: $2^{n-1} + 2^{n-2} + \ldots + 1 = 2^n - 1$.

This is dynamic programming: intermediate results flow forward, each round reusing the previous round's work. The fold operation after round $i$ produces exactly the data structure needed for round $i+1$. Instead of recomputing $\tilde{a}(r_1, \ldots, r_i, x_{i+1}, \ldots, x_n)$ from scratch, we derive it from the previous round's output with a single linear pass.

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

### Code: The Halving Trick

The following Python implements the folding prover for sum-check over a product $\tilde{a}(x) \cdot \tilde{b}(x)$. Notice how the arrays shrink after each round.

```python
def sumcheck_fold(A, B, challenges):
    """
    Sum-check prover using the halving trick.
    Proves: H = sum over hypercube of A[x] * B[x]

    Args:
        A, B: Tables of size 2^n (as flat lists, index = binary encoding)
        challenges: List of n verifier challenges r_1, ..., r_n

    Returns: List of round polynomials, each as (s(0), s(1), s(2))
    """
    rounds = []

    for r in challenges:
        half = len(A) // 2

        # Compute s(0), s(1), s(2) for this round's polynomial
        # s(t) = sum over remaining vars of A(t, ...) * B(t, ...)
        s0 = sum(A[2*i] * B[2*i] for i in range(half))
        s1 = sum(A[2*i + 1] * B[2*i + 1] for i in range(half))

        # s(2): extrapolate using linearity. For a line through
        # (0, y0) and (1, y1), the value at t=2 is 2*y1 - y0
        s2 = sum((2*A[2*i + 1] - A[2*i]) * (2*B[2*i + 1] - B[2*i])
                 for i in range(half))

        rounds.append((s0, s1, s2))

        # FOLD: A'[i] = (1-r)*A[2i] + r*A[2i+1]
        # This computes A restricted to first variable = r
        A = [(1 - r) * A[2*i] + r * A[2*i + 1] for i in range(half)]
        B = [(1 - r) * B[2*i] + r * B[2*i + 1] for i in range(half)]

    return rounds

# Reproduce the worked example above
A = [2, 5, 4, 3]  # A[00]=2, A[01]=5, A[10]=4, A[11]=3
B = [3, 1, 2, 4]  # B[00]=3, B[01]=1, B[10]=2, B[11]=4

print(f"True sum: {sum(A[i]*B[i] for i in range(4))}")  # 31

rounds = sumcheck_fold(A, B, challenges=[3, 7])
for i, (s0, s1, s2) in enumerate(rounds):
    print(f"Round {i+1}: s(0)={s0}, s(1)={s1}, s(2)={s2}")
    print(f"  Check: s(0) + s(1) = {s0 + s1}")
```

Output:
```
True sum: 31
Round 1: s(0)=11, s(1)=20, s(2)=13
  Check: s(0) + s(1) = 31
Round 2: s(0)=0, s(1)=-10, s(2)=-200
  Check: s(0) + s(1) = -10
```

The key insight: each round, the arrays halve in size. Total work is $4 + 2 = 6$ operations, not $4 + 4 = 8$. For $n$ variables with table size $N = 2^n$, this gives $N + N/2 + N/4 + \cdots = O(N)$.



## Sparse Sums

The halving trick solves the dense case: when all $2^n$ terms are present, we achieve optimal $O(2^n)$ proving time. But many applications involve **sparse** sums, where only $T \ll 2^n$ terms are non-zero, and here the halving trick falls short.

Consider a lookup table with $N = 2^{30}$ possible indices but only $T = 2^{20}$ actual lookups. The halving trick still touches all $2^{30}$ positions, folding arrays of zeros. We're wasting a factor of 1000 in both time and space.

Can the prover exploit sparsity?

### The Challenge

The dense algorithm folds arrays of size $N$. Even if most entries are zero, the fold operation touches all positions. We need a fundamentally different approach.

### The Key Assumption: Separable Product Structure

Not every sparse polynomial admits fast proving. The technique requires a specific structure.

**Clarification: sparse input, dense polynomial.** When we say "sparse sum," we mean the *input data* is sparse: the table of values on the Boolean hypercube has mostly zeros. The multilinear extension of this sparse vector is typically a *dense* polynomial with non-zero values everywhere on the continuous domain. This distinction matters because we operate on the basis vector (the table), not the polynomial coefficients. Sparsity in the table is what we exploit.

Suppose the polynomial factors as:

$$g(p, s) = \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$$

where we split the $n$ variables into prefix $p = (x_1, \ldots, x_{n/2})$ and suffix $s = (x_{n/2+1}, \ldots, x_n)$, and:

- **$\tilde{a}(p, s)$** is a **sparse** selector with only $T$ non-zero entries
- **$\tilde{f}(p)$** depends only on prefix variables (dense, size $2^{n/2}$)
- **$\tilde{h}(s)$** depends only on suffix variables (dense, size $2^{n/2}$)

This structure arises naturally in memory-checking arguments, lookup protocols, and batch polynomial evaluation. Think of $\tilde{a}$ as selecting "which (address, value) pairs actually occur," $\tilde{f}$ as encoding "address-dependent data," and $\tilde{h}$ as encoding "value-dependent data."

### Why This Structure Enables Sparsity Exploitation

The separable product structure is what makes sparse proving possible. Here's the key observation:

When we build intermediate arrays for sum-check, the sparse factor $\tilde{a}(p,s)$ acts as a filter. To compute an aggregate like $\sum_s \tilde{a}(p,s) \cdot \tilde{h}(s)$, we only need to touch the $T$ positions where $\tilde{a}$ is non-zero. The dense factors $\tilde{f}$ and $\tilde{h}$ are accessed only at locations dictated by the sparse selector.

Without this structure, exploiting sparsity is impossible. A general sparse polynomial $g(x_1, \ldots, x_n)$ doesn't decompose into independent prefix and suffix factors, so we can't avoid touching all $2^n$ positions during folding.

### Two-Stage Proving

Given the separable product structure, we prove the sum in two stages. Each stage handles half the variables, building dense arrays of size $2^{n/2}$ by scanning only the $T$ sparse entries.

**Stage 1: Sum-check over prefix variables.**

Define aggregated arrays $P$ and $F$, each of size $2^{n/2}$, indexed by prefix bit-vectors $p \in \{0,1\}^{n/2}$:

$$P[p] = \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{h}(s)$$
$$F[p] = \tilde{f}(p)$$

The arrays $P$ and $F$ have size $2^{n/2}$, not $2^n$. By summing out the suffix variables when building $P$, we reduce the problem from $n$ variables to $n/2$ variables for Stage 1.

Computing $P$ requires one pass over the $T$ non-zero terms: for each non-zero $(p, s)$ pair, add $\tilde{a}(p, s) \cdot \tilde{h}(s)$ to $P[p]$.

Now observe: the original sum-check claim is
$$\sum_{p \in \{0,1\}^{n/2}} \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s) = \sum_{p \in \{0,1\}^{n/2}} \tilde{f}(p) \cdot \underbrace{\sum_{s \in \{0,1\}^{n/2}} \tilde{a}(p, s) \cdot \tilde{h}(s)}_{= P[p]}$$

So proving the original sum reduces to proving $\sum_p \tilde{P}(p) \cdot \tilde{F}(p)$, a sum-check with only $n/2$ variables. Here $\tilde{P}$ and $\tilde{F}$ are the multilinear extensions of arrays $P$ and $F$.

Run the dense halving algorithm on these $2^{n/2}$-sized arrays. Time: $O(T)$ to build $P$ from sparse entries, plus $O(2^{n/2})$ for the dense sum-check.

**Stage 2: Sum-check over suffix variables (to verify Stage 1's evaluation).**

Stage 1 is a complete sum-check on its own polynomial, ending with an evaluation claim. But that claim involves $\tilde{P}(r_p)$, which is itself defined as a sum. Where does Stage 2 come from?

**The key point:** Stage 1 is a complete sum-check, but on a *different polynomial* than the original. Compare:

| | Original claim | Stage 1 claim |
|---|---|---|
| **Polynomial** | $g(p,s) = \tilde{a}(p,s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$ | $\tilde{P}(p) \cdot \tilde{F}(p)$ |
| **Variables** | $n$ (both $p$ and $s$) | $n/2$ (only $p$) |
| **Rounds** | $n$ | $n/2$ |

The two sums are equal (both equal $H$), but Stage 1's polynomial has half the variables because we pre-summed the suffix into $P[p]$.

Like any sum-check, Stage 1 ends with a final evaluation claim: "I claim $\tilde{P}(r_p) \cdot \tilde{F}(r_p) = v_1$." The verifier can check $\tilde{F}(r_p)$ via polynomial commitment. But what about $\tilde{P}(r_p)$?

Expanding using the definition of $P$:

$$\tilde{P}(r_p) = \sum_{s \in \{0,1\}^{n/2}} \tilde{a}(r_p, s) \cdot \tilde{h}(s)$$

This is a sum over $2^{n/2}$ terms. The verifier can't compute it directly. **Stage 2 is a second sum-check to prove this evaluation claim.** We use sum-check to verify that the final evaluation from Stage 1 is correct.

Define arrays $H$ and $Q$, each of size $2^{n/2}$, indexed by suffix bit-vectors $s \in \{0,1\}^{n/2}$:

$$H[s] = \tilde{a}((r_1, \ldots, r_{n/2}), s)$$
$$Q[s] = \tilde{h}(s)$$

Here $H$ is the sparse selector with its prefix fixed to the random challenges: it answers "what is the selector's value at address $(r_p, s)$?" The factor $\tilde{f}(r_p)$ is now a constant (computed once from the dense $F$ array) that multiplies the entire Stage 2 sum.

Computing $H$ requires the MLE interpolation identity: $\tilde{a}(r_p, s) = \sum_{p'} \tilde{a}(p', s) \cdot \widetilde{\text{eq}}(p', r_p)$. For each sparse entry $(p, s)$, we need the Lagrange coefficient $\widetilde{\text{eq}}(p, r_p)$ to weight its contribution to $H[s]$.

(The function $\widetilde{\text{eq}}$ is the "equality polynomial" that extracts a specific Boolean point's contribution to an MLE. We'll define it formally in the Spartan section below; for now, just think of it as the multilinear Lagrange basis function.)

A naive approach computes each $\widetilde{\text{eq}}(p, r_p)$ independently in $O(n/2)$ field ops, giving $O(T \cdot n)$ total. But we can do better: precompute *all* $2^{n/2}$ values $\widetilde{\text{eq}}(p, r_p)$ for every Boolean $p$ in $O(2^{n/2})$ time using the product structure of $\widetilde{\text{eq}}$. Then each sparse entry requires only a table lookup plus one multiplication. Total: $O(2^{n/2})$ for precomputation, $O(T)$ for the pass over sparse entries.

Run the dense halving algorithm on $H$ and $Q$ for the remaining $n/2$ rounds. Time: $O(2^{n/2})$ for precomputing $\widetilde{\text{eq}}$ values, $O(T)$ to accumulate into $H$, plus $O(2^{n/2})$ for the dense sum-check.

**Total.** The structure is two chained sum-checks:

1. **Stage 1** ($n/2$ rounds): proves the sum equals $H$, ends with evaluation claim about $\tilde{P}(r_p)$
2. **Stage 2** ($n/2$ rounds): proves that evaluation claim, ends with evaluation of $\tilde{a}(r_p, r_s)$ and $\tilde{h}(r_s)$

Together: $n/2 + n/2 = n$ rounds, matching the original $n$-variable sum-check. But prover work is only:
$$O(T + 2^{n/2})$$

Two passes over $T$ sparse terms (one per stage), plus two $2^{n/2}$-sized dense sum-checks. With appropriate parameters, this can be much less than $O(2^n)$.

### Worked Example: Sparse Sum with $N = 16$, $T = 3$

Consider a table of size $N = 16$ (so $n = 4$ variables), but only $T = 3$ entries are non-zero. We want to prove:
$$H = \sum_{(p, s) \in \{0,1\}^4} \tilde{a}(p, s) \cdot \tilde{f}(p) \cdot \tilde{h}(s)$$

where $p = (x_1, x_2)$ is the 2-bit prefix and $s = (x_3, x_4)$ is the 2-bit suffix.

**The sparse data.** Suppose the only non-zero entries are:

| Index | Prefix $p$ | Suffix $s$ | $\tilde{a}(p,s)$ | $\tilde{f}(p)$ | $\tilde{h}(s)$ | Product |
|-------|------------|------------|------------------|----------------|----------------|---------|
| 5 | $(0,1)$ | $(0,1)$ | 3 | 2 | 4 | 24 |
| 9 | $(1,0)$ | $(0,1)$ | 5 | 1 | 4 | 20 |
| 14 | $(1,1)$ | $(1,0)$ | 2 | 3 | 7 | 42 |

True sum: $H = 24 + 20 + 42 = 86$.

**Dense approach (bad).** Store all 16 entries, fold arrays of size 16 → 8 → 4 → 2 → 1. Touches all 16 positions even though 13 are zero.

**Sparse two-stage approach (good).**

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

**Building $H$ via $\widetilde{\text{eq}}$ precomputation.** First, precompute the Lagrange table for all 4 Boolean prefixes:

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

> **Remark: Multilinear vs. Univariate Encodings.**
> This multilinear view differs fundamentally from the QAP approach in Chapter 12 (Groth16). There, R1CS matrices become univariate polynomials via Lagrange interpolation over roots of unity. The constraint $Az \circ Bz = Cz$ transforms into a polynomial divisibility condition: $A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$, where $Z_H$ is the vanishing polynomial over the evaluation domain. Proving satisfaction means exhibiting the quotient $H(X)$.
>
> Spartan takes a different path. Instead of interpolating over roots of unity, it interprets vectors and matrices as multilinear extensions over the Boolean hypercube. Instead of checking divisibility by a vanishing polynomial, it checks that an error polynomial evaluates to zero on all Boolean inputs, via sum-check. No quotient polynomial, no FFT, no roots of unity. Just multilinear algebra and sum-check.
>
> Both approaches reduce R1CS to polynomial claims. QAP reduces to divisibility; Spartan reduces to vanishing on the hypercube. The sum-check approach avoids the $O(n \log n)$ FFT costs and the trusted setup of pairing-based SNARKs, at the cost of larger proofs (logarithmic in the constraint count rather than constant).

### The Zero-on-Hypercube Reduction

Here is Spartan's key insight: checking that $g$ vanishes on the Boolean hypercube reduces to a single sum-check. The technique works for any polynomial, not just R1CS errors.

**The problem:** We want to verify that $g(x) = 0$ for all $x \in \{0,1\}^{\log m}$.

**The reduction:** Sample random $\tau \in \mathbb{F}^{\log m}$ and check:
$$\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$$

**The equality polynomial.** The function $\widetilde{\text{eq}}: \mathbb{F}^n \times \mathbb{F}^n \to \mathbb{F}$ (previewed in the sparse sum-check section above) is defined as:
$$\widetilde{\text{eq}}(\tau, x) = \prod_{i=1}^{n} \left(\tau_i x_i + (1-\tau_i)(1-x_i)\right)$$

Think of $\widetilde{\text{eq}}$ as Lagrange interpolation in disguise. It creates a function that equals 1 at exactly one Boolean point and 0 at all others. When $\tau$ is Boolean, $\widetilde{\text{eq}}(\tau, x)$ is 1 if $x = \tau$ and 0 for every other Boolean $x$. When $\tau$ is a general field element, $\widetilde{\text{eq}}(\tau, x)$ smoothly interpolates, giving the coefficients needed to "select" any value from a table.

Each factor is linear in both $\tau_i$ and $x_i$. On Boolean inputs, the factor equals 1 when $\tau_i = x_i$ (both 0 or both 1) and equals 0 when they differ. On non-Boolean inputs, the factor interpolates smoothly; for instance, $\tau_i x_i + (1-\tau_i)(1-x_i)$ at $(\tau_i, x_i) = (2, 0)$ gives $0 + (-1)(1) = -1$.

**The key observation:** When both inputs are Boolean, the product equals $\mathbf{1}[\tau = x]$, the indicator function that is 1 if and only if $\tau = x$, and 0 otherwise. But the formula extends smoothly to all field elements. This is precisely the multilinear extension of the equality indicator over $\{0,1\}^n \times \{0,1\}^n$.

**A small example.** Take $n = 2$. We have $\widetilde{\text{eq}}((\tau_1, \tau_2), (x_1, x_2)) = (\tau_1 x_1 + (1-\tau_1)(1-x_1)) \cdot (\tau_2 x_2 + (1-\tau_2)(1-x_2))$.

Evaluate at $\tau = (2, 3)$ for each Boolean $x$:

- $\widetilde{\text{eq}}((2,3), (0,0)) = (0 + (-1)(-1)) \cdot (0 + (-2)(-1)) = 1 \cdot 2 = 2$
- $\widetilde{\text{eq}}((2,3), (0,1)) = (0 + (-1)(-1)) \cdot (3 + 0) = 1 \cdot 3 = 3$
- $\widetilde{\text{eq}}((2,3), (1,0)) = (2 + 0) \cdot (0 + (-2)(-1)) = 2 \cdot 2 = 4$
- $\widetilde{\text{eq}}((2,3), (1,1)) = (2 + 0) \cdot (3 + 0) = 2 \cdot 3 = 6$

Notice these sum to $2 + 3 + 4 + 6 = 15 \neq 1$. The equality polynomial doesn't form a partition of unity when $\tau$ is non-Boolean, but it doesn't need to. What matters is the next property.

**The key identity.** For any function $f: \{0,1\}^n \to \mathbb{F}$ with multilinear extension $\tilde{f}$:
$$\sum_{x \in \{0,1\}^n} \widetilde{\text{eq}}(\tau, x) \cdot f(x) = \tilde{f}(\tau)$$

This is the MLE evaluation formula from Chapter 4: the sum "selects" the value at $\tau$ via weighted interpolation. When $\tau$ is Boolean, exactly one term survives (weight 1, all others 0). When $\tau$ is a general field element, all $2^n$ terms contribute with the appropriate interpolation weights.

**Why not just sum $g$ directly?** A natural first attempt: prove $\sum_{x \in \{0,1\}^n} g(x) = 0$ via sum-check. If $g$ vanishes on the hypercube, this sum is indeed zero. But the converse fails: the sum can be zero even when $g$ doesn't vanish everywhere. For instance, if $g(0,0) = 5$ and $g(0,1) = -5$ with $g(1,0) = g(1,1) = 0$, then $\sum_x g(x) = 0$ despite $g$ being nonzero at two points. The positive and negative values cancel.

The equality polynomial fixes this. By weighting each term with a random coefficient $\widetilde{\text{eq}}(\tau, x)$, cancellation becomes overwhelmingly unlikely.

**Why the reduction works.** The sum $\sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x)$ is a random linear combination of the values $\{g(x)\}_{x \in \{0,1\}^n}$. The coefficients $\widetilde{\text{eq}}(\tau, x)$ depend on the random challenge $\tau$, and for random $\tau$, these coefficients are essentially random field elements.

If all $g(x) = 0$, the sum is trivially zero. But if even one $g(x^*) \neq 0$, the sum becomes a random linear combination with at least one nonzero term. Such a combination equals zero only when the coefficients "conspire" to cancel, an event with negligible probability over random $\tau$.

More precisely: define $Q(\tau) = \sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x)$. By the key identity, $Q(\tau) = \tilde{g}(\tau)$, the multilinear extension of $g$ evaluated at $\tau$. This polynomial $Q$ has degree at most $n$ (one per variable).

- If $g(x) = 0$ for all $x \in \{0,1\}^n$, then $\tilde{g}$ is the zero polynomial, so $Q(\tau) = 0$ for all $\tau$.
- If some $g(x^*) \neq 0$, then $\tilde{g}$ is a nonzero polynomial of degree at most $n$. By Schwartz-Zippel, $Q(\tau) \neq 0$ for random $\tau$ with probability $\geq 1 - n/|\mathbb{F}|$.

This reduces "check $g$ vanishes on $2^n$ points" to "run sum-check on one random linear combination and verify it equals zero."

### The Sum-Check Protocol

1. **Verifier sends** random $\tau \in \mathbb{F}^{\log m}$
2. **Prover claims** $\sum_{x \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$, where $g(x) = \left(\sum_y \tilde{A}(x, y) \tilde{z}(y)\right) \cdot \left(\sum_y \tilde{B}(x, y) \tilde{z}(y)\right) - \sum_y \tilde{C}(x, y) \tilde{z}(y)$
3. **Run sum-check** on this claim

At the end, the verifier holds a random point $r \in \mathbb{F}^{\log m}$ and needs to evaluate $g(r)$. This requires:

- $\sum_y \tilde{A}(r, y) \tilde{z}(y)$, $\sum_y \tilde{B}(r, y) \tilde{z}(y)$, $\sum_y \tilde{C}(r, y) \tilde{z}(y)$

Each of these is itself a sum over the hypercube, requiring three more sum-checks! But now the sums are over $y$, and the polynomials have the form $\tilde{M}(r, y) \cdot \tilde{z}(y)$ for the fixed $r$ from the outer sum-check.

**The reduction chain.** After running these three inner sum-checks (which can be batched into one using random linear combinations), the verifier holds a random point $s \in \mathbb{F}^{\log n}$ and needs to check:

- $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$: evaluations of the matrix MLEs
- $\tilde{z}(s)$: evaluation of the witness MLE

The matrix evaluations are handled by SPARK (below). The witness evaluation $\tilde{z}(s)$ is where polynomial commitments enter: the prover opens the committed $\tilde{z}$ at the random point $s$, and the verifier checks the opening proof.

This is the full reduction: R1CS satisfaction → zero-on-hypercube (outer sum-check) → matrix-vector products (inner sum-checks) → point evaluations (polynomial commitment openings).

### Handling Sparse Matrices: SPARK

We've reduced R1CS to sum-check, but there's a lingering problem: the matrices $A$, $B$, $C$ are $m \times n$, potentially huge. A dense representation costs $O(mn)$ space, and committing to them naively would dominate the entire protocol.

But R1CS matrices are sparse. A circuit with $m$ constraints typically has only $O(m)$ non-zero entries total, not $O(mn)$. Can we exploit this?

**The sparse representation.** A sparse matrix with $T$ non-zero entries can be stored as a list of $(i, j, v)$ tuples: row index, column index, value. This costs $O(T)$ space instead of $O(mn)$.

**The evaluation problem.** At the end of the inner sum-checks, the verifier needs the matrix MLE evaluations $\tilde{A}(r, s)$, $\tilde{B}(r, s)$, $\tilde{C}(r, s)$ at random points $(r, s) \in \mathbb{F}^{\log m} \times \mathbb{F}^{\log n}$. How do we compute these from the sparse representation?

The MLE of a matrix $M$ evaluated at $(r_x, r_y)$ is:
$$\tilde{M}(r_x, r_y) = \sum_{(i,j) \in \{0,1\}^{\log m} \times \{0,1\}^{\log n}} M(i,j) \cdot \widetilde{\text{eq}}(i, r_x) \cdot \widetilde{\text{eq}}(j, r_y)$$

Since $M(i,j) = 0$ for most entries, this simplifies to a sum over only the $T$ non-zero entries:
$$\tilde{M}(r_x, r_y) = \sum_{(i,j): M(i,j) \neq 0} M(i,j) \cdot \widetilde{\text{eq}}(i, r_x) \cdot \widetilde{\text{eq}}(j, r_y)$$

**The naive cost.** For each non-zero entry $(i, j, v)$, we need $\widetilde{\text{eq}}(i, r_x)$ and $\widetilde{\text{eq}}(j, r_y)$. Computing $\widetilde{\text{eq}}(i, r_x)$ directly from the formula $\prod_k (i_k \cdot (r_x)_k + (1-i_k)(1-(r_x)_k))$ costs $O(\log m)$. Over $T$ entries, total cost: $O(T \log m)$.

**SPARK's insight.** Spartan introduces **SPARK** (Sparse Polynomial Arithmetic via Randomized Kernels) to reduce this to $O(T)$. The trick: precompute lookup tables.

1. **Precompute row weights.** Build a table $E_{\text{row}}[i] = \widetilde{\text{eq}}(i, r_x)$ for all $i \in \{0,1\}^{\log m}$. This costs $O(m)$ using the standard MLE evaluation algorithm (stream through bit-vectors, accumulate products).

2. **Precompute column weights.** Build a table $E_{\text{col}}[j] = \widetilde{\text{eq}}(j, r_y)$ for all $j \in \{0,1\}^{\log n}$. Cost: $O(n)$.

3. **Evaluate via lookups.** Initialize a running sum to zero. For each non-zero entry $(i, j, v)$, look up $E_{\text{row}}[i]$ and $E_{\text{col}}[j]$, then add $v \cdot E_{\text{row}}[i] \cdot E_{\text{col}}[j]$ to the running sum. After processing all $T$ entries, the sum equals $\tilde{M}(r_x, r_y)$. Cost: $O(T)$.

Total: $O(m + n + T)$, linear in the sparse representation size.

**But who checks the lookups?** The prover claims to have looked up the correct values, but the verifier can't check this directly without the full tables. SPARK uses a memory-checking argument to verify consistency.

Here's the intuition. Think of $E_{\text{row}}$ as a read-only memory with $m$ cells. The prover reads from this memory $T$ times, once per sparse entry. Each read is a pair $(\text{addr}_k, v_k)$: "I read value $v_k$ from address $\text{addr}_k$." The prover collects all $T$ reads into a list.

Now the key observation: if every read is honest, then the multiset of reads must be consistent with the memory contents. Concretely, if address $i$ appears $c_i$ times in the reads, the claimed values at those positions must all equal $E_{\text{row}}[i]$. A cheating prover who claims a wrong value creates an inconsistency.

To check this efficiently, both the reads and the memory contents are encoded as polynomials. The verifier picks a random challenge and checks that a certain polynomial identity holds. This identity essentially compares "fingerprints" of the read list versus the memory. If any read is incorrect, the fingerprints mismatch with high probability over the random challenge.

We'll develop this memory-checking technique fully in Chapter 20. For now, the key point is that it adds only $O(\log T)$ to proof size and verification time, preserving SPARK's linear prover efficiency.

### The Full Protocol

Putting it together, Spartan proceeds as follows:

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

> **Remark (UniSkip).** Spartan's outer sum-check can skip the first round entirely using a technique called UniSkip. The idea: Spartan indexes constraints symmetrically over $\{-N, \ldots, N\}$ rather than $\{0, \ldots, 2N\}$. When summing the first-round polynomial $s_1(X)$ over this symmetric domain, odd-degree terms cancel (for every $+i$ there's a $-i$). The sum depends only on even-degree coefficients, which the verifier can check using precomputed power sums $\sigma_k = \sum_{i=-N}^{N} i^k$. The prover sends the full polynomial; the verifier computes the sum via a dot product with the power sums, then samples a random challenge and continues with round 2. This saves one round of interaction and enables prover optimizations from the symmetric structure.

With $T$ non-zero matrix entries, total prover work is $O(m + n + T)$, linear in the instance size. No trusted setup is required when using IPA or FRI as the polynomial commitment.

### Why This Matters

Step back and consider what we've built. Spartan proves R1CS satisfaction, the standard constraint system for zkSNARKs, using only sum-check and polynomial commitments. No univariate polynomial encodings (like PLONK's permutation argument). No pairing-based trusted setup (like Groth16). No PCP constructions (like early STARKs).

The architecture is minimal: multilinear polynomials, sum-check, commitment scheme. Three ideas, combined cleanly. This simplicity is not merely aesthetic. It's the reason Spartan became the template for subsequent systems. Lasso added lookup arguments; Jolt extended further to prove virtual machine execution. Each built on the same foundation.

Notice the graph structure emerging. Spartan has two levels: an outer sum-check (over constraints) and inner sum-checks (over matrix-vector products). The outer sum-check ends with a claim; the inner sum-checks prove that claim. This is exactly the depth-two graph from the remark at the chapter's start. More complex protocols like Lasso (for lookups) and Jolt (for full RISC-V execution) extend this graph to dozens of nodes across multiple stages, but the pattern remains: sum-checks reducing claims to other sum-checks, bottoming out at committed polynomials.

When a construction is this simple, it becomes a building block for everything that follows.



## The PCP Detour and Sum-Check's Return

Now that we've seen Spartan's elegance (sum-check plus commitments, nothing more) the historical question becomes pressing: how did the field spend two decades missing this?

The answer involves one of cryptography's most instructive wrong turns.

### The Road Not Taken

In 1990, sum-check arrived. Two years later, the PCP theorem landed: every NP statement has a proof checkable by reading only a constant number of bits. *Constant* query complexity. This was astonishing, and it captured the field's imagination completely.

The PCP theorem seemed to obsolete sum-check. Why settle for logarithmic verification when you could have constant-query verification? Kilian showed how to compile PCPs into succinct arguments: commit to the PCP via Merkle tree, let the verifier query random locations, authenticate responses with hash paths. This became *the* template for succinct proofs. Systems like Pepper, Ginger, and early Pinocchio drew on PCP-derived constructions.

Sum-check faded into the background, remembered as a stepping stone rather than a destination.

### The Unnecessary Indirection

Here's what everyone missed: a logical error hiding in plain sight.

The PCP theorem transforms an interactive proof into a *static* proof string that the verifier can query non-adaptively. The prover writes down the entire PCP upfront; the verifier reads random locations without talking to the prover. Interaction removed.

But a PCP string is enormous, polynomial in the computation size. To make it succinct, Kilian's construction has the prover commit to the PCP via a Merkle tree, then the verifier interactively requests random query locations, and the prover reveals those locations with authentication paths. Interaction reintroduced.

To deploy in practice, you apply Fiat-Shamir to make Kilian's protocol non-interactive. Interaction removed again.

Count the transformations: IP → PCP (remove interaction) → Kilian argument (add interaction back) → Fiat-Shamir (remove interaction again).

Two removals of interaction. One obviously redundant. If Fiat-Shamir handles the final step anyway, why go through the PCP at all? Why not apply Fiat-Shamir directly to the original interactive proof, the one based on sum-check?

For twenty years, this question hung in the air, unanswered.

### The Return

Starting around 2018, the answer finally arrived. The missing pieces had fallen into place: fast proving algorithms (the halving trick, sparse sums) and efficient polynomial commitment schemes (KZG, FRI, IPA) that could handle multilinear polynomials directly.

A wave of systems returned to the source:

- **Hyrax** (2018), **Libra** (2019): early sum-check-based SNARKs with linear-time provers
- **Spartan** (2020): sum-check for R1CS without trusted setup
- **HyperPlonk** (2023): sum-check meets Plonkish arithmetization
- **Lasso/Jolt** (2023-24): sum-check plus lookup arguments for zkVMs
- **Binius** (2024): sum-check over binary fields
- **HybridPlonk** (2025): sublogarithmic proof size with linear-time prover

The pattern is consistent:

1. Sum-check as the core interactive proof
2. Polynomial commitments for cryptographic binding
3. Fiat-Shamir applied once

No PCP construction. No double removal. No enormous proof strings that need to be Merkle-hashed and then re-interactivized. The resulting systems are simpler, faster, and closer to optimal, with prover times within a small constant factor of computing the witness itself.

The detour lasted twenty years. The destination was where we started. Sometimes the most powerful technique is the one that was always there, waiting to be taken seriously.



## Application: The Hadamard Product Constraint

The Spartan construction involves R1CS matrices, inner/outer sum-checks, and SPARK. Let's strip away that complexity and see the core ideas in isolation: the zero-on-hypercube reduction (using $\widetilde{\text{eq}}$ to convert "vanishes everywhere" into a single sum) and the halving trick for $O(N)$ proving. No sparsity here, just the dense case.

**Problem.** Given committed vectors $a, b, c \in \mathbb{F}^N$ (where $N = 2^n$), prove that $a \circ b = c$, the entrywise product.

This constraint appears everywhere: multiplication gates in arithmetic circuits, quadratic constraints in R1CS, polynomial products in PLONK. It's the core building block that Spartan lifts to full R1CS.

### The Reduction

Define the error polynomial:
$$g(x) = \tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x)$$

where $\tilde{a}, \tilde{b}, \tilde{c}$ are multilinear extensions. (Note that $g$ is not itself multilinear since the product $\tilde{a} \cdot \tilde{b}$ has degree 2, so we write $g$ without the tilde.)

The constraint $a \circ b = c$ holds if and only if $g(x) = 0$ for all $x \in \{0,1\}^n$.

Using the zero-on-hypercube reduction from Spartan, sample random $r \in \mathbb{F}^n$ and check:
$$\sum_{x \in \{0,1\}^n} \widetilde{\text{eq}}(r, x) \cdot g(x) = 0$$

If any $g(x) \neq 0$, this sum is nonzero with high probability (Schwartz-Zippel).

### The Protocol

1. Verifier sends random $r \in \mathbb{F}^n$
2. Prover claims $H = 0$ (the sum should be zero)
3. Parties run sum-check on $\sum_x \widetilde{\text{eq}}(r, x) \cdot g(x) = 0$
4. At the end, the verifier holds a random point $z = (z_1, \ldots, z_n)$ and a claimed final value $v_{\text{final}}$ from the last round of sum-check
5. Prover opens $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$ via polynomial commitments
6. Verifier computes $\widetilde{\text{eq}}(r, z) \cdot (\tilde{a}(z) \cdot \tilde{b}(z) - \tilde{c}(z))$ and checks that it equals $v_{\text{final}}$

The final check is the sum-check reduction endpoint: the verifier directly evaluates the polynomial being summed at the random point $z$ and confirms it matches what the prover claimed during the protocol.

### Prover Efficiency

The polynomial being summed is:
$$\widetilde{\text{eq}}(r, x) \cdot (\tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x))$$

This is a product of multilinear polynomials. The halving trick applies directly:

- Store tables for $\widetilde{\text{eq}}(r, \cdot)$, $\tilde{a}$, $\tilde{b}$, $\tilde{c}$ (or compute on the fly)
- Fold all four tables after each round

Total prover time: $O(N)$, linear in the constraint size.

### Worked Example: Hadamard Product with $N = 4$

Let $n = 2$ and consider vectors of length 4:

| Index $(b_1, b_2)$ | $a$ | $b$ | $c = a \circ b$ |
|--------------------|-----|-----|-----------------|
| $(0, 0)$ | 2 | 3 | 6 |
| $(0, 1)$ | 4 | 2 | 8 |
| $(1, 0)$ | 1 | 5 | 5 |
| $(1, 1)$ | 3 | 1 | 3 |

We want to prove $a \circ b = c$ via sum-check.

**Step 1: Verifier sends random challenge $r = (r_1, r_2) = (2, 3)$.**

**Step 2: Compute $\widetilde{\text{eq}}(r, x)$ for all $x \in \{0,1\}^2$.**

The equality polynomial is $\widetilde{\text{eq}}(r, x) = \prod_i (r_i x_i + (1-r_i)(1-x_i))$.

- $\widetilde{\text{eq}}((2,3), (0,0)) = (1-2)(1-3) = (-1)(-2) = 2$
- $\widetilde{\text{eq}}((2,3), (0,1)) = (1-2)(3) = (-1)(3) = -3$
- $\widetilde{\text{eq}}((2,3), (1,0)) = (2)(1-3) = (2)(-2) = -4$
- $\widetilde{\text{eq}}((2,3), (1,1)) = (2)(3) = 6$

**Step 3: Compute $g(x) = \tilde{a}(x) \cdot \tilde{b}(x) - \tilde{c}(x)$ on Boolean inputs.**

Since $c = a \circ b$ is correct, $g(x) = 0$ for all $x \in \{0,1\}^2$:

- $g(0,0) = 2 \cdot 3 - 6 = 0$
- $g(0,1) = 4 \cdot 2 - 8 = 0$
- $g(1,0) = 1 \cdot 5 - 5 = 0$
- $g(1,1) = 3 \cdot 1 - 3 = 0$

**Step 4: The claimed sum.**

$$H = \sum_{x \in \{0,1\}^2} \widetilde{\text{eq}}(r, x) \cdot g(x) = 2 \cdot 0 + (-3) \cdot 0 + (-4) \cdot 0 + 6 \cdot 0 = 0$$

Prover claims $H = 0$. This is correct because $a \circ b = c$.

**Step 5: Run sum-check protocol.**

**Round 1:** The prover computes $s_1(X_1)$ by summing over $X_2 \in \{0,1\}$:
$$s_1(X_1) = \sum_{x_2 \in \{0,1\}} \widetilde{\text{eq}}((2,3), (X_1, x_2)) \cdot g(X_1, x_2)$$

Since $g$ is zero on Boolean inputs, the degree-3 polynomial $s_1(X_1)$ satisfies $s_1(0) + s_1(1) = 0$. The prover sends four evaluations $s_1(0), s_1(1), s_1(2), s_1(3)$ to specify this degree-3 polynomial (degree bound is 3: $\widetilde{\text{eq}}$ is degree 1, times $\tilde{a} \cdot \tilde{b}$ which is degree 2, giving degree 3 total).

*Technique: The prover computes $s_1$ by iterating over all $N = 4$ table entries once, $O(N)$ work for this round.*

**Round 2:** After receiving challenge $z_1$, fold all four arrays using the halving trick from earlier in this chapter: $A'[x_2] = (1-z_1) \cdot A[0, x_2] + z_1 \cdot A[1, x_2]$, and similarly for $B$, $C$, and the $\widetilde{\text{eq}}$ table. Then compute $s_2(X_2)$ from the folded arrays. The verifier checks $s_2(0) + s_2(1) = s_1(z_1)$.

*Technique: Halving trick. After folding, the four tables of size 4 become four tables of size 2. Computing $s_2$ requires $O(N/2) = O(2)$ work. Total across both rounds: $O(4 + 2) = O(N)$, not $O(N \log N)$.*

**Final check:** The verifier holds point $z = (z_1, z_2)$ and value $s_2(z_2)$. The prover opens $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$. The verifier checks:
$$\widetilde{\text{eq}}(r, z) \cdot (\tilde{a}(z) \cdot \tilde{b}(z) - \tilde{c}(z)) \stackrel{?}{=} s_2(z_2)$$

*Technique: Polynomial commitment opening. The prover uses the PCS to prove the three evaluations. The verifier checks the opening proofs (cost depends on PCS) and computes $\widetilde{\text{eq}}(r, z)$ directly in $O(\log N) = O(2)$ field multiplications.*

**Why this catches cheating.** The left-hand side is just $f(z)$, the polynomial being summed, evaluated at the random point $z$. The right-hand side $s_2(z_2)$ is what the prover *claimed* this value would be during the sum-check protocol.

The sum-check protocol guarantees: if the prover's claimed sum $H$ was correct, and all the round polynomials $s_1, s_2$ were consistent, then the final claimed value $s_2(z_2)$ must equal $f(z)$. If the prover lied anywhere (wrong sum, wrong round polynomial) the equality fails with high probability over the random challenges $z_1, z_2$.

*Technique: Schwartz-Zippel. If $a \circ b \neq c$, then some $g(x) \neq 0$ for at least one Boolean $x$. The random linear combination $H = \sum_x \widetilde{\text{eq}}(r, x) \cdot g(x)$ is nonzero with high probability over the random choice of $r$. A cheating prover claiming $H = 0$ when $H \neq 0$ will be caught by sum-check's final verification.*

**Work summary:**

| Step | Prover | Verifier | Technique |
|------|--------|----------|-----------|
| Round 1 | $O(N)$ | $O(d)$ | Direct summation over tables |
| Round 2 | $O(N/2)$ | $O(d)$ | Halving trick (folded tables) |
| Final check | PCS-dependent | $O(\log N)$ + PCS | Polynomial commitment opening |
| **Total** | $O(N)$ | $O(\log N)$ + PCS | Geometric series: $N + N/2 + \ldots = O(N)$ |



## Reducing the Final Evaluation Cost

Every sum-check protocol ends the same way: the verifier holds a random point $z$ and needs to check that $g(z)$ equals some claimed value. We've deferred this question throughout the chapter. Now it's time to address it directly.

If $g = \tilde{a} \cdot \tilde{b} - \tilde{c}$, then $g(z)$ requires knowing $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$.

**Without commitments:** Evaluating $\tilde{a}(z)$ from the coefficient representation takes $O(2^n)$ time, as expensive as the original sum.

**With commitments:** The polynomial commitment scheme handles this. The prover provides evaluation proofs for $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$. The verifier checks these proofs (typically in time logarithmic or constant, depending on the PCS) and computes $g(z)$ with three field operations.

This is where polynomial commitments earn their keep: they shift the final evaluation burden from direct computation to cryptographic verification.

### Batching

When sum-check produces multiple evaluation queries at the same point (like $\tilde{a}(z), \tilde{b}(z), \tilde{c}(z)$) batch evaluation arguments reduce proof size and verification time. Instead of three opening proofs, a single batched proof suffices.

Chapter 20 develops these batch techniques.



## The Streaming Model

For truly massive computations ($N = 2^{40}$ terms), even $O(N)$ memory becomes prohibitive. That's a terabyte of field elements. The prefix-suffix decomposition opens an unexpected door: **streaming provers** that use sublinear memory.

**Definition.** A streaming prover processes the non-zero terms in sequential passes, using memory sublinear in $N$.

With $c$ chunks:

- Passes: $c$
- Memory: $O(N^{1/c})$

For $c = 2$: two passes, $O(\sqrt{N})$ memory. When $N = 2^{40}$, this means ~$2^{20}$ memory instead of $2^{40}$, a million-fold reduction.

Streaming provers differ from recursive SNARKs. Recursion proves proofs of proofs, adding cryptographic overhead at each level. Streaming exploits the algebraic structure of sum-check directly, without recursion.



## Key Takeaways

### Core Techniques

1. **The halving trick achieves $O(N)$ prover time.** Naive sum-check costs $O(N \log N)$ because each of $\log N$ rounds recomputes $N$ terms. The halving trick folds evaluation tables after each round: $N \to N/2 \to N/4 \to \ldots$ Total work: $N + N/2 + N/4 + \ldots = O(N)$.

2. **Folding relies on the hybrid evaluation property.** For multilinear $\tilde{f}$: evaluating at $(r, x_2, \ldots, x_n)$ is a linear combination of evaluations at $(0, x_2, \ldots)$ and $(1, x_2, \ldots)$. This lets the prover collapse a table of size $N$ into size $N/2$ with $O(N)$ field operations.

3. **Sparse sums via prefix-suffix decomposition.** Factor $\widetilde{\text{eq}}(\tau, x) = \widetilde{\text{eq}}(\tau_{\text{prefix}}, x_{\text{prefix}}) \cdot \widetilde{\text{eq}}(\tau_{\text{suffix}}, x_{\text{suffix}})$. Precompute suffix contributions, then stream through non-zero terms. Cost: $O(T + \sqrt{N})$ for $T$ non-zeros with two passes and $O(\sqrt{N})$ memory.

4. **Batching avoids linear blowup.** When sum-check produces $k$ evaluation queries, don't run $k$ separate protocols. Combine with random coefficients: $\sum_i \rho_i \cdot \text{claim}_i$. One sum-check suffices; soundness follows from Schwartz-Zippel.

### Spartan's Architecture

5. **Zero-on-hypercube reduction.** To prove $g(x) = 0$ for all $x \in \{0,1\}^n$, prove instead that $\sum_x \widetilde{\text{eq}}(\tau, x) \cdot g(x) = 0$ for random $\tau$. The $\widetilde{\text{eq}}$ polynomial acts as a random linear combination of the constraints: if any constraint fails, the sum is nonzero with high probability (Schwartz-Zippel).

6. **R1CS reduces to two sum-checks.** Outer sum-check handles the zero-on-hypercube claim (prover: $O(m)$, halving trick). Inner sum-check handles matrix-vector products (prover: $O(n)$, halving trick + batching). Total: $O(m + n)$ for the interactive protocol.

7. **SPARK achieves $O(T)$ for sparse matrices.** Precompute $\widetilde{\text{eq}}(i, r)$ tables for all row/column indices in $O(m + n)$. Then each of $T$ non-zero entries requires only table lookups, with no per-entry logarithmic cost. Memory-checking fingerprints verify correctness.

### The Full Pipeline

8. **Sum-check reduces verification to evaluation.** After $\log N$ rounds, the verifier holds a random point $z$ and a claimed value $v$. All that remains: check that $f(z) = v$ for the polynomial $f$ being summed.

9. **Polynomial commitments handle evaluations.** The prover opens the committed polynomial at $z$; the verifier checks the opening proof. This is where cryptographic hardness enters, since sum-check itself is information-theoretic.

10. **Streaming provers trade passes for memory.** With $c$ passes, memory drops to $O(N^{1/c})$. At $c = 2$: two passes, $O(\sqrt{N})$ memory. This exploits sum-check's algebraic structure directly, without recursive proof composition.

### Historical Perspective

11. **The PCP detour cost two decades.** The path IP → PCP → Kilian → Fiat-Shamir removes interaction, reintroduces it, then removes it again. The direct path (sum-check + Fiat-Shamir) skips the redundant steps. Modern systems (Spartan, Lasso, Jolt, Binius) follow the direct path and achieve prover times within small constants of witness computation.





\newpage

# Chapter 20: Minimizing Commitment Costs

> *This chapter lives at the frontier. The techniques here, some from papers published in 2024 and 2025, represent the current edge of what's known about fast proving. We assume comfort with polynomial commitments (Chapter 9), sum-check (Chapter 3), and the memory checking ideas from Chapter 14. First-time readers may find themselves reaching for earlier chapters often; that's expected. The reward for persisting is a view of how the fastest SNARKs actually work.*

In 2023, the Jolt team profiled their zkVM and found something disturbing. The prover was "linear time." The sum-check was optimal. Yet proving a simple program took 30 seconds when naive arithmetic suggested it should take 3.

The culprit: polynomial commitments. Specifically, multi-scalar multiplications (MSMs): computing $\sum_i s_i \cdot G_i$ where each $s_i$ is a scalar and each $G_i$ is an elliptic curve point. The prover was computing millions of group exponentiations, each one costing thousands of field operations. All the careful sum-check optimization was irrelevant; the cryptography swallowed everything.

This is the trap that ensnares SNARK designers. You optimize the proving algorithm to touch each constraint once. You achieve the theoretical minimum field operations. Then you discover that committing to the polynomials takes 10× longer than proving anything about them.

A single elliptic curve exponentiation costs roughly 3,000 field multiplications. An MSM over $N$ points costs about $N/\log N$ exponentiations. For a polynomial of degree $10^6$, commitment alone requires $\approx 3 \times 10^8$ field operations. If your proving algorithm runs in $10^7$ operations, the commitment is the bottleneck. By a lot.

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

- *Folding.* In Nova (Chapter 22), the accumulated instance is virtual. Each fold updates a claim about what could be verified (not data sitting in memory).

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

For the verifier, something remarkable happens. The verification circuit depends only on $m = \log_2(M)$ (the log of total trace area), not on the individual table heights $h_y$. Whether the trace has 100 tables of equal size or 100 tables of wildly varying sizes, the verifier does the same work.

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

**The core insight:**
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




\newpage

# Chapter 21: The Two Classes of PIOPs

Every modern SNARK, stripped to its essence, follows the same recipe: a Polynomial Interactive Oracle Proof (PIOP), compiled with a Polynomial Commitment Scheme (PCS), made non-interactive via Fiat-Shamir. The PIOP provides information-theoretic security: it would be sound even against unbounded provers if the verifier could magically check polynomial evaluations. The PCS adds cryptographic binding. Fiat-Shamir removes interaction.

But within this unifying framework, two distinct philosophies have emerged. They use different polynomial types, different domains, different proof strategies. They lead to systems with different performance profiles.

Understanding when to use which is not academic curiosity; it's essential for SNARK system design.

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

The verifier computes $Z_H(r) = r^N - 1$ in $O(\log N)$ time via repeated squaring. This simple structure, an accident of multiplicative group theory, makes quotienting practical. Chapter 13 develops this further: roots of unity also enable FFT-based polynomial arithmetic and the shift structure essential for accumulator checks.

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

For read-only tables (like bytecode or lookup tables), $f(k)$ is fixed. For read-write memory (like registers or RAM), $f(k)$ becomes $f(k, j)$: the value at cell $k$ at time $j$, reconstructed from the history of writes. Chapter 20 shows how this state table can be virtualized: rather than committing to the full $K \times T$ matrix, commit only to write addresses and value increments, then compute the state implicitly via sum-check.

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

**Quotienting excels when structure is fixed and dense.** The quotient polynomial costs $O(N)$ regardless of how many constraints actually matter. FFT runs in $O(N \log N)$ regardless of sparsity. The permutation argument handles any wiring pattern equally. This uniformity is a strength when constraints fill the domain densely and circuit topology is known at compile time. Small circuits with degree-2 or degree-3 constraints, existing infrastructure with optimized KZG and FFT libraries, applications where proof size matters more than prover time: these favor quotienting.

**Sum-check excels when structure is dynamic and sparse.** The prefix-suffix algorithm runs in $O(T)$ for $T$ non-zero terms, ignoring the $N - T$ zeros entirely. Memory checking handles structured access patterns (locality, repeated reads) more efficiently than permutation arguments. Virtual polynomials let you skip commitment entirely for intermediate values. This adaptivity matters for large circuits with billions of gates, memory-intensive computation with lookup arguments and batch evaluation, and zkVMs where the constraint pattern depends on the program being executed.

The wiring story reinforces this. Permutation arguments treat all wire patterns uniformly: a random scramble costs the same as a structured dataflow. Memory checking adapts: tensor decomposition exploits address structure, virtualization skips commitment to state tables, and read-only versus read-write falls out of the same framework.

A useful heuristic: if you know exactly what your circuit looks like at compile time and it fits comfortably in memory, quotienting's simplicity wins. If your circuit's shape depends on runtime data, or if you're pushing toward billions of constraints, sum-check's adaptivity becomes essential.


## Key Takeaways

1. **The core distinction.** Quotienting proves "$Z_H$ divides the error polynomial" via a committed quotient. Sum-check proves "the weighted sum equals zero" via interactive reduction. Same goal, different algebra.

2. **Domain shapes computation.** Roots of unity give FFT and simple $Z_H(X) = X^N - 1$. The Boolean hypercube gives tensor structure and the halving trick. Each domain has algebraic gifts; the proof strategy exploits them.

3. **The quotient is overhead.** Every quotienting proof commits to $Q(X)$. Sum-check needs no extra commitment beyond the original polynomials. For sparse constraints, this difference is dramatic.

4. **Sparsity changes everything.** Quotienting costs $O(N \log N)$ regardless of how many constraints are non-trivial. Sum-check costs $O(T)$ for $T$ non-zero terms. When $T \ll N$, sum-check wins by orders of magnitude.

5. **Wiring has two faces.** Quotienting encodes copy constraints as permutations, verified via a grand product accumulator. Sum-check encodes them as memory access, verified via sparse indicator matrices. Same constraint, different abstractions.

6. **PIOP and PCS co-evolve.** Univariate PIOPs pair with KZG or FRI over roots of unity. Multilinear PIOPs pair with Bulletproofs, Dory, or Hyrax over the hypercube. Mixing paradigms is possible but rarely optimal.

7. **Virtualization is sum-check's superpower.** Any polynomial computable from committed polynomials can be "virtual": defined implicitly, never committed. Quotienting requires explicit commitment to every polynomial that appears in a divisibility check.

8. **The design heuristic.** Fixed circuit, dense constraints, proof size matters: quotienting. Dynamic structure, sparse constraints, prover speed matters: sum-check. Neither dominates; choose based on your bottleneck.



\newpage

# Chapter 22: Composition and Recursion

Could you build a proof system that runs forever? A proof that updates itself every second, attesting to the entire history of a computation, but never growing in size?

The idea sounds impossible. It requires a proof system to verify its own verification logic, to "eat itself." For years, this remained a theoretical curiosity, filed under "proof-carrying data" and assumed impractical.

This chapter traces how the impossible became routine. We start with **composition**: wrapping one proof inside another to combine their strengths. We then reach **recursion**: proofs that verify themselves, enabling unbounded computation with constant-sized attestations. Finally, we arrive at **folding**: a recent revolution that makes recursion cheap by deferring verification entirely. The destination is IVC (incrementally verifiable computation), where proofs grow with time but stay constant-sized. Today's zkEVMs and app-chains are built on this foundation.

No single SNARK dominates all others. Fast provers tend to produce large proofs. Small proofs come from slower provers. Transparent systems avoid trusted setup but sacrifice verification speed. Post-quantum security demands hash-based constructions that bloat proof size. Every deployed system occupies a point in this multi-dimensional trade-off space.

But here's a thought: what if we could *combine* systems? Use a fast prover for the heavy computational lifting, then wrap its output in a small-proof system for efficient delivery to verifiers. Or chain proofs together, where each proof attests to the validity of the previous, enabling unlimited computation with constant verification.

These ideas, **composition** and **recursion**, transform SNARKs from isolated verification tools into composable building blocks. The result is proof systems that achieve properties no single construction could reach alone.

## Composition: Proving a Proof Is Valid

**Composition** means proving that a proof is valid. You have a proof $\pi$ of some statement. Verifying $\pi$ is itself a computation. You can express that verification as a circuit and prove *that* circuit was satisfied. The result: a proof about a proof.

Why do this? Different proof systems have different strengths. A STARK proves quickly but produces a 100KB proof. Groth16 produces a 128-byte proof but proves slowly. What if you could have both: prove quickly with a STARK, then wrap the result in Groth16 for compact delivery?

This is exactly what composition achieves. The STARK handles the heavy lifting (proving the original computation). Groth16 handles the packaging (proving the STARK verifier accepted). The final recipient sees only the tiny Groth16 proof.

### Inner and Outer

The names **inner** and **outer** describe the nesting:

- The **inner proof** is created first. It proves the statement you actually care about ("I executed this program correctly," "I know a secret satisfying this relation").

- The **outer proof** is the wrapper, created second. It proves "I ran the inner verifier and it accepted."

```
Inner: "I know witness w such that C(w) = y"
              ↓ produces
         [Inner Proof π]
              ↓ becomes witness for
Outer: "I verified π and it was valid"
              ↓ produces
         [Outer Proof π']
```

The verifier of the outer proof never sees the inner proof or the original witness. They see only $\pi'$ and check that it's valid. If the outer system is zero-knowledge, nothing leaks about $\pi$ or $w$.

Think of it like nested containers: the inner proof is a large box containing detailed evidence. The outer proof is a small envelope containing a signed attestation that someone trustworthy opened the box and verified its contents. Recipients need only check the signature on the envelope.

### Complementary Strengths

Now let's be precise about what composition can achieve. Imagine two SNARKs:

**Inner SNARK $\mathcal{I}$** (fast prover, large proofs):

- Prover time: $O(|C|)$, linear in circuit size
- Proof size: $O(\sqrt{|C|})$, sublinear but not constant
- Verification time: $O(\sqrt{|C|})$
- Example: STARK-like systems

**Outer SNARK $\mathcal{O}$** (slow prover, tiny proofs):

- Prover time: $O(|C| \log |C|)$, superlinear
- Proof size: $O(1)$, constant
- Verification time: $O(1)$
- Example: Groth16

The composed system $\mathcal{F} = \mathcal{O} \circ \mathcal{I}$ inherits the best of both:

- Prover time close to $\mathcal{I}$'s (fast)
- Proof size close to $\mathcal{O}$'s (tiny)
- Verification time close to $\mathcal{O}$'s (instant)

How does this work?


## The Composition Construction

The key insight: verification is itself a computation, and computations can be proven.

**Step 1: Run the inner prover.** The prover executes $\mathcal{I}$ on the original circuit $C$ with witness $w$, producing proof $\pi_I$. This costs $O(|C|)$ time.

**Step 2: Arithmetize the inner verifier.** The verification algorithm $V_I$ of the inner SNARK is a computation: it reads the proof, performs some checks, outputs accept or reject. Express this verification as a circuit $C_{V_I}$:

- Public inputs: the original statement $x$
- Witness: the inner proof $\pi_I$
- Output: 1 if $V_I$ accepts, 0 otherwise

The verifier circuit $C_{V_I}$ is much smaller than $C$. If $\mathcal{I}$ has $O(\sqrt{|C|})$ verification time, then $|C_{V_I}| = O(\sqrt{|C|})$.

**Step 3: Run the outer prover.** The prover executes $\mathcal{O}$ on the verifier circuit $C_{V_I}$, using the inner proof $\pi_I$ as the witness. This produces the final proof $\pi_O$.

**Step 4: Deliver only the outer proof.** The prover discards $\pi_I$ and sends only $\pi_O$ to the verifier. The inner proof was a means to an end; it never leaves the prover's machine.

**Step 5: Verify.** The end verifier runs $V_O$ on $\pi_O$, a constant-time operation for Groth16-like systems. They never see $\pi_I$.

### Addressing the Obvious Questions

**"Doesn't proving twice defeat the purpose?"**

Yes, the prover does more total work than using either system alone. But the work is *distributed* strategically:

- The expensive part (proving the original $N$-gate circuit) uses the *fast* inner prover: $O(N)$ time.
- The slow outer prover only handles the tiny verifier circuit: $O(\sqrt{N})$ gates.

The outer prover's $O(\sqrt{N} \log \sqrt{N})$ work is negligible compared to the inner prover's $O(N)$. For a million-gate circuit, the inner proof might take 5 seconds; wrapping it takes 0.1 seconds. Total: 5.1 seconds, dominated by the fast system.

**"What about the witness?"**

The original witness $w$ is used only in Step 1. The outer proof's witness is $\pi_I$ (the inner proof), not $w$. The outer system proves "I possess a valid inner proof," not "I know the original witness."

This is crucial: the outer circuit doesn't re-check the original computation. It only checks that $V_I(\pi_I) = \text{accept}$. The witness $w$ is not needed for verification at any stage. It's consumed entirely during inner proving and never appears again. If the application requires revealing $w$ (or parts of it), that's a separate choice; the proof system doesn't require it.

The soundness chain is:

$$\pi_O \text{ valid} \implies \pi_I \text{ valid} \implies w \text{ satisfies } C$$

The outer proof *transitively* guarantees the original statement, without directly involving $w$.

**"What gets delivered: one proof or two?"**

One proof: only $\pi_O$. The inner proof $\pi_I$ is consumed during composition and never transmitted. This is the entire point: $\pi_I$ might be 100KB, but $\pi_O$ is 128 bytes. The verifier sees only the small envelope, not the large box inside it.

**"This sounds too good to be true. What's the catch?"**

There are catches, and they're significant. The analysis above assumed the inner verifier circuit $C_{V_I}$ is small and easy to express in the outer system. But what if the inner and outer systems speak different languages? STARKs operate over one field; Groth16 operates over another. Encoding foreign field arithmetic can blow up the verifier circuit by orders of magnitude. Trusted setup requirements, field mismatches, and post-quantum concerns all constrain which combinations actually work. The later sections on **The Verifier Circuit Problem** and **Curve Cycles** address these issues in detail.

### The Cost Analysis

Let $|C| = N$ be the original circuit size.

- **Inner proof time:** $O(N)$ from the fast inner prover
- **Verifier circuit size:** $|C_{V_I}| = O(\sqrt{N})$
- **Outer proof time:** $O(\sqrt{N} \log \sqrt{N})$ from the slower outer prover
- **Total prover time:** $O(N) + O(\sqrt{N} \log N) \approx O(N)$

The total is dominated by the fast inner prover. The slow outer prover contributes negligibly because it only processes the small verifier circuit.

**Proof size and verification:** Both inherit from $\mathcal{O}$: constant, tiny, fast.

### A Concrete Example

Circuit size: $N = 10^6$ gates.

Without composition, running Groth16 on the full circuit might take 5 minutes. The prover performs $10^6$ expensive operations (multi-scalar multiplications, FFTs).

With composition:

- Inner SNARK (STARK-like): 5 seconds to prove, produces a proof that the verifier can check in $\sim 1000$ operations
- The verifier circuit $C_{V_I}$ has $\sim 1000$ gates
- Outer SNARK (Groth16): 1 second to prove a 1000-gate circuit

Total: ~6 seconds. Proof size: ~100 bytes (Groth16's constant). Verification: 3 pairings.

We've achieved Groth16-size proofs with STARK-like prover speed, the best of both worlds.

### Adding Zero-Knowledge

Here's a bonus. Suppose the inner SNARK lacks zero-knowledge: some STARK variants reveal execution traces that leak witness information. But the outer SNARK is fully ZK.

The composed system inherits zero-knowledge from the outer layer. The final proof $\pi_O$ proves knowledge of a valid inner proof $\pi_I$ without revealing $\pi_I$ itself. Since $\pi_I$ depends on the witness $w$, hiding $\pi_I$ suffices to hide $w$.

The inner SNARK's lack of ZK is encapsulated and hidden by the outer layer.



## Recursion: Composing with Yourself

If composing two different SNARKs is useful, what about composing a SNARK with *itself*?

### The Idea

Take a hypothetical SNARK $\mathcal{S}$ where verifying a proof for a circuit of size $N$ costs $O(\sqrt{N})$ operations. (This is pedagogical; real SNARKs have $O(1)$ verification like Groth16, or $O(\text{polylog } N)$ like STARKs. The $\sqrt{N}$ gives clean math for illustration.)

Now trace what happens when we recurse:

**Layer 0:** Prove the original circuit $C$ (size $N$). This produces proof $\pi_0$. Verifying $\pi_0$ costs $O(\sqrt{N})$ operations.

**Layer 1:** Wrap $\pi_0$ in another proof. The circuit being proved is now the *verifier* for $\pi_0$, which has size $O(\sqrt{N})$. This produces $\pi_1$. Verifying $\pi_1$ costs $O(\sqrt{\sqrt{N}}) = O(N^{1/4})$ operations.

**Layer 2:** Wrap $\pi_1$. The circuit is the verifier for $\pi_1$, size $O(N^{1/4})$. Verifying $\pi_2$ costs $O(N^{1/8})$ operations.

The pattern: each layer proves "the previous verifier accepted," and since verifiers are smaller than the circuits they verify, each layer's circuit shrinks.

After $k$ layers:

$$\text{Verifier cost for } \pi_k = O(N^{1/2^k})$$

After $O(\log \log N)$ layers, verification cost reaches a constant, the **recursion threshold**.

The key insight: we're not proving the original circuit $C$ over and over. Each layer proves a *different* (smaller) circuit: the verifier of the previous layer. The shrinking comes from the fact that verification is cheaper than computation.

### Proof of Proof of Proof...

From the prover's perspective, deep recursion means building a tower of proofs:

1. $\pi_1$: proves "I know witness $w$ satisfying circuit $C$"
2. $\pi_2$: proves "I know a valid proof $\pi_1$"
3. $\pi_3$: proves "I know a valid proof $\pi_2$"
4. Continue until the verifier circuit is minimal

Each $\pi_i$ is a proof *about* the previous proof. The final $\pi_k$ can be verified in constant time regardless of the original computation's size.

### The Strange Loop

There is something vertiginous in this tower. A proof that proves a proof that proves a proof: the structure is self-referential in a way that usually leads to paradox.

Gödel showed that sufficiently powerful formal systems can express statements about themselves, and this self-reference produces incompleteness. "This statement is unprovable" becomes a sentence the system can express but cannot resolve. Escher drew hands that draw each other into existence, each one the cause and effect of the other. Self-reference, in these contexts, produces either paradox or infinite regress.

Recursive SNARKs are self-referential systems that *work*. The proof system is expressive enough to describe its own verification procedure, to prove statements about that description, and to iterate the process indefinitely. But instead of paradox, the self-reference leads to compression. The tower of proofs, which could grow without bound, collapses into a single constant-sized object.

The difference: Gödel's self-reference asks "is this provable?", a question the system cannot answer about itself. Recursive SNARKs ask "is this verifiable?", and verification is a concrete computation that can be proven like any other. The proof doesn't need to understand itself; it only needs to verify a mechanical check. That's enough to close the loop without contradiction.

### The Extraction Caveat

Deep recursion complicates security proofs. To understand why, we need to see how SNARK security proofs actually work.

**How security proofs work.** We can't prove a cryptographic system is secure in an absolute sense. (That would require proving $P \neq NP$ and more.) Instead, we prove *relative* security: "if someone can break system X, they can also break problem Y." If we believe Y is hard, then X must be hard too.

A SNARK security proof is exactly this kind of reduction. The proof constructs an algorithm (the "reducer") that treats any successful attacker as a black box. If the attacker can forge proofs, the reducer uses that ability to solve discrete logarithms. Since we believe discrete log is hard, forging proofs must also be hard.

For knowledge soundness specifically, the reducer must *extract* the witness from any prover that creates valid proofs. The standard technique is called **rewinding**: you run the prover once, record its behavior, then "rewind" it to an earlier state and run it again with different random challenges.

**A concrete example.** Consider a $\Sigma$-protocol where the prover sends commitment $a$, receives challenge $e$, and responds with $z$. The extractor works like this:

1. Run the prover. It sends $a$, you send challenge $e_1$, it responds with $z_1$.
2. Rewind to just after the prover sent $a$. (In a proof, we model the prover as a stateful algorithm we can checkpoint and restore.)
3. Send a *different* challenge $e_2$.
4. The prover responds with $z_2$.
5. From $(e_1, z_1)$ and $(e_2, z_2)$ with the same $a$, you can algebraically solve for the witness.

This works because the prover committed to $a$ before seeing the challenge. With two different challenges for the same commitment, the witness is over-determined and can be extracted.

**The problem with recursion.** For a single-layer proof, extraction might require running the prover $R$ times (say, $R = 100$). For a 2-layer recursive proof, you must:

1. Extract the inner proof $\pi_I$ from the outer layer: $R$ runs
2. For *each* of those $R$ runs, extract the witness from $\pi_I$: $R$ more runs each
3. Total: $R \times R = R^2$ runs

For depth $k$: $R^k$ runs. At depth 100 with $R = 100$, that's $100^{100} = 10^{200}$ operations.

**Why this breaks the security proof.** Security theorems have the form: "if an attacker breaks the SNARK, our reducer solves discrete log."

But the reducer must be *efficient*. If the reducer takes $10^{200}$ operations to extract a witness, the theorem becomes: "if an attacker breaks the SNARK, discrete log can be solved in $10^{200}$ operations." This is useless. We already know discrete log can be brute-forced in $2^{256} \approx 10^{77}$ operations. The theorem no longer rules out attackers.

To be clear: more rewinds doesn't make the *system* easier to attack. It makes our *proof technique* too slow to demonstrate security. The reducer's inefficiency is a problem for the theorist writing the proof, not for the attacker trying to break the system.

**What this means in practice.** The system might be perfectly secure. We just can't prove it using standard reduction techniques. No one has found attacks that exploit the recursive structure. The underlying hard problem (discrete log, collision resistance) remains hard. The gap is between what we can *prove* and what we *believe*.

This situation parallels the random oracle model: we use hash functions in ways we can't fully justify theoretically, but deployed systems resist all known attacks. Recursive SNARKs occupy similar territory. Practitioners accept the theoretical gap and ship, while researchers work on tighter proof techniques.



## The Curve Cycle Problem

For pairing-based SNARKs like Groth16, recursion faces a fundamental obstacle: field mismatch.

### Two Fields, One Problem

Every pairing-based SNARK involves two distinct fields. To understand why, recall how elliptic curve cryptography works.

An elliptic curve $E$ is defined over a **base field** $\mathbb{F}_q$. Points on the curve have coordinates $(x, y)$ where $x, y \in \mathbb{F}_q$. When you add two points or compute $k \cdot P$ (scalar multiplication), you're doing arithmetic in $\mathbb{F}_q$: additions, multiplications, and inversions of these coordinates.

But the *scalars* $k$ live in a different field. The curve's points form a group under addition, and this group has an **order** $p$: the number of elements in the group. For any point $P$, we have $p \cdot P = \mathcal{O}$ (the identity). Scalars are integers modulo $p$, giving us the **scalar field** $\mathbb{F}_p$.

**A concrete example with BN254** (the curve Ethereum uses for precompiles):

- Base field: $\mathbb{F}_q$ where $q \approx 2^{254}$ (a specific 254-bit prime)
- Scalar field: $\mathbb{F}_p$ where $p \approx 2^{254}$ (a *different* 254-bit prime)
- A point on the curve: $(x, y)$ with $x, y \in \mathbb{F}_q$
- A Groth16 proof element: $\pi_A = s \cdot G$ where $s \in \mathbb{F}_p$ and $G$ is a generator point

**Where each field appears in Groth16:**

- *Scalar field $\mathbb{F}_p$*: Your circuit's witness values. If you're proving "I know $x$ such that $x^3 + x + 5 = 35$", then $x \in \mathbb{F}_p$. All constraint equations are polynomial identities over $\mathbb{F}_p$.

- *Base field $\mathbb{F}_q$*: The proof elements themselves. The proof $\pi = (\pi_A, \pi_B, \pi_C)$ consists of elliptic curve points, which have coordinates in $\mathbb{F}_q$. Verification requires point additions and pairings, all computed over $\mathbb{F}_q$.

**Why this creates a problem for recursion.** To verify a Groth16 proof inside a circuit, you must express the verifier's computation as constraints. The verifier computes pairings and point operations, which are $\mathbb{F}_q$ arithmetic. But your circuit constraints are over $\mathbb{F}_p$.

To do $\mathbb{F}_q$ arithmetic inside an $\mathbb{F}_p$ circuit, you must *emulate* it: represent each $\mathbb{F}_q$ element as multiple $\mathbb{F}_p$ elements and implement multiplication/addition using many $\mathbb{F}_p$ operations. A single $\mathbb{F}_q$ multiplication might expand to hundreds of $\mathbb{F}_p$ constraints. The verifier circuit explodes from a few thousand operations to hundreds of thousands.

**Terminology: "native" vs. "emulated" arithmetic.** When we say arithmetic is *native*, we mean it's cheap inside the circuit: one field operation becomes one constraint. A circuit over $\mathbb{F}_p$ can do $\mathbb{F}_p$ arithmetic natively. It must *emulate* $\mathbb{F}_q$ arithmetic, paying 100+ constraints per operation. The curve cycle trick ensures we're always doing native arithmetic by switching fields at every recursive step.

### Cycles of Curves

**For single composition**, the fix is straightforward: choose an outer curve whose scalar field matches the inner curve's base field. If the inner verifier does $\mathbb{F}_q$ arithmetic, use an outer system over $\mathbb{F}_q$. One wrap, native arithmetic, done.

**For deep recursion**, this isn't enough. After wrapping once, you have a new proof whose verifier does arithmetic in some *other* field. To wrap again natively, you need yet another matching curve. The solution is a **cycle of elliptic curves** $(E_1, E_2)$:

- $E_1$ has scalar field $\mathbb{F}_p$ and base field $\mathbb{F}_q$
- $E_2$ has scalar field $\mathbb{F}_q$ and base field $\mathbb{F}_p$

The fields swap roles between curves. Recursion alternates:

- Proof $\pi_1$ on curve $E_1$: verifier performs $\mathbb{F}_q$ arithmetic
- Proof $\pi_2$ on curve $E_2$: verifier performs $\mathbb{F}_p$ arithmetic, can *natively* prove about $\pi_1$'s verification
- Proof $\pi_3$ on curve $E_1$: can natively prove about $\pi_2$'s verification
- And so on indefinitely

Each step's verifier circuit uses native field arithmetic. The alternation continues as long as needed, with no expensive cross-field emulation at any layer.

### Practical Curve Cycles

**Pasta curves (Pallas and Vesta):** A true cycle. Neither curve is pairing-friendly, but both support efficient Pedersen commitments and inner-product arguments. Used in Halo 2 and related systems.

**BN254 / Grumpkin:** Grumpkin is obtained by swapping BN254's base and scalar fields. Since BN254 has Ethereum precompiles, this cycle enables efficient on-chain verification of recursively composed proofs. Aztec uses this for their rollup architecture. Note that Grumpkin itself isn't pairing-friendly, so the cycle alternates between pairing-based proofs (on BN254) and inner-product-based proofs (on Grumpkin).

**BLS12-377 / BW6-761:** A "half-cycle" enabling efficient one-step recursion for pairing-based SNARKs. BW6-761's scalar field matches BLS12-377's base field, allowing native verification of BLS12-377 proofs.

**A related curiosity: embedded curves.** BabyJubjub is defined over BN254's scalar field $\mathbb{F}_p$, so BabyJubjub point operations can be expressed natively as BN254 circuit constraints. This enables in-circuit cryptography: EdDSA signatures, Pedersen hashes, and other EC-based primitives. But BabyJubjub doesn't form a cycle with BN254. The alignment is one-way: BN254's scalar field equals BabyJubjub's base field, but BabyJubjub's group order is much smaller than BN254's base field. You can do BabyJubjub crypto inside a BN254 circuit, but you can't use the pair for recursion.

Finding curve cycles is mathematically delicate. The size constraints (both fields must be large primes), security requirements (curves must resist known attacks), and efficiency demands (curves should have fast arithmetic) severely restrict the design space.



## Incrementally Verifiable Computation (IVC)

Composition combines different proof systems; the recursion we've seen so far compresses proofs through towers of wrapping. But there's a different problem that recursion solves, one that isn't about shrinking proofs or mixing systems.

**The problem: proving computation that hasn't finished yet.**

A blockchain processes transactions one by one. A verifiable delay function (VDF) computes a hash chain for hours, proving that real time elapsed. A zkVM executes a program instruction by instruction. In each case, the computation is *sequential*: step $i$ depends on step $i-1$. You can't parallelize it. You can't wait until the end to start proving (the end might be days away, or never).

What you want is a proof that *grows* with the computation. After step 1, you have a proof of step 1. After step 1000, you have a proof of steps 1 through 1000. Crucially, the proof at step 1000 shouldn't be 1000× larger than the proof at step 1. And creating the proof for step 1000 shouldn't require re-proving steps 1 through 999.

This is **incrementally verifiable computation**, or **IVC**: proofs that extend cheaply, verify in constant time, and accumulate the history of an unbounded sequential process. The term appears throughout the literature; systems like Nova, SuperNova, and ProtoStar are "IVC schemes."

### The Setting

Consider a function $F: X \to X$ iterated $T$ times:

$$y_T = F(F(\cdots F(x_0) \cdots)) = F^T(x_0)$$

For $T = 10^9$ iterations, directly proving this requires a circuit of size $O(T \cdot |F|)$: billions of gates. Even fast provers choke on circuits this large. And you'd have to wait until iteration $10^9$ completes before generating any proof at all.

### The Incremental Approach

Generate proofs *incrementally*, one step at a time:

- $\pi_0$: trivial (base case, no computation yet)
- $\pi_1$: proves "$y_1 = F(x_0)$ and I know a valid $\pi_0$"
- $\pi_2$: proves "$y_2 = F(y_1)$ and I know a valid $\pi_1$"
- $\pi_i$: proves "$y_i = F(y_{i-1})$ and I know a valid $\pi_{i-1}$"

Each $\pi_i$ has constant size and proves the *entire* computation from $x_0$ to $y_i$. The proof for step $i$ subsumes all previous proofs.

### The Recursive Circuit

At step $i$, the prover runs a circuit that:

1. **Verifies $\pi_{i-1}$:** Checks that the previous proof is valid
2. **Computes $y_i = F(y_{i-1})$:** Performs one step of the function
3. **Produces $\pi_i$:** Outputs a new proof

The circuit size is $|V| + |F|$: the cost of verifying the previous proof plus the cost of one function evaluation. The overhead of recursion is $|V|$, the verifier circuit size.

For a SNARK with efficient verification, $|V|$ might be a few thousand gates. If $|F|$ is also a few thousand gates (a hash function, say), the overhead roughly doubles the per-step cost. For larger $|F|$, the overhead is proportionally smaller.

### Where IVC Shines

**Verifiable Delay Functions (VDFs).** The canonical example: repeated squaring $x \mapsto x^2 \mod N$ for an RSA modulus $N$. Each squaring depends on the previous result; you can't compute $x^{2^T}$ faster than $T$ sequential multiplications (without knowing the factorization of $N$). After computing $y = F^T(x)$, the prover produces a proof that $y$ is correct, verifiable in time much less than $T$. IVC is natural here: the function is inherently sequential, and the proof accumulates with each step.

**Succinct Blockchains.** Each block contains a proof that:

1. This block's transactions are valid
2. The previous block's proof was valid

A new node syncing to the chain verifies a *single* proof (the most recent one) rather than replaying every transaction since genesis. Mina Protocol pioneered this approach.

**Proof Aggregation.** Multiple independent provers generate $T$ separate proofs. An aggregator combines them into one proof via recursive composition. Batch verification becomes constant-time regardless of the number of original proofs.

## Folding Schemes: The Modern Revolution

Traditional recursion has a fundamental problem: the overhead of verifying the previous proof can exceed the cost of computing $F$ itself.

If $|V| = 10,000$ gates and $|F| = 1,000$ gates, verification dominates. The prover spends 90% of their time proving they verified correctly, only 10% proving they computed correctly. For tiny $|F|$ (say, a single hash), the ratio gets even worse.

**Folding schemes** address this by replacing verification with something cheaper.

### The Key Insight

Instead of *fully verifying* $\pi_{i-1}$ at step $i$, we **fold** the claim about step $i-1$ with the claim about step $i$. Folding combines two claims into one claim of the same structure, without verifying either.

> **The Debt Analogy**
>
> Imagine you owe the bank money every day (you must verify a proof).
>
> **Traditional recursion:** You pay off the debt in full every single day. Expensive and slow.
>
> **Folding:** You go to the bank and say, "Can I combine yesterday's debt with today's debt into one IOU?" The bank agrees, using a random challenge to prevent fraud. You do this for a million days. You never pay a cent. On the very last day, you pay off the single accumulated IOU.
>
> Because "combining debts" is far cheaper than "paying them off," you save enormous work. The cost of combining is a few group operations; the cost of paying is a full SNARK proof.

The cost of folding is drastically cheaper than the cost of verification, typically just a handful of group operations.

### Nova's Approach

Nova, the pioneering folding scheme (Kothapalli, Setty, Tzialla, 2021), introduced a modified constraint system: **relaxed R1CS**. The relaxation is precisely what enables folding.

Standard R1CS demands:
$$(A \cdot z) \circ (B \cdot z) = C \cdot z$$

Relaxed R1CS allows slack:
$$(A \cdot z) \circ (B \cdot z) = u \cdot (C \cdot z) + E$$

where $u$ is a scalar and $E$ is an "error vector." A standard R1CS instance has $u = 1$ and $E = 0$. Relaxed instances can have $u \neq 1$ and $E \neq 0$, but satisfying a relaxed instance still proves something about the underlying computation.

### Why Relaxation Enables Folding

Think of the error vector $E$ as a "trash can" for the cross-terms. When we fold two instances, the algebra gets messy: products of sums produce interaction terms that don't belong to either original constraint. Standard R1CS has nowhere to put this mess, so folding breaks the equation. Relaxed R1CS adds a variable ($E$) specifically to hold that mess, keeping the equation valid despite the extra terms.

The key insight is that relaxed R1CS instances can be *linearly combined*. Suppose we want to fold two instances by taking a random linear combination with challenge $r$:

$$z = z_1 + r \cdot z_2$$

This is the core of folding: two separate witnesses $z_1$ and $z_2$ become a single witness $z$. The folded witness has the same dimension as the originals; we're not concatenating, we're combining. Think of it geometrically: $z_1$ and $z_2$ are points in $\mathbb{F}^n$; the fold $z$ is another point on the line through them, selected by the random challenge $r$.

What happens when we plug this combined witness into the constraint? Let's compute $(Az) \circ (Bz)$:

$$(A(z_1 + rz_2)) \circ (B(z_1 + rz_2))$$
$$= (Az_1 + r \cdot Az_2) \circ (Bz_1 + r \cdot Bz_2)$$
$$= (Az_1 \circ Bz_1) + r \cdot (Az_1 \circ Bz_2 + Az_2 \circ Bz_1) + r^2 \cdot (Az_2 \circ Bz_2)$$

The Hadamard product distributes, but it creates **cross-terms**: the middle expression $Az_1 \circ Bz_2 + Az_2 \circ Bz_1$ mixes the two instances. This is the "interaction" between them.

For standard R1CS, these cross-terms would break everything. But relaxed R1CS absorbs them into the error vector $E$. Define:

$$T = Az_1 \circ Bz_2 + Az_2 \circ Bz_1 - u_1 \cdot Cz_2 - u_2 \cdot Cz_1$$

This is the **cross-term vector**. To understand where each term comes from, recall that each relaxed R1CS instance has its own slack factor: instance 1 has $(z_1, E_1, u_1)$ and instance 2 has $(z_2, E_2, u_2)$. When we expand the *right side* of the relaxed constraint $u \cdot (Cz)$ using the folded values $u = u_1 + ru_2$ and $z = z_1 + rz_2$:

$$(u_1 + ru_2) \cdot C(z_1 + rz_2) = u_1 Cz_1 + r(u_1 Cz_2 + u_2 Cz_1) + r^2 \cdot u_2 Cz_2$$

The coefficient of $r$ on the right side is $u_1 Cz_2 + u_2 Cz_1$. On the left side (the Hadamard product expansion above), the coefficient of $r$ is $Az_1 \circ Bz_2 + Az_2 \circ Bz_1$. The cross-term $T$ is exactly the difference between these: what the left side produces at $r$ minus what the right side produces at $r$. This mismatch gets absorbed into the error vector.

Note that the $r^2$ coefficient works out automatically: the left side gives $Az_2 \circ Bz_2$ and the right side gives $u_2 Cz_2$, which is exactly instance 2's original constraint (up to $E_2$). The folded error $E = E_1 + rT + r^2 E_2$ absorbs the second instance's error at $r^2$.

### The Folding Protocol

A relaxed R1CS instance consists of a witness vector $z$, an error vector $E$, and a slack scalar $u$. A fresh (non-folded) instance has $u = 1$ and $E = 0$; after folding, both accumulate non-trivial values.

Given two instances $(z_1, E_1, u_1)$ and $(z_2, E_2, u_2)$, the protocol folds them into one. But the verifier doesn't see the actual witness vectors, since that would defeat the point. Instead, the verifier works with **commitments**.

**What the verifier holds:** Commitments $C_{z_1}, C_{z_2}$ to the witness vectors, commitments $C_{E_1}, C_{E_2}$ to the error vectors, and the public scalars $u_1, u_2$. (Public inputs are also visible, but we omit them for clarity.)

**The protocol:**

1. **Prover computes the cross-term $T$:** The formula above requires knowing both witnesses, so only the prover can compute it.

2. **Prover commits to $T$:** Sends commitment $C_T$ to the verifier. This is the only new cryptographic operation per fold.

3. **Verifier sends random challenge $r$.**

4. **Both compute the folded instance using commitments:**

   - $C_z = C_{z_1} + r \cdot C_{z_2}$ (the verifier computes this from the commitments)
   - $u = u_1 + r \cdot u_2$ (public scalars, both can compute)
   - $C_E = C_{E_1} + r \cdot C_T + r^2 \cdot C_{E_2}$ (again from commitments)

The verifier never sees $z_1, z_2, E_1, E_2$, or $T$ directly. They work entirely with commitments. Because commitments are additively homomorphic (Pedersen commitments satisfy $C(a) + C(b) = C(a+b)$), the folded commitment $C_z$ is a valid commitment to the folded witness $z = z_1 + r \cdot z_2$, which only the prover knows.

**Meanwhile, the prover** computes the actual folded witness $z = z_1 + r \cdot z_2$ and the actual folded error $E = E_1 + r \cdot T + r^2 \cdot E_2$. The prover holds these for the next fold (or for the final SNARK).

The folded error vector absorbs the cross-terms at the $r$ coefficient and the second instance's error at the $r^2$ coefficient. This is exactly what makes the constraint hold: the expansion of $(Az) \circ (Bz)$ produces terms at powers $1$, $r$, and $r^2$, and the folded $E$ and $u \cdot Cz$ absorb them all.

**Why this works:** If you expand $(Az) \circ (Bz) - u \cdot Cz - E$ using the folded values, all terms cancel if and only if both original instances satisfied their constraints. The random $r$ acts as a Schwartz-Zippel check: a cheating prover who folds two *unsatisfied* instances would need the folded instance to satisfy the constraint, but this happens with negligible probability over random $r$.

Two claims have become one, without verifying either. The prover paid the cost of one commitment (to $T$) and some field operations. No expensive SNARK proving.

### IVC with Folding

Now we connect the folding protocol to the IVC setting from earlier in the chapter. Recall the problem: prove $y_T = F^T(x_0)$ for large $T$ without circuits that grow with $T$.

**The key insight:** The folding protocol combines two relaxed R1CS instances into one. For IVC, we'll maintain a **running instance** that accumulates all previous steps, and fold in each new step as it happens.

**What gets folded:** At each step, we have two things:

- The **running instance** $(C_{z_{acc}}, C_{E_{acc}}, u_{acc})$: commitments and slack representing "all steps so far are correct"
- The **step instance** $(C_{z_i}, C_{E_i} = C_0, u_i = 1)$: a fresh claim that "step $i$ was computed correctly"

The step instance is always fresh: $u_i = 1$ and $E_i = 0$ because it comes from a standard (non-relaxed) R1CS. Only the running instance accumulates non-trivial slack.

**The IVC loop in detail:**

**Step 0 (Base case):** Initialize the running instance to a trivial satisfiable state. No computation yet.

**Step $i$ (for $i = 1, 2, \ldots, T$):**

1. **Compute:** Execute $y_i = F(y_{i-1})$

2. **Create the step instance:** Express "$y_i = F(y_{i-1})$" as an R1CS constraint. The witness $z_i$ encodes the input $y_{i-1}$, output $y_i$, and intermediate values. Commit to get $C_{z_i}$.

3. **Fold:** Run the folding protocol between the running instance and the step instance:
   - Prover computes cross-term $T_i$ and commits to get $C_{T_i}$
   - Challenge $r_i$ is derived (via Fiat-Shamir from the transcript)
   - Both parties compute the new running instance:
     - $C_{z_{acc}} \leftarrow C_{z_{acc}} + r_i \cdot C_{z_i}$
     - $u_{acc} \leftarrow u_{acc} + r_i \cdot 1$
     - $C_{E_{acc}} \leftarrow C_{E_{acc}} + r_i \cdot C_{T_i} + r_i^2 \cdot C_0$
   - Prover updates actual witnesses: $z_{acc} \leftarrow z_{acc} + r_i \cdot z_i$, etc.

4. **Repeat:** The new running instance becomes input to step $i+1$

**After $T$ steps:** The prover holds a final running instance $(C_{z_{acc}}, C_{E_{acc}}, u_{acc})$ with $u_{acc} = 1 + r_1 + r_1 r_2 + \cdots$ (accumulated from all the folds). This single instance encodes the claim "all $T$ steps were computed correctly."

**The final SNARK:** One last proof demonstrates that the running instance is satisfiable, namely that there exists a witness $z_{acc}$ and error vector $E_{acc}$ such that:

$$(Az_{acc}) \circ (Bz_{acc}) = u_{acc} \cdot (Cz_{acc}) + E_{acc}$$

This single SNARK invocation is the only expensive cryptographic operation. The $T$ folding steps required only cheap group operations (scalar multiplications on commitments). The cost of proving is amortized across all steps.

**What the verifier checks:** The verifier receives the final running instance (the commitments and public scalars), the final SNARK proof, and the claimed output $y_T$. They verify the SNARK and check that $y_T$ matches what the instance claims. If both pass, they're convinced that $y_T = F^T(x_0)$ without seeing any intermediate states.

### Security Considerations for Folding

Folding schemes have a reputation in the zkVM community for being where security problems arise. This isn't accidental; the architecture creates several subtle attack surfaces.

**Deferred verification.** Traditional recursion verifies at each step: if something is wrong, you catch it immediately. Folding defers *all* verification to the final SNARK. Errors compound silently across thousands of folds before manifesting. Debugging becomes archaeology, trying to identify which of 10,000 folds went wrong.

**The commitment to $T$ is critical.** The cross-term $T$ must be committed *before* the verifier sends challenge $r$. If the prover can open this commitment to different values after seeing $r$, soundness breaks completely: the prover can fold unsatisfied instances and make them appear satisfied. Nova uses Pedersen commitments (computationally binding under discrete log), so breaking the binding property would require solving discrete log. But implementation bugs in commitment handling have caused real vulnerabilities.

**Accumulator state is prover-controlled.** Between folding steps, the prover holds the running accumulated instance $(z_{acc}, E_{acc}, u_{acc})$. The final SNARK proves this accumulated instance is satisfiable, but doesn't directly verify it came from honest folding. A malicious prover who can inject a satisfiable-but-fake accumulated instance breaks the chain of trust. The "decider" circuit must carefully check that public inputs match the accumulator state.

**Soundness error accumulates.** Each fold relies on Schwartz-Zippel over challenge $r$. After $T$ folds, soundness error is roughly $T \cdot d / |\mathbb{F}|$ where $d$ is the constraint degree. For $T = 10^6$ folds over a 256-bit field, this is negligible ($\approx 2^{-236}$). But for smaller fields or exotic parameters, verify the concrete security.

**Implementation complexity.** Folding has more moving parts than traditional recursion: cross-term computation, accumulator updates, commitment bookkeeping, the interaction between folding and the final decider SNARK. Each is a potential bug location. Several folding implementations have had soundness bugs discovered post-audit. The Jolt team (among others) has noted this pattern: the abstraction is elegant, but the implementation details are unforgiving.

None of this means folding is insecure. It means the security argument is more delicate than "run a SNARK at each step." The efficiency gains are real, but so is the need for careful implementation and thorough auditing.

### Folding and the PIOP Paradigms

How does folding relate to the two classes of PIOPs from Chapter 21?

Folding schemes operate at a different level of the stack. The hierarchy is:

1. **Constraint system**: R1CS, Plonkish, CCS, AIR
2. **PIOP paradigm**: How you prove constraints (quotienting or sum-check)
3. **Recursion strategy**: How you chain proofs (full verification, folding, accumulation)

Nova's folding operates at level 3. It takes R1CS instances and folds them algebraically. The *final* SNARK, the one that proves the accumulated instance is satisfiable, can use either paradigm.

**The practical pattern:** Folding schemes emerged from the sum-check lineage. Nova came from the Spartan team (Microsoft Research), and Spartan proves R1CS using sum-check over multilinear extensions. The algebraic structure of relaxed R1CS (linear combinations of witnesses, error absorption via slack vectors) fits naturally with the multilinear machinery.

HyperNova takes this further with CCS (Customizable Constraint Systems), which was designed specifically for sum-check-based proving. The folding protocol and the final SNARK both use multilinear polynomials and sum-check reductions.

You *can* wrap a folded instance in Groth16 at the end for tiny proofs (important for on-chain verification), but the folding itself is sum-check-native. The quotienting paradigm doesn't have a natural analog to "relax the constraint and absorb cross-terms into an error vector"; that algebraic trick relies on the multilinear structure.

**The heuristic:** If you're building an IVC system and care about prover speed, you're probably in sum-check territory. Folding + Spartan-style final proof. If you need the absolute smallest proofs for cheap on-chain verification, you fold with sum-check machinery, then compose with Groth16 at the very end.

### The Numbers

| Aspect | Traditional Recursion | Folding (Nova) |
|--------|----------------------|----------------|
| Per-step overhead | Full SNARK verification | Two group operations |
| Curves needed | Pairing-friendly or cycle | Any curve works |
| Final proof | Proves last recursive step | Proves folded instance |
| Prover bottleneck | Verification overhead | Actual computation $F$ |

For small $F$ (hash function evaluations, state machine transitions), folding is an order of magnitude faster than traditional recursion. The per-step cost drops from thousands of gates to tens of operations.



## Beyond Nova: HyperNova and ProtoStar

Nova opened the door; subsequent work has widened it considerably. The limitations of relaxed R1CS (its restriction to degree-2 constraints, its awkwardness with custom gates) motivated generalizations.

### The CCS Abstraction

Nova's restriction to R1CS creates friction. Real systems want custom gates (cheaper than R1CS for common operations), higher-degree constraints (more expressive per gate), and structured access patterns (AIR's row-to-row relationships). Converting everything to R1CS works but bloats constraint counts.

**Customizable Constraint Systems (CCS)**, introduced in Chapter 8, unify R1CS, Plonkish, and AIR under one framework. As a reminder, the core equation is:

$$\sum_{j=1}^{q} c_j \cdot \bigcirc_{i \in S_j} (M_i \cdot z) = \mathbf{0}$$

Each term $j$ takes a Hadamard product ($\bigcirc$) over the matrix-vector products $M_i \cdot z$ for matrices in multiset $S_j$, then scales by coefficient $c_j$. The multiset sizes determine constraint degree: R1CS uses $|S| = 2$ (degree 2), higher-degree gates use larger multisets, linear constraints use $|S| = 1$.

**Why CCS matters for folding:** With CCS, a folding scheme designer targets one interface. HyperNova folds CCS instances directly, so any constraint system expressible as CCS, which includes R1CS, Plonkish, and AIR, inherits folding automatically. You can fold circuits written in different constraint languages without converting to a common format first. The abstraction pays for itself when you want custom gates, higher-degree constraints, or mixed constraint types within a single IVC computation.

### HyperNova: Folding CCS

**HyperNova** extends Nova's folding approach to CCS, but the generalization isn't straightforward. The degree problem that Nova sidestepped returns with a vengeance.

**The degree problem.** Recall Nova's cross-term: when folding $z = z_1 + r \cdot z_2$ into a degree-2 constraint, the expansion produces terms at $r^0$, $r^1$, and $r^2$. The error vector $E$ absorbs the cross-term at $r^1$.

For a degree-$d$ constraint, folding $z = z_1 + r \cdot z_2$ produces terms at powers $r^0, r^1, \ldots, r^d$. Each intermediate power $r^1, \ldots, r^{d-1}$ generates a cross-term that must be absorbed. Naive relaxation requires $d-1$ error vectors, each requiring a commitment. The prover cost scales with degree.

**The linearization insight.** HyperNova avoids this by observing: if one of the two instances is already *linear* (degree 1), then the cross-terms don't explode. Folding a linear instance with a degree-$d$ instance produces at most degree $d$, with manageable cross-terms.

**LCCCS (Linearized CCS).** The trick is to convert an accumulated CCS instance into a different form before folding. A CCS constraint is a *vector* equation over $m$ entries:

$$\sum_{j=1}^{q} c_j \cdot \bigcirc_{i \in S_j} (M_i \cdot z) = \mathbf{0} \in \mathbb{F}^m$$

Each of the $m$ entries must be zero. The "linearized" version collapses this to a *scalar* equation by taking a random linear combination of all $m$ constraints. Given random $r \in \mathbb{F}^{\log m}$, weight each constraint by $\widetilde{\text{eq}}(r, k)$ (the multilinear extension of the equality predicate from Chapter 4):

$$\sum_{k \in \{0,1\}^{\log m}} \widetilde{\text{eq}}(r, k) \cdot \left( \sum_{j} c_j \cdot \bigcirc_{i \in S_j} (M_i \cdot z)_k \right) = 0$$

By Schwartz-Zippel, if any entry of the original vector is non-zero, this scalar equation fails with high probability over random $r$. This is the standard "batch to a single equation" trick.

The resulting scalar can be expressed in terms of multilinear extension evaluations: $\tilde{M}_i(r)$ is the MLE of $M_i \cdot z$ evaluated at $r$. The witness $z$ now appears only through these evaluation claims, which sum-check can reduce to polynomial openings.

Why call this "linearized"? The term refers to how the *folding* works, not the constraint degree. When folding an LCCCS (which is a scalar evaluation claim) with a fresh CCS instance (a vector constraint), the interaction between them produces manageable cross-terms. The scalar form of LCCCS means folding doesn't multiply the number of error terms the way naive CCS folding would.

**The key trick: asymmetric folding.**

Nova folds two things of the *same* shape: relaxed R1CS instance + relaxed R1CS instance → relaxed R1CS instance. The error vector absorbs the degree-2 cross-term.

HyperNova folds two things of *different* shapes:

- **Running instance (LCCCS):** A scalar claim about polynomial evaluations
- **Fresh instance (CCS):** A vector constraint over $m$ entries

You're not combining "vector + vector → vector." You're combining "scalar + vector → scalar." This asymmetry is what prevents cross-term explosion.

**How sum-check bridges them:** The sum-check protocol takes a claim about a sum (the CCS vector constraint, batched into a scalar) and reduces it to an evaluation claim at a random point. After sum-check, both the running LCCCS and the fresh CCS have been reduced to evaluation claims at the *same* random point. These scalar claims can be linearly combined without degree blowup.

**The loop:**

1. **Running LCCCS:** A scalar claim "$\sum_j c_j \prod_{i \in S_j} \tilde{M}_i(r_{old}) = v_{old}$"
2. **Fresh CCS arrives:** A vector constraint that must hold at all $m$ positions
3. **Sum-check:** Batch the CCS into a scalar claim at a new random point $r_{new}$, then combine with the LCCCS
4. **Result:** A new scalar claim at $r_{new}$, another LCCCS ready for the next fold

The sum-check rounds are the cost of generality: $O(\log m)$ rounds of interaction (or Fiat-Shamir hashing). But once sum-check finishes, combining the evaluation claims needs only one multi-scalar multiplication, the same per-fold cost as Nova regardless of constraint degree.

**The analogy:** In Nova, the error vector $E$ absorbs degree-2 cross-terms algebraically. In HyperNova, sum-check absorbs arbitrary-degree cross-terms interactively. Different mechanisms, same goal: constant prover cost per fold.

**Additional benefits:**

- *Multi-instance folding*: Fold $k$ instances simultaneously by running sum-check over all $k$ at once. The cost is $O(\log k)$ additional sum-check rounds. This enables efficient PCD (proof-carrying data), where proofs from multiple sources combine into one.
- *Free zero-knowledge*: The randomization introduced by sum-check challenges provides hiding. Unlike Nova, which requires explicit blinding for ZK, HyperNova's folding randomization already masks the witness.
- *CycleFold integration*: The curve-cycle overhead can be amortized using a companion protocol (see below).

### ProtoStar: Accumulation for Special-Sound Protocols

**ProtoStar** takes a different generalization path. Rather than targeting a specific constraint system, it provides accumulation for any $(2k-1)$-move special-sound protocol.

Recall that Sigma protocols (Chapter 16) are 3-move special-sound protocols. Many proof components (including sum-check rounds, polynomial evaluations, lookup arguments) follow this pattern. ProtoStar accumulates them all.

**Why special-soundness enables accumulation.** A special-sound protocol has a key property: the verifier's check is a low-degree polynomial equation $V(x, \pi, r) = 0$, where $x$ is the public input, $\pi$ is the prover's messages, and $r$ is the verifier's challenge. The degree $d$ of $V$ in $r$ is typically small (often 1 or 2).

This algebraic structure is exactly what folding exploits. Given two protocol instances with the same structure, you can take a random linear combination:

$$V_{acc}(x, \pi, r) = V_1(x_1, \pi_1, r) + \beta \cdot V_2(x_2, \pi_2, r)$$

If both $V_1 = 0$ and $V_2 = 0$, then $V_{acc} = 0$ for any $\beta$. If either is non-zero, $V_{acc} = 0$ with probability at most $d/|\mathbb{F}|$ over random $\beta$. The accumulated check is equivalent to both original checks, with negligible soundness loss.

**The cost difference.** The comparison table lists "3 scalar muls" for ProtoStar versus "1 MSM" for Nova/HyperNova. This reflects different trade-offs:

- Nova/HyperNova commit to the cross-term $T$ (or run sum-check), requiring one multi-scalar multiplication per fold
- ProtoStar works directly with the protocol's algebraic structure, avoiding new commitments but requiring the prover to compute and send $d-1$ "error polynomials" that capture the cross-terms

For degree-2 checks (like most $\Sigma$-protocols), this means a few scalar multiplications instead of an MSM. The MSM dominates for large witnesses, so ProtoStar can be faster when the step function is small.

**Lookup support.** ProtoStar handles lookup arguments with overhead $O(d)$ in the lookup table size, compared to $O(d \log N)$ for HyperNova. The difference: HyperNova encodes lookups via sum-check over the table, adding $\log N$ rounds. ProtoStar accumulates the lookup protocol directly, paying only for the protocol's native degree. For applications with large tables (memory, range checks), this matters.

**ProtoGalaxy.** A refinement of ProtoStar that reduces the recursive verifier's work further. The key observation: when folding $k$ instances, naive accumulation requires $O(k)$ verifier work. ProtoGalaxy uses a Lagrange-basis trick to compress this to $O(\log k)$ field operations plus a constant number of hash evaluations. For multi-instance aggregation (combining proofs from many sources), ProtoGalaxy approaches the minimal possible overhead.

### Comparison

| Feature | Nova | HyperNova | ProtoStar |
|---------|------|-----------|-----------|
| Constraint system | R1CS only | Any CCS (R1CS, Plonk, AIR) | Any special-sound protocol |
| Constraint degree | 2 | Arbitrary | Arbitrary |
| Per-step prover cost | 1 MSM | 1 MSM | 3 scalar muls |
| Lookup support | Via R1CS encoding | $O(d \log N)$ | $O(d)$ |
| Zero-knowledge | Requires blinding | Free from folding | Requires blinding |
| Multi-instance | Sequential only | Native support | Native support |

### When to Use What: A Practitioner's Guide

The progression from Nova to HyperNova to ProtoStar isn't a simple linear improvement. Each occupies a different point in the design space, and the "best" choice depends on your bottleneck.

**The key question: where does your prover spend time?**

Decompose total proving cost into two parts:

- **Step cost $|F|$:** Proving one iteration of your function (one hash, one VM instruction, one state transition)
- **Accumulation overhead $|V|$:** The cost of folding/recursing that step into the running proof

For traditional IVC (recursive SNARKs), $|V|$ is the verifier circuit size, typically thousands to tens of thousands of constraints. For folding, $|V|$ drops to a handful of group operations. The ratio $|F| / |V|$ determines whether folding helps.

**Folding wins when $|F|$ is small:**

- VDFs (repeated squaring): $|F| \approx$ a few hundred constraints per square
- Simple state machines: $|F| \approx$ hundreds to low thousands
- Hash chain proofs: $|F| \approx$ constraint count of one hash invocation

In these cases, traditional IVC spends most of its time proving the *verifier*, not the *computation*. Folding eliminates this overhead almost entirely.

**Folding's advantage shrinks when $|F|$ is large:**

- zkVM instruction execution: $|F| \approx 10,000$ to $100,000$ constraints per instruction
- Complex smart contract proofs: $|F|$ dominates regardless
- Batch proofs of many operations: amortization across the batch matters more than per-step overhead

When $|F| \gg |V|$, the prover spends 95%+ of time on the step function whether using folding or traditional IVC. Folding's 100× reduction in $|V|$ becomes a 5% improvement in total cost.

**The engineering dimension.** Beyond raw performance:

- *Folding schemes are newer.* Less battle-tested, fewer audits, more subtle security pitfalls.
- *AIR/STARK tooling is mature.* Well-understood compilation, debugging, and optimization paths.
- *Folding debugging is harder.* Errors compound across folds; traditional recursion catches bugs per-step.

Some production teams (Nexus, for example) explored folding and reverted to AIR-based approaches. Not because folding is inferior in theory, but because for their specific $|F|$ (complex zkVM execution), the engineering complexity didn't pay off.

**The heuristic:**

| Scenario | Recommended Approach |
|----------|---------------------|
| Small step function (< 1000 constraints), millions of steps | Folding (Nova/HyperNova) |
| Large step function (> 10000 constraints), complex logic | Traditional IVC or STARK |
| Need multi-instance aggregation | HyperNova or ProtoStar |
| Custom gates, non-R1CS constraints | HyperNova (CCS) or ProtoStar |
| Maximum simplicity, proven tooling | STARK/AIR |
| Smallest possible final proof | Fold, then wrap in Groth16 |

### CycleFold: Efficient Curve Switching

All folding schemes face the curve-cycle problem from earlier in this chapter: the folding verifier performs group operations, which are expensive to prove in-circuit over a different field. But folding has a unique advantage here that traditional recursion doesn't: the "verifier work" per step is tiny (a few scalar multiplications), not a full SNARK verification. CycleFold exploits this.

**The problem, revisited.** In Nova's IVC loop, the prover updates the running commitment:

$$C_{z_{acc}} \leftarrow C_{z_{acc}} + r \cdot C_{z_i}$$

This is a scalar multiplication on curve $E_1$. If our main circuit is over the scalar field $\mathbb{F}_p$ of $E_1$, we can't compute this operation natively. The curve points have coordinates in $\mathbb{F}_q$ (the base field), and $\mathbb{F}_q$ arithmetic inside an $\mathbb{F}_p$ circuit is expensive.

Traditional recursion would embed the entire verifier (including pairings) in the circuit, paying hundreds of thousands of constraints. But Nova's "verifier" is just this one scalar multiplication. Can we handle it more cheaply?

**The CycleFold idea.** Instead of proving the scalar multiplication in the main circuit, *defer* it to a separate accumulator on the cycle curve $E_2$.

Recall the cycle: $E_1$ has scalar field $\mathbb{F}_p$ and base field $\mathbb{F}_q$; $E_2$ has scalar field $\mathbb{F}_q$ and base field $\mathbb{F}_p$. The scalar multiplication $r \cdot C$ on $E_1$ involves $\mathbb{F}_q$ arithmetic (the curve operations). But $E_2$ circuits are *natively* over $\mathbb{F}_q$. So:

1. **Main circuit (on $E_1$):** Prove that "$F$ was computed correctly" and that the folding challenges were derived correctly. Don't verify the commitment update.

2. **Auxiliary circuit (on $E_2$):** Prove that "$C_{z_{acc}} + r \cdot C_{z_i}$ was computed correctly." This is a tiny circuit: just one scalar multiplication, natively expressed over $\mathbb{F}_q$.

3. **Fold both accumulators.** The main accumulator (on $E_1$) folds as before. The auxiliary accumulator (on $E_2$) folds the curve-operation claims.

**Why this helps.** The auxiliary circuit on $E_2$ is minimal: roughly 10,000 constraints for one scalar multiplication. Compare to 100,000+ constraints for non-native field emulation. And because we're *folding* the auxiliary claims (not proving them at each step), the cost is amortized.

After $T$ steps:

- Main accumulator: one final SNARK on $E_1$ proves "$F$ was applied correctly $T$ times"
- Auxiliary accumulator: one final SNARK on $E_2$ proves "all $T$ commitment updates were computed correctly"

Both SNARKs are over their native fields. No cross-field emulation anywhere.

**The cost breakdown:**

- Per step: ~10,000 constraints on the cycle curve (the scalar multiplication circuit)
- Final proof: two SNARKs, one on each curve
- Total overhead: roughly $10,000 \cdot T$ constraints across all steps, versus $100,000 \cdot T$ without CycleFold

For long computations, this is a 10× reduction in the curve-cycle overhead.

**Why this is folding-specific.** Traditional recursion embeds the *entire verifier* in circuit at each step. The verifier includes pairings, hash evaluations, and complex checks. You can't easily "defer" these to an auxiliary circuit because they're entangled with the soundness argument.

Folding's verifier is structurally simpler: a few scalar multiplications on commitments. This modularity allows CycleFold to separate "check the computation" from "check the commitment updates" and handle them on different curves.

CycleFold applies to Nova, HyperNova, and ProtoStar, making all of them practical over curve cycles like Pasta (Pallas/Vesta) or BN254/Grumpkin.

## Choosing a Strategy

**Use composition** when:

- You need a small final proof for bandwidth-constrained delivery
- The inner SNARK has fast proving but large proofs
- One-time compilation overhead is acceptable
- You're wrapping a non-ZK system in a ZK outer layer

**Use IVC with folding** when:

- The computation is long and iterative (millions of steps)
- Per-step overhead must be minimized
- Transparency is required (no trusted setup desired)
- The step function $F$ is small

**Use traditional recursion** when:

- You need constant-size proofs at *every* step, not just the final one
- Infrastructure for curve cycles already exists in your system
- Knowledge soundness with a tight reduction is required
- You're building on pairing-based SNARKs

### The Recursion Threshold

Every recursive system has a minimum useful circuit size. If your computation is smaller than the verifier circuit, recursion provides no benefit, and direct proving is more efficient.

Traditional recursion has a high threshold: verifier circuits typically require 10,000-50,000 constraints. Folding dramatically lowers it to under 100 group operations. This is why folding schemes have been transformative: they make recursion practical for small step functions where it was previously absurd.



## Key Takeaways

### The Core Ideas

1. **Composition wraps proofs in proofs.** Prove with a fast system, wrap in a small-proof system. The outer prover only handles the inner verifier circuit, which is much smaller than the original computation. Result: fast proving *and* tiny proofs.

2. **Recursion compresses through self-reference.** A SNARK proving its own verifier creates a shrinking tower: each layer's circuit is the previous layer's verifier. After $O(\log \log N)$ levels, verification cost reaches a constant threshold.

3. **IVC proves computation as it happens.** Each step's proof attests to both "this step was correct" and "all previous steps were correct." The proof grows with computation but stays constant-sized.

### The Obstacles

4. **Field mismatch blocks naive recursion.** Pairing-based verifiers do $\mathbb{F}_q$ arithmetic, but circuits are over $\mathbb{F}_p$. Emulating one field inside another blows up circuit size by 100×. Curve cycles (Pasta, BN254/Grumpkin, BLS12-377/BW6-761) solve this by alternating between matched curve pairs.

5. **Deep recursion weakens security proofs.** Extraction requires $R^k$ rewinds for depth $k$. The system may be secure, but standard proof techniques can't demonstrate it. This parallels random oracle methodology: practitioners accept the gap.

### The Folding Revolution

6. **Folding replaces verification with accumulation.** Two claims become one claim of the same structure, without checking either. Only the final accumulated claim needs a SNARK. Per-step cost drops from thousands of constraints to a handful of group operations.

7. **Relaxed R1CS absorbs cross-terms.** Nova adds slack $(u, E)$ to constraints: $(Az) \circ (Bz) = u \cdot (Cz) + E$. When folding $z = z_1 + rz_2$, the error vector $E$ absorbs the interaction terms that would otherwise break the constraint.

8. **HyperNova generalizes via linearization.** For higher-degree constraints (CCS), convert the accumulated instance to scalar form (LCCCS) before folding. Sum-check bridges scalar claims with fresh vector constraints, preventing cross-term explosion.

9. **Folding wins when $|F| \ll |V|$.** If your step function is smaller than the verifier circuit, folding transforms recursion from impractical to efficient. For large $|F|$, the advantage shrinks; the computation dominates regardless.

### Practical Guidance

10. **The design heuristic.** Composition for combining complementary systems (STARK speed + Groth16 size). Traditional recursion for constant-size proofs at every step. Folding for minimal per-step overhead on long sequential computations. CycleFold for practical curve-cycle deployment.



\newpage

# Chapter 23: Choosing a SNARK

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

Virtual polynomials (Chapter 20) minimize commitment costs. Lookup arguments (Chapter 14) replace expensive constraint checks with table lookups. Everything is oriented toward making the prover faster, because at billion-constraint scale, prover time is the binding constraint.

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



\newpage

# Chapter 24: MPC and ZK: Parallel Paths

In 1982, Andrew Yao posed a puzzle that sounded like a parlor game. Two millionaires meet at a party. Each wants to know who is richer, but neither wants to reveal their actual wealth. Is there a protocol that determines who has more money without either party learning anything else?

The question seems impossible. To compare two numbers, someone must see both numbers. A trusted third party could collect the figures, announce the winner, and burn the evidence. But what if there is no trusted party? What if the millionaires trust no one, not even each other?

The stakes extend far beyond money. Satellite operators need to check if their orbits will collide without revealing classified trajectories. Banks need to detect money laundering across institutions without exposing customer data. Nuclear inspectors need to verify warhead counts without learning weapon designs. In each case, the computation requires data that no single party can be trusted to see.

Yao proved something remarkable: the comparison can be done. Not by clever social arrangements or legal contracts, but by cryptography alone. The protocol he constructed, now called *garbled circuits*, allows two parties to jointly compute any function on their private inputs while revealing nothing but the output. Neither party sees the other's input. The trusted third party dissolves into mathematics.

This was the birth of **Secure Multiparty Computation** (MPC). The field expanded rapidly. In 1988, Ben-Or, Goldwasser, and Wigderson showed that with an honest majority of participants, MPC could achieve *information-theoretic* security: no computational assumption required, just the mathematics of secret sharing. The same year, Chaum, Crépeau, and Damgård proved that with dishonest majorities, MPC remained possible under cryptographic assumptions. By the early 1990s, the core theoretical question was settled: any function computable by a circuit could be computed securely by mutually distrustful parties.

The philosophical implications are striking. Computation, it turns out, does not require a single trusted processor. It can be *distributed* across adversaries who share nothing but a communication channel and a willingness to follow a protocol. The output emerges from the collaboration, but the inputs remain private. This is coordination without trust, agreement without revelation.

### Why MPC Belongs in This Book

Throughout this book, we've focused on trust between prover and verifier. The verifier need not believe the prover is honest; the proof itself carries the evidence. But there's another trust relationship we've quietly assumed: the prover has access to the witness. What if the witness is too sensitive to give to any single party?

Consider a company that wants to prove its financial reserves exceed its liabilities without revealing the actual figures to the auditor, the proving service, or anyone else. The company holds the witness (the books), but generating a ZK proof requires computation. If the company lacks the infrastructure to prove locally, it faces a dilemma: outsource the proving and expose the witness, or don't prove at all.

MPC offers an escape. The company secret-shares its witness among multiple proving servers. Each server sees only meaningless fragments. Together, they compute the proof without any single server learning the books. The witness never exists in one place. Trust is distributed rather than concentrated.

This is one of several approaches to the "who runs the prover?" problem:

**Prove locally.** Keep the witness on your own hardware. No trust required, but you need sufficient compute. For lightweight proofs this works; for zkVM-scale computation it may not.

**Distribute via MPC.** Secret-share the witness among multiple servers. No single server learns anything. Requires the servers not to collude (honest majority or computational assumptions). This chapter develops the techniques.

**Hardware enclaves (TEEs).** Run the prover inside a Trusted Execution Environment like Intel SGX or ARM TrustZone. The enclave attests that it ran the correct code on hidden inputs. Trust shifts from the server operator to the hardware manufacturer: not trustless, but a different trust assumption.

MPC and ZK also connect at a deeper level. MPC techniques directly yield ZK constructions through the "MPC-in-the-head" paradigm: simulate an MPC protocol inside the prover's mind, commit to the simulated parties' views, and let the verifier audit a subset. The parallel paths converge into a single construction.

This chapter traces both paths. We begin with the MPC problem itself, then develop two foundational approaches: secret-sharing protocols and garbled circuits. We examine oblivious transfer, the cryptographic primitive that enables input privacy. Finally, we show how MPC becomes ZK through the in-the-head transformation, completing the circle between these two pillars of programmable cryptography.



## The MPC Problem

The formal setting: $n$ parties hold private inputs $x_1, \ldots, x_n$. They want to learn $f(x_1, \ldots, x_n)$ for some agreed-upon function $f$, but nothing else. A trusted third party could collect everything, compute, and announce the result. MPC achieves the same outcome without the trusted party.

What does "nothing else" mean precisely? The security definition captures this through simulation: whatever a coalition of corrupt parties learns from the protocol, they could have computed from their own inputs and the output alone. The protocol leaks nothing beyond what the function itself reveals.

### Who Might Cheat, and How?

The adversary model shapes everything. A **semi-honest** (or passive) adversary follows the protocol faithfully but tries to extract information from the messages it observes. Think of a curious employee who logs everything but doesn't forge packets. A **malicious** (or active) adversary can deviate arbitrarily: send wrong values, abort early, collude with others. Think of a compromised machine running modified software.

Most efficient protocols assume semi-honest adversaries. Malicious security is achievable but roughly doubles the cost, requiring authentication on shares and consistency checks at gates. The SPDZ protocol (pronounced "speedz") pioneered practical malicious security, discussed later in this chapter.

### How Many Can Collude?

Protocols specify a threshold $t$: security holds as long as at most $t$ of the $n$ parties are corrupt. The critical boundary is $t = n/2$.

With an **honest majority** ($t < n/2$), protocols can achieve information-theoretic security. No computational assumption, no cryptographic hardness. Even an unbounded adversary learns nothing. The mathematics of secret sharing suffices.

With a **dishonest majority** ($t < n$, potentially $t = n-1$), information-theoretic security becomes impossible. If all but one party collude, they can simulate the entire protocol among themselves. Cryptographic assumptions become necessary: the adversary *could* break the scheme given infinite time, but doing so requires solving hard problems.



## Secret-Sharing MPC

The BGW protocol, named after Ben-Or, Goldwasser, and Wigderson, takes a direct approach: secret-share each input, compute on the shares, and reconstruct only the output. To understand how this works, we need to understand what secret sharing actually does.

### Shamir's Secret Sharing

The idea is elegant (Appendix A covers the full details, including reconstruction formulas and security properties). To share a secret $s$ among $n$ parties with threshold $t$, construct a random polynomial of degree $t-1$ that passes through the point $(0, s)$:

$$P(X) = s + a_1 X + a_2 X^2 + \cdots + a_{t-1} X^{t-1}$$

The coefficients $a_1, \ldots, a_{t-1}$ are chosen uniformly at random. The secret $s$ is the constant term, recoverable as $P(0)$.

Each party $i$ receives the share $s_i = P(i)$, the polynomial evaluated at their index. Any $t$ parties can pool their shares and use Lagrange interpolation to recover the polynomial, hence the secret. But $t-1$ shares reveal nothing: a degree $t-1$ polynomial is determined by $t$ points, so with only $t-1$ points, every possible secret is equally consistent with the observed shares.

**Concrete example.** Share the secret $s = 7$ among 3 parties with threshold $t = 2$. Choose a random linear polynomial passing through $(0, 7)$, say $P(X) = 7 + 3X$. The shares are:

- Party 1: $s_1 = P(1) = 10$
- Party 2: $s_2 = P(2) = 13$
- Party 3: $s_3 = P(3) = 16$

Any two parties can reconstruct. Parties 1 and 3, holding $(1, 10)$ and $(3, 16)$, interpolate: the unique line through these points is $P(X) = 7 + 3X$, so $P(0) = 7$. But party 1 alone, holding only $(1, 10)$, knows nothing. Any line through $(1, 10)$ could have any $y$-intercept. The secret could be anything.

### Setup

Each party $i$ secret-shares their input $x_i$ by constructing a random polynomial $P_i(X)$ with $P_i(0) = x_i$ and sending share $P_i(j)$ to party $j$. After this initial exchange, party $j$ holds one share of every input: $P_1(j), P_2(j), \ldots, P_n(j)$. No single party can reconstruct any input, but the distributed shares encode everything needed to compute.

### Linear Operations

Here's where the magic happens. Shamir sharing is *linear*. If parties hold shares of secrets $a$ and $b$ encoded by polynomials $P_a$ and $P_b$, then adding the shares gives valid shares of $a + b$.

Why? Party $j$ holds $P_a(j)$ and $P_b(j)$. When they compute $P_a(j) + P_b(j)$, this equals $(P_a + P_b)(j)$, the evaluation of the sum polynomial at $j$. The sum polynomial $P_a + P_b$ has constant term $P_a(0) + P_b(0) = a + b$. So the parties now hold valid Shamir shares of $a + b$, without any communication.

The same holds for scalar multiplication. If party $j$ holds share $P_a(j)$ and multiplies it by a public constant $c$, the result $c \cdot P_a(j)$ is the evaluation of the polynomial $c \cdot P_a$ at $j$. This polynomial has constant term $c \cdot a$. Each party scales locally; no messages needed.

**Concrete example continued.** The previous example shared $a = 7$ via $P(X) = 7 + 3X$, giving shares $(10, 13, 16)$. Now suppose another party wants to share their private input $b = 5$. They construct $Q(X) = 5 + 2X$ and distribute:

- Party 1: $q_1 = Q(1) = 7$
- Party 2: $q_2 = Q(2) = 9$
- Party 3: $q_3 = Q(3) = 11$

After this exchange, each party holds two shares: party 1 holds $(s_1 = 10, q_1 = 7)$, party 2 holds $(s_2 = 13, q_2 = 9)$, party 3 holds $(s_3 = 16, q_3 = 11)$. Nobody knows $a = 7$ or $b = 5$ except the original owners.

To compute shares of $a + b$, each party adds their shares locally: party 1 computes $10 + 7 = 17$, party 2 computes $13 + 9 = 22$, party 3 computes $16 + 11 = 27$. These are evaluations of $(P + Q)(X) = 12 + 5X$ at points $1, 2, 3$. Interpolating any two recovers $(P + Q)(0) = 12 = a + b$. The sum was computed without anyone learning the inputs.

Addition and scalar multiplication are free. The cost of MPC concentrates entirely on multiplication.

### Multiplication: The Challenge

Multiplication breaks the easy pattern. The product of two shares is *not* a valid share of the product. Shamir sharing uses polynomials of degree $t-1$. If parties locally multiply their shares $P_a(j) \cdot P_b(j)$, they get evaluations of the product polynomial $P_a \cdot P_b$, which has degree $2(t-1)$. This polynomial does encode $ab$ at zero, but the threshold has effectively doubled: now $2t-1$ parties are needed to reconstruct, not $t$. Repeated multiplications would make the degree explode.

> **The Paint Analogy**
>
> Adding secret shares is like adding cups of the same color paint: if I have 1 cup of Red and you have 1 cup of Red, together we have 2 cups of Red. Easy.
>
> Multiplying is like mixing colors: Red times Blue makes Purple. You can't un-mix paint to recover the original colors. Worse, the "shade" of your result depends on both inputs in a non-linear way.
>
> Beaver Triples are like pre-mixed paint samples from a store. We don't know the exact shades (the store mixed them secretly), but we know that Sample A mixed with Sample B produces Sample C. When we need to multiply our real secret colors, we use these pre-mixed samples as a reference point, adjusting our result without ever revealing the original colors we started with.

Donald Beaver's solution is elegant. Before the computation begins, distribute shares of random *triples* $(u, v, w)$ satisfying $w = u \cdot v$. Nobody knows $u$, $v$, or $w$ individually, but everyone holds valid shares of all three.

To describe the protocol, we use bracket notation: $[a]$ means "the parties collectively hold Shamir shares of $a$," with each party holding one evaluation $P_a(j)$. To multiply $[a]$ by $[b]$ using a triple:

1. Parties compute $[\alpha] = [a] - [u]$ and $[\beta] = [b] - [v]$ locally (subtraction is linear, so each party $j$ subtracts their shares)
2. Parties reconstruct $\alpha$ and $\beta$ publicly by pooling shares (these values are masked by the random $u$ and $v$, so they reveal nothing about $a$ or $b$)
3. Parties compute $[ab] = [w] + \alpha \cdot [v] + \beta \cdot [u] + \alpha\beta$ locally (each party $j$ uses their shares of $w$, $v$, $u$ plus the now-public $\alpha$, $\beta$)

The algebra works because $ab = (u + \alpha)(v + \beta) = w + \alpha v + \beta u + \alpha\beta$. Each triple enables one multiplication and is consumed in the process. A preprocessing phase generates triples before inputs are known.

### Circuit Evaluation

With these building blocks, any arithmetic circuit can be evaluated. Share the inputs. Process gates in topological order: addition gates require no communication, multiplication gates consume one Beaver triple each. After the final gate, reconstruct the output by combining shares.

The communication cost is $O(n^2)$ field elements per multiplication (each party sends one message to each other party). Round complexity equals the circuit's multiplicative depth, since multiplications at the same depth can proceed in parallel.

## Garbled Circuits

Secret-sharing MPC generalizes naturally to $n$ parties, but requires rounds proportional to circuit depth. Each multiplication forces a round of communication. For deep circuits or high-latency networks, this cost compounds. Is there another approach, one that computes the entire circuit in constant rounds regardless of depth?

Yao's garbled circuits achieve exactly this for the **two-party** case. The approach is fundamentally asymmetric: one party (the *garbler*) encrypts the entire circuit and hands it to the other (the *evaluator*), who evaluates it blindly. The evaluator learns the output without learning any intermediate values, not even the structure of the gates they're evaluating.

### The Core Idea: Labels as Passwords

The key insight is to replace bits with passwords. Each wire in the circuit carries not a 0 or 1, but a random cryptographic label. For each wire, the garbler creates two labels: one that "means 0" and one that "means 1." The evaluator receives exactly one label per wire, the one corresponding to the actual value, but cannot tell which meaning it carries.

Why does this help? The evaluator computes the entire circuit without ever learning any intermediate values. They hold passwords that encode the computation, but the passwords themselves reveal nothing. A random 128-bit string looks the same whether it means 0 or 1.

### Garbling a Single Gate

How do gates compute on passwords instead of bits? The garbler precomputes all possible outputs and encrypts them so only the correct one can be recovered.

Consider an AND gate with input wires $L$ (left) and $R$ (right) and output wire $O$. The garbler generates six random labels, each a 128-bit string that doubles as a symmetric encryption key:

- Wire $L$: labels $L_0$ and $L_1$ (meaning "left input is 0" and "left input is 1")
- Wire $R$: labels $R_0$ and $R_1$
- Wire $O$: labels $O_0$ and $O_1$

The garbler creates these labels, so they know which label corresponds to which bit. The subscript in $L_0$ is the garbler's private bookkeeping: "this is the label I'll use when the left input is 0." The evaluator never sees this subscript. They receive a label like `9c2b...` with no indication of whether it means 0 or 1.

The plain truth table for AND is:

| Left | Right | Output |
|------|-------|--------|
| 0    | 0     | 0      |
| 0    | 1     | 0      |
| 1    | 0     | 0      |
| 1    | 1     | 1      |

The garbler transforms this into a *garbled table* by encrypting each output label under the corresponding input labels:

| Encrypted Entry |
|-----------------|
| $\text{Enc}_{L_0, R_0}(O_0)$ |
| $\text{Enc}_{L_0, R_1}(O_0)$ |
| $\text{Enc}_{L_1, R_0}(O_0)$ |
| $\text{Enc}_{L_1, R_1}(O_1)$ |

The encryption $\text{Enc}_{L_a, R_b}(O_c)$ uses both input labels as the key. Only someone who knows *both* $L_a$ and $R_b$ can decrypt the corresponding row.

But there's a problem: if the table rows stay in this order, the evaluator learns which row they decrypted and hence learns the input bits. The solution is simple: **randomly shuffle the rows**. After shuffling, the garbled table might look like:

| Shuffled Encrypted Entry |
|--------------------------|
| $\text{Enc}_{L_1, R_1}(O_1)$ |
| $\text{Enc}_{L_0, R_0}(O_0)$ |
| $\text{Enc}_{L_1, R_0}(O_0)$ |
| $\text{Enc}_{L_0, R_1}(O_0)$ |

Now the evaluator, holding one label for each input wire, tries to decrypt each row. Only one decryption succeeds (the one matching their labels), revealing the output label. They learn nothing about which row succeeded because the encryption includes authentication: wrong keys produce random garbage, not a valid label.

### Hash-Indexed Tables

There's an elegant alternative to random shuffling. Instead of listing ciphertexts in random order and trying all four, use the hash of the input labels as a row index:

| Row Index | Encrypted Entry |
|-----------|-----------------|
| $H(L_0, R_0)$ | $\text{Enc}_{L_0, R_0}(O_0)$ |
| $H(L_0, R_1)$ | $\text{Enc}_{L_0, R_1}(O_0)$ |
| $H(L_1, R_0)$ | $\text{Enc}_{L_1, R_0}(O_0)$ |
| $H(L_1, R_1)$ | $\text{Enc}_{L_1, R_1}(O_1)$ |

The evaluator, holding labels $L_a$ and $R_b$, computes $H(L_a, R_b)$ and looks up that row directly. No trial decryptions needed. The hash reveals nothing about which row was accessed since the evaluator doesn't know the other labels to compute their hashes.

This structure scales better: instead of trying all rows, the evaluator does one hash and one decryption per gate. For circuits with millions of gates, the difference matters.

### How the Evaluator Proceeds

With either approach (shuffled tables with trial decryption, or hash-indexed tables with direct lookup), the evaluator follows the same pattern. They hold one label per input wire, use those labels to decrypt exactly one entry from the garbled table, and obtain the output label. The output label becomes input to the next gate. The evaluator never learns which bit any label represents; they just propagate opaque 128-bit strings through the circuit.

### Chaining Gates Together

A single gate is not a computation. How do labels propagate through a circuit?

The key is consistency: the output labels of one gate become the input labels of subsequent gates. The garbler ensures that the labels generated as outputs of gate $G_1$ are the same labels used as inputs in gate $G_2$. The evaluator, holding one label per wire, can evaluate gate after gate, each time recovering exactly one output label to feed forward.

**Example: A tiny circuit.** Consider computing $(a \land b) \lor c$, which requires an AND gate followed by an OR gate.

```
       a ──┐
            ├── AND ──┬── t
       b ──┘          │
                      ├── OR ── output
       c ─────────────┘
```

The intermediate wire $t$ connects AND's output to OR's input. The garbler:

1. Generates labels for wires $a$, $b$, $c$, $t$, and $output$ (two labels per wire)
2. Creates a garbled table for AND using $a$'s and $b$'s labels as input keys, encrypting $t$'s labels as outputs
3. Creates a garbled table for OR using $t$'s and $c$'s labels as input keys, encrypting $output$'s labels as outputs
4. Sends both garbled tables to the evaluator

The consistency between gates requires no "enforcement" since the garbler controls construction. The labels $t_0$ and $t_1$ are created once, then used in two places: as the encrypted outputs of the AND table, and as the decryption keys indexed in the OR table. When the evaluator decrypts the AND gate and obtains (say) $t_0$, that exact string appears as an index in the OR table. The garbler wired them together at construction time.

The evaluator:

1. Receives labels for $a$, $b$, $c$ (via oblivious transfer for their inputs, directly for the garbler's inputs)
2. Evaluates the AND gate, obtaining a label for $t$
3. Uses the $t$ label plus the $c$ label to evaluate the OR gate
4. Obtains a label for the output wire

At the final output, the garbler reveals the mapping: "If your output label is $X$, the result is 0; if it's $Y$, the result is 1." Only now does the evaluator learn the actual output bit. This isn't a security breach: the whole point is for both parties to learn $f(a, b)$. The protection is that intermediate wire mappings stay hidden, so the evaluator learns only the final answer, not the computation path that produced it.

### A Concrete Walkthrough

The abstract description may still feel mysterious. Let's trace through a complete example with actual values: computing $a \land b$ where the garbler holds $a = 1$ and the evaluator holds $b = 0$.

**Setup.** The garbler generates random labels:

- Wire $a$: $L_0 = \texttt{3a7f...}$, $L_1 = \texttt{9c2b...}$
- Wire $b$: $R_0 = \texttt{5e81...}$, $R_1 = \texttt{d4a3...}$
- Wire $out$: $O_0 = \texttt{72f9...}$, $O_1 = \texttt{1b6e...}$

**Garbling.** The garbled table (before shuffling):

| Input Labels | Output Label | Ciphertext |
|--------------|--------------|------------|
| $L_0, R_0$   | $O_0$        | $\text{Enc}_{\texttt{3a7f...,5e81...}}(\texttt{72f9...})$ |
| $L_0, R_1$   | $O_0$        | $\text{Enc}_{\texttt{3a7f...,d4a3...}}(\texttt{72f9...})$ |
| $L_1, R_0$   | $O_0$        | $\text{Enc}_{\texttt{9c2b...,5e81...}}(\texttt{72f9...})$ |
| $L_1, R_1$   | $O_1$        | $\text{Enc}_{\texttt{9c2b...,d4a3...}}(\texttt{1b6e...})$ |

After random shuffling, the garbler sends the four ciphertexts in jumbled order.

**Evaluation.** The two input labels arrive through different channels:

- *Garbler's input*: The garbler knows their own input is 1, so they simply send $L_1 = \texttt{9c2b...}$ directly. No special protocol needed.
- *Evaluator's input*: The garbler holds both $R_0$ and $R_1$ but must not learn which the evaluator needs. The evaluator knows their bit is 0 but cannot reveal this. Via oblivious transfer, the evaluator receives $R_0 = \texttt{5e81...}$ without the garbler learning which label was transferred, and without the evaluator learning $R_1$.

The evaluator tries decrypting each of the four ciphertexts with key $(\texttt{9c2b..., 5e81...})$. Only one decrypts successfully, yielding $O_0 = \texttt{72f9...}$.

**Output.** The garbler reveals: "Output label $\texttt{72f9...}$ means 0." The evaluator learns the result: $1 \land 0 = 0$.

What did the evaluator learn? Only the output. They never learned that their label $R_0$ "meant 0" or that the garbler's input was 1. The computation proceeded entirely on encrypted values.

### Yao's Protocol (Two Parties)

With the mechanics clear, here's the full protocol:

Party A (the garbler) has input $x$. Party B (the evaluator) has input $y$. They want to compute $f(x, y)$.

In the **garbling phase**, A transforms the circuit into an encrypted version. For each wire $w$, A generates two random labels: $K_w^0$ (representing the bit 0) and $K_w^1$ (representing 1). For each gate, A creates a garbled table: four encryptions encoding the gate's truth table, randomly shuffled. A sends the garbled circuit (all garbled tables) to B.

In the **evaluation phase**, B learns the output without learning intermediate values. A sends the labels for their own input wires (the $K_w^{x_w}$ values corresponding to their actual input $x$). B obtains labels for their input wires via *oblivious transfer* (explained below), a primitive that lets B receive the label for their bit without A learning which bit B chose. Now B holds one label per input wire. For each gate, B uses the two input labels as decryption keys, recovering exactly one output label from the garbled table. Gate by gate, B propagates labels through the circuit until reaching the output wires. The final labels map to the output bits.

### Why It's Secure

B learns only one label per wire: the one corresponding to the actual computation path. The other label remains hidden. Since labels are random, B cannot distinguish $K_w^0$ from $K_w^1$ and learns nothing about intermediate values, only the output.

A learns nothing about B's input because the oblivious transfer hides B's choice. A sees only the garbled circuit and the labels for their own input.

### The Free-XOR Optimization

The basic protocol requires four encryptions per gate: one for each row of the truth table, covering all four input combinations $(0,0), (0,1), (1,0), (1,1)$. Can we do better for certain gate types?

A beautiful optimization makes XOR gates essentially free. The idea is to impose a global structure on all labels so that XOR "just works" algebraically, requiring no garbled table at all.

**The constraint.** The garbler chooses a random global secret $\Delta$ (a 128-bit string kept hidden from the evaluator). For *every* wire $w$ in the circuit, the garbler ensures:
$$K_w^1 = K_w^0 \oplus \Delta$$

That is, the two labels for any wire differ by exactly $\Delta$. The garbler picks $K_w^0$ randomly, then derives $K_w^1$ by XORing with $\Delta$. This constraint propagates through the entire circuit.

**Why this helps.** Consider an XOR gate: the output bit equals $a \oplus b$ where $a$ and $b$ are the input bits. The garbler defines the output labels as:
$$O_0 = L_0 \oplus R_0$$

Since the $\Delta$-constraint must also hold for the output wire, we need $O_1 = O_0 \oplus \Delta$. Let's verify this is consistent:
$$O_1 = O_0 \oplus \Delta = L_0 \oplus R_0 \oplus \Delta$$

**The magic.** The evaluator holds labels $L_a$ and $R_b$ (one for each input wire, corresponding to bits $a$ and $b$ that they don't know). They simply XOR them: $L_a \oplus R_b$. Why does this produce the correct output label $O_{a \oplus b}$?

- If $a = 0, b = 0$: evaluator computes $L_0 \oplus R_0 = O_0$ $\checkmark$ (and $0 \oplus 0 = 0$)
- If $a = 0, b = 1$: evaluator computes $L_0 \oplus R_1 = L_0 \oplus (R_0 \oplus \Delta) = O_0 \oplus \Delta = O_1$ $\checkmark$ (and $0 \oplus 1 = 1$)
- If $a = 1, b = 0$: evaluator computes $L_1 \oplus R_0 = (L_0 \oplus \Delta) \oplus R_0 = O_0 \oplus \Delta = O_1$ $\checkmark$ (and $1 \oplus 0 = 1$)
- If $a = 1, b = 1$: evaluator computes $L_1 \oplus R_1 = (L_0 \oplus \Delta) \oplus (R_0 \oplus \Delta) = L_0 \oplus R_0 = O_0$ $\checkmark$ (and $1 \oplus 1 = 0$)

In each case, the XOR of the input labels produces exactly the output label for bit $a \oplus b$. No encryption, no garbled table, no communication for that gate. The evaluator performs a single XOR operation and obtains the correct output label.

**Why is it secure?** The evaluator can't exploit the $\Delta$ structure because they never learn $\Delta$ itself. They see only one label per wire, a random-looking 128-bit string. Without knowing $\Delta$, they can't compute the other label or detect the relationship between wires.

This matters enormously in practice. XOR is the most common operation in many computations. Free-XOR reduces circuit size by 30-50% in typical applications.

### Complexity

Communication is $O(|C|)$, proportional to the circuit size, since each non-XOR gate requires a constant-size garbled table. (XOR gates are free.) Computation uses only symmetric-key operations (AES), making garbled circuits fast in practice. The protocol runs in constant rounds: one round to send the garbled circuit, one for oblivious transfers. This makes garbled circuits attractive when network latency dominates, since secret-sharing MPC requires rounds proportional to circuit depth.

## Oblivious Transfer

Garbled circuits solve almost all of the two-party computation problem, but leave one gap: how does the evaluator receive labels for their own input bits? The garbler knows both labels for each input wire ($K_w^0$ and $K_w^1$), but must give the evaluator exactly one, the one corresponding to their actual bit. The garbler cannot learn which bit the evaluator chose, and the evaluator cannot learn the other label.

This is *oblivious transfer* (OT): a sender holds two messages $m_0$ and $m_1$, a receiver holds a choice bit $b$, and after the protocol the receiver learns $m_b$ and nothing else while the sender learns nothing about $b$.

The requirement sounds contradictory. How can the sender give one message without knowing which? How can the receiver receive one without learning the other? Several elegant constructions make this possible.

### Construction from Commutative Encryption

Imagine an encryption scheme where the order of encryption and decryption doesn't matter:
$$\text{Dec}_b(\text{Dec}_a(\text{Enc}_b(\text{Enc}_a(x)))) = x$$

A physical metaphor: a box locked with two padlocks. Alice locks it with her padlock and sends it to Bob. Bob adds his padlock and sends it back. Alice removes her lock (Bob's lock doesn't block her). She sends it back. Bob removes his lock and opens the box. The message traveled securely without either party ever having full access.

Mathematically, exponentiation in a finite group provides commutative encryption: encrypt message $g$ with key $a$ by computing $g^a$. Decrypt by taking an $a$-th root. The order of operations doesn't matter since $(g^a)^b = (g^b)^a = g^{ab}$.

**The OT protocol.** Alice has $n$ messages $x_1, \ldots, x_n$. Bob wants $x_i$ without Alice learning $i$.

1. Alice encrypts all messages with her key $a$ and sends: $\text{Enc}_a(x_1), \ldots, \text{Enc}_a(x_n)$ in order
2. Bob picks out $\text{Enc}_a(x_i)$, encrypts it with his key $b$, and sends back $\text{Enc}_b(\text{Enc}_a(x_i))$
3. Alice decrypts with her key, obtaining $\text{Enc}_b(x_i)$, and sends it to Bob
4. Bob decrypts with his key to recover $x_i$

Why is Bob protected? Alice sees only a doubly-encrypted blob. She doesn't know Bob's key $b$, so she can't decrypt it to see which message he chose.

Why is Alice protected? Bob receives only one singly-encrypted message ($\text{Enc}_b(x_i)$ in step 3). The other $n-1$ messages remain encrypted under Alice's key, which Bob doesn't have.

### Construction from Diffie-Hellman

The commutative encryption approach requires three message rounds. Can we do better?

A more efficient construction reduces this using Diffie-Hellman key exchange. Work in a group $\mathbb{G}$ of prime order $q$ with generator $g$. The sender chooses random $a$ and sends $A = g^a$. The receiver, depending on their choice bit $b$, responds strategically: if $b = 0$, choose random $k$ and send $B = g^k$; if $b = 1$, send $B = A \cdot g^k = g^{a+k}$ for random $k$.

The sender computes two keys: $K_0 = B^a$ and $K_1 = (B \cdot A^{-1})^a$. Then the sender encrypts both messages, $c_0 = \text{Enc}_{K_0}(m_0)$ and $c_1 = \text{Enc}_{K_1}(m_1)$, and sends both ciphertexts.

The receiver can compute only one key. If $b = 0$, the receiver knows $k$ and can compute $K_0 = A^k = g^{ak}$, which equals $B^a$ since $B = g^k$. But $K_1 = (B/A)^a = g^{(k-a)a}$ requires knowing the discrete log of $B/A$, which the receiver doesn't have. The receiver decrypts $c_0$ and learns $m_0$. If $b = 1$, the situation reverses: the receiver can compute $K_1$ but not $K_0$.

The sender sees only $B$, a random group element that reveals nothing about whether the receiver chose $b = 0$ or $b = 1$.

### OT Extension

Both constructions require public-key operations: exponentiations in a group. For a single OT this is fast enough, but garbled circuits need one OT per input bit. A circuit with a million input bits would require a million exponentiations.

OT extension, pioneered by the IKNP protocol, breaks this barrier. A small number of base OTs ($\kappa$, the security parameter, typically 128) enable an unlimited number of extended OTs using only symmetric-key operations. The amortized cost drops to a few AES calls per OT. This makes garbled circuits practical even for inputs with millions of bits.

## Mixing Protocols

We now have two complete approaches to MPC: secret-sharing (optimal for arithmetic operations, but requires rounds proportional to depth) and garbled circuits (constant rounds, but expensive per gate). Neither dominates the other. Which should we use?

The answer, increasingly, is both. Real computations don't fit neatly into one paradigm. A machine learning inference might need field arithmetic for the linear layers (where secret-sharing MPC excels) but comparisons for activation functions (where Boolean circuits are better). The most efficient approach often switches representations mid-computation.

Modern MPC frameworks like ABY and MP-SPDZ support three representations: **A**rithmetic sharing for field operations, **B**oolean sharing for bitwise operations and comparisons, and **Y**ao's garbled circuits for complex Boolean functions that would require deep circuits in other representations.

Conversion protocols translate between representations. Arithmetic-to-Boolean (A2B) converts additive shares of a field element into XOR-shares of its bit representation. Boolean-to-Arithmetic (B2A) reverses the process, using oblivious transfer to handle the carry bits that arise when interpreting binary as an integer. Yao conversions (A2Y, Y2A, B2Y, Y2B) interface with garbled circuits.

The design problem becomes: given a computation, which operations should use which representation? The answer depends on the operation mix and the network characteristics. Deep multiplicative chains favor secret sharing (low communication per multiplication). Complex comparisons favor garbled circuits (constant rounds). The optimal decomposition is often hand-tuned for critical applications.

## MPC-in-the-Head: Where the Paths Converge

This chapter opened by observing that MPC and ZK developed in parallel, addressing different trust problems. But the connection runs deeper than shared history. MPC protocols can be *compiled* into zero-knowledge proofs through a transformation called "MPC-in-the-head."

The idea exploits a strange symmetry. In MPC, multiple real parties compute on secret-shared inputs, and the security guarantee is that no coalition learns more than the output. In MPC-in-the-head, a single prover *simulates* an MPC protocol entirely inside their own mind, playing all the parties simultaneously. The security guarantee transforms: instead of protecting inputs from other parties, it protects the witness from the verifier.

The construction works as follows. The prover secret-shares the witness among $n$ *imaginary* parties. Then the prover simulates the MPC protocol that would compute $R(x, w)$, playing all $n$ roles simultaneously. Each simulated party has a "view": the messages it sent and received, its random tape, its share of the witness. The prover commits to all $n$ views.

Think of the prover as a one-person theater troupe performing a conversation between three characters (Alice, Bob, Charlie). The prover writes out the full script: what Alice said to Bob, what Bob said to Charlie, what Charlie said to Alice. Then they seal each character's script in a separate envelope.

The verifier challenges: "Open the views of parties $i$ and $j$." (Show me Alice and Bob's envelopes.) The prover reveals those two views. The verifier checks consistency: do the messages that party $i$ claims to have sent match what party $j$ claims to have received? Did both parties follow the protocol correctly given their views? Does the MPC output equal 1? If Alice's script says she sent "7" to Bob, but Bob's script says he received "9" from Alice, the prover is caught lying. By randomly checking different pairs, the verifier catches any inconsistency in the performance.

Why is this sound? If the witness is invalid, the MPC would output 0. For the prover to fake acceptance, they must forge views where the MPC appears to output 1. But faking a valid MPC execution requires consistency across all parties. If any pair of views is inconsistent (messages don't match, or a party deviated from the protocol), the verifier catches it. A cheating prover can make some pairs consistent, but not all. The random challenge catches an inconsistent pair with constant probability. Repeat to amplify.

Why is this zero-knowledge? Opening $t-1$ views of a $t$-threshold MPC reveals nothing about the secret (by the MPC privacy guarantee). The verifier sees only a subset of views, not enough to reconstruct the witness.

### Instantiations

**ZKBoo and ZKB++** use 3-party secret sharing. The verifier opens 2 of 3 parties, giving a soundness error of $1/3$ per repetition. These schemes excel at proving knowledge of hash preimages, where the circuit structure is fixed and well-optimized.

**Ligero** combines MPC-in-the-head with Reed-Solomon codes, achieving proof size $O(\sqrt{n})$ for circuits with $n$ gates. This is sublinear, better than naive approaches though not as succinct as polynomial-based SNARKs.

**Limbo** and subsequent work push practical performance further, targeting real-world deployment for specific statement classes.



## Threshold Cryptography

MPC computes arbitrary functions on distributed inputs. But some functions appear so frequently that they deserve specialized treatment. Chief among these: cryptographic operations. What if the *key itself* is secret-shared?

Threshold cryptography applies MPC machinery to distribute cryptographic keys. Instead of a single party holding a signing or decryption key, $n$ parties each hold a share. Any $t$ of them can cooperate to sign or decrypt, but no coalition of fewer than $t$ learns anything about the key. The secret never exists in one place.

### Threshold Signatures

Consider the problem of institutional key custody. A cryptocurrency exchange holds billions in assets. A single signing key is a single point of failure: theft, coercion, insider attack. The traditional solution is multisig, where the blockchain verifies $t$-of-$n$ separate signatures. But multisig reveals the signing structure on-chain and requires protocol-level support.

Threshold signatures solve this differently. The $n$ parties hold shares of a single signing key $sk$. When $t$ cooperate, they produce a single signature that looks identical to a signature from a solo signer. The blockchain sees nothing unusual. The distribution is invisible.

**FROST** implements threshold Schnorr signatures with particular elegance. The protocol has two phases. In the first, parties jointly generate shares of a random nonce $k$ using Feldman's verifiable secret sharing (Appendix A). Each party contributes randomness, and the distributed nonce emerges without anyone learning its value. In the second phase, each party computes a partial signature using their share of $k$ and their share of $sk$. These partial signatures combine via Lagrange interpolation, the same reconstruction formula from Shamir's scheme. The result is a valid Schnorr signature.

The linearity of Schnorr makes this work. A Schnorr signature has the form $s = k + e \cdot x$ where $e$ is the challenge hash. If parties hold shares $k_i$ and $x_i$, they compute partial signatures $s_i = k_i + e \cdot x_i$. Lagrange interpolation reconstructs $s = k + e \cdot x$ exactly. FROST inherits Feldman's verifiability: parties can detect if someone contributes malformed shares during the nonce generation, catching cheaters before they can disrupt signing.

One important caveat: FROST's nonce generation phase requires **synchronous coordination**. All participating signers must be online simultaneously to jointly generate the nonce shares and exchange their commitments. If a signer goes offline during this phase, the protocol stalls. This synchronicity constraint can be problematic in real-world deployments where signers span different time zones or operate on unreliable networks.

**ROAST** addresses this limitation by wrapping FROST in a robust, asynchronous coordinator. Instead of requiring all $t$ signers to be online at once, ROAST has a coordinator that adaptively selects responsive signers. The coordinator maintains multiple concurrent signing sessions and gracefully handles signers who fail to respond. If a signer times out, the coordinator simply starts a new session with a different signer subset. The first session to complete produces the signature. ROAST doesn't modify FROST's cryptography; it adds a session management layer that tolerates network asynchrony and unresponsive parties, making threshold signing practical for geographically distributed deployments.

Threshold ECDSA is more complex. ECDSA signatures involve a modular inversion step, $s = k^{-1}(z + r \cdot x)$, and inversion is not linear. Computing it on shared values requires a full MPC protocol for the inversion, adding rounds and computational overhead. Protocols like GG18 and GG20 solve this but at higher cost than FROST.

### Threshold Decryption

The same distribution principle applies to decryption. Parties hold shares of a decryption key. When a ciphertext arrives, each party contributes a partial decryption using their share. The threshold combines these contributions to recover the plaintext, but no party ever holds the full key.

This structure appears in voting systems, where an encrypted ballot should only be decrypted after polls close and only if enough trustees cooperate. It appears in key escrow, where law enforcement access requires multiple parties to agree. And it appears in distributed custody systems, where no single server compromise can steal user funds.

## Practical Considerations

The theoretical protocols are complete: given enough time and bandwidth, any function can be computed securely. But theory and practice diverge. What determines whether an MPC deployment actually works?

### Communication Patterns

The network topology shapes everything. MPC protocols differ in how parties communicate, and the choice significantly affects performance. In a star topology, all parties route messages through a central dealer or combiner. This simplifies coordination but creates a bottleneck and a single point of failure. In full connectivity, every party communicates directly with every other party. This eliminates the central bottleneck but requires $O(n^2)$ connections. Broadcast protocols have each message go to all parties simultaneously, useful when the computation requires everyone to see the same values (like reconstructing a shared secret).

The bottleneck inversion between ZK and MPC deserves emphasis. In ZK, the bottleneck is usually **compute**: the prover performs heavy cryptographic work (MSMs, FFTs, hashes) and sends relatively small proofs. In MPC, the bottleneck is almost always **bandwidth**: many parties do lightweight operations but exchange massive amounts of data. A ZK prover might spend 10 seconds computing and 10 milliseconds sending. An MPC protocol might spend 10 milliseconds computing and 10 seconds sending. This inversion dictates architecture: you can run a ZK prover on a single powerful machine, but you can't run high-speed MPC over a 4G connection.

Network latency often dominates the cost of MPC. A protocol that requires 100 rounds of communication will be slow even if each round sends only a few bytes. This is why garbled circuits, with their constant round complexity, often outperform secret-sharing MPC for interactive applications despite sending more data. The design choice depends on whether bandwidth or latency is the limiting factor.

### Preprocessing vs. Online

A key optimization divides MPC into two phases. The preprocessing phase generates correlated randomness before the actual inputs are known. Beaver triples for multiplication, OT correlations for garbled circuits, and random sharings for masking all fall into this category. The online phase consumes this preprocessed material to compute on the real inputs.

This separation has practical benefits. Preprocessing can happen during idle time, spreading the computational cost across hours or days. When the actual computation is needed, the online phase runs quickly using the stockpiled randomness. For applications like sealed-bid auctions, where parties submit bids that must be processed immediately, the preprocessing model allows sub-second latency despite the underlying cryptographic complexity.

Where does the preprocessing come from? One option is a trusted dealer who generates and distributes the correlated randomness. This is simple but reintroduces trust. Another option is to generate the preprocessing via MPC itself, a slower process that pays the full cost but requires no trusted party. A third option uses hardware: trusted execution environments can generate the randomness with attestation that the correct distribution was used.

### Malicious Security

Everything so far assumes semi-honest adversaries: parties who follow the protocol faithfully but try to extract information from what they observe. What if an adversary can deviate arbitrarily, sending malformed messages or aborting at strategic moments?

Adding security against malicious adversaries roughly doubles the computational cost.

For secret-sharing MPC, malicious security requires authenticating every share. The SPDZ protocol attaches a Message Authentication Code (MAC) to each shared value. When shares are combined or reconstructed, the MACs are verified. A cheating party who modifies a share will fail the MAC check with overwhelming probability.

Consistency checks at each gate catch parties who compute incorrectly. The SPDZ preprocessing includes authenticated triples, and the online phase verifies that multiplications respect the triple structure.

For garbled circuits, malicious security faces a different challenge. The semi-honest protocol assumes the garbler constructs the circuit correctly. A malicious garbler could create a circuit that computes the wrong function, leaking information about the evaluator's input. How can the evaluator verify the circuit without being able to inspect it?

**Cut-and-choose** solves this with redundancy. The garbler creates $s$ independent garbled circuits for the same function (typically $s = 40$ or more). The evaluator randomly partitions these circuits: select a fraction (say, half) to *check* and the rest to *evaluate*.

For checked circuits, the garbler reveals everything: all labels, all randomness used during garbling. The evaluator reconstructs the circuit from scratch and verifies it matches what was sent. If any checked circuit is malformed, the evaluator aborts and the garbler is caught cheating.

For evaluated circuits, the protocol proceeds normally. The evaluator computes on all of them and takes the majority output. Even if the garbler cheated on some evaluated circuits, majority voting ensures correctness as long as most circuits are honest.

The security argument: the garbler doesn't know which circuits will be checked. If they cheat on $k$ circuits, the probability that *all* cheated circuits end up in the evaluated set (avoiding detection) is roughly $(1/2)^k$. Cheating is exponentially unlikely to succeed.

**Point-and-permute** is a simpler optimization that improves efficiency without full cut-and-choose. The garbler appends a random "pointer bit" to each label. The four rows of a garbled table are sorted by these pointer bits rather than randomly shuffled. The evaluator, holding input labels with their pointer bits, immediately knows which row to decrypt without trying all four. This reduces decryption work from 4 attempts to 1.

These overheads explain why many practical deployments assume semi-honest adversaries when the trust model permits it. Malicious security is achievable, but it comes at a cost.

## Key Takeaways

1. **MPC eliminates trusted third parties**: Any function computable by a circuit can be computed jointly by mutually distrustful parties, revealing only the output. The theoretical result is complete; practical efficiency is the ongoing challenge.

2. **Two paradigms, different tradeoffs**: Secret-sharing MPC (BGW) handles $n$ parties and makes linear operations free, but requires communication rounds proportional to circuit depth. Garbled circuits achieve constant rounds for two parties, but require communication proportional to circuit size.

3. **Multiplication is the bottleneck**: In secret-sharing MPC, addition and scalar multiplication need no communication. Multiplication consumes preprocessed Beaver triples and forces a round of interaction. Circuit design should minimize multiplicative depth.

4. **Oblivious transfer is fundamental**: OT lets a sender transmit one of two messages without learning which was received, and lets the receiver learn one without accessing the other. This seemingly impossible primitive underlies garbled circuits and much else. OT extension makes it practical at scale.

5. **Free-XOR transforms garbled circuit efficiency**: By constraining labels so that $K_w^1 = K_w^0 \oplus \Delta$ for a global secret $\Delta$, XOR gates require no garbled table at all. This reduces circuit size by 30-50% in typical applications.

6. **MPC-in-the-head bridges MPC and ZK**: Simulate an MPC protocol in your head, commit to all party views, let the verifier audit a random pair. MPC privacy becomes ZK; MPC correctness becomes soundness. This compiler yields practical ZK proofs (ZKBoo, Ligero) without polynomial machinery.

7. **Threshold cryptography distributes trust**: Secret-share a signing or decryption key among $n$ parties. Any $t$ can operate; fewer than $t$ learn nothing. The key never exists in one place. FROST makes threshold Schnorr practical; ROAST adds asynchrony.

8. **Preprocessing separates costs**: Generate Beaver triples and OT correlations during idle time. The online phase consumes this stockpile, achieving low latency when inputs arrive. The split enables sub-second MPC for time-sensitive applications.

9. **Malicious security is achievable but costly**: SPDZ authenticates shares with MACs; cut-and-choose forces honest garbling. Both roughly double the work. Choose based on your trust model.


\newpage

# Chapter 25: Frontiers and Open Problems

In 1894, physicist Albert Michelson declared that "the more important fundamental laws and facts of physical science have all been discovered." Physics was done; all that remained was measuring constants to more decimal places. Eleven years later, Einstein published Special Relativity. Then came quantum mechanics. Michelson had mistaken a plateau for a summit.

In 2020, SNARKs felt similarly settled. We had Groth16 for minimal proofs and PLONK for universal setups. The trade-offs seemed fixed, the design space mapped. Then came the Lookup Revolution (2020), Folding (2021), and Binary Fields (2023). Each reshaped what we thought possible.

This chapter is a reminder that we are not at the end of history. The "fundamental laws" of ZK are still being written. The techniques described here are the Special Relativity moments of our decade: advances that didn't refine existing theory but rewrote it.

The frontiers span a remarkable range: from the algebraic structure of binary fields to the engineering of GPU kernels, from quantum threat models to the economics of decentralized proving markets. What unites them is a common goal: making proofs smaller, faster, and more trustworthy.

This chapter surveys those frontiers. Some involve hardness assumptions we cannot yet prove. Others involve efficiency gaps between what theory permits and what practice achieves. A few touch questions so deep that resolving them would reshape our understanding of computation itself. Think of what follows as a map of the territory we have not yet conquered.



## Small-Field SNARKs and Binius

### The Overhead Problem

Every proof system in this book operates over large prime fields (typically 254-bit or 256-bit elements). But most real-world data is small: booleans, bytes, 32-bit integers. Representing a single bit as a 256-bit field element wastes 255 bits of capacity.

This isn't merely inelegant; it's expensive. Field multiplications dominate prover time. Each multiplication operates on the full 256 bits even when the "meaningful" data is tiny. For bit-level operations (hashing, AES, bitwise logic) the overhead is a factor of 256×.

### Binary Fields: The Natural Solution

**Binius** takes a radical approach: work over binary fields $\mathbb{F}_{2^k}$ where field elements are actual $k$-bit strings. A boolean is a 1-bit field element. A byte is an 8-bit field element. No padding, no waste.

> **The Native Language Analogy**
>
> Imagine a Spanish speaker forced to express every thought in German, even when talking to other Spanish speakers. Every sentence requires mental translation. Simple ideas become laborious.
>
> This is what traditional SNARKs do. They force computer data (bits and bytes) into prime fields (large numbers). A single bit becomes a 256-bit integer. The computer "thinks" in binary, but the proof system demands a foreign representation.
>
> Binius speaks the computer's native language. It treats bits as bits. It doesn't translate "0" into a 256-bit representation of zero; it keeps it as a single bit. No translation, no overhead.

The arithmetic of binary fields differs from prime fields. Addition is XOR (free in hardware). Multiplication uses polynomial arithmetic over $\mathbb{F}_2$. There are no "negative" elements; the field characteristic is 2. This seems like a step backward; binary fields lack the convenient structure of prime-order groups. But Binius recovers efficiency through clever protocol design.

### The Binius Architecture

Binius combines several innovations:

**Multilinear polynomials over towers of binary fields.** Instead of a single large field, use a tower: $\mathbb{F}_2 \subset \mathbb{F}_{2^2} \subset \mathbb{F}_{2^4} \subset \mathbb{F}_{2^8} \subset \ldots$ Each level doubles the extension degree. Small values live in small fields; only the cryptographic randomness requires the full tower height.

What does "operating in a tower" mean concretely? Each level is a field extension: $\mathbb{F}_2$ contains just $\{0,1\}$ with XOR addition; $\mathbb{F}_{2^8}$ contains 8-bit elements (bytes); $\mathbb{F}_{2^{128}}$ provides cryptographic security. The key insight: *elements of smaller fields are also elements of larger fields*. A bit in $\mathbb{F}_2$ can be viewed as an element of $\mathbb{F}_{2^{128}}$; it's just a very special element.

This enables a crucial optimization: store witness data in the smallest field that fits (bits stay bits, bytes stay bytes), perform arithmetic at the appropriate level, and only "lift" to the full tower when random challenges enter. The 256× overhead of representing a single bit as a 256-bit field element vanishes.

(Note: this "tower" is unrelated to the "tower of proofs" in Chapter 22's recursion discussion. There, "tower" refers to proofs-of-proofs: $\pi_1 \to \pi_2 \to \pi_3$. Here, "tower" refers to nested field extensions. Both exploit hierarchical structure (recursion avoids re-proving entire computations; field towers avoid doing large-field arithmetic on small values) but the mechanisms are distinct.)

**GKR-based multiplication.** Binary field multiplication is non-trivial: it's polynomial multiplication modulo an irreducible polynomial. Rather than encoding this as constraints (expensive), Binius uses the GKR protocol to verify multiplications. The prover commits only to inputs and outputs; intermediate multiplication steps are checked via sum-check.

**FRI over binary fields (FRI-Binius).** The FRI low-degree test adapts to binary domains, but the standard folding approach doesn't directly transfer: the squaring map $x \mapsto x^2$ is not 2-to-1 on binary fields as it is over roots of unity. FRI-Binius instead uses *subspace vanishing polynomials* combined with an *additive NTT* to achieve the necessary folding structure. The technique draws a connection between the Novel Polynomial Basis and binary field FRI, enabling efficient commitment to polynomials over tiny fields like $\mathbb{F}_2$ with no embedding overhead.

### Performance Implications

For bit-intensive computations, Binius achieves order-of-magnitude improvements:

| Operation | Traditional (256-bit field) | Binius |
|-----------|-----------------------------|--------------------|
| SHA-256 hash | ~25,000 constraints | ~5,000 constraints |
| AES block | ~10,000 constraints | ~1,000 constraints |
| Bitwise AND | 1 constraint + range check | 1 native operation |

The savings compound: fewer constraints mean smaller polynomials, faster FFTs, smaller proofs.

### Current Status and Challenges

Binius is under active development. Polygon and Irreducible have been building production-grade Binius-based systems, with ongoing testing and iteration. But despite the compelling performance numbers, several challenges explain why existing zkVMs haven't switched wholesale.

**The tradeoff: prover speed vs proof size.** Binius achieves much faster proving but produces larger proofs and slower verification than FRI-based systems. For on-chain verification where calldata costs dominate, this tradeoff matters. A 5× faster prover doesn't help if verification gas costs double.

**Recursion is harder.** Verifying a Binius proof inside another Binius proof requires embedding binary field arithmetic, which is non-trivial when the verifier circuit itself uses binary fields. The algebraic structure that makes Binius fast for computation makes it awkward for recursive self-verification.

**The workload mix.** Binius shines for bit-intensive operations: hashing, AES, bitwise logic. But zkVMs also do 32/64-bit arithmetic, memory operations, control flow. The benefits are less dramatic for these. Some researchers suggest Binius may be better suited for *precompiles* (hash functions, signature verification) rather than full VM execution: use Binius where it wins, prime fields elsewhere.

**Prover memory.** The tower structure requires careful memory management. Naive implementations have high memory overhead.

**Tooling gap.** Existing circuit languages target prime fields. New frontends that exploit binary field structure are needed.

The broader lesson: matching the proof system's field to the computation's natural representation eliminates artificial overhead. Binius is the most developed example, but the principle applies generally. The future likely involves *hybrid* systems: Binius for hash-heavy components, traditional fields for arithmetic-heavy components, composed via the techniques from Chapter 22.

But field representation is only one axis of adaptation. Another looms larger on the horizon: the cryptographic assumptions themselves.

## Post-Quantum SNARKs

### The Coming Storm

Shor's algorithm threatens the foundations of modern cryptography. Running in polynomial time on a quantum computer, it breaks discrete logarithm (the assumption underlying Schnorr, Pedersen, Bulletproofs), integer factoring (the assumption underlying RSA), and elliptic curve discrete log (the assumption underlying all pairing-based SNARKs).

What do these problems share? They all have **hidden periodic structure in abelian groups**. Factoring $N$ reduces to finding the period of $a^x \mod N$. Discrete log in $\langle g \rangle$ reduces to finding the period of $g^a h^b$. Shor's algorithm applies the *quantum Fourier transform* (QFT) to extract this periodicity in polynomial time. The QFT is the key ingredient: it converts quantum superposition over exponentially many values into a measurement that reveals the period. Any problem with hidden abelian group structure falls to this attack.

Hash functions survive because they're designed to have *no* exploitable structure: no periodicity, no algebraic relations. Grover's algorithm provides only a generic $\sqrt{N}$ search speedup (quadratic, not exponential), which doubling the hash output neutralizes.

Every system in Part IV of this book (Groth16, PLONK, KZG-based constructions) will become insecure once cryptographically-relevant quantum computers exist.

Timeline estimates vary wildly: 10 years, 20 years, 30 years, never. But "never" is a dangerous bet for infrastructure with long lifespans. Financial systems, identity infrastructure, archival signatures: these need security guarantees that extend decades into the future.

### Current Paths Forward

**Hash-based systems.** STARKs and FRI rely only on collision-resistant hashing. Since hash functions resist Shor (no hidden periodic structure) and Grover only provides quadratic speedup, STARKs are the current practical choice for post-quantum proofs. Their large proof sizes limit some applications, but they work today.

**Lattice-based commitments.** Replace Pedersen commitments with schemes based on Module-LWE or similar lattice problems. Why do lattices resist quantum attacks? Because they lack the hidden periodic structure that Shor exploits. The problem "find a short vector in this high-dimensional lattice" has no known abelian group structure for QFT to extract.

The approach: commit to a polynomial $f(X)$ by encoding its coefficients as a lattice point. The "hardness of finding short vectors" ensures binding (can't open to a different polynomial). Noise flooding or rejection sampling provides hiding.

The algebraic structure is richer than hashes: you can perform homomorphic operations on commitments (add them, sometimes multiply). This enables sum-check-style protocols without the overhead of pure symmetric-key approaches. But there's a catch: the noise in LWE grows with operations. After too many homomorphic steps, noise overwhelms signal. Managing this requires larger parameters, meaning larger commitments and proofs. Current constructions run 10-100× slower than hash-based alternatives for equivalent security.

**Symmetric-key SNARKs.** Build entirely from symmetric primitives: hashes, block ciphers, nothing else. The MPC-in-the-head paradigm (Ligero, Limbo, and descendants) follows this path.

The key insight: instead of algebraic assumptions, simulate an MPC protocol *inside the prover's head*. The prover imagines $n$ virtual parties holding secret shares of the witness. These virtual parties execute an MPC protocol that verifies the computation. The prover commits (via hash) to all parties' views: their inputs, randomness, and messages exchanged.

The verifier challenges: "reveal the views of parties $i$ and $j$." The verifier checks that those two views are consistent with honest execution. If the prover cheated, at least one pair of parties has inconsistent views. With enough challenges, cheating is detected with high probability.

Why is this post-quantum? The only cryptographic primitive is the hash-based commitment to parties' views. No discrete log, no pairings, no lattices. Security reduces to collision resistance of the hash function.

Why is it slow? The MPC protocol has communication overhead. Even efficient protocols require $O(|C|)$ work per multiplication gate, where $|C|$ is the circuit size. The prover must simulate all of this. Ligero improved this with linear-time proving via interleaved Reed-Solomon codes, but constants remain large, typically 10-100× slower than algebraic SNARKs.

See Chapter 24 for the underlying MPC techniques.

### Open Problems

The post-quantum SNARK landscape faces three interrelated challenges. First, lattice-based polynomial commitments remain 10-100× slower than hash-based alternatives. Can we close this gap while maintaining rigorous security? Second, security reductions are often loose; the concrete security is much worse than asymptotic claims suggest. Tighter reductions would either increase confidence or reveal that larger parameters are needed. Third, the transition period creates its own problem: can we build hybrid systems secure against *both* classical and quantum adversaries without paying twice the cost?

The post-quantum transition will reshape the SNARK landscape, but it operates on a timescale of years to decades. Meanwhile, a different revolution is already underway: the race to prove arbitrary computation.

## zkVMs: The Universal Prover

### The Vision

Every proof system we've studied requires translating the computation into a constraint system: R1CS, AIR, PLONKish gates. This translation is a specialized craft. Experts hand-optimize circuits for months; a single bug invalidates the work. The barrier to entry is enormous.

zkVMs invert this relationship. Instead of adapting computations to proof systems, adapt proof systems to computations. Compile any program to a standard virtual machine (RISC-V, EVM, WASM) and prove correct execution. The zkVM handles memory reads and writes, branching and loops, function calls and returns. Write your logic in Rust or any high-level language. Compile to the target ISA. Prove execution. No circuit engineering required.

### The Current Race

The zkVM landscape has stratified into distinct architectural approaches, each with different tradeoffs.

**Jolt (a16z).** The sum-check purist. Built entirely on multilinear polynomials and the Lasso lookup argument from Chapter 20. The philosophy: "Just One Lookup Table." Implement CPU instructions via lookups into structured tables rather than hand-crafted constraint systems. As of mid-2025, achieves over 1 million RISC-V cycles per second on a 32-core CPU, with ~50KB proof sizes (an order of magnitude smaller than STARK-based alternatives). The lookup-centric architecture sidesteps quotient polynomials and grand products. A streaming prover is under development that will prove arbitrarily long executions in under 2GB RAM, enabling mobile proving with minimal recursion overhead.

**RISC Zero.** The production workhorse. STARK-based with FRI commitments over the Baby Bear field, targeting RISC-V. Uses continuations to split large computations into bounded segments (~$10^6$ cycles), proves each with STARK, then aggregates via recursion. Final proofs wrap in Groth16 for cheap on-chain verification. The Bonsai network provides prover-as-a-service infrastructure, abstracting away proof generation entirely. R0VM 2.0 (April 2025) reduced Ethereum block proving from 35 minutes to 44 seconds. The "dual-engine" strategy: Bonsai for hosted enterprise proving, Boundless for a decentralized proof marketplace.

*Note on continuations:* Continuations are a specific flavor of recursion. Instead of proving the entire computation history at each step, you prove only the current segment plus a commitment to the previous segment's final state (a memory root or hash). This lets you pause and resume computation at arbitrary points, which is critical for programs that run longer than a single proof cycle allows. Think of it as a checkpoint system: each segment proves "I started from this checkpoint and reached that checkpoint," rather than "I verified everything that came before me."

**SP1 (Succinct).** The precompile optimizer. Cross-table lookup architecture with a flexible precompile system that accelerates common operations (signature verification, hashing) by 5-10× over raw RISC-V. A *precompile* is essentially a "cheat code" for the VM: instead of executing a SHA-256 hash step-by-step through thousands of RISC-V instructions, the VM recognizes the operation and delegates it to a specialized, hand-optimized sub-circuit. Think of it as a GPU inside the CPU specifically for heavy cryptographic math. SP1 Hypercube (2025) moved from STARKs to multilinear polynomials, achieving real-time Ethereum proving: 99.7% of L1 blocks proven in under 12 seconds on 16 GPUs. First general-purpose zkVM to eliminate proximity gap conjectures. The team estimates a real-time prover cluster could be built for ~$100K in hardware.

**Zisk (Polygon spinoff).** The latency minimizer. Spun out of Polygon's zkEVM team (led by co-founder Jordi Baylina) in June 2025, with all Polygon zkEVM IP transferred to the new entity. Built on RISC-V 64, designed from the ground up for low-latency distributed proving. Features a 1.5GHz zkVM execution engine, highly parallelized proof generation, GPU-optimized code, and advanced aggregation circuits. The architecture targets real-time Ethereum block proving via massive parallelization across prover clusters.

**zkWASM and others.** Target WebAssembly, enabling proofs of browser-compatible code. Useful when the goal is proving execution of existing web applications rather than purpose-built programs.

The competition is fierce and productive. Notice the convergence: multiple teams moving toward multilinear polynomials (away from univariate STARKs), real-time proving as the target, and precompiles for common operations. Techniques developed for one system often transfer to others.

### Architectural Insights from Production Systems

Several zkVM design patterns have emerged that generalize beyond specific implementations:

**The stack machine insight.** Traditional CPU architectures distinguish registers (fast, few) from memory (slow, large). In ZK circuits, this distinction vanishes: both register access and memory access are polynomial lookups with identical cost. Valida exploited this by eliminating general-purpose registers entirely, using a stack machine instead. The simplification reduces per-cycle constraint count and CPU state complexity. Any zkVM designer should ask: does our architecture carry assumptions from physical hardware that don't apply in ZK?

**Segment-based proving.** Long computations face a memory wall: proving $10^9$ cycles requires holding intermediate state for $10^9$ steps. RISC Zero's approach: split execution into bounded segments (~$10^6$ cycles each), prove each segment independently, then aggregate via recursive composition (lift/join). Peak prover memory stays bounded regardless of total computation length. This is a general pattern: unbounded computation can always be factored into bounded pieces with recursive aggregation.

**Challenge-based memory arguments.** Memory consistency can be verified two ways: Merkle trees (commit to memory state, prove access via authentication paths) or algebraic challenges (accumulate memory operations into fingerprint polynomials, verify consistency via Schwartz-Zippel). The Merkle approach requires hashing inside the circuit, which is expensive. The challenge approach (used in SP1, related to Twist-and-Shout from Chapter 20) uses only field arithmetic. For memory-heavy workloads, the difference is 10×+.

**The precompile pattern.** Some operations appear frequently and have specialized efficient circuits: SHA256, Keccak, ECDSA, pairing computations. Rather than interpreting these through the general VM, zkVMs expose "precompiles," direct circuit implementations that run 10-100× faster than interpreted execution. The trade-off: each precompile adds engineering complexity and circuit size. The design question: which operations justify dedicated circuits? Current heuristics target cryptographic primitives, as they're both expensive (many constraints per operation) and common (appear in most blockchain applications).

### Open Problems

The zkVM overhead problem dominates. Current systems run 100-1000× slower than native computation. A program that runs in 1 second requires 100-1000 seconds to prove. Can we approach 10×? Approaching 1× seems impossible with current techniques, but every generation of proof systems has surprised us.

Memory efficiency presents a related challenge. A 4GB address space means $2^{32}$ potential memory cells, far too many to commit individually. Virtual polynomial techniques (Chapter 20) help, but scaling to gigabytes of working memory remains challenging.

Then there's the precompile selection problem. Adding dedicated circuits for common operations (hashing, signatures) improves performance 10-100× for those operations, but each precompile requires engineering effort. Current systems hand-pick based on blockchain workloads. General-purpose proving may need different choices. Can we automate precompile discovery, identifying hot operations and generating specialized circuits?

> **A note on circuit-friendly signatures**: The ECDSA verification bottleneck has driven adoption of EdDSA over "embedded" curves like BabyJubJub, curves whose base field equals the scalar field of the outer proving curve (typically BN254 or BLS12-381). EdDSA verification becomes native field arithmetic rather than expensive non-native simulation. This design pattern, choosing cryptographic primitives for circuit efficiency, recurs throughout ZK system design.

Finally, parallelization: most zkVMs are inherently sequential, each instruction depending on the previous state. But physical computation increasingly relies on parallelism. How do we prove parallel programs efficiently? How do we exploit prover parallelism for sequential programs?

The zkVM race demonstrates a recurring pattern: performance improvements come from both algorithms (better proof systems, smarter memory arguments) and systems engineering (GPU kernels, distributed proving, careful memory management). The field is young enough that order-of-magnitude gains still come regularly.

But speed means nothing if the proofs are wrong.

## Formal Verification

### The Invisible Bugs

A bug in a ZK system is uniquely dangerous. Unlike a crash, which announces itself loudly, a soundness bug operates in silence. An attacker exploits it to forge proofs; the verifier accepts; the system behaves as though everything is fine. By the time the compromise is discovered, the damage is done.

High-profile vulnerabilities have been found in deployed systems: missing constraint checks that allowed witnesses to satisfy constraints they shouldn't, incorrect range assumptions that permitted overflow attacks, field confusion bugs where values were interpreted in the wrong field. These are not hypothetical risks. They have happened. They will happen again.

### Current Efforts

Several approaches are gaining traction. Verified compilers prove that compilation from a high-level circuit language to low-level constraints preserves semantics. If the compiler is verified, bugs in the source circuit remain bugs in the source circuit, not silent specification violations introduced by translation.

Machine-checked formal soundness proofs (in Coq, Lean, Isabelle) establish that the protocol is sound by construction. A formal proof eliminates entire classes of bugs.

Static analysis tools detect common vulnerability patterns in circuit code: unconstrained variables, degree violations, missing range checks. These catch bugs before deployment rather than after exploitation.

### Open Problems

The verification challenge is the gaps between verified components. You might verify the compiler but not the runtime, the protocol but not the implementation, the circuit but not the witness generator. Bugs hide at the boundaries. End-to-end verification, covering the entire stack from source code to final proof, remains an open problem.

Automated bug finding offers a complementary approach. Can we build fuzzers or symbolic executors specifically designed for ZK circuits? The search space is enormous, but constraint systems have structure that might enable efficient exploration.

Perhaps the hardest challenge: verification of optimized implementations. The fastest code uses hand-tuned assembly, GPU kernels, FPGA bitstreams. These are inherently hard to verify. How do we maintain security guarantees when performance demands low-level optimization?

Formal verification addresses correctness; the next frontier is raw performance.

## Hardware Acceleration

### The Computational Bottleneck

Prover computation is dominated by a few operations: multi-scalar multiplication (computing $\sum_i s_i \cdot G_i$ for scalar and point vectors), number-theoretic transforms (converting between coefficient and evaluation representations), and hash evaluations (for FRI, Merkle trees, Fiat-Shamir).

These workloads share a common structure: massive parallelism with minimal branching. CPUs are optimized for the opposite: branch prediction, cache locality, and general-purpose control flow. This mismatch creates opportunity.

### Current Approaches

GPUs provide 10-100× speedup for MSM and NTT, which are massively parallel by nature. Libraries like cuSNARK and ICICLE offer CUDA implementations. FPGAs offer energy efficiency and latency advantages, with the ability to implement custom arithmetic units for specific field sizes. ASICs represent the ultimate optimization: custom chips designed specifically for ZK proving. Several companies are developing these, betting that proof generation will become a significant computational market.

### Open Problems

Memory bandwidth increasingly dominates. Large circuits require gigabytes of data; memory transfer between CPU and GPU often exceeds computation time. Minimizing data movement requires new algorithms designed with memory hierarchy in mind.

This suggests a deeper opportunity: algorithm-hardware co-design. Current proof systems were designed for CPUs. What if we designed protocols that explicitly exploit GPU or ASIC parallelism? The FFT is elegant but assumes certain memory access patterns. A proof system designed around GPU memory hierarchy might look very different.

Decentralized proving poses its own challenges. How do we distribute proving across many machines without trusted coordination? Recursive composition provides one answer (each machine proves a piece, proofs aggregate), but the coordination overhead is substantial.

Hardware acceleration speeds up individual provers. But often the bottleneck isn't proving one thing fast enough; it's proving *many* things at all.

## Aggregation and Batching

### The Verification Problem

Blockchain applications face a scaling challenge on the verification side. A rollup might process millions of transactions. A privacy system might have millions of users. Each transaction, each credential, each computation generates a proof. Verifying them individually costs $O(n)$ time. For large $n$, verification becomes the bottleneck even if each individual proof is fast.

### Current Techniques

Three main approaches have emerged. Recursive aggregation proves that you verified $n$ proofs; the aggregation proof attests to all underlying proofs, making verification cost constant regardless of $n$. Batch verification uses clever randomization to check $n$ proofs with work sublinear in $n$; pairing-based proofs can sometimes batch to roughly 2× the cost of a single verification. Proof compression wraps a large proof (STARK) in a small proof (Groth16); the inner proof is never revealed, and the outer proof serves as a constant-size attestation.

### Open Problems

Recursion adds significant prover overhead since proving verification is expensive. Can we aggregate proofs without proving verification? Some approaches use algebraic structure (e.g., aggregating KZG openings), but general solutions remain elusive.

Incremental aggregation poses another challenge. Given an aggregate of $n$ proofs, how do we add proof $n+1$ without recomputing from scratch? Naive recursion requires touching all previous proofs.

Cross-system aggregation may be the most ambitious goal: can we aggregate proofs from *different* proof systems into a single attestation? A Groth16 proof and a STARK proof combined without exposing either?

Aggregation addresses the question of how to combine proofs after they exist. But there's an earlier bottleneck, one that often dominates total proving time.

## Witness Generation

### The Hidden Cost

Discussions of prover efficiency focus on the cryptographic work: computing commitments, running sum-check, evaluating polynomials. But there's a step before that. The witness includes not just the prover's secret input but all intermediate values in the computation. For a circuit with $n$ gates, the witness has $O(n)$ elements. Computing these elements (executing the circuit) can take longer than the proving step itself.

> **The Hidden Iceberg**
>
> Academic papers report "prover time" as the time spent on cryptographic operations: MSMs, FFTs, hashes. But the full cost of generating a proof includes witness generation, and this is often the larger piece.
>
> Think of an iceberg. The cryptographic prover is the visible tip above water. Witness generation is the massive bulk beneath the surface. A paper might report "proving takes 10 seconds" while silently omitting that witness generation took 60 seconds. The total time to produce a proof is 70 seconds, not 10.
>
> This matters because witness generation and proving have different scaling properties. Proving can be parallelized across GPUs; witness generation is often sequential and memory-bound. Optimizing the cryptographic prover by 10× helps less than you'd expect if witness generation dominates.

This hidden cost explains why benchmarks sometimes mislead. A proof system might advertise "10 million constraints per second," but if witness generation runs at 1 million constraints per second, the advertised speed is unreachable.

### Current Approaches

Several techniques help. Parallel witness generation computes independent portions simultaneously. Witness streaming generates values on-demand rather than materializing everything upfront, reducing peak memory. Witness compression stores only a subset of values and recomputes others when needed, trading computation for space.

### Open Problems

For zkVMs, witness generation from traces is a key bottleneck. The execution trace (the sequence of states the CPU passed through) already exists. Translating it into the format the prover needs is expensive. This translation often dominates end-to-end proving time.

Incremental witness update matters for interactive applications. When the input changes slightly, can we update the witness without recomputing entirely? For applications where inputs evolve over time (games, simulations, collaborative editing), this could unlock new use cases.

Witness generation is a systems problem: engineering, not cryptography. But it increasingly determines real-world performance. The most elegant protocol means nothing if witness generation is the bottleneck.

All the techniques we've discussed (field choice, post-quantum assumptions, zkVMs, verification, hardware, aggregation, witness generation) serve as building blocks for applications. The most demanding application on the horizon may be machine learning.

## Privacy-Preserving Machine Learning

### The Intersection

Zero-knowledge proofs enable tantalizing possibilities for machine learning: prove that a model was trained correctly on a claimed dataset without revealing the training data; prove that an inference was computed correctly without revealing the model or the input; prove that a model satisfies certain properties (fairness, robustness) without revealing the model itself.

Privacy-preserving ML could transform healthcare (prove diagnosis without revealing patient data), finance (prove creditworthiness without revealing financial history), and countless other domains.

### The Current State

Proof of training remains prohibitively expensive. A GPT-scale model has billions of parameters; training involves trillions of operations. Current SNARKs cannot handle computations of this scale, not remotely close.

Proof of inference is more tractable. Small neural networks (thousands to tens of thousands of parameters) have been proven. But even here, the overhead is substantial: 100× or more compared to native inference.

### Open Problems

Scaling to large models is the central challenge. Can we prove inference for models with millions of parameters? The constraint count is daunting, but perhaps structure (repeated layers, sparse activations) can be exploited.

Non-linearities create a specific bottleneck. ReLU, softmax, and other activation functions are expensive in arithmetic circuits. Approximating them efficiently, or designing "ZK-friendly" architectures that use amenable non-linearities, could unlock significant improvements.

Current approaches often require hand-optimized circuits for specific model architectures. Model-agnostic techniques that work for *any* architecture without manual optimization remain elusive.

ZK is not the only path to privacy-preserving ML. Fully homomorphic encryption (FHE) enables encrypted inference: the model owner computes on encrypted data without seeing the inputs. The trust model differs: FHE hides inputs from the server, while ZK proves correctness to the client. Hybrid approaches combining ZK and FHE are under active research. See Chapter 26 for a broader discussion of how ZK relates to FHE and other programmable cryptography primitives.

Privacy-preserving ML is perhaps the most ambitious application of ZK proofs. Success would require advances across nearly every frontier we've discussed: better proof systems, faster hardware, efficient witness generation, formal verification. It's a stress test for the entire field.

We've surveyed the practical frontiers. But the practical advances rest on theoretical foundations, and those foundations have their own open questions.

## Theoretical Foundations

### Fundamental Questions

Beyond the engineering challenges, deep theoretical questions remain open.

What is the optimal soundness error for a given proof size? We have constructions, but we lack matching lower bounds. Perhaps dramatically better systems are possible; perhaps we're already close to optimal. Tight bounds would tell us whether to keep searching or to focus elsewhere.

Does deep recursion preserve knowledge soundness? Current theory suggests the security reduction degrades with recursion depth. Is this inherent, or an artifact of our proof techniques? The answer matters for the recursive composition that underpins modern zkVMs.

Can we build succinct proofs without *any* computational assumption, purely from interaction and randomness? The theoretical complexity of IP (interactive proofs) suggests limits, but the exact boundaries remain unclear.

What if multiple provers, each with partial information, jointly convince a verifier? Multi-prover SNARKs might enable new efficiency tradeoffs or trust models.

### Connections to Broader Theory

ZK proofs touch fundamental questions in theoretical computer science.

SNARK techniques have implications for complexity theory: questions about circuit lower bounds, algebraic computation, and the structure of NP. Progress on SNARKs sometimes yields progress on these foundational questions, and vice versa.

The assumptions underlying SNARKs (knowledge assumptions, generic group model) are stronger than standard cryptographic assumptions. Are they actually true? Their validity is a matter of ongoing debate.

Information theory asks: what are the fundamental limits of proof compression? How much can you prove with how few bits? These questions connect to the deepest problems in theoretical computer science.

These questions matter beyond intellectual curiosity. Tight lower bounds would tell us whether current systems are close to optimal or whether dramatically better constructions await discovery. The answers will shape the field's long-term trajectory.

## Closing Perspective

The frontiers we've surveyed span a remarkable range: from the algebraic structure of binary fields to the engineering of GPU kernels, from quantum threat models to the economics of decentralized proving markets. What unites them is a common goal: making proofs smaller, faster, and more trustworthy.

The field is young. Systems that seemed optimal five years ago have been superseded. Techniques dismissed as impractical have become standard. The gap between theory and practice has narrowed faster than anyone predicted.

Some patterns emerge from the chaos. Post-quantum concerns are driving a shift toward hash-based systems. zkVMs are becoming the default abstraction for provable computation. Multilinear polynomials are displacing univariate encodings. Hardware acceleration is transitioning from optional to essential. Formal verification is gaining recognition as necessary, not nice-to-have.

But predictions are dangerous in a field moving this fast. The most important development of the next five years may not appear on any current research agenda. It may come from an unexpected connection between existing techniques, or from a problem domain no one is currently targeting.

What we can say with confidence: the fundamental primitives work. Sum-check, polynomial commitments, and recursive composition have proven themselves. The remaining questions are about optimization, about engineering, about scaling to real-world demands. Those are the kinds of questions that, historically, get solved.

But ZK proofs are not the only approach to computing on secrets. They're the first to reach satisfying practicality, but they're part of a larger landscape: fully homomorphic encryption, program obfuscation, and the convergence of techniques from multiple branches of programmable cryptography. The next chapter steps back to see where ZK fits in that broader picture, and where the paths are beginning to merge.




\newpage

# Chapter 26: ZK in the Cryptographic Landscape

In 1943, a resistance fighter in occupied France needs to send a message to London. She writes it in cipher, slips it into a dead letter drop, and waits. A courier retrieves it, carries it across the Channel, and a cryptographer at Bletchley Park decrypts it. The message travels safely because no one who intercepts it can read it.

For the next fifty years, this was cryptography's entire mission: move secrets from A to B without anyone in between learning them. Telegraph, radio, internet. The medium changed; the problem stayed the same. Encrypt, transmit, decrypt. A message sealed or opened, a secret stored or revealed.

Then computers stopped being message carriers and became *thinkers*. The question changed. It was no longer enough to ask "can I send a secret?" Now we needed to ask: "can I *use* a secret without exposing it?"

This is the dream of **programmable cryptography**: not just secure storage and transmission, but secure *computation*. Mathematics that thinks while blindfolded.

The dream took many forms. "Can I prove I know a secret without revealing it?" led to zero-knowledge proofs. "Can we compute together while keeping our inputs private?" led to secure multiparty computation. "Can I encrypt data so someone else can compute on it?" led to fully homomorphic encryption. "Can I publish a program that reveals nothing about how it works?" led to program obfuscation.

These aren't just different techniques; they're different philosophies about who computes, who learns, and what trust means. For decades they developed in parallel, each with its own community, its own breakthroughs, its own brick walls.

This book taught you the path that arrived first: zero-knowledge proofs. Of the four dreams, ZK is the only one that reached satisfying practicality. Understanding *why* ZK succeeded where others struggled illuminates both the landscape and the road ahead.


## Why ZK Arrived First

The most important asymmetry is structural: the prover works in the clear. In ZK, the expensive cryptographic operations happen *after* the computation, not during it. The prover computes at native speed, then invests work in generating a proof. In FHE, every operation pays the cryptographic tax. In program obfuscation, the program itself becomes the cryptographic object. This difference compounds across millions of operations.

ZK also benefited from mathematical serendipity. SNARKs exploit polynomial arithmetic over finite fields, exactly what elliptic curves, pairings, and FFTs handle efficiently. The tools developed for other purposes (error-correcting codes, number theory, algebraic geometry) turned out to fit the ZK problem beautifully. FHE and obfuscation involve noise management and lattice arithmetic that fight against efficient computation rather than harmonizing with it.

The theory developed steadily over thirty years. The path from GMR (1985) to PCPs (1992) to IOPs (2016) to practical SNARKs (2016-2020) was long but each step built on the previous. The sum-check protocol from 1991 became the heart of modern systems. Polynomial commitments from 2010 enabled succinctness. The pieces accumulated until they clicked together.

Finally, blockchain created urgent demand. Scalability, privacy, trustless verification: billions of dollars flowed into ZK research. The ecosystem grew with companies, open-source libraries, educational materials, and developer tools. FHE has applications but no comparable catalyst. Program obfuscation has no applications that couldn't wait until it works, a chicken-and-egg problem that starves it of engineering investment.

Secure multiparty computation (MPC) also reached practicality, though with different trade-offs. Chapter 24 covers MPC in depth: secret sharing, garbled circuits, oblivious transfer, and how MPC techniques yield ZK proofs through the "MPC-in-the-head" paradigm. This chapter focuses on the two dreams that remain partially unfulfilled: computing on encrypted data, and making programs incomprehensible.



## Gentry's Miracle: Computing on Ciphertexts

For thirty years, cryptographers wondered: is fully homomorphic encryption even possible?

The question wasn't idle. A homomorphic encryption scheme lets you compute on ciphertexts, encrypting $x$ and $y$ to produce a ciphertext of $x + y$ without knowing $x$ or $y$. Many schemes could do *some* operations. RSA is multiplicatively homomorphic: $E(m_1) \cdot E(m_2) = E(m_1 \cdot m_2)$. Paillier is additively homomorphic: encryption has the form $E(m) = g^m \cdot r^n \mod n^2$ for random $r$, so multiplying ciphertexts yields $E(m_1) \cdot E(m_2) = g^{m_1 + m_2} \cdot (r_1 r_2)^n = E(m_1 + m_2)$. But a scheme that handles *both* addition and multiplication (and therefore any computation) required something no one knew how to build.

Craig Gentry's 2009 thesis changed everything.

### The Core Idea: Learning With Errors

Modern FHE rests on a problem called **Learning With Errors (LWE)**. The intuition is simple: linear equations are easy to solve, but linear equations with noise are hard.

> **The Radio Noise Analogy**
>
> Imagine you're trying to tune into a radio station. If the signal comes through perfectly clear, you hear every word. But add static, and suddenly comprehension becomes difficult. Add enough static, and the voice becomes indistinguishable from random noise.
>
> LWE works the same way. The "signal" is a linear equation. Without noise, anyone can solve it. But add a small random error to each equation, and the system becomes unsolvable. The legitimate receiver has a "filter" (the secret key) that strips away the static. Everyone else hears only noise.

**The easy problem.** Suppose I give you equations like $3x + 2y = 17$ and $5x + y = 19$. You solve for $x$ and $y$ immediately. This is high school algebra. Even with hundreds of variables, Gaussian elimination solves it in polynomial time.

**The hard problem.** Now suppose each equation has a small random error: $3x + 2y \approx 17$ and $5x + y \approx 19$, where "$\approx$" means "equals, plus or minus a little noise." Suddenly the problem becomes believed to be intractable. The errors compound; you can't tell whether a near-solution is wrong or just obscured by noise. This is LWE: given noisy linear equations, recover the unknowns.

**Why this enables encryption.** The secret key is a vector $\vec{s}$ (the "unknowns" in our linear system). The modulus $q$ is a public parameter. To encrypt a single bit $m \in \{0, 1\}$:

1. Pick a fresh random vector $\vec{a}$ (the "coefficients," different for each encryption)
2. Pick small random noise $e$
3. Compute $b = \langle \vec{a}, \vec{s} \rangle + e + m \cdot \lfloor q/2 \rfloor$
4. The ciphertext is $(\vec{a}, b)$. Both values are public, sent to whoever will compute on them

The message bit $m$ gets encoded as a large shift: if $m = 0$, we add nothing; if $m = 1$, we add $q/2$ (half the modulus). This creates a big gap between encodings of $0$ and $1$. The noise $e$ is tiny by comparison: it obscures the exact value but not which half of the range we're in.

**Decryption.** Someone who knows $\vec{s}$ computes $b - \langle \vec{a}, \vec{s} \rangle = e + m \cdot \lfloor q/2 \rfloor$. The noise $e$ is small (say, less than $q/10$), so rounding to the nearest multiple of $q/2$ recovers $m$ exactly: values near $0$ decrypt to $0$; values near $q/2$ decrypt to $1$.

**Security.** An attacker sees many ciphertexts $(\vec{a}_i, b_i)$ and wants to recover $\vec{s}$. But each $b_i$ is a noisy linear combination of $\vec{s}$. Solving noisy linear equations is the LWE problem, believed hard even for quantum computers. This quantum resistance is why lattice-based cryptography (including FHE) is central to post-quantum cryptographic standards.

### The Noise Problem

The magic (and the curse) lies in how operations affect the error. A concrete example makes this vivid.

**Setup.** Say our modulus is $q = 1000$. We encode bit $0$ as values near $0$, and bit $1$ as values near $500$ (that's $q/2$). Fresh ciphertexts have noise around $\pm 10$. Decryption works by asking: "Is this value closer to $0$ or to $500$?"

**Fresh encryption.** Encrypt two bits, both equal to $1$:

- Ciphertext $c_1$ decrypts to $500 + 7 = 507$ (the $7$ is noise)
- Ciphertext $c_2$ decrypts to $500 - 4 = 496$ (the $-4$ is noise)

Both decrypt correctly: $507$ is closer to $500$ than to $0$, so it's a $1$. Same for $496$.

**Addition.** Add the ciphertexts to compute $1 + 1 = 0$ (in binary, with carry). The noises add:

- Result decrypts to $(507 + 496) \mod 1000 = 1003 \mod 1000 = 3$

Noise is now $7 + (-4) = 3$. Still small. Decryption works: $3$ is close to $0$, giving the correct answer.

**Multiplication.** Here's where trouble starts. Multiplying ciphertexts (through a clever but complex construction) multiplies the noises:

- After one multiplication: noise $\approx 7 \times 4 = 28$
- After two multiplications: noise $\approx 28 \times 10 = 280$
- After three multiplications: noise $\approx 280 \times 10 = 2800$

But our "safety margin" is only $250$ (values must stay closer to their target than to the other option). After just a few multiplications, the noise exceeds the margin. A value that should decrypt to $1$ (near $500$) might land at $500 + 280 = 780$, which is closer to $1000 \equiv 0$ than to $500$. Decryption returns garbage.

This is the **noise budget**: every FHE scheme has a limit on how much computation can be performed before the ciphertext becomes useless. Addition is cheap (noise grows linearly). Multiplication is expensive (noise grows multiplicatively, which becomes exponential in circuit depth).

### Bootstrapping: The Key Insight

Gentry's breakthrough was **bootstrapping**: a way to produce a fresh, low-noise ciphertext from a noisy one, without ever decrypting in the clear.

**The problem.** Continuing our example: you have a ciphertext encoding the bit $1$, but the noise has grown to $280$. The internal value is $500 + 280 = 780$. One more multiplication and you'll cross into garbage territory. You need to somehow reduce the noise from $280$ back down to something small like $10$, while keeping the message ($1$) intact, and without ever exposing the plaintext.

**The key observation.** Decryption *is itself a computation*. It takes a ciphertext and a secret key, does some arithmetic (subtract the mask, then round), and outputs the plaintext bit. If we could run this computation homomorphically, on encrypted inputs, we'd get an encrypted output.

**The clever trick.** Here's the setup:

- You have a noisy ciphertext $c$ (noise $= 280$, encoding bit $1$)
- You also have, as a public parameter, an encryption of the secret key: $\text{Enc}(\vec{s})$

Now do the following:

1. Treat your noisy ciphertext $c$ as public data (it's already encrypted, so this is safe)
2. Run the decryption circuit homomorphically, using $\text{Enc}(\vec{s})$ as the key input
3. The circuit computes: "subtract the mask, round to nearest $0$ or $500$, output the bit"
4. Since the key was encrypted, the output is also encrypted: you get $\text{Enc}(1)$

**What got "reset"?** The output $\text{Enc}(1)$ is a *fresh* ciphertext. Its noise comes only from the bootstrapping computation itself (say, noise $= 50$), not from the $280$ that had accumulated before. The message is the same ($1$), but the noise dropped from $280$ to $50$. You've bought yourself room for more multiplications.

**Why does this work?** The old noise ($280$) was inside ciphertext $c$. When you run decryption homomorphically, that $280$ gets processed by the rounding step, which absorbs it (rounding $780$ to $500$ gives $1$, correctly). The *new* noise ($50$) comes from the homomorphic operations in the bootstrapping circuit, which is much smaller than $280$ because the decryption circuit is shallow.

**The catch.** The decryption circuit must be simple enough that running it homomorphically doesn't itself exhaust the noise budget. If decryption required deep circuits, bootstrapping would add more noise than it removes. Gentry's construction carefully designs decryption to be "bootstrappable," but the cost is significant: early implementations took minutes per bootstrap.

**The payoff.** With bootstrapping, there's no depth limit. Compute until noise gets dangerous, bootstrap to refresh, continue. Any computation becomes possible, one refresh at a time.

### Modern Schemes

The fifteen years since Gentry's thesis have seen real improvements, but FHE remains far from practical for general use.

**TFHE** (Torus FHE) optimizes for Boolean circuits. It achieves "programmable bootstrapping": the bootstrap operation itself can compute a function, giving gate-by-gate evaluation in ~10-50ms per gate on modern hardware. Good for bit-level operations, but 10ms per gate means a circuit with a million gates takes hours.

**BGV/BFV** optimize for integer arithmetic. They exploit "batching": a single ciphertext can encode thousands of values, and operations apply to all simultaneously (SIMD-style parallelism). One multiplication computes thousands of products. This helps for embarrassingly parallel workloads, but many real computations don't parallelize cleanly.

**CKKS** accepts approximate arithmetic. Instead of exact integers, it works with fixed-point real numbers, allowing small errors in exchange for efficiency. This makes it suitable for machine learning inference, where tiny numerical errors don't affect results. But "suitable" is relative: encrypted inference on a small neural network still takes seconds to minutes, versus milliseconds in the clear.

**The honest assessment.** Current overhead sits at roughly $10^3$ to $10^4$ times native computation. Early implementations were a million times slower; today's best are "only" a thousand times slower. This is genuine progress, but a thousand-fold slowdown is still brutal. A computation that takes 1 second in the clear takes 15 minutes encrypted. A 1-minute computation becomes a full day.

For narrow applications (simple queries on encrypted databases, basic encrypted analytics), FHE is starting to see deployment. But for general computation, the overhead remains prohibitive. Nobody is running encrypted video processing or encrypted large-language-model inference.

**Will it ever be practical?** Unknown. The optimists point to the trajectory: million-fold → thousand-fold in 15 years. Another 15 years might bring another few orders of magnitude. Hardware acceleration (custom FPGAs, ASICs) could help. The pessimists note that the overhead may be fundamental: noise management and ciphertext expansion might have irreducible costs. ZK proofs found clever ways around their bottlenecks; FHE might not.

> **Why Hardware Acceleration Matters**
>
> FHE's core operations are polynomial arithmetic and Number Theoretic Transforms (NTTs) over large integers. CPUs execute these operations sequentially, one instruction at a time. But NTTs are massively parallelizable: the same operation applied to thousands of coefficients simultaneously.
>
> Custom hardware (FPGAs, ASICs) can exploit this parallelism directly. Where a CPU computes one multiplication, a dedicated chip computes thousands in the same clock cycle. Companies like Intel, DARPA, and several startups are building FHE accelerators that promise 100-1000× speedups over software implementations.
>
> If these accelerators deliver, FHE's effective overhead drops from 1000× to 1-10×. That's the difference between "research curiosity" and "production deployment."

Libraries like Microsoft SEAL, OpenFHE, and Zama's Concrete have made FHE accessible to researchers and adventurous practitioners. But "accessible" doesn't mean "deployable at scale."



## The Holy Grail That Wasn't

Program obfuscation is the most ambitious dream of all. Not just computing on secrets, but making *programs themselves* into secrets.

### The Dream: Virtual Black-Box Obfuscation

The strongest notion is **virtual black-box (VBB) obfuscation**. The idea: transform a program's source code into a form that still runs correctly, but reveals nothing about *how* it works.

**A concrete example.** Suppose you have a program that checks passwords:

```
def check(password):
    return password == "hunter2"
```

An obfuscator would transform this into something like:

```
def check_obfuscated(password):
    # 10,000 lines of incomprehensible bit manipulation
    # that somehow still returns True iff password == "hunter2"
```

The obfuscated version works identically (returns True for "hunter2", False for everything else), but someone reading the code can't figure out what the secret password is. They can *use* the program, but they can't *understand* it.

**The formal requirement.** An obfuscator $\mathcal{O}$ satisfies VBB if for any program $P$:

1. **Functionality**: $\mathcal{O}(P)(x) = P(x)$ for all inputs $x$
2. **Black-box security**: Anything efficiently computable from $\mathcal{O}(P)$ is also efficiently computable given only oracle access to $P$

In plain terms: having the obfuscated code gives you no advantage over having a locked box that runs the program. You can query the box with inputs and see outputs, but that's it. Any information you could extract from the obfuscated code, you could also get just by running it on test inputs. The code is in front of you, but it's as opaque as a black box.

**Why this would be transformative.** With VBB obfuscation, you could:

- Ship proprietary algorithms to untrusted machines. The code runs locally, but competitors can't reverse-engineer it.
- Distribute a SNARK prover with a witness baked in. Anyone can generate proofs, but no one can extract the witness.
- Build "time-lock" encryption: a program that decrypts a message only after a certain date, with no way to extract the key early.
- Create software licenses that are actually enforceable: the program checks the license, and there's no way to patch out the check.

### The Impossibility

In 2001, Barak, Goldreich, Impagliazzo, Rudich, Sahai, Vadhan, and Yang proved that **VBB obfuscation is impossible** in general.

The key insight: some programs are inherently "unobfuscatable." The proof constructs a pair of programs $P_0$ and $P_1$ that:

- Have identical input-output behavior on almost all inputs
- Can be distinguished by examining their *code*

No obfuscator can hide which program was obfuscated. The distinguishing property survives any transformation that preserves functionality.

The construction is diabolically clever. Program $P_b$ behaves normally on most inputs, but if given *its own code* as input, it outputs $b$. This self-reference traps any obfuscator:

$$P_b(\mathcal{O}(P_b)) = b$$

Any obfuscation of $P_b$ must output $b$ when fed itself, revealing which program it came from. No amount of code transformation can hide this.

### The Weaker Notion: Indistinguishability Obfuscation

A weaker notion survived. **Indistinguishability obfuscation (iO)** guarantees only:

If programs $P_0$ and $P_1$ compute the *same function* (identical outputs on all inputs), then their obfuscations are computationally indistinguishable:

$$\mathcal{O}(P_0) \approx_c \mathcal{O}(P_1)$$

You cannot tell which equivalent implementation was obfuscated.

This seems weak: you're only hiding the *implementation details*, not the *function*. Given two different implementations of the same algorithm, you can't tell which one was used. So what?

### Why iO Is Powerful

At first, iO sounds useless. "You can't tell which of two equivalent implementations was obfuscated." Who cares? If they compute the same function, why does it matter which one you started with?

**The lightbulb moment.** The power of iO comes from *what you can hide inside equivalent programs*.

Consider two programs that both output "Hello, World!":

```
Program A: print("Hello, World!")

Program B:
    secret_key = 0x7a3f...  # 256-bit key, embedded in the code
    if sha256(input) == target:
        return decrypt(secret_key, ciphertext)
    print("Hello, World!")
```

Program B has a secret key hidden inside it. On every normal input, it behaves identically to Program A (just prints the greeting). But if you find an input whose hash matches `target`, it decrypts and returns a hidden message.

Here's the magic: *these programs compute the same function* (assuming finding the hash preimage is computationally infeasible). No efficient algorithm can find an input that distinguishes them. So by iO, their obfuscations are indistinguishable.

This means you can take Program B, obfuscate it, and publish the result. The secret key is *in the code*, but no one can extract it. The obfuscated program is indistinguishable from an obfuscation of the trivial Program A, which contains no secrets at all. The key is hidden in plain sight.

**The utopia iO promises.** With efficient iO, you could build almost any cryptographic primitive imaginable. The most striking is *witness encryption*: encrypt a message so that only someone who knows a solution to a puzzle can decrypt it. Not a specific person with a specific key, but *anyone* who can solve the puzzle. "This message can be read by whoever proves P ≠ NP." "This inheritance unlocks for whoever finds my will." The decryption key doesn't exist until someone produces the witness.

$$\text{WE.Enc}(\text{statement}, m) \to c \qquad \text{WE.Dec}(c, \text{witness}) \to m$$

> **The Time Capsule Analogy: Witness Encryption vs ZK**
>
> Think of witness encryption as a time capsule with a puzzle lock. You seal a message inside and inscribe a mathematical challenge on the outside. Anyone who solves the puzzle can open the capsule and read the message. You don't need to know *who* will solve it, or *when*. The lock itself enforces the access rule.
>
> Zero-knowledge works in the opposite direction. Instead of "prove you can solve this to read the secret," ZK says "prove you already solved this without showing your solution." WE grants access based on future knowledge. ZK demonstrates existing knowledge.
>
> The duality is precise: both are parameterized by an NP statement. WE encrypts *to* the statement (anyone with a witness can decrypt). ZK proves *about* the statement (I have a witness, but you won't learn it).

Witness encryption reveals a beautiful duality with zero-knowledge. A ZK proof says "I know a witness for statement $x$" without revealing it. Witness encryption says "only someone who knows a witness can read this" without specifying who. One proves knowledge; the other grants access based on knowledge. They're two sides of the same coin, formalized through the same NP relation.

The applications cascade from there. *Functional encryption* lets you give someone a key that computes $f(m)$ from an encryption of $m$, without learning $m$ itself. A hospital holds encrypted patient records; a researcher gets a key that computes "average age of diabetic patients" but reveals nothing else. Not "decrypt or don't," but fine-grained access to computations on secrets. *Deniable encryption* lets you encrypt a message, then later produce fake randomness that makes it look like you encrypted something completely different. Under coercion, you reveal the fake randomness; the adversary decrypts and sees an innocent message. True plausible deniability, mathematically guaranteed. You could even build *self-destructing programs*: code that works for a while, then stops, not because of a flag you can patch out, but because the cryptographic structure makes continued execution impossible after a deadline.

iO is the "master tool" of cryptography. Given iO, you can build almost anything. The constraint isn't imagination; it's efficiency.

### The Construction and Its Costs

In 2021, Jain, Lin, and Sahai finally constructed iO from well-founded assumptions. The theoretical question was settled: iO exists, assuming standard cryptographic hardness (variants of LWE and related problems).

The construction is intricate. It uses **branching programs** as the computational model: a restricted form of computation where the program's state follows a path through a graph based on input bits. The obfuscation encodes these transitions in algebraic noise:

- Matrix encodings hide the transition structure
- Randomized self-reduction prevents reverse-engineering
- Careful algebraic constraints preserve evaluability

The intuition: the program becomes a maze of matrix operations that computes correctly but reveals no structure.

### The Practical Wall

Current constructions are not merely slow; they are *cosmologically* slow.

Obfuscating a circuit of size $n$ requires operations scaling as $2^{O(n)}$. Not polynomial, not quasi-polynomial: exponential. For any program larger than a few hundred gates, the computational cost exceeds what the observable universe could perform.

Unlike FHE, which improved from $10^{12}\times$ overhead to $10^3\times$ in fifteen years, iO has no clear path to practicality. The exponential blowup appears inherent to current techniques.

**The lesson**: Not every theoretically possible primitive becomes practical. Some are waiting for new mathematical insights. Some may never arrive.



## The Convergence

The boundaries between these approaches are dissolving.

The most natural combination is zkFHE. A server computes on encrypted data using FHE, but how does the client know the server computed correctly? The server generates a ZK proof of correct FHE evaluation. The client verifies without decrypting intermediate results, getting both privacy and verifiability in one protocol.

Private machine learning illustrates the complementary strengths. ZK can prove correct inference without revealing model or input (Chapter 25 discusses the challenges). FHE allows the model owner to receive encrypted queries and return encrypted responses, never seeing the actual data. These aren't competing approaches; they're different trust models for different deployments. Similarly, MPC protocols let multiple parties compute together (Chapter 24), and ZK can prove they followed the protocol honestly without revealing individual contributions. Threshold signatures, distributed key management, collaborative computation with verification: the primitives compose.

Even the line between proving and computing is blurring. The folding and accumulation techniques from Chapter 22 let incrementally verifiable computation fold claims together, deferring expensive proof work. Is this ZK, or a new form of verifiable computation? The categories no longer carve nature at its joints.

The dream of programmable cryptography is fragmenting into specialized tools. ZK handles verification without revelation. MPC enables joint computation. FHE supports outsourced computation on secrets. Each occupies a niche; together they cover territory no single approach could reach.

Hardware approaches offer yet another trade-off. Trusted Execution Environments (TEEs) like Intel SGX and ARM TrustZone rely on hardware isolation rather than cryptographic protection: a "secure enclave" that even the operating system cannot inspect. TEEs are fast (near-native speed) but require trusting the hardware manufacturer, and side-channel attacks have repeatedly compromised their guarantees. The cryptographic approaches avoid this trust assumption at the cost of computational overhead.



## Key Takeaways

1. **Programmable cryptography is the broader dream.** ZK proofs answer "can I prove without revealing?" but parallel questions led to MPC (joint computation), FHE (computing on encrypted data), and program obfuscation (hiding implementation). Each represents a different philosophy about who computes, who learns, and what trust means.

2. **ZK succeeded first because of structural advantages.** The prover works in the clear, paying the cryptographic cost only *after* computation. FHE pays the cost on *every operation*. This asymmetry, combined with algebraic serendipity (polynomials fit FFTs, pairings, and elliptic curves) and blockchain funding, explains why ZK reached practicality first.

3. **FHE is real but slow.** Gentry's 2009 breakthrough proved fully homomorphic encryption possible. Bootstrapping refreshes noisy ciphertexts by homomorphically evaluating decryption. Current schemes run ~1000× slower than native computation. Practical for narrow applications; general computation remains out of reach.

4. **Program obfuscation hit a wall.** Virtual black-box obfuscation is impossible in general (Barak et al. 2001). The weaker notion, indistinguishability obfuscation (iO), exists theoretically but requires exponential computation. iO would be cryptography's "master tool," but practicality is not on the horizon.

5. **The primitives are converging.** zkFHE combines encrypted computation with verifiable correctness. MPC and ZK compose for honest-protocol proofs. Folding blurs the line between proving and computing. The boundaries between approaches are dissolving as researchers combine techniques.

6. **Trust models differ.** ZK: prover sees data, verifier learns only validity. MPC: parties jointly compute, no one sees others' inputs. FHE: server computes blindly, client holds decryption key. Choose based on who you trust and what you're hiding from whom.


## Summary: The Landscape at a Glance

| Approach | Who computes? | Who learns result? | Trust assumption | Status |
|----------|---------------|-------------------|------------------|--------|
| ZK | Prover | Verifier | Soundness of proofs | Practical |
| MPC | All parties jointly | All parties | Threshold honesty | Practical |
| FHE | Untrusted server | Client only | Encryption security | Emerging (~1000× overhead) |
| iO | Anyone | Anyone | Obfuscation security | Theoretical only |



## Looking Forward

This book taught you zero-knowledge proofs: the first branch of programmable cryptography to reach satisfying practicality. But ZK is not the whole story. It's the *first* story to reach an ending.

The dream that animated GMR, Gentry, and generations of cryptographers was more ambitious: computation on secrets as natural as computation in the clear. We're not there yet. FHE is still a thousand times too slow for most applications. iO remains a theoretical curiosity. The locked room stays partly locked.

But the trajectory is clear. ZK proofs were impractical in 2010, expensive in 2016, and routine in 2024. FHE follows a similar curve, perhaps a decade behind. The tools are converging; the applications are multiplying.

You've learned the part of the story that's already been written. The rest is still being discovered.



\newpage

\part*{Appendices}

\newpage

# Appendix A: Cryptographic Primitives

This appendix collects cryptographic building blocks used throughout the book but not central to the SNARK narrative. These primitives appear in trusted setups, commitment schemes, and protocol constructions.

We begin with a brief reminder of assumed mathematical background, then cover specific primitives.

## Mathematical Background

This section provides quick reminders of concepts assumed throughout the book. If these are unfamiliar, consult a textbook on abstract algebra or cryptography before proceeding.

### Finite Fields

A **finite field** $\mathbb{F}_p$ (for prime $p$) is the set $\{0, 1, \ldots, p-1\}$ with addition and multiplication modulo $p$. Every nonzero element has a multiplicative inverse.

**Key properties**:

- The multiplicative group $\mathbb{F}_p^\ast$ has order $p - 1$
- **Fermat's Little Theorem**: For $a \neq 0$, $a^{p-1} = 1$. Thus $a^{-1} = a^{p-2}$.
- **Primitive roots**: There exists $g \in \mathbb{F}_p^\ast$ such that $\lbrace g^0, g^1, \ldots, g^{p-2} \rbrace = \mathbb{F}_p^\ast$

**Extension fields** $\mathbb{F}_{p^k}$ arise by adjoining roots of irreducible polynomials. Elements are degree-$(k-1)$ polynomials over $\mathbb{F}_p$, with multiplication modulo the irreducible polynomial. SNARK-friendly fields often have $p \approx 2^{254}$ for 128-bit security.

**Roots of unity**: If $n \mid (p-1)$, there exist $n$-th roots of unity $\omega$ satisfying $\omega^n = 1$. These enable FFT-based polynomial multiplication.

### Elliptic Curves

An **elliptic curve** over $\mathbb{F}_p$ is the set of points $(x, y) \in \mathbb{F}_p^2$ satisfying
$$y^2 = x^3 + ax + b$$
plus a "point at infinity" $\mathcal{O}$ serving as identity.

**Group law**: Points form an abelian group under a geometric addition rule. For distinct points $P = (x_1, y_1)$ and $Q = (x_2, y_2)$:
$$\lambda = \frac{y_2 - y_1}{x_2 - x_1}, \quad x_3 = \lambda^2 - x_1 - x_2, \quad y_3 = \lambda(x_1 - x_3) - y_1$$

The group order $|E(\mathbb{F}_p)|$ is approximately $p$ (Hasse's theorem: $|p + 1 - |E|| \leq 2\sqrt{p}$).

**Discrete log hardness**: Given $P$ and $Q = kP$, finding $k$ is believed hard. This is the security foundation for elliptic curve cryptography.

**Scalar multiplication**: Computing $kP$ for scalar $k$ uses double-and-add, taking $O(\log k)$ group operations.

**Curve forms**: The Weierstrass form $y^2 = x^3 + ax + b$ is standard, but other forms offer advantages. **Montgomery curves** ($By^2 = x^3 + Ax^2 + x$) enable constant-time scalar multiplication via the Montgomery ladder. **Twisted Edwards curves** ($ax^2 + y^2 = 1 + dx^2y^2$) have unified addition formulas (the same formula works for doubling), making them efficient and resistant to side-channel attacks. BabyJubjub and Jubjub are twisted Edwards curves.

### Bilinear Pairings

A **pairing** is a map $e: \mathbb{G}_1 \times \mathbb{G}_2 \to \mathbb{G}_T$ between elliptic curve groups satisfying:

- **Bilinearity**: $e(aP, bQ) = e(P, Q)^{ab}$
- **Non-degeneracy**: If $P$ and $Q$ are generators, $e(P, Q)$ generates $\mathbb{G}_T$
- **Efficiency**: Computable in polynomial time

Pairings enable "multiplication in the exponent": given $g^a$ and $g^b$, you can't compute $g^{ab}$ directly, but $e(g^a, g^b) = e(g,g)^{ab}$ moves the product to a different group.

**Why pairings matter for SNARKs**: KZG commitments use pairings to verify polynomial evaluations. The verifier checks $e([f(s)], [1]) = e([q(s)], [s - z]) \cdot e([f(z)], [1])$ without knowing $s$.

**Pairing-friendly curves**: Not all curves support efficient pairings. BN254 and BLS12-381 are specifically designed for this.

### The Discrete Log Assumption

The security of elliptic curve cryptography rests on:

**Discrete Log Problem (DLP)**: Given $P$ and $Q = kP$, find $k$.

**Computational Diffie-Hellman (CDH)**: Given $P$, $aP$, and $bP$, compute $abP$.

**Decisional Diffie-Hellman (DDH)**: Distinguish $(P, aP, bP, abP)$ from $(P, aP, bP, cP)$ for random $c$.

In pairing groups, DDH is easy (check via pairing), but CDH is still believed hard. This is the **gap Diffie-Hellman** setting that KZG exploits.

## Secure Random Sampling

Many protocols require random field elements. "Random" means sampled uniformly from $\mathbb{F}_p$ or a subgroup, with each element equally likely.

### The Modulo Bias Problem

A common implementation: generate random bytes, interpret as integer, take modulo $p$.

```
x = random_bytes(32)  # 256 bits
r = int(x) mod p
```

This introduces bias. If $2^{256} \mod p \neq 0$, some residues are more likely than others.

**Example**: Sample from $\{0, 1, \ldots, 9\}$ using a random byte (0-255).

- Naive: $r = \text{byte} \mod 10$
- Values 0-5 appear with probability $26/256$ (26 preimages each: 0, 10, 20, ..., 250)
- Values 6-9 appear with probability $25/256$ (25 preimages each)

The bias is small but potentially exploitable over many samples.

### Rejection Sampling

Generate candidates and reject those outside an unbiased range.

```
repeat:
    x = random_bytes(32)
    if x < p * floor(2^256 / p):
        return x mod p
```

This ensures each residue has equal probability. Expected iterations: $< 2$ when $p$ is close to a power of 2.

### Hashing to Field Elements

When deriving field elements from structured data (Fiat-Shamir challenges, randomness beacons):

1. Hash the input: $h = H(\text{data})$
2. Interpret as integer and reduce modulo $p$
3. Or use a domain-specific "hash-to-field" function (RFC 9380)

The hash output should be larger than $p$ (e.g., 512 bits for a 256-bit field) to minimize bias.

## Nothing-Up-My-Sleeve (NUMS) Constructions

Sometimes protocols require public constants that "couldn't have been chosen maliciously."

### The Problem

If a constant $c$ is needed (e.g., a generator, a hash input), how do we convince others it wasn't chosen to create a trapdoor?

### NUMS Technique

Derive the constant from a public, unpredictable source:

- Digits of $\pi$, $e$, or $\sqrt{2}$
- Hashes of fixed strings: $c = H(\text{"nothing up my sleeve"})$
- Sequential integers: "Point number 1", "Point number 2", etc.

**Example**: The secp256k1 curve (used in Bitcoin) derives its parameters from sequential digits. This convinced the community the curve wasn't backdoored.

### Application to Trusted Setup

In a Powers of Tau ceremony, the initial toxic waste $\tau$ should be derived via NUMS:
$$\tau_0 = H(\text{beacon hash} \| \text{round number})$$

Each participant then randomizes: $\tau_i = \tau_{i-1} \cdot r_i$ where $r_i$ is their secret randomness.

## Shamir's Secret Sharing

Distribute a secret $s$ among $n$ parties such that any $t$ can reconstruct but $t-1$ learn nothing.

### Construction

Work over a finite field $\mathbb{F}_p$ with $p > n$.

**Sharing (by dealer)**:

1. Choose random polynomial $P(X) = s + a_1 X + a_2 X^2 + \cdots + a_{t-1} X^{t-1}$
2. The secret is $P(0) = s$
3. Give party $i$ the share $s_i = P(i)$

**Reconstruction (by any $t$ parties)**:

1. Collect $t$ shares: $(i_1, s_{i_1}), \ldots, (i_t, s_{i_t})$
2. Use Lagrange interpolation to find $P(0)$:
   $$s = P(0) = \sum_{j=1}^{t} s_{i_j} \cdot \prod_{k \neq j} \frac{-i_k}{i_j - i_k}$$

### Security

Any $t-1$ shares are consistent with every possible secret. The polynomial through $t-1$ points can have any value at 0. Information-theoretic security: even computationally unbounded adversaries learn nothing.

### The Phase Transition

Shamir's scheme exhibits a striking property borrowed from physics: a **phase transition** at the threshold $t$.

In thermodynamics, phase transitions are sharp boundaries where a system's behavior changes discontinuously. Water at 99°C is liquid; at 101°C it's gas. There's no gradual transition: the properties flip at a critical point.

Shamir's scheme has exactly this character:

- With $t-1$ shares, the adversary knows **nothing** about the secret (every value in $\mathbb{F}_p$ is equally likely)
- With $t$ shares, the adversary knows **everything** (the secret is uniquely determined)

There's no intermediate state. The information doesn't leak gradually as shares accumulate. At $t-1$ shares, the entropy of the secret is $\log_2 p$ bits (maximum uncertainty). At $t$ shares, the entropy drops to zero (complete knowledge). The transition is discontinuous.

This is information-theoretic, not computational. The phase transition persists even against adversaries with unlimited computing power. The mathematics of polynomial interpolation creates a genuine discontinuity in the information landscape.

### Worked Example

Secret $s = 10$, threshold $t = 2$, parties $n = 3$, field $\mathbb{F}_{17}$.

Polynomial: $P(X) = 10 + 5X$ (random coefficient $a_1 = 5$).

Shares:

- Party 1: $P(1) = 15$
- Party 2: $P(2) = 20 \equiv 3 \pmod{17}$
- Party 3: $P(3) = 25 \equiv 8 \pmod{17}$

Reconstruction from parties 1 and 3:
$$s = 15 \cdot \frac{-3}{1 - 3} + 8 \cdot \frac{-1}{3 - 1} = 15 \cdot \frac{-3}{-2} + 8 \cdot \frac{-1}{2}$$

In $\mathbb{F}_{17}$: $(-2)^{-1} = 8$, $2^{-1} = 9$.
$$s = 15 \cdot (-3) \cdot 8 + 8 \cdot (-1) \cdot 9 = 15 \cdot 11 + 8 \cdot 8 = 165 + 64 \equiv 10 \pmod{17}$$

## Feldman's Verifiable Secret Sharing

Standard Shamir assumes an honest dealer. What if the dealer distributes inconsistent shares?

### The Problem

A malicious dealer could give shares that don't reconstruct to any secret, or reconstruct to different secrets for different groups.

### Feldman's Solution

Broadcast commitments to the polynomial coefficients.

**Setup**: Group $\mathbb{G}$ of prime order $q$, generator $g$.

**Sharing**:

1. Dealer chooses $P(X) = s + a_1 X + \cdots + a_{t-1} X^{t-1}$
2. Dealer broadcasts commitments: $C_0 = g^s, C_1 = g^{a_1}, \ldots, C_{t-1} = g^{a_{t-1}}$
3. Dealer sends share $s_i = P(i)$ to party $i$

**Verification**: Party $i$ checks:
$$g^{s_i} = \prod_{j=0}^{t-1} C_j^{i^j}$$

This holds because:
$$\prod_{j=0}^{t-1} C_j^{i^j} = \prod_{j=0}^{t-1} g^{a_j \cdot i^j} = g^{\sum_j a_j i^j} = g^{P(i)} = g^{s_i}$$

If verification fails, party $i$ broadcasts a complaint. Honest parties can detect malicious dealers.

### Limitation

Feldman VSS reveals $g^s$ (the "encrypted" secret). This may leak partial information (e.g., equality with other secrets). Pedersen VSS adds blinding for perfect hiding.

## Hash Functions in Zero-Knowledge

SNARKs use hash functions for:

- Fiat-Shamir challenges
- Merkle tree commitments (FRI, STARKs)
- Random oracle instantiation

### The Circuit Cost Problem

Standard hashes (SHA-256, BLAKE3) are expensive in circuits. SHA-256 uses operations that CPUs handle efficiently (32-bit XOR, bit rotations, boolean operations), but these are catastrophic inside arithmetic circuits over prime fields.

A single XOR in an arithmetic circuit requires: decomposing each input into bits (one constraint per bit to enforce booleanity: $b_i \cdot (1 - b_i) = 0$), then computing the XOR bit-by-bit as $a_i + b_i - 2 \cdot a_i \cdot b_i$. A 256-bit XOR that takes one CPU cycle becomes hundreds of constraints.

**The numbers**: SHA-256 costs roughly 25,000–30,000 constraints per invocation. A depth-20 Merkle tree (about 1 million leaves) requires 20 hashes, totaling 500,000–600,000 constraints just for hashing.

### Algebraic Hashes: The Solution

**Algebraically-friendly hashes** use only native field operations: addition and multiplication. No bit operations at all. This isn't just an optimization; it's a paradigm shift from "implement SHA-256 in a circuit" to "what hash would we design if we were circuit architects from the start?"

**Poseidon** is the dominant choice. It uses a sponge construction with a permutation built from three layers per round:

1. **Add round constants**: Breaks symmetry. Cost: 0 constraints (additions are linear).
2. **S-box**: Apply $x^\alpha$ (typically $x^5$) for nonlinearity. Cost: 2 constraints per S-box.
3. **MDS matrix**: Multiply state by a maximum-distance-separable matrix for diffusion. Cost: 0 constraints (linear operations absorbed into next nonlinear step).

The key optimization is **HADES**: use *full rounds* (S-box on all state elements) at the beginning and end for statistical security, and *partial rounds* (S-box on only one element) in the middle for algebraic security. A typical configuration: 8 full rounds and 56 partial rounds, totaling ~160 constraints per hash.

**Comparison**: For a depth-20 Merkle tree:

| Hash | Constraints/hash | Total |
|------|------------------|-------|
| SHA-256 | ~25,000 | ~500,000 |
| Poseidon | ~160 | ~3,200 |

That's **156× fewer constraints**: the difference between feasible and impractical.

**Other algebraic hashes**:

- **MiMC**: Earlier design (2016), simpler but higher multiplicative depth. Largely superseded.
- **Rescue**: Alternates S-box and inverse S-box. Good for specific systems.
- **Poseidon2** (2023): Same constraints as Poseidon but 3× faster witness generation.

### Security Considerations

Algebraic hashes have less cryptanalytic history than SHA-256. Poseidon has received significant analysis (Grassi et al. 2019, subsequent Gröbner basis attacks), and current parameters include security margins. But conservative applications may:

- Use more rounds than the minimum recommended
- Fall back to SHA-256 for security-critical operations outside circuits
- Accept constraint overhead for robustness

Poseidon is *not* for general-purpose hashing. For files, passwords, or data at rest, use SHA-256 or BLAKE3. Poseidon is a specialized tool for proving hash computations inside ZK circuits.

## Modular Arithmetic Implementation

SNARK provers spend most time in modular arithmetic. Implementation details matter enormously.

### Montgomery Multiplication

Standard modular multiplication: compute $a \cdot b$, then divide by $p$ and take remainder.

**Montgomery representation**: Store $\bar{a} = a \cdot R \mod p$ where $R = 2^k$ for convenient $k$.

Montgomery product: $\bar{c} = \bar{a} \cdot \bar{b} \cdot R^{-1} \mod p$

> **The Shift Analogy**
>
> Think of Montgomery form as shifting the decimal point. We multiply numbers in a "shifted space" where division by $R$ is just "deleting the last $k$ digits" (a bit shift), which is essentially free in hardware. We only shift back at the end.
>
> It's like computing $1.5 \times 2.5$ by working with $15 \times 25 = 375$, then remembering to put two decimal places back: $3.75$. The multiplication happens in the "scaled up" space where the arithmetic is simpler.

Avoids expensive division by using bit shifts and addition. Conversion overhead amortized over many operations.

### SIMD and Parallelism

Modern CPUs have vector instructions (AVX-256, AVX-512). Field arithmetic can be parallelized:

- Four 64-bit multiplications simultaneously
- Eight 32-bit multiplications simultaneously

GPU arithmetic parallelizes across thousands of threads. SNARK provers achieve 10-100× speedup from GPU acceleration.

## Random Beacons

Some applications require public randomness that:

- Cannot be predicted before a deadline
- Cannot be biased by any party
- Is verifiable by all

### Blockchain-Based Beacons

Use the hash of a future block as randomness. The block hash is unpredictable until mined.

**Risk**: Miners can withhold blocks to manipulate the beacon (at cost of block rewards).

### VDF-Based Beacons

A Verifiable Delay Function (VDF) computes $f^T(x)$ where:

- Computing $f^T$ requires time $T$ (sequential)
- Verifying the result is fast

A beacon seeds a VDF. By the time the output is known, manipulation is impossible.

### Multi-Party Beacons

Multiple parties contribute randomness. If any one is honest, the result is unbiased.

**Simple protocol**: Each party commits to a random value, then all reveal. Beacon = hash of all revealed values.

**Risk**: Last revealer sees the beacon before revealing. Commit-then-reveal with timeouts mitigates this.

## Elliptic Curves in Zero-Knowledge

Not all elliptic curves work for SNARKs. Pairing-based systems (Groth16, KZG commitments) require curves with efficiently computable bilinear pairings. The choice of curve determines the scalar field, which in turn determines what field elements your circuit operates over.

### BN254 (alt_bn128)

The workhorse of practical SNARKs. A Barreto-Naehrig curve with embedding degree 12.

- **Scalar field**: $r \approx 2^{254}$ (254 bits)
- **Security**: Originally claimed ~128 bits, now estimated at ~100 bits due to advances in discrete log attacks on extension fields
- **Status**: Still widely used (Ethereum precompiles, most zkEVMs, Groth16 deployments)

BN254's scalar field prime:
$$r = 21888242871839275222246405745257275088548364400416034343698204186575808495617$$

Ethereum has native precompiles for BN254 operations (ecAdd, ecMul, ecPairing), making it the default for on-chain verification.

### BLS12-381

A Barreto-Lynn-Scott curve with embedding degree 12. Designed to provide ~128-bit security even with improved attacks.

- **Scalar field**: $r \approx 2^{255}$ (255 bits)
- **Security**: Solid 128-bit security margin
- **Status**: Used in newer systems (Zcash Sapling, Ethereum 2.0 signatures, PLONK implementations)

BLS12-381 is larger than BN254 (larger field, more expensive operations) but future-proof against known attack improvements.

### Embedded Curves: BabyJubjub and Jubjub

Pairing curves have large coordinates. What if you need to do elliptic curve operations *inside* a circuit, for example, verifying an EdDSA signature within a SNARK?

Computing BN254 point addition inside a BN254 circuit is expensive: the base field is ~254 bits, requiring big-integer arithmetic in constraints. The solution: use a *different* curve whose base field matches the SNARK's scalar field.

**BabyJubjub** is a twisted Edwards curve defined over BN254's scalar field. Points on BabyJubjub have coordinates in $\mathbb{F}_r$ where $r$ is BN254's scalar field order. This means:

- BabyJubjub operations are native arithmetic in BN254 circuits
- Point addition costs ~6 constraints (not thousands)
- EdDSA signature verification becomes practical inside circuits

**Jubjub** plays the same role for BLS12-381: a twisted Edwards curve over BLS12-381's scalar field.

The pattern: an "embedded" or "inner" curve lives over the outer curve's scalar field, enabling efficient in-circuit elliptic curve operations.

### Curve Cycles

For recursive SNARKs, you need to verify a proof *inside* a circuit. If both the proof system and the circuit use the same field, you hit a problem: the verifier does arithmetic in the scalar field, but the proof's group operations are over the base field.

A **curve cycle** pairs two curves where each curve's base field equals the other's scalar field. Pasta curves (Pallas and Vesta) form such a cycle, enabling efficient recursion in systems like Halo 2.

| Curve | Base Field | Scalar Field |
|-------|------------|--------------|
| Pallas | $\mathbb{F}_p$ | $\mathbb{F}_q$ |
| Vesta | $\mathbb{F}_q$ | $\mathbb{F}_p$ |

Prove over Pallas, verify in a Vesta circuit; prove over Vesta, verify in a Pallas circuit. The cycle enables indefinite recursion.

> **The BN254/Grumpkin Cycle**
>
> While Pallas/Vesta is the most famous cycle (used in Halo 2), the BN254/Grumpkin cycle is crucial for Ethereum developers. Since BN254 is precompiled on Ethereum, systems like Aztec use this cycle to verify recursive proofs on-chain cheaply. Grumpkin is a curve whose base field matches BN254's scalar field, enabling the same recursive trick while staying compatible with Ethereum's existing infrastructure.

## Group Operations

Elliptic curve SNARKs rely on fast group operations.

### Point Addition (Affine)

Given points $P = (x_1, y_1)$ and $Q = (x_2, y_2)$ on curve $y^2 = x^3 + ax + b$:

$$\lambda = \frac{y_2 - y_1}{x_2 - x_1}$$
$$x_3 = \lambda^2 - x_1 - x_2$$
$$y_3 = \lambda(x_1 - x_3) - y_1$$

Affine coordinates require field inversion (expensive).

### Projective Coordinates

Represent $(x, y)$ as $(X : Y : Z)$ where $x = X/Z$, $y = Y/Z$.

Point addition and doubling use only multiplication, avoiding inversion until final conversion.

> **The No-Division Rule**
>
> In computer hardware, division is expensive (like doing long division by hand). Multiplication is cheap.
>
> Projective coordinates let us represent points as ratios $(X:Y:Z)$ so we can do all our math using only multiplication. We only perform the expensive division once at the very end to convert back. It's like working with fractions: to compute $\frac{1}{3} + \frac{1}{4}$, you do $\frac{4+3}{12}$ and delay the actual division as long as possible.

**Jacobian coordinates**: $(X : Y : Z)$ with $x = X/Z^2$, $y = Y/Z^3$. Optimized for repeated doubling.

### Multi-Scalar Multiplication (MSM)

Compute $\sum_i s_i \cdot G_i$ for scalars $s_i$ and points $G_i$.

**Pippenger's algorithm**: Group scalars by their bit patterns. Reduces work from $O(n \cdot \log |s|)$ to $O(n / \log n \cdot \log |s|)$.

MSM dominates KZG commitment time. Parallelization and GPU implementation are essential for practical SNARKs.


## Key Takeaways

**Mathematical foundations**:

1. **Finite fields**: $\mathbb{F}_p$ is integers mod prime $p$. Fermat gives inverses: $a^{-1} = a^{p-2}$. Roots of unity enable FFT when $n \mid (p-1)$.

2. **Elliptic curves**: Points on $y^2 = x^3 + ax + b$ form a group. Security rests on discrete log hardness.

3. **Pairings**: Bilinear maps $e(aP, bQ) = e(P,Q)^{ab}$ enable "multiplication in the exponent." This powers KZG verification.

**Cryptographic primitives**:

4. **Modulo bias**: Naive random sampling is biased. Use rejection sampling or hash outputs wider than the field.

5. **NUMS construction**: Derive constants from unpredictable sources (digits of $\pi$, hashes of fixed strings) to prevent trapdoors.

6. **Shamir's secret sharing**: Polynomial interpolation enables $(t, n)$-threshold sharing with information-theoretic security. The threshold is a phase transition: $t-1$ shares reveal nothing, $t$ shares reveal everything.

7. **Feldman VSS**: Broadcast commitments to polynomial coefficients allow parties to verify share consistency without trusting the dealer.

8. **Algebraic hashes**: SHA-256 costs ~25,000 constraints per hash in circuits. Poseidon costs ~160 by using only native field operations. The HADES design mixes full rounds (all S-boxes) with partial rounds (one S-box) for efficiency.

**Curves and implementation**:

9. **Curve selection**: BN254 has Ethereum precompiles but ~100-bit security. BLS12-381 offers full 128-bit security. Choose based on deployment requirements.

10. **Embedded curves**: BabyJubjub (for BN254) and Jubjub (for BLS12-381) enable efficient in-circuit elliptic curve operations by living over the outer curve's scalar field.

11. **Curve cycles**: Pairs like Pallas/Vesta where each curve's base field equals the other's scalar field enable efficient recursive proof composition.

12. **Montgomery multiplication**: Avoids expensive division by working in a modified representation. Standard for high-performance field arithmetic.

13. **Projective coordinates**: Avoid field inversions by representing points as ratios. Essential for efficient elliptic curve operations.

14. **MSM optimization**: Multi-scalar multiplication dominates KZG commitment time. Pippenger's algorithm and GPU parallelization are critical for practical provers.


\newpage

# Appendix B: Historical Timeline

The development of zero-knowledge proofs and succinct arguments spans four decades. This timeline traces the key theoretical breakthroughs and practical systems that shaped the field.



## The Theoretical Foundations (1985-1992)

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



## The ZK Winter (1992-2008)

For sixteen years, zero-knowledge proofs remained a theoretical curiosity. The PCP theorem promised succinct proofs, but the constructions had astronomical overhead ($O(n^{10})$ blowup in early versions). Computers were too slow. The algorithms were too heavy. Cryptographers knew ZK was possible but not practical.

The field didn't stop entirely. Researchers refined PCP constructions, developed new proof composition techniques, and explored connections to coding theory. But there were no implementations, no applications, no urgency.

Two events ended the winter. In 2008, Goldwasser, Kalai, and Rothblum published GKR, showing that sum-check could verify arithmetic circuits with manageable overhead. Then in 2009, Bitcoin launched. Suddenly there was a financial ecosystem that desperately needed what ZK could provide: privacy, scalability, trustless verification. Theoretical possibility met practical demand. The spring began.



## The Path to Practical Systems (2008-2016)

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



## The Scaling Era (2017-2020)

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

### The Phylogenetic Tree

By the end of this era, three distinct "species" of zero-knowledge proofs had evolved from a common ancestor:

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

*The three main species of zero-knowledge proofs, each with distinct cryptographic foundations: pairings, hashes, and sum-check.*



## The Modern Era (2020-Present)

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

### The Convergence

Modern zkVMs are not new inventions. They are the confluence of three decades of distinct research streams:

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



## Visual Timeline

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



## Key Themes

**From Theory to Practice (1985-2016)**: Early work established that zero-knowledge proofs exist for all of NP, but constructions were impractical. The path from GMR to Groth16 took 31 years of incremental improvement.

**The Trusted Setup Debate (2016-2019)**: Groth16's efficiency came with per-circuit trusted setup. PLONK's universal setup and STARKs' transparency offered alternatives. The field fragmented into camps, each valid for different applications.

**The zkVM Vision (2020-Present)**: Rather than hand-crafting circuits for each application, prove correct execution of arbitrary programs. RISC-V and WASM emerge as target ISAs. Developer experience becomes a competitive advantage.

**The Sum-Check Renaissance (2022-Present)**: After years of PCP-inspired constructions, the field rediscovers sum-check's elegance. Linear-time proving, virtual polynomials, and folding schemes push efficiency to theoretical limits.



## Looking Forward

The timeline is far from complete. Active research directions include:

- **Post-quantum SNARKs**: Lattice-based and hash-based constructions that survive quantum computers
- **Formal verification**: Machine-checked proofs of protocol security
- **Hardware acceleration**: GPUs, FPGAs, and ASICs specialized for proving
- **zkML**: Zero-knowledge proofs for machine learning inference
- **Decentralized proving**: Distributed prover networks for large computations

Each breakthrough opens new questions. The field accelerates.


\newpage

# Appendix C: Field Equations Cheat Sheet

A quick reference for the core equations that power zero-knowledge proof systems.



## Schwartz-Zippel Lemma

**The most important bound in the book.**

For a non-zero polynomial $p(X_1, \ldots, X_n)$ of total degree $d$ over a field $\mathbb{F}$:

$$\Pr_{r \leftarrow \mathbb{F}^n}[p(r) = 0] \leq \frac{d}{|\mathbb{F}|}$$

**Consequence**: Random evaluation catches cheating with probability $\geq 1 - d/|\mathbb{F}|$.



## Multilinear Extensions

### Lagrange Basis Polynomial

For $w \in \{0,1\}^n$:

$$L_w(X) = \prod_{i=1}^{n} \left( w_i \cdot X_i + (1 - w_i)(1 - X_i) \right)$$

**Property**: $L_w(w) = 1$ and $L_w(b) = 0$ for $b \neq w$.

### Multilinear Extension Formula

For $f: \{0,1\}^n \to \mathbb{F}$:

$$\tilde{f}(X) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(X)$$

### Equality Polynomial

$$\widetilde{\text{eq}}(X, Y) = \prod_{i=1}^{n} \left( X_i Y_i + (1 - X_i)(1 - Y_i) \right)$$

**Property**: $\widetilde{\text{eq}}(a, b) = 1$ if $a = b$, else $0$ (on hypercube).



## Sum-Check Protocol

*Dimensions: Vector size $N = 2^n$; protocol runs $n$ rounds.*

### The Claim

Prove:
$$H = \sum_{b \in \{0,1\}^n} g(b_1, \ldots, b_n)$$

### Round $i$ Polynomial

Prover sends:
$$s_i(X_i) = \sum_{b_{i+1}, \ldots, b_n \in \{0,1\}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

### Verifier Checks

- Round 1: $s_1(0) + s_1(1) = H$
- Round $i > 1$: $s_i(0) + s_i(1) = s_{i-1}(r_{i-1})$
- Final: query oracle at $(r_1, \ldots, r_n)$ to check $s_n(r_n) = g(r_1, \ldots, r_n)$

### Soundness

$$\epsilon \leq \frac{n \cdot d}{|\mathbb{F}|}$$

where $n$ is the number of variables and $d$ is the maximum individual degree. (More precisely: $\sum_i d_i / |\mathbb{F}|$ where $d_i$ is the degree in variable $i$.)



## Vanishing Polynomials

### Over Roots of Unity

For domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$ where $\omega^n = 1$:

$$Z_H(X) = X^n - 1$$

**Property**: $Z_H(\omega^i) = 0$ for all $i$, and $Z_H(r) \neq 0$ for $r \notin H$.

### Over Boolean Hypercube

For proving a polynomial vanishes on $\{0,1\}^n$, use the univariate identity:

$$Z_{\{0,1\}}(X) = X(X-1)$$

applied variable by variable in multilinear settings.



## R1CS and QAP

### R1CS Constraint

*Dimensions: Matrices $A, B, C$ are $m \times n$; witness $z$ is $n \times 1$; result is $m \times 1$.*

For witness vector $z = (1, x, w)$:

$$(A \cdot z) \circ (B \cdot z) = C \cdot z$$

where $\circ$ is entry-wise multiplication.

### QAP Polynomial Identity

Define polynomials $A(X), B(X), C(X)$ by interpolating constraint matrices.

The constraint system is satisfied iff:

$$A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$$

where $Z_H(X) = \prod_{\alpha \in H}(X - \alpha)$ is the vanishing polynomial.



## KZG Polynomial Commitments

*Dimensions: Polynomial degree $< D$; SRS size $D+1$ elements.*

### Structured Reference String (SRS)

Secret $\tau$; public: $(g, g^\tau, g^{\tau^2}, \ldots, g^{\tau^D})$

### Commitment

For $f(X) = \sum_i c_i X^i$:

$$C = g^{f(\tau)} = \prod_i (g^{\tau^i})^{c_i}$$

### Evaluation Proof

To prove $f(z) = v$: *(Prover knows $f(X)$; Verifier knows $C$, $z$, $v$)*

1. Compute quotient: $w(X) = \frac{f(X) - v}{X - z}$
2. Proof: $\pi = g^{w(\tau)}$

### Verification (Pairing Check)

$$e(\pi, g^\tau \cdot g^{-z}) = e(C \cdot g^{-v}, g)$$

Equivalently:

$$e(g^{w(\tau)}, g^{\tau - z}) = e(g^{f(\tau) - v}, g)$$



## FRI Folding

### Split Polynomial

For $f(X) = f_E(X^2) + X \cdot f_O(X^2)$:

- $f_E(Y)$: even coefficients
- $f_O(Y)$: odd coefficients

### Folding with Challenge $\alpha$

$$f_1(Y) = f_E(Y) + \alpha \cdot f_O(Y)$$

**Property**: $\deg(f_1) < \deg(f)/2$

### Consistency Check

At query point $x$ (where $-x$ is its conjugate on the same coset), verify:

$$f_1(x^2) = \frac{f(x) + f(-x)}{2} + \alpha \cdot \frac{f(x) - f(-x)}{2x}$$

This uses: $f_E(x^2) = \frac{f(x) + f(-x)}{2}$ and $f_O(x^2) = \frac{f(x) - f(-x)}{2x}$.



## AIR (Algebraic Intermediate Representation)

### Trace Polynomials

For a trace matrix with $w$ registers and $T$ timesteps, interpolate each column over domain $H = \{1, \omega, \ldots, \omega^{T-1}\}$:

$$P_j(\omega^i) = \text{trace}[i][j]$$

### Transition Constraints

For a constraint "register 0 at next step equals $f$ of current registers":

$$P_0(\omega X) = f(P_0(X), P_1(X), \ldots)$$

The shift $\omega X$ accesses "next row" values. Define constraint polynomial:

$$C(X) = P_0(\omega X) - f(P_0(X), P_1(X), \ldots)$$

### Quotient Check

Valid trace iff $C(X)$ vanishes on transition domain $H' = \{1, \omega, \ldots, \omega^{T-2}\}$:

$$Q(X) = \frac{C(X)}{Z_{H'}(X)}$$

is a polynomial (not rational function).

### Boundary Constraints

Pin inputs/outputs. For $P_j(\omega^k) = v$:

$$\frac{P_j(X) - v}{X - \omega^k}$$

must be a polynomial.



## PLONK

### Gate Equation

$$Q_L(X) \cdot a(X) + Q_R(X) \cdot b(X) + Q_O(X) \cdot c(X) + Q_M(X) \cdot a(X) \cdot b(X) + Q_C(X) = 0$$

on domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$.

### Permutation Grand Product

Accumulator $Z(X)$ satisfies:

$$Z(1) = 1$$

$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{(a_i + \beta \omega^i + \gamma)(b_i + \beta k_1\omega^i + \gamma)(c_i + \beta k_2\omega^i + \gamma)}{(a_i + \beta \sigma_a(\omega^i) + \gamma)(b_i + \beta \sigma_b(\omega^i) + \gamma)(c_i + \beta \sigma_c(\omega^i) + \gamma)}$$

**Property**: The product telescopes, so $Z(\omega^n) = Z(1) = 1$ iff all copy constraints hold.

### Quotient Check

All constraints satisfied iff there exists $t(X)$ with:

$$\text{(gate)} + \alpha \cdot \text{(permutation)} = t(X) \cdot Z_H(X)$$



## Groth16

### Public Input Combination

Given public inputs $(z_0, z_1, \ldots, z_\ell)$ where $z_0 = 1$:

$$\text{vk}_x = \sum_{j=0}^{\ell} z_j \cdot (\text{vk}_{IC})_j$$

where $(\text{vk}_{IC})_j = g_1^{\frac{\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)}{\gamma}}$ are verification key elements.

### Verification Equation

Given proof $(\pi_A, \pi_B, \pi_C) \in \mathbb{G}_1 \times \mathbb{G}_2 \times \mathbb{G}_1$:

$$e(\pi_A, \pi_B) \stackrel{?}{=} e(g_1^{\alpha}, g_2^{\beta}) \cdot e(\text{vk}_x, g_2^{\gamma}) \cdot e(\pi_C, g_2^{\delta})$$

**Verification cost**: One MSM (size $\ell$) + 3-4 pairings, independent of circuit size.

### Proof Size

3 group elements: 128 bytes over BN254 (32 + 64 + 32 for $\mathbb{G}_1$, $\mathbb{G}_2$, $\mathbb{G}_1$).



## Lookup Arguments

### Plookup Identity

For lookups $f = \{f_1, \ldots, f_n\}$ and table $t = \{t_1, \ldots, t_d\}$, let $s = \text{sort}(f \cup t)$.

$$\prod_i (\gamma + f_i) \cdot \prod_i (\gamma(1+\beta) + t_i + \beta t_{i+1}) \cdot (1+\beta)^n$$

$$= \prod_i (\gamma(1+\beta) + s_i + \beta s_{i+1})$$

**Property**: Equality holds iff $f \subseteq t$.

### LogUp Identity

For lookups $f = \{f_1, \ldots, f_n\}$ into table $t = \{t_1, \ldots, t_d\}$ with multiplicities $m_j$:

$$\sum_{i=1}^{n} \frac{1}{\gamma + f_i} = \sum_{j=1}^{d} \frac{m_j}{\gamma + t_j}$$

**Property**: Equality holds iff each $f_i \in t$ and $m_j$ counts occurrences correctly.

**Soundness**: By Schwartz-Zippel, equality holds with probability $\geq 1 - (n+d)/|\mathbb{F}|$ over random $\gamma$.

**Advantage**: No sorting required; additive structure enables multi-table batching.



## GKR Protocol

*Dimensions: Layer $i$ has $S_i$ gates; layer $i+1$ (inputs) has $S_{i+1}$ gates; $k = \log_2 S_i$.*

### Layer Reduction

For layered circuit with values $V^{(i)}$ at layer $i$:

$$\tilde{V}^{(i)}(r) = \sum_{p,q \in \{0,1\}^k} \widetilde{\text{add}}^{(i)}(r, p, q) \cdot (\tilde{V}^{(i+1)}(p) + \tilde{V}^{(i+1)}(q))$$
$$+ \widetilde{\text{mult}}^{(i)}(r, p, q) \cdot \tilde{V}^{(i+1)}(p) \cdot \tilde{V}^{(i+1)}(q)$$

### Sum-Check Reduction

A claim about $\tilde{V}^{(i)}(r)$ reduces via sum-check to claims about $\tilde{V}^{(i+1)}(p^*)$ and $\tilde{V}^{(i+1)}(q^*)$ for random $p^*, q^*$.

**Soundness**: Compound over $d$ layers, each with $O(\log n)$ sum-check rounds.



## Inner Product Argument (IPA)

### The Claim

Prove $\langle \vec{a}, \vec{b} \rangle = c$ for committed $\vec{a}$.

### Folding Step

Given challenge $\alpha$:

$$\vec{a}' = \alpha \cdot \vec{a}_L + \alpha^{-1} \cdot \vec{a}_R$$
$$\vec{b}' = \alpha^{-1} \cdot \vec{b}_L + \alpha \cdot \vec{b}_R$$

**Property**: $\langle \vec{a}', \vec{b}' \rangle = \langle \vec{a}, \vec{b} \rangle + \alpha^2 L + \alpha^{-2} R$

where $L = \langle \vec{a}_L, \vec{b}_R \rangle$ and $R = \langle \vec{a}_R, \vec{b}_L \rangle$.

### Proof Size

$O(\log n)$ group elements after $\log n$ rounds.



## Nova Folding

### Relaxed R1CS

Standard R1CS: $(A \cdot z) \circ (B \cdot z) = C \cdot z$

Relaxed R1CS with scalar $u$ and error $E$:

$$(A \cdot z) \circ (B \cdot z) = u \cdot (C \cdot z) + E$$

A satisfying instance has $u = 1$ and $E = 0$.

### Folding Two Instances

Given instances $(u_1, E_1, z_1)$ and $(u_2, E_2, z_2)$, with challenge $r$:

$$u = u_1 + r \cdot u_2$$
$$E = E_1 + r \cdot T + r^2 \cdot E_2$$
$$z = z_1 + r \cdot z_2$$

where $T$ is the "cross-term" computed by the prover.

**Property**: If both inputs satisfy relaxed R1CS, so does the folded instance.



## Fiat-Shamir Transform

### Challenge Derivation

$$r_i = H(\text{transcript prefix including all previous messages})$$

### Security Requirement

The hash must include:

- The public statement $x$
- All previous commitments $C_1, \ldots, C_{i-1}$
- All previous challenges $r_1, \ldots, r_{i-1}$



## Complexity Summary

| System | Proof Size | Verification | Prover | Setup |
|--------|------------|--------------|--------|-------|
| Groth16 | $O(1)$ | $O(1)$ | $O(n \log n)$ | Per-circuit |
| PLONK+KZG | $O(1)$ | $O(1)$ | $O(n \log n)$ | Universal |
| STARK/FRI | $O(\log^2 n)$ | $O(\log^2 n)$ | $O(n \log n)$ | Transparent |
| Bulletproofs | $O(\log n)$ | $O(n)$ | $O(n \log n)$ | Transparent |
| Sum-check IP | $O(\log n)$ | $O(\log n)$ | $O(n)$ | None |



## Field Sizes (Common Choices)

| Field | Size | Security | Use Case |
|-------|------|----------|----------|
| BN254 scalar | $\approx 2^{254}$ | ~100 bits | Ethereum, Groth16, PLONK |
| BLS12-381 scalar | $\approx 2^{255}$ | ~128 bits | Zcash, many SNARKs |
| Goldilocks | $2^{64} - 2^{32} + 1$ | ~100 bits* | Plonky2, fast arithmetic |
| Baby Bear | $2^{31} - 2^{27} + 1$ | ~100 bits* | RISC Zero |
| Mersenne-31 | $2^{31} - 1$ | ~100 bits* | Circle STARKs |

*Small fields require extension fields for cryptographic security; base field security refers to the overall system design.



## Quick Reference: What to Use When

**Proving a sum over hypercube**: Sum-check protocol

**Encoding data as polynomial**: Multilinear extension (hypercube) or Lagrange interpolation (roots of unity)

**Binding prover to polynomial**: KZG (trusted setup, constant size), FRI (transparent, log² size), IPA (no pairings, log size)

**Checking polynomial identity on a domain**: Quotient by $Z_H(X) = X^n - 1$ for roots of unity

**Checking table membership**: Lookup argument (Plookup with sorting, LogUp without)

**Verifying circuit layer-by-layer**: GKR protocol with sum-check at each layer

**Incremental computation**: Nova folding (amortize SNARK cost across steps)

**Eliminating interaction**: Fiat-Shamir with complete transcript hashing


<!-- End matter -->
\newpage
\thispagestyle{empty}
\mbox{}

<!-- Back cover -->
\newpage
\thispagestyle{empty}
\AddToShipoutPictureBG*{\includegraphics[width=\paperwidth,height=\paperheight]{../images/cover/zkBookBack.png}}
\null

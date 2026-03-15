# Chapter 17: The Zero-Knowledge Property

In 1982, Shafi Goldwasser and Silvio Micali submitted a paper to STOC proposing that a proof could convince a verifier of a statement's truth while revealing nothing beyond that single bit: true or false. The program committee rejected it. The concept seemed contradictory. A proof, by its nature, is a demonstration: it convinces by showing. How could showing suffice for conviction while simultaneously revealing nothing?

They persisted. The paper, expanded with Charles Rackoff, was published in 1985 as "The Knowledge Complexity of Interactive Proof Systems." It won the Gödel Prize in 1993. Goldwasser and Micali received the Turing Award in 2012. The reviewers' skepticism was not foolish; it reflected a genuine conceptual difficulty that the paper resolved.

Their resolution was a definition so clean it still underlies every modern proof system. A proof reveals nothing if everything the verifier sees could have been produced by a *simulator* who knows nothing about the secret. If real and simulated transcripts are indistinguishable, the real one carries no information about the witness. This immediately raises the question the rest of the chapter answers: if a fake transcript looks identical to a real one, what did the prover actually contribute?

The definition is deceptively simple. The consequences are not. Simulation is not a property that protocols possess by default. The sum-check protocol, central to this book, leaks witness data through its round polynomials: no simulator can fake them without the witness, because the protocol was never designed to allow it. Understanding when simulation is possible, what makes it possible, and what flavors of indistinguishability suffice is the work of this chapter.

## The Simulation Argument

We have already seen a simulator in action. Chapter 16 constructed one for the Schnorr protocol: to produce a valid transcript $(a, e, z)$ without knowing the witness $w$, pick $e$ and $z$ first (both uniformly random), then compute $a = g^z h^{-e}$. The transcript satisfies the verification equation by construction, and its distribution matches a real transcript exactly.

What does this buy us? Recall that the *witness* $w$ is the prover's secret (a private key, a satisfying assignment, the preimage of a hash), and the *transcript* is the full sequence of messages exchanged during the protocol. If someone who never touched $w$ can produce transcripts identical to a real prover's, then the transcript itself cannot encode anything about $w$, even though the real prover used $w$ to compute it. The computation depends on the witness; the distribution does not. The verifier, holding only the transcript, learns nothing. This reasoning generalizes beyond Schnorr. A proof system is zero-knowledge if a simulator (an efficient algorithm with no access to the witness) can produce transcripts indistinguishable from real protocol executions. This is the **simulation paradigm**. In short: a simulator is a machine that takes only the public statement (everything except the witness), generates challenges on behalf of the verifier, fabricates prover responses, and outputs a complete transcript whose distribution is indistinguishable from a real execution.

To make the argument precise: suppose the verifier could extract some information $I$ about the witness from a real transcript. The simulator doesn't know the witness, so its transcript cannot possibly encode $I$. But the two transcripts are indistinguishable, so any extraction procedure that works on real transcripts must also work on simulated ones, yet simulated ones contain no witness information to extract. The assumption that $I$ is extractable leads to a contradiction. Real transcripts don't leak $I$. The proof is convincing precisely because it could have been fabricated, and this indistinguishability is not a flaw to be patched; it is the definition of success.


## The Graph Non-Isomorphism Protocol

We claimed the simulation paradigm is general. To build conviction, let's see it work in a protocol with entirely different structure: no group elements, no algebraic equations, just graphs and permutations. The Graph Non-Isomorphism protocol from Chapter 1 makes the mechanics of simulation visible without any algebraic machinery to hide behind.

Both parties see two graphs $G_0$ and $G_1$ (the public statement). The prover claims they are non-isomorphic: no permutation $\pi$ of the vertex set satisfies $G_0 = \pi(G_1)$. Graph Isomorphism is in NP (the permutation itself is the witness), but Graph Non-Isomorphism is not known to be in NP. There is no obvious short certificate for the *absence* of an isomorphism, and the verifier cannot efficiently check the claim on her own. This is precisely what makes GNI a natural candidate for interactive proofs.

The protocol works as follows. The verifier picks a secret bit $b \in \{0, 1\}$, applies a random permutation $\pi$ to $G_b$, and sends $H = \pi(G_b)$ to the prover. The prover must identify which graph $H$ came from. If the graphs are truly non-isomorphic, they have different structural fingerprints (spectrum, degree sequence, triangle counts), so an unbounded prover can determine $b$ with certainty and sends back $b' = b$. The key observation: if the graphs *were* isomorphic, $\pi(G_0)$ and $\pi(G_1)$ would be identically distributed, and no prover could do better than guessing $b$ correctly with probability $1/2$. Repeating $k$ times drives the soundness error to $2^{-k}$. Success at this task therefore proves non-isomorphism.

Now consider what the verifier actually sees after a successful execution:

- The challenge $H$ that she generated herself
- The bit $b'$ that matches her secret $b$

But $b$ was her own random choice. $H$ was her own computation. The prover's response $b' = b$ just echoes her own randomness back. The transcript $(H, b')$ contains nothing the verifier didn't already know.

A simulator can exploit this. Given only the graphs $G_0, G_1$ (not the prover's ability to distinguish them), it plays both sides of the conversation:

1. Pick $b \leftarrow \{0, 1\}$ uniformly at random (playing the verifier)
2. Pick $\pi$ uniformly from permutations of the vertex set (playing the verifier)
3. Compute $H = \pi(G_b)$ (playing the verifier)
4. Output the transcript $(H, b)$ (playing the prover, using the $b$ it already chose)

The simulator does not need to distinguish the graphs. It knows $b$ because it generated $b$ itself. A real cheating prover, facing a live verifier, would have to guess $b$ from $H$ alone (and could do no better than $1/2$). The simulator sidesteps this entirely by controlling both sides. The resulting distribution over $(H, b)$ is identical to what an honest verifier would see in a real execution. The simulated and real distributions are not merely close; they are identical. This is **perfect zero-knowledge**: the statistical distance between real and simulated transcripts is exactly zero.

### Simulation and Polynomial Commitments

The algebraic protocols that dominate the rest of this book share a structure that GNI lacks: a commit → challenge → respond sequence. A real prover commits to a polynomial $p(X)$, receives a verifier-chosen evaluation point $z$, and responds with $v = p(z)$. The simulator, just as in Schnorr, reverses this: it picks $z$ and $v$ first, then constructs a commitment consistent with these choices. The commitment "could have been" to any polynomial that passes through $(z, v)$, because a single evaluation does not determine a polynomial. One $(e, z)$ pair in Schnorr is consistent with infinitely many secrets $w$; one evaluation $(z, v)$ is consistent with infinitely many polynomials. The simulator exploits this ambiguity. The real prover is bound by her earlier commitment; the simulator is free to work backward from the challenge.

This is why KZG requires the verifier to choose $z$ *after* the commitment, why FRI queries come after the oracle is fixed, and why Fiat-Shamir hashes the commitment before deriving challenges. The temporal ordering (commit → challenge → respond) is what makes the live proof convincing. The simulator's freedom from that ordering is what makes the transcript uninformative.

## Formal Definition

Let $(\mathcal{P}, \mathcal{V})$ be an interactive proof system for a language $\mathcal{L}$ (recall from Chapter 1: a set of yes-instances for some decision problem). On input $x \in \mathcal{L}$, the prover $\mathcal{P}$ holds a witness $w$; the verifier $\mathcal{V}$ sees only $x$.

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

where the **statistical distance** (or total variation distance) between distributions $P$ and $Q$ is defined as:
$$\Delta(P, Q) = \frac{1}{2} \sum_{x} |P(x) - Q(x)| = \max_{S} |P(S) - Q(S)|$$

This is the maximum advantage any distinguisher (even computationally unbounded) can achieve. An unbounded adversary might distinguish the distributions, but only with probability $2^{-\Omega(\lambda)}$ (effectively never).

SZK allows for protocols where perfect simulation is impossible but the gap is cryptographically small. To see how this arises in practice, return to Schnorr. The simulator picks $z$ uniformly from $\mathbb{Z}_q$ and achieves a perfect match. But suppose the implementation samples $z$ uniformly from $\{0, \ldots, 2^{256} - 1\}$ instead of $\{0, \ldots, q-1\}$ (a common shortcut when $q \approx 2^{256}$). The real transcript samples $r$ from $\mathbb{Z}_q$, so $z = r + we$ is uniform over $\mathbb{Z}_q$; the simulated transcript has $z$ uniform over a slightly larger range. The statistical distance is on the order of $(2^{256} - q)/2^{256}$, which is negligible when $q$ is close to $2^{256}$. No unbounded adversary can distinguish with non-negligible advantage, but the distributions are no longer identical. This is SZK, not PZK.

**Computational zero-knowledge (CZK).** No efficient algorithm can distinguish the distributions:
$$\text{View}_{\mathcal{V}} \stackrel{c}{\approx} \mathcal{S}(x)$$

The distributions might be statistically far apart, but every polynomial-time distinguisher's advantage is negligible. Security relies on computational hardness; an unbounded adversary could distinguish.

CZK is the weakest but most practical notion. Modern SNARKs typically achieve CZK. The simulator might use pseudorandom values where the real protocol uses true randomness; distinguishing requires breaking the underlying assumption.


## Honest Verifiers and Malicious Verifiers

The definition above assumes the verifier follows the protocol honestly. What if she doesn't?

**Honest-verifier zero-knowledge (HVZK).** Zero-knowledge is guaranteed only when the verifier follows the protocol as specified, hence "honest." The simulator can hardcode this known strategy into its construction. For Schnorr, the honest verifier samples $e$ uniformly and independently of $a$, and the simulator exploits exactly this: it picks $(e, z)$ first, then derives $a = g^z h^{-e}$. The independence of $e$ from $a$ is what makes the reversal work. If the verifier instead chose $e = f(a)$ for some function $f$, the simulator would need to find $a$ such that $f(a)$ equals the $e$ it already committed to, which it generally cannot do.

**Malicious-verifier zero-knowledge.** The simulator must produce indistinguishable output against *any* efficient verifier strategy $\mathcal{V}^*$, including:

- Adversarial challenge selection
- Auxiliary information from other sources
- Arbitrary protocol deviations

To see what malicious verification looks like concretely, consider the Graph Non-Isomorphism protocol again. An honest verifier sends $H = \pi(G_b)$ for her secret $b$. But a malicious verifier could send some other graph $H'$ (perhaps one she suspects is isomorphic to $G_0$ but isn't sure). The all-powerful prover will correctly identify whether $H'$ matches $G_0$, $G_1$, or neither. The verifier learns something she couldn't efficiently compute herself!

The protocol is HVZK but not malicious-verifier ZK. The prover, dutifully answering whatever question is posed, inadvertently becomes an oracle for graph isomorphism.

Closing this gap requires additional machinery:

- *Coin-flipping protocols* force the verifier to commit to her randomness before seeing the prover's messages. The verifier's challenges become unpredictable even to her.
- *Trapdoor commitments* let the simulator "equivocate": commit to one value, then open to another after seeing the verifier's behavior.
- *The Fiat-Shamir transform* eliminates interaction entirely. With no verifier messages, there's no room for malicious behavior. The simulator controls the random oracle and programs it as needed.

Non-interactive proofs (after Fiat-Shamir) largely dissolve the HVZK/malicious distinction. The "verifier" merely checks a static proof string.

For malicious verifiers in interactive protocols, the simulator often needs a stronger technique: **rewinding**. Rather than constructing the transcript in one shot (as Schnorr's simulator does), it runs the verifier multiple times, replaying from an earlier state with fresh randomness until it finds a challenge it can handle. Rewinding is a proof technique, not a real capability: it shows that the transcript *could* have been generated without the witness, even though no real prover could rewind a live verifier.

This brings us back to the question posed in the introduction: if a simulator can produce valid transcripts without the witness, what did the prover actually contribute? The answer is not data but *compliance*: she demonstrates she can respond correctly to challenges she could not have predicted. That is soundness. Zero-knowledge is the other side of the same coin: the simulator's success shows that the static transcript, stripped of temporal ordering, contains no extractable information about the witness. The two properties coexist because they concern different things. Soundness is about the live process (commit, then challenge, then respond). Zero-knowledge is about the information content of the record. The simulator can fake the record precisely because it is free from the ordering that makes the process convincing.


## The Limits of Zero-Knowledge

Perfect and statistical zero-knowledge seem strictly stronger than computational. Are they always preferable?

No. There are fundamental limits.

**Theorem (Fortnow, Aiello-Håstad).** Any language with a statistical zero-knowledge proof lies in $\text{AM} \cap \text{coAM}$.

The class $\text{AM}$ (Arthur-Merlin) consists of languages decidable by a two-move interactive proof in which the verifier's coins are public: the verifier sends a random string, the prover responds, and the verifier decides deterministically. Unlike IP, where the verifier's randomness is private, AM exposes it to the prover. The class $\text{coAM}$ contains languages whose complements are in AM. Graph Non-Isomorphism, the protocol we studied earlier, is a natural example of a problem in $\text{AM} \cap \text{coAM}$.

The intersection $\text{AM} \cap \text{coAM}$ is believed to be much smaller than NP. Under standard complexity-theoretic conjectures, it contains no NP-complete problems. The implication is stark: statistical zero-knowledge proofs for NP-complete problems likely do not exist.

The intuition is that statistical zero-knowledge is *too good* at hiding. If a simulator can reproduce the verifier's view without the witness, and no unbounded distinguisher can tell the difference, then the proof isn't leveraging the witness in any essential way. An all-powerful observer could use the simulator itself to decide membership: simulate the transcript, check if the distribution is close to what a real execution would produce, and conclude whether $x \in \mathcal{L}$. This effectively places both $\mathcal{L}$ and its complement in AM. For NP-hard problems, where the witness should be "hard to avoid using," this is too much to ask.

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

Is sum-check zero-knowledge? Not inherently. The univariate polynomials $g_i$ reveal partial information about $g$. If $g$ encodes secret witness data, this information leaks. For applications where $g$ is derived from public inputs (verifiable computation on public data), this leakage is harmless. For private-witness applications, we need modifications.

Several masking techniques (developed in Chapter 18) add zero-knowledge to sum-check:

- Add random low-degree polynomials that cancel in the sum
- Commit to intermediate values instead of revealing them
- Use randomization to hide the structure of $g$

The key insight: zero-knowledge is a *system-level* property, not a per-protocol property. We can compose non-ZK building blocks (sum-check, FRI, polynomial commitments) into ZK systems by carefully controlling what the verifier sees.


> **Zero-knowledge vs. knowledge soundness**
>
> This chapter has focused on what the *verifier* learns. An orthogonal question is what the *prover* demonstrates. A proof system can be zero-knowledge without being a proof of knowledge (GNI proves membership in a language but extracts no witness), and a proof of knowledge without being zero-knowledge (the prover could send the witness in the clear). These are independent axes: zero-knowledge constrains the verifier's view, knowledge soundness (Chapter 16) constrains the prover's ability to cheat without knowing a witness. Practical SNARKs target both, but they are achieved by separate mechanisms: simulation for the former, extraction for the latter.



## Auxiliary Input

If zero-knowledge is a system-level property achieved by composing building blocks, we need a definition that survives composition. The standard simulation definition assumes the verifier starts with only the public statement. But when a ZK proof runs as a subroutine in a larger protocol, the verifier may carry information from earlier stages: an IP address, previous proofs, partial knowledge of the secret from another source. A secure ZK protocol must ensure that even with this extra context, the proof leaks nothing *new*.

**Definition (Auxiliary-Input ZK).** A protocol is auxiliary-input zero-knowledge if for every efficient verifier $\mathcal{V}^*$ with auxiliary input $z$:

$$\text{View}_{\mathcal{V}^*(z)}(\mathcal{P}(w) \leftrightarrow \mathcal{V}^*(z))(x) \approx \mathcal{S}(x, z)$$

The simulator receives the same auxiliary input $z$ as the verifier. The key requirement: whatever the verifier knew beforehand, the proof adds nothing to it.

This definition handles composed protocols. Even if the verifier has side information about the statement or witness, the proof reveals nothing new. The simulator, given the same side information, produces indistinguishable transcripts.

Auxiliary-input ZK is essential for security in complex systems where many proofs interleave.


## Key Takeaways

1. **Zero-knowledge** means existence of a simulator: an efficient algorithm that, without the witness, produces transcripts indistinguishable from real executions. If the transcript could have been fabricated, it carries no information about the witness.

2. **Three flavors**: Perfect (identical distributions), Statistical (negligible statistical distance), Computational (no efficient distinguisher). Modern SNARKs typically achieve computational ZK.

3. **HVZK vs. malicious-verifier ZK**: HVZK assumes the verifier follows the protocol; malicious-verifier ZK protects against arbitrary verifier strategies. Non-interactive proofs (post Fiat-Shamir) largely collapse this distinction.

4. **Simulation does not break soundness.** The simulator works offline, fabricating transcripts of true statements. A cheating prover faces a live verifier on false statements. Rewinding (the simulator's key technique) is a proof method, not a real capability.

5. **Limits of SZK**: Statistical zero-knowledge proofs exist only for languages in $\text{AM} \cap \text{coAM}$, likely excluding NP-complete problems. Computational ZK, paired with computational soundness, sidesteps this barrier.

6. **Sum-check is not inherently ZK**: The round polynomials leak witness information. Masking techniques (Chapter 18) restore privacy. Zero-knowledge is a system-level property, not a per-protocol property.

7. **Auxiliary-input ZK** ensures security under composition: even when the verifier carries side information from other protocol stages, the proof leaks nothing new.

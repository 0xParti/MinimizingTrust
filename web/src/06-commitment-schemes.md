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

**Formal reduction**: Suppose adversary $\mathcal{A}$ breaks binding with non-negligible probability, outputting $(m, r)$ and $(m', r')$ with $m \neq m'$ and $g^m h^r = g^{m'} h^{r'}$. We construct a DLog solver $\mathcal{B}$: given challenge $h$, run $\mathcal{A}$ to get the two openings, then compute $\log_g h = (m - m')/(r' - r) \mod q$. Note $r' \neq r$ since $m \neq m'$ would otherwise give $g^{m-m'} = 1$, implying $m = m' \mod q$. Thus $\mathcal{B}$ solves DLog whenever $\mathcal{A}$ breaks binding.

### Why Hiding Holds

The commitment $C = g^m h^r$ is **perfectly hiding**. Here's the key insight: since $r$ is uniformly random in $\mathbb{Z}_q$, and $h$ is a generator of $G$, the term $h^r$ is uniformly distributed over all of $G$.

For any message $m$, the commitment $C = g^m \cdot h^r$ is a uniformly random group element. This means:

- $\text{Commitment to } m_1 \sim \text{Uniform}(G)$
- $\text{Commitment to } m_2 \sim \text{Uniform}(G)$

The two distributions are identical: not just computationally indistinguishable, but *statistically* identical. Even an unbounded adversary cannot determine the committed value from the commitment alone.


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

If we commit to the coefficient vector using a Pedersen vector commitment, we've effectively committed to the polynomial itself. The verifier knows the evaluation point $z$, so they know $\vec{z} = (1, z, z^2, \ldots)$. The prover knows $\vec{c}$. Proving that a claimed value $v$ equals $f(z) = \langle \vec{c}, \vec{z} \rangle$ becomes an inner product argument: the prover convinces the verifier that their committed vector has the right inner product with the public vector $\vec{z}$.

Homomorphism alone doesn't give us inner products. But it's a key ingredient: inner product arguments (like Bulletproofs) use the additive homomorphism to recursively fold commitments, shrinking the problem size logarithmically. The commitment structure enables the protocol; additional machinery makes it work.

This observation, that polynomial evaluation reduces to inner product, is the conceptual bridge from simple commitments to full polynomial commitment schemes. We'll cross that bridge in Chapter 9.



## Proving Knowledge of an Opening

A commitment alone proves nothing; the prover must eventually reveal the opening to be useful. But what if we want to prove we *know* a valid opening without revealing it?

This is where $\Sigma$-protocols (Chapter 16) enter the picture. A prover who knows the opening for a commitment can convince a verifier they know it without revealing the values. This is a *proof of knowledge*: the prover demonstrates possession of the witness $(m, r)$, not a property of $m$.

**Setup**: The prover has committed $C = g^m h^r$, where $m$ is the secret message and $r$ is the blinding factor. Both are hidden. The prover wants to prove they know $(m, r)$ without revealing either.

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

These requirements conflict. Perfect hiding means the distributions $\{\text{Commit}(m_0; r)\}$ and $\{\text{Commit}(m_1; r)\}$ are identical for all messages $m_0, m_1$. But if the distributions are identical, every commitment value $c$ must be reachable from both $m_0$ and $m_1$ (otherwise we could distinguish them). So there exist openings $(m_0, r_0)$ and $(m_1, r_1)$ that both produce $c$. Binding is broken.

**The resolution**: Relax one property to *computational* rather than *information-theoretic*.

An **information-theoretic** (or *statistical*, or *perfect*) guarantee holds against adversaries with unlimited computational power. No amount of computation can break it. A **computational** guarantee holds only against efficient (polynomial-time) adversaries. An unbounded adversary could break it, but doing so requires solving a problem believed to be hard (like discrete log or factoring).

The tradeoff:

- **Perfectly hiding, computationally binding**: Pedersen commitments. As we proved earlier, for any message $m$ there exists an $r$ that produces any given commitment, so an unbounded adversary cannot determine which value is inside. But finding two openings requires solving discrete log, so binding holds against efficient adversaries. Even an all-powerful being cannot tell which value is committed (perfect hiding), but a quantum computer could eventually break the lock (computational binding).

- **Perfectly binding, computationally hiding**: Hash-based commitments $C = H(m \| r)$. A hash function is deterministic: each $(m, r)$ pair maps to exactly one commitment, and collision resistance means you cannot find two pairs that collide. The value is locked in tight (perfect binding). But an unbounded adversary could brute-force all possible inputs to find $(m, r)$ (computational hiding).

This tradeoff shapes the design space. For ZK proofs, we typically want hiding (don't reveal the witness) and accept computational binding (secure against poly-time adversaries). Pedersen commitments are the natural choice: the witness stays perfectly hidden, and binding holds as long as discrete log is hard.



## Looking Ahead

We've established the cryptographic primitive that makes succinct proofs possible. Commitments transform interactive protocols, where timing and ordering are honor-system, into cryptographically enforced games where cheating is computationally infeasible.

In Chapter 9, we'll see how polynomial commitment schemes (KZG, IPA, and FRI) extend these ideas to commit to polynomials and prove evaluations. These are the engines that power modern SNARKs.

But first, we need to understand *what* we're proving. Chapter 7 introduces the GKR protocol, which uses sum-check to verify layered arithmetic circuits. And Chapter 8 shows how arbitrary computations become circuits, which become polynomials. Together, these chapters complete the story of how a computation becomes a succinct proof.



## Key Takeaways

1. **The binding problem**: Interactive proofs need cryptographic enforcement to prevent provers from adapting their answers to verifier challenges.

2. **Commitment = seal**: A commitment locks in a value before revealing it. Binding ensures it can't change; hiding ensures it reveals nothing.

3. **Pedersen commitments**: $C = g^m h^r$ achieves perfect hiding and computational binding (from discrete log hardness). The generators $g$ and $h$ must have unknown discrete log relationship, or binding fails.

4. **Homomorphic structure**: Pedersen commitments allow addition in the committed domain ($C_1 \cdot C_2$ commits to $m_1 + m_2$), and extend naturally to vectors. Committing to a coefficient vector effectively commits to a polynomial.

5. **Proof of knowledge**: Sigma protocols let a prover demonstrate they know a commitment's opening without revealing it.

6. **Commit-and-prove paradigm**: The foundation of all modern SNARKs: commit first, then prove properties of the committed values.

7. **Bridge to polynomial commitments**: Polynomial evaluation is an inner product. This connects vector commitments to the polynomial commitment schemes (Chapter 9) that power SNARKs.

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

This seemingly simple equation has profound consequences. It allows us to check multiplicative relationships *in the exponent*. Given commitments $g^a$ and $g^b$, we cannot compute $g^{ab}$ (that would break CDH). But if someone claims to know $c = ab$, we can *verify* their claim by checking:

$$e(g^a, g^b) = e(g^c, g)$$

One multiplication check "for free" in the hidden exponent world. This is exactly what polynomial evaluation needs.

### The Trusted Setup

KZG requires a **structured reference string (SRS)**: a set of public parameters computed from a secret:

1. Choose a random secret $\tau \in \mathbb{F}_p$ (the "toxic waste")
2. Compute the SRS: $(g, g^\tau, g^{\tau^2}, \ldots, g^{\tau^D})$
3. **Destroy** $\tau$

The SRS encodes powers of the secret $\tau$ "in the exponent." Anyone can use these elements without knowing $\tau$ itself. But if anyone learns $\tau$, they can forge proofs for false statements, so the setup must ensure $\tau$ is never known to any party. In practice, this is done via multi-party computation ceremonies where many participants contribute randomness, and security holds as long as *any one* participant is honest.

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

The verification equation $e(\pi, g^\tau \cdot g^{-z}) = e(C \cdot g^{-v}, g)$ is equivalent to the polynomial identity $w(\tau)(\tau - z) = f(\tau) - v$. To see this, substitute the definitions:

- $\pi = g^{w(\tau)}$
- $g^\tau \cdot g^{-z} = g^{\tau - z}$
- $C \cdot g^{-v} = g^{f(\tau)} \cdot g^{-v} = g^{f(\tau) - v}$

This gives:

$$e(g^{w(\tau)}, g^{\tau - z}) = e(g^{f(\tau) - v}, g)$$

By bilinearity:
$$e(g,g)^{w(\tau)(\tau - z)} = e(g,g)^{f(\tau) - v}$$

This holds iff $w(\tau)(\tau - z) = f(\tau) - v$, which is exactly the polynomial identity $f(X) - v = w(X)(X - z)$ evaluated at $\tau$.

**Why this implies soundness**: Suppose the prover lies; they claim $f(z) = v$ when actually $f(z) \neq v$. Then $f(X) - v$ is *not* divisible by $(X - z)$, so no polynomial $w(X)$ satisfies the identity $f(X) - v = w(X)(X - z)$. Without such a $w(X)$, the prover must instead find some $w'(X)$ where the identity fails as polynomials but happens to hold at $\tau$:

$$w'(\tau)(\tau - z) = f(\tau) - v$$

But the prover doesn't know $\tau$; it's hidden in the SRS. From their perspective, $\tau$ is a random field element. Two distinct degree-$d$ polynomials agree on at most $d$ points (Schwartz-Zippel), so the probability that a "wrong" $w'$ accidentally satisfies the check at the unknown $\tau$ is at most $d/|\mathbb{F}|$ (negligible for large fields).

**Formal soundness statement**: Let $f(X)$ be the committed polynomial of degree at most $d$. For any adversary $\mathcal{A}$ that outputs $(z, v, \pi)$ with $f(z) \neq v$:
$$\Pr[\text{Verify}(C, z, v, \pi) = \text{accept}] \leq \frac{d}{|\mathbb{F}|}$$
where the probability is over the random choice of $\tau$ in the trusted setup. Under the $q$-Strong Diffie-Hellman assumption (that computing $g^{1/(\tau+a)}$ from the SRS is hard), this bound holds even for adversaries who choose $f$ adaptively.



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



## Managing Toxic Waste: Powers of Tau Ceremonies

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

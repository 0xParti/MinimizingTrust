# Chapter 9: Polynomial Commitment Schemes: The Cryptographic Engine

In 2016, six people met in a hotel room to birth the Zcash privacy protocol. Their task: generate a cryptographic secret so dangerous that if even one of them kept a copy, it could forge unlimited fake coins, undetectable forever. They called it "toxic waste."

The ceremony was a paranoid ballet. Participants were scattered across the globe, connected by encrypted channels. One flew to an undisclosed location, computed on an air-gapped laptop, then incinerated the machine and its hard drive. Another broadcast their participation live so viewers could verify no one was coercing them. The randomness they generated was combined through multi-party computation, ensuring that if *any single participant* destroyed their secret, the final parameters would be safe.

Why such extreme measures? Because polynomial commitment schemes, the cryptographic engine that makes SNARKs work, sometimes require a *structured reference string*: public parameters computed from a secret that must then cease to exist. The Zcash ceremony became legendary in cryptography circles, part security protocol, part performance art. It demonstrated both the power and the peril of pairing-based commitments.

This chapter explores that peril and its alternatives. We'll see two fundamental approaches to polynomial commitments: **KZG**, which achieves constant-size proofs at the cost of trusted setup, and **IPA/Bulletproofs**, which eliminates the toxic waste but pays with linear verification. Each represents a different answer to the same question: how do you prove facts about a polynomial without revealing it? A third major scheme, **FRI**, takes a fundamentally different approach based on hashing rather than algebraic assumptions; we cover it in Chapter 10. (For advanced schemes like **Dory** that achieve logarithmic verification without trusted setup, see Appendix D.)

---

Everything we've built (sum-check, GKR, arithmetization) reduces complex claims to polynomial identities. A prover claims that polynomial $p(X)$ has certain properties: it equals another polynomial, it vanishes on a domain, it evaluates to a specific value at a point.

But here's the catch: verifying these claims directly would require the verifier to see the entire polynomial. For a polynomial of degree $n$, that's $n+1$ coefficients, exactly as much data as the original computation. We've achieved nothing.

**Polynomial Commitment Schemes (PCS)** solve this problem. A PCS allows a prover to commit to a polynomial with a short commitment, then later prove claims about the polynomial (its evaluations at specific points) without revealing the polynomial itself. The commitment is binding (the prover can't change the polynomial), and the proofs are succinct (much smaller than the polynomial).

This is where abstract algebra meets cryptography.



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


## Batch Opening

KZG has a remarkable property: proving evaluations at multiple points is barely more expensive than proving one.

To prove $f(z_1) = v_1, \ldots, f(z_k) = v_k$:

1. Define the vanishing polynomial $Z(X) = \prod_i (X - z_i)$
2. Compute the interpolating polynomial $R(X)$ such that $R(z_i) = v_i$
3. The quotient $w(X) = \frac{f(X) - R(X)}{Z(X)}$ exists iff all evaluations are correct
4. The proof is just $g^{w(\tau)}$ (still one group element!)

This is why KZG scales so well in practice. A SNARK verifier might need to check dozens of polynomial evaluations; with batch opening, these collapse into a single pairing check.


## KZG: Properties and Trade-offs

**Advantages**:

- **Constant commitment size**: One group element, regardless of polynomial degree
- **Constant proof size**: One group element per evaluation
- **Constant verification time**: A few pairings and exponentiations
- **Batch opening**: Multiple evaluations verified with a single proof

**Disadvantages**:

- **Trusted setup**: The "toxic waste" must be destroyed. If compromised, soundness breaks.
- **Not post-quantum**: Pairing-based cryptography falls to quantum computers
- **Degree-bounded**: The SRS size caps the maximum polynomial degree


## Managing Toxic Waste: Powers of Tau Ceremonies

The trusted setup creates a serious practical problem: someone must generate τ, compute the powers, and then *verifiably destroy* τ. How do you convince the world that the toxic waste is truly gone?

The solution is **multi-party computation (MPC) ceremonies**. Instead of trusting a single party, we chain together contributions from many independent participants:

1. **Participant 1** picks secret $\tau_1$, computes $[1]_1, [\tau_1]_1, [\tau_1^2]_1, \ldots$ and destroys $\tau_1$
2. **Participant 2** picks secret $\tau_2$, raises each element to $\tau_2$, getting $[1]_1, [\tau_1\tau_2]_1, [(\tau_1\tau_2)^2]_1, \ldots$ and destroys $\tau_2$
3. Continue for hundreds or thousands of participants...

The final structured reference string encodes powers of $\tau = \tau_1 \cdot \tau_2 \cdot \tau_3 \cdots \tau_n$. The crucial insight: **the setup is secure if *any single participant* destroyed their secret**. This is the "1-of-N" trust model; you only need to trust that *one* honest participant existed among potentially thousands.

The Zcash Powers of Tau ceremony (2017-2018) had 87 participants contribute to a universal phase, followed by circuit-specific ceremonies for Sapling. The Ethereum KZG Ceremony (2023) dwarfed this with over 140,000 contributions for EIP-4844 blob commitments.

Some ceremonies produce parameters usable for any circuit up to a size bound (universal), while others are tailored to specific circuits. KZG setups are inherently universal; the same powers of tau work for any polynomial of degree at most $d$.

The scale of modern ceremonies makes collusion effectively impossible. When 140,000 independent participants contribute, the probability that *all* of them colluded or were compromised approaches zero.



## IPA/Bulletproofs: No Trusted Setup

The Inner Product Argument emerged from a different lineage than KZG. Bootle et al. (2016) introduced the core folding technique for efficient inner product proofs. Bünz et al. (2017) refined this into **Bulletproofs**, originally designed for *range proofs*, proving that a committed value lies in a range $[0, 2^n)$ without revealing it. This was motivated by confidential transactions in cryptocurrencies: prove your balance is non-negative without revealing the amount.

The terminology can be confusing:

- **IPA** (Inner Product Argument) is the *technique*: the recursive folding protocol that proves $\langle \vec{a}, \vec{b} \rangle = c$
- **Bulletproofs** is the *system* that used IPA for range proofs and general arithmetic circuits

Today, "IPA" and "Bulletproofs" are often used interchangeably to describe the folding-based polynomial commitment scheme. The key innovation: achieving transparency (no toxic waste) at the cost of logarithmic proofs and linear verification.

### The Key Insight: Polynomial Evaluation as Inner Product

As we saw in Chapters 4 and 5, polynomial evaluation is an inner product. For univariate polynomials:

$$f(z) = \sum_{i=0}^{n-1} c_i z^i = \langle \vec{c}, \vec{z} \rangle$$

where $\vec{c} = (c_0, \ldots, c_{n-1})$ are coefficients and $\vec{z} = (1, z, z^2, \ldots, z^{n-1})$ is the powers vector. For multilinear polynomials, the structure differs: $\tilde{f}(r_1, \ldots, r_n) = \langle \vec{f}, \vec{L}(r) \rangle$, where $\vec{f}$ contains evaluations on the Boolean hypercube and $\vec{L}(r)$ contains Lagrange basis weights. Both cases reduce polynomial evaluation to an inner product claim, but the vectors involved differ. If we can prove inner product claims efficiently, we can prove polynomial evaluations. IPA does exactly this: it reduces the inner product by *folding* both vectors with random challenges, halving the dimension each round. This is the same algebraic trick as sum-check, with different cryptographic wrapping. We'll develop IPA using the univariate representation (coefficients × powers), but the technique applies to any inner product.

### From Vector Commitments to Inner Product Claims

We've reduced polynomial evaluation to an inner product, and inner products operate on vectors. So to commit to a polynomial, we commit to a vector (its coefficients). Pedersen commitments provide exactly this: a way to commit to a vector such that we can later prove inner product claims about it.

The basic Pedersen vector commitment uses generators $\vec{G} = (G_0, \ldots, G_{n-1})$ (one per coefficient) and $H$ for blinding:

$$C = \langle \vec{c}, \vec{G} \rangle + r \cdot H = \sum_{i=0}^{n-1} c_i \cdot G_i + r \cdot H$$

This commits to the polynomial's coefficient vector $\vec{c} = (c_0, \ldots, c_{n-1})$. The commitment $C$ binds us to these coefficients, but to prove an evaluation $\langle \vec{c}, \vec{z} \rangle = v$, we need to bind the claimed value $v$ into the protocol as well. IPA does this by introducing a separate generator $U$ and forming:

$$P = \langle \vec{c}, \vec{G} \rangle + v \cdot U + r \cdot H$$

Think of $P$ as encoding two things simultaneously: the coefficient vector (via $\vec{G}$) and the claimed inner product (via $U$). The folding protocol will manipulate both parts together, and only if $v$ is the true inner product will everything stay consistent through the recursion.

### The Folding Trick

The brilliant idea of IPA is recursive "folding" that shrinks the problem by half each round.

**Setup**

Prover holds coefficient vector $\vec{c}$ of length $n$. They've committed to it as $P = \langle \vec{c}, \vec{G} \rangle + v \cdot U$ where $v = \langle \vec{c}, \vec{z} \rangle$ is the claimed evaluation. (We omit the blinding term $rH$ for clarity.)

**One round of folding**

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

**Why this works**

We need to show that $P'$ is a valid commitment to $(\vec{c}', v')$ under the folded generators $\vec{G}'$.

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

**The recursion**

After $\log_2 n$ rounds, the vectors have length 1. The prover reveals the final scalar, and the verifier checks directly.

### Final Verification: The Endgame

After $\log_2 n$ rounds of folding, the vectors have length 1:

- Prover holds a single scalar $c'$ (the folded coefficient)
- The $z$-vector has folded to $z'$ (known to both parties)
- The commitment has transformed to $P_{\text{final}}$ through all the updates

**The prover reveals**

- The final coefficient $c' \in \mathbb{F}$
- The final blinding factor $r' \in \mathbb{F}$

The verifier must check: does $c'$ actually correspond to the final commitment?

$$P_{\text{final}} \stackrel{?}{=} c' \cdot G'_1 + (c' \cdot z'_1) \cdot U + r' \cdot H$$

where $z'_1$ is the final folded evaluation point (known to both parties).

But what is $G'_1$? It's the result of folding all the generators through all $\log n$ rounds:

$$\vec{G}' = \alpha_1^{-1} \vec{G}_L^{(1)} + \alpha_1 \vec{G}_R^{(1)} \quad \text{(first fold)}$$
$$\vec{G}'' = \alpha_2^{-1} \vec{G}'_L + \alpha_2 \vec{G}'_R \quad \text{(second fold)}$$
$$\vdots$$

Computing this folded generator is the verifier's bottleneck: it requires applying all $\log n$ folding operations to the original $n$ generators, taking $O(n)$ group operations. The verifier needs to know what commitment value a correctly-folded polynomial *should* produce, and there's no shortcut without computing the folded generators. This is IPA's fundamental trade-off: no trusted setup, but linear verification. We'll analyze when this cost is acceptable after the worked example.

### Worked Example: IPA Verification

Let's trace through a complete IPA proof for a polynomial with 4 coefficients. This requires 2 rounds of folding. We work in $\mathbb{F}_{101}$, where $2^{-1} = 51$ (since $2 \cdot 51 = 102 \equiv 1$) and $3^{-1} = 34$ (since $3 \cdot 34 = 102 \equiv 1$).

**Setup**

- Coefficient vector: $\vec{c} = (3, 5, 2, 7)$ (prover's secret)
- Evaluation point: $z = 2$, so $\vec{z} = (1, 2, 4, 8)$ (public)
- Claimed evaluation: $v = \langle \vec{c}, \vec{z} \rangle = 3(1) + 5(2) + 2(4) + 7(8) = 77$
- Generators: $G_1, G_2, G_3, G_4$ (for coefficients), $U$ (for inner product)
- Initial commitment: $P = (3G_1 + 5G_2 + 2G_3 + 7G_4) + 77U$

The verifier knows: $P$, $\vec{z}$, $v = 77$, and all generators. The verifier does *not* know $\vec{c}$.

**Round 1** (reduce from 4 to 2 elements)

*Prover's work* (uses secret $\vec{c}$):

Split: $\vec{c}_L = (3, 5)$, $\vec{c}_R = (2, 7)$, $\vec{z}_L = (1, 2)$, $\vec{z}_R = (4, 8)$

Compute cross inner products:

- $\langle \vec{c}_L, \vec{z}_R \rangle = 3(4) + 5(8) = 52$
- $\langle \vec{c}_R, \vec{z}_L \rangle = 2(1) + 7(2) = 16$

Send commitments to verifier:

- $L_1 = (3G_3 + 5G_4) + 52U$
- $R_1 = (2G_1 + 7G_2) + 16U$

*Verifier's challenge*: $\alpha_1 = 2$, so $\alpha_1^{-1} = 51$

*Both parties compute* (verifier uses only public information):

Folded generators: $\vec{G}' = \alpha_1^{-1} \vec{G}_L + \alpha_1 \vec{G}_R$

- $G'_1 = 51 G_1 + 2 G_3$
- $G'_2 = 51 G_2 + 2 G_4$

Folded evaluation vector: $\vec{z}' = \alpha_1^{-1} \vec{z}_L + \alpha_1 \vec{z}_R$

- $z'_1 = 51(1) + 2(4) = 59$
- $z'_2 = 51(2) + 2(8) = 102 + 16 = 17 \pmod{101}$

Updated commitment: $P' = \alpha_1^2 L_1 + P + \alpha_1^{-2} R_1 = 4 L_1 + P + 76 R_1$

(Here $\alpha_1^{-2} = 51^2 = 2601 \equiv 76 \pmod{101}$)

The $U$-coefficient of $P'$ becomes $v' = 77 + 4(52) + 76(16) = 77 + 208 + 1216 \equiv 87 \pmod{101}$.

*Prover also computes* (secretly):

$\vec{c}' = \alpha_1 \vec{c}_L + \alpha_1^{-1} \vec{c}_R = 2(3,5) + 51(2,7) = (6 + 102, 10 + 357) = (108, 367) \equiv (7, 64) \pmod{101}$

Sanity check: $\langle \vec{c}', \vec{z}' \rangle = 7(59) + 64(17) = 413 + 1088 = 1501 \equiv 87 \pmod{101}$ $\checkmark$

**Round 2** (reduce from 2 to 1 element)

*Prover's work*:

Split: $c'_L = 7$, $c'_R = 64$, $z'_L = 59$, $z'_R = 17$

Compute cross inner products:

- $c'_L \cdot z'_R = 7 \cdot 17 = 119 \equiv 18 \pmod{101}$
- $c'_R \cdot z'_L = 64 \cdot 59 = 3776 \equiv 38 \pmod{101}$

Send commitments:

- $L_2 = 7 G'_2 + 18 U$
- $R_2 = 64 G'_1 + 38 U$

*Verifier's challenge*: $\alpha_2 = 3$, so $\alpha_2^{-1} = 34$

*Both parties compute*:

Folded generator: $G'' = 34 G'_1 + 3 G'_2$

Folded evaluation point: $z'' = 34(59) + 3(17) = 2006 + 51 \equiv 36 \pmod{101}$

Updated commitment: $P'' = 9 L_2 + P' + 45 R_2$

(Here $\alpha_2^{-2} = 34^2 = 1156 \equiv 45 \pmod{101}$)

The $U$-coefficient of $P''$ becomes $v'' = 87 + 9(18) + 45(38) = 87 + 162 + 1710 \equiv 41 \pmod{101}$.

*Prover computes*:

$c'' = 3(7) + 34(64) = 21 + 2176 \equiv 75 \pmod{101}$

Sanity check: $c'' \cdot z'' = 75 \cdot 36 = 2700 \equiv 41 \pmod{101}$ $\checkmark$

**Final verification**

Prover reveals: $c'' = 75$

Verifier computes the fully folded generator $G''$ in terms of original generators:
$$G'' = 34 G'_1 + 3 G'_2 = 34(51 G_1 + 2 G_3) + 3(51 G_2 + 2 G_4)$$
$$= 1734 G_1 + 153 G_2 + 68 G_3 + 6 G_4 \equiv 17 G_1 + 52 G_2 + 68 G_3 + 6 G_4 \pmod{101}$$

This is the $O(n)$ work: computing a linear combination of all $n$ original generators.

Verifier checks: $P'' \stackrel{?}{=} c'' \cdot G'' + (c'' \cdot z'') \cdot U$

Substituting: $P'' \stackrel{?}{=} 75 \cdot (17 G_1 + 52 G_2 + 68 G_3 + 6 G_4) + 41 \cdot U$

Expanding (mod 101): $P'' \stackrel{?}{=} 62 G_1 + 61 G_2 + 48 G_3 + 46 G_4 + 41 U$

The verifier also computes $P''$ from the commitment updates: $P'' = 9 L_2 + P' + 45 R_2$, which traces back through $P' = 4 L_1 + P + 76 R_1$ to the original commitment $P = 3G_1 + 5G_2 + 2G_3 + 7G_4 + 77U$. Both sides match, so the proof is valid. The verifier is convinced that the prover knows $\vec{c}$ such that $\langle \vec{c}, \vec{z} \rangle = 77$, without ever learning $\vec{c}$.

### Efficiency

- **Commitment size**: One group element (same as KZG)
- **Proof size**: $O(\log n)$ group elements (the $L_i, R_i$ cross-terms from each round)
- **Verifier time**: $O(n)$ (must compute folded generators; this is the fundamental limitation)
- **Prover time**: $O(n \log n)$

The verifier's linear work is the main drawback compared to KZG's constant verification. However, IPA requires no trusted setup; the generators can be chosen transparently (e.g., by hashing).

### The Linear Verifier Problem

This $O(n)$ verification cost is a serious limitation. For a polynomial with $N = 2^{20}$ coefficients (about 1 million), the verifier must perform over a million group operations, each involving expensive elliptic curve arithmetic. A scalar multiplication on an elliptic curve involves roughly 400 group additions, and each group addition involves 6-12 base field operations. The result: verification can be ~4000× slower than simple field arithmetic.

For interactive proofs where verification happens once, this is acceptable. For applications like blockchains where proofs are verified by thousands of nodes, or for recursive proof composition, linear verification becomes prohibitive.

This limitation motivated the development of schemes like Hyrax and Dory that exploit additional structure to achieve sublinear verification. (See Appendix D for Dory's approach.)



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

- **KZG** is the right choice when verification efficiency is paramount and a trusted setup is acceptable. Most production SNARKs (Groth16, PLONK with KZG) use this approach.
- **IPA** is the right choice when trust minimization is critical, or in systems designed for transparent setups (Halo, Pasta curves).

What if we want both transparency *and* efficient verification? Schemes like **Hyrax** and **Dory** achieve sublinear verification without trusted setup by exploiting additional algebraic structure. The machinery is more complex, so we cover these advanced schemes in Appendix D.



## Multilinear Polynomial Commitments

Both KZG and IPA extend naturally to multilinear polynomials, exploiting the tensor structure of Lagrange basis evaluations.

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
- FRI (Chapter 10) → STARKs (transparent, post-quantum)



## The Complete PCS Landscape

Now that we've seen both commitment schemes in depth, let's compare them systematically (including Dory from Appendix D and FRI from Chapter 10 for reference):

| Property | KZG | IPA/Bulletproofs | Dory (App. D) | FRI (Ch. 10) |
|----------|-----|------------------|---------------|--------------|
| **Trusted setup** | Required | None | None | None |
| **Commitment size** | $O(1)$ | $O(1)$ | $O(1)$ | $O(1)$ |
| **Proof size** | $O(1)$ | $O(\log N)$ | $O(\log N)$ | $O(\log^2 N)$ |
| **Verification time** | $O(1)$ | $O(N)$ | $O(\log N)$ | $O(\log^2 N)$ |
| **Prover time** | $O(N)$ | $O(N \log N)$ | $O(N)$ | $O(N \log N)$ |
| **Assumption** | q-SDH + Pairings | DLog only | DLog + Pairings | Hash collision |
| **Post-quantum** | No | No | No | **Yes** |
| **Batching** | Excellent | Good | Very good | Good |

KZG dominates when verification cost matters and trust is acceptable, which is why Ethereum L1 and most production SNARKs use it. IPA suits applications where trust minimization outweighs verification speed, like privacy-focused systems. FRI is the only option that survives quantum computers.



## Key Takeaways

### The Core Abstraction

1. **Polynomial commitments bridge theory and practice.** Interactive proofs reduce complex claims to polynomial identities, but verifying those identities directly requires seeing the entire polynomial. A PCS lets the prover commit to a polynomial with a short commitment, then prove evaluations at specific points without revealing anything else.

2. **The interface is simple: Commit, Open, Verify.** Binding ensures the prover can't change the polynomial after committing. Succinctness ensures commitments and proofs are much smaller than the polynomial itself. These two properties are what make succinct proofs possible.

3. **Polynomial evaluation reduces to inner product.** For a polynomial $f(X) = \sum c_i X^i$, the evaluation $f(z) = \langle \vec{c}, (1, z, z^2, \ldots) \rangle$. This connection underlies IPA, which proves inner products directly via recursive folding.

### The Two Paradigms

4. **KZG achieves constant-size proofs via pairings.** The key insight: if $(X - z)$ divides $f(X) - v$, then $f(z) = v$. The prover commits to the quotient; the verifier checks divisibility at a secret point $\tau$ using one pairing equation. No matter the polynomial's size, the proof is one group element.

5. **KZG requires trusted setup.** The structured reference string encodes powers of a secret $\tau$. If anyone learns $\tau$, they can forge proofs. Multi-party ceremonies with thousands of participants ensure security under the "1-of-N" trust model: security holds if any single participant was honest.

6. **IPA eliminates trusted setup via recursive folding.** Each round halves the problem size by combining left and right halves with a random challenge. After $\log n$ rounds, the prover reveals a single scalar. The verifier checks consistency by tracking commitment updates through all rounds.

7. **IPA's bottleneck is linear verification.** The verifier must compute folded generators, requiring $O(n)$ group operations. This is acceptable for single proofs but prohibitive for recursive composition or blockchain verification where proofs are checked thousands of times. Schemes like Dory (Appendix D) address this limitation.

### Practical Considerations

8. **Batching amortizes costs across many polynomials.** KZG batches evaluations at multiple points into one proof. For systems with dozens of committed polynomials, batching dominates the cost savings.

9. **The choice of PCS determines SNARK properties.** KZG gives constant verification with trusted setup (Groth16, PLONK). IPA gives transparency with linear verification (Halo). FRI (next chapter) gives post-quantum security. The right choice depends on whether you prioritize verification speed, trust minimization, or quantum resistance.

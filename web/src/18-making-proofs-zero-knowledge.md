# Chapter 18: Making Proofs Zero-Knowledge

A conventional proof convinces by exposing its internals. The verifier sees intermediate values, checks each step, and traces the chain of reasoning from hypothesis to conclusion. Conviction comes from transparency: every piece of the argument is laid bare for inspection.

Zero-knowledge proofs must convince without this transparency. The verifier still receives messages, checks relationships, and follows a protocol. But the values she sees are randomized so that they carry no information about the witness. She inspects a full transcript and becomes convinced the statement is true, yet the transcript could have come from any valid witness, or from no witness at all (a simulator). The challenge is preserving the structure that makes verification work while destroying the information that would make the witness recoverable.

This requires care.

Most proof systems were not designed with privacy in mind. The interactive proofs of the 1980s and 1990s were built to make verification cheap: a weak verifier checking claims from a powerful prover. The sum-check protocol, GKR, and the algebraic machinery underlying modern SNARKs all emerged from complexity theory, where the goal was efficient verification, not confidential computation. Privacy became necessary only later, as these tools migrated from theory to practice and applications like blockchain transactions, private credentials, and anonymous voting demanded that proofs reveal nothing beyond validity. The result is a retrofit problem: taking elegant machinery built for transparency and making it opaque.

We saw zero-knowledge informally in $\Sigma$-protocols (Chapter 16), then formally in Chapter 17. We have also seen it applied in specific systems: the random scalars $(r, s)$ in Groth16 (Chapter 12), the blinding polynomials $(b_1 X + b_2) Z_H(X)$ in PLONK (Chapter 13). Strip these additions and the proof systems still work, they are still sound and succinct, but they leak witness information. This chapter develops the general theory behind those additions. How do we take a working proof system and add the layer that makes it reveal nothing?

The chapter develops two general techniques, then shows how specific proof systems apply them.

**Commit-and-prove** works for any protocol: hide every witness-dependent value behind a commitment, then prove the required relations via $\Sigma$-protocols. This is general but expensive, with cost proportional to the number of multiplications.

**Masking polynomials** applies specifically to protocols where the prover sends polynomials (notably sum-check): add random noise that preserves validity while hiding the witness. This is efficient but requires algebraic structure.

Neither technique is used in isolation by production systems. Groth16 and PLONK each implement their own variants, tailored to their algebraic structure. After developing the general theory, we examine how these systems achieve zero-knowledge in practice.

## The Leakage Problem

Let's be concrete about what leaks. Consider the sum-check protocol proving:

$$H = \sum_{b \in \{0,1\}^n} g(b)$$

When $g$ encodes private witness values, the verifier should not learn $g$ beyond what is necessary for verification. In a proper ZK protocol, the verifier would only learn $g(r)$ at a single random point $r$ at the end (via a commitment opening), not the polynomial itself. But sum-check requires the prover to send intermediate polynomials.

In round $i$, the prover sends a univariate polynomial representing the partial sum with variable $X_i$ free:

$$g_i(X_i) = \sum_{b_{i+1}, \ldots, b_n \in \{0,1\}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

This polynomial depends on $g$. Its coefficients encode information about the witness.

To see this concretely, suppose $g$ encodes a computation with secret witness values $(w_1, w_2, w_3)$:

$$g(X_1, X_2) = w_1 X_1 + w_2 X_2 + w_3 X_1 X_2$$

The verifier does not know this polynomial; they only know they are verifying a sum. The first round polynomial is:

$$g_1(X_1) = g(X_1, 0) + g(X_1, 1) = w_1 X_1 + (w_1 X_1 + w_2 + w_3 X_1) = (2w_1 + w_3) X_1 + w_2$$

The prover sends this polynomial to the verifier. The constant term is exactly $w_2$. The coefficient of $X_1$ is $2w_1 + w_3$. The verifier learns linear combinations of the secrets directly from the protocol message.

Consider what these witness values could represent. Suppose you are proving eligibility for a loan without revealing your finances. Your witness might encode: $w_1$ = your salary, $w_2$ = your social security number, $w_3$ = your total debt. The computation verifies that your debt-to-income ratio meets some threshold. From that single round polynomial, the verifier learns your SSN directly (the constant term) and a linear combination of your salary and debt. They did not need to learn any of this to verify your eligibility. The protocol leaked it anyway.

This isn't zero-knowledge. We need to hide these coefficients while still allowing verification.


## Technique 1: Commit-and-Prove

The commit-and-prove approach is conceptually simple: never send a value in the clear. Always send a commitment, then prove the committed values satisfy the required relations.

### The Paradigm

For any public-coin protocol that sends witness-dependent values (public-coin means the verifier's messages are random and visible to both parties, which is the case for sum-check, GKR, and all Fiat-Shamir-compiled protocols):

1. **Replace values with commitments.** Instead of sending $v$, send $C(v) = g^v h^r$ (a Pedersen commitment with random blinding $r$).

2. **Prove relations in zero-knowledge.** For each algebraic relation the original protocol checks (e.g., "this value equals that value," "this is the product of those two"), run a $\Sigma$-protocol on the committed values.

The verifier never sees actual values. They see commitments (opaque group elements that reveal nothing about the committed data). The $\Sigma$-protocols convince them the data satisfies the required structure.

### Pedersen's Homomorphism as Leverage

Recall from Chapter 6 that Pedersen commitments ($C(v) = g^v h^r$) are perfectly hiding (the commitment reveals nothing about $v$, even to an unbounded adversary) and additively homomorphic ($C(a) \cdot C(b) = C(a + b)$). This means the verifier can check additive relations on committed values for free, without any interaction or $\Sigma$-protocol: given $C(a), C(b), C(c)$, verify $c = a + b$ by checking $C(c) = C(a) \cdot C(b)$.

Multiplication is more expensive. Checking $c = a \cdot b$ on committed values requires a $\Sigma$-protocol that proves the multiplicative relation without revealing the values. This takes three group elements and three field elements per multiplication gate.

### Applying to Circuits

Since arithmetic circuits consist entirely of addition and multiplication gates, the cost of commit-and-prove is determined by the multiplication count $M$: the prover commits to every wire value, addition gates are verified for free via homomorphism, and each multiplication gate requires one $\Sigma$-protocol (~3 group elements). The proof contains $O(M)$ group elements (one $\Sigma$-protocol transcript per multiplication gate), and verification requires $O(M)$ group exponentiations, each costing $O(\lambda)$ field multiplications for security parameter $\lambda$.

This is not succinct. A circuit with a million multiplications produces a proof with millions of group elements. But it achieves *perfect* zero-knowledge: the simulator can produce indistinguishable transcripts by simulating each $\Sigma$-protocol independently.

### Recovering Succinctness: Proof on a Proof

Commit-and-prove costs $O(M)$ per multiplication gate, so it is impractical for large circuits. But it does not need to be applied to the original circuit. The idea is to split the work into two layers:

1. **First layer (not zero-knowledge).** Run an efficient interactive proof, such as GKR (Chapter 7), on the original circuit $C$. GKR is sound and succinct: the verifier's work is polylogarithmic in $|C|$. The protocol produces a transcript $T$ consisting of prover messages, verifier challenges, and a final evaluation claim. This transcript is not zero-knowledge; the prover's messages leak witness information.

2. **Second layer (zero-knowledge).** The GKR verifier is itself a computation: given $T$, check consistency and output accept or reject. Express this verification as a small circuit $V_{\text{GKR}}$ of size $O(\text{polylog}(|C|))$. Now apply commit-and-prove to $V_{\text{GKR}}$: the prover commits to all transcript values (which include the witness-derived quantities), then proves via $\Sigma$-protocols that these commitments would make $V_{\text{GKR}}$ accept.

This is the "proof on a proof": the first layer proves correctness (via GKR), the second layer proves that the first layer's transcript is valid without revealing it (via commit-and-prove on the small verifier circuit). The cost of the second layer depends on $V_{\text{GKR}}$'s multiplication count, which is polylogarithmic in $|C|$, not on $|C|$ itself.

The key detail is the structure of $V_{\text{GKR}}$. Recall from Chapter 7 that GKR verification consists mostly of sum-check consistency checks (pure additions, which Pedersen homomorphism handles for free). The only multiplications arise at layer boundaries, where the verifier checks an equation involving the product of two sub-circuit evaluations: one multiplication per layer. A circuit of depth $d = O(\log n)$ thus requires only $O(\log n)$ $\Sigma$-protocols in the second layer, not the $O(n)$ that direct commit-and-prove on the original circuit would require.

The verifier sees the public inputs and outputs (part of the statement), Pedersen commitments to all transcript values, and $\Sigma$-protocol proofs that the committed values satisfy GKR verification. The witness $w$ is still encoded in the transcript coefficients $c_j$ (the chain is $w \to \text{gate values} \to \text{layer MLEs} \to \text{sum-check polynomials} \to c_j$), but the commitments are perfectly hiding. The $\Sigma$-protocols prove only *structural* facts about these coefficients (that they satisfy certain arithmetic relations), never *semantic* facts (what they represent in the original computation). Every valid witness producing the same output $y$ yields commitments with the same distribution, so the verifier cannot distinguish which $w$ was used.



## Technique 2: Masking Polynomials

Commit-and-prove hides values behind commitments and proves relations one at a time. This is general but expensive: the cost scales with the number of multiplications. For polynomial-based protocols like sum-check, a lighter approach exists: instead of hiding each value individually, randomize the polynomial itself so that the values the verifier sees carry no information about the witness.

### The Core Idea

Whenever a protocol requires the prover to send a polynomial derived from the witness (as sum-check does with its round polynomials), the prover can mask it. Instead of sending $g(X)$ directly, the prover sends:

$$f(X) = g(X) + \rho \cdot p(X)$$

where $p(X)$ is a random polynomial (committed in advance) and $\rho$ is a random scalar from the verifier.

Since $p$ is random and $\rho$ is chosen after the commitment, $\rho \cdot p(X)$ acts like a one-time pad: the verifier sees $f$ but cannot extract $g$ without knowing $p$.

The natural concern is soundness. The original protocol verified $\sum_b g(b) = H$; now the verifier sees $f = g + \rho p$ instead. The masked sum is:

$$\sum_b f(b) = \sum_b g(b) + \rho \cdot \sum_b p(b) = H + \rho \cdot P$$

where $P = \sum_b p(b)$ is sent alongside the commitment to $p$. The verifier checks $\sum_b f(b) = H + \rho P$. For a false claim $H' \neq H$, this requires $H + \rho P = H' + \rho P$, which implies $H = H'$. Masking is a *soundness-preserving transformation*: it changes the representation but not the truth value.

### Constructing the Masking Polynomial

The masking polynomial $p(X)$ must have the same degree structure as $g$ (otherwise $f = g + \rho p$ would fail the verifier's degree checks), known aggregate sum $P = \sum_b p(b)$ (so the verifier can adjust the check), and genuinely random coefficients (so the masking actually hides $g$).

**Protocol flow:**

1. Before the main protocol, the prover commits to a random masking polynomial $p$ and sends its sum $P = \sum_b p(b)$.
2. The verifier sends a random $\rho$.
3. The prover runs sum-check on $f = g + \rho p$, sending masked round polynomials.
4. The verifier checks that round polynomials sum correctly to $H + \rho P$ (the adjusted claim).

The verifier sees $f$ and knows $f = g + \rho p$ with $\rho$, but only has a commitment to $p$, not $p$ itself. For any polynomial the verifier might guess for $g$, there exists a $p$ consistent with the observed $f$. This is the polynomial one-time pad: the random masking makes all witness polynomials equally plausible. In the multivariate case, the prover commits to a masking polynomial $p(X_1, \ldots, X_n)$ with the same structure as $g$, and each sum-check round polynomial derived from $f = g + \rho p$ is masked.

### Masking the Final Evaluation

The round polynomials are now hidden, but there is a remaining leak. At the end of sum-check, the prover must open $g(r_1, \ldots, r_n)$ at the random evaluation point (typically via a polynomial commitment). This final evaluation is a deterministic function of the witness and reveals information about it.

To handle this, the prover adds random terms that vanish on the Boolean hypercube but randomize evaluations outside it. Instead of committing to $g$ directly, the prover commits to a randomized version:

$$\hat{g}(X_1, \ldots, X_n) = g(X_1, \ldots, X_n) + \sum_{i=1}^n c_i \cdot X_i(1 - X_i)$$

where $c_1, \ldots, c_n$ are random field elements chosen by the prover and never revealed. Since $X_i(1 - X_i) = 0$ when $X_i \in \{0, 1\}$, we have $\hat{g}(b) = g(b)$ on the Boolean hypercube: correctness is preserved, and the sum $\sum_b g(b)$ is unchanged. But at a random point $z \notin \{0, 1\}^n$ (where the verifier queries after sum-check), the evaluation becomes $\hat{g}(z) = g(z) + \sum_i c_i \cdot z_i(1 - z_i)$. The verifier sees $\hat{g}(z)$ via the commitment opening but does not know the $c_i$, so it cannot recover $g(z)$.

**Worked example.** Let $g(X) = 3X$ (a single-variable polynomial encoding witness data). Randomize with $c = 7$:

$$\hat{g}(X) = 3X + 7 \cdot X(1 - X) = 10X - 7X^2$$

On the hypercube: $\hat{g}(0) = 0 = g(0)$ and $\hat{g}(1) = 3 = g(1)$. At a random point $z = 0.5$: $g(0.5) = 1.5$ (would leak), but $\hat{g}(0.5) = 3.25$ (masked). Different $c$ values produce different evaluations at $z$, hiding $g$.

For an $n$-variable polynomial, the $n$ random scalars $c_1, \ldots, c_n$ provide enough entropy: the verifier learns one evaluation $\hat{g}(z) = g(z) + \sum_i c_i z_i(1-z_i)$, which for uniform $c_i$ is uniformly distributed over $\mathbb{F}$ regardless of $g$. A simulator who does not know $g$ can produce identically distributed evaluations by choosing random $c_i$.

### The Simulator

Chapter 17 defined zero-knowledge via simulation: a proof system is ZK if an efficient simulator, given only the public statement, can produce transcripts indistinguishable from real executions. Chapter 17 also observed that vanilla sum-check fails this test: the round polynomials are deterministic functions of the witness, and no simulator can produce them without it. Masking repairs this. To close the loop, we construct the simulator explicitly and verify indistinguishability.

**Real protocol:**

1. Prover commits to random masking polynomial $p$
2. Verifier sends random $\rho$
3. Parties execute sum-check on $f = g + \rho p$
4. Prover opens $g(z)$ and $p(z)$ at random point $z$

**Simulator $\mathcal{S}$ (no access to the witness, and therefore no access to $g$):**

1. Commit to random polynomial $p$
2. Choose a random polynomial $q$ of the same degree as $g$
3. Execute sum-check on $f' = q + \rho p$
4. Open $q(z)$ and $p(z)$

The simulator replaces $g$ with a random $q$. The question is whether the verifier can tell the difference.

The verifier's view in both cases consists of: a commitment to $p$, sum-check round messages derived from $f$ or $f'$, the scalar $\rho$, and the final evaluations. The commitment to $p$ is a random group element in both cases (Pedersen hiding). The round messages are derived from $f = g + \rho p$ (real) or $f' = q + \rho p$ (simulated). Since $p$ is uniformly random and independent of $g$, and $\rho$ is chosen after $p$ is committed, the polynomial $\rho \cdot p$ is uniformly distributed among polynomials of its degree. Adding a uniform polynomial to any fixed $g$ produces a uniform result, just as adding a uniform field element to any fixed value produces a uniform field element. The distribution of $f$ depends only on the randomness in $p$ and $\rho$, not on $g$. The same holds for $f'$. The two distributions are identical.

For the final evaluation: the verifier learns $g(z)$ and $p(z)$ (real) or $q(z)$ and $p(z)$ (simulated). Since $q$ is uniformly random, $q(z)$ is uniform over $\mathbb{F}$. The masking of the final evaluation (via the $X_i(1-X_i)$ terms from the previous section) ensures that $g(z)$ is also uniformly distributed from the verifier's perspective. Both views are identically distributed, completing the simulation argument.

## Comparing the General Techniques

| Aspect | Commit-and-Prove | Masking Polynomials |
|--------|-----------------|---------------------|
| **Generality** | Works for any public-coin protocol | Specialized for polynomial protocols |
| **Overhead** | $O(M)$ $\Sigma$-protocols for $M$ multiplications | $O(1)$ additional commitments |
| **Succinctness** | Requires "proof on a proof" | Naturally preserves succinctness |
| **Post-quantum** | No (relies on discrete log) | Yes (with hash-based PCS) |
| **Complexity** | Conceptually straightforward | Requires algebraic design |

The cost difference reflects a difference in abstraction level. Commit-and-prove works on *scalars*: each field element gets its own commitment, and relations are proved one at a time. Masking polynomials works on *functions*: a single random polynomial masks all coefficients at once. Hiding $n$ scalars requires $n$ commitments; hiding an $n$-coefficient polynomial requires one random polynomial. The jump from scalar to function is what makes masking efficient for polynomial-based protocols.

Most production systems use masking for the main protocol body and commit-and-prove for auxiliary statements (range proofs, committed value equality, etc.).

A third approach, developed in the HyperNova paper (Kothapalli, Setty, Tzialla, 2023), sidesteps both techniques entirely. Instead of masking round polynomials or wrapping each check in a $\Sigma$-protocol, the prover replaces every sum-check message with a Pedersen commitment and then proves, via Nova folding, that the committed values satisfy the verifier's checks. The folding step acts as an algebraic one-time pad: the real witness is combined with a random satisfying instance, producing a folded witness that is uniformly distributed regardless of the original. The cost is roughly 3 KB of additional proof data and negligible prover overhead. This technique, called BlindFold, is what made production zkVMs (notably Jolt) genuinely zero-knowledge. Chapter 22 develops it in full after introducing the folding machinery it depends on.

## Zero-Knowledge in Practice

The general techniques above provide the conceptual foundation, but production systems do not apply them directly. Groth16 and PLONK each exploit their own algebraic structure to achieve zero-knowledge more efficiently. The underlying principle is the same (randomize what the verifier sees while preserving what the verifier checks), but the mechanisms are system-specific.

### Groth16

Recall from Chapter 12 that the prover constructs QAP polynomials $A(X), B(X), C(X)$ encoding the witness, evaluates them at the secret point $\tau$ from the structured reference string, and packages the results as three group elements $(\pi_A, \pi_B, \pi_C)$. The polynomials never leave the prover; the verifier sees only these group elements. Without additional randomization, however, the proof elements are deterministic functions of the witness: same witness, same proof. An observer comparing two proofs could detect whether they use the same witness.

Groth16 addresses this the same way Pedersen commitments hide a message: by adding randomness in the exponent. The prover samples fresh scalars $(r, s)$ and incorporates them into the proof elements, making $(\pi_A, \pi_B, \pi_C)$ uniformly distributed while preserving the pairing verification equation.

#### The Blinding Mechanism

Concretely, the prover samples $r, s \in \mathbb{F}$ and incorporates them:

$$\pi_A = g_1^{\alpha + A(\tau) + r\delta}$$
$$\pi_B = g_2^{\beta + B(\tau) + s\delta}$$

The $r\delta$ and $s\delta$ terms add randomness. But where do they go? They'd break the verification equation unless compensated. The construction of $\pi_C$ absorbs them:

$$\pi_C = g_1^{\frac{\text{private terms}}{\delta} + \frac{H(\tau)Z_H(\tau)}{\delta} + s(\alpha + A(\tau) + r\delta) + r(\beta + B(\tau)) - rs\delta}$$

The terms $sA(\tau)$, $s\alpha$, $rB(\tau)$, $r\beta$, and $rs\delta$ in $\pi_C$ exactly cancel the cross-terms that appear when expanding $e(\pi_A, \pi_B)$.

#### Why This Works

The verification equation checks:
$$e(\pi_A, \pi_B) = e(g_1^\alpha, g_2^\beta) \cdot e(\text{vk}_x, g_2^\gamma) \cdot e(\pi_C, g_2^\delta)$$

Expanding $e(\pi_A, \pi_B)$ with blinding:
$$e(g_1^{\alpha + A(\tau) + r\delta}, g_2^{\beta + B(\tau) + s\delta})$$

The exponent becomes $(\alpha + A + r\delta)(\beta + B + s\delta)$, which expands to include cross-terms: $\alpha s\delta$, $A s\delta$, $r\beta\delta$, $rB\delta$, $rs\delta^2$.

The $\pi_C$ construction is designed so that when paired with $g_2^\delta$, it produces exactly these cross-terms (plus the core QAP check). Everything cancels except the QAP identity $A(\tau)B(\tau) = C(\tau) + H(\tau)Z_H(\tau)$.

Different $(r, s)$ produce different valid proofs for the same witness, making proofs for distinct witnesses indistinguishable from proofs for the same witness with different randomness. Note that the blinding depends on $\delta$: the prover computes $g_1^{r\delta}$ as $(g_1^\delta)^r$ using the proving key, without knowing $\delta$ as a field element. The setup secret is required by the mechanism.



### PLONK

PLONK's approach is closer to masking polynomials than to Groth16's element-level randomization. Recall from Chapter 13 that PLONK encodes constraints as polynomial identities that must hold on a multiplicative subgroup $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$. The prover commits to witness polynomials $w(X)$ whose values on $H$ encode the wire assignments. After Fiat-Shamir, the verifier queries these polynomials at a random point $\zeta$ outside $H$ to check the constraints.

The separation between the constraint domain ($H$) and the query point ($\zeta \notin H$) is what PLONK exploits for zero-knowledge. Unlike Groth16, which randomizes proof elements, PLONK randomizes the polynomials themselves before committing: add a random multiple of the vanishing polynomial $Z_H(X) = X^n - 1$, which is zero on $H$. The committed polynomial agrees with the original where constraints are checked but is randomized where the verifier queries.

#### The Vanishing Polynomial Trick

Concretely, to blind a witness polynomial $w(X)$, add a random low-degree polynomial times $Z_H$:

$$\tilde{w}(X) = w(X) + (b_1 X + b_2) \cdot Z_H(X)$$

where $b_1, b_2$ are random field elements.

On the constraint-check domain:
$$\tilde{w}(\omega^i) = w(\omega^i) + (b_1 \omega^i + b_2) \cdot 0 = w(\omega^i)$$

Why a polynomial, not just a scalar? The verifier queries at a random point $\zeta$, receiving $\tilde{w}(\zeta)$. A single scalar $b$ would add the fixed value $b \cdot Z_H(\zeta)$, which might not provide enough entropy depending on what else the verifier learns. Using $(b_1 X + b_2)$ ensures sufficient randomness for simulation arguments.

#### Blinding the Accumulator

PLONK's permutation argument uses an accumulator polynomial $Z(X)$ that tracks whether wire values are correctly copied. This polynomial also reveals structure.

The accumulator is checked at two points: $\zeta$ and $\zeta\omega$ (the "shifted" evaluation). To mask both, use three random scalars:

$$\tilde{Z}(X) = Z(X) + (c_1 X^2 + c_2 X + c_3) \cdot Z_H(X)$$

The boundary condition $Z(1) = 1$ and the recursive multiplicative relation are preserved on $H$. Outside $H$, both $\tilde{Z}(\zeta)$ and $\tilde{Z}(\zeta\omega)$ are randomized.

The same blinding applies to every polynomial PLONK commits to, including the quotient polynomial $t(X)$ (which is split into pieces for degree reasons, each blinded independently).

### The Unifying Principle

Despite different mechanisms, Groth16 and PLONK follow the same pattern: find the *null space* of the verification procedure (transformations that don't affect the outcome) and inject randomness there. In Groth16, the null space is the set of $(r, s)$ shifts that cancel in the pairing. In PLONK, it is the space of $Z_H$ multiples that vanish on the constraint domain. This connects directly to the simulation paradigm from Chapter 17: the simulator can produce valid-looking transcripts because it can choose randomness within this null space.



## Key Takeaways

1. **Every ZK technique finds the null space of the verification procedure and injects randomness there.** Transformations that don't affect the verification outcome are the prover's freedom. Soundness constrains what the prover can do; zero-knowledge exploits what the prover is free to randomize.

2. **Commit-and-prove is general but expensive.** It works for any public-coin protocol by hiding values behind Pedersen commitments and proving relations via $\Sigma$-protocols. Cost scales with multiplication count ($O(M)$), but the "proof on a proof" trick recovers succinctness by applying commit-and-prove to the $O(\log n)$ verifier circuit instead of the original computation.

3. **Masking polynomials are efficient but specialized.** For polynomial-sending protocols like sum-check, adding $\rho \cdot p(X)$ (a committed random polynomial scaled by a verifier challenge) acts as a one-time pad. Succinctness is preserved naturally. Final evaluations require separate treatment via terms like $\sum_i c_i X_i(1-X_i)$ that vanish on the Boolean hypercube.

4. **Production systems tailor the null space to their algebraic structure.**
   - *Groth16*: fresh scalars $(r, s)$ shift the proof elements; $\pi_C$ absorbs the cross-terms so the pairing equation is unchanged.
   - *PLONK*: random multiples of $Z_H(X)$ vanish on the constraint domain $H$ but randomize evaluations at the query point $\zeta \notin H$.

5. **Production systems blend approaches.** Masking handles the core polynomial protocol. Commit-and-prove handles auxiliary statements (range proofs, committed value equality). BlindFold (Chapter 22) offers a third path via folding.

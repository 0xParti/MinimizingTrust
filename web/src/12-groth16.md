# Chapter 12: Groth16: The Pairing-Based Optimal

In 2016, when Zcash was preparing to launch, they faced a practical problem. Blockchain transactions are expensive. Every byte costs money. The existing SNARKs (Pinocchio and its descendants) required proofs of nearly 300 bytes. It was workable, but clunky.

Then Jens Groth published a paper that seemed to violate the laws of physics. He shaved the proof down to 128 bytes on BN254. To demonstrate just how small this was, developers realized they could fit an entire zero-knowledge proof, verifying a computation of millions of steps, into a single tweet:

`[Proof: 0x1a2b3c...] #Zcash`

This was not just optimization. It was the theoretical minimum. Groth proved mathematically that for pairing-based systems, you literally cannot get smaller than 3 group elements. He had found the floor.

The paper, "On the Size of Pairing-based Non-interactive Arguments," became the most deployed SNARK in history. When Zcash launched its Sapling upgrade in 2018, it used Groth16. When Tornado Cash and dozens of other privacy applications needed succinct proofs, they used Groth16. The answer to "what's the smallest possible proof?" turned out to be the answer the entire field needed.

---

The SNARKs we've studied follow a common pattern: construct an IOP, compile it with a polynomial commitment scheme, apply Fiat-Shamir. This modular approach yields flexible systems (swap the PCS, change the trust assumptions) but leaves efficiency on the table.

Groth16 takes a different path. Rather than instantiating a generic framework, it was designed from first principles to minimize proof size. The layers are fused: optimized as a unit rather than composed as modules. Chapter 8 introduced QAP as one approach to arithmetization; here we develop it fully.

This optimality comes with constraints. The trusted setup is circuit-specific: change a single gate and you need a new ceremony. The prover cannot be made faster than $O(n \log n)$ without giving up something else. Zero-knowledge requires careful blinding woven into the protocol's fabric rather than layered on top.



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

From Chapter 8, we have 5 constraints encoding the circuit: $v_1 = x \cdot x$, $v_2 = v_1 \cdot x$, $v_3 = v_2 + x$, $v_4 = v_3 + 5$, and output $= v_4$. This gives 7 witness positions. Let the evaluation points be $\{1, 2, 3, 4, 5\}$.

The witness is $Z = (1, 35, 3, 9, 27, 30, 35)$ representing $(1, \text{output}, x, x^2, x^3, x^3+x, x^3+x+5)$.

For the second column (corresponding to variable $x$), the column vector in $A$ is $(1, 0, 1, 0, 0)$, representing that $x$ appears in constraints 1 and 3. The basis polynomial $A_2(X)$ interpolates through points $(1, 1), (2, 0), (3, 1), (4, 0), (5, 0)$:

$$A_2(X) = 1 \cdot L_1(X) + 1 \cdot L_3(X)$$

where $L_i(X)$ is the $i$-th Lagrange basis polynomial (recall from Chapter 2: $L_i(X) = \prod_{j \neq i} \frac{X - j}{i - j}$, satisfying $L_i(i) = 1$ and $L_i(j) = 0$ for $j \neq i$).

Each basis polynomial $A_j(X)$, $B_j(X)$, $C_j(X)$ has degree at most $m - 1 = 4$. Once we compute all of them, the witness polynomials are:

$$A(X) = \sum_{j=0}^{6} Z_j \cdot A_j(X) = 1 \cdot A_0(X) + 35 \cdot A_1(X) + 3 \cdot A_2(X) + \cdots$$

and similarly for $B(X)$ and $C(X)$. Each witness polynomial has degree at most $m - 1 = 4$.

The polynomial $P(X) = A(X) \cdot B(X) - C(X)$ has degree at most $2(m-1) = 8$. Since the R1CS is satisfied, $P(X)$ vanishes at all five evaluation points $\{1, 2, 3, 4, 5\}$, so the vanishing polynomial $Z_H(X) = (X-1)(X-2)(X-3)(X-4)(X-5)$ divides $P(X)$. The quotient $H(X) = P(X) / Z_H(X)$ has degree $2(m-1) - m = m - 2 = 3$.

In practice, the prover computes $H(X)$ via polynomial division: evaluate $P(X)$ and $Z_H(X)$ at enough points, divide pointwise, then interpolate. FFT-based methods make this efficient.

## The Core Protocol Idea

Verifying the QAP identity directly requires evaluating polynomials of degree $O(m)$, far too expensive for succinctness. The Schwartz-Zippel approach suggests evaluating at a random point $\tau$: if $A(\tau) \cdot B(\tau) - C(\tau) = H(\tau) \cdot Z_H(\tau)$, then the identity holds with overwhelming probability.

But the witness polynomials encode the secret witness. We cannot simply send $A(\tau)$ to the verifier.

Groth16 solves this with three ideas working in concert:

1. **Homomorphic hiding**: Evaluate in the exponent. Send $g^{A(\tau)}$ instead of $A(\tau)$.

2. **Pairing verification**: Check multiplication via bilinear pairing. The equation $e(g^a, g^b) = e(g, g)^{ab}$ lets the verifier check multiplicative relations on hidden values.

3. **Structured randomness**: Embed the check into the trusted setup. The verifier never sees $\tau$; they receive encoded values that enable verification without knowing the secret.

### Linear PCPs: The Abstraction

Groth16 is best understood through the lens of **Linear PCPs**, introduced in Chapter 1. Recall: in a standard PCP, the verifier queries specific positions of a proof string. In a Linear PCP, the "proof" is a linear function $\pi: \mathbb{F}^k \to \mathbb{F}$, and the verifier can only ask for linear combinations $\pi(q) = \sum_i q_i \cdot \pi_i$ for chosen query vectors $q$.

This restriction enables a clever trick: if the queries are encrypted as $g^q$, the prover can compute $g^{\pi(q)}$ homomorphically—without ever learning $q$ itself.

Groth16's trusted setup embeds carefully chosen query vectors into group elements. The prover computes responses using only scalar multiplication: linear operations on the encrypted queries. The verifier checks a quadratic relation using a single pairing equation.

This is why the proof has exactly three elements. Verification is a single pairing equation of the form $e(A, B) = e(\cdot, \cdot) \cdot e(\cdot, \cdot)$. Pairings take one element from $\mathbb{G}_1$ and one from $\mathbb{G}_2$, so the proof needs elements in both source groups: two in $\mathbb{G}_1$ (conventionally called $A$ and $C$) and one in $\mathbb{G}_2$ (called $B$).

## The Trusted Setup

Groth16 requires a **Structured Reference String (SRS)** generated by a trusted ceremony. The ceremony has two phases with fundamentally different properties.

### Phase 1: Powers of Tau (Universal)

A secret random value $\tau \in \mathbb{F}^*$ is chosen. The ceremony outputs encrypted powers:

$$\{g_1, g_1^{\tau}, g_1^{\tau^2}, \ldots, g_1^{\tau^{d}}\} \quad \text{and} \quad \{g_2, g_2^{\tau}, g_2^{\tau^2}, \ldots, g_2^{\tau^{d}}\}$$

where $d$ is large enough to support circuits up to a certain size.

This phase is **universal**: the same Powers of Tau can be used for any circuit within the size bound. Public ceremonies like "Perpetual Powers of Tau" provide reusable parameters. The MPC ceremony structure (1-of-N trust model, chained contributions) was covered in Chapter 9.

### Phase 2: Circuit-Specific Secrets

Phase 2 generates additional secrets $\alpha, \beta, \gamma, \delta \in \mathbb{F}^*$ that are specific to the circuit being proven. Their roles will become clear when we see the verification equation; for now, here's the intuition:

**$\alpha$ and $\beta$ (Cross-term cancellation)**: When the prover constructs their proof elements, the verification equation produces "cross-terms" like $\alpha \cdot B(\tau)$. The $\alpha, \beta$ blinding ensures these terms cancel correctly without revealing the witness.

**$\gamma$ (Public input binding)**: Separates public from private inputs in the verification equation. The verifier computes a commitment to the public inputs and checks it against the $\gamma$-scaled portion of the SRS.

**$\delta$ (Private witness binding)**: Forces the prover to use consistent values across the $A$, $B$, and $C$ polynomials. Without $\delta$, the prover could use different witnesses for different polynomials (a completeness attack).

### Why Phase 2 Cannot Be Universal

The Phase 2 parameters are not generic encrypted powers; they are **circuit-specific combinations** like:

$$g_1^{\frac{\beta \cdot A_j(\tau) + \alpha \cdot B_j(\tau) + C_j(\tau)}{\delta}}$$

These encode the basis polynomials $A_j, B_j, C_j$ directly. Change the circuit, change the basis polynomials, and these elements no longer make cryptographic sense.

At a deeper level, computing these elements requires knowing $\alpha, \beta, \gamma, \delta$ in the clear. After the ceremony, these secrets are destroyed. They cannot be recovered to compute new circuit-specific values.

This is Groth16's central tradeoff. The circuit-specific encoding enables the minimal proof size. It also mandates a new ceremony for every circuit.


## Protocol Specification

With setup complete, we specify the prover and verifier algorithms. We first present the **soundness core** without zero-knowledge, then show how randomization achieves privacy.

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

### Prover Algorithm (Soundness Core)

Given witness $Z = (1, \text{io}, W)$ where $\text{io}$ are public inputs and $W$ is the private witness:

1. **Compute witness polynomials**: Form $A(X), B(X), C(X)$ from the witness.

2. **Compute quotient**: Calculate $H(X) = \frac{A(X) \cdot B(X) - C(X)}{Z_H(X)}$.

3. **Construct proof elements** (without zero-knowledge):

$$\pi_A = g_1^{\alpha + A(\tau)}$$

$$\pi_B = g_2^{\beta + B(\tau)}$$

$$\pi_C = g_1^{\frac{\sum_{j \in \text{priv}} z_j (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau))}{\delta} + \frac{H(\tau) \cdot Z_H(\tau)}{\delta}}$$

The $\alpha, \beta$ terms enforce that the prover uses the *same* witness in $A$, $B$, and $C$. Without them, a cheating prover could use inconsistent values.

### Adding Zero-Knowledge

The soundness-only version above leaks information: given multiple proofs for related statements, an adversary might learn about the witness. To achieve zero-knowledge, the prover adds randomization.

**Sample fresh randomness**: $r, s \leftarrow \mathbb{F}$.

**Randomized proof elements**:

$$\pi_A = g_1^{\alpha + A(\tau) + r\delta}$$

$$\pi_B = g_2^{\beta + B(\tau) + s\delta}$$

$$\pi_C = g_1^{\frac{\sum_{j \in \text{priv}} z_j (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau))}{\delta} + \frac{H(\tau) \cdot Z_H(\tau)}{\delta} + s(\alpha + A(\tau) + r\delta) + r(\beta + B(\tau) + s\delta) - rs\delta}$$

The formula looks arbitrary, but it follows from a constraint: the verification equation must still hold. We need $e(\pi_A, \pi_B) = e(g_1^\alpha, g_2^\beta) \cdot e(\text{vk}_x, g_2^\gamma) \cdot e(\pi_C, g_2^\delta)$.

With blinding, $e(\pi_A, \pi_B)$ expands to (in exponent form):

$$(\alpha + A(\tau) + r\delta)(\beta + B(\tau) + s\delta)$$

This contains new cross-terms: $\alpha s\delta$, $r\beta\delta$, $A(\tau)s\delta$, $rB(\tau)\delta$, and $rs\delta^2$. These don't appear in the soundness-only version.

The term $e(\pi_C, g_2^\delta)$ contributes $\delta \cdot (\text{exponent of } \pi_C)$ to the equation. So $\pi_C$ must contain terms that, when multiplied by $\delta$, cancel the unwanted cross-terms. Working backwards:

- To cancel $\alpha s \delta$: include $s\alpha$ in $\pi_C$'s exponent (becomes $s\alpha\delta$ after multiplying by $\delta$)
- To cancel $A(\tau)s\delta$: include $sA(\tau)$
- To cancel $r\beta\delta$: include $r\beta$
- To cancel $rB(\tau)\delta$: include $rB(\tau)$
- To cancel $rs\delta^2$: include $rs\delta$

Grouping: $s(\alpha + A(\tau)) + r(\beta + B(\tau)) + rs\delta$. But $\pi_A$'s exponent is $\alpha + A(\tau) + r\delta$, so we can write $s(\alpha + A(\tau) + r\delta) + r(\beta + B(\tau) + s\delta) - rs\delta$. The $-rs\delta$ corrects for double-counting.

The formula is not arbitrary—it's the unique solution ensuring the blinding terms cancel while the QAP check remains intact.

The prover outputs $\pi = (\pi_A, \pi_B, \pi_C) \in \mathbb{G}_1 \times \mathbb{G}_2 \times \mathbb{G}_1$.

### Proof Size

On the BN254 curve:

- $\pi_A \in \mathbb{G}_1$: 32 bytes (compressed)
- $\pi_B \in \mathbb{G}_2$: 64 bytes (compressed)
- $\pi_C \in \mathbb{G}_1$: 32 bytes (compressed)

**Total: 128 bytes.**

This is the smallest proof size achieved by any pairing-based SNARK. The paper proves a lower bound: any SNARK in this model requires at least two group elements. Groth16's three elements are close to optimal.

### Verifier Algorithm

The verification equation is identical for both versions—the verifier doesn't know (or care) whether zero-knowledge randomization was used. The $r, s$ terms cancel algebraically.

Given public inputs $\text{io} = (z_0, z_1, \ldots, z_\ell)$ where $z_0 = 1$:

1. **Compute public input combination**:
   $$\text{vk}_x = \sum_{j=0}^{\ell} z_j \cdot (\text{vk}_{IC})_j$$
   where $(\text{vk}_{IC})_j = g_1^{\frac{\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)}{\gamma}}$

2. **Check pairing equation**:
   $$e(\pi_A, \pi_B) \stackrel{?}{=} e(g_1^{\alpha}, g_2^{\beta}) \cdot e(\text{vk}_x, g_2^{\gamma}) \cdot e(\pi_C, g_2^{\delta})$$

The verifier accepts if the equation holds, rejects otherwise. Note that only $\pi_A$, $\pi_B$, $\pi_C$ come from the proof; the elements $g_1^{\alpha}$, $g_2^{\beta}$, $g_2^{\gamma}$, $g_2^{\delta}$ are part of the verification key (fixed per circuit).

### Verification Cost

The verification requires:

- One multi-scalar multiplication in $\mathbb{G}_1$ (size proportional to public input count)
- Four pairing computations (or three pairings after rearrangement)

Pairings are expensive: roughly 2-3ms each on modern hardware. But the cost is independent of circuit size. A circuit with a million constraints verifies as fast as one with a hundred.

## Why the Verification Equation Works

We first verify the soundness-only version (without $r, s$), then show how the zero-knowledge terms cancel.

### The Core Check (Without Zero-Knowledge)

With the simplified proof elements $\pi_A = g_1^{\alpha + A(\tau)}$, $\pi_B = g_2^{\beta + B(\tau)}$:

$$e(\pi_A, \pi_B) = e(g_1^{\alpha + A(\tau)}, g_2^{\beta + B(\tau)})$$

Using bilinearity, the exponent in $\mathbb{G}_T$ is:

$$(\alpha + A(\tau))(\beta + B(\tau)) = \alpha\beta + \alpha B(\tau) + \beta A(\tau) + A(\tau)B(\tau)$$

On the right-hand side:

**Term 1**: $e(g_1^{\alpha}, g_2^{\beta})$ contributes exponent $\alpha\beta$.

**Term 2**: $e(\text{vk}_x, g_2^{\gamma})$ contributes:

$$\sum_{j \in \text{public}} z_j \cdot (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau))$$

after the $\gamma$ cancels.

**Term 3**: $e(\pi_C, g_2^{\delta})$ contributes the private witness consistency check plus the quotient:

$$\sum_{j \in \text{private}} z_j \cdot (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)) + H(\tau) \cdot Z_H(\tau)$$

after the $\delta$ cancels.

Combining public and private terms:

$$\sum_{\text{all } j} z_j \cdot (\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)) = \beta A(\tau) + \alpha B(\tau) + C(\tau)$$

The RHS exponent is: $\alpha\beta + \beta A(\tau) + \alpha B(\tau) + C(\tau) + H(\tau)Z_H(\tau)$

Setting LHS = RHS and canceling matching terms:

- $\alpha\beta$ cancels
- $\alpha B(\tau)$ cancels
- $\beta A(\tau)$ cancels

What remains:

$$A(\tau)B(\tau) = C(\tau) + H(\tau)Z_H(\tau)$$

This is exactly the QAP identity.

### The Full Check (With Zero-Knowledge)

With the full proof elements (including $r, s$):

$$e(\pi_A, \pi_B) = e(g_1^{\alpha + A(\tau) + r\delta}, g_2^{\beta + B(\tau) + s\delta})$$

Using bilinearity, the exponent in $\mathbb{G}_T$ is:

$$(\alpha + A(\tau) + r\delta)(\beta + B(\tau) + s\delta)$$

Expanding:

$$= \alpha\beta + \alpha B(\tau) + \alpha s\delta + \beta A(\tau) + A(\tau)B(\tau) + A(\tau)s\delta + r\beta\delta + r B(\tau)\delta + rs\delta^2$$

This contains the desired term $A(\tau)B(\tau)$ mixed with cross-terms involving the randomness $r, s$.

**Term 3 now contributes additional terms**: $e(\pi_C, g_2^{\delta})$ includes (after the $\delta$ cancels):

$$H(\tau) \cdot Z_H(\tau) + s\alpha\delta + sA(\tau)\delta + r\beta\delta + rB(\tau)\delta + rs\delta^2$$

The RHS exponent becomes:

$$\alpha\beta + \beta A(\tau) + \alpha B(\tau) + C(\tau) + H(\tau)Z_H(\tau) + \alpha s\delta + A(\tau)s\delta + \beta r\delta + B(\tau)r\delta + rs\delta^2$$

Setting LHS = RHS and canceling:

- $\alpha\beta$ cancels
- $\alpha B(\tau)$ cancels
- $\beta A(\tau)$ cancels
- All $r, s$ terms cancel: $\alpha s\delta$, $A(\tau)s\delta$, $r\beta\delta$, $rB(\tau)\delta$, $rs\delta^2$

What remains is unchanged:

$$A(\tau)B(\tau) = C(\tau) + H(\tau)Z_H(\tau)$$

The elaborate construction of $\pi_C$ provides exactly the terms needed to cancel the zero-knowledge blinding while preserving the soundness check.

### Soundness

If the QAP is not satisfied (i.e., $A(X)B(X) - C(X) \neq H(X)Z_H(X)$ as polynomials), then the difference $A(X)B(X) - C(X) - H(X)Z_H(X)$ is a non-zero polynomial. By Schwartz-Zippel, it vanishes at the random point $\tau$ with probability at most $\deg/|\mathbb{F}|$. Since $\tau$ is hidden in the SRS, a cheating prover cannot target it. Thus false proofs are rejected with overwhelming probability.

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

The SRS contains group elements encoding powers of $\tau$ and combinations involving $\alpha, \beta, \gamma, \delta$. The prover never sees these scalars directly—only their encrypted forms. To produce a valid proof, the prover must construct group elements satisfying the verification equation.

The security argument asks: what group elements can a prover actually compute? They can only form linear combinations of SRS elements (scalar multiplication and addition). The proof shows that any linear combination satisfying the verification equation must encode a valid QAP solution. There's no way to "forge" the right algebraic structure without knowing a witness, because the prover can't extract $\tau$ from $g^\tau$ or construct arbitrary polynomials evaluated at $\tau$.

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

Production deployments run MPC ceremonies with many participants. Each participant raises the current parameters to a fresh random power, then destroys their secret; the mechanism was covered in Chapter 9. The 1-of-N trust model applies: security holds if *any single participant* destroyed their contribution.

Groth16's Phase 2 requires the same ceremony structure but with circuit-specific parameters. Each circuit needs its own Phase 2, coordinated among willing participants.

### Phase 2 Complexity

Phase 1 (Powers of Tau) is performed once per maximum circuit size and reused indefinitely.

Phase 2 requires:

- Computing circuit-specific elements for every wire
- MPC ceremony among willing participants
- Verification that each contribution was correct

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

## Key Takeaways

1. **Optimal proof size.** Three group elements (128 bytes on BN254). Groth proved this is the theoretical minimum for pairing-based SNARKs.

2. **QAP compresses constraints.** R1CS's $m$ constraint checks become one polynomial divisibility condition: $A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$. Lagrange interpolation encodes constraint participation into basis polynomials.

3. **Pairings check multiplication on hidden values.** The verification equation $e(\pi_A, \pi_B) = \ldots$ checks that $A(\tau) \cdot B(\tau) = C(\tau) + H(\tau)Z_H(\tau)$ without revealing $\tau$ or the witness polynomials. Bilinearity is the mechanism.

4. **The prover is algebraically constrained.** The SRS contains group elements encoding $\tau^i$, $\alpha$, $\beta$, $\gamma$, $\delta$ in specific combinations. The prover can only form linear combinations of these. Any proof satisfying the verification equation must encode a valid QAP solution—there's no way to "forge" the algebraic structure.

5. **Circuit-specific setup.** Phase 1 (powers of tau) is universal. Phase 2 embeds the circuit's basis polynomials $A_j(\tau), B_j(\tau), C_j(\tau)$ into the SRS. Change one gate, redo Phase 2.

6. **1-of-N trust.** If any ceremony participant destroys their toxic waste, the setup is secure. This makes the trust assumption practical despite requiring a trusted setup.

7. **Zero-knowledge by algebraic design.** The blinding terms in $\pi_C$ are not arbitrary—they're the unique values ensuring the $r\delta$, $s\delta$ masks cancel in the verification equation. The protocol's ZK property is woven into its algebraic structure.

8. **Generic group model.** Security relies on assuming adversaries cannot exploit the curve's number-theoretic structure. Stronger than standard assumptions, but no practical attacks are known.

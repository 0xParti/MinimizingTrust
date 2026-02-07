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

**Formal soundness preservation**: Suppose the prover claims $\sum_b g(b) = H'$ but the true sum is $H \neq H'$. After masking, the verifier checks whether $\sum_b f(b) = H' + \rho P$. But $\sum_b f(b) = \sum_b g(b) + \rho P = H + \rho P$. For the check to pass, we'd need $H + \rho P = H' + \rho P$, which implies $H = H'$. Contradiction. The masking is a *soundness-preserving transformation*: it changes the representation but not the truth value of what's being verified.

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

**Counting the randomness**: For an $n$-variable multilinear polynomial, we add $n$ random scalars $c_1, \ldots, c_n$. The verifier learns one evaluation $\tilde{W}(z) = W(z) + \sum_i c_i z_i(1-z_i)$ at random $z$. Since each $z_i(1-z_i) \neq 0$ for random $z_i \notin \{0,1\}$, this is a random affine function of the $c_i$ values. The key observation: for uniform random $c_i$ and any fixed $W$, the distribution of $\tilde{W}(z)$ is identical (uniform over $\mathbb{F}$). A simulator who doesn't know $W$ can produce identically distributed evaluations by choosing random $c_i$. This is how zero-knowledge is achieved.

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

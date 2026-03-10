# Chapter 15: STARKs

While Gabizon and Williamson were building PLONK, a parallel revolution was underway.

Eli Ben-Sasson had been working on probabilistically checkable proofs (PCPs) since the early 2000s: the discovery that any proof can be encoded so a verifier need only spot-check a few random bits to detect errors. PCPs transformed complexity theory but remained practically useless. The constructions were galactic.

All the pairing-based SNARKs we've seen (Groth16, PLONK) require trusted setup. Ben-Sasson asked a different question: could you build proof systems using *nothing but hash functions*?

In 2018, Ben-Sasson and colleagues (Bentov, Horesh, Riabzev) published the **STARK** (Scalable Transparent ARgument of Knowledge) construction: transparent (no trusted setup), post-quantum (no pairings), with security based only on collision-resistant hashing. The theoretical ingredients, Interactive Oracle Proofs (IOPs), the FRI protocol (see Chapter 10), the ALI protocol (Algebraic Linking IOP), had been developed over the preceding years, often by the same researchers. The 2018 paper synthesized them into a complete, practical system.

STARKs have since become one of the two dominant proof system families, with independent implementations by StarkWare, Polygon, and RISC Zero. This chapter develops the STARK paradigm: how FRI combines with a state-machine model of computation to yield transparent, scalable, quantum-resistant proofs, at the cost of larger proof sizes than their pairing-based cousins.

---

## Why Not Pairings?

The most efficient SNARKs in Chapters 12-13 rely on pairing-based polynomial commitments. Groth16 builds pairings directly into its verification equation. PLONK is a polynomial IOP, agnostic to the commitment scheme, but achieves its smallest proofs when compiled with KZG, which requires pairings. The bilinear map $e: \mathbb{G}_1 \times \mathbb{G}_2 \to \mathbb{G}_T$ is what enables constant-size proofs and $O(1)$ verification.

This foundation is remarkably productive. But it carries costs that grow heavier with scrutiny.

**The first cost is trust.** A KZG commitment scheme requires a structured reference string: powers of a secret $\tau$ encoded in the group. Someone generated that $\tau$. If they kept it, they can forge proofs. The elaborate ceremonies of Chapter 12 (the multi-party computations, the public randomness beacons, the trusted participants) exist to distribute this trust. But distributed trust is still trust. The ceremony could fail. Participants could collude. The procedures could contain subtle flaws discovered years later.

**The second cost is quantum vulnerability.** Shor's algorithm solves discrete logarithms in polynomial time on a quantum computer. The security of KZG, Groth16, and IPA all rest on the hardness of discrete log in elliptic curve groups. Pairings add structure on top of this assumption but don't change the underlying vulnerability. When a sufficiently large quantum computer exists, all these schemes break. When that day comes is uncertain. That it will come seems increasingly likely. A proof verified today may need to remain trusted for decades.

**The third cost is field rigidity.** Only a small family of elliptic curves support efficient pairings while remaining cryptographically secure, and each curve dictates a specific large prime field (e.g., the 254-bit field of BN254, the 381-bit field of BLS12-381). Pairing-based proof systems are locked into these fields, ruling out optimizations over smaller or differently structured fields where arithmetic is dramatically cheaper.

STARKs abandon elliptic curves entirely. They ask a more primitive question: *what can we prove using only hash functions?*



## The Hash Function Gambit

A collision-resistant hash function is perhaps the most conservative cryptographic assumption we have. SHA-256, Blake3, Keccak: these primitives are analyzed relentlessly, deployed universally, and trusted implicitly. They offer no algebraic structure, no homomorphisms, no elegant equations. Just a box that takes input and produces output, where finding two inputs with the same output is computationally infeasible.

The quantum story here is fundamentally different from discrete log. Grover's algorithm provides a quadratic speedup for unstructured search, reducing the security of a 256-bit hash from $2^{256}$ to $2^{128}$ operations. This is manageable: use a larger hash output and security is restored. Contrast this with Shor's exponential speedup against discrete log, which breaks the problem entirely rather than merely weakening it.

This seems like a step backward. Algebraic structure is what made polynomial commitments possible. KZG works because $g^{p(\tau)}$ preserves polynomial relationships, because the commitment scheme respects the algebra of the underlying object. A hash function respects nothing. $H(a + b) \neq H(a) + H(b)$. The hash of a polynomial evaluation tells you nothing about the polynomial.

Yet hash functions offer something pairings cannot: a Merkle tree. Chapter 10 developed this machinery in detail; here we summarize the key ideas before showing how STARKs compose them into a complete proof system.

Commit to a sequence of values by hashing them into a binary tree. The root is the commitment. To open any leaf, provide the authentication path, the $O(\log n)$ hashes connecting that leaf to the root. The binding property is information-theoretic within the random oracle model: changing any leaf changes the root. No trapdoors, no toxic waste, no ceremonies.

The problem is that a Merkle commitment is simultaneously too strong and too weak. It's too strong in that opening a single position already costs $O(\log n)$ hash values, compared to $O(1)$ for KZG. And it's too weak in that there's no way to prove anything *about* the committed values without opening them. A KZG commitment to a polynomial $p$ lets you prove $p(z) = v$ at any point with a single group element. A Merkle commitment to evaluations of $p$ on a domain lets you prove $p(z) = v$ only if $z$ happens to be in the domain, and only by opening that leaf explicitly.

The insight behind STARKs is that these limitations can be overcome by a shift in perspective. Instead of proving polynomial identities directly, we prove that a committed function is *close to* a low-degree polynomial. This is the domain of coding theory, not algebra. And coding theory has powerful tools for detecting errors through random sampling.

## The Reed-Solomon Lens

Every proof system we've seen reduces computation to polynomial constraints. The prover commits to polynomials; the verifier checks that these polynomials satisfy certain identities. In pairing-based systems (Groth16, PLONK), the commitment scheme itself enforces polynomial structure: KZG commitments can only represent polynomials, and pairing checks verify evaluations algebraically. Low-degree-ness is built into the commitment.

With Merkle trees, this is no longer free. A Merkle tree commits to arbitrary sequences of field elements, with no structural guarantee. The prover *claims* the committed values are evaluations of a low-degree polynomial, but nothing about the commitment prevents them from committing garbage.

The Reed-Solomon encoding (Chapter 2) solves this. The prover's polynomial has degree at most $k - 1$, determined by $k$ evaluations. But the prover evaluates it on a much larger domain of $n$ points, with $n \gg k$, and commits to all $n$ values. This serves two purposes. First, it creates something to check: any $k$ field elements are consistent with *some* degree-$(k-1)$ polynomial (by Lagrange interpolation), so a commitment to just $k$ values can never be invalid. But most sequences of $n$ values are *not* consistent with any low-degree polynomial, so cheating becomes detectable. Second, the verifier queries random points in the extended domain rather than the trace domain, so the actual computation data is never revealed.

The Reed-Solomon distance property quantifies the first point. If the committed values don't correspond to a degree-$(k-1)$ polynomial, they disagree with *every* such polynomial on at least $n - k + 1$ of the $n$ positions. A random query hits a disagreement with probability at least $\delta = 1 - (k-1)/n$, and $q$ independent queries miss all disagreements with probability at most $(1 - \delta)^q$. For a blowup factor $\rho = n/k = 8$ and $q = 45$ queries: $(1/8)^{45} < 2^{-135}$. A random sample suffices.

The **FRI protocol** (Chapter 10) turns this sampling argument into a complete interactive low-degree test, replacing the structural guarantee that KZG provides for free.

So STARKs have a way to commit to polynomials (Merkle trees) and a way to verify they're low-degree (FRI). But FRI only proves a degree bound: the committed function is close to *some* low-degree polynomial. We still need to prove it's the *right* polynomial, one that encodes a valid computation. That requires a way to express computation as polynomial constraints.



## Computation as State Evolution

How should we encode computation into polynomials for this framework? The proof systems of previous chapters use circuits: directed acyclic graphs where wires carry values and gates impose constraints. This works, but it handles iteration awkwardly. A loop executing $n$ times becomes $n$ copies of the loop body, each a separate subcircuit. The repetition that made the loop simple to write is obscured in the flattened graph.

STARKs adopt a different model: the **state machine**.

A computation is a sequence of states $S_0, S_1, \ldots, S_{T-1}$ evolving over discrete time. Each state is a tuple of register values. A transition function $f$ maps $S_i$ to $S_{i+1}$, and $f$ is the same at every timestep. Only the register values change.

This uniformity is what makes the model efficient. A hash function running for $n$ rounds, a CPU executing $n$ instructions: both are $n$ applications of the same transition function. In a circuit, each iteration contributes its own gates and constraints, scaling linearly with $n$. In a state machine, the transition constraints describe a single step and apply identically at every timestep. The description has fixed size, independent of $n$.

Suppose we want to prove we computed $3^8 = 6561$. The state machine has two registers: a counter $c$ and an accumulator $a$. The transition rule: $c' = c + 1$ and $a' = a \cdot 3$. The trace:

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

This table is a *trace*: a matrix with $w = 2$ registers and $T = 9$ rows. The "Step" column is just a label; the actual data is the $c$ and $a$ columns. Each row captures the complete state at one moment; each column tracks one register's evolution through time.

The transition constraint ("next accumulator equals current accumulator times 3") is the same at every row. We don't need 8 separate multiplication gates; we need one constraint that holds 8 times. The prover commits to the entire trace, then proves the constraint holds everywhere. For $3^{1000000}$, the constraint is still just one equation; only the trace grows longer.

## Algebraic Intermediate Representation

An **AIR** (Algebraic Intermediate Representation) encodes the trace and its transition constraints in polynomial form.

The trace is a matrix with $w$ columns (registers) and $T$ rows (timesteps). Each column, viewed as a sequence of $T$ field elements, becomes a polynomial via interpolation. Choose a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{T-1}\}$ where $\omega$ is a primitive $T$-th root of unity. The column polynomial $P_j(X)$ is the unique polynomial of degree less than $T$ satisfying $P_j(\omega^i) = \text{trace}[i][j]$.

In the $3^8$ trace, we have two registers: $c$ (the counter) and $a$ (the accumulator). These become two column polynomials:

- $P_c(X)$: the unique degree-8 polynomial passing through $(1, 0), (\omega, 1), (\omega^2, 2), \ldots, (\omega^8, 8)$
- $P_a(X)$: the unique degree-8 polynomial passing through $(1, 1), (\omega, 3), (\omega^2, 9), \ldots, (\omega^8, 6561)$

Since $P_j(\omega^i)$ is the value of register $j$ at step $i$, replacing $X$ with $\omega X$ shifts forward by one step: $P_j(\omega \cdot \omega^i) = P_j(\omega^{i+1})$, which is step $i + 1$. This lets us express "next row" algebraically. The transition constraint "next accumulator = current accumulator × 3" becomes $P_a(\omega X) = 3 \cdot P_a(X)$. At $X = \omega^2$, this says $P_a(\omega^3) = 3 \cdot P_a(\omega^2)$, i.e., $27 = 3 \cdot 9$. The single polynomial identity encodes all 8 transition checks at once.

Another example: if a different transition function requires that register $r_0$ at step $i+1$ equals $r_0^3 + r_1$ at step $i$, this becomes:

$$P_0(\omega X) = P_0(X)^3 + P_1(X)$$

This identity must hold for $X \in \{1, \omega, \ldots, \omega^{T-2}\}$, covering all $T - 1$ transitions. Define the constraint polynomial:

$$C(X) = P_0(\omega X) - P_0(X)^3 - P_1(X)$$

If the trace is valid, $C(X)$ vanishes on $H' = \{1, \omega, \ldots, \omega^{T-2}\}$. By the factor theorem, $C(X)$ is divisible by the vanishing polynomial $Z_{H'}(X) = \prod_{h \in H'}(X - h)$. The quotient:

$$Q(X) = \frac{C(X)}{Z_{H'}(X)}$$

is a polynomial of known degree. If $C(X)$ doesn't vanish on $H'$ (if the trace violates the transition constraint somewhere) then $Q(X)$ isn't a polynomial. It's a rational function with poles at the violation points.

> **Why Constraint Degree Matters**
>
> The degree of the constraint polynomial $C(X)$ directly impacts prover cost. If a transition constraint involves $P_0(X)^3$, that term has degree $3(T-1)$ (since $P_0$ has degree $T-1$). The composition polynomial inherits this: $\deg(\text{Comp}) \approx \deg(\text{constraint}) \times T$. The prover must commit to this polynomial over the LDE domain, and FRI must prove its degree bound.
>
> This creates a fundamental trade-off. Higher-degree constraints let you express more complex transitions in a single step, but they blow up the prover's work. A degree-8 constraint over a million-step trace produces a composition polynomial of degree ~8 million, requiring proportionally more commitment and FRI work. Most practical AIR systems keep constraint degree between 2 and 4, accepting more trace columns (more registers) to avoid high-degree terms. The art of AIR design is balancing expressiveness against this degree bottleneck.

Transition constraints enforce the rules at every step, but they say nothing about *which* computation we're proving. We also need **boundary constraints** to pin down the inputs and outputs. In our $3^8$ example:

- **Input**: $P_a(1) = 1$ (accumulator starts at 1)
- **Output**: $P_a(\omega^8) = 6561$ (accumulator ends at $3^8$)

Each becomes a divisibility check. If the input requires register 0 to equal 5 at step 0, the constraint $P_0(1) = 5$ becomes $P_0(X) - 5$ vanishing at $X = 1$, quotient $(P_0(X) - 5)/(X - 1)$.

We now have multiple constraint quotients: $Q_{\text{trans}}$ for the transition, $Q_{\text{in}}$ and $Q_{\text{out}}$ for boundaries, possibly more. Rather than prove each separately, we batch them into a single polynomial using random challenges $\alpha_1, \alpha_2, \ldots$ (derived via Fiat-Shamir):

$$\text{Comp}(X) = \alpha_1 Q_{\text{trans}}(X) + \alpha_2 Q_{\text{in}}(X) + \alpha_3 Q_{\text{out}}(X) + \ldots$$

Why does this work? If all quotients are polynomials, their linear combination is a polynomial. If any quotient has a pole (from a violated constraint), the random combination almost certainly preserves that pole: the $\alpha_i$ values would need to be precisely chosen to cancel it, which happens with negligible probability over a large field.

Putting it together for our $3^8$ example, the three quotients are:

1. **Transition**: $Q_{\text{trans}}(X) = C(X) / Z_{H'}(X)$ is a polynomial (each step follows the rules)
2. **Input boundary**: $(P_a(1) - 1)/(X - 1)$ is a polynomial (accumulator starts at 1)
3. **Output boundary**: $(P_a(\omega^8) - 6561)/(X - \omega^8)$ is a polynomial (accumulator ends at 6561)

If any constraint fails, the corresponding quotient has a pole, the composition polynomial inherits it, and FRI rejects it as non-low-degree.

To make this concrete: the trace polynomials $P_j(X)$ have degree at most $T - 1$, since the trace domain $H = \{1, \omega, \ldots, \omega^{T-1}\}$ has $T$ points (9 in our $3^8$ example). The prover evaluates them not on $H$ alone, but on a larger domain $D \supset H$, typically 4 to 16 times larger. This is the **low-degree extension (LDE)**. As we saw in the Reed-Solomon section, this redundancy is what makes cheating detectable: FRI's random queries in $D$ catch the non-low-degree composition polynomial. The prover commits to these LDE evaluations via Merkle tree, with the root as the commitment.



## The Complete Protocol

**Prover's Algorithm:**

1. Execute the computation, producing the execution trace.

2. Interpolate each trace column to obtain polynomials $P_1(X), \ldots, P_w(X)$ over domain $H$.

3. Evaluate all $w$ polynomials on the LDE domain $D$, forming a $|D| \times w$ matrix. Commit this matrix in a single Merkle tree: each leaf is the hash of one row $(P_1(x), \ldots, P_w(x))$ for a domain point $x \in D$. Send the trace root to the verifier.

4. Derive random challenges $\alpha_1, \alpha_2, \ldots$ by hashing the transcript (Fiat-Shamir).

5. Compute constraint polynomials, form quotients, and batch them into the composition polynomial using the challenges from step 4.

6. Evaluate the composition polynomial on $D$. Commit via a second Merkle tree and send the composition root to the verifier.

7. Run FRI on the composition polynomial, proving it has degree less than the known bound.

8. Derive query points $x_1, \ldots, x_k$ by hashing the transcript (Fiat-Shamir). For each $x_i$: open the trace polynomials and composition polynomial, providing Merkle authentication paths.

Each query catches a cheater with probability roughly $1 - 1/\rho$, where $\rho$ is the blowup factor ($|D|/|H|$). With $k$ queries, soundness error is roughly $(1/\rho)^k$. For 128-bit security with blowup factor 8, around 45 queries suffice.

**Verifier's Algorithm:**

1. Receive the Merkle roots (trace and composition), FRI commitments, and query responses.

2. Derive all Fiat-Shamir challenges from the transcript.

3. Verify FRI: check that the committed function is close to a low-degree polynomial.

4. For each query point $x$:
   - The prover opens the trace Merkle tree at $x$, providing the row $(P_1(x), \ldots, P_w(x))$ and an authentication path. The verifier hashes the row and checks it against the trace root.
   - The prover also opens the composition Merkle tree at $x$, providing $\text{Comp}(x)$ and its authentication path. The verifier checks it against the composition root (which FRI proved corresponds to a low-degree polynomial).
   - The verifier plugs the trace values into the constraint equations, forms the quotients, applies the batching coefficients $\alpha_i$, and locally recomputes what $\text{Comp}(x)$ should be. If this doesn't match the opened composition value, reject.

5. Accept if all checks pass.

This last sub-step is the **AIR-FRI link**: it connects FRI (which only proves low-degree-ness, knowing nothing about constraints or computations) to the actual claim being verified. Without it, a cheating prover could commit to $\text{Comp}(X) = 0$, pass FRI trivially, and hope the verifier is satisfied.

Why is this sound? The prover committed to the trace *before* learning the query points (Fiat-Shamir). If the trace violates any constraint, the composition polynomial has poles and isn't low-degree; FRI catches this. If the trace is valid but the prover committed to a *different* composition polynomial, the opened value and the locally recomputed value disagree at most points (Schwartz-Zippel); the random queries catch this.

There is a subtle gap in standard FRI: the verifier only queries points in the LDE domain $D$, so a cheating prover could commit to a function that's low-degree on $D$ but encodes wrong trace values. **DEEP-FRI** (introduced in Chapter 10) closes this gap. The verifier samples a random point $z$ *outside* $D$ and requires the prover to open the trace polynomials there. Since honest trace polynomials are globally low-degree, they can be evaluated anywhere; a cheater who faked values only on $D$ cannot consistently answer at $z$. In the STARK context, this means the AIR-FRI link is checked at a point the prover could not have anticipated when constructing the trace commitment, which is why most STARK implementations use DEEP-FRI rather than standard FRI.



## A Concrete Example: Fibonacci

Let's trace the protocol on a minimal computation: proving knowledge of the 7th Fibonacci number.

The claim: starting from $F_0 = 1, F_1 = 1$, the sequence satisfies $F_6 = 13$. The trace has two registers $(a, b)$ representing consecutive Fibonacci numbers, with 6 rows (steps 0-5):

| Step | $a$ | $b$ |
|------|-----|-----|
| 0 | 1 | 1 |
| 1 | 1 | 2 |
| 2 | 2 | 3 |
| 3 | 3 | 5 |
| 4 | 5 | 8 |
| 5 | 8 | 13 |

The transition constraints enforce, at each step $i \in \{0, \ldots, 4\}$:

- $a_{i+1} = b_i$ (the next $a$ is the current $b$)
- $b_{i+1} = a_i + b_i$ (the next $b$ is the sum)

The boundary constraints pin down the endpoints:

- $a_0 = 1$ (initial condition)
- $b_0 = 1$ (initial condition)
- $b_5 = 13$ (the claimed output $F_6$)

Let $\omega$ be a primitive 6th root of unity. Interpolating the columns gives $A(X)$ with $A(\omega^i) = a_i$ and $B(X)$ with $B(\omega^i) = b_i$. Using the $\omega$-shift from the AIR section, the constraint polynomials are:

- $C_1(X) = A(\omega X) - B(X)$: next $a$ equals current $b$
- $C_2(X) = B(\omega X) - A(X) - B(X)$: next $b$ equals current $a + b$
- $C_{B1}(X) = A(X) - 1$, vanishing at $X = 1$
- $C_{B2}(X) = B(X) - 1$, vanishing at $X = 1$
- $C_{B3}(X) = B(X) - 13$, vanishing at $X = \omega^5$

Each constraint polynomial is divided by the appropriate vanishing polynomial. The transition constraints must hold at steps 0-4, so they're divided by $Z_5(X) = (X^6 - 1)/(X - \omega^5)$. Batching with random challenges $\alpha_1, \ldots, \alpha_5$:
$$\text{Comp}(X) = \alpha_1 \frac{C_1(X)}{Z_5(X)} + \alpha_2 \frac{C_2(X)}{Z_5(X)} + \alpha_3 \frac{C_{B1}(X)}{X-1} + \ldots$$

If the trace is valid (and it is) this composition is a polynomial of degree roughly $\deg(A) + \deg(B) - 5 \approx 5$.

Now the commitment step. The prover evaluates $A(X)$ and $B(X)$ on a larger LDE domain $D$ (say 48 points, with blowup factor 8). Each leaf of the trace Merkle tree holds the pair $(A(x), B(x))$ for one $x \in D$. The prover sends the trace root. After deriving the Fiat-Shamir challenges $\alpha_1, \ldots, \alpha_5$, the prover evaluates $\text{Comp}(X)$ on $D$, commits it in a second Merkle tree, and sends the composition root.

At query time, one detail this example reveals: to check $C_1(x) = A(\omega x) - B(x)$, the verifier needs trace values at both $x$ and $\omega x$. So queries come in *pairs*: the prover opens the trace Merkle tree at $x$ and $\omega x$ together, giving the verifier both the "current row" and "next row" values. The prover also opens the composition tree at $x$. The verifier recomputes $\text{Comp}(x)$ from the trace values and checks it matches the opened composition value.

FRI then proves the composition polynomial is low-degree via the folding protocol from Chapter 10. For our degree-5 polynomial over a 48-point LDE domain (blowup factor 8), three folding rounds reduce it to a constant. At each round, the verifier spot-checks that the folded layer is consistent with the previous one. The same query points serve both the AIR consistency check (opening trace values) and FRI verification (opening composition values at $y$ and $-y$ for folding), so one set of openings handles both.


## Adding Zero-Knowledge

The protocol as described so far is a transparent argument of knowledge, but it is not zero-knowledge. When the verifier queries a point $x \in D$ and the prover opens the trace Merkle tree, the verifier learns the actual values $P_1(x), \ldots, P_w(x)$. These are evaluations of the trace polynomials, and they leak information about the witness (the execution trace).

Chapter 18 covers the general theory of making proof systems zero-knowledge. Two broad techniques apply: commit-and-prove (hiding values behind homomorphic commitments) and polynomial masking (adding randomness that is invisible on the constraint domain but randomizes the verifier's queries). Here we focus on the approach specific to STARKs: **trace randomization**.

The idea is to extend the execution trace with random data before committing. The prover appends $k$ random rows to the trace (typically $k = 2$ to $4$), filled with random field elements, extending it from $T$ to $T + k$ rows. The trace polynomials are then interpolated over a domain of size $T + k$ rather than $T$.

Why does this help? The trace polynomials now encode both the real computation (on the first $T$ rows) and random noise (on the last $k$ rows). A low-degree polynomial is globally determined by its values, so the random rows "contaminate" evaluations everywhere outside the original domain $H$. More precisely, each trace polynomial has degree $T + k - 1$, determined by $T$ real values and $k$ random values. The $k$ random degrees of freedom make the polynomial's evaluations at any $k$ points outside $H$ statistically independent of the real trace. Since the verifier's queries land in $D \setminus H$, the opened values reveal nothing about the witness.

The constraint system requires only minor adjustments. The random rows do not satisfy the transition constraints, but they don't need to: $Z_{H'}(X)$ already vanishes only at $\{\omega^0, \ldots, \omega^{T-2}\}$, so the quotient $C(X) / Z_{H'}(X)$ remains a polynomial even though $C(X)$ is nonzero at the random row positions. Boundary constraints are unaffected since they pin specific rows within the original trace (e.g., $P_a(\omega^0) = 1$). The composition polynomial is formed as before but over the larger domain, and FRI proves the slightly larger degree bound $T + k - 1$.

Verification works directly on the blinded polynomials. The verifier never needs to see the actual trace values on $H$. At a query point $x \in D \setminus H$, the prover opens the blinded evaluations $P_1(x), \ldots, P_w(x)$, and the verifier recomputes $C(x) / Z_{H'}(x)$ from them, checking consistency with FRI. The quotient check confirms that some low-degree polynomial satisfies the constraints on $H$, which is all the verifier needs. The boundary constraints are verified through their own quotient terms in the composition polynomial.

A simulator that knows only the public inputs and outputs can produce identically distributed transcripts: it picks random trace polynomials consistent with the boundary constraints and simulates the protocol. The random rows provide enough freedom to match any set of query responses the real prover would produce. This technique is specific to the STARK setting because it exploits the separation between the trace domain $H$ and the query domain $D \setminus H$. Pairing-based systems use different masking strategies suited to their algebraic structure (see Chapter 18).


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

But the size gap has motivated clever engineering. Proof wrapping is a general composition technique where one proof system verifies the output of another, and any system can in principle be wrapped. STARKs benefit from this the most because their large proofs are precisely the problem wrapping solves. Concretely, a STARK proves the bulk of the computation (transparently, with the state machine model's natural fit for VMs), then a Groth16 proof attests "I verified a valid STARK proof." The Groth16 verification circuit is fixed-size and small. The on-chain cost is the cost of verifying Groth16, regardless of the original computation's size.

This hybrid architecture is deployed in production systems like StarkNet, zkSync, and Polygon zkEVM. The STARK itself remains fully transparent, relying only on hash functions. Pairings enter only through the Groth16 wrapper, which verifies a fixed, auditable circuit. Part of why STARKs dominate in these systems is AIR's natural fit for virtual machines: the transition constraints encode the VM's instruction set once, and the trace varies with the program while the constraints stay fixed. The circuit model would require a different circuit for each program, or "unrolling" the VM for a fixed number of steps. AIR handles arbitrary-length execution with fixed constraint complexity.


## Circle STARKs and Small-Field Proving

Throughout this chapter, we interpolated trace columns over a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{T-1}\}$ of roots of unity. This choice wasn't arbitrary: roots of unity enable the FFT, which is what makes interpolation and evaluation over $H$ efficient ($O(n \log n)$ rather than $O(n^2)$). But FFT requires a multiplicative subgroup of size $2^k$, which constrains the field: we need primes $p$ where $p - 1$ is divisible by a large power of 2. Fields like Goldilocks ($2^{64} - 2^{32} + 1$) and BabyBear ($2^{31} - 2^{27} + 1$) are carefully constructed to meet this requirement.

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

The Mersenne prime $M_{31} = 2^{31} - 1$ deserves special attention. Two properties converge to make it exceptionally efficient for STARKs.

The first is cheap arithmetic, a property of Mersenne primes themselves. For any product $a \cdot b < 2^{62}$, split the result into low and high 31-bit parts, $ab = \text{lo} + \text{hi} \cdot 2^{31}$. Since $2^{31} \equiv 1 \pmod{M_{31}}$, reduction is just $\text{lo} + \text{hi}$ plus a conditional subtraction. No division, no extended multiplication. Since elements range from $0$ to $2^{31} - 2$, each fits in a single 32-bit word, so CPUs handle them natively and SIMD instructions process 4-8 elements per cycle. Compare this to 64-bit Goldilocks (needs 64-bit multiplies, harder to vectorize) or 254-bit BN254 (requires multi-precision arithmetic, roughly 10x slower per operation). This fast arithmetic is a property of the prime, not the circle group. STARKs can exploit it because their security comes from hash functions, not from discrete log hardness over the field, so 31-bit elements provide enough room. Pairing-based systems like Groth16 and PLONK (with KZG) cannot: the pairing-friendly curve fixes the scalar field at ~254 bits, and no pairing-friendly curve exists over a 31-bit field. Sum-check based systems occupy a middle ground: sum-check itself is field-agnostic, but the PCS dictates the field. With KZG commitments, they inherit the same ~254-bit constraint. With hash-based commitments (Brakedown, Binius), they too can use small fields.

The second property is the circle group's order. Over M31, the multiplicative group has order $p - 1 = 2(2^{30} - 1)$, which is not a large power of 2, so traditional FFT-based STARKs cannot use M31 directly. But the circle group has order $p + 1 = 2^{31}$, a perfect power of 2, enabling FFT-like algorithms over the circle. Trace lengths of $2^{20}$ or $2^{25}$ divide evenly with no wasted bits.

These advantages compound. Implementations using M31 Circle STARKs, such as StarkWare's Stwo and Polygon's Plonky3, report order-of-magnitude speedups over provers using larger fields. The security model is unchanged: the circle structure is used for FFTs, not for cryptographic assumptions.

### The Trade-off

Circle STARKs require adapting the polynomial machinery:

- Polynomials are defined over the circle group, not a multiplicative subgroup
- FRI folding uses the circle structure
- Some constraint types require reformulation

The implementation complexity is higher. But for systems targeting maximum prover speed, particularly zkVMs where prover time dominates, Circle STARKs offer a path to significant performance improvements.

### The Broader Lesson

Circle STARKs exemplify a general principle: *match the algebraic structure to hardware capabilities*. Traditional STARKs chose fields for mathematical convenience (large primes with smooth multiplicative order). Circle STARKs choose fields for computational efficiency (Mersenne primes with fast reduction), then build the necessary mathematical structure (the circle group) around that choice. Binius (Chapter 25) pushes this further by working over binary tower fields, where addition is XOR and field elements match the computer's native data types. As proof systems mature, field choice increasingly reflects hardware realities rather than purely mathematical aesthetics.


## Key Takeaways

1. **STARKs eliminate trusted setup** by building on hash functions rather than pairings. Merkle trees provide binding commitments; FRI proves low-degree properties.

2. **Computation becomes a trace.** The state machine model represents computation as a matrix of register values over timesteps. Each column interpolates to a polynomial over a root-of-unity domain $H$, and uniform transition constraints relate consecutive rows via the $\omega X$ shift.

3. **The algebraic pipeline reduces all constraints to a single degree check.** Constraint satisfaction becomes polynomial divisibility (quotients), quotients batch into a composition polynomial via random weights, and FRI verifies the degree bound. Low-degree extension over $D \supset H$ ensures any violation spreads across most of $D$.

4. **The AIR-FRI link.** The verifier opens trace values at query points, locally recomputes the composition, and checks it matches the committed value. The same queries feed into FRI consistency checks: one query, two purposes.

5. **Trace randomization adds zero-knowledge.** Appending random rows before committing contaminates evaluations outside $H$, so queries in $D \setminus H$ reveal nothing about the witness. The existing constraint structure accommodates this with no changes to the vanishing polynomial.

6. **Circle STARKs unlock small-field proving.** By replacing multiplicative subgroups with the circle group, STARKs can use Mersenne primes like $M_{31}$, where 31-bit arithmetic and SIMD vectorization yield order-of-magnitude speedups. This is possible because STARK security depends on hash functions, not on field size.

7. **The STARK trade-off**: post-quantum security and transparency at the cost of larger proofs (tens of kilobytes versus hundreds of bytes). Hybrid architectures wrap STARKs in pairing-based proofs for on-chain verification.

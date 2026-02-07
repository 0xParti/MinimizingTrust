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

**The distance property.** How different is a corrupted codeword from valid ones? Dramatically. Two distinct degree-$(k-1)$ polynomials agree on at most $k-1$ points (their difference is a degree-$(k-1)$ polynomial with at most $k-1$ roots). So any two valid codewords differ in at least $n - k + 1$ positions.

*Proof*: Let $p \neq q$ both have degree $< k$. Then $p - q$ is nonzero with degree $< k$, so it has at most $k-1$ roots. Thus $p(x) = q(x)$ for at most $k-1$ values, meaning they differ on at least $n - (k-1) = n - k + 1$ points. $\square$

This is the **minimum distance** of the Reed-Solomon code: $d = n - k + 1$. Errors don't cluster; they spread across most of the codeword. Random sampling finds them.

**The connection to STARKs.** The prover commits to function evaluations via Merkle tree. They claim these evaluations correspond to a low-degree polynomial. If they're lying (if the committed function isn't actually low-degree) it disagrees with *every* low-degree polynomial on at least $n - k + 1$ points. Random queries find these disagreements with high probability.

**Soundness bound**: If the committed function disagrees with every degree-$(k-1)$ polynomial on at least $\delta n$ points (where $\delta = 1 - (k-1)/n$ is the relative distance), then a single random query hits a disagreement with probability $\geq \delta$. With $q$ independent queries, the probability of missing all disagreements is at most $(1-\delta)^q$. For a blowup factor $\rho = n/k$ (e.g., $\rho = 8$), we have $\delta \approx 1 - 1/\rho$, so $(1-\delta)^q \approx (1/\rho)^q$. With $\rho = 8$ and $q = 45$ queries: $(1/8)^{45} < 2^{-135}$.

This is the leverage STARKs exploit. The verifier doesn't need to check all $n$ evaluations. A random sample suffices.

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

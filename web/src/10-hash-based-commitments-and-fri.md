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

**Formal definition**: A function $f: D \to \mathbb{F}$ is $\delta$-close to degree $d$ if there exists a polynomial $p(X)$ of degree $\leq d$ such that $f$ and $p$ agree on at least $(1-\delta)|D|$ points. The distance $\Delta(f, d) = \min_{\deg p \leq d} |\{x : f(x) \neq p(x)\}|/|D|$ measures how far $f$ is from being low-degree.

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

```mermaid
flowchart TB
    subgraph round0["ROUND 0: deg(f₀) < d, domain D₀ (size n)"]
        R0A["f₀(X) = f₀,E(X²) + X · f₀,O(X²)"]
        R0B["even part"]
        R0C["odd part"]
        R0D["f₁(Y) = f₀,E(Y) + α₀ · f₀,O(Y)"]
        R0E["Prover commits via Merkle tree"]
        R0F["Verifier sends random α₀"]
        R0A --> R0B & R0C
        R0B & R0C --> R0D
        R0E --> R0F --> R0D
    end

    subgraph round1["ROUND 1: deg(f₁) < d/2, domain D₁ (size n/2)"]
        R1A["f₁(Y) = f₁,E(Y²) + Y · f₁,O(Y²)"]
        R1B["f₂(Z) = f₁,E(Z) + α₁ · f₁,O(Z)"]
        R1A --> R1B
    end

    subgraph dots["..."]
        DD["log(d) rounds total"]
    end

    subgraph final["FINAL: deg(f_k) < 1 = CONSTANT"]
        FF["f_k = c"]
        FG["Prover sends c directly"]
        FF --> FG
    end

    round0 --> round1 --> dots --> final

    subgraph shrink["SHRINKAGE"]
        SH1["Domain: n → n/2 → n/4 → ... → 1"]
        SH2["Degree: d → d/2 → d/4 → ... → 1"]
    end
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

*Why this works*: Since $f_0(X) = f_{0,E}(X^2) + X \cdot f_{0,O}(X^2)$, we have $f_0(x) = f_{0,E}(y) + x \cdot f_{0,O}(y)$ and $f_0(-x) = f_{0,E}(y) - x \cdot f_{0,O}(y)$ where $y = x^2$. Adding these gives $2f_{0,E}(y)$; subtracting gives $2x \cdot f_{0,O}(y)$. Solving recovers the even and odd parts.

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

# Chapter 5: Univariate Polynomials and Finite Fields

Gauss discovered the Fast Fourier Transform in 1805. He needed to predict the orbits of asteroids Pallas and Juno, so he wrote an algorithm that computed transforms in $O(n \log n)$ time instead of $O(n^2)$. He wrote it in Latin, in a notebook, and never published it. The algorithm waited 160 years for someone to notice.

Cooley and Tukey rediscovered it in 1965. They gave it a name. It became one of the most important algorithms in computing: MRI machines, audio compression, the entire edifice of digital signal processing. All of it built on mathematics that had been sitting, unread, in the papers of a man who died in 1855.

Why does the same algorithm keep appearing? Because the symmetries of roots of unity make it inevitable. Once you see the structure, the algorithm writes itself. Those symmetries now power zero-knowledge proofs.

This chapter develops the univariate polynomial paradigm: finite fields, roots of unity, and the techniques that make systems like Groth16, PLONK, and STARKs possible. Where Chapter 4 explored multilinear polynomials over the Boolean hypercube, here we explore a single variable of high degree over a very different domain.



## Finite Fields: The Algebraic Foundation

Zero-knowledge proofs live in finite fields. Not the real numbers, not the integers; finite fields, where arithmetic wraps around and every division is exact.

A finite field $\mathbb{F}_p$ consists of the integers $\{0, 1, 2, \ldots, p-1\}$ with arithmetic modulo a prime $p$. Addition and multiplication work as usual, then you take the remainder when dividing by $p$:

$$3 + 5 = 8 \equiv 1 \pmod 7$$
$$3 \times 5 = 15 \equiv 1 \pmod 7$$

The magic is in division. Every nonzero element has a multiplicative inverse: this is guaranteed because $p$ is prime. (More generally, finite fields exist for any prime power $p^k$, but prime fields $\mathbb{F}_p$ are the simplest case.) In $\mathbb{F}_7$, we have $3^{-1} = 5$ because $3 \times 5 = 15 \equiv 1$. You can divide by any nonzero element, and the result is exact (no fractions, no approximations).

This is why we call it a *field*. A *ring* (like the integers $\mathbb{Z}$) lets you add, subtract, and multiply. A *field* lets you also divide. The integers are not a field because $1/2$ isn't an integer. But in $\mathbb{F}_7$, division always works: $1/2 = 1 \cdot 2^{-1} = 1 \cdot 4 = 4$, since $2 \cdot 4 = 8 \equiv 1$.

The nonzero elements $\mathbb{F}_p^* = \{1, 2, \ldots, p-1\}$ form a **cyclic group** under multiplication. This is fundamental: there exists a **generator** $g$ such that every nonzero element is some power of $g$.

**Example in $\mathbb{F}_7$**: The element $3$ generates everything:

| Power | $3^k \mod 7$ |
|-------|--------------|
| $3^1$ | $3$ |
| $3^2$ | $2$ |
| $3^3$ | $6$ |
| $3^4$ | $4$ |
| $3^5$ | $5$ |
| $3^6$ | $1$ |

Every nonzero element appears exactly once. The powers cycle through all of $\mathbb{F}_7^*$ before returning to 1.

For cryptographic applications, we use primes of 256 bits or more. The field is vast, roughly $2^{256}$ elements, making exhaustive search impossible.



## Roots of Unity

Because $\mathbb{F}_p^*$ is cyclic of order $p-1$, it contains subgroups of every order dividing $p-1$. The most useful are the **roots of unity**.

An element $\omega \in \mathbb{F}_p$ is an **$n$-th root of unity** if $\omega^n = 1$. It's a **primitive** $n$-th root if additionally $\omega^k \neq 1$ for any $0 < k < n$: the smallest positive power that gives 1 is exactly $n$.

If $\omega$ is a primitive $n$-th root, the complete set of $n$-th roots is:

$$H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$$

This is a subgroup of order $n$. It's the evaluation domain that powers univariate-based SNARKs.

### Worked Example: Fourth Roots in $\mathbb{F}_{17}$

Take $p = 17$. The multiplicative group has order $16 = 2^4$. Since $4$ divides $16$, fourth roots of unity exist.

Is $\omega = 4$ a primitive fourth root?

$$4^1 = 4$$
$$4^2 = 16 \equiv -1 \pmod{17}$$
$$4^3 = 64 \equiv 13 \equiv -4 \pmod{17}$$
$$4^4 = 256 \equiv 1 \pmod{17}$$

Yes. The fourth roots of unity are:

$$H = \{1, 4, 16, 13\} = \{1, 4, -1, -4\}$$

Notice the structure: $4$ and $-4 = 13$ are negatives of each other, as are $1$ and $-1 = 16$. This is not a coincidence.



## The Symmetries

Roots of unity have two key symmetries that enable fast algorithms.

### Symmetry 1: Squaring Halves the Group

When $n$ is even:

$$\omega^{n/2} = -1$$

**Why is this true?** Start with the defining property: $\omega^n = 1$. Taking the square root of both sides: $(\omega^{n/2})^2 = 1$. So $\omega^{n/2}$ is a square root of 1. In any field, the square roots of 1 are exactly $1$ and $-1$. But $\omega^{n/2} \neq 1$ because $\omega$ is *primitive*: its first power to equal 1 is $\omega^n$, not $\omega^{n/2}$. Therefore $\omega^{n/2} = -1$.

This has a remarkable consequence. If you square every element of $H$:

$$(\omega^k)^2 = \omega^{2k}$$

The squares form the $(n/2)$-th roots of unity. And since $(\omega^{k + n/2})^2 = (\omega^k \cdot \omega^{n/2})^2 = (\omega^k)^2 \cdot 1 = (\omega^k)^2$, each square root of unity appears exactly twice.

**In $\mathbb{F}_{17}$**: Squaring the fourth roots $\{1, 4, 16, 13\}$:

$$1^2 = 1, \quad 4^2 = 16, \quad 16^2 = 1, \quad 13^2 = 16$$

The squares are $\{1, 16\}$: the square roots of unity, each appearing twice.

### Symmetry 2: Opposite Elements are Negatives

Elements half a cycle apart are negatives:

$$\omega^{k + n/2} = \omega^k \cdot \omega^{n/2} = -\omega^k$$

**In $\mathbb{F}_{17}$**:

- $\omega^0 = 1$ and $\omega^2 = 16 = -1$
- $\omega^1 = 4$ and $\omega^3 = 13 = -4$

These two symmetries, squaring halves the group and opposites are negatives, are the engine of the Fast Fourier Transform.

### The DFT Is Polynomial Evaluation

Here is one of those facts that seems almost too good to be true.

The Discrete Fourier Transform (DFT) is defined as a matrix-vector multiplication. Given a vector $(c_0, c_1, \ldots, c_{n-1})$, the DFT produces a new vector whose $k$-th entry is:

$$\sum_{j=0}^{n-1} c_j \cdot \omega^{jk}$$

where $\omega$ is a primitive $n$-th root of unity.

If you've seen the continuous Fourier transform, this is the same idea. The continuous version projects a function onto $e^{i\theta} = \cos\theta + i\sin\theta$ via integration, measuring how much of each frequency is present. Here, the integral becomes a sum, and the exponentials become $n$-th roots of unity: $\omega^k = e^{2\pi i k/n}$, equally spaced points on the unit circle. The projection interpretation is identical. You're decomposing a signal into frequency components; the discretization just replaces integration with summation.

Now look at polynomial evaluation. Given a polynomial $P(X) = c_0 + c_1 X + \cdots + c_{n-1} X^{n-1}$, evaluate it at $\omega^k$:

$$P(\omega^k) = \sum_{j=0}^{n-1} c_j \cdot (\omega^k)^j = \sum_{j=0}^{n-1} c_j \cdot \omega^{jk}$$

They are identical. The DFT of the coefficient vector *is* the evaluation vector at roots of unity. This is not a useful analogy or a computational trick. It is a mathematical identity.

The FFT, then, is not "like" converting between polynomial representations. It *is* converting between polynomial representations. Coefficient form and evaluation form are the two natural bases for the same vector space, and the DFT matrix is the change-of-basis matrix. The FFT is the fast algorithm for this change of basis, made possible by the recursive structure of roots of unity.

This is why the same algorithm appears in signal processing, image compression, and zero-knowledge proofs. They are not merely related applications; they are the same mathematical operation in different disguises.


## Two Representations of Polynomials

A polynomial of degree less than $n$ can be viewed in two ways.

**Coefficient form**: The polynomial is stored as its coefficients.

$$P(X) = c_0 + c_1 X + c_2 X^2 + \cdots + c_{n-1} X^{n-1}$$

**Evaluation form**: The polynomial is stored as its values at $n$ distinct points. Using the $n$-th roots of unity:

$$[P(1), P(\omega), P(\omega^2), \ldots, P(\omega^{n-1})]$$

These two forms carry exactly the same information. A polynomial of degree less than $n$ is uniquely determined by its values at any $n$ points (this is Lagrange interpolation). The coefficient form and evaluation form are just two different coordinate systems for the same object.

Why care about evaluation form? In zero-knowledge proofs, constraints are naturally expressed as evaluations. Gate $i$ must satisfy some relation; this becomes: the constraint polynomial $C(X)$ must equal zero at $\omega^i$. The evaluation form directly represents these constraints.

### Polynomial Evaluation as Inner Product

In Chapter 4, we saw that evaluating a multilinear polynomial is an inner product: $\tilde{f}(r) = \langle \vec{f}, \vec{L}(r) \rangle$. The same structure appears for univariate polynomials, in two forms.

In coefficient form:
$$P(z) = c_0 + c_1 z + c_2 z^2 + \cdots + c_{n-1} z^{n-1} = \langle \vec{c}, \vec{z} \rangle$$

where $\vec{c} = (c_0, c_1, \ldots, c_{n-1})$ is the coefficient vector and $\vec{z} = (1, z, z^2, \ldots, z^{n-1})$ is the "powers of $z$" vector.

In evaluation form, the same polynomial can be written via Lagrange interpolation:
$$P(z) = \sum_{i=0}^{n-1} P(\omega^i) \cdot L_i(z) = \langle \vec{P}, \vec{L}(z) \rangle$$

where $\vec{P} = (P(1), P(\omega), \ldots, P(\omega^{n-1}))$ is the evaluation vector and $\vec{L}(z)$ is the vector of Lagrange basis evaluations. Each $L_i(z) = \prod_{j \neq i} \frac{z - \omega^j}{\omega^i - \omega^j}$ is the unique degree-$(n-1)$ polynomial that equals 1 at $\omega^i$ and 0 at all other roots of unity (Chapter 2). We'll see a cleaner closed form for roots of unity later in this chapter.

Either way, polynomial evaluation is an inner product. Committing to a polynomial reduces to committing to a vector; proving an evaluation reduces to proving an inner product claim.

The difference from Chapter 4 is computational. For multilinear polynomials, the Lagrange basis factors beautifully:
$$L_w(r) = \prod_{i=1}^{n} \big(r_i \cdot w_i + (1 - r_i)(1 - w_i)\big)$$
Each term depends on one coordinate; the product of $n$ terms costs $O(n)$ per basis element. With $2^n$ basis elements, streaming through all of them takes $O(2^n)$ total.

For univariate polynomials, no such factorization exists. Each $L_i(z) = \prod_{j \neq i} \frac{z - \omega^j}{\omega^i - \omega^j}$ is a product of $n-1$ terms that all depend on the same variable $z$. Computing one basis element costs $O(n)$; computing all $n$ of them naively costs $O(n^2)$. The FFT is what rescues us.

We'll exploit the inner product connection extensively in Chapter 9.

**Two ways to commit**: This duality (coefficient form vs evaluation form) manifests directly in polynomial commitment schemes:

- **KZG** (Chapter 9) commits in coefficient form: $C = g^{f(\tau)} = \prod_i (g^{\tau^i})^{c_i}$. The commitment encodes "evaluate the coefficients at a secret point $\tau$."

- **FRI** (Chapter 10) commits in evaluation form: a Merkle tree over $[f(1), f(\omega), \ldots, f(\omega^{n-1})]$. The commitment is a hash of all the evaluations.

The FFT is what makes these equivalent: you can convert between representations in $O(n \log n)$ time. But the choice of representation affects everything: proof size, prover cost, setup requirements, and the algebraic tricks available for verification.



## The Fast Fourier Transform

Converting between coefficient and evaluation form naively takes $O(n^2)$ operations: you'd compute each of $n$ evaluations, each requiring $O(n)$ work.

The **Fast Fourier Transform (FFT)** does it in $O(n \log n)$. This speedup is essential; without it, the polynomials in modern proof systems would be computationally intractable.

The FFT exploits the symmetries of roots of unity through divide-and-conquer.

### The Core Idea

Split a polynomial into its even and odd terms:

$$P(X) = P_{\text{even}}(X^2) + X \cdot P_{\text{odd}}(X^2)$$

where:

- $P_{\text{even}}(Y) = c_0 + c_2 Y + c_4 Y^2 + \cdots$ (even-indexed coefficients)
- $P_{\text{odd}}(Y) = c_1 + c_3 Y + c_5 Y^2 + \cdots$ (odd-indexed coefficients)

Both have half the degree of $P$.

Now, when we square the $n$-th roots of unity, we get the $(n/2)$-th roots (each appearing twice). So to evaluate $P$ at all of $H$, we:

1. Recursively evaluate $P_{\text{even}}$ and $P_{\text{odd}}$ at the $(n/2)$-th roots
2. Combine the results

The combination uses the antisymmetry property:

$$P(\omega^k) = P_{\text{even}}(\omega^{2k}) + \omega^k \cdot P_{\text{odd}}(\omega^{2k})$$
$$P(\omega^{k + n/2}) = P_{\text{even}}(\omega^{2k}) - \omega^k \cdot P_{\text{odd}}(\omega^{2k})$$

Two evaluations of $P$ from one evaluation each of $P_{\text{even}}$ and $P_{\text{odd}}$: the same work computes both, with just an addition versus subtraction.

### Worked Example: 4-Point FFT

Evaluate $P(X) = 5 + 3X + X^2 + 2X^3$ at $H = \{1, 4, 16, 13\}$ in $\mathbb{F}_{17}$.

**Split**:

- $P_{\text{even}}(Y) = 5 + Y$ (coefficients $c_0 = 5$, $c_2 = 1$)
- $P_{\text{odd}}(Y) = 3 + 2Y$ (coefficients $c_1 = 3$, $c_3 = 2$)

**Evaluate on $\{1, 16\}$** (the square roots of unity):

| $Y$ | $P_{\text{even}}(Y) = 5 + Y$ | $P_{\text{odd}}(Y) = 3 + 2Y$ |
|-----|------------------------------|------------------------------|
| $1$ | $6$ | $5$ |
| $16$ | $21 \equiv 4$ | $35 \equiv 1$ |

**Combine** using $\omega^0 = 1$, $\omega^1 = 4$, $\omega^2 = 16$, $\omega^3 = 13$:

$$P(1) = P_{\text{even}}(1) + 1 \cdot P_{\text{odd}}(1) = 6 + 5 = 11$$
$$P(4) = P_{\text{even}}(16) + 4 \cdot P_{\text{odd}}(16) = 4 + 4 = 8$$
$$P(16) = P_{\text{even}}(1) - 1 \cdot P_{\text{odd}}(1) = 6 - 5 = 1$$
$$P(13) = P_{\text{even}}(16) - 4 \cdot P_{\text{odd}}(16) = 4 - 4 = 0$$

**Result**: $[P(1), P(4), P(16), P(13)] = [11, 8, 1, 0]$.

Verification: $P(4) = 5 + 3(4) + 16 + 2(64) = 5 + 12 + 16 + 128 = 161 \equiv 8 \pmod{17}$. Correct.

The inverse FFT, going from evaluations back to coefficients, uses the same algorithm with $\omega^{-1}$ instead of $\omega$ and a factor of $1/n$.



## The Vanishing Polynomial

Here is the central insight of univariate arithmetization.

The **vanishing polynomial** of a set $H$ is:

$$Z_H(X) = \prod_{h \in H}(X - h)$$

For the $n$-th roots of unity, this simplifies dramatically:

$$Z_H(X) = X^n - 1$$

This is because $\omega^n = 1$ for every root of unity $\omega$; they are precisely the roots of $X^n - 1$.

**The key theorem**: A polynomial $C(X)$ vanishes at every point of $H$ if and only if $Z_H(X)$ divides $C(X)$.

This is the compression at the heart of univariate SNARKs:

1. Encode $n$ constraints as: "$C(\omega^i) = 0$ for all $i$"
2. This is equivalent to: "$Z_H(X)$ divides $C(X)$"
3. Which is equivalent to: "There exists $Q(X)$ such that $C(X) = Q(X) \cdot Z_H(X)$"

One polynomial divisibility condition captures $n$ separate constraint checks.



## The Divisibility Check

How do we verify divisibility efficiently?

The prover computes the quotient $Q(X) = C(X) / Z_H(X)$ and commits to it. The verifier picks a random challenge $z \in \mathbb{F}$ and checks:

$$C(z) \stackrel{?}{=} Q(z) \cdot Z_H(z)$$

If $C(X) = Q(X) \cdot Z_H(X)$ as polynomials, this equation holds for all $z$, including the random one.

If $C(X) \neq Q(X) \cdot Z_H(X)$, their difference is a nonzero polynomial. By Schwartz-Zippel, a random $z$ catches this disagreement with probability at least $1 - d/|\mathbb{F}|$, where $d$ is the degree.

One random check. $n$ constraints verified. This is the magic.



## Lagrange Interpolation over Roots of Unity

We saw earlier that the Lagrange basis $L_i(X) = \prod_{j \neq i} \frac{X - \omega^j}{\omega^i - \omega^j}$ is the polynomial that equals 1 at $\omega^i$ and 0 at all other roots. For roots of unity, this product simplifies to a closed form:

$$L_i(X) = \frac{\omega^i}{n} \cdot \frac{X^n - 1}{X - \omega^i}$$

Why does this work? The numerator $X^n - 1$ vanishes at all $n$-th roots of unity. Dividing by $(X - \omega^i)$ removes the zero at $\omega^i$, leaving a polynomial that vanishes at all roots *except* $\omega^i$. The prefactor $\frac{\omega^i}{n}$ normalizes so that $L_i(\omega^i) = 1$.

**Worked example**: Let $n = 4$ in $\mathbb{F}_5$. Here $\omega = 2$ is a primitive 4th root of unity: $2^1 = 2$, $2^2 = 4$, $2^3 = 3$, $2^4 = 1$. The roots are $\{1, 2, 4, 3\}$.

For $L_1(X)$, the polynomial that equals 1 at $\omega^1 = 2$ and 0 at $\{1, 4, 3\}$:

$$L_1(X) = \frac{2}{4} \cdot \frac{X^4 - 1}{X - 2}$$

In $\mathbb{F}_5$, we have $4^{-1} = 4$ (since $4 \cdot 4 = 16 \equiv 1$), so $\frac{2}{4} = 2 \cdot 4 = 8 \equiv 3$.

Factor $X^4 - 1 = (X-1)(X-2)(X-4)(X-3)$ over $\mathbb{F}_5$. Dividing out $(X-2)$:

$$L_1(X) = 3 \cdot (X-1)(X-4)(X-3)$$

Check at $X = 2$: $L_1(2) = 3 \cdot (2-1)(2-4)(2-3) = 3 \cdot (1)(-2)(-1) = 3 \cdot 2 = 6 \equiv 1$. ✓

Check at $X = 1$: $L_1(1) = 3 \cdot (0)(-3)(-2) = 0$. ✓

The polynomial passing through points $(\omega^i, y_i)$ is then $P(X) = \sum_{i=0}^{n-1} y_i \cdot L_i(X)$.



## Cosets: Shifting the Domain

Lagrange interpolation just did something powerful: it extended values defined on $H$ (the roots of unity) to a polynomial defined on all of $\mathbb{F}$. This is the univariate analog of multilinear extension from Chapter 4. There, we extended a function on the Boolean hypercube $\{0,1\}^n$ to all of $\mathbb{F}^n$. Here, we extend a function on roots of unity to all of $\mathbb{F}$.

But sometimes we need more than just extension. We need structured evaluation points *outside* $H$. **Cosets** provide exactly this.

If $k \notin H$ is any nonzero field element, then:

$$k \cdot H = \{k, k\omega, k\omega^2, \ldots, k\omega^{n-1}\}$$

is a coset of $H$. It's a "shifted" copy: $n$ new points, disjoint from $H$.

**Worked example**: In $\mathbb{F}_{13}$, let $\omega = 5$ (a primitive 4th root: $5^2 = 12$, $5^3 = 8$, $5^4 = 1$). The subgroup is $H = \{1, 5, 12, 8\}$.

Take $k = 2$. The coset is $2H = \{2, 10, 11, 3\}$. The two sets are disjoint, giving 8 evaluation points.

The key property: to evaluate $P(X)$ on $2H$, you don't need a new algorithm. If $P(X) = c_0 + c_1 X + c_2 X^2 + c_3 X^3$, then evaluating at $2\omega^i$ is the same as evaluating $P'(X) = c_0 + 2c_1 X + 4c_2 X^2 + 8c_3 X^3$ at $\omega^i$. Scale the coefficients by powers of $k$, then run the standard FFT on $H$. Cosets give you new evaluation domains for free.

**Why cosets matter in ZK:** Several proof systems crucially depend on cosets:

- **PLONK's permutation argument**: Uses multiple cosets to encode wire positions. If you have $n$ gates with 3 wires each ($a$, $b$, $c$), PLONK encodes them on $H$, $kH$, and $k^2H$ (three disjoint domains of size $n$ each). This lets the permutation polynomial distinguish "wire $a$ of gate 5" from "wire $b$ of gate 5."

- **FRI's low-degree testing**: The prover evaluates on a domain larger than the polynomial's degree (for "rate" or "blowup"). Using $H \cup kH$ doubles the evaluation domain while maintaining FFT structure.

- **Quotient degree management**: If $C(X)$ has degree $2n$ but we've only committed to evaluations on $H$ (size $n$), we need more points to pin down the quotient. Using $H \cup kH$ gives $2n$ points (enough to determine a polynomial of degree less than $2n$).

The FFT works on cosets too: just multiply each root of unity by $k$ before running the algorithm.



## The Quotient Argument

The divisibility check above verified vanishing on a *set* of points (all of $H$). The quotient argument is the single-point version: prove that $P(z) = y$ for a committed polynomial $P$.

The **factor theorem** says: $P(z) = y$ if and only if $(X - z)$ divides $P(X) - y$.

The prover computes:

$$Q(X) = \frac{P(X) - y}{X - z}$$

If $P(z) = y$, this is a polynomial. If not, the division has a remainder; $Q$ isn't a polynomial.

The verifier checks the polynomial identity:

$$P(X) - y = Q(X) \cdot (X - z)$$

at a random point. This is the foundation of KZG opening proofs (Chapter 9).



## Univariate vs. Multilinear

We now have two paradigms for polynomial proofs:

| Aspect | Multilinear | Univariate |
|--------|-------------|------------|
| **Variables** | $n$ variables, degree 1 each | 1 variable, degree $N-1$ |
| **Domain** | Boolean hypercube $\{0,1\}^n$ | Roots of unity $H$ |
| **Size** | $N = 2^n$ points | $N$ points |
| **Constraint encoding** | Sum over hypercube | Divisibility by $Z_H$ |
| **Key algorithm** | Recursive halving | FFT |
| **Prover cost** | $O(N)$ (linear) | $O(N \log N)$ (quasi-linear) |
| **Verification** | Sum-check protocol | Random evaluation |
| **Systems** | GKR, Spartan, Lasso | PLONK, Marlin, STARKs |

Both achieve the same essential goal: reduce exponentially many constraint checks to a constant number of random evaluations. They're complementary perspectives on the same phenomenon (the rigidity of low-degree polynomials).

**A note on Groth16**: Groth16 uses univariate polynomials but doesn't require roots of unity; it encodes constraints via QAP (Quadratic Arithmetic Programs) and verifies satisfaction through pairing equations, not divisibility checks at structured domains. Provers *can* use FFT as an optimization for polynomial arithmetic, but it's not fundamental to the protocol. PLONK and STARKs, by contrast, rely structurally on roots of unity: constraints are encoded as "polynomial vanishes on $H$," checked via the divisibility pattern described above.



## Key Takeaways

1. **Finite fields** provide exact arithmetic with every nonzero element invertible. The nonzero elements form a cyclic group.

2. **Roots of unity** are elements with $\omega^n = 1$. They form a subgroup of size $n$ when $n$ divides $p-1$.

3. **The key symmetries**: Squaring halves the group; opposite elements are negatives. These enable the FFT.

4. **Two representations**: Polynomials can be stored as coefficients or evaluations. The FFT converts between them in $O(n \log n)$ time.

5. **The vanishing polynomial** $Z_H(X) = X^n - 1$ captures all roots of unity. A polynomial vanishes on $H$ iff $Z_H$ divides it.

6. **Constraint compression**: $n$ constraints "$C(\omega^i) = 0$" become one divisibility "$Z_H | C$", verified by one random check.

7. **Lagrange interpolation** over roots of unity has a clean closed form exploiting the structure of $Z_H$.

8. **Cosets** extend the domain while preserving FFT-friendliness.

9. **Quotient arguments** prove evaluation claims: to show $P(z) = y$, prove $(X-z)$ divides $P(X) - y$.

10. **The FFT exists because of roots of unity.** The algorithm is a direct consequence of the symmetries $\omega^{n/2} = -1$ and $(\omega^k)^2 = \omega^{2k}$.

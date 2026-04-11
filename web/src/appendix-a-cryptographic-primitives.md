# Appendix A: Cryptographic Primitives

This appendix collects cryptographic building blocks used throughout the book but not central to the SNARK narrative. These primitives appear in trusted setups, commitment schemes, and protocol constructions.

We begin with a brief reminder of assumed mathematical background, then cover specific primitives.

## Mathematical Background

This section provides quick reminders of concepts assumed throughout the book. If these are unfamiliar, consult a textbook on abstract algebra or cryptography before proceeding.

### Finite Fields

A **finite field** $\mathbb{F}_p$ (for prime $p$) is the set $\{0, 1, \ldots, p-1\}$ with addition and multiplication modulo $p$. Every nonzero element has a multiplicative inverse.

**Key properties**:

- The multiplicative group $\mathbb{F}_p^\ast$ has order $p - 1$
- **Fermat's Little Theorem**: For $a \neq 0$, $a^{p-1} = 1$. Thus $a^{-1} = a^{p-2}$.
- **Primitive roots**: There exists $g \in \mathbb{F}_p^\ast$ such that $\lbrace g^0, g^1, \ldots, g^{p-2} \rbrace = \mathbb{F}_p^\ast$

**Extension fields** $\mathbb{F}_{p^k}$ arise by adjoining roots of irreducible polynomials. Elements are degree-$(k-1)$ polynomials over $\mathbb{F}_p$, with multiplication modulo the irreducible polynomial. SNARK-friendly fields often have $p \approx 2^{254}$ for 128-bit security.

**Roots of unity**: If $n \mid (p-1)$, there exist $n$-th roots of unity $\omega$ satisfying $\omega^n = 1$. These enable FFT-based polynomial multiplication.

### Elliptic Curves

An **elliptic curve** over $\mathbb{F}_p$ is the set of points $(x, y) \in \mathbb{F}_p^2$ satisfying
$$y^2 = x^3 + ax + b$$
plus a "point at infinity" $\mathcal{O}$ serving as identity.

**Group law**: Points form an abelian group under a geometric addition rule. For distinct points $P = (x_1, y_1)$ and $Q = (x_2, y_2)$:
$$\lambda = \frac{y_2 - y_1}{x_2 - x_1}, \quad x_3 = \lambda^2 - x_1 - x_2, \quad y_3 = \lambda(x_1 - x_3) - y_1$$

The group order $|E(\mathbb{F}_p)|$ is approximately $p$ (Hasse's theorem: $|p + 1 - |E|| \leq 2\sqrt{p}$).

**Discrete log hardness**: Given $P$ and $Q = kP$, finding $k$ is believed hard. This is the security foundation for elliptic curve cryptography.

**Scalar multiplication**: Computing $kP$ for scalar $k$ uses double-and-add, taking $O(\log k)$ group operations.

**Curve forms**: The Weierstrass form $y^2 = x^3 + ax + b$ is standard, but other forms offer advantages. **Montgomery curves** ($By^2 = x^3 + Ax^2 + x$) enable constant-time scalar multiplication via the Montgomery ladder. **Twisted Edwards curves** ($ax^2 + y^2 = 1 + dx^2y^2$) have unified addition formulas (the same formula works for doubling), making them efficient and resistant to side-channel attacks. BabyJubjub and Jubjub are twisted Edwards curves.

### Bilinear Pairings

A **pairing** is a map $e: \mathbb{G}_1 \times \mathbb{G}_2 \to \mathbb{G}_T$ between elliptic curve groups satisfying:

- **Bilinearity**: $e(aP, bQ) = e(P, Q)^{ab}$
- **Non-degeneracy**: If $P$ and $Q$ are generators, $e(P, Q)$ generates $\mathbb{G}_T$
- **Efficiency**: Computable in polynomial time

Pairings enable "multiplication in the exponent": given $g^a$ and $g^b$, you can't compute $g^{ab}$ directly, but $e(g^a, g^b) = e(g,g)^{ab}$ moves the product to a different group.

**Why pairings matter for SNARKs**: KZG commitments use pairings to verify polynomial evaluations. The verifier checks $e([f(s)], [1]) = e([q(s)], [s - z]) \cdot e([f(z)], [1])$ without knowing $s$.

**Pairing-friendly curves**: Not all curves support efficient pairings. BN254 and BLS12-381 are specifically designed for this.

### The Discrete Log Assumption

The security of elliptic curve cryptography rests on:

**Discrete Log Problem (DLP)**: Given $P$ and $Q = kP$, find $k$.

**Computational Diffie-Hellman (CDH)**: Given $P$, $aP$, and $bP$, compute $abP$.

**Decisional Diffie-Hellman (DDH)**: Distinguish $(P, aP, bP, abP)$ from $(P, aP, bP, cP)$ for random $c$.

In pairing groups, DDH is easy (check via pairing), but CDH is still believed hard. This is the **gap Diffie-Hellman** setting that KZG exploits.

## Secure Random Sampling

Many protocols require random field elements. "Random" means sampled uniformly from $\mathbb{F}_p$ or a subgroup, with each element equally likely.

### The Modulo Bias Problem

A common implementation: generate random bytes, interpret as integer, take modulo $p$.

```
x = random_bytes(32)  # 256 bits
r = int(x) mod p
```

This introduces bias. If $2^{256} \mod p \neq 0$, some residues are more likely than others.

**Example**: Sample from $\{0, 1, \ldots, 9\}$ using a random byte (0-255).

- Naive: $r = \text{byte} \mod 10$
- Values 0-5 appear with probability $26/256$ (26 preimages each: 0, 10, 20, ..., 250)
- Values 6-9 appear with probability $25/256$ (25 preimages each)

The bias is small but potentially exploitable over many samples.

### Rejection Sampling

Generate candidates and reject those outside an unbiased range.

```
repeat:
    x = random_bytes(32)
    if x < p * floor(2^256 / p):
        return x mod p
```

This ensures each residue has equal probability. Expected iterations: $< 2$ when $p$ is close to a power of 2.

### Hashing to Field Elements

When deriving field elements from structured data (Fiat-Shamir challenges, randomness beacons):

1. Hash the input: $h = H(\text{data})$
2. Interpret as integer and reduce modulo $p$
3. Or use a domain-specific "hash-to-field" function (RFC 9380)

The hash output should be larger than $p$ (e.g., 512 bits for a 256-bit field) to minimize bias.

## Nothing-Up-My-Sleeve (NUMS) Constructions

Sometimes protocols require public constants that "couldn't have been chosen maliciously."

### The Problem

If a constant $c$ is needed (e.g., a generator, a hash input), how do we convince others it wasn't chosen to create a trapdoor?

### NUMS Technique

Derive the constant from a public, unpredictable source:

- Digits of $\pi$, $e$, or $\sqrt{2}$
- Hashes of fixed strings: $c = H(\text{"nothing up my sleeve"})$
- Sequential integers: "Point number 1", "Point number 2", etc.

**Example**: The secp256k1 curve (used in Bitcoin) derives its parameters from sequential digits. This convinced the community the curve wasn't backdoored.

### Application to Trusted Setup

In a Powers of Tau ceremony, the initial toxic waste $\tau$ should be derived via NUMS:
$$\tau_0 = H(\text{beacon hash} \| \text{round number})$$

Each participant then randomizes: $\tau_i = \tau_{i-1} \cdot r_i$ where $r_i$ is their secret randomness.

## Shamir's Secret Sharing

Distribute a secret $s$ among $n$ parties such that any $t$ can reconstruct but $t-1$ learn nothing.

### Construction

Work over a finite field $\mathbb{F}_p$ with $p > n$.

**Sharing (by dealer)**:

1. Choose random polynomial $P(X) = s + a_1 X + a_2 X^2 + \cdots + a_{t-1} X^{t-1}$
2. The secret is $P(0) = s$
3. Give party $i$ the share $s_i = P(i)$

**Reconstruction (by any $t$ parties)**:

1. Collect $t$ shares: $(i_1, s_{i_1}), \ldots, (i_t, s_{i_t})$
2. Use Lagrange interpolation to find $P(0)$:
   $$s = P(0) = \sum_{j=1}^{t} s_{i_j} \cdot \prod_{k \neq j} \frac{-i_k}{i_j - i_k}$$

### Security

Any $t-1$ shares are consistent with every possible secret. The polynomial through $t-1$ points can have any value at 0. Information-theoretic security: even computationally unbounded adversaries learn nothing.

### The Phase Transition

Shamir's scheme exhibits a striking property borrowed from physics: a **phase transition** at the threshold $t$.

In thermodynamics, phase transitions are sharp boundaries where a system's behavior changes discontinuously. Water at 99°C is liquid; at 101°C it's gas. There's no gradual transition: the properties flip at a critical point.

Shamir's scheme has exactly this character:

- With $t-1$ shares, the adversary knows **nothing** about the secret (every value in $\mathbb{F}_p$ is equally likely)
- With $t$ shares, the adversary knows **everything** (the secret is uniquely determined)

There's no intermediate state. The information doesn't leak gradually as shares accumulate. At $t-1$ shares, the entropy of the secret is $\log_2 p$ bits (maximum uncertainty). At $t$ shares, the entropy drops to zero (complete knowledge). The transition is discontinuous.

This is information-theoretic, not computational. The phase transition persists even against adversaries with unlimited computing power. The mathematics of polynomial interpolation creates a genuine discontinuity in the information landscape.

### Worked Example

Secret $s = 10$, threshold $t = 2$, parties $n = 3$, field $\mathbb{F}_{17}$.

Polynomial: $P(X) = 10 + 5X$ (random coefficient $a_1 = 5$).

Shares:

- Party 1: $P(1) = 15$
- Party 2: $P(2) = 20 \equiv 3 \pmod{17}$
- Party 3: $P(3) = 25 \equiv 8 \pmod{17}$

Reconstruction from parties 1 and 3:
$$s = 15 \cdot \frac{-3}{1 - 3} + 8 \cdot \frac{-1}{3 - 1} = 15 \cdot \frac{-3}{-2} + 8 \cdot \frac{-1}{2}$$

In $\mathbb{F}_{17}$: $(-2)^{-1} = 8$, $2^{-1} = 9$.
$$s = 15 \cdot (-3) \cdot 8 + 8 \cdot (-1) \cdot 9 = 15 \cdot 11 + 8 \cdot 8 = 165 + 64 \equiv 10 \pmod{17}$$

## Feldman's Verifiable Secret Sharing

Standard Shamir assumes an honest dealer. What if the dealer distributes inconsistent shares?

### The Problem

A malicious dealer could give shares that don't reconstruct to any secret, or reconstruct to different secrets for different groups.

### Feldman's Solution

Broadcast commitments to the polynomial coefficients.

**Setup**: Group $\mathbb{G}$ of prime order $q$, generator $g$.

**Sharing**:

1. Dealer chooses $P(X) = s + a_1 X + \cdots + a_{t-1} X^{t-1}$
2. Dealer broadcasts commitments: $C_0 = g^s, C_1 = g^{a_1}, \ldots, C_{t-1} = g^{a_{t-1}}$
3. Dealer sends share $s_i = P(i)$ to party $i$

**Verification**: Party $i$ checks:
$$g^{s_i} = \prod_{j=0}^{t-1} C_j^{i^j}$$

This holds because:
$$\prod_{j=0}^{t-1} C_j^{i^j} = \prod_{j=0}^{t-1} g^{a_j \cdot i^j} = g^{\sum_j a_j i^j} = g^{P(i)} = g^{s_i}$$

If verification fails, party $i$ broadcasts a complaint. Honest parties can detect malicious dealers.

### Limitation

Feldman VSS reveals $g^s$ (the "encrypted" secret). This may leak partial information (e.g., equality with other secrets). Pedersen VSS adds blinding for perfect hiding.

## Hash Functions in Zero-Knowledge

SNARKs use hash functions for:

- Fiat-Shamir challenges
- Merkle tree commitments (FRI, STARKs)
- Random oracle instantiation

### The Circuit Cost Problem

Standard hashes (SHA-256, BLAKE3) are expensive in circuits. SHA-256 uses operations that CPUs handle efficiently (32-bit XOR, bit rotations, boolean operations), but these are catastrophic inside arithmetic circuits over prime fields.

A single XOR in an arithmetic circuit requires: decomposing each input into bits (one constraint per bit to enforce booleanity: $b_i \cdot (1 - b_i) = 0$), then computing the XOR bit-by-bit as $a_i + b_i - 2 \cdot a_i \cdot b_i$. A 256-bit XOR that takes one CPU cycle becomes hundreds of constraints.

**The numbers**: SHA-256 costs roughly 25,000–30,000 constraints per invocation. A depth-20 Merkle tree (about 1 million leaves) requires 20 hashes, totaling 500,000–600,000 constraints just for hashing.

### Algebraic Hashes: The Solution

**Algebraically-friendly hashes** use only native field operations: addition and multiplication. No bit operations at all. This isn't just an optimization; it's a paradigm shift from "implement SHA-256 in a circuit" to "what hash would we design if we were circuit architects from the start?"

**Poseidon** is the dominant choice. It uses a sponge construction with a permutation built from three layers per round:

1. **Add round constants**: Breaks symmetry. Cost: 0 constraints (additions are linear).
2. **S-box**: Apply $x^\alpha$ (typically $x^5$) for nonlinearity. Cost: 2 constraints per S-box.
3. **MDS matrix**: Multiply state by a maximum-distance-separable matrix for diffusion. Cost: 0 constraints (linear operations absorbed into next nonlinear step).

The key optimization is **HADES**: use *full rounds* (S-box on all state elements) at the beginning and end for statistical security, and *partial rounds* (S-box on only one element) in the middle for algebraic security. A typical configuration: 8 full rounds and 56 partial rounds, totaling ~160 constraints per hash.

**Comparison**: For a depth-20 Merkle tree:

| Hash | Constraints/hash | Total |
|------|------------------|-------|
| SHA-256 | ~25,000 | ~500,000 |
| Poseidon | ~160 | ~3,200 |

That's **156× fewer constraints**: the difference between feasible and impractical.

**Other algebraic hashes**:

- **MiMC**: Earlier design (2016), simpler but higher multiplicative depth. Largely superseded.
- **Rescue**: Alternates S-box and inverse S-box. Good for specific systems.
- **Poseidon2** (2023): Same constraints as Poseidon but 3× faster witness generation.

### Security Considerations

Algebraic hashes have less cryptanalytic history than SHA-256. Poseidon has received sustained analysis (Grassi et al. 2019, subsequent Gröbner basis attacks), and current parameters include security margins. But conservative applications may:

- Use more rounds than the minimum recommended
- Fall back to SHA-256 for security-critical operations outside circuits
- Accept constraint overhead for robustness

Poseidon is *not* for general-purpose hashing. For files, passwords, or data at rest, use SHA-256 or BLAKE3. Poseidon is a specialized tool for proving hash computations inside ZK circuits.

## Modular Arithmetic Implementation

SNARK provers spend most time in modular arithmetic. Implementation details matter enormously.

### Montgomery Multiplication

Standard modular multiplication: compute $a \cdot b$, then divide by $p$ and take remainder.

**Montgomery representation**: Store $\bar{a} = a \cdot R \mod p$ where $R = 2^k$ for convenient $k$.

Montgomery product: $\bar{c} = \bar{a} \cdot \bar{b} \cdot R^{-1} \mod p$

> **The Shift Analogy**
>
> Think of Montgomery form as shifting the decimal point. We multiply numbers in a "shifted space" where division by $R$ is just "deleting the last $k$ digits" (a bit shift), which is essentially free in hardware. We only shift back at the end.
>
> It's like computing $1.5 \times 2.5$ by working with $15 \times 25 = 375$, then remembering to put two decimal places back: $3.75$. The multiplication happens in the "scaled up" space where the arithmetic is simpler.

Avoids expensive division by using bit shifts and addition. Conversion overhead amortized over many operations.

### SIMD and Parallelism

Modern CPUs have vector instructions (AVX-256, AVX-512). Field arithmetic can be parallelized:

- Four 64-bit multiplications simultaneously
- Eight 32-bit multiplications simultaneously

GPU arithmetic parallelizes across thousands of threads. SNARK provers achieve 10-100× speedup from GPU acceleration.

## Random Beacons

Some applications require public randomness that:

- Cannot be predicted before a deadline
- Cannot be biased by any party
- Is verifiable by all

### Blockchain-Based Beacons

Use the hash of a future block as randomness. The block hash is unpredictable until mined.

**Risk**: Miners can withhold blocks to manipulate the beacon (at cost of block rewards).

### VDF-Based Beacons

A Verifiable Delay Function (VDF) computes $f^T(x)$ where:

- Computing $f^T$ requires time $T$ (sequential)
- Verifying the result is fast

A beacon seeds a VDF. By the time the output is known, manipulation is impossible.

### Multi-Party Beacons

Multiple parties contribute randomness. If any one is honest, the result is unbiased.

**Simple protocol**: Each party commits to a random value, then all reveal. Beacon = hash of all revealed values.

**Risk**: Last revealer sees the beacon before revealing. Commit-then-reveal with timeouts mitigates this.

## Elliptic Curves in Zero-Knowledge

Not all elliptic curves work for SNARKs. Pairing-based systems (Groth16, KZG commitments) require curves with efficiently computable bilinear pairings. The choice of curve determines the scalar field, which in turn determines what field elements your circuit operates over.

### BN254 (alt_bn128)

The workhorse of practical SNARKs. A Barreto-Naehrig curve with embedding degree 12.

- **Scalar field**: $r \approx 2^{254}$ (254 bits)
- **Security**: Originally claimed ~128 bits, now estimated at ~100 bits due to advances in discrete log attacks on extension fields
- **Status**: Still widely used (Ethereum precompiles, most zkEVMs, Groth16 deployments)

BN254's scalar field prime:
$$r = 21888242871839275222246405745257275088548364400416034343698204186575808495617$$

Ethereum has native precompiles for BN254 operations (ecAdd, ecMul, ecPairing), making it the default for on-chain verification.

### BLS12-381

A Barreto-Lynn-Scott curve with embedding degree 12. Designed to provide ~128-bit security even with improved attacks.

- **Scalar field**: $r \approx 2^{255}$ (255 bits)
- **Security**: Solid 128-bit security margin
- **Status**: Used in newer systems (Zcash Sapling, Ethereum 2.0 signatures, PLONK implementations)

BLS12-381 is larger than BN254 (larger field, more expensive operations) but future-proof against known attack improvements.

### Embedded Curves: BabyJubjub and Jubjub

Pairing curves have large coordinates. What if you need to do elliptic curve operations *inside* a circuit, for example, verifying an EdDSA signature within a SNARK?

Computing BN254 point addition inside a BN254 circuit is expensive: the base field is ~254 bits, requiring big-integer arithmetic in constraints. The solution: use a *different* curve whose base field matches the SNARK's scalar field.

**BabyJubjub** is a twisted Edwards curve defined over BN254's scalar field. Points on BabyJubjub have coordinates in $\mathbb{F}_r$ where $r$ is BN254's scalar field order. This means:

- BabyJubjub operations are native arithmetic in BN254 circuits
- Point addition costs ~6 constraints (not thousands)
- EdDSA signature verification becomes practical inside circuits

**Jubjub** plays the same role for BLS12-381: a twisted Edwards curve over BLS12-381's scalar field.

The pattern: an "embedded" or "inner" curve lives over the outer curve's scalar field, enabling efficient in-circuit elliptic curve operations.

### Curve Cycles

For recursive SNARKs, you need to verify a proof *inside* a circuit. If both the proof system and the circuit use the same field, you hit a problem: the verifier does arithmetic in the scalar field, but the proof's group operations are over the base field.

A **curve cycle** pairs two curves where each curve's base field equals the other's scalar field. Pasta curves (Pallas and Vesta) form such a cycle, enabling efficient recursion in systems like Halo 2.

| Curve | Base Field | Scalar Field |
|-------|------------|--------------|
| Pallas | $\mathbb{F}_p$ | $\mathbb{F}_q$ |
| Vesta | $\mathbb{F}_q$ | $\mathbb{F}_p$ |

Prove over Pallas, verify in a Vesta circuit; prove over Vesta, verify in a Pallas circuit. The cycle enables indefinite recursion.

> **The BN254/Grumpkin Cycle**
>
> While Pallas/Vesta is the most famous cycle (used in Halo 2), the BN254/Grumpkin cycle matters for Ethereum developers. Since BN254 is precompiled on Ethereum, systems like Aztec use this cycle to verify recursive proofs on-chain cheaply. Grumpkin is a curve whose base field matches BN254's scalar field, enabling the same recursive trick while staying compatible with Ethereum's existing infrastructure.

## Group Operations

Elliptic curve SNARKs rely on fast group operations.

### Point Addition (Affine)

Given points $P = (x_1, y_1)$ and $Q = (x_2, y_2)$ on curve $y^2 = x^3 + ax + b$:

$$\lambda = \frac{y_2 - y_1}{x_2 - x_1}$$
$$x_3 = \lambda^2 - x_1 - x_2$$
$$y_3 = \lambda(x_1 - x_3) - y_1$$

Affine coordinates require field inversion (expensive).

### Projective Coordinates

Represent $(x, y)$ as $(X : Y : Z)$ where $x = X/Z$, $y = Y/Z$.

Point addition and doubling use only multiplication, avoiding inversion until final conversion.

> **The No-Division Rule**
>
> In computer hardware, division is expensive (like doing long division by hand). Multiplication is cheap.
>
> Projective coordinates let us represent points as ratios $(X:Y:Z)$ so we can do all our math using only multiplication. We only perform the expensive division once at the very end to convert back. It's like working with fractions: to compute $\frac{1}{3} + \frac{1}{4}$, you do $\frac{4+3}{12}$ and delay the actual division as long as possible.

**Jacobian coordinates**: $(X : Y : Z)$ with $x = X/Z^2$, $y = Y/Z^3$. Optimized for repeated doubling.

### Multi-Scalar Multiplication (MSM)

Compute $\sum_i s_i \cdot G_i$ for scalars $s_i$ and points $G_i$.

**Pippenger's algorithm**: Group scalars by their bit patterns. Reduces work from $O(n \cdot \log |s|)$ to $O(n / \log n \cdot \log |s|)$.

MSM dominates KZG commitment time. Parallelization and GPU implementation are necessary for practical SNARKs.


## Key Takeaways

**Mathematical foundations**:

1. **Finite fields**: $\mathbb{F}_p$ is integers mod prime $p$. Fermat gives inverses: $a^{-1} = a^{p-2}$. Roots of unity enable FFT when $n \mid (p-1)$.

2. **Elliptic curves**: Points on $y^2 = x^3 + ax + b$ form a group. Security rests on discrete log hardness.

3. **Pairings**: Bilinear maps $e(aP, bQ) = e(P,Q)^{ab}$ enable "multiplication in the exponent." This powers KZG verification.

**Cryptographic primitives**:

4. **Modulo bias**: Naive random sampling is biased. Use rejection sampling or hash outputs wider than the field.

5. **NUMS construction**: Derive constants from unpredictable sources (digits of $\pi$, hashes of fixed strings) to prevent trapdoors.

6. **Shamir's secret sharing**: Polynomial interpolation enables $(t, n)$-threshold sharing with information-theoretic security. The threshold is a phase transition: $t-1$ shares reveal nothing, $t$ shares reveal everything.

7. **Feldman VSS**: Broadcast commitments to polynomial coefficients allow parties to verify share consistency without trusting the dealer.

8. **Algebraic hashes**: SHA-256 costs ~25,000 constraints per hash in circuits. Poseidon costs ~160 by using only native field operations. The HADES design mixes full rounds (all S-boxes) with partial rounds (one S-box) for efficiency.

**Curves and implementation**:

9. **Curve selection**: BN254 has Ethereum precompiles but ~100-bit security. BLS12-381 offers full 128-bit security. Choose based on deployment requirements.

10. **Embedded curves**: BabyJubjub (for BN254) and Jubjub (for BLS12-381) enable efficient in-circuit elliptic curve operations by living over the outer curve's scalar field.

11. **Curve cycles**: Pairs like Pallas/Vesta where each curve's base field equals the other's scalar field enable efficient recursive proof composition.

12. **Montgomery multiplication**: Avoids expensive division by working in a modified representation. Standard for high-performance field arithmetic.

13. **Projective coordinates**: Avoid field inversions by representing points as ratios. Essential for efficient elliptic curve operations.

14. **MSM optimization**: Multi-scalar multiplication dominates KZG commitment time. Pippenger's algorithm and GPU parallelization are necessary for practical provers.

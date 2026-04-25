# Appendix C: Field equations cheat sheet

A quick reference for the core equations in zero-knowledge proof systems.



## Schwartz-Zippel lemma

For a non-zero polynomial $p(X_1, \ldots, X_n)$ of total degree $d$ over a field $\mathbb{F}$:

$$\Pr_{r \leftarrow \mathbb{F}^n}[p(r) = 0] \leq \frac{d}{|\mathbb{F}|}$$

**Consequence**: Random evaluation catches cheating with probability $\geq 1 - d/|\mathbb{F}|$.



## Multilinear extensions

### Lagrange basis polynomial

For $w \in \{0,1\}^n$:

$$L_w(X) = \prod_{i=1}^{n} \left( w_i \cdot X_i + (1 - w_i)(1 - X_i) \right)$$

**Property**: $L_w(w) = 1$ and $L_w(b) = 0$ for $b \neq w$.

### Multilinear extension formula

For $f: \{0,1\}^n \to \mathbb{F}$:

$$\tilde{f}(X) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(X)$$

### Equality polynomial

$$\widetilde{\text{eq}}(X, Y) = \prod_{i=1}^{n} \left( X_i Y_i + (1 - X_i)(1 - Y_i) \right)$$

**Property**: $\widetilde{\text{eq}}(a, b) = 1$ if $a = b$, else $0$ (on hypercube).



## Sum-check protocol

*Dimensions: Vector size $N = 2^n$; protocol runs $n$ rounds.*

### The claim

Prove:
$$H = \sum_{b \in \{0,1\}^n} g(b_1, \ldots, b_n)$$

### Round $i$ polynomial

Prover sends:
$$s_i(X_i) = \sum_{b_{i+1}, \ldots, b_n \in \{0,1\}} g(r_1, \ldots, r_{i-1}, X_i, b_{i+1}, \ldots, b_n)$$

### Verifier checks

- Round 1: $s_1(0) + s_1(1) = H$
- Round $i > 1$: $s_i(0) + s_i(1) = s_{i-1}(r_{i-1})$
- Final: query oracle at $(r_1, \ldots, r_n)$ to check $s_n(r_n) = g(r_1, \ldots, r_n)$

### Soundness

$$\epsilon \leq \frac{n \cdot d}{|\mathbb{F}|}$$

where $n$ is the number of variables and $d$ is the maximum individual degree. (More precisely: $\sum_i d_i / |\mathbb{F}|$ where $d_i$ is the degree in variable $i$.)



## Vanishing polynomials

### Over roots of unity

For domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$ where $\omega^n = 1$:

$$Z_H(X) = X^n - 1$$

**Property**: $Z_H(\omega^i) = 0$ for all $i$, and $Z_H(r) \neq 0$ for $r \notin H$.

### Over boolean hypercube

For proving a polynomial vanishes on $\{0,1\}^n$, use the univariate identity:

$$Z_{\{0,1\}}(X) = X(X-1)$$

applied variable by variable in multilinear settings.



## R1CS and QAP

### R1CS constraint

*Dimensions: Matrices $A, B, C$ are $m \times n$; witness $z$ is $n \times 1$; result is $m \times 1$.*

For witness vector $z = (1, x, w)$:

$$(A \cdot z) \circ (B \cdot z) = C \cdot z$$

where $\circ$ is entry-wise multiplication.

### QAP polynomial identity

Define polynomials $A(X), B(X), C(X)$ by interpolating constraint matrices.

The constraint system is satisfied iff:

$$A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$$

where $Z_H(X) = \prod_{\alpha \in H}(X - \alpha)$ is the vanishing polynomial.



## KZG polynomial commitments

*Dimensions: Polynomial degree $< D$; SRS size $D+1$ elements.*

### Structured reference string (SRS)

Secret $\tau$; public: $(g, g^\tau, g^{\tau^2}, \ldots, g^{\tau^D})$

### Commitment

For $f(X) = \sum_i c_i X^i$:

$$C = g^{f(\tau)} = \prod_i (g^{\tau^i})^{c_i}$$

### Evaluation proof

To prove $f(z) = v$: *(Prover knows $f(X)$; Verifier knows $C$, $z$, $v$)*

1. Compute quotient: $w(X) = \frac{f(X) - v}{X - z}$
2. Proof: $\pi = g^{w(\tau)}$

### Verification (pairing check)

$$e(\pi, g^\tau \cdot g^{-z}) = e(C \cdot g^{-v}, g)$$

Equivalently:

$$e(g^{w(\tau)}, g^{\tau - z}) = e(g^{f(\tau) - v}, g)$$



## FRI folding

### Split polynomial

For $f(X) = f_E(X^2) + X \cdot f_O(X^2)$:

- $f_E(Y)$: even coefficients
- $f_O(Y)$: odd coefficients

### Folding with challenge $\alpha$

$$f_1(Y) = f_E(Y) + \alpha \cdot f_O(Y)$$

**Property**: $\deg(f_1) < \deg(f)/2$

### Consistency check

At query point $x$ (where $-x$ is its conjugate on the same coset), verify:

$$f_1(x^2) = \frac{f(x) + f(-x)}{2} + \alpha \cdot \frac{f(x) - f(-x)}{2x}$$

This uses: $f_E(x^2) = \frac{f(x) + f(-x)}{2}$ and $f_O(x^2) = \frac{f(x) - f(-x)}{2x}$.



## AIR (Algebraic Intermediate Representation)

### Trace polynomials

For a trace matrix with $w$ registers and $T$ timesteps, interpolate each column over domain $H = \{1, \omega, \ldots, \omega^{T-1}\}$:

$$P_j(\omega^i) = \text{trace}[i][j]$$

### Transition constraints

For a constraint "register 0 at next step equals $f$ of current registers":

$$P_0(\omega X) = f(P_0(X), P_1(X), \ldots)$$

The shift $\omega X$ accesses "next row" values. Define constraint polynomial:

$$C(X) = P_0(\omega X) - f(P_0(X), P_1(X), \ldots)$$

### Quotient check

Valid trace iff $C(X)$ vanishes on transition domain $H' = \{1, \omega, \ldots, \omega^{T-2}\}$:

$$Q(X) = \frac{C(X)}{Z_{H'}(X)}$$

is a polynomial (not rational function).

### Boundary constraints

Pin inputs/outputs. For $P_j(\omega^k) = v$:

$$\frac{P_j(X) - v}{X - \omega^k}$$

must be a polynomial.



## PLONK

### Gate equation

$$Q_L(X) \cdot a(X) + Q_R(X) \cdot b(X) + Q_O(X) \cdot c(X) + Q_M(X) \cdot a(X) \cdot b(X) + Q_C(X) = 0$$

on domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$.

### Permutation grand product

Accumulator $Z(X)$ satisfies:

$$Z(1) = 1$$

$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{(a_i + \beta \omega^i + \gamma)(b_i + \beta k_1\omega^i + \gamma)(c_i + \beta k_2\omega^i + \gamma)}{(a_i + \beta \sigma_a(\omega^i) + \gamma)(b_i + \beta \sigma_b(\omega^i) + \gamma)(c_i + \beta \sigma_c(\omega^i) + \gamma)}$$

**Property**: The product telescopes, so $Z(\omega^n) = Z(1) = 1$ iff all copy constraints hold.

### Quotient check

All constraints satisfied iff there exists $t(X)$ with:

$$\text{(gate)} + \alpha \cdot \text{(permutation)} = t(X) \cdot Z_H(X)$$



## Groth16

### Public input combination

Given public inputs $(z_0, z_1, \ldots, z_\ell)$ where $z_0 = 1$:

$$\text{vk}_x = \sum_{j=0}^{\ell} z_j \cdot (\text{vk}_{IC})_j$$

where $(\text{vk}_{IC})_j = g_1^{\frac{\beta A_j(\tau) + \alpha B_j(\tau) + C_j(\tau)}{\gamma}}$ are verification key elements.

### Verification equation

Given proof $(\pi_A, \pi_B, \pi_C) \in \mathbb{G}_1 \times \mathbb{G}_2 \times \mathbb{G}_1$:

$$e(\pi_A, \pi_B) \stackrel{?}{=} e(g_1^{\alpha}, g_2^{\beta}) \cdot e(\text{vk}_x, g_2^{\gamma}) \cdot e(\pi_C, g_2^{\delta})$$

**Verification cost**: One MSM (size $\ell$) + 3-4 pairings, independent of circuit size.

### Proof size

3 group elements: 128 bytes over BN254 (32 + 64 + 32 for $\mathbb{G}_1$, $\mathbb{G}_2$, $\mathbb{G}_1$).



## Lookup arguments

### Plookup identity

For lookups $f = \{f_1, \ldots, f_n\}$ and table $t = \{t_1, \ldots, t_d\}$, let $s = \text{sort}(f \cup t)$.

$$\prod_i (\gamma + f_i) \cdot \prod_i (\gamma(1+\beta) + t_i + \beta t_{i+1}) \cdot (1+\beta)^n$$

$$= \prod_i (\gamma(1+\beta) + s_i + \beta s_{i+1})$$

**Property**: Equality holds iff $f \subseteq t$.

### LogUp identity

For lookups $f = \{f_1, \ldots, f_n\}$ into table $t = \{t_1, \ldots, t_d\}$ with multiplicities $m_j$:

$$\sum_{i=1}^{n} \frac{1}{\gamma + f_i} = \sum_{j=1}^{d} \frac{m_j}{\gamma + t_j}$$

**Property**: Equality holds iff each $f_i \in t$ and $m_j$ counts occurrences correctly.

**Soundness**: By Schwartz-Zippel, equality holds with probability $\geq 1 - (n+d)/|\mathbb{F}|$ over random $\gamma$.

**Advantage**: No sorting required; additive structure enables multi-table batching.



## GKR protocol

*Dimensions: Layer $i$ has $S_i$ gates; layer $i+1$ (inputs) has $S_{i+1}$ gates; $k = \log_2 S_i$.*

### Layer reduction

For layered circuit with values $V^{(i)}$ at layer $i$:

$$\tilde{V}^{(i)}(r) = \sum_{p,q \in \{0,1\}^k} \widetilde{\text{add}}^{(i)}(r, p, q) \cdot (\tilde{V}^{(i+1)}(p) + \tilde{V}^{(i+1)}(q))$$
$$+ \widetilde{\text{mult}}^{(i)}(r, p, q) \cdot \tilde{V}^{(i+1)}(p) \cdot \tilde{V}^{(i+1)}(q)$$

### Sum-check reduction

A claim about $\tilde{V}^{(i)}(r)$ reduces via sum-check to claims about $\tilde{V}^{(i+1)}(p^*)$ and $\tilde{V}^{(i+1)}(q^*)$ for random $p^*, q^*$.

**Soundness**: Compound over $d$ layers, each with $O(\log n)$ sum-check rounds.



## Inner product argument (IPA)

### The claim

Prove $\langle \vec{a}, \vec{b} \rangle = c$ for committed $\vec{a}$.

### Folding step

Given challenge $\alpha$:

$$\vec{a}' = \alpha \cdot \vec{a}_L + \alpha^{-1} \cdot \vec{a}_R$$
$$\vec{b}' = \alpha^{-1} \cdot \vec{b}_L + \alpha \cdot \vec{b}_R$$

**Property**: $\langle \vec{a}', \vec{b}' \rangle = \langle \vec{a}, \vec{b} \rangle + \alpha^2 L + \alpha^{-2} R$

where $L = \langle \vec{a}_L, \vec{b}_R \rangle$ and $R = \langle \vec{a}_R, \vec{b}_L \rangle$.

### Proof size

$O(\log n)$ group elements after $\log n$ rounds.



## Nova folding

### Relaxed R1CS

Standard R1CS: $(A \cdot z) \circ (B \cdot z) = C \cdot z$

Relaxed R1CS with scalar $u$ and error $E$:

$$(A \cdot z) \circ (B \cdot z) = u \cdot (C \cdot z) + E$$

A satisfying instance has $u = 1$ and $E = 0$.

### Folding two instances

Given instances $(u_1, E_1, z_1)$ and $(u_2, E_2, z_2)$, with challenge $r$:

$$u = u_1 + r \cdot u_2$$
$$E = E_1 + r \cdot T + r^2 \cdot E_2$$
$$z = z_1 + r \cdot z_2$$

where $T$ is the "cross-term" computed by the prover.

**Property**: If both inputs satisfy relaxed R1CS, so does the folded instance.



## Fiat-Shamir transform

### Challenge derivation

$$r_i = H(\text{transcript prefix including all previous messages})$$

### Security requirement

The hash must include:

- The public statement $x$
- All previous commitments $C_1, \ldots, C_{i-1}$
- All previous challenges $r_1, \ldots, r_{i-1}$



## Complexity summary

| System | Proof Size | Verification | Prover | Setup |
|--------|------------|--------------|--------|-------|
| Groth16 | $O(1)$ | $O(1)$ | $O(n \log n)$ | Per-circuit |
| PLONK+KZG | $O(1)$ | $O(1)$ | $O(n \log n)$ | Universal |
| STARK/FRI | $O(\log^2 n)$ | $O(\log^2 n)$ | $O(n \log n)$ | Transparent |
| Bulletproofs | $O(\log n)$ | $O(n)$ | $O(n \log n)$ | Transparent |
| Sum-check IP | $O(\log n)$ | $O(\log n)$ | $O(n)$ | None |



## Field sizes (common choices)

| Field | Size | Security | Use Case |
|-------|------|----------|----------|
| BN254 scalar | $\approx 2^{254}$ | ~100 bits | Ethereum, Groth16, PLONK |
| BLS12-381 scalar | $\approx 2^{255}$ | ~128 bits | Zcash, many SNARKs |
| Goldilocks | $2^{64} - 2^{32} + 1$ | ~100 bits* | Plonky2, fast arithmetic |
| Baby Bear | $2^{31} - 2^{27} + 1$ | ~100 bits* | RISC Zero |
| KoalaBear | $2^{31} - 2^{24} + 1$ | ~100 bits* | Lean Ethereum (Whirlaway) |
| Mersenne-31 | $2^{31} - 1$ | ~100 bits* | Circle STARKs, Airbender |

*Small fields require extension fields for cryptographic security; base field security refers to the overall system design.



## Quick reference

**Proving a sum over hypercube**: Sum-check protocol

**Encoding data as polynomial**: Multilinear extension (hypercube) or Lagrange interpolation (roots of unity)

**Binding prover to polynomial**: KZG (trusted setup, constant size), FRI (transparent, log² size), IPA (no pairings, log size)

**Checking polynomial identity on a domain**: Quotient by $Z_H(X) = X^n - 1$ for roots of unity

**Checking table membership**: Lookup argument (Plookup with sorting, LogUp without)

**Verifying circuit layer-by-layer**: GKR protocol with sum-check at each layer

**Incremental computation**: Nova folding (amortize SNARK cost across steps)

**Eliminating interaction**: Fiat-Shamir with complete transcript hashing

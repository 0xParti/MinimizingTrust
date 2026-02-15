# Appendix D: Advanced Polynomial Commitment Schemes

This appendix covers polynomial commitment schemes that achieve specialized trade-offs beyond the main KZG and IPA schemes presented in Chapter 9. These schemes are important for specific applications but involve more complex cryptographic machinery.

## Hyrax: Square-Root Commitments via Tensor Structure

Chapter 9's IPA scheme suffers from linear verification time: the verifier must compute the folded generators, doing $O(N)$ work for a polynomial with $N$ coefficients. **Hyrax** (Wahby et al., 2018) reduces verification to $O(\sqrt{N})$ by exploiting the tensor structure of multilinear polynomials. The key insight is that polynomial evaluation can be written as a vector-matrix-vector product, and this matrix structure enables a commitment scheme where the prover commits to rows separately.

### The Core Idea: From Flat Vectors to Matrices

A multilinear polynomial $\tilde{f}$ over $n$ variables has $N = 2^n$ coefficients. The naive approach stores these as a flat vector $(f_0, f_1, \ldots, f_{N-1})$ and commits with a single Pedersen commitment using $N$ generators. Evaluation then requires $O(N)$ work.

The key insight: **reshape the flat vector into a matrix**. Instead of a length-$N$ vector, arrange the coefficients as a $\sqrt{N} \times \sqrt{N}$ matrix $M$:

$$\underbrace{(f_0, f_1, \ldots, f_{N-1})}_{\text{flat vector}} \quad \longrightarrow \quad \underbrace{M = \begin{pmatrix} f_0 & f_1 & \cdots & f_{\sqrt{N}-1} \\ f_{\sqrt{N}} & f_{\sqrt{N}+1} & \cdots & f_{2\sqrt{N}-1} \\ \vdots & \vdots & \ddots & \vdots \end{pmatrix}}_{\text{matrix form}}$$

The entry $M[a][b]$ stores the coefficient $f_{a \cdot \sqrt{N} + b}$, which corresponds to the evaluation at the Boolean point whose binary representation concatenates $a$ and $b$.

Why does this help? Because polynomial evaluation decomposes into a **vector-matrix-vector product**, and we can commit to rows separately. This reduces verification from $O(N)$ to $O(\sqrt{N})$.

### Tensor Structure of Multilinear Evaluation

Recall from Chapter 5 that multilinear evaluation uses the equality polynomial:

$$\tilde{f}(r_1, \ldots, r_n) = \sum_{b \in \{0,1\}^n} f_b \cdot \text{eq}(b, r)$$

where $\text{eq}(b, r) = \prod_{i=1}^{n} (b_i r_i + (1-b_i)(1-r_i))$.

The crucial observation: $\text{eq}$ factors across the split. If we partition the evaluation point $r = (r_L, r_R)$ where $r_L = (r_1, \ldots, r_{n/2})$ and $r_R = (r_{n/2+1}, \ldots, r_n)$, then:

$$\text{eq}((a, b), r) = \text{eq}(a, r_L) \cdot \text{eq}(b, r_R)$$

Define the Lagrange coefficient vectors:

$$L[a] = \text{eq}(a, r_L) \quad \text{for } a \in \{0,1\}^{n/2}$$
$$R[b] = \text{eq}(b, r_R) \quad \text{for } b \in \{0,1\}^{n/2}$$

Then evaluation becomes a bilinear form. Starting from the MLE definition:

$$\tilde{f}(r) = \sum_{b \in \{0,1\}^n} f_b \cdot \text{eq}(b, r)$$

Split each index $b = (a, c)$ where $a$ indexes rows and $c$ indexes columns:

$$= \sum_{a \in \{0,1\}^{n/2}} \sum_{c \in \{0,1\}^{n/2}} M[a][c] \cdot \text{eq}((a,c), r)$$

Factor the equality polynomial:

$$= \sum_{a} \sum_{c} M[a][c] \cdot \text{eq}(a, r_L) \cdot \text{eq}(c, r_R)$$

Substitute the Lagrange vectors $L[a] = \text{eq}(a, r_L)$ and $R[c] = \text{eq}(c, r_R)$:

$$= \sum_{a,c} M[a][c] \cdot L[a] \cdot R[c] = \vec{L}^T M \vec{R}$$

This is a rank-2 tensor contraction: two vectors contracting with a matrix. The key insight is that the factorization of $\text{eq}$ lets us separate the "row selection" ($\vec{L}$) from the "column selection" ($\vec{R}$).

This is why the matrix reshaping matters: a flat vector evaluation $\sum_i f_i \cdot \chi_i(r)$ requires touching all $N$ terms, but the matrix form $\vec{L}^T M \vec{R}$ can be computed in two steps. First compute $\vec{u} = M^T \vec{L}$ (a length-$\sqrt{N}$ vector), then compute $\langle \vec{u}, \vec{R} \rangle$ (a single dot product). Each step involves only $\sqrt{N}$ operations.

### The Hyrax Commitment Scheme

#### Public Parameters

Random generators $\vec{G} = (G_0, \ldots, G_{\sqrt{N}-1}) \in \mathbb{G}^{\sqrt{N}}$ and $H \in \mathbb{G}$ for blinding.

#### Commitment

Instead of committing to all $N$ coefficients at once (which would require $N$ generators), commit to each row separately:

$$C_a = \langle M[a], \vec{G} \rangle + r_a \cdot H = \sum_{b=0}^{\sqrt{N}-1} M[a][b] \cdot G_b + r_a \cdot H$$

where $r_a$ is a blinding factor for row $a$. The full commitment is the tuple of row commitments:

$$\text{Com}(M) = (C_0, C_1, \ldots, C_{\sqrt{N}-1})$$

This requires $\sqrt{N}$ group elements, not one. The trade-off: larger commitment size for cheaper verification.

### The Opening Protocol

To prove $\tilde{f}(r) = v$ where $r = (r_L, r_R)$:

#### Step 1: Both parties compute Lagrange vectors

From the evaluation point $r = (r_L, r_R)$, both prover and verifier compute:
- $\vec{L}$: row Lagrange coefficients from $r_L$
- $\vec{R}$: column Lagrange coefficients from $r_R$

#### Step 2: Prover computes the projection vector

The prover computes $\vec{u} = M^T \vec{L}$, the weighted column sums:

$$u_b = \sum_{a=0}^{\sqrt{N}-1} L[a] \cdot M[a][b]$$

Each $u_b$ is the $L$-weighted sum of column $b$.

#### Step 3: Verifier computes combined commitment (MSM #1)

The verifier combines the original row commitments (from the commitment phase) using $\vec{L}$:

$$C' = \sum_{a=0}^{\sqrt{N}-1} L[a] \cdot C_a$$

This is computed by the verifier during opening, not as part of the initial commitment. The verifier doesn't have access to the matrix $M$, but they don't need it. By Pedersen's homomorphism, a linear combination of commitments *is* a commitment to the linear combination of the underlying vectors:

$$C' = \sum_a L[a] \cdot C_a = \sum_a L[a] \cdot \langle M[a], \vec{G} \rangle = \langle \sum_a L[a] \cdot M[a], \vec{G} \rangle$$

The inner sum $\sum_a L[a] \cdot M[a]$ is exactly the projection vector $(u_0, u_1, \ldots, u_{\sqrt{N}-1})$, where each $u_b$ is defined in Step 2. So $C'$ would equal $\langle \vec{u}, \vec{G} \rangle$ if the prover computed $\vec{u}$ correctly. The verifier doesn't know $\vec{u}$ yet, but they have computed what a commitment to the *correct* $\vec{u}$ should be.

#### Step 4: Verify consistency (MSM #2)

The prover sends $\vec{u} = (u_0, \ldots, u_{\sqrt{N}-1})$. The verifier computes a commitment to the claimed $\vec{u}$:

$$C'' = \sum_{b=0}^{\sqrt{N}-1} u_b \cdot G_b = \langle \vec{u}, \vec{G} \rangle$$

Check: $C' \stackrel{?}{=} C''$

If $C' = C''$, the prover's $\vec{u}$ is consistent with the committed matrix. The verifier derived $C'$ from the row commitments (which bind the prover to $M$), so equality means the prover computed $\vec{u} = M^T \vec{L}$ correctly.

#### Step 5: Verify the dot product

Check: $\langle \vec{u}, \vec{R} \rangle \stackrel{?}{=} v$

#### Why this proves evaluation

The tensor contraction gives:

$$\tilde{f}(r) = \sum_{a,b} M[a][b] \cdot L[a] \cdot R[b] = \sum_b \left(\sum_a L[a] \cdot M[a][b]\right) \cdot R[b] = \sum_b u_b \cdot R[b] = \langle \vec{u}, \vec{R} \rangle$$

So the dot product check verifies that the claimed value $v$ equals the polynomial evaluation.

#### Zero-knowledge variant

The prover doesn't send $\vec{u}$ directly (which would leak information about $M$). Instead, both checks are combined into a ZK dot product protocol that proves consistency without revealing $\vec{u}$.

### Zero-Knowledge Dot Product Protocol

Hyrax uses a Schnorr-style protocol for proving $\langle \vec{a}, \vec{u} \rangle = v$ where $\vec{u}$ is committed (with blinding) and $\vec{a}$ is public.

#### Setup

Prover holds $\vec{u}$ with Pedersen commitment $C = \langle \vec{u}, \vec{G} \rangle + s \cdot H$ and blinding factor $s$.

#### Protocol

1. Prover picks random masking vector $\vec{d} \in \mathbb{F}^{\sqrt{N}}$ and blinding $s_d \in \mathbb{F}$
2. Prover sends commitment $D = \langle \vec{d}, \vec{G} \rangle + s_d \cdot H$ and masked dot product $e = \langle \vec{a}, \vec{d} \rangle$
3. Verifier sends random challenge $c$
4. Prover responds with $\vec{z} = \vec{d} + c \cdot \vec{u}$ and $s_z = s_d + c \cdot s$
5. Verifier checks:
   - $\langle \vec{z}, \vec{G} \rangle + s_z \cdot H = D + c \cdot C$ (commitment consistency)
   - $\langle \vec{a}, \vec{z} \rangle = e + c \cdot v$ (dot product relation)

The first check ensures $\vec{z}$ opens the linear combination $D + c \cdot C$. The second check verifies that $\langle \vec{a}, \vec{d} + c \cdot \vec{u} \rangle = \langle \vec{a}, \vec{d} \rangle + c \cdot \langle \vec{a}, \vec{u} \rangle$, which holds only if $\langle \vec{a}, \vec{u} \rangle = v$.

**Communication cost:** $O(\sqrt{N})$ field elements (the response vector $\vec{z}$).

### Worked Example: Hyrax on a 4-Variable Polynomial

Let's trace through Hyrax for $n = 4$ variables, so $N = 16$ evaluations arranged as a $4 \times 4$ matrix.

#### Setup

Polynomial evaluations on $\{0,1\}^4$ arranged as matrix $M$ (row index = first 2 bits, column index = last 2 bits):

$$M = \begin{pmatrix} 3 & 1 & 4 & 1 \\ 5 & 9 & 2 & 6 \\ 5 & 3 & 5 & 8 \\ 9 & 7 & 9 & 3 \end{pmatrix}$$

Generators: $\vec{G} = (G_0, G_1, G_2, G_3)$ and blinding generator $H$. Evaluation point: $r = (0.5, 0.5, 0.5, 0.5)$ (working over reals for clarity).

#### Step 1: Commitment phase

Prover commits to each row (omitting blinding for clarity):

$$C_0 = 3G_0 + 1G_1 + 4G_2 + 1G_3$$
$$C_1 = 5G_0 + 9G_1 + 2G_2 + 6G_3$$
$$C_2 = 5G_0 + 3G_1 + 5G_2 + 8G_3$$
$$C_3 = 9G_0 + 7G_1 + 9G_2 + 3G_3$$

The commitment is $(C_0, C_1, C_2, C_3)$: four group elements.

#### Step 2: Compute Lagrange vectors

Split $r = (r_L, r_R)$ where $r_L = (0.5, 0.5)$ and $r_R = (0.5, 0.5)$.

$$L[00] = (1-0.5)(1-0.5) = 0.25, \quad L[01] = (1-0.5)(0.5) = 0.25$$
$$L[10] = (0.5)(1-0.5) = 0.25, \quad L[11] = (0.5)(0.5) = 0.25$$

Similarly $\vec{R} = (0.25, 0.25, 0.25, 0.25)$. Both prover and verifier compute these from the evaluation point.

#### Step 3: Compute projection vector

The prover computes $\vec{u} = M^T \vec{L}$. Each $u_b$ is the $L$-weighted sum of column $b$:

$$u_0 = 0.25(3 + 5 + 5 + 9) = 5.5$$
$$u_1 = 0.25(1 + 9 + 3 + 7) = 5$$
$$u_2 = 0.25(4 + 2 + 5 + 9) = 5$$
$$u_3 = 0.25(1 + 6 + 8 + 3) = 4.5$$

So $\vec{u} = (5.5, 5, 5, 4.5)$. The prover sends $\vec{u}$ (in the non-ZK variant).

#### Step 4: Two MSMs

MSM #1: Combine row commitments with $\vec{L}$:
$$C' = 0.25 \cdot C_0 + 0.25 \cdot C_1 + 0.25 \cdot C_2 + 0.25 \cdot C_3$$

Expanding: $C' = 0.25[(3+5+5+9)G_0 + (1+9+3+7)G_1 + (4+2+5+9)G_2 + (1+6+8+3)G_3]$
$= 5.5G_0 + 5G_1 + 5G_2 + 4.5G_3$

MSM #2: Commit to $\vec{u}$ using generators:
$$C'' = 5.5G_0 + 5G_1 + 5G_2 + 4.5G_3$$

Check: $C' = C''$ ✓ (The projection vector is consistent with the committed matrix.)

#### Step 5: Dot product check

$$v = \langle \vec{u}, \vec{R} \rangle = 5.5(0.25) + 5(0.25) + 5(0.25) + 4.5(0.25) = 5$$

Check: $\langle \vec{u}, \vec{R} \rangle = v = 5$ ✓

#### Verification cost

The verifier performed two MSMs of size 4 (not 16), plus field arithmetic for the dot product. Total: $O(\sqrt{N})$ group operations.

### Using Bulletproofs for Logarithmic Proof Size

The basic Hyrax protocol has $O(\sqrt{N})$ communication because the prover sends $\vec{z}$ (length $\sqrt{N}$) in the Schnorr-style dot product proof. This can be reduced to $O(\log N)$ by replacing Schnorr with Bulletproofs' inner product argument.

Bulletproofs (Bünz et al., 2018) proves $\langle \vec{a}, \vec{b} \rangle = c$ with $O(\log n)$ proof size but $O(n)$ verifier time (linear in vector length). When applied to Hyrax's dot product step (vectors of length $\sqrt{N}$):

- Proof size: $O(\sqrt{N} + \log \sqrt{N}) = O(\sqrt{N})$ (row commitments dominate)
- Verifier time: $O(\sqrt{N})$ (MSM for $C'$ plus Bulletproofs verification on length-$\sqrt{N}$ vectors)

### Generalized Trade-off: The $\iota$ Parameter

The Hyrax paper introduces a generalization parameter $\iota \geq 2$ that controls a communication vs. computation trade-off. Instead of a square matrix, arrange the coefficients as $N^{1/\iota} \times N^{(\iota-1)/\iota}$:

- **$\iota = 2$ (square-root)**: $\sqrt{N} \times \sqrt{N}$ matrix, $O(\sqrt{N})$ commitment, $O(\sqrt{N})$ verification
- **$\iota = 3$**: $N^{1/3} \times N^{2/3}$ matrix, $O(N^{1/3})$ commitment, $O(N^{2/3})$ verification
- **General**: $O(N^{1/\iota})$ commitment size, $O(N^{(\iota-1)/\iota})$ verification time

Higher $\iota$ reduces commitment size (fewer row commitments) at the cost of higher verification time (longer dot product vectors). Since the commitment is sent once but may be opened many times, the square-root case ($\iota = 2$) typically offers the best balance.

### Hyrax: Properties and Trade-offs

| Property | Hyrax (square-root, $\iota = 2$) |
|----------|-------|
| Trusted setup | **None (Transparent)** |
| Commitment size | $O(\sqrt{N})$ group elements |
| Proof size | $O(\log N)$ with Bulletproofs |
| Verification time | $O(\sqrt{N})$ group operations |
| Prover time | $O(N)$ for commitment, $O(\sqrt{N})$ per opening |
| Assumption | Discrete log only |
| Quantum-safe | No |

**Comparison with IPA:**

| | IPA | Hyrax |
|--|-----|-------|
| Commitment size | $O(1)$ | $O(\sqrt{N})$ |
| Verification time | $O(N)$ | $O(\sqrt{N})$ |
| Proof size | $O(\log N)$ | $O(\log N)$ |

Both IPA and Hyrax (with Bulletproofs) achieve logarithmic proof size, but Hyrax trades larger commitments for faster verification. This trade-off is worthwhile when:
- The same polynomial is opened at multiple points (amortizes commitment cost)
- Verification speed matters more than proof/commitment size
- You want transparency without paying IPA's linear verification cost

### Connection to Dory

Hyrax's square-root verification is a significant improvement over IPA's linear verification, but can we do better? **Dory** answers yes by combining Hyrax's matrix structure with pairings.

The key observation: Hyrax's verifier bottleneck is the MSM $C' = \sum_a L[a] \cdot C_a$. This is $O(\sqrt{N})$ group operations. Dory eliminates this by:

1. **Tier 2 commitment:** Instead of storing row commitments directly, Dory combines them into a single $\mathbb{G}_T$ element using pairings
2. **Lazy verification:** The verifier never computes $C'$ explicitly; instead, they track commitments in $\mathbb{G}_T$ and verify everything with a single final pairing check

Where Hyrax achieves $O(\sqrt{N})$ verification, Dory achieves $O(\log N)$. The cost is more complex cryptographic machinery (pairings, two-tier structure, SXDH assumption instead of plain discrete log).

---

## Dory: Logarithmic Verification Without Trusted Setup

Hyrax reduces IPA's $O(N)$ verification to $O(\sqrt{N})$ by exploiting tensor structure. **Dory** (Lee, 2021) pushes further to $O(\log N)$ by combining Hyrax's matrix arrangement with pairings.

The core idea is deferred verification. In IPA, the verifier recalculates the folded generators at each step, doing $O(n)$ work. Dory's verifier instead accumulates commitments and defers all verification to a single final pairing check. The algebraic structure of pairings makes this possible: the verifier can "absorb" all the folding challenges into target group elements, then verify everything at once.

> **Note:** Dory is one of the more advanced commitment schemes covered in this book. The two-tier structure, pairing-based folding, and binding arguments involve subtle cryptographic reasoning. Don't worry if the details don't click on first reading; the key intuition is that pairings allow verification to happen "in the target group" without the verifier touching the original generators directly.

### Two-Tier Commitment Structure

Dory commits to polynomials using AFGHO commitments (Abe et al.'s structure-preserving commitments) combined with Pedersen commitments.

**Public parameters (SRS):** Generated transparently by sampling random group elements (the notation $\xleftarrow{\$}$ means "sampled uniformly at random from"):
- $\Gamma_1 \xleftarrow{\$} \mathbb{G}_1^{\sqrt{N}}$: commitment key for row commitments
- $\Gamma_2 \xleftarrow{\$} \mathbb{G}_2^{\sqrt{N}}$: commitment key for final commitment
- $H_1 \xleftarrow{\$} \mathbb{G}_1$, $H_2 \xleftarrow{\$} \mathbb{G}_2$: blinding generators (for hiding/zero-knowledge)
- $H_T = e(H_1, H_2)$: derived blinding generator in $\mathbb{G}_T$

All parameters are **public**. The prover's secrets are the blinding factors $r_i, r_{\text{fin}} \in \mathbb{F}$.

**Tier 1: Row Commitments ($\mathbb{G}_1$)**

Treat the polynomial coefficients as a $\sqrt{N} \times \sqrt{N}$ matrix $M$. For each row $i$, compute a Pedersen commitment:

$$R_i = \langle M[i], \Gamma_1 \rangle + r_i \cdot H_1 = \sum_{j=0}^{\sqrt{N}-1} M[i][j] \cdot \Gamma_1[j] + r_i \cdot H_1$$

where $r_i \in \mathbb{F}$ is a **secret** blinding factor. This produces $\sqrt{N}$ elements in $\mathbb{G}_1$.

**Tier 2: Final Commitment ($\mathbb{G}_T$)**

Combine row commitments via pairing with generators $\Gamma_2 \in \mathbb{G}_2^{\sqrt{N}}$:

$$C = \langle \vec{R}, \Gamma_2 \rangle_T + r_{\text{fin}} \cdot H_T = \sum_{i=0}^{\sqrt{N}-1} e(R_i, \Gamma_2[i]) + r_{\text{fin}} \cdot e(H_1, H_2)$$

where $r_{\text{fin}}$ is a final blinding factor. This produces one $\mathbb{G}_T$ element (the commitment).

**Why two tiers?**

| Tier | Purpose |
|------|---------|
| Tier 1 (rows) | Enables streaming: process row-by-row with $O(\sqrt{N})$ memory |
| | Row commitments serve as "hints" for efficient batch opening |
| Tier 2 ($\mathbb{G}_T$) | Provides succinctness: one element regardless of polynomial size |
| | Binding under SXDH assumption in Type III pairings |

The AFGHO commitment is hiding because $r_{\text{fin}} \cdot e(H_1, H_2)$ is uniformly random in $\mathbb{G}_T$. Both tiers are additively homomorphic, which is crucial for the evaluation protocol.

### From Coefficients to Matrix Form

**Why matrices?** A multilinear polynomial evaluation $f(r_1, \ldots, r_n)$ can be written as a vector-matrix-vector product. The evaluation point $(r_1, \ldots, r_n)$ splits into:
- Row coordinates $(r_1, \ldots, r_{n/2})$: selects which row
- Column coordinates $(r_{n/2+1}, \ldots, r_n)$: selects which column

This mirrors the coefficient arrangement: $M[i][j] = f(\text{bits of } i \| \text{bits of } j)$.

Each half determines a vector of **Lagrange coefficients** via the equality polynomial:

$$\ell_j = \text{eq}((r_1, \ldots, r_{n/2}), j) = \prod_{i=1}^{\log\sqrt{N}} \left( r_i \cdot j_i + (1 - r_i) \cdot (1 - j_i) \right)$$

$$\rho_j = \text{eq}((r_{n/2+1}, \ldots, r_n), j) = \prod_{i=1}^{\log\sqrt{N}} \left( r_{n/2+i} \cdot j_i + (1 - r_{n/2+i}) \cdot (1 - j_i) \right)$$

where $j_i \in \{0,1\}$ are the bits of index $j$. We use $\ell$ for row (left) and $\rho$ for column (right) coefficients, distinct from the evaluation point $r$.

The evaluation becomes a bilinear form:

$$f(r) = \sum_{i,j} M[i][j] \cdot \ell_i \cdot \rho_j = \vec{\ell}^T M \vec{\rho}$$

**Worked example ($n=2$):** For $f(x_1, x_2) = c_{00}(1-x_1)(1-x_2) + c_{01}(1-x_1)x_2 + c_{10}x_1(1-x_2) + c_{11}x_1x_2$:

$$f(r_1, r_2) = \underbrace{(1-r_1, r_1)}_{\vec{\ell}^T} \begin{pmatrix} c_{00} & c_{01} \\ c_{10} & c_{11} \end{pmatrix} \underbrace{\begin{pmatrix} 1-r_2 \\ r_2 \end{pmatrix}}_{\vec{\rho}}$$

### The Opening Protocol (Dory-Innerproduct)

**The key reduction:** Polynomial evaluation becomes an inner product. Define two vectors:

- $\vec{v}_1 = M \cdot \vec{\rho}$, the matrix times the column Lagrange vector. Each entry $(v_1)_j = \langle M[j], \vec{\rho} \rangle$ is row $j$ evaluated at the column coordinates.
- $\vec{v}_2 = \vec{\ell}$, the row Lagrange vector.

Then $\langle \vec{v}_1, \vec{v}_2 \rangle = \vec{\ell}^T M \vec{\rho} = f(r)$. The inner product of these two vectors *is* the polynomial evaluation.

**Goal:** Prove $\langle \vec{v}_1, \vec{v}_2 \rangle = v$ for committed vectors, which proves $f(r) = v$ for the polynomial.

**The Language:** Dory proves membership in:

$$\mathcal{L}_{n,\Gamma_1,\Gamma_2,H_1,H_2} = \{(C, D_1, D_2) : \exists (\vec{v}_1, \vec{v}_2, r_C, r_{D_1}, r_{D_2}) \text{ s.t.}$$
$$D_1 = \langle \vec{v}_1, \Gamma_2 \rangle + r_{D_1} H_T, \quad D_2 = \langle \Gamma_1, \vec{v}_2 \rangle + r_{D_2} H_T, \quad C = \langle \vec{v}_1, \vec{v}_2 \rangle + r_C H_T\}$$

In words: $D_1$ commits to $\vec{v}_1$ (using $\Gamma_2$), $D_2$ commits to $\vec{v}_2$ (using $\Gamma_1$), and $C$ commits to their inner product. The protocol proves these three commitments are consistent, that the same vectors appear in all three.

### How Verification Works (The Key Insight)

**The question:** The prover knows $\vec{\ell}$, $\vec{\rho}$, and $M$. The verifier can compute $\vec{\ell}$ and $\vec{\rho}$ from the evaluation point, but doesn't know $M$. How can the verifier check $f(r) = v$ without the matrix?

**The answer:** The verifier never needs $M$ directly. Instead:

**Step 1: The verifier has** the commitment $C$ (which encodes $M$ cryptographically) and the claimed evaluation $v$.

**Step 2: The prover sends a VMV message** $(C_{\text{vmv}}, D_2, E_1)$ where:

- $C_{\text{vmv}} = e(\langle \vec{R}, \vec{v}_1 \rangle, H_2)$
- $D_2 = e(\langle \Gamma_1, \vec{v}_1 \rangle, H_2)$
- $E_1 = \langle \vec{R}, \vec{\ell} \rangle$ (row commitments combined with row Lagrange coefficients)

Recall $\vec{v}_1 = M \cdot \vec{\rho}$ from earlier. This is the non-hiding variant; the row commitments $\vec{R}$ already contain blinding from tier 1.

**Step 3: First verification check.** The verifier checks:

$$e(E_1, H_2) \stackrel{?}{=} D_2$$

**Why this works:** By Pedersen linearity:

$$E_1 = \langle \vec{R}, \vec{\ell} \rangle = \sum_i \ell_i \cdot R_i = \sum_i \ell_i \cdot \langle M[i], \Gamma_1 \rangle = \langle \vec{\ell}^T M, \Gamma_1 \rangle$$

Note that $\vec{\ell}^T M$ is a row vector, while $\vec{v}_1 = M \cdot \vec{\rho}$ is a column vector. However, both represent "partial evaluations" of the matrix. The key point: $E_1$ is determined by the row commitments and Lagrange coefficients. The check $e(E_1, H_2) = D_2$ verifies that the prover's $D_2$ is consistent with the row commitments $\vec{R}$. This binds the prover's intermediate computation to the committed polynomial.

**Step 4: The verifier computes $E_2 = H_2 \cdot v$** (not from the prover).

The verifier computes this themselves from the claimed evaluation $v$. This is how the claimed value enters the protocol: it's bound to the blinding generator $H_2$. If the prover lied about $v = f(r)$, then $E_2$ won't match the prover's internal computation, and the final check will fail.

**Step 5: Initialize verifier state.**

- $C \leftarrow C_{\text{vmv}}$ (from VMV message)
- $D_1 \leftarrow$ the polynomial commitment (the tier-2 commitment the verifier already has)
- $D_2 \leftarrow$ from VMV message
- $E_1, E_2$ as computed above

**What remains to prove:** The prover must demonstrate that $\langle \vec{v}_2, \vec{v}_1 \rangle = v$. That is, the intermediate vector $\vec{v}_1$ (committed implicitly via the consistency check) inner-producted with $\vec{v}_2 = \vec{\ell}$ yields the claimed evaluation. This is where Dory-Reduce takes over.

### The Folding Protocol (Dory-Reduce)

Each round halves the problem size. Given vectors of length $2m$, the round uses two challenges ($\beta$, then $\alpha$) and two prover messages:

**First message** (before any challenge):

- $D_{1L} = \langle \vec{v}_{1L}, \Gamma_2' \rangle$, $D_{1R} = \langle \vec{v}_{1R}, \Gamma_2' \rangle$ (cross-pairings of $\vec{v}_1$ halves with generator halves)
- $D_{2L} = \langle \Gamma_1', \vec{v}_{2L} \rangle$, $D_{2R} = \langle \Gamma_1', \vec{v}_{2R} \rangle$ (cross-pairings of $\vec{v}_2$ halves with generator halves)

**Verifier sends first challenge** $\beta \stackrel{\$}{\leftarrow} \mathbb{F}$

**Prover updates vectors**:

- $\vec{v}_1 \leftarrow \vec{v}_1 + \beta \cdot \Gamma_1$
- $\vec{v}_2 \leftarrow \vec{v}_2 + \beta^{-1} \cdot \Gamma_2$

**Second message** (computed with $\beta$-modified vectors):

- $C_+ = \langle \vec{v}_{1L}, \vec{v}_{2R} \rangle$, $C_- = \langle \vec{v}_{1R}, \vec{v}_{2L} \rangle$ (cross inner products of modified vectors)

**Verifier sends second challenge** $\alpha \stackrel{\$}{\leftarrow} \mathbb{F}$

**Prover folds vectors:**

- $\vec{v}_1' = \alpha \vec{v}_{1L} + \vec{v}_{1R}$
- $\vec{v}_2' = \alpha^{-1} \vec{v}_{2L} + \vec{v}_{2R}$

**Verifier updates accumulators** (no pairing checks, just $\mathbb{G}_T$ arithmetic):

- $C' = C + \chi_k + \beta D_2 + \beta^{-1} D_1 + \alpha C_+ + \alpha^{-1} C_-$
- $D_1' = \alpha D_{1L} + D_{1R}$
- $D_2' = \alpha^{-1} D_{2L} + D_{2R}$

where $\chi_k = e(\Gamma_1[0..2^k], \Gamma_2[0..2^k])$ is a **precomputed SRS value** (the pairing of generator prefixes at round $k$).

**Recurse** with vectors of length $m$.

After $\log(\sqrt{N})$ rounds, vectors have length 1.

**Final pairing check:** After all rounds:

$$e(E_1' + d \cdot \Gamma_{1,0}, E_2' + d^{-1} \cdot \Gamma_{2,0}) = C' + \chi_0 + d \cdot D_2' + d^{-1} \cdot D_1'$$

where primes denote folded values, and $d$ is a final challenge.

**The invariant:** Throughout folding, $(C, D_1, D_2)$ satisfy:

- $C = \langle \vec{v}_1, \vec{v}_2 \rangle$ (inner product commitment)
- $D_1 = \langle \vec{v}_1, \Gamma_2 \rangle$, $D_2 = \langle \Gamma_1, \vec{v}_2 \rangle$ (commitments to each vector)

The verifier does no per-round pairing checks, only accumulator updates. Soundness comes from the final check verifying this invariant for the length-1 vectors.

### Why Binding Works

The prover provides row commitments $\vec{R}$ alongside the tier-2 commitment. Why can't the prover cheat by providing fake rows?

1. **Tier 2 constrains Tier 1:** The tier-2 commitment $C = \langle \vec{R}, \Gamma_2 \rangle_T + r_{\text{fin}} H_T$ is a deterministic function of the row commitments. Changing any $R_i$ changes $C$.

2. **Tier 1 constrains the data:** Each $R_i = \langle M[i], \Gamma_1 \rangle + r_i H_1$ is a Pedersen commitment. Under discrete log hardness, the prover cannot find two different row vectors that produce the same $R_i$.

3. **No trapdoor:** The SRS generators are sampled randomly. Without their discrete logs, the prover is computationally bound to the original coefficients.

If the Dory proof verifies, then with overwhelming probability (under SXDH), the prover knew valid openings for all original commitments.

### Dory: Properties and Trade-offs

| Property | Dory |
|----------|------|
| Trusted setup | **None (Transparent)** |
| Commitment size | $O(1)$ (one $\mathbb{G}_T$ element) |
| Proof size | $O(\log N)$ group elements |
| Verification time | **$O(\log N)$** (the key improvement!) |
| Prover time | $O(N)$ for commitment, $O(\sqrt{N})$ per opening |
| Assumption | SXDH (on Type III pairings) |
| Quantum-safe | No (uses pairings) |

Dory uses pairings (like KZG) but achieves transparency (like IPA). It gets logarithmic verification (better than IPA's linear) at the cost of more complex pairing machinery. This makes Dory particularly attractive for systems with many polynomial openings that can be batched (like Jolt's zkVM), where the amortized cost per opening becomes very small.

Implementations like Jolt store row commitments $\vec{R} \in \mathbb{G}_1^{\sqrt{N}}$ as "opening hints." This increases proof size by $O(\sqrt{N})$ per polynomial but enables efficient batch opening without recomputing expensive MSMs. For Jolt's ~26 committed polynomials with $N = 2^{20}$, this means ~26 KB of hints instead of ~800 bytes, but saves massive computation during batch verification.

Batching multiple polynomials exploits Pedersen's homomorphism. When batching $k$ polynomials with random linear combination coefficient $\gamma$, we combine corresponding rows across all polynomials:

$$R^{(\text{joint})}_j = \sum_{i=1}^{k} \gamma^i \cdot R^{(i)}_j$$

Row $j$ of $f_{\text{joint}} = \sum_i \gamma^i f_i$ has coefficients $M_{\text{joint}}[j] = \sum_i \gamma^i M_i[j]$. By linearity of Pedersen commitments, $\langle M_{\text{joint}}[j], \Gamma_1 \rangle = \sum_i \gamma^i R^{(i)}_j = R^{(\text{joint})}_j$. The joint row commitments feed directly into Dory-Reduce, avoiding $k \cdot \sqrt{N}$ expensive MSM recomputations.

### Why Dory Achieves Logarithmic Verification

Why does Dory achieve logarithmic verification while IPA requires linear time? IPA's linear cost comes from computing folded generators. Dory sidesteps this entirely: the verifier works with commitments in $\mathbb{G}_T$, updating accumulators each round without touching generators. The algebraic structure of pairings ($e(aG_1, bG_2) = e(G_1, G_2)^{ab}$) lets the verifier "absorb" folding challenges into commitments. The precomputed $\chi_k$ values handle the generator contributions.

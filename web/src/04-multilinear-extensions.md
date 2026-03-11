# Chapter 4: Multilinear Extensions

In 1971, the Mariner 9 probe became the first spacecraft to orbit another planet. Its mission: map the surface of Mars. But transmitting high-resolution images across 100 million miles of static-filled space was a nightmare. A single burst of cosmic noise could turn a crater into a glitch.

NASA didn't send raw pixels. They used a code developed years earlier by Irving Reed and David Muller: treat the pixel data as evaluations of a *multivariate polynomial*. The Reed-Muller code could correct up to seven bit errors per 32-bit word. When Mariner 9 arrived to find Mars engulfed in a planet-wide dust storm, mission control reprogrammed the spacecraft from Earth and waited. When the dust cleared, the code delivered 7,329 images, mapping 85% of the Martian surface.

Why not Reed-Solomon? In Chapter 2, we encoded $n$ values as a univariate polynomial of degree $n-1$. That works when $n$ is modest. But Mariner's data was indexed by *bit positions*: a 32-bit word has $2^5$ bit combinations, a memory address space has $2^{64}$ locations, a boolean formula with 100 variables has $2^{100}$ possible assignments. Encoding $2^{100}$ values as a univariate polynomial means degree $2^{100} - 1$. Impossible.

The solution: let each bit be its own variable. A 100-bit index becomes 100 coordinates, each 0 or 1. The polynomial has 100 variables instead of degree $2^{100}$. Data lives not on a line but on a hypercube. This chapter develops that theory.

---

In Chapter 2, we turned data into polynomials via Lagrange interpolation: given $n$ values, construct the unique degree-$(n-1)$ univariate polynomial passing through them. That was interpolation over a *line*.

Now we need interpolation over a *hypercube*. The data lives at $2^n$ vertices, indexed by bit strings. The polynomial must agree with the data at these vertices and extend smoothly to all of $\mathbb{F}^n$. The construction is analogous to univariate Lagrange, but the geometry is different, and the efficiency implications are dramatic.

This chapter develops the theory of **multilinear extensions**: the canonical way to extend functions from the Boolean hypercube $\{0,1\}^n$ to polynomials over $\mathbb{F}^n$. These extensions are the workhorses of sum-check-based proof systems, encoding everything from circuit wire values to constraint satisfaction.



## The Boolean Hypercube

Consider the set $\{0,1\}^n$, all $n$-bit binary strings. This is the **Boolean hypercube**, and it contains exactly $2^n$ points.

```
n = 2:
    (1,1)
     /  \
 (0,1)  (1,0)
     \  /
    (0,0)

n = 3: A cube with 8 vertices
```

Any function $f: \{0,1\}^n \to \mathbb{F}$ assigns a field element to each vertex of this hypercube. There are $2^n$ vertices, so $f$ is essentially a table of $2^n$ values.

For example:

- A vector $(v_1, \ldots, v_{2^n})$ can be viewed as $f(b) = v_{1 + \text{bin}(b)}$ where $\text{bin}(b)$ converts the bit string to an index

- The output values of a layer of circuit gates

- A database of $2^n$ records indexed by $n$-bit keys

Why does the hypercube matter? Because computation is fundamentally boolean. A memory address is a bit string. A circuit's inputs are bits. A satisfying assignment to a boolean formula is a point in $\{0,1\}^n$. When we want to verify a computation, the objects we care about—wire values, memory contents, constraint satisfaction—are naturally indexed by binary strings. The hypercube $\{0,1\}^n$ is where computational problems live.

But polynomials live over fields, not just $\{0,1\}$. We want a polynomial that agrees with $f$ on the hypercube but extends smoothly to all of $\mathbb{F}^n$. This extension is what lets us apply the algebraic machinery (Schwartz-Zippel, sum-check) that makes verification efficient.



## Why Multilinear?

In Chapter 2, we used univariate polynomials (Reed-Solomon). Why switch to multivariate now?

The problem with univariate encoding is degree: if you encode $N = 2^{20}$ data points into a single-variable polynomial $p(x)$, that polynomial has degree about one million. Manipulating degree-million polynomials is expensive, requiring heavy FFT operations.

Multilinear polynomials avoid this. If you encode the same $2^{20}$ points into a 20-variable multilinear polynomial, the degree in each variable is just 1. The total degree is only 20. By increasing the number of variables, we drastically lower the per-variable degree. This tradeoff (more variables, lower degree) enables the linear-time prover algorithms that power modern systems like HyperPlonk and Lasso, avoiding the expensive FFTs required by univariate approaches.

A polynomial in $n$ variables has terms like $X_1^{a_1} X_2^{a_2} \cdots X_n^{a_n}$ with various exponents. The **degree** in variable $X_i$ is the maximum exponent of $X_i$ across all terms.

A polynomial is **multilinear** if its degree in every variable is at most 1. Every term looks like a product of distinct variables (or subsets thereof). We write $\tilde{f}$ (with a tilde) to denote the multilinear extension of a function $f$:

$$\tilde{f}(X_1, \ldots, X_n) = \sum_{S \subseteq \{1,\ldots,n\}} c_S \prod_{i \in S} X_i$$

For example, with $n = 2$:
$$\tilde{f}(X_1, X_2) = c_\emptyset + c_{\{1\}} X_1 + c_{\{2\}} X_2 + c_{\{1,2\}} X_1 X_2$$

There are $2^n$ possible subsets $S$, hence $2^n$ coefficients. A multilinear polynomial in $n$ variables is fully specified by $2^n$ numbers, exactly matching the number of points in the hypercube.

This is not a coincidence. It's the key theorem:

**Theorem (Multilinear Extension).** For any function $f: \{0,1\}^n \to \mathbb{F}$, there exists a unique multilinear polynomial $\tilde{f}: \mathbb{F}^n \to \mathbb{F}$ such that $\tilde{f}(b) = f(b)$ for all $b \in \{0,1\}^n$.

The function $\tilde{f}$ is called the **multilinear extension (MLE)** of $f$.



## Constructing the Multilinear Extension

The theorem claims uniqueness. How do we actually construct $\tilde{f}$?

### The Lagrange Basis

For each point $w \in \{0,1\}^n$, define the **Lagrange basis polynomial**:

$$L_w(X) = \prod_{i=1}^{n} \left( w_i \cdot X_i + (1 - w_i)(1 - X_i) \right)$$

Here $w = (w_1, \ldots, w_n)$ is a fixed boolean vector, where each $w_i \in \{0,1\}$. You can read $w$ as the binary representation of an index from 0 to $2^n - 1$, addressing one of the $2^n$ vertices of the hypercube. Meanwhile $X = (X_1, \ldots, X_n)$ is a vector of formal variables where each $X_i$ ranges over all of $\mathbb{F}$. Geometrically, $w$ lives at a corner of the unit hypercube, while $X$ can be any point in $\mathbb{F}^n$, including points "between" corners. The polynomial $L_w$ is defined over all of $\mathbb{F}^n$, but it has a special property on the hypercube: it equals 1 at $w$ and 0 at every other boolean point.

To see why, consider what happens at point $w$:

- If $w_i = 1$: the factor is $1 \cdot X_i + 0 \cdot (1 - X_i) = X_i$, which evaluates to $1$

- If $w_i = 0$: the factor is $0 \cdot X_i + 1 \cdot (1 - X_i) = 1 - X_i$, which evaluates to $1$

Every factor equals 1, so $L_w(w) = 1$.

At any other point $b \neq w$:

- There exists some coordinate $i$ where $b_i \neq w_i$

- If $w_i = 1$ and $b_i = 0$: the factor $X_i$ evaluates to $0$

- If $w_i = 0$ and $b_i = 1$: the factor $1 - X_i$ evaluates to $0$

One factor is zero, so $L_w(b) = 0$.

### The Extension Formula

The multilinear extension is now simply:

$$\tilde{f}(X) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(X)$$

At any hypercube point $b$:
$$\tilde{f}(b) = \sum_w f(w) \cdot L_w(b) = f(b) \cdot 1 + \sum_{w \neq b} f(w) \cdot 0 = f(b)$$

The extension agrees with $f$ on the hypercube. Since it's a sum of multilinear terms (each $L_w$ is multilinear), $\tilde{f}$ is multilinear.

### Uniqueness

**Claim**: If a multilinear polynomial $p$ vanishes on all of $\{0,1\}^n$, then $p \equiv 0$.

*Proof by induction on $n$*:

**Base case** ($n=1$): A multilinear polynomial in one variable has form $p(X) = a + bX$. If $p(0) = 0$ and $p(1) = 0$, then $a = 0$ and $a + b = 0$, so $b = 0$. Thus $p \equiv 0$.

**Inductive step**: Write $p(X_1, \ldots, X_n) = q_0(X_2, \ldots, X_n) + X_1 \cdot q_1(X_2, \ldots, X_n)$ where $q_0, q_1$ are multilinear in $n-1$ variables. Evaluating at $X_1 = 0$: $p(0, X_2, \ldots, X_n) = q_0(X_2, \ldots, X_n)$. Since $p$ vanishes on all of $\{0,1\}^n$, in particular $q_0$ vanishes on $\{0,1\}^{n-1}$. By induction, $q_0 \equiv 0$. Similarly, $p(1, X_2, \ldots, X_n) = q_1(X_2, \ldots, X_n)$ vanishes on $\{0,1\}^{n-1}$, so $q_1 \equiv 0$. Thus $p \equiv 0$. $\square$

**Corollary**: If two multilinear polynomials agree on $\{0,1\}^n$, their difference vanishes there, hence is identically zero, so they are equal.



## The Equality Polynomial

One Lagrange basis polynomial deserves special attention: the **equality polynomial**.

$$\widetilde{\text{eq}}(X, Y) = \prod_{i=1}^{n} \left( X_i Y_i + (1 - X_i)(1 - Y_i) \right)$$

This is the MLE of the equality function:
$$\text{eq}(a, b) = \begin{cases} 1 & \text{if } a = b \\ 0 & \text{otherwise} \end{cases}$$

for $a, b \in \{0,1\}^n$.

The Lagrange basis polynomials are just the equality polynomial with one input fixed:
$$L_w(X) = \widetilde{\text{eq}}(w, X)$$

The equality polynomial appears constantly in sum-check-based protocols, through the identity:

$$\sum_{x \in \{0,1\}^n} \widetilde{\text{eq}}(\tau, x) \cdot f(x) = \widetilde{f}(\tau)$$

This follows directly from the Lagrange formula: $\widetilde{f}(\tau) = \sum_x f(x) \cdot L_x(\tau) = \sum_x f(x) \cdot \widetilde{\text{eq}}(\tau, x)$. Summing $f$ weighted by $\widetilde{\text{eq}}(\tau, \cdot)$ over the hypercube gives the MLE of $f$ evaluated at $\tau$. This means evaluating an MLE at a random challenge $\tau$ reduces to a sum-check on $g(x) = \widetilde{\text{eq}}(\tau, x) \cdot f(x)$.

This immediately gives a powerful zero test. Suppose the verifier wants to check that $f$ vanishes on the entire Boolean hypercube. By the identity above, checking that all $f(x)$ values are zero is the same as checking that $\widetilde{f}(\tau) = 0$. The verifier picks a random $\tau \in \mathbb{F}^n$ and runs sum-check on:

$$\sum_{x \in \{0,1\}^n} \widetilde{\text{eq}}(\tau, x) \cdot f(x) = 0$$

This is a random linear combination of all $f(x)$ values. If $f$ truly vanishes on the hypercube, then $\widetilde{f} \equiv 0$ (by the uniqueness theorem above), so the sum is always 0. If even one value $f(x^*) \neq 0$, then $\widetilde{f}$ is a nonzero multilinear polynomial, and Schwartz-Zippel guarantees $\widetilde{f}(\tau) \neq 0$ with probability at least $1 - n/|\mathbb{F}|$. Over a 254-bit field, this is negligible. This "zero-on-hypercube" test is the foundation of Spartan and related sum-check-based proof systems.



## Worked Example: A 2-Variable Function

Let's trace through a complete example.

Consider $f: \{0,1\}^2 \to \mathbb{F}$ defined by the table:

| $(X_1, X_2)$ | $f(X_1, X_2)$ |
|--------------|---------------|
| $(0, 0)$     | $3$           |
| $(0, 1)$     | $7$           |
| $(1, 0)$     | $2$           |
| $(1, 1)$     | $5$           |

The Lagrange basis polynomials are:

$$L_{(0,0)}(X) = (1 - X_1)(1 - X_2)$$
$$L_{(0,1)}(X) = (1 - X_1) \cdot X_2$$
$$L_{(1,0)}(X) = X_1 \cdot (1 - X_2)$$
$$L_{(1,1)}(X) = X_1 \cdot X_2$$

The multilinear extension is then:

$$\tilde{f}(X_1, X_2) = 3 \cdot (1-X_1)(1-X_2) + 7 \cdot (1-X_1)X_2 + 2 \cdot X_1(1-X_2) + 5 \cdot X_1 X_2$$

Expanding:

$$= 3(1 - X_1 - X_2 + X_1 X_2) + 7(X_2 - X_1 X_2) + 2(X_1 - X_1 X_2) + 5 X_1 X_2$$
$$= 3 - 3X_1 - 3X_2 + 3X_1X_2 + 7X_2 - 7X_1X_2 + 2X_1 - 2X_1X_2 + 5X_1X_2$$
$$= 3 + (-3 + 2)X_1 + (-3 + 7)X_2 + (3 - 7 - 2 + 5)X_1X_2$$
$$= 3 - X_1 + 4X_2 - X_1X_2$$

We can verify this matches the table:

- $\tilde{f}(0,0) = 3 - 0 + 0 - 0 = 3$ (matches)

- $\tilde{f}(0,1) = 3 - 0 + 4 - 0 = 7$ (matches)

- $\tilde{f}(1,0) = 3 - 1 + 0 - 0 = 2$ (matches)

- $\tilde{f}(1,1) = 3 - 1 + 4 - 1 = 5$ (matches)

What happens at a non-boolean point? Evaluating at $(0.5, 0.3)$:
$$\tilde{f}(0.5, 0.3) = 3 - 0.5 + 4(0.3) - (0.5)(0.3) = 3 - 0.5 + 1.2 - 0.15 = 3.55$$

This value has no "meaning" on the hypercube; $(0.5, 0.3)$ isn't a Boolean point. But this is exactly what we want: the polynomial is defined everywhere, and random evaluation is the key to probabilistic verification.



## Efficient Evaluation

Given the table of values $\{f(w) : w \in \{0,1\}^n\}$ and a query point $r \in \mathbb{F}^n$, how fast can we compute $\tilde{f}(r)$?

The naive approach sums over all $2^n$ terms:
$$\tilde{f}(r) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(r)$$

Each $L_w(r)$ takes $O(n)$ to compute. Total: $O(n \cdot 2^n)$.

We can do better with streaming evaluation. $\tilde{f}(r)$ is computable in $O(2^n)$ time with the following observation.

Define $T_k$ as the "partial extension" using only the first $k$ variables of $r$:

$$T_k(x_{k+1}, \ldots, x_n) = \sum_{(b_1, \ldots, b_k) \in \{0,1\}^k} f(b_1, \ldots, b_k, x_{k+1}, \ldots, x_n) \cdot \prod_{i=1}^{k} L_{b_i}(r_i)$$

At $k = 0$: $T_0 = f$ (the original table).

At $k = n$: $T_n = \tilde{f}(r)$ (a single value).

The recursion from $T_k$ to $T_{k+1}$:

$$T_{k+1}(x_{k+2}, \ldots, x_n) = (1 - r_{k+1}) \cdot T_k(0, x_{k+2}, \ldots) + r_{k+1} \cdot T_k(1, x_{k+2}, \ldots)$$

Each step halves the table size. Total work: $2^n + 2^{n-1} + \cdots + 1 = O(2^n)$.

This is linear in the table size, optimal for any algorithm that must touch all values.

### Worked Example: Streaming Evaluation

Let's trace through this algorithm with our earlier function $f: \{0,1\}^2 \to \mathbb{F}$:

| $(b_1, b_2)$ | $f(b_1, b_2)$ |
|--------------|---------------|
| $(0, 0)$     | $3$           |
| $(0, 1)$     | $7$           |
| $(1, 0)$     | $2$           |
| $(1, 1)$     | $5$           |

We want to compute $\tilde{f}(r_1, r_2)$ at the point $r = (0.4, 0.7)$.

**Step 0: Initialize $T_0$**

$T_0$ is just the original table, a function of both variables:
$$T_0(x_1, x_2) = f(x_1, x_2)$$

Think of it as four values indexed by $(x_1, x_2) \in \{0,1\}^2$:
$$T_0 = \begin{array}{c|cc} & x_2=0 & x_2=1 \\ x_1=0 & 3 & 7 \\ x_1=1 & 2 & 5 \end{array}$$

**Step 1: Compute $T_1$ by "folding in" $r_1 = 0.4$**

The recursion says:
$$T_1(x_2) = (1 - r_1) \cdot T_0(0, x_2) + r_1 \cdot T_0(1, x_2)$$

This is a weighted combination of the two rows, using $1 - r_1 = 0.6$ and $r_1 = 0.4$:

- $T_1(0) = 0.6 \cdot T_0(0,0) + 0.4 \cdot T_0(1,0) = 0.6 \cdot 3 + 0.4 \cdot 2 = 1.8 + 0.8 = 2.6$

- $T_1(1) = 0.6 \cdot T_0(0,1) + 0.4 \cdot T_0(1,1) = 0.6 \cdot 7 + 0.4 \cdot 5 = 4.2 + 2.0 = 6.2$

The table has shrunk from 4 values to 2 values: $T_1 = [2.6, 6.2]$.

**Step 2: Compute $T_2$ by "folding in" $r_2 = 0.7$**

$$T_2 = (1 - r_2) \cdot T_1(0) + r_2 \cdot T_1(1) = 0.3 \cdot 2.6 + 0.7 \cdot 6.2 = 0.78 + 4.34 = 5.12$$

The table has shrunk from 2 values to 1 value. This single value is $\tilde{f}(0.4, 0.7) = 5.12$.

We can verify using the explicit formula $\tilde{f}(X_1, X_2) = 3 - X_1 + 4X_2 - X_1X_2$:
$$\tilde{f}(0.4, 0.7) = 3 - 0.4 + 4(0.7) - (0.4)(0.7) = 3 - 0.4 + 2.8 - 0.28 = 5.12 \checkmark$$

This works because the Lagrange basis polynomial factorizes into independent pieces, one per coordinate:
$$L_{(b_1, b_2)}(r_1, r_2) = L_{b_1}(r_1) \cdot L_{b_2}(r_2)$$

where $L_0(r) = 1 - r$ and $L_1(r) = r$ are univariate selectors. This factorization holds because the multilinear Lagrange formula is a *product* over coordinates:

$$L_w(X) = \prod_{i=1}^{n} \left( w_i \cdot X_i + (1 - w_i)(1 - X_i) \right)$$

Each factor depends only on one coordinate of $w$ and one coordinate of $X$. So evaluating at $(r_1, r_2)$ gives a product of independent terms.

The algorithm exploits this factorization. The MLE evaluation is:
$$\tilde{f}(r_1, r_2) = \sum_{b_1, b_2 \in \{0,1\}} f(b_1, b_2) \cdot L_{b_1}(r_1) \cdot L_{b_2}(r_2)$$

Rearranging the sum (grouping by $b_2$):
$$= \sum_{b_2} L_{b_2}(r_2) \cdot \underbrace{\left( \sum_{b_1} f(b_1, b_2) \cdot L_{b_1}(r_1) \right)}_{T_1(b_2)}$$

The inner sum is exactly what Step 1 computes: for each value of $b_2$, it combines the two $b_1$ cases using weights $L_0(r_1) = 1 - r_1$ and $L_1(r_1) = r_1$. The result $T_1$ has half as many entries. Step 2 then folds in the $r_2$ weights similarly.

An analogy helps here: think of a single-elimination tournament with $2^n$ players. In each round, pairs compete and half are eliminated. After $n$ rounds, one champion remains. The streaming algorithm works the same way: $2^n$ table entries enter, each round uses a random weight to combine pairs, and after $n$ rounds a single evaluation emerges. The tournament bracket is the structure of multilinear computation.

This pattern of using a random challenge to collapse pairs of values and halving the problem size will reappear throughout this book. In Chapter 10 (FRI), we'll name it **folding** and see it as one of the central techniques in zero-knowledge proofs.

### Code: Streaming MLE Evaluation

The algorithm above translates directly to code. Each coordinate of $r$ folds the table in half.

```python
def mle_eval(table, r):
    """
    Evaluate the multilinear extension of `table` at point `r`.

    Args:
        table: List of 2^n field elements (the function values on hypercube)
        r: Tuple of n coordinates (r_1, ..., r_n)

    Returns: The value of the MLE at r
    """
    T = table.copy()

    for r_i in r:
        half = len(T) // 2
        # Fold: T'[j] = (1 - r_i) * T[2j] + r_i * T[2j+1]
        T = [(1 - r_i) * T[2*j] + r_i * T[2*j + 1]
             for j in range(half)]

    return T[0]  # Single value remains

# Example from the worked example above
table = [3, 7, 2, 5]  # f(0,0)=3, f(0,1)=7, f(1,0)=2, f(1,1)=5
r = (0.4, 0.7)

result = mle_eval(table, r)
print(f"Streaming: MLE({r}) = {result}")

# Verify against explicit formula: f(X1,X2) = 3 - X1 + 4*X2 - X1*X2
explicit = 3 - 0.4 + 4*0.7 - 0.4*0.7
print(f"Explicit:  MLE({r}) = {explicit}")
```

Output:
```
Streaming: MLE((0.4, 0.7)) = 5.12
Explicit:  MLE((0.4, 0.7)) = 5.12
```

The streaming algorithm touches each table entry exactly once. For a table of size $N = 2^n$, total work is $N/2 + N/4 + \cdots + 1 = N - 1 = O(N)$.



## Tensor Product Structure

The factorization we used in the streaming algorithm generalizes to any number of variables. For $w = (w_1, \ldots, w_n) \in \{0,1\}^n$:

$$L_w(r_1, \ldots, r_n) = \prod_{i=1}^{n} L_{w_i}(r_i)$$

where $L_0(r_i) = 1 - r_i$ and $L_1(r_i) = r_i$.

This is a **tensor product** structure. To see what this means concretely, consider $n = 2$. Define the vectors:

$$\vec{v}_1 = (L_0(r_1), L_1(r_1)) = (1 - r_1, r_1)$$
$$\vec{v}_2 = (L_0(r_2), L_1(r_2)) = (1 - r_2, r_2)$$

Their tensor product $\vec{v}_1 \otimes \vec{v}_2$ is the $2 \times 2$ matrix (or equivalently, length-4 vector) of all pairwise products:

$$\vec{v}_1 \otimes \vec{v}_2 = \begin{pmatrix} (1-r_1)(1-r_2) & (1-r_1)r_2 \\ r_1(1-r_2) & r_1 r_2 \end{pmatrix}$$

Reading off the entries: $L_{(0,0)}(r), L_{(0,1)}(r), L_{(1,0)}(r), L_{(1,1)}(r)$. The tensor product *is* the vector of Lagrange evaluations.

For general $n$, the vector of all $2^n$ Lagrange evaluations is:

$$(L_0(r_1), L_1(r_1)) \otimes (L_0(r_2), L_1(r_2)) \otimes \cdots \otimes (L_0(r_n), L_1(r_n))$$

The streaming algorithm exploits this tensor structure. Instead of computing all $2^n$ Lagrange values (expensive), it processes one coordinate at a time, folding the tensor product incrementally. This is why MLE evaluation costs $O(2^n)$ instead of $O(n \cdot 2^n)$. The same tensor structure enables:

- Efficient prover algorithms for sum-check (Chapter 19)

- Recursive proof constructions

- Memory-efficient streaming over large tables



## Multilinear Extensions of Functions on Larger Domains

What if our function isn't defined on $\{0,1\}^n$?

Suppose $f: \{0, 1, \ldots, m-1\} \to \mathbb{F}$ for some $m = 2^n$. We can *interpret* the domain as $\{0,1\}^n$ via binary encoding:

$$\tilde{f}(X_1, \ldots, X_n) = \text{MLE of } (k \mapsto f(k)) \text{ with } k = \sum_i 2^{i-1} X_i$$

Any function on a power-of-two domain has a natural multilinear extension.

For domains not of size $2^n$, we can pad with zeros or use more sophisticated encodings. The key insight: as long as the domain is *finite*, we can always encode it in binary and take the MLE.



## Connection to Sum-Check

The sum-check protocol (Chapter 3) proves claims of the form:

$$H = \sum_{b \in \{0,1\}^n} g(b)$$

for some polynomial $g$. When $g$ is the multilinear extension of a function $f$, this sum equals $\sum_{b \in \{0,1\}^n} f(b)$, the sum of all function values on the hypercube.

As an example, suppose we want to prove that a vector $(v_1, \ldots, v_N)$ with $N = 2^n$ sums to a claimed value $H$.

Let $\tilde{v}$ be the MLE encoding the vector. Then:
$$\sum_{b \in \{0,1\}^n} \tilde{v}(b) = \sum_{i=1}^{N} v_i = H$$

Sum-check verifies this identity without the verifier seeing all of $v$. The protocol reduces the sum to a single random evaluation $\tilde{v}(r)$, which the prover supplies (with a commitment proof).

This is the bridge from "data" to "proof": encode data as an MLE, verify properties via sum-check, bind via polynomial commitment.



## Evaluations and Coefficients

A perspective that clarifies many constructions:

A multilinear polynomial $\tilde{f}$ has $2^n$ coefficients (the $c_S$ values in the monomial expansion $\sum_S c_S \prod_{i \in S} X_i$). These coefficients live in an abstract "coefficient space."

But $\tilde{f}$ also has $2^n$ evaluations on the hypercube. These evaluations are just $f(w)$, the original table values you started with.

These are not the same numbers. The table entry $f(0,0) = 3$ in our worked example is not a coefficient of the polynomial. The polynomial $\tilde{f}(X_1, X_2) = 3 - X_1 + 4X_2 - X_1X_2$ has coefficients $\{3, -1, 4, -1\}$, while the table values are $\{3, 7, 2, 5\}$. They're related by the Lagrange interpolation formula.

For multilinear polynomials, the evaluation table *is* a complete description. You can recover coefficients from evaluations and vice versa. They're just two bases for the same $2^n$-dimensional vector space.

The transformation between bases is exactly the Lagrange interpolation formula and its inverse. Both can be computed in $O(2^n)$ time.

This means:

- Committing to a multilinear polynomial = committing to its evaluation table

- Evaluating at a random point = a linear combination of table entries

- Sum-check over an MLE = verifying global properties through local queries

The table has $2^n$ entries. The verifier touches $O(n)$ of them. The polynomial is what bridges the gap: it's a compressed representation that can be probed at random points, and those random probes reveal whether the full table satisfies the claimed property. Extension creates redundancy; redundancy enables compression; compression enables succinctness.

### Polynomial Evaluation as Inner Product

There's a beautiful way to see this algebraically: **polynomial evaluation is an inner product**.

For a multilinear polynomial, the evaluation at any point $r$ is:

$$\tilde{f}(r) = \sum_{w \in \{0,1\}^n} f(w) \cdot L_w(r) = \langle \vec{f}, \vec{L}(r) \rangle$$

where $\vec{f} = (f(w))_{w \in \{0,1\}^n}$ is the table of values and $\vec{L}(r) = (L_w(r))_{w \in \{0,1\}^n}$ is the vector of Lagrange basis evaluations at $r$.

This linear algebra perspective is surprisingly powerful. For decades, sum-check was seen as a beautiful theoretical result with limited practical use. Then came the realization: polynomial evaluation is an inner product, and inner products interact beautifully with commitment schemes. No FFTs, no trusted setups, just vectors and dot products. Systems like Spartan, HyperPlonk, and Lasso all exploit this insight. Chapter 19 tells the full story of this "Sum-Check Renaissance."

The consequences are immediate:

- **Commitment**: Committing to $\tilde{f}$ means committing to the vector $\vec{f}$
- **Evaluation proof**: Proving $\tilde{f}(r) = y$ means proving an inner product claim $\langle \vec{f}, \vec{L}(r) \rangle = y$
- **The verifier knows $\vec{L}(r)$**: Given $r$, anyone can compute the Lagrange evaluations

This reduces polynomial evaluation proofs to inner product proofs, and inner products interact beautifully with homomorphic commitments. We'll exploit this connection in Chapters 6 and 9.



## Key Takeaways

1. **The Boolean hypercube** $\{0,1\}^n$ is the natural domain for multilinear polynomials. It has $2^n$ points.

2. **Multilinear extension (MLE)**: The unique polynomial of degree at most 1 in each variable that agrees with $f$ on the hypercube.

3. **Lagrange basis polynomials** $L_w(X)$ equal 1 at $w$ and 0 elsewhere. The MLE is $\tilde{f}(X) = \sum_w f(w) \cdot L_w(X)$.

4. **The equality polynomial** $\widetilde{\text{eq}}(X, Y)$ is the MLE of the equality indicator. Lagrange bases are $L_w(X) = \widetilde{\text{eq}}(w, X)$.

5. **Tensor product structure**: $L_w(r) = \prod_i L_{w_i}(r_i)$. The basis factorizes, enabling fast algorithms.

6. **Efficient evaluation**: Given the table and a point, compute the MLE in $O(2^n)$ time via streaming.

7. **Sum over the hypercube**: $\sum_b \tilde{f}(b) = \sum_w f(w)$. Sum-check verifies such sums efficiently.

8. **Evaluations = coefficients**: For MLEs, the table of values completely determines the polynomial. They're dual representations.

9. **Binary encoding**: Any function on $\{0, \ldots, 2^n - 1\}$ can be encoded as a function on $\{0,1\}^n$, then extended multilinearly.

10. **The bridge to proofs**: MLEs encode data; sum-check verifies properties; polynomial commitment binds the prover. This trinity underlies sum-check-based SNARKs.

# Chapter 8: From Circuits to Polynomials

In 1931, Kurt Gödel shattered the foundations of mathematics. He proved that any formal system powerful enough to express arithmetic is "haunted": it contains true statements that cannot be proven. More precisely: if a formal system $F$ is *consistent* (it cannot prove both a statement and its negation) and capable of expressing basic arithmetic, then $F$ is *incomplete* (there exists a statement $G$ such that neither $G$ nor $\neg G$ is provable in $F$). To establish this, Gödel had to solve a technical nightmare: how do you make math talk about itself?

His solution was Gödel numbering. He assigned a unique integer to every logical symbol ($+$, $=$, $\forall$), turning logical statements into integers and logical proofs into arithmetic relationships between those integers. He turned logic into arithmetic so that arithmetic could reason about logic.

What we do in zero-knowledge proofs is a direct descendant of Gödel's trick. We take the logic of a computer program (loops, conditionals, memory access) and encode it as polynomial equations. This translation is called **arithmetization**, and it's the subject of this chapter.



## Arithmetic Circuits

An **arithmetic circuit** over a field $\mathbb{F}$ is a directed acyclic graph where each node is either an input, a constant, or a gate (addition or multiplication). Wires carry field elements from gate outputs to gate inputs. The circuit computes a function $f: \mathbb{F}^n \to \mathbb{F}^m$ by propagating values from inputs through gates to outputs.

Think of it as a recipe: inputs enter at the top, flow through a network of additions and multiplications, and produce outputs at the bottom. The recipe is fixed (the circuit structure), but you can run it on different ingredients (input values).

Why circuits? They're the universal language of computation. Any program, any algorithm, any function computable by a computer can be expressed as a (possibly enormous) arithmetic circuit. This universality is what makes circuit-based proof systems so powerful: prove you can verify circuits, and you can verify anything.


## Two Problems, Two Paradigms

Before diving in, we must distinguish two fundamentally different problems:

**Circuit Evaluation**: Given a circuit $C$ and input $x$, prove that $C(x) = y$.

The prover claims they computed the circuit correctly. The verifier could recompute it themselves, but the proof system makes verification faster. GKR handles this directly.

**Circuit Satisfiability**: Given a circuit $C$, public input $x$, and output $y$, prove there exists a secret witness $w$ such that $C(x, w) = y$.

The prover claims they *know* a secret input that makes the circuit output the desired value. They reveal nothing about this secret. This is the paradigm behind most real-world ZK applications, and it's what enables privacy.

Note that GKR (Chapter 7) natively handles circuit *evaluation*, not satisfiability: it proves "$C(x) = y$" for public inputs, with no secrets involved. To handle satisfiability, where the prover has a private witness, you need additional machinery: polynomial commitments that hide the witness values, combined with sum-check to verify the computation. Systems like Jolt use GKR-style sum-check reductions but wrap them with commitment schemes that provide zero-knowledge. The distinction matters: "GKR-based" doesn't mean "evaluation only"; it means the verification logic uses sum-check over layered structure, while commitments handle privacy.

**Example: Proving Knowledge of a Hash Preimage**

Suppose $y = \text{SHA256}(w)$ for some secret $w$. The prover wants to demonstrate they know $w$ without revealing it.

- The circuit $C$ implements SHA256
- The public input is (essentially) empty
- The public output is $y$ (the hash)
- The witness is $w$ (the secret preimage)

The prover demonstrates: "I know a value $w$ such that when I run SHA256 on it, I get exactly $y$." The verifier learns nothing about $w$ except that it exists.

This *satisfiability* paradigm underlies almost all practical ZK applications: proving password knowledge, transaction validity, computation integrity, and more.



## Understanding the Witness

The **witness** is central to zero-knowledge proofs. It's what separates a mere computation from a proof of knowledge.

### What Exactly Is a Witness?

A witness is an input that, together with the public inputs, satisfies the circuit's constraints. In zero-knowledge proofs, the witness is kept private. In the equation $x^3 + x + 5 = 35$, the witness is $x = 3$. Anyone can verify that $3^3 + 3 + 5 = 35$, but the prover is demonstrating they *know* this solution.

More precisely, for a relation $R$, a witness $w$ for statement $x$ is a value such that $R(x, w) = 1$. The relation encodes the computational problem:

- **Hash preimage**: $R(y, w) = 1$ iff $\text{Hash}(w) = y$
- **Digital signature**: $R((m, \sigma, \text{pk}), \text{sk}) = 1$ iff $\text{Sign}(\text{sk}, m) = \sigma$
- **Sudoku solution**: $R(\text{puzzle}, \text{solution}) = 1$ iff the solution correctly fills the puzzle

**The Sudoku Analogy.** Think of a ZK proof as a solved Sudoku puzzle. The *circuit* is the rules of Sudoku: every row, column, and 3×3 square must contain the digits 1 through 9. The *public input* is the pre-filled numbers printed in the newspaper. The *witness* is the numbers you penciled in to solve it. Verifying the solution is easy: check the rows, columns, and squares (the constraints). You don't need to know the order in which the solver filled the numbers, nor the mental logic they used. You just check that the final grid (witness + public input) satisfies the rules.



## The Execution Trace: Witness as Computation History

Modern arithmetization uses a clever insight: instead of building a circuit that *performs* the computation, we build a circuit that *verifies* a claimed execution trace.

### What Is an Execution Trace?

An **execution trace** is a complete record of a computation's execution: every instruction, every intermediate value, every memory access. Think of it as a detailed log file that captures everything that happened during the computation.

The key insight: checking that a trace is valid is much easier than producing the computation. Validity checking is *local*. To verify a trace, you only need to check that each step follows from the previous one according to the program's rules. The prover does the hard computational work; the circuit does the much easier work of checking consistency.

For simple computations (evaluating a polynomial, computing a hash), the trace is just the sequence of intermediate values at each gate. For more complex computations like CPU execution, the trace includes registers, program counters, and memory operations. The machinery for handling such traces (time consistency, memory consistency via permutation arguments) is developed in Chapter 20 in the context of efficient proving techniques. Here, we focus on the simpler case: a circuit where the witness captures all intermediate gate values.



## R1CS: The Constraint Language

How do we express these checks algebraically? The classic approach is **Rank-1 Constraint System (R1CS)**.

An R1CS instance consists of:

- Three matrices $A, B, C$ of dimension $m \times n$
- A witness vector $Z$ of length $n$

The constraint is: for each row $i$,

$$(A_i \cdot Z) \times (B_i \cdot Z) = C_i \cdot Z$$

In words: (linear combination) × (linear combination) = (linear combination).

The matrices encode which wires participate in each constraint. Each row enforces one multiplication gate.

Why this particular form? The fundamental reason is that degree-2 polynomial constraints are the simplest non-trivial form that's still universal. Linear constraints (degree 1) can't express multiplication. Degree 2 is the minimal step up, and it turns out to be enough: any computation can be decomposed into steps involving at most one multiplication each. Historically, pairings reinforced this choice. A bilinear map can verify one multiplication "for free," so early SNARKs (Groth16, BCTV14) were designed around degree-2 constraints. But the format isn't pairing-specific: modern systems verify R1CS using FRI or IPA, no pairings required.

At first glance, "one multiplication per constraint" seems limiting. What if you need to compute $a \cdot b \cdot c$? That requires two multiplications, not one. What about $x^4$? That's three multiplications. How can a format that allows only one multiplication per constraint express arbitrary computations?

The answer: introduce intermediate variables. To compute $a \cdot b \cdot c$, define a helper variable $t = a \cdot b$, then write two constraints:

- Constraint 1: $a \times b = t$
- Constraint 2: $t \times c = \text{result}$

Each constraint has exactly one multiplication. The witness vector grows to include $t$, but that's fine since the prover computed it anyway. This is the general pattern: any polynomial computation of degree $d$ can be flattened into $O(d)$ R1CS constraints by naming intermediate products.

Addition, by contrast, is free. To constrain $a + b + c = d$, we write $(a + b + c) \times 1 = d$, which costs one constraint but involves no "real" multiplication. More generally, we can pack arbitrary additions into either side of a multiplication: $(a + b + c) \times (d + e) = f + g$ is still a single R1CS row. Why? Because $A \cdot Z$ computes a weighted sum of witness variables. Matrix-vector multiplication is just addition, so combining $a + b + c + \ldots$ into one linear combination costs nothing. We only "pay" when we multiply the result of $A \cdot Z$ by the result of $B \cdot Z$.

This decomposition is why R1CS can encode arbitrary arithmetic circuits. Every gate becomes one constraint. The "one multiplication" rule isn't a limitation; it's a *normal form* that any computation can be converted into.

Any arithmetic circuit with $m$ multiplication gates and $a$ addition gates can be expressed as an R1CS with exactly $m$ constraints. The witness vector has length at most $m + a + \text{inputs} + \text{outputs}$. Addition gates require no constraints; they're absorbed into the linear combinations.

### The Witness Vector in R1CS

The witness vector $Z$ in R1CS has a specific structure. It concatenates three parts:

$$Z = \begin{pmatrix} 1 \\ \text{io} \\ W \end{pmatrix}$$

**The constant 1**: Always the first element. This allows encoding constants and pure additions. To constrain $x = 5$, write $x \times 1 = 5 \times 1$. For addition $a + b = c$, write $(a + b) \times 1 = c$.

**The public inputs/outputs (io)**: Values the verifier knows. For a hash preimage proof, this is the hash value $y$. For a transaction validity proof, it might include the transaction amount and recipient.

**The private witness (W)**: The secret values only the prover knows, plus all intermediate computation values.

For example, proving $x^3 + x + 5 = 35$ with secret $x = 3$:

| Index | Value | Description |
|-------|-------|-------------|
| $Z_0$ | 1 | Constant |
| $Z_1$ | 35 | Public output |
| $Z_2$ | 3 | Private: $x$ |
| $Z_3$ | 9 | Private: $x^2$ |
| $Z_4$ | 27 | Private: $x^3$ |
| $Z_5$ | 30 | Private: $x^3 + x$ |
| $Z_6$ | 35 | Private: $x^3 + x + 5$ |

The witness includes not just the input $x$, but all intermediate values. The constraint system checks that each step was performed correctly.

### Basic Gates in R1CS

**Multiplication** ($a \cdot b = c$):

- Row $i$ of $A$ selects $a$ from $Z$
- Row $i$ of $B$ selects $b$ from $Z$
- Row $i$ of $C$ selects $c$ from $Z$
- Constraint: $a \times b = c$

**Addition** ($a + b = c$):

- Set $B$ to select the constant 1
- Row $i$ of $A$ selects both $a$ and $b$ (with coefficients 1, 1)
- Row $i$ of $C$ selects $c$
- Constraint: $(a + b) \times 1 = c$

**Constant multiplication** ($k \cdot a = c$):

- Row $i$ of $A$ selects $a$
- Row $i$ of $B$ selects constant $k$ (or encode $k$ in $A$)
- Row $i$ of $C$ selects $c$



## Worked Example: $x^3 + x + 5 = 35$

Let's arithmetize a complete example. The prover claims to know $x$ such that $x^3 + x + 5 = 35$. (The secret is $x = 3$.)

### Step 1: Flatten to Basic Operations

Break the computation into primitive gates:

```
v1 = x * x        (compute x²)
v2 = v1 * x       (compute x³)
v3 = v2 + x       (compute x³ + x)
v4 = v3 + 5       (compute x³ + x + 5)
assert: v4 = 35   (check the result)
```

### Step 2: Define the Witness Vector

The witness contains:

- The constant 1 (always included)
- The public output 35
- The secret input $x$
- All intermediate values

$$Z = (1, \; 35, \; x, \; v_1, \; v_2, \; v_3, \; v_4)$$

With $x = 3$:
$$Z = (1, \; 35, \; 3, \; 9, \; 27, \; 30, \; 35)$$

### Step 3: Build the Constraint Matrices

Each gate becomes a row in the matrices:

**Gate 1**: $v_1 = x \cdot x$

- $A_1 = (0, 0, 1, 0, 0, 0, 0)$: selects $x$
- $B_1 = (0, 0, 1, 0, 0, 0, 0)$: selects $x$
- $C_1 = (0, 0, 0, 1, 0, 0, 0)$: selects $v_1$

Check: $(A_1 \cdot Z) \times (B_1 \cdot Z) = 3 \times 3 = 9 = C_1 \cdot Z$

**Gate 2**: $v_2 = v_1 \cdot x$

- $A_2 = (0, 0, 0, 1, 0, 0, 0)$: selects $v_1$
- $B_2 = (0, 0, 1, 0, 0, 0, 0)$: selects $x$
- $C_2 = (0, 0, 0, 0, 1, 0, 0)$: selects $v_2$

Check: $9 \times 3 = 27$

**Gate 3**: $v_3 = v_2 + x$

For addition, we use the trick: $(v_2 + x) \times 1 = v_3$

- $A_3 = (0, 0, 1, 0, 1, 0, 0)$: selects $v_2 + x$
- $B_3 = (1, 0, 0, 0, 0, 0, 0)$: selects constant 1
- $C_3 = (0, 0, 0, 0, 0, 1, 0)$: selects $v_3$

Check: $(27 + 3) \times 1 = 30$

**Gate 4**: $v_4 = v_3 + 5$

- $A_4 = (5, 0, 0, 0, 0, 1, 0)$: selects $5 \cdot 1 + v_3$
- $B_4 = (1, 0, 0, 0, 0, 0, 0)$: selects 1
- $C_4 = (0, 0, 0, 0, 0, 0, 1)$: selects $v_4$

Check: $(5 + 30) \times 1 = 35$

**Gate 5**: $v_4 = 35$ (the public output constraint)

- $A_5 = (0, 0, 0, 0, 0, 0, 1)$: selects $v_4$
- $B_5 = (1, 0, 0, 0, 0, 0, 0)$: selects 1
- $C_5 = (0, 35, 0, 0, 0, 0, 0)$: selects $35 \cdot 1$

Check: $35 \times 1 = 35$

All five constraints are satisfied. The R1CS captures the entire computation.

The complete matrices:

$$A = \begin{pmatrix} 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 1 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 & 1 & 0 & 0 \\ 5 & 0 & 0 & 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 \end{pmatrix}$$

$$B = \begin{pmatrix} 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 1 & 0 & 0 & 0 & 0 & 0 & 0 \\ 1 & 0 & 0 & 0 & 0 & 0 & 0 \\ 1 & 0 & 0 & 0 & 0 & 0 & 0 \end{pmatrix}$$

$$C = \begin{pmatrix} 0 & 0 & 0 & 1 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 \\ 0 & 35 & 0 & 0 & 0 & 0 & 0 \end{pmatrix}$$

Each row corresponds to one constraint. The columns are indexed by $Z = (1, \text{out}, x, v_1, v_2, v_3, v_4)^T$. Notice the sparsity: most entries are zero. This is typical of R1CS matrices and is why efficient implementations use sparse representations.



## Two Ways to Prove R1CS

Once we have R1CS constraints, how do we prove they're all satisfied? There are two major approaches.

### Approach 1: QAP (Quadratic Arithmetic Program)

QAP was introduced by Gennaro, Gentry, Parno, and Rabin in the Pinocchio system (2013), one of the first practical SNARKs. Groth16 (2016) refined and optimized this approach, achieving the smallest proof size known for pairing-based systems. Today, QAP is primarily associated with Groth16. Modern systems have moved to other arithmetizations (PLONKish, AIR, sum-check), but QAP remains important for applications where proof size is paramount.

The key idea: instead of checking $m$ separate constraints, check one polynomial divisibility.

For each column $j$ of the R1CS matrices, define polynomials $A_j(X), B_j(X), C_j(X)$ that interpolate the column values at points $\{1, 2, \ldots, m\}$. (So $A_j(i)$ equals the entry in row $i$, column $j$ of matrix $A$.)

Now let $\vec{Z} = (Z_0, Z_1, \ldots, Z_n)$ be the **witness vector**, the full assignment including the constant 1, public inputs, and private witness values. Define:
$$A(X) = \sum_j Z_j \cdot A_j(X), \quad B(X) = \sum_j Z_j \cdot B_j(X), \quad C(X) = \sum_j Z_j \cdot C_j(X)$$

Each $Z_j$ is a scalar (from the witness), while $A_j(X)$ is a polynomial. The sum computes a linear combination, exactly mirroring how R1CS constraints are matrix-vector products.

The R1CS is satisfied iff $A(X) \cdot B(X) - C(X) = 0$ at all constraint points $\{1, 2, \ldots, m\}$.

By the Factor Theorem, this means the vanishing polynomial $Z_H(X) = (X-1)(X-2)\cdots(X-m)$ divides $A(X) \cdot B(X) - C(X)$.

The prover exhibits a quotient polynomial $H(X)$ such that:
$$A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$$

We develop QAP fully in Chapter 12, where Groth16 uses it to achieve the smallest possible pairing-based proofs.

### Approach 2: Sum-Check on Multilinear Extensions (Spartan)

Spartan was introduced by Setty in 2019, reviving ideas from the GKR protocol (2008) and sum-check literature. While Groth16 uses univariate polynomials and FFTs, Spartan showed that multilinear extensions and the sum-check protocol could handle R1CS directly: no Lagrange interpolation, no roots of unity, optimal prover time. This "sum-check renaissance" led to systems like Lasso, Jolt, and HyperNova.

R1CS constraint satisfaction can be expressed as a polynomial sum equaling zero:

$$\sum_{x \in \{0,1\}^k} \tilde{\text{eq}}(x) \cdot \left[\tilde{A}(x) \cdot \tilde{B}(x) - \tilde{C}(x)\right] = 0$$

Here $\tilde{A}(x)$, $\tilde{B}(x)$, $\tilde{C}(x)$ are the MLEs of the matrix-vector products $A \cdot Z$, $B \cdot Z$, $C \cdot Z$ respectively, each viewed as a function from row index $x \in \{0,1\}^{\log m}$ to a field element.

This formulation matters for three reasons:

1. **Time-optimal proving**: The prover's work is $O(N)$ where $N$ is the number of constraints, just reading the constraints, no FFTs.

2. **Sparsity-preserving**: Multilinear extensions preserve the structure of sparse matrices. In R1CS, most matrix entries are zero. The MLE directly reflects this sparsity.

3. **Natural fit with sum-check**: The sum-check protocol (Chapter 3) is designed exactly for this type of problem.

Comparing QAP and Spartan:

| Property | QAP (Groth16) | Spartan |
|----------|---------------|---------|
| Polynomial type | Univariate, high-degree | Multilinear |
| Core technique | Divisibility by $Z_H(X)$ | Sum-check |
| Prover time | $O(N \log N)$ | $O(N)$ |
| Setup | Circuit-specific trusted | Transparent |

When to use each:

- **When proof size matters most**: Use QAP-based systems (Groth16, BCTV14, Pinocchio). On-chain verification on Ethereum costs gas proportional to proof size, making Groth16's ~200-byte proofs attractive despite the circuit-specific setup. Groth16 is the most optimized of this family and dominates in practice.

- **When prover time matters most**: Use Spartan or other sum-check systems. The $O(N)$ prover (vs $O(N \log N)$ for FFT-based systems) becomes significant at scale. Transparent setup avoids trust assumptions entirely. Natural fit for recursive composition and folding schemes (Nova, HyperNova). The tradeoff: larger proofs and more expensive verification.



## PLONKish Arithmetization

R1CS isn't the only way to encode computations. **PLONKish** takes a fundamentally different approach, one that has become widely adopted in production ZK systems.

**Historical context**: PLONK (Permutations over Lagrange-bases for Oecumenical Noninteractive arguments of Knowledge) was introduced by Gabizon, Williamson, and Ciobotaru in 2019. It addressed Groth16's main limitation, circuit-specific trusted setup, by providing a **universal** setup: one ceremony works for any circuit up to a given size. PLONK spawned a family of "PLONKish" systems (Halo 2, Plonky2, HyperPlonk) that now power most production ZK applications.

### The Universal Gate Equation

PLONK's core innovation is a single standardized gate equation:

$$Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot a \cdot b + Q_C = 0$$

The $Q$ values are **selectors**, public constants that "program" each gate.

**Addition gate** ($a + b = c$): Set $Q_L = 1, Q_R = 1, Q_O = -1$, rest zero.

**Multiplication gate** ($a \cdot b = c$): Set $Q_M = 1, Q_O = -1$, rest zero.

**Public input** ($a = k$): Set $Q_L = 1, Q_C = -k$, rest zero.

The same equation handles all gate types!

### Copy Constraints: The Permutation Argument

PLONK's gate equation only relates wires *within* a single gate. It doesn't enforce that the output of gate 1 feeds into the input of gate 5.

This is where the **permutation argument** enters. Number all wire positions in the circuit as $1, 2, 3, \ldots, n$. Some positions must hold equal values (because one gate's output connects to another's input). We encode these equalities as a permutation $\sigma$: positions that must be equal form cycles under $\sigma$. The constraint "all wiring is respected" becomes:

$$f(i) = f(\sigma(i)) \quad \text{for all } i$$

where $f(i)$ is the value at position $i$. PLONK proves this via a grand product check. With random challenges $\beta, \gamma$:

$$\prod_i \frac{f(i) + \beta \cdot i + \gamma}{f(i) + \beta \cdot \sigma(i) + \gamma} = 1$$

The intuition: each fraction pairs a value with its position. If copy constraints hold, the numerators and denominators rearrange to cancel. If any constraint fails, the random $\beta, \gamma$ ensure the product differs from 1 with overwhelming probability. We develop the full permutation argument in Chapter 13.

### When to Use PLONKish

PLONKish shines when you need **flexibility without sacrificing succinctness**:

- **Universal setup** (vs Groth16's circuit-specific): One ceremony covers all circuits up to a size bound
- **Custom gates**: Optimize specific operations (hash functions, range checks, elliptic curve arithmetic)

The tradeoff versus Groth16 (which uses R1CS + QAP): slightly larger proofs (~2-3x), but no circuit-specific ceremony.

Note: Sum-check systems like Spartan go further with fully transparent setup (no ceremony at all), but with larger proofs.



## AIR: Algebraic Intermediate Representation

A third constraint format takes yet another path, designed specifically for computations with **repetitive structure**: state machines, virtual machines, and iterative algorithms.

An AIR consists of:

- **Execution trace**: A table where each row represents a "state" and columns hold state variables
- **Transition constraints**: Polynomials that relate row $i$ to row $i+1$ (the local rules)
- **Boundary constraints**: Conditions on specific rows (initial state, final state)

The insight: many computations are naturally described as "apply the same transition rule repeatedly." A CPU executes instructions in a loop. A hash function applies the same round function many times. AIR captures this by encoding the transition rule once and proving it holds for all consecutive row pairs.

**Example**: A simple counter that increments by 1:

- Transition constraint: $s_{i+1} - s_i - 1 = 0$
- Boundary constraint: $s_0 = 0$ (start at zero)

This single transition constraint, applied to $n$ rows, proves correct execution of $n$ steps.

The algebraic formulation uses a clever trick. Interpolate each trace column as a polynomial $P(X)$ over a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{T-1}\}$ where $\omega$ is a $T$-th root of unity. Now $P(\omega^i)$ gives the value at step $i$, and $P(\omega \cdot \omega^i) = P(\omega^{i+1})$ gives the value at step $i+1$. So the "next step" value is $P(\omega X)$.

The transition constraint $s_{i+1} - s_i - 1 = 0$ becomes the polynomial identity:

$$P(\omega X) - P(X) - 1 = 0 \quad \text{for all } X \in H' = \{1, \omega, \ldots, \omega^{T-2}\}$$

If this holds, the constraint polynomial $C(X) = P(\omega X) - P(X) - 1$ vanishes on $H'$, so the quotient $Q(X) = C(X) / Z_{H'}(X)$ is a polynomial (not a rational function with poles). The prover commits to $Q(X)$ and proves it's low-degree via FRI. Boundary constraints work similarly: $P(1) = 0$ becomes $(P(X) - 0)/(X - 1)$ being a polynomial.

AIR is the native format for **STARKs**, which we develop fully in **Chapter 15**. The combination of AIR's repetitive structure with FRI's hash-based commitments yields transparent, plausibly post-quantum proofs.

### Comparing the Three Formats

| Property | R1CS | PLONKish | AIR |
|----------|------|----------|-----|
| Structure | Sparse matrices | Gates + selectors | Execution trace + transitions |
| Gate flexibility | One mult/constraint | Custom gates | Transition polynomials |
| Best for | Simple circuits | Complex, irregular ops | Repetitive state machines |
| Used by | Groth16, Spartan | PLONK, Halo 2 | STARKs, Cairo |

In practice:

- **R1CS + Groth16**: When proof size dominates (on-chain verification)
- **PLONKish**: When you need flexibility and universal setup
- **AIR + STARKs**: When transparency and post-quantum security matter



## CCS: Unifying the Constraint Formats

We now have three constraint formats (R1CS, PLONKish, AIR) each with distinct strengths. But this proliferation creates fragmentation: tools, optimizations, and folding schemes must be reimplemented for each format.

Why do we need yet another format? The answer is folding (Chapter 21). Newer protocols like Nova and HyperNova work by "folding" two proof instances into one. R1CS folds easily, but PLONKish constraints do not. **Customizable Constraint Systems (CCS)** was invented to give us both: the expressiveness of PLONK's custom gates with the foldability of R1CS's matrix structure. CCS provides a unifying abstraction that captures all three formats without overhead.

### The CCS Framework

A CCS instance consists of:

- **Matrices** $M_1, \ldots, M_t$: sparse matrices over $\mathbb{F}$, encoding constraint structure
- **Constraint specifications**: which matrices combine in each constraint, with what operation

The key insight: any constraint system can be expressed as:

$$\sum_i c_i \cdot \bigcirc_{j \in S_i} (M_j \cdot z) = 0$$

where:

- $z$ is the witness vector (including public inputs and the constant 1)
- $S_i$ specifies which matrices participate in term $i$
- $\bigcirc$ is the Hadamard (element-wise) product: $(a_1, a_2, a_3) \circ (b_1, b_2, b_3) = (a_1 b_1, a_2 b_2, a_3 b_3)$
- $c_i$ are scalar coefficients

The notation $\bigcirc_{j \in S_i}$ means: for each matrix index $j$ in the set $S_i$, compute the vector $M_j \cdot z$, then Hadamard-multiply all those vectors together. If $S_i = \{1, 2\}$, you get $(M_1 \cdot z) \circ (M_2 \cdot z)$. If $S_i = \{3\}$ (a single matrix), you just get $M_3 \cdot z$ with no Hadamard.

Each term $i$ in the sum takes a subset of matrices $\{M_j : j \in S_i\}$, multiplies each by the witness vector $z$, Hadamard-multiplies the results together, and scales by $c_i$. The constraint is satisfied when all terms sum to zero.

Every constraint format we've seen boils down to two operations: (1) selecting and summing witness values (matrix-vector products), and (2) multiplying those sums together (Hadamard products). CCS makes these two operations explicit and composable:

- **Linear constraints**: A single matrix-vector product, no Hadamard
- **Quadratic constraints**: Hadamard of two matrix-vector products
- **Higher-degree constraints**: Hadamard of more products
- **Mixed constraints**: Different terms can have different degrees

### Recovering Standard Formats

**R1CS as CCS:**

- Three matrices: $M_1 = A$, $M_2 = B$, $M_3 = C$
- Two terms: $S_1 = \{1, 2\}$ (Hadamard of $A$ and $B$), $S_2 = \{3\}$ (just $C$)
- Coefficients: $c_1 = 1$, $c_2 = -1$

The CCS formula becomes:
$$1 \cdot \big((M_1 \cdot z) \circ (M_2 \cdot z)\big) + (-1) \cdot (M_3 \cdot z) = 0$$

which is exactly $(A \cdot z) \circ (B \cdot z) - C \cdot z = 0$, the R1CS equation.

**PLONKish as CCS:**

The PLONK gate equation $Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot a \cdot b + Q_C = 0$ becomes:

- Matrices: $M_a$ (selects wire $a$), $M_b$ (selects wire $b$), $M_c$ (selects wire $c$), $M_{Q_L}$ (selector), $M_{Q_R}$, $M_{Q_O}$, $M_{Q_M}$, $M_{Q_C}$
- Terms map to the gate equation:
  - $Q_L \cdot a$: Hadamard of selector and wire → $S_1 = \{Q_L, a\}$
  - $Q_M \cdot a \cdot b$: Hadamard of three matrices → $S_2 = \{Q_M, a, b\}$
  - ...and so on for each term

The CCS formula becomes:
$$1 \cdot (M_{Q_L} \cdot z) \circ (M_a \cdot z) + 1 \cdot (M_{Q_R} \cdot z) \circ (M_b \cdot z) + \ldots = 0$$

Each term in PLONK's gate equation maps to one term in the CCS sum.

**AIR as CCS:**

Recall from the AIR section that the transition constraint $s_{i+1} - s_i - 1 = 0$ becomes the polynomial identity $P(\omega X) - P(X) - 1 = 0$. CCS captures this same structure with matrices instead of the $\omega X$ shift.

A transition constraint like $s_{i+1} = 2 \cdot s_i + 1$ becomes:

- Matrices: $M_{\text{curr}}$ (extracts current-row values), $M_{\text{next}}$ (extracts next-row values), $M_{\text{const}}$ (constant column)
- The constraint $s' - 2s - 1 = 0$ becomes:

$$1 \cdot (M_{\text{next}} \cdot z) + (-2) \cdot (M_{\text{curr}} \cdot z) + (-1) \cdot (M_{\text{const}} \cdot z) = 0$$

The matrix $M_{\text{next}}$ plays the role of the $\omega X$ shift: it extracts "next step" values from the witness vector, just as $P(\omega X)$ evaluates the polynomial at the next domain point.

Here all terms have $|S_i| = 1$ (no Hadamard products), so the constraint is purely linear in state variables. Quadratic AIR constraints (like $s' = s^2$) would use Hadamard: $(M_{\text{next}} \cdot z) - (M_{\text{curr}} \cdot z) \circ (M_{\text{curr}} \cdot z) = 0$.

### Why CCS Matters

CCS enables unified tooling: compilers, analyzers, and optimizers can target CCS once. The specific frontend (Circom, Cairo, Noir) produces CCS; the backend (Spartan, Nova, HyperNova) consumes it. HyperNova folds CCS instances directly, so any constraint format expressible as CCS inherits folding for free. Matrix sparsity, constraint reordering, and parallel proving apply uniformly regardless of the original constraint format. Theoretical results about CCS apply to all formats it subsumes.

### CCS in Practice

Modern systems increasingly use CCS as their internal representation:

- **HyperNova**: Folds CCS directly, achieving the benefits of PLONK's flexibility with Nova's efficiency
- **Sonobe**: A folding framework that targets CCS
- **Research prototypes**: Use CCS for cleaner proofs of concept

The constraint format ecosystem is consolidating. R1CS, PLONKish, and AIR remain useful surface-level abstractions, but CCS provides the common substrate beneath.



## Handling Non-Arithmetic Operations

Real programs use operations that aren't native to field arithmetic: comparisons, bitwise operations, conditionals, hash functions. These require careful encoding, and this is where constraint counts explode.

### Bit Decomposition: The Fundamental Technique

The standard technique: represent an integer $a$ as bits $(a_0, a_1, \ldots, a_{W-1})$.

**Enforce "bitness"**: Each $a_i$ must satisfy $a_i \cdot (a_i - 1) = 0$. This polynomial is zero iff $a_i \in \{0, 1\}$.

Why? If $a_i = 0$: $0 \cdot (0-1) = 0$ (satisfied).
If $a_i = 1$: $1 \cdot (1-1) = 0$ (satisfied).
If $a_i = 2$: $2 \cdot (2-1) = 2 \neq 0$ (fails).

**Reconstruct the value**: Verify $a = \sum_{i=0}^{W-1} a_i \cdot 2^i$.

### Constraint Costs: A Reality Check

Here's where things get expensive. Let's count constraints for common operations:

| Operation | Constraints | Notes |
|-----------|-------------|-------|
| Field addition | 0 | Free! Just combine wires |
| Field multiplication | 1 | Native R1CS operation |
| 64-bit decomposition | 64 | One per bit (bitness check) |
| 64-bit reconstruction | 1 | Sum with powers of 2 |
| 64-bit AND | ~130 | Decompose both, multiply bits, reconstruct |
| 64-bit XOR | ~130 | Decompose both, compute XOR per bit |
| 64-bit comparison | ~200 | Decompose, subtract, check sign bit |
| 64-bit range proof | ~65 | Decompose + bitness checks |
| SHA256 hash | ~20,000 | Many bitwise operations |
| Poseidon hash | ~250 | Field-native design |

Bitwise operations are roughly 100x more expensive than field operations. This is why:

- ZK-friendly hash functions (Poseidon, Rescue) exist: they avoid bit operations
- zkVMs are expensive because they must handle arbitrary CPU instructions
- Custom circuits beat general-purpose approaches for specific computations

### Simulating Logic Gates

With bits exposed, we can simulate Boolean logic:

**AND** ($c = a \land b$): For each bit position $i$:
$$c_i = a_i \cdot b_i$$
Cost: 1 multiplication constraint per bit

**OR** ($c = a \lor b$): For each bit position $i$:
$$c_i = a_i + b_i - a_i \cdot b_i$$
Cost: 1 multiplication constraint per bit

**XOR** ($c = a \oplus b$): For each bit position $i$:
$$c_i = a_i + b_i - 2 \cdot a_i \cdot b_i$$
Cost: 1 multiplication constraint per bit

**NOT** ($c = \lnot a$): For each bit position $i$:
$$c_i = 1 - a_i$$
Cost: 0 (just linear combination)

### Range Proofs: Proving $a < 2^k$

To prove a value is within a range $[0, 2^k)$:

1. Decompose into $k$ bits
2. Check each bit satisfies $b_i(b_i - 1) = 0$
3. Verify reconstruction: $a = \sum_{i=0}^{k-1} b_i \cdot 2^i$

Cost: $k$ bitness constraints + 1 reconstruction constraint

### Comparison: Proving $a < b$

To prove $a < b$ for values in range $[0, 2^k)$:

**Approach 1: Subtraction with underflow**

1. Compute $d = b - a + 2^k$ (shifted to avoid underflow)
2. Decompose $d$ into $k+1$ bits
3. Check the most significant bit equals 1 (meaning $b - a \geq 0$, so $b > a$)

Cost: ~$k+1$ constraints for bit decomposition + bitness checks

**Approach 2: Lexicographic comparison**

1. Decompose both $a$ and $b$ into bits
2. Starting from the MSB, find the first position where they differ
3. At that position, check $a_i = 0$ and $b_i = 1$

Cost: More complex, often not better for general comparisons

The pattern is clear: anything involving bits is expensive. For years, circuit designers accepted this cost as unavoidable, until lookup arguments changed everything.



## Lookup Arguments: Breaking the Bit Decomposition Wall

The constraint costs above create a fundamental problem. A silicon CPU executes `a XOR b` in one cycle. In R1CS, that same XOR costs ~25 constraints: decompose both operands into bits, check bitness, compute per-bit XOR, reconstruct. For a 64-bit instruction set, every operation explodes into hundreds of constraints. Building a zkVM this way is like simulating a Ferrari using wooden gears.

**Lookup arguments** solve this by replacing *computation* with *table membership*. Instead of proving *how* you computed a result, prove *that* the result appears in a precomputed table.

To prove an 8-bit XOR:

- **Bit decomposition**: 16 bitness checks + 8 XOR computations + reconstruction ≈ 25 constraints
- **Lookup**: Precompute all $256 \times 256 = 65,536$ valid XOR triples $(a, b, a \oplus b)$. Prove $(a, b, c)$ is in the table ≈ 3 constraints

The savings compound. A 64-bit XOR via bit decomposition costs ~130 constraints. Via lookups on 8-bit chunks: 8 lookups × 3 constraints = 24 constraints.

This changes what's feasible:

| Operation | Without Lookups | With Lookups |
|-----------|-----------------|--------------|
| 16-bit range check | 17 constraints | ~3 constraints |
| 8-bit XOR | ~25 constraints | ~3 constraints |
| 64-bit XOR | ~130 constraints | ~24 constraints |
| SHA-256 (via chunks) | ~20,000 constraints | ~2,000 constraints |

The "how" of lookup arguments (Plookup's grand products, LogUp's logarithmic derivatives, Lasso's decomposition for huge tables) is developed in **Chapter 14**. The key insight for arithmetization is architectural: non-field-native operations that would otherwise dominate constraint counts can be handled via table membership at roughly constant cost per lookup.

This is why modern zkVMs are practical. Cairo, RISC-Zero, SP1, and Jolt prove instruction execution not by encoding CPU semantics in constraints, but by verifying that each instruction's behavior matches a precomputed table. The paradigm shifted from encoding *logic* to referencing *data*.



## The Frontend/Backend Split

This chapter describes **frontends**, compilers that transform high-level programs into arithmetic form. The **backend** is the proof system (GKR, Groth16, PLONK, STARKs) that proves the resulting constraints.

**CPU-style frontends** (Cairo, RISC-Zero, SP1, Jolt):

- Define a virtual machine with a fixed instruction set
- Any program compiles to that instruction set
- The arithmetization verifies instruction execution
- General-purpose but with overhead

**ASIC-style frontends** (Circom, custom circuits):

- Create a specialized circuit for each specific program
- Maximum efficiency for fixed computations
- Poor for general-purpose or data-dependent control flow

**Hybrid approaches**:

- Use custom circuits for the common case
- Fall back to general VM for edge cases
- Example: Specialized hash circuit + general VM for the rest

The choice depends on your use case. Verifying a hash? A custom circuit is fastest. Running arbitrary computation? You need a zkVM. Running the same computation millions of times? The circuit development cost is amortized.



## Key Takeaways

1. **The pipeline**: Program → execution trace (witness) → constraint system → polynomial identity → proof. Arithmetization is the bridge between computation and algebra.

2. **Circuit satisfiability vs. evaluation**: Most applications prove knowledge of a secret witness, not just correct evaluation.

3. **The witness is everything**: It's the complete set of values (public, private, and intermediate) that satisfies the constraints.

4. **Three constraint formats**: R1CS (sparse matrices, $(A \cdot Z) \times (B \cdot Z) = C \cdot Z$), PLONKish (universal gate + permutation), AIR (transition polynomials). CCS unifies them all.

5. **Bit decomposition is expensive**: A 64-bit operation costs ~65-200 constraints via traditional encoding. Lookup arguments (Chapter 14) reduce this to ~3 constraints per table lookup.

6. **Frontend/backend split**: Frontends handle arithmetization; backends handle proving. They can be mixed and matched.

7. **Constraint cost guides design**: Choose field-friendly operations (hashes, curves) over bit-heavy operations.

# Chapter 8: From Circuits to Polynomials

In 1931, Kurt Gödel shattered the foundations of mathematics. He proved that any formal system powerful enough to express arithmetic is "haunted": it contains true statements that cannot be proven. To establish this, Gödel had to solve a technical nightmare: how do you make math talk about itself?

His solution was Gödel numbering. He assigned a unique integer to every logical symbol ($+$, $=$, $\forall$), turning logical statements into integers and logical proofs into arithmetic relationships between those integers. He turned logic into arithmetic so that arithmetic could reason about logic.

What we do in zero-knowledge proofs is a direct descendant of Gödel's trick. We take the logic of a computer program (loops, jumps, variables) and map it into the rigid algebra of polynomials. This translation process is called **arithmetization**.

But the analogy goes deeper. Once computation is translated into algebra, the verification of that algebra becomes just another computation. And since we can translate any computation into polynomials, we can translate the verifier itself. This closes the loop. Just as Gödel used arithmetic to talk about arithmetic, arithmetization allows ZK proofs to verify ZK proofs. This self-referential capability (recursion) is what allows us to compress hours of computation into a millisecond check. It all starts here, with the translation of thought into number.



## Two Problems, Two Paradigms

Before diving in, we must distinguish two fundamentally different problems:

**Circuit Evaluation**: Given a circuit $C$ and input $x$, prove that $C(x) = y$.

The prover claims they computed the circuit correctly. The verifier could recompute it themselves, but the ZK system just makes verification faster. GKR handles this directly.

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

A witness is a private input that, together with the public inputs, satisfies the circuit's constraints. In the equation $x^3 + x + 5 = 35$, the witness is $x = 3$. Anyone can verify that $3^3 + 3 + 5 = 35$, but the prover is demonstrating they *know* this solution.

More precisely, for a relation $R$, a witness $w$ for statement $x$ is a value such that $R(x, w) = 1$. The relation encodes the computational problem:

- **Hash preimage**: $R(y, w) = 1$ iff $\text{Hash}(w) = y$
- **Digital signature**: $R((m, \sigma, \text{pk}), \text{sk}) = 1$ iff $\text{Sign}(\text{sk}, m) = \sigma$
- **Sudoku solution**: $R(\text{puzzle}, \text{solution}) = 1$ iff the solution correctly fills the puzzle

**The Sudoku Analogy.** Think of a ZK proof as a solved Sudoku puzzle. The *circuit* is the rules of Sudoku: every row, column, and 3×3 square must contain the digits 1 through 9. The *public input* is the pre-filled numbers printed in the newspaper. The *witness* is the numbers you penciled in to solve it. Verifying the solution is easy: check the rows, columns, and squares (the constraints). You don't need to know the order in which the solver filled the numbers, nor the mental logic they used. You just check that the final grid (witness + public input) satisfies the rules.

### The Witness Vector Structure

In constraint systems like R1CS, the witness takes a specific form. The full **witness vector** $Z$ is a concatenation of three parts:

$$Z = \begin{pmatrix} 1 \\ \text{io} \\ W \end{pmatrix}$$

**The constant 1**: Always the first element. This allows encoding constant additions and multiplications easily. To constrain $x = 5$, we can write $x \times 1 = 5 \times 1$.

**The public inputs/outputs (io)**: Values the verifier already knows and agrees upon. For a hash preimage proof, this is the hash value $y$. For a transaction validity proof, this might include the transaction amount and recipient.

**The private witness (W)**: The secret values only the prover knows. This is what the prover is demonstrating knowledge of without revealing.

### A Concrete Example

For our equation $x^3 + x + 5 = 35$ with $x = 3$:

| Index | Value | Description |
|-------|-------|-------------|
| $Z_0$ | 1 | Constant |
| $Z_1$ | 35 | Public output |
| $Z_2$ | 3 | Private: $x$ |
| $Z_3$ | 9 | Private: $x^2$ |
| $Z_4$ | 27 | Private: $x^3$ |
| $Z_5$ | 30 | Private: $x^3 + x$ |
| $Z_6$ | 35 | Private: $x^3 + x + 5$ |

Notice that the witness includes not just the input $x$, but all intermediate values computed along the way. This is crucial: the constraint system checks that each step was performed correctly.



## The Execution Trace: Witness as Computation History

Modern arithmetization uses a clever insight: instead of building a circuit that *performs* the computation, we build a circuit that *verifies* a claimed execution trace.

### What Is an Execution Trace?

An **execution trace** is a complete record of a computation's execution: every instruction, every intermediate value, every memory access. Think of it as a detailed log file that captures everything that happened during the computation.

**The Key Insight**: Checking that a trace is *valid* is much easier than *producing* the computation.

Why? Because validity checking is *local*. To verify a trace, you only need to check that each step follows from the previous one according to the program's rules. You don't need to understand the whole program's logic, just that each individual transition is correct.

### A Brief Detour: How Computers Execute Programs

Before examining traces, we need a mental model of program execution. A computer at any moment has a **state**: the contents of its memory and a small set of fast storage locations called **registers**. Think of registers as the mathematician's scratch paper, a few variables (typically 8–32) that hold the values currently being manipulated. Memory is the larger workspace, addressed by integers: location 100, location 104, and so on.

The **program counter (PC)** is a special register that holds the address of the current instruction. Each instruction is an **opcode** (the operation: ADD, MUL, LOAD, STORE, JUMP) plus **operands** (which registers or memory addresses to use). Execution proceeds in a loop: fetch the instruction at the PC, execute it, update the PC (usually PC + 1, unless we jumped), repeat.

A LOAD instruction copies a value from memory into a register. A STORE does the reverse. Arithmetic opcodes like ADD or MUL operate on registers. A conditional jump like BEQ ("branch if equal") changes the PC based on a comparison; this is how loops and conditionals are implemented at the machine level.

The key insight for arithmetization: at each time step, the machine's entire state (registers, PC, memory) is just a tuple of field elements. Execution is a sequence of such tuples, and each transition is governed by simple local rules.

### Execution Trace Structure

A trace consists of rows, where each row represents the machine state at one time step:

| Step | PC | Opcode | Operands | Registers | Memory Reads | Memory Writes |
|------|----|---------|-----------|--------------------|--------------|---------------|
| 0 | 0 | LOAD | r1, [100] | r1=0, r2=0, r3=0 | [100]=42 | - |
| 1 | 1 | LOAD | r2, [104] | r1=42, r2=0, r3=0 | [104]=17 | - |
| 2 | 2 | MUL | r3, r1, r2 | r1=42, r2=17, r3=0 | - | - |
| 3 | 3 | STORE | r3, [108] | r1=42, r2=17, r3=714 | - | [108]=714 |

Each row includes:

- **Program Counter (PC)**: Which instruction we're executing
- **Opcode**: What operation is being performed
- **Operands**: Which registers/memory locations are involved
- **Register State**: The values of all registers
- **Memory Operations**: What was read from or written to memory

### The Circuit Doesn't Compute: It Verifies

Here's the paradigm shift: the circuit doesn't actually run the computation. It assumes the prover has already computed the trace (they have; they did the computation) and verifies that:

1. Each transition follows the correct rules
2. The trace starts with the correct initial state
3. The trace ends with the claimed output

The prover does the hard computational work. The circuit does the much easier work of checking consistency.



## What the Circuit Must Check

A trace verification circuit performs two categories of checks:

### Time Consistency (Transition Rules)

For every adjacent pair of rows $(S_t, S_{t+1})$, verify that the state transition follows from the instruction.

The idea is simple: given the current state and the instruction being executed, the next state is completely determined. If the trace claims the machine went from state $A$ to state $B$, we can check whether that transition is legal without needing to know anything about the states before or after.

**Example: Checking an ADD instruction**

If the opcode at step $t$ is ADD with operands r1, r2, r3:

- Check: $\text{PC}_{t+1} = \text{PC}_t + 1$ (we move to the next instruction)
- Check: $r3_{t+1} = r1_t + r2_t$ (the destination register gets the sum)
- Check: All other registers unchanged: $r1_{t+1} = r1_t$, $r2_{t+1} = r2_t$

**Example: Checking a conditional jump (BEQ r1, r2, label)**

- If $r1_t = r2_t$: Check $\text{PC}_{t+1} = \text{label}$ (branch taken)
- If $r1_t \neq r2_t$: Check $\text{PC}_{t+1} = \text{PC}_t + 1$ (branch not taken)
- Check: All registers unchanged

These checks are **local**: they only look at two adjacent rows. This locality is crucial: checking $n$ transitions requires $n$ independent checks, each involving only $O(1)$ values. The circuit applies the same transition-checking logic at every time step, making it uniform and amenable to polynomial encoding.

### Memory Consistency

This is trickier. A read at time $t$ might depend on a write from much earlier. The naive approach, searching backward through the trace for the most recent write, would be expensive.

**The Problem**: Time consistency is local: step $t+1$ depends only on step $t$. But memory breaks this locality. A read at step 1000 might retrieve a value written at step 3. The dependency spans nearly the entire trace.

Consider: step 0 writes value 42 to address 100. Steps 1 through 99 touch other addresses. Step 100 reads from address 100, and it should get 42. How do we check this without searching back through 100 steps?

**The Permutation Trick**:

The solution is to view the same data from a different angle. Imagine the memory operations as a deck of cards, each labeled with (address, time, operation, value). In the execution trace, these cards appear in time order, shuffled from the perspective of memory addresses. But we can *sort* the deck by address, grouping all operations on address 12 together, all operations on address 18 together, and so on.

Here's the insight: in the sorted view, operations on the same address are adjacent. Checking that a read returns the right value becomes a local check: just compare with the previous card in the sorted deck.

The protocol works as follows:

1. Extract all memory operations from the trace: `(address, time, operation, value)`

2. Create two lists:

   - **Time-ordered** (the original sequence of operations)
   - **Address-ordered** (sorted by address, then by time within each address)

3. Prove these lists are permutations of each other (same cards, different order). This uses polynomial fingerprinting: encode each list as a polynomial, and check they have the same "signature" at a random point.

4. In the address-ordered list, checking memory consistency is **local**: each read should match the value from the immediately preceding operation at that address.

**Worked Example**:

Time-ordered operations:
```
t=1: write(addr=18, val=7)
t=2: write(addr=12, val=5)
t=3: read(addr=18) → expects 7
t=4: write(addr=12, val=9)
```

Address-ordered (sorted first by address, then by time):
```
(addr=12, t=2, write, 5)
(addr=12, t=4, write, 9)
(addr=18, t=1, write, 7)
(addr=18, t=3, read, 7)  ← easy to check: matches the previous row at this address
```

In the address-ordered view, operations on the same address are consecutive. The read at $t=3$ for address 18 appears immediately after the write at $t=1$ for address 18. Checking correctness is just comparing adjacent rows, with no searching required.

The permutation check ensures the prover didn't fabricate operations or alter values when "sorting." The local consistency check on the sorted list verifies that memory behaves correctly. Together, they reduce a non-local problem to local checks plus a permutation argument.



## R1CS: The Constraint Language

How do we express these checks algebraically? The classic approach is **Rank-1 Constraint System (R1CS)**.

But first, a question: *why this particular algebraic form?*

The answer traces back to pairings. A bilinear map $e: \mathbb{G}_1 \times \mathbb{G}_2 \to \mathbb{G}_T$ has a remarkable property: it can check *one multiplication* "for free." Given commitments to $a$ and $b$, you can verify $a \cdot b = c$ with a single pairing equation. But pairings are expensive, so you want exactly one multiplication per constraint, no more.

This is why R1CS has its peculiar shape. The system was reverse-engineered from the verification equation: *what constraint format lets pairings check everything in one shot?* The answer is a product of two linear combinations.

An R1CS instance consists of:

- Three matrices $A, B, C$ of dimension $m \times n$
- A witness vector $Z$ of length $n$

The constraint is: for each row $i$,

$$(A_i \cdot Z) \times (B_i \cdot Z) = C_i \cdot Z$$

In words: (linear combination) × (linear combination) = (linear combination).

The matrices encode which wires participate in each constraint; the product structure is the algebraic shape that pairings can verify.

**Why is this form so expressive?** At first glance, "one multiplication per constraint" seems limiting. But here's the key insight: any computation can be broken into steps where each step involves at most one multiplication. Addition is free: you can add as many terms as you want on either side. The constraint $(a + b + c) \times (d + e) = f + g$ is a single R1CS row.

**Why is addition free?** In R1CS, linear combinations happen inside the matrix multiplication. $A \cdot Z$ computes a weighted sum of the witness variables. Since matrix-vector multiplication is just a series of additions, we can represent $a + b + c + d + \ldots$ in a single row of matrix $A$. We only "pay" (incur a constraint) when we need to multiply the result of matrix $A$ by the result of matrix $B$.

The trick is introducing intermediate variables. Suppose you need to compute $a \cdot b \cdot c$. You can't do this in one R1CS constraint (that would require two multiplications), but you can introduce a helper variable $t = a \cdot b$, then write:

- Constraint 1: $a \times b = t$
- Constraint 2: $t \times c = \text{result}$

Two constraints, each with one multiplication. This is the general pattern: any polynomial computation of degree $d$ can be flattened into $O(d)$ R1CS constraints by naming intermediate products. The witness grows to include these intermediate values, but that's fine since the prover knows them.

This decomposition is why R1CS can encode arbitrary arithmetic circuits. Every gate becomes one constraint. The "one multiplication" rule isn't a limitation; it's a *normal form* that any computation can be converted into.

**Formal claim**: Any arithmetic circuit with $m$ multiplication gates and $a$ addition gates can be expressed as an R1CS with exactly $m$ constraints. The witness vector has length at most $m + a + \text{inputs} + \text{outputs}$. Addition gates require no constraints; they're absorbed into the linear combinations. Each multiplication gate contributes one constraint of the form $(A_i \cdot Z) \times (B_i \cdot Z) = C_i \cdot Z$.

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



## Two Ways to Prove R1CS

Once we have R1CS constraints, how do we prove they're all satisfied? There are two major approaches.

### Approach 1: QAP (Quadratic Arithmetic Program)

**Historical context**: QAP was introduced by Gennaro, Gentry, Parno, and Rabin in the **Pinocchio** system (2013), one of the first practical SNARKs. Groth16 (2016) refined and optimized this approach, achieving the smallest proof size known for pairing-based systems. Today, QAP is primarily associated with Groth16. Modern systems have moved to other arithmetizations (PLONKish, AIR, sum-check), but QAP remains important for applications where proof size is paramount.

**The Key Idea**: Instead of checking $m$ separate constraints, check one polynomial divisibility.

For each column $j$ of the R1CS matrices, define polynomials $A_j(X), B_j(X), C_j(X)$ that interpolate the column values at points $\{1, 2, \ldots, m\}$. (So $A_j(i)$ equals the entry in row $i$, column $j$ of matrix $A$.)

Now let $\vec{Z} = (Z_0, Z_1, \ldots, Z_n)$ be the **witness vector**, the full assignment including the constant 1, public inputs, and private witness values. Define:
$$A(X) = \sum_j Z_j \cdot A_j(X), \quad B(X) = \sum_j Z_j \cdot B_j(X), \quad C(X) = \sum_j Z_j \cdot C_j(X)$$

Each $Z_j$ is a scalar (from the witness), while $A_j(X)$ is a polynomial. The sum computes a linear combination, exactly mirroring how R1CS constraints are matrix-vector products.

The R1CS is satisfied iff $A(X) \cdot B(X) - C(X) = 0$ at all constraint points $\{1, 2, \ldots, m\}$.

By the Factor Theorem, this means the vanishing polynomial $Z_H(X) = (X-1)(X-2)\cdots(X-m)$ divides $A(X) \cdot B(X) - C(X)$.

**The QAP Check**: Prover exhibits quotient $H(X)$ such that:
$$A(X) \cdot B(X) - C(X) = H(X) \cdot Z_H(X)$$

We develop QAP fully in Chapter 12, where Groth16 uses it to achieve the smallest possible pairing-based proofs.

### Approach 2: Sum-Check on Multilinear Extensions (Spartan)

**Historical context**: Spartan was introduced by Setty in 2019, reviving ideas from the GKR protocol (2008) and sum-check literature. While Groth16 uses univariate polynomials and FFTs, Spartan showed that **multilinear extensions** and the **sum-check protocol** could handle R1CS directly, without Lagrange interpolation, without roots of unity, and with optimal prover time. This "sum-check renaissance" led to systems like Lasso, Jolt, and HyperNova.

**The Core Insight**: R1CS constraint satisfaction can be expressed as a polynomial sum equaling zero:

$$\sum_{x \in \{0,1\}^k} \tilde{\text{eq}}(x) \cdot \left[\tilde{A}(x) \cdot \tilde{B}(x) - \tilde{C}(x)\right] = 0$$

where $\tilde{A}(x) = \sum_{y \in \{0,1\}^k} \tilde{A}_{\text{matrix}}(x, y) \cdot \tilde{Z}(y)$ is the MLE of the matrix-vector product.

**Why This Matters**:

1. **Time-optimal proving**: The prover's work is $O(N)$ where $N$ is the number of constraints, just reading the constraints, no FFTs.

2. **Sparsity-preserving**: Multilinear extensions preserve the structure of sparse matrices. In R1CS, most matrix entries are zero. The MLE directly reflects this sparsity.

3. **Natural fit with sum-check**: The sum-check protocol (Chapter 3) is designed exactly for this type of problem.

**Comparing QAP and Spartan**:

| Property | QAP (Groth16) | Spartan |
|----------|---------------|---------|
| Polynomial type | Univariate, high-degree | Multilinear |
| Core technique | Divisibility by $Z_H(X)$ | Sum-check |
| Prover time | $O(N \log N)$ | $O(N)$ |
| Setup | Circuit-specific trusted | Transparent |

**When to use each**:

- **Groth16 (QAP)**: When proof size is the dominant constraint. On-chain verification on Ethereum costs gas proportional to proof size, making Groth16's 128-byte proofs attractive despite the circuit-specific setup. Use when your circuit is stable and you can afford a trusted ceremony.

- **Spartan / sum-check systems**: When prover time matters most. The $O(N)$ prover (vs $O(N \log N)$ for FFT-based systems) becomes significant at scale. Transparent setup avoids trust assumptions entirely. Natural fit for recursive composition and folding schemes (Nova, HyperNova). The tradeoff: larger proofs and more expensive verification.



## PLONKish Arithmetization

R1CS isn't the only way to encode computations. **PLONKish** takes a fundamentally different approach, one that's become so influential it dominates modern ZK applications.

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

This is where the **permutation argument** enters. The circuit's wiring defines a permutation $\sigma$ on wire positions. Copy constraints are satisfied if:

$$\text{value at position } i = \text{value at position } \sigma(i)$$

PLONK proves this via a grand product check: with random challenges $\beta, \gamma$, verify:

$$\prod_i \frac{f(i) + \beta \cdot i + \gamma}{f(i) + \beta \cdot \sigma(i) + \gamma} = 1$$

If copy constraints hold, corresponding terms cancel. A mismatch disrupts the product.

### When to Use PLONKish

PLONKish shines when you need **flexibility without sacrificing succinctness**:

- **Universal setup**: One ceremony covers all circuits up to a size bound, so you can deploy new circuits without new ceremonies
- **Custom gates**: Optimize specific operations (hash functions, range checks, elliptic curve arithmetic)
- **Mature tooling**: The PLONKish ecosystem (Halo 2, Plonky2) offers production-ready implementations

The tradeoff versus Groth16: slightly larger proofs (~2-3x), but no circuit-specific ceremony.



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

**Why CCS? The Folding Era.** You might wonder why we need yet another format when we have R1CS and PLONK. The answer is folding (Chapter 21). Newer protocols like Nova and HyperNova work by "folding" two proof instances into one. It turns out that R1CS folds easily, but PLONKish constraints do not. CCS was invented to give us the best of both worlds: the expressiveness of PLONK's custom gates with the foldability of R1CS's matrix structure.

**CCS (Customizable Constraint Systems)** provides a unifying abstraction that captures all three formats without overhead.

### The CCS Framework

A CCS instance consists of:

- **Matrices** $M_1, \ldots, M_t$: sparse matrices over $\mathbb{F}$, encoding constraint structure
- **Constraint specifications**: which matrices combine in each constraint, with what operation

The key insight: any constraint system can be expressed as:

$$\sum_i c_i \cdot \bigcirc_{j \in S_i} M_j \cdot z = 0$$

where:

- $z$ is the witness vector (including public inputs and the constant 1)
- $S_i$ specifies which matrices participate in term $i$
- $\bigcirc$ is the Hadamard (element-wise) product
- $c_i$ are scalar coefficients

**Reading this formula**: Each term $i$ in the sum works as follows:

1. Take some subset of matrices $\{M_j : j \in S_i\}$
2. Multiply each matrix by the witness vector $z$, getting vectors $M_j \cdot z$
3. Hadamard-multiply these vectors together (element-wise): $\bigcirc_{j \in S_i} (M_j \cdot z)$
4. Scale the result by coefficient $c_i$

The constraint is satisfied when all these terms sum to zero.

**Why Hadamard products?** The Hadamard product is what lets CCS express multiplication. In R1CS, the constraint $(A \cdot z) \circ (B \cdot z) = C \cdot z$ involves multiplying two linear combinations element-wise, which is a Hadamard product. In PLONKish, the term $Q_M \cdot a \cdot b$ multiplies wire values, again element-wise across all gates. The Hadamard product is the "multiplication primitive" that CCS builds from.

**Why this generalizes everything**: The formula is a sum of scaled Hadamard products of matrix-vector products. This captures:

- **Linear constraints**: Use a single matrix in $S_i$ (no Hadamard needed)
- **Quadratic constraints**: Hadamard-multiply two matrix-vector products
- **Higher-degree constraints**: Hadamard-multiply more matrices
- **Multiple constraint types**: Different terms $i$ can have different structures

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

A transition constraint like $s_{i+1} = 2 \cdot s_i + 1$ becomes:

- Matrices: $M_{\text{curr}}$ (extracts current-row values), $M_{\text{next}}$ (extracts next-row values), $M_{\text{const}}$ (constant column)
- The constraint $s' - 2s - 1 = 0$ becomes:

$$1 \cdot (M_{\text{next}} \cdot z) + (-2) \cdot (M_{\text{curr}} \cdot z) + (-1) \cdot (M_{\text{const}} \cdot z) = 0$$

Here all terms have $|S_i| = 1$ (no Hadamard products), so the constraint is purely linear in state variables. Quadratic AIR constraints (like $s' = s^2$) would use Hadamard: $(M_{\text{next}} \cdot z) - (M_{\text{curr}} \cdot z) \circ (M_{\text{curr}} \cdot z) = 0$.

### Why CCS Matters

**1. Unified tooling.** Compilers, analyzers, and optimizers can target CCS once. The specific frontend (Circom, Cairo, Noir) produces CCS; the backend (Spartan, Nova, HyperNova) consumes it.

**2. Folding scheme compatibility.** HyperNova folds CCS instances directly. Any constraint format expressible as CCS inherits folding for free, with no separate construction needed.

**3. Format-agnostic optimization.** Matrix sparsity, constraint reordering, and parallel proving apply uniformly regardless of the original constraint format.

**4. Research unification.** Theoretical results about CCS apply to all formats it subsumes.

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

**The Takeaway**: Bitwise operations are roughly 100x more expensive than field operations. This is why:

- ZK-friendly hash functions (Poseidon, Rescue) exist because they avoid bit operations
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



## Lookup Tables: The Modern Approach

Lookup arguments represent the most significant optimization technique in modern ZK systems. They sidestep bit decomposition entirely by replacing computation with table membership.

### The Core Idea

Instead of proving *how* you computed a result, prove *that* the result appears in a precomputed table.

**Example**: To prove XOR of two 8-bit values:

**Traditional approach** (bit decomposition):

1. Decompose both inputs into 8 bits each (16 bitness constraints)
2. Compute XOR per bit: $c_i = a_i + b_i - 2a_i b_i$ (8 multiplication constraints)
3. Reconstruct output (1 constraint)
4. Total: ~25 constraints

**Lookup approach**:

1. Precompute a table of all $256 \times 256 = 65,536$ XOR results: $(a, b, a \oplus b)$
2. Prove the triple $(a, b, c)$ appears in this table
3. Total: ~3 constraints (regardless of operation complexity!)

The savings compound. A 64-bit XOR via bit decomposition costs ~130 constraints. Via lookups on 8-bit chunks: 8 lookups × 3 constraints = 24 constraints, a 5x improvement.

### Why This Isn't Crazy

At first glance, "prove membership in a 65,536-entry table" sounds worse than bit decomposition. Checking 65,536 possibilities naively would be astronomical. The key insight is that we don't check membership directly; we use *polynomial identity testing*.

The table becomes a polynomial. If $T = [t_1, \ldots, t_N]$, encode it as:
$$T(X) = \prod_{i=1}^{N} (X - t_i)$$

A value $v$ is in the table if and only if $T(v) = 0$. But evaluating this polynomial at a random point, or checking divisibility relationships between polynomials, costs $O(\log N)$ work, not $O(N)$.

The magic: polynomials let you reason about *all* table entries simultaneously via a single random evaluation. A table of size $2^{16}$ doesn't require $2^{16}$ checks; it requires one polynomial identity that holds only if every lookup is valid. The Schwartz-Zippel lemma guarantees that a cheating prover gets caught with overwhelming probability.

This is the same principle underlying all polynomial-based SNARKs: compress exponentially many checks into a constant number of random evaluations. Lookups are just a particularly clean application of this principle.

### How Lookup Arguments Work

The prover has a table $T = [t_1, t_2, \ldots, t_N]$ and claims that values $f_1, \ldots, f_m$ all appear in $T$.

**Plookup** (2020, Gabizon and Williamson): Uses a grand product argument. Sort the lookup values and table together, then check that adjacent elements satisfy a relationship that's only possible if every lookup value came from the table.

**LogUp** (2022, Haböck): Reformulates the product check as a sum of logarithmic derivatives:
$$\sum_i \frac{1}{X - f_i} = \sum_j \frac{m_j}{X - t_j}$$
where $m_j$ is the multiplicity of table element $t_j$ among the lookups. This is more efficient for tables with repeated accesses.

**Lasso** (2023, Setty et al.): Combines lookups with sum-check, achieving prover time proportional to the number of lookups rather than the table size. This enables tables of size $2^{128}$ or larger, covering operations like full 64-bit multiplication in a single lookup.

### What Lookups Enable

**Range proofs without bit decomposition**: A table $[0, 1, 2, \ldots, 2^{16}-1]$ proves 16-bit range with one lookup instead of 16 bitness constraints.

**Efficient hash functions**: Even non-ZK-friendly hashes become tractable. SHA-256's bitwise operations can be replaced by table lookups on chunks.

**zkVMs at scale**: Systems like Jolt prove CPU instruction execution via lookups. Each instruction (ADD, XOR, MUL, etc.) becomes a table lookup. The instruction's semantics are "baked into" the table; the circuit just checks membership.

**Memory operations**: Read-write memory can be verified via sorted lookup arguments, proving that memory accesses are consistent without encoding RAM semantics in constraints.

### The Lookup Landscape

| Protocol | Prover Cost | Table Size Limit | Best For |
|----------|-------------|------------------|----------|
| Plookup | $O(N \log N)$ | ~$2^{20}$ | Moderate tables, PLONKish |
| LogUp | $O(N \log N)$ | ~$2^{20}$ | Repeated accesses |
| Lasso | $O(m \log m)$ | ~$2^{128}$ | Huge tables, zkVMs |

Here $N$ is the circuit size and $m$ is the number of lookups.

### Design Implications

Lookups shift circuit design philosophy:

**Before lookups**: Minimize bit operations. Use ZK-friendly primitives. Accept that some operations are inherently expensive.

**After lookups**: Think in terms of table design. Any function with a reasonable domain can become a lookup. The question becomes: what's the optimal table decomposition?

For a 64-bit operation, you might:

- Use 8 lookups into $2^{16}$-entry tables (8-bit chunks, twice per operand)
- Use 4 lookups into $2^{32}$-entry tables (16-bit chunks)
- Use 1 lookup into a $2^{128}$-entry virtual table (Lasso-style)

The optimal choice depends on table construction costs, lookup argument efficiency, and memory constraints.



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



## The Big Picture

We've traced the path from programs to proofs:

1. **Program** → A computation we want to prove

2. **Execution trace** → The witness, capturing every intermediate state (registers, memory, etc.)

3. **Constraint system** → Algebraic rules the trace must satisfy:

   - R1CS: $(A \cdot Z) \circ (B \cdot Z) = C \cdot Z$
   - PLONK: Universal gate + permutation
   - AIR: Transition polynomials (STARKs)

4. **Polynomial representation** → The constraints become polynomial identities:

   - QAP: Divisibility by vanishing polynomial
   - Sum-check: Sum over hypercube equals zero
   - PIOP: Polynomial oracle proofs

5. **Proof system** → Polynomial commitments + algebraic checks verify the identity

Arithmetization is the bridge between computation and algebra. It's where computer science meets cryptography, and where clever encoding can save orders of magnitude in proof cost.



## Key Takeaways

1. **Circuit satisfiability vs. evaluation**: Most applications prove knowledge of a secret witness, not just correct evaluation.

2. **The witness is everything**: It's the complete set of values (public, private, and intermediate) that satisfies the constraints.

3. **Execution trace as witness**: The prover records their entire computation; the circuit verifies the recording.

4. **Time and memory consistency**: The trace must follow transition rules (local checks) and memory rules (permutation checks).

5. **R1CS**: Expresses constraints as $(A \cdot Z) \times (B \cdot Z) = C \cdot Z$. Universal but can be verbose.

6. **Three constraint formats**: R1CS (sparse matrices), PLONKish (gates + selectors), AIR (transition constraints). CCS unifies them all.

7. **Bit decomposition is expensive**: A 64-bit operation costs ~65-200 constraints via traditional encoding.

8. **Lookup arguments changed everything**: Plookup, LogUp, and Lasso replace expensive bit operations with cheap table membership proofs, enabling efficient zkVMs and non-ZK-friendly operations.

9. **Frontend/backend split**: Frontends handle arithmetization; backends handle proving. They can be mixed and matched.

# Chapter 13: PLONK: Universal SNARKs and the Permutation Argument

By 2018, Groth16 had proven SNARKs worked in production. Zcash was live, proofs were 128 bytes, verification was fast. But every protocol upgrade required a new trusted setup ceremony—a multi-party computation specific to that circuit. For a project planning rapid iteration, this was a bottleneck. The cryptographic world wanted a setup you could perform once and reuse for any circuit.

Ariel Gabizon, Zachary Williamson, and Oana Ciobotaru found the path. Their insight was *permutations*: instead of encoding circuit structure directly into the setup, separate two concerns: what each gate computes (local) and how gates connect (global). The wiring could be encoded as a permutation, checked with a polynomial argument that worked identically for any circuit.

The result was PLONK (2019): **P**ermutations over **L**agrange-bases for **O**ecumenical **N**oninteractive arguments of **K**nowledge. "Oecumenical" signals universality: one ceremony suffices for all circuits up to a maximum size. Since PLONK needs only powers of tau (no circuit-specific Phase 2), the entire setup is **updatable**: anyone can strengthen security by adding a contribution, without coordinating with previous participants.

PLONK's modularity extends to the commitment scheme. The core is a **Polynomial IOP**: an interactive protocol where the prover sends polynomials and the verifier queries evaluations. Compile it with KZG for constant-size proofs with trusted setup. Compile with FRI for larger proofs without trust assumptions. The IOP is unchanged; only the cryptographic layer differs.

The cost of universality is larger proofs (~400-500 bytes versus 128) and more verification work (~10 pairings versus 3). Whether this trade-off makes sense depends on deployment constraints: Groth16 remains preferred when proof size or verification cost is critical; PLONK variants dominate when development velocity or custom gates matter more.

## Architecture: Gates and Copy Constraints

Chapter 8 introduced PLONKish arithmetization: the universal gate equation $Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot ab + Q_C = 0$ and the permutation argument for copy constraints. Here we develop the full protocol.

The key architectural distinction from R1CS: PLONK separates gate constraints (each gate satisfies a polynomial equation relating its wires) from copy constraints (wires at different positions carry equal values when the circuit's topology demands it).

This separation has consequences for extensibility. Gate logic becomes uniform: one equation for all gates. Wiring becomes explicit: a permutation argument proves all copy constraints simultaneously. Because gate definitions and wiring are independent, adding custom gates or lookup arguments doesn't require rethinking the copy constraint mechanism.

### The Gate Equation

Recall from Chapter 8: every gate has three wires ($a_i$, $b_i$, $c_i$) and the universal gate equation

$$Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot ab + Q_C = 0$$

where selectors $Q_L, Q_R, Q_O, Q_M, Q_C$ are public constants that program each gate's operation. Addition sets $Q_L = Q_R = 1, Q_O = -1$; multiplication sets $Q_M = 1, Q_O = -1$; constant assignment sets $Q_L = 1, Q_C = -k$. Modern variants extend to more wires (5+ instead of 3) and higher-degree terms ($a^5$ for Poseidon S-boxes).

### From Discrete Checks to Polynomial Identity

The circuit has $n$ gates. We want to verify all $n$ gate equations simultaneously.

Define a domain $H = \{1, \omega, \omega^2, \ldots, \omega^{n-1}\}$ where $\omega$ is a primitive $n$-th root of unity. The $i$-th gate corresponds to domain point $\omega^i$.

Each selector has one value per gate. For $Q_L$, we have a vector $(Q_{L,0}, Q_{L,1}, \ldots, Q_{L,n-1})$ where $Q_{L,i}$ is the left-wire selector at gate $i$. Interpolation finds the unique polynomial $Q_L(X)$ of degree $< n$ passing through the points $(\omega^0, Q_{L,0}), (\omega^1, Q_{L,1}), \ldots, (\omega^{n-1}, Q_{L,n-1})$. The result: $Q_L(\omega^i) = Q_{L,i}$ for all $i$. We do the same for $Q_R, Q_O, Q_M, Q_C$, and for the witness polynomials $a(X), b(X), c(X)$ (where $a(\omega^i) = a_i$, the left input at gate $i$).

The witness structure differs from R1CS. In R1CS (Chapter 8), the witness is a single flattened vector $Z = (1, \text{public inputs}, \text{private inputs}, \text{intermediate values})$. Each wire has exactly one index in $Z$. When two constraints reference the same wire, they use the same index; wiring is implicit in the indexing scheme.

PLONK structures the witness differently: three separate vectors $(a, b, c)$, each of length $n$ (the number of gates). Entry $a_i$ is gate $i$'s left input; $b_i$ is its right input; $c_i$ is its output. When the same value appears in multiple positions (say, a variable feeding two different gates) it occupies multiple slots in these vectors. This has a crucial consequence: PLONK needs explicit "copy constraints" to enforce that slots holding the same logical wire actually contain the same value. We'll see how this works shortly.

To make this concrete, consider $y = (x + z) \cdot z$ with $x = 3$, $z = 2$, so $y = 10$.

*R1CS representation* (2 constraints, 5 wires):

Witness vector: $Z = (1, x, z, v_1, y) = (1, 3, 2, 5, 10)$ where $v_1 = x + z$.

$$A = \begin{pmatrix} 1 & 1 & 0 & 0 \\ 0 & 0 & 1 & 0 \end{pmatrix}, \quad B = \begin{pmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \end{pmatrix}, \quad C = \begin{pmatrix} 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \end{pmatrix}$$

(Columns correspond to $x, z, v_1, y$; we omit the constant column for brevity.)

Row 1: 

$(1 \cdot x + 1 \cdot z) \times (1) = v_1$ checks $x + z = v_1$.

Row 2:

$(1 \cdot z) \times (1 \cdot v_1) = y$ checks $z \cdot v_1 = y$.

The matrices encode *which wires participate in which constraints*. Wire $z$ (column 2) appears in both rows; the matrix structure encodes this sharing.

*PLONK representation* (2 gates):

| Gate | $a$ | $b$ | $c$ | $Q_L$ | $Q_R$ | $Q_O$ | $Q_M$ | $Q_C$ |
|------|-----|-----|-----|-------|-------|-------|-------|-------|
| 1    | 3   | 2   | 5   | 1     | 1     | -1    | 0     | 0     |
| 2    | 5   | 2   | 10  | 0     | 0     | -1    | 1     | 0     |

Witness vectors: $a = (3, 5)$, $b = (2, 2)$, $c = (5, 10)$.

Gate 1:

$1 \cdot 3 + 1 \cdot 2 + (-1) \cdot 5 + 0 + 0 = 0$ $\checkmark$ (addition)

Gate 2:

$0 + 0 + (-1) \cdot 10 + 1 \cdot 5 \cdot 2 + 0 = 0$ $\checkmark$ (multiplication)

Notice: $z = 2$ appears twice ($b_1$ and $b_2$), and $v_1 = 5$ appears twice ($c_1$ and $a_2$). The gate equations don't enforce $b_1 = b_2$ or $c_1 = a_2$; a cheating prover could use different values. Copy constraints will enforce these equalities.

The structural difference: R1CS matrices *select* from a shared witness vector (same wire, same column, automatic equality). PLONK has vectors where each gate slot is independent (same value, different slots, explicit copy constraints needed).

How does this compare to QAP (Chapter 12)? In QAP, each wire $j$ gets basis polynomials $A_j(X), B_j(X), C_j(X)$ encoding how that wire participates across all constraints. The witness appears as coefficients weighting these basis polynomials: $A(X) = \sum_j z_j A_j(X)$. The basis polynomials encode the circuit structure.

PLONK separates these concerns differently:

- **Selector polynomials** ($Q_L, Q_R, Q_O, Q_M, Q_C$): Define the circuit. Fixed once the circuit is designed. Different circuits have different selectors.
- **Witness polynomials** ($a, b, c$): Computed fresh by the prover for each proof. Different inputs produce different witness values, interpolated into different polynomials.

Circuit structure lives in the selector polynomials, which are ordinary polynomials—not special objects requiring circuit-specific setup. This separation is what enables universality: the same trusted setup works for any circuit, because it doesn't need to "know" about selectors in advance.

With all these polynomials defined, the per-gate equation $Q_L \cdot a + Q_R \cdot b + Q_O \cdot c + Q_M \cdot ab + Q_C = 0$ becomes a polynomial identity:

$$Q_L(X) \cdot a(X) + Q_R(X) \cdot b(X) + Q_O(X) \cdot c(X) + Q_M(X) \cdot a(X) \cdot b(X) + Q_C(X) = 0$$

for all $X \in H$.

If this holds on $H$, the vanishing polynomial $Z_H(X) = X^n - 1$ divides the left side. There exists quotient $t(X)$ with:

$$Q_L(X)a(X) + Q_R(X)b(X) + Q_O(X)c(X) + Q_M(X)a(X)b(X) + Q_C(X) = Z_H(X) \cdot t(X)$$

The prover demonstrates this divisibility: a single polynomial identity encoding all gate constraints.

## The Copy Constraint Problem

Gate equations ensure internal consistency: the output of each gate equals the specified function of its inputs. They say nothing about how gates connect.

Consider a circuit computing $y = (x + z) \cdot z$:

- Gate 1: Addition, output $c_1 = a_1 + b_1$
- Gate 2: Multiplication, output $c_2 = a_2 \cdot b_2$

The wiring requires $c_1 = a_2$ (Gate 1's output feeds Gate 2's left input) and $b_1 = b_2$ (variable $z$ feeds both gates).

Because PLONK's witness consists of three separate vectors $(a, b, c)$, nothing in the gate equation relates $c_1$ to $a_2$; they're independent entries. A cheating prover could satisfy all gate equations with disconnected, inconsistent values. The circuit would "verify" despite computing garbage.

**Copy constraints** are the explicit assertions: wire $i$ equals wire $j$. The challenge is proving all copy constraints efficiently (potentially thousands of equality assertions) without enumerating them individually.

The name "copy constraint" is slightly misleading. We aren't copying data from one location to another. We are enforcing *equality*: two wire slots that happen to hold the same logical variable must contain identical values. Think of it as a wormhole connecting two distant parts of the circuit instantaneously. The value at $c_1$ doesn't "flow" to $a_2$; rather, they are the same point in the circuit's logical topology, temporarily given different addresses for bookkeeping. The permutation argument detects whether these "same points" actually hold the same value.

## The Permutation Argument

PLONK's central innovation is reducing all copy constraints to a single polynomial identity via a **permutation argument**, building on techniques from Bayer and Groth (Eurocrypt 2012).

### From Gates to Cycles: The Conceptual Shift

Before diving into the mechanism, understand the key mental shift. So far, we've thought of circuits as *gates*: local computational units that take inputs and produce outputs. Copy constraints seem like *connections between gates*: wire $c_1$ connects to wire $a_2$.

The permutation argument reframes this. Instead of "connections," think of *equivalence classes*. All wires that should hold the same value belong to the same class. Within each class, the wires form a *cycle* under a permutation: $c_1 \to a_2 \to c_1$ (a 2-cycle), or longer chains like $a_1 \to b_3 \to c_5 \to a_1$ (a 3-cycle). Wires with no copy constraints form trivial 1-cycles (fixed points).

The grand product argument then asks: if we traverse each cycle, do all the values match? If wire $c_1$ maps to wire $a_2$ and they share the same value, their contributions to the product cancel. If every cycle closes properly (all values match within the equivalence class), the entire product equals 1.

This shift from "gates and wires" to "values and cycles" is why the permutation argument works. We're not checking connections one by one; we're verifying that the entire wiring topology is consistent in one algebraic stroke.

### Representing Wiring as a Permutation

Give each wire slot a unique identity (think of it as an "index" or "address"):

- Gate $i$'s left wire: $\text{id}(a_i) = \omega^i$
- Gate $i$'s right wire: $\text{id}(b_i) = k_1 \omega^i$
- Gate $i$'s output wire: $\text{id}(c_i) = k_2 \omega^i$

where $k_1, k_2$ are distinct constants separating the three wire "columns." The identity function $\text{id}$ maps wire slots to field elements; it's just a naming scheme.

The circuit's wiring defines a permutation $\sigma$ on wire identities. If wire $c_1$ connects to wire $a_2$, then $\sigma$ maps $c_1$'s identity to $a_2$'s identity (and vice versa; connected wires form cycles under $\sigma$). Unconnected wires map to themselves.

**Example**: For our circuit $y = (x + z) \cdot z$ with 2 gates, label the 6 wire slots as $a_1, b_1, c_1, a_2, b_2, c_2$. The copy constraints are $c_1 = a_2$ (output of gate 1 feeds gate 2) and $b_1 = b_2$ (variable $z$ used twice). The permutation $\sigma$ encodes this: $\sigma(c_1) = a_2$, $\sigma(a_2) = c_1$ (a 2-cycle), and $\sigma(b_1) = b_2$, $\sigma(b_2) = b_1$ (another 2-cycle). Wires $a_1$ and $c_2$ aren't copied anywhere, so $\sigma(a_1) = a_1$ and $\sigma(c_2) = c_2$ (fixed points).

The key insight: all copy constraints hold if and only if every wire's value equals the value at its connected position. Here $\sigma(w)$ denotes the *position* that wire $w$ is connected to (not a transformed value):

$$\text{value at position } w = \text{value at position } \sigma(w) \quad \forall w$$

### The Grand Product Check

How do we verify this equality-under-permutation efficiently?

Consider two multisets: the wire values $\{v_1, v_2, \ldots, v_{3n}\}$ and the same values permuted according to $\sigma$. If copy constraints hold, these multisets are identical; they contain the same elements, just in different order.

Testing multiset equality via products fails: $\{1, 6\}$ and $\{2, 3\}$ have equal products but differ. A randomized check succeeds with overwhelming probability.

Given random challenge $\gamma$:

$$\prod_{i=1}^{3n} (v_i + \gamma) = \prod_{i=1}^{3n} (v_{\sigma(i)} + \gamma)$$

Why is this sound? If the multisets differ (some value appears with different multiplicities), then the polynomials $\prod_{i=1}^{3n} (X + v_i)$ and $\prod_{i=1}^{3n} (X + v_{\sigma(i)})$ are distinct. By Schwartz-Zippel, distinct degree-$3n$ polynomials agree on at most $3n$ points, so a random $\gamma$ satisfies the equality with probability at most $3n/|\mathbb{F}|$ (negligible for cryptographic fields).

### Binding Values to Locations

The multiset check has a flaw. A cheating prover could satisfy copy constraints on some wires by *violating* them on others, as long as they swap equal amounts. The overall multiset remains unchanged even though specific equalities fail.

**Example**: Circuit requires $c_1 = a_2$. Honest values: $c_1 = 5$, $a_2 = 5$. Cheating prover sets $c_1 = 5$, $a_2 = 99$, but compensates by swapping some other wire that should be $99$ to $5$. The multiset of all values is preserved.

The fix: bind each value to its **location** using a second challenge $\beta$:

$$\text{randomized value} = v_i + \beta \cdot \text{id}_i + \gamma$$

where $\text{id}_i$ is the wire's identity (its domain point).

The grand product check becomes:

$$\prod_{w \in \text{wires}} \left( \text{value}(w) + \beta \cdot \text{id}(w) + \gamma \right) = \prod_{w \in \text{wires}} \left( \text{value}(w) + \beta \cdot \sigma(\text{id}(w)) + \gamma \right)$$

**Why this works (mini-example)**: Suppose we have just two wires that should be equal: wire $A$ at position 1 with value $v$, and wire $B$ at position 2 with value $v$. The permutation swaps their positions: $\sigma(1) = 2$, $\sigma(2) = 1$. Left side: $(v + \beta \cdot 1 + \gamma)(v + \beta \cdot 2 + \gamma)$. Right side: $(v + \beta \cdot 2 + \gamma)(v + \beta \cdot 1 + \gamma)$. Same factors, just reordered; products match. But if wire $B$ had value $v' \neq v$, the right side would be $(v + \beta \cdot 2 + \gamma)(v' + \beta \cdot 1 + \gamma)$; different factors, products don't match. The $\beta$ term "tags" each value with its location, so swapping positions only works if the values actually match.

The left side combines each wire's value with its own identity. The right side combines each wire's value with its *permuted* identity.

If $c_1 = a_2$ (copy constraint holds), the term for $c_1$ on the right equals the term for $a_2$ on the left; they cancel in the product. If $c_1 \neq a_2$, no cancellation occurs; the products differ.

### The Accumulator Polynomial

Computing a product over $3n$ terms naively requires $O(n)$ work per verification query, which is not succinct. PLONK encodes the product as a polynomial.

Define the **accumulator polynomial** $Z(X)$ recursively:

**Initialization**: $Z(\omega) = 1$

**Recursion**: For domain points $\omega^i$:

$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{(a_i + \beta \omega^i + \gamma)(b_i + \beta k_1\omega^i + \gamma)(c_i + \beta k_2\omega^i + \gamma)}{(a_i + \beta S_{\sigma_1}(\omega^i) + \gamma)(b_i + \beta S_{\sigma_2}(\omega^i) + \gamma)(c_i + \beta S_{\sigma_3}(\omega^i) + \gamma)}$$

where $S_{\sigma_1}, S_{\sigma_2}, S_{\sigma_3}$ are **permutation polynomials** encoding $\sigma$ for the three wire columns.

The accumulator starts at 1 and multiplies through all gates. Each step contributes: numerator terms for "original" identities, denominator terms for "permuted" identities. If copy constraints hold, terms cancel across the cycle, and the accumulator returns to 1 at the end.

**The permutation constraints**:

1. **Initialization**: $Z(\omega) = 1$

   Enforced by: $(Z(X) - 1) \cdot L_1(X) = 0$ where $L_1(X)$ is the first Lagrange basis polynomial.

2. **Recursion**: The step-by-step product relation holds across the domain.

   Enforced by a polynomial identity involving $Z(X)$ and $Z(X\omega)$ (the "shifted" evaluation).

Both constraints, like the gate constraint, reduce to divisibility by $Z_H(X)$.


## Worked Example: The Permutation Argument in Action

The abstraction clarifies; the concrete convinces. Let's trace through the permutation argument on a minimal circuit: proving $z = (x + y) \cdot y$ for inputs $x = 2$, $y = 3$.

### The Circuit

**Gate 1** (addition): $c_1 = a_1 + b_1$
**Gate 2** (multiplication): $c_2 = a_2 \cdot b_2$

**Witness assignment** (for $x=2$, $y=3$, $z=15$):

- Gate 1: $a_1 = 2$, $b_1 = 3$, $c_1 = 5$
- Gate 2: $a_2 = 5$, $b_2 = 3$, $c_2 = 15$

**Copy constraints**:

- $c_1 = a_2$ (the intermediate value 5 feeds from Gate 1's output to Gate 2's left input)
- $b_1 = b_2$ (the input $y=3$ is used in both gates)

### Wire Identities

With domain $H = \{1, \omega\}$ (two gates) and constants $k_1, k_2$:

| Wire | Identity | Value |
|------|----------|-------|
| $a_1$ | $1$ | $2$ |
| $b_1$ | $k_1$ | $3$ |
| $c_1$ | $k_2$ | $5$ |
| $a_2$ | $\omega$ | $5$ |
| $b_2$ | $k_1\omega$ | $3$ |
| $c_2$ | $k_2\omega$ | $15$ |

### The Permutation $\sigma$

The wiring groups wire identities into cycles:

**Cycle 1** (the $y$ input): $b_1 \leftrightarrow b_2$
$$\sigma(k_1) = k_1\omega, \quad \sigma(k_1\omega) = k_1$$

**Cycle 2** (the intermediate value): $c_1 \leftrightarrow a_2$
$$\sigma(k_2) = \omega, \quad \sigma(\omega) = k_2$$

**Fixed points** (unconnected wires):
$$\sigma(1) = 1, \quad \sigma(k_2\omega) = k_2\omega$$

### Permutation Polynomials

The polynomials $S_{\sigma_1}(X)$, $S_{\sigma_2}(X)$, $S_{\sigma_3}(X)$ encode $\sigma$ for each wire column.

**$S_{\sigma_1}(X)$** (the $a$ wires):

- $S_{\sigma_1}(1) = \sigma(1) = 1$ (wire $a_1$ is a fixed point)
- $S_{\sigma_1}(\omega) = \sigma(\omega) = k_2$ (wire $a_2$ connects to $c_1$)

**$S_{\sigma_2}(X)$** (the $b$ wires):

- $S_{\sigma_2}(1) = \sigma(k_1) = k_1\omega$ (wire $b_1$ connects to $b_2$)
- $S_{\sigma_2}(\omega) = \sigma(k_1\omega) = k_1$ (wire $b_2$ connects to $b_1$)

**$S_{\sigma_3}(X)$** (the $c$ wires):

- $S_{\sigma_3}(1) = \sigma(k_2) = \omega$ (wire $c_1$ connects to $a_2$)
- $S_{\sigma_3}(\omega) = \sigma(k_2\omega) = k_2\omega$ (wire $c_2$ is a fixed point)

These evaluations uniquely determine the permutation polynomials (degree at most 1 over a domain of size 2).

### The Accumulator Trace

Let random challenges be $\beta$ and $\gamma$. The accumulator $Z(X)$ computes a running product.

**Initialization**: $Z(1) = 1$

**Step at $X = 1$** (processing Gate 1):

$$Z(\omega) = Z(1) \cdot \frac{(a_1 + \beta \cdot 1 + \gamma)(b_1 + \beta \cdot k_1 + \gamma)(c_1 + \beta \cdot k_2 + \gamma)}{(a_1 + \beta \cdot S_{\sigma_1}(1) + \gamma)(b_1 + \beta \cdot S_{\sigma_2}(1) + \gamma)(c_1 + \beta \cdot S_{\sigma_3}(1) + \gamma)}$$

Substituting values:

**Numerator** = $(2 + \beta + \gamma)(3 + \beta k_1 + \gamma)(5 + \beta k_2 + \gamma)$

**Denominator** = $(2 + \beta \cdot 1 + \gamma)(3 + \beta \cdot k_1\omega + \gamma)(5 + \beta \cdot \omega + \gamma)$

The $a_1$ term $(2 + \beta + \gamma)$ appears in both numerator and denominator; it cancels (wire $a_1$ is a fixed point).

The $b_1$ numerator term is $(3 + \beta k_1 + \gamma)$; the denominator has $(3 + \beta k_1\omega + \gamma)$.

The $c_1$ numerator term is $(5 + \beta k_2 + \gamma)$; the denominator has $(5 + \beta\omega + \gamma)$.

**Step at $X = \omega$** (processing Gate 2):

$$Z(\omega^2) = Z(\omega) \cdot \frac{(a_2 + \beta\omega + \gamma)(b_2 + \beta k_1\omega + \gamma)(c_2 + \beta k_2\omega + \gamma)}{(a_2 + \beta \cdot S_{\sigma_1}(\omega) + \gamma)(b_2 + \beta \cdot S_{\sigma_2}(\omega) + \gamma)(c_2 + \beta \cdot S_{\sigma_3}(\omega) + \gamma)}$$

Substituting:

**Numerator** = $(5 + \beta\omega + \gamma)(3 + \beta k_1\omega + \gamma)(15 + \beta k_2\omega + \gamma)$

**Denominator** = $(5 + \beta k_2 + \gamma)(3 + \beta k_1 + \gamma)(15 + \beta k_2\omega + \gamma)$

### The Cancellation

Now examine the full product $Z(\omega^2) = Z(1) \cdot [\text{fraction}_1] \cdot [\text{fraction}_2]$.

The copy constraint $c_1 = a_2 = 5$ means:

- Numerator of fraction 1 contains $(5 + \beta k_2 + \gamma)$
- Denominator of fraction 2 contains $(5 + \beta k_2 + \gamma)$

These cancel.

The copy constraint $b_1 = b_2 = 3$ means:

- Numerator of fraction 1 contains $(3 + \beta k_1 + \gamma)$
- Denominator of fraction 2 contains $(3 + \beta k_1 + \gamma)$

These cancel.

And conversely:

- Denominator of fraction 1 contains $(5 + \beta\omega + \gamma)$
- Numerator of fraction 2 contains $(5 + \beta\omega + \gamma)$

These cancel.

- Denominator of fraction 1 contains $(3 + \beta k_1\omega + \gamma)$
- Numerator of fraction 2 contains $(3 + \beta k_1\omega + \gamma)$

These cancel.

**Every term in the numerator has a matching term in the denominator across the full cycle.** The product collapses to $Z(\omega^2) = 1$.

Since $\omega^2 = 1$ for $n = 2$, we have $Z(1) = 1$ as required. The accumulator returns to its starting value, confirming all copy constraints hold.

### What If a Constraint Were Violated?

Suppose the prover cheats: sets $a_2 = 7$ instead of $5$ (breaking $c_1 = a_2$).

The term $(5 + \beta k_2 + \gamma)$ from $c_1$ no longer matches $(7 + \beta k_2 + \gamma)$ from the fraudulent $a_2$. No cancellation occurs. The accumulator ends at a value $\neq 1$, and the constraint $(Z(X) - 1) \cdot L_n(X) = 0$ fails.

The random challenges $\beta, \gamma$ ensure this failure is detectable with overwhelming probability.

## The Full Protocol

We now specify the complete PLONK protocol with KZG commitments.

### Preprocessed Data (Circuit-Specific)

Fixed at circuit compilation:

- Selector polynomial commitments: $[Q_L]_1, [Q_R]_1, [Q_O]_1, [Q_M]_1, [Q_C]_1$
- Permutation polynomial commitments: $[S_{\sigma_1}]_1, [S_{\sigma_2}]_1, [S_{\sigma_3}]_1$

### Common Reference String (Universal)

The SRS, shared across all circuits up to size $n$:

- $\{[1]_1, [\tau]_1, [\tau^2]_1, \ldots, [\tau^{n+5}]_1\}$
- $[\tau]_2$

The prover needs the full $\mathbb{G}_1$ sequence. The verifier needs only $[\tau]_2$, an asymmetry that enables efficient verification.

### Round 1: Commit to Witness

The prover:

1. Computes witness polynomials $a(X), b(X), c(X)$ by interpolating wire values
2. **Blinds** each polynomial for zero-knowledge: $a(X) \leftarrow a(X) + (b_1 X + b_2) Z_H(X)$, where $b_1, b_2$ are random field elements
3. Commits: sends $[a]_1, [b]_1, [c]_1$

Why does blinding work? The term $(b_1 X + b_2) Z_H(X)$ is zero on $H$ (since $Z_H(\omega^i) = 0$ for all $\omega^i \in H$), so adding it doesn't change the polynomial's values at gate positions; correctness is preserved. But outside $H$, this random term "scrambles" the polynomial, hiding information about the original witness values. The verifier will later query the polynomial at a random point $\zeta \notin H$; without blinding, these evaluations could leak witness information.

### Round 2: Commit to Accumulator

The prover:

1. Derives challenges $\beta, \gamma$ via Fiat-Shamir (hash of transcript including Round 1 commitments)
2. Computes accumulator polynomial $Z(X)$ from the recursive definition
3. Blinds with higher-degree term (three random scalars, since $Z$ is checked at two points: $z$ and $z\omega$)
4. Commits: sends $[Z]_1$

### Round 3: Compute Quotient

The prover:

1. Derives challenge $\alpha$ via Fiat-Shamir
2. Forms the combined constraint polynomial using $\alpha$ for random linear combination:

$$P(X) = \text{(gate constraint)} + \alpha \cdot \text{(permutation recursion)} + \alpha^2 \cdot \text{(permutation initialization)}$$

   The **permutation recursion** is the constraint that forces the accumulator to update correctly at each step: the polynomial form of "$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{\text{numerator}}{\text{denominator}}$" from the grand product. The **permutation initialization** is the boundary condition: the accumulator must start at 1, encoded as $(Z(X) - 1) \cdot L_1(X)$ where $L_1$ is the Lagrange polynomial that equals 1 at $\omega$ and 0 elsewhere.

3. Computes quotient: $t(X) = P(X) / Z_H(X)$
4. Splits $t(X)$ into lower-degree pieces for commitment (since $\deg(t) > n$)
5. Commits to quotient pieces

### Round 4: Evaluate and Open

The prover:

1. Derives evaluation point $\zeta$ via Fiat-Shamir
2. Evaluates all relevant polynomials at $\zeta$:

   - Witness: $a(\zeta), b(\zeta), c(\zeta)$
   - Accumulator: $Z(\zeta)$, and crucially $Z(\zeta\omega)$ (the shifted evaluation)
   - Permutation: $S_{\sigma_1}(\zeta), S_{\sigma_2}(\zeta)$
3. Sends evaluations to verifier
4. Computes batched opening proofs (linearization optimization)

### Round 5: Batched Opening Proofs

The prover:

1. Derives batching challenge $v$ via Fiat-Shamir
2. Constructs opening proof for all evaluations at $\zeta$ (batched)
3. Constructs opening proof for evaluation at $\zeta\omega$ (the shifted point)
4. Sends two KZG proofs

### Verification

The verifier performs the following steps:

**1. Reconstruct Challenges**

From the transcript (all prover commitments), derive:

- $\beta, \gamma$ from Round 1 commitments (for permutation argument)
- $\alpha$ from Round 2 commitments (for constraint aggregation)
- $\zeta$ from Round 3 commitments (evaluation point)
- $v$ from Round 4 evaluations (batching challenge)

All challenges are deterministic functions of the transcript via Fiat-Shamir.

**2. Compute the Linearization Polynomial Commitment**

The verifier computes a commitment $[r]_1$ to the "linearization polynomial": a carefully constructed combination that, when evaluated at $\zeta$, should equal zero if all constraints hold.

The linearization includes:

- **Gate constraint**: $[Q_L]_1 \cdot a(\zeta) + [Q_R]_1 \cdot b(\zeta) + [Q_O]_1 \cdot c(\zeta) + [Q_M]_1 \cdot a(\zeta)b(\zeta) + [Q_C]_1$
- **Permutation recursion** (scaled by $\alpha$): Terms involving $[Z]_1$, the permutation polynomials, and the evaluated witness values
- **Permutation initialization** (scaled by $\alpha^2$): $(Z(\zeta) - 1) \cdot L_1(\zeta)$

The key insight: most terms are linear combinations of known evaluations and committed polynomials. The verifier can compute $[r]_1$ using only the commitments received from the prover and the evaluation values.

**3. Compute the Expected Evaluation**

The verifier computes what $r(\zeta)$ *should* equal if the prover is honest. This involves:

- The quotient polynomial contribution: $t(\zeta) \cdot Z_H(\zeta)$
- Witness polynomial contributions at $\zeta$

**4. Batched Opening Verification**

The verifier checks two batched KZG opening proofs:

**Opening at $\zeta$**: All polynomials evaluated at $\zeta$ are batched using challenge $v$:
$$[F]_1 = [r]_1 + v[a]_1 + v^2[b]_1 + v^3[c]_1 + v^4[S_{\sigma_1}]_1 + v^5[S_{\sigma_2}]_1$$

The verifier checks that $[F]_1$ opens to the batched evaluation:
$$F(\zeta) = r(\zeta) + v \cdot a(\zeta) + v^2 \cdot b(\zeta) + \ldots$$

**Opening at $\zeta\omega$**: The accumulator's shifted evaluation:
$$e([Z]_1 - [Z(\zeta\omega)]_1, [\tau]_2) \stackrel{?}{=} e([W_{\zeta\omega}]_1, [\tau - \zeta\omega]_2)$$

where $[W_{\zeta\omega}]_1$ is the KZG opening proof for evaluation at $\zeta\omega$.

**5. Pairing Check**

The final verification reduces to two pairing equations (often combined into one via random linear combination):

$$e([W_\zeta]_1 + u \cdot [W_{\zeta\omega}]_1, [\tau]_2) = e(\zeta \cdot [W_\zeta]_1 + u\zeta\omega \cdot [W_{\zeta\omega}]_1 + [F]_1 - [E]_1, [1]_2)$$

where $u$ is a random challenge for batching the two opening proofs, and $[E]_1$ is the commitment to the expected evaluations.

**Verification Cost**

| Operation | Count |
|-----------|-------|
| Scalar multiplications in $\mathbb{G}_1$ | ~15-20 |
| Field multiplications | ~30-50 |
| Pairing computations | 2 |

Total verification time: ~5-10ms on commodity hardware, independent of circuit size.

## Proof Size Analysis

With KZG over BN254:

| Element | Size | Count | Total |
|---------|------|-------|-------|
| $\mathbb{G}_1$ commitments | 32 bytes | ~10 | 320 bytes |
| $\mathbb{G}_1$ opening proofs | 32 bytes | 2 | 64 bytes |
| Field element evaluations | 32 bytes | ~7 | 224 bytes |

**Total: ~600 bytes** (varies with optimizations)

This is 4-5× larger than Groth16's 128 bytes. The cost buys universality: one setup ceremony, any circuit.

## Why Roots of Unity?

PLONK's use of roots of unity (multiplicative subgroup of order $2^k$) is not arbitrary.

**FFT efficiency**: Polynomial operations (interpolation, multiplication, division) run in $O(n \log n)$ via FFT. Without roots of unity, these operations cost $O(n^2)$.

**Simple vanishing polynomial**: $Z_H(X) = X^n - 1$. Compact representation, efficient evaluation.

**Shift structure**: The accumulator's recursive relation compares $Z(X)$ and $Z(X\omega)$. Multiplication by $\omega$ shifts through the domain cyclically. This algebraic structure is essential for encoding the step-by-step product check.

Groth16 uses an arithmetic progression $\{1, 2, \ldots, m\}$ because its prover doesn't interpolate; it computes linear combinations of precomputed basis polynomials. The FFT advantage doesn't apply.

## Comparison: PLONK vs. Groth16

The systems embody different engineering philosophies.

### Witness Treatment

**Groth16**: Witness values are *coefficients*. The setup computes basis polynomials $A_j(X), B_j(X), C_j(X)$ for each wire. The prover forms $A(X) = \sum_j z_j A_j(X)$ as a linear combination.

**PLONK**: Witness values are *evaluations*. The prover interpolates to find polynomials passing through $(ω^i, a_i)$ for each gate.

This distinction explains why Groth16's setup is circuit-specific (it precomputes basis polynomials for the specific circuit) while PLONK's is universal (the prover does interpolation at proving time using generic powers of $\tau$).

### Wiring Mechanism

**Groth16**: Copy constraints are implicit. The R1CS matrices reference the same witness index for connected wires. No separate mechanism needed.

**PLONK**: Copy constraints are explicit via the permutation argument. This separation enables the universal setup: wiring information lives in circuit-specific preprocessed polynomials, not in the SRS.

### Constraint Expressiveness

**Groth16/R1CS**: Each constraint has form $(a \cdot w)(b \cdot w) = c \cdot w$, a single multiplication with linear combinations. High fan-in additions compress into one constraint.

**PLONK**: The gate equation handles one multiplication or addition per gate. But custom gates and lookup arguments extend expressiveness far beyond R1CS for complex operations.

### Trade-off Summary

| Aspect | Groth16 | PLONK |
|--------|---------|-------|
| Setup | Circuit-specific | Universal |
| Proof size | 128 bytes | ~500 bytes |
| Verification | 3 pairings | ~10 pairings |
| Prover work | MSM-dominated | FFT + MSM |
| Extensibility | Fixed | Custom gates, lookups |


## Custom Gates and Extensions

PLONK's gate equation generalizes naturally.

### More Wires

Modern systems (Halo2, UltraPLONK) use 5+ wires per gate:

$$\sum_{i=1}^{5} Q_i \cdot w_i + Q_{M_{12}} w_1 w_2 + Q_{M_{34}} w_3 w_4 + \cdots = 0$$

More wires mean fewer gates for complex operations.

### Higher-Degree Terms

The Poseidon hash uses $x^5$ in its S-box. A custom gate term $Q_{\text{pow5}} \cdot a^5$ computes this in one gate rather than five multiplications.

### Non-Native Arithmetic

A major driver for custom gates is *non-native arithmetic*: computing over a field different from the proof system's native field. PLONK (with BN254) operates over a ~254-bit prime field. But many applications require arithmetic over other fields: Bitcoin uses secp256k1's scalar field, Ethereum signatures use different curve parameters, and recursive proof verification requires operating over the "inner" proof's field.

Without custom gates, non-native field multiplication requires decomposing elements into limbs, performing schoolbook multiplication with carries, and range-checking intermediate results. A single non-native multiplication can cost 50+ native gates. Custom gates can batch these operations, reducing the cost by 5-10×. This is why efficient ECDSA verification (for Ethereum account abstraction or Bitcoin bridge verification) demands sophisticated custom gate design.

### Boolean Constraints

Enforcing $x \in \{0, 1\}$ requires $x(x-1) = 0$, equivalently $x^2 - x = 0$. With selector $Q_{\text{bool}}$:

$$Q_{\text{bool}} \cdot (a^2 - a) = 0$$

One gate, one constraint.

### Lookup Arguments

The most powerful extension. Rather than computing a function in gates, prove that (input, output) pairs appear in a precomputed table.

**Example**: Range check. Proving $x \in [0, 2^{16})$ via bit decomposition costs 16 gates. A lookup into a table of $\{0, 1, \ldots, 2^{16}-1\}$ costs ~3 constraints.

Chapter 14 develops lookup arguments in detail.


## UltraPLONK

"UltraPLONK" denotes PLONK variants combining custom gates and lookup arguments. These systems achieve dramatic efficiency gains for real-world circuits.

**Composite gates**: A single gate encoding multiple operations (e.g., $a + b = c$ AND $d \cdot e = f$ simultaneously).

**Lookup integration**: The permutation argument extends to prove set membership in lookup tables.

**Optimized hashing**: Poseidon-specific gates reduce hash computation by 10-20× compared to vanilla PLONK.

The architecture remains: polynomial IOP compiled with KZG (or alternatives). The IOP grows more sophisticated, but the verification structure persists.

**Aztec's evolution**: Aztec Labs, co-founded by Zac Williamson (one of PLONK's creators), developed UltraPLONK in their Barretenberg library. Their system has since evolved to **Honk**, which replaces the univariate polynomial IOP with sum-check over multilinear polynomials (similar to Spartan's approach). Honk retains PLONKish arithmetization but gains the memory efficiency of sum-check. For on-chain verification, Aztec compresses Honk proofs into UltraPLONK proofs; UltraPLONK's simpler verifier (fewer selector polynomials, no multilinear machinery) reduces gas costs. Their **Goblin PLONK** technique further optimizes recursive proof composition by deferring expensive elliptic curve operations rather than computing them at each recursion layer.


## Security Considerations

### Trusted Setup

PLONK's universality doesn't eliminate trust; it redistributes it.

The SRS still encodes secret $\tau$. If known, proofs can be forged. The advantage is logistical: one ceremony covers all circuits. Updates strengthen security without coordination.

Production deployments (Aztec, zkSync, Scroll) run multi-party ceremonies with hundreds of participants. The 1-of-N trust model, where security holds if any participant is honest, provides strong guarantees.

### Random Oracle Model

Fiat-Shamir security assumes hash functions behave as random oracles. Real hash functions are deterministic algorithms with structure.

No practical attacks are known. The gap between model and reality is a persistent concern across all Fiat-Shamir-compiled protocols.

### Soundness Assumptions

With KZG:

- **q-SDH**: Given powers of $\tau$, cannot produce $(c, g^{1/(\tau+c)})$
- **Discrete log**: Cannot compute $\tau$ from $g^\tau$

Without KZG (FRI compilation):

- **Collision resistance**: Hash function security

The assumption stack is well-studied. Pairing-based systems carry more algebraic structure (and assumption weight) than hash-based alternatives.


## Worked Example: Three-Gate Circuit

Consider proving knowledge of $x$ such that $(x + 1) \cdot x = 6$.

**Circuit**:

- Gate 1: Constant assignment, $b_1 = 1$
- Gate 2: Addition, $c_2 = a_2 + b_2$
- Gate 3: Multiplication, $c_3 = a_3 \cdot b_3$, constrained to equal 6

**Witness** (with $x = 2$):

- Gate 1: $a_1 = 0$, $b_1 = 1$, $c_1 = 0$ (unused output)
- Gate 2: $a_2 = 2$, $b_2 = 1$, $c_2 = 3$
- Gate 3: $a_3 = 3$, $b_3 = 2$, $c_3 = 6$

**Copy constraints**:

- $b_1 = b_2$ (constant 1 reused)
- $a_2 = b_3$ (input $x$ reused)
- $c_2 = a_3$ (addition output feeds multiplication)

**Permutation**:
Wires $b_1$ and $b_2$ form a cycle. Wires $a_2$ and $b_3$ form a cycle. Wires $c_2$ and $a_3$ form a cycle. Remaining wires are fixed points.

**Selector polynomials**: Interpolate selector values over domain $H = \{1, \omega, \omega^2\}$.

**Witness polynomials**: Interpolate $(a_1, a_2, a_3)$, $(b_1, b_2, b_3)$, $(c_1, c_2, c_3)$.

**Accumulator**: Starts at 1. After processing all gates, if copy constraints hold, returns to 1.

**Verification**: Evaluate combined constraint polynomial at random $\zeta$. If constraints satisfied, the evaluation is zero. Verify via KZG opening proofs.



## Key Takeaways

1. **Universal setup**: One ceremony, all circuits up to a size bound. Updateable security model.

2. **Separation of concerns**: Gate constraints (local correctness) separate from copy constraints (global wiring). Each has its own polynomial mechanism.

3. **The permutation argument**: Reduces all copy constraints to one polynomial identity via randomized grand product check.

4. **Witness as evaluations**: PLONK interpolates witness values. Groth16 uses them as coefficients. This architectural choice enables universality.

5. **Roots of unity**: FFT efficiency for polynomial operations. Shift structure for accumulator recursion. Not cosmetic but essential.

6. **Custom gates**: The framework generalizes. More wires, higher degrees, specialized operations. UltraPLONK extends vanilla PLONK dramatically.

7. **Lookup arguments**: Prove table membership instead of computation. Game-changing for non-arithmetic operations.

8. **Proof size trade-off**: ~500 bytes vs. Groth16's 128. Universality has a cost.

9. **Verification structure**: Two batched KZG proofs. Constant work regardless of circuit size.

10. **Deployment patterns**: PLONK derivatives are widely adopted for their development flexibility, while Groth16 persists where minimal proof size is paramount.

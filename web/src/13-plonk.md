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

The name "copy constraint" is slightly misleading. We aren't copying data from one location to another. We are enforcing *equality*: two wire slots that represent the same logical variable must contain identical values. The permutation argument detects whether slots that should hold the same value actually do.

## The Permutation Argument

PLONK's central innovation is reducing all copy constraints to a single polynomial identity via a **permutation argument**, building on techniques from Bayer and Groth (Eurocrypt 2012).

### From Gates to Cycles

Before diving into the mechanism, understand the key mental shift. So far, we've thought of circuits as *gates*: local computational units that take inputs and produce outputs. Copy constraints seem like *connections between gates*: wire $c_1$ connects to wire $a_2$.

The permutation argument reframes this. Instead of "connections," think of *equivalence classes*. All wires that should hold the same value belong to the same class. Within each class, the wires form a *cycle* under a permutation: $c_1 \to a_2 \to c_1$ (a 2-cycle), or longer chains like $a_1 \to b_3 \to c_5 \to a_1$ (a 3-cycle). Wires with no copy constraints form trivial 1-cycles (fixed points).

If we traverse each cycle, do all the values match? This shift from "gates and wires" to "values and cycles" is what makes efficient verification possible—we're not checking connections one by one, but verifying that the entire wiring topology is consistent in one algebraic test.

### Representing Wiring as a Permutation

The circuit's wiring defines a permutation $\sigma$ on wire slots. If two wires must hold the same value, $\sigma$ maps one to the other (and vice versa, forming a cycle). Unconnected wires map to themselves: $\sigma(w) = w$.

All copy constraints hold if and only if every wire's value equals the value at the position $\sigma$ maps it to:

$$\text{value}(w) = \text{value}(\sigma(w)) \quad \forall w$$

**Example**: For our circuit $y = (x + z) \cdot z$ with 2 gates, label the 6 wire slots as $a_1, b_1, c_1, a_2, b_2, c_2$. The copy constraints are $c_1 = a_2$ (output of gate 1 feeds gate 2) and $b_1 = b_2$ (variable $z$ used twice). The permutation $\sigma$ encodes this: $\sigma(c_1) = a_2$, $\sigma(a_2) = c_1$ (a 2-cycle), and $\sigma(b_1) = b_2$, $\sigma(b_2) = b_1$ (another 2-cycle). Wires $a_1$ and $c_2$ aren't copied anywhere, so $\sigma(a_1) = a_1$ and $\sigma(c_2) = c_2$ (fixed points).

### The Grand Product Check

How do we verify this equality-under-permutation efficiently?

For a circuit with $n$ gates, there are $3n$ wire slots (each gate has wires $a$, $b$, $c$). Consider two multisets: the wire values $\{v_1, v_2, \ldots, v_{3n}\}$ and the same values permuted according to $\sigma$. If copy constraints hold, these multisets are identical; they contain the same elements, just in different order.

A naive approach checks whether the products match:

$$\prod_{i=1}^{3n} v_i \stackrel{?}{=} \prod_{i=1}^{3n} v_{\sigma(i)}$$

This fails: $\{1, 6\}$ and $\{2, 3\}$ have equal products but differ. Adding a random challenge $\gamma$ fixes this:

$$\prod_{i=1}^{3n} (v_i + \gamma) = \prod_{i=1}^{3n} (v_{\sigma(i)} + \gamma)$$

Why is this sound? If the multisets differ (some value appears with different multiplicities), then the polynomials $\prod_{i=1}^{3n} (X + v_i)$ and $\prod_{i=1}^{3n} (X + v_{\sigma(i)})$ are distinct. By Schwartz-Zippel, distinct degree-$3n$ polynomials agree on at most $3n$ points, so a random $\gamma$ satisfies the equality with probability at most $3n/|\mathbb{F}|$ (negligible for cryptographic fields).

### Binding Values to Locations

The multiset check has a flaw. A cheating prover could satisfy copy constraints on some wires by *violating* them on others, as long as they swap equal amounts. The overall multiset remains unchanged even though specific equalities fail.

**Example**: Circuit requires $c_1 = a_2$. Honest values: $c_1 = 5$, $a_2 = 5$. Cheating prover sets $c_1 = 5$, $a_2 = 99$, but compensates by swapping some other wire that should be $99$ to $5$. The multiset of all values is preserved.

The fix: bind each value to its **location** using a second challenge $\beta$:

$$\text{randomized value} = v_i + \beta \cdot \text{id}_i + \gamma$$

Each wire slot gets a unique identity $\text{id}$:

- Gate $i$'s left wire: $\text{id}(a_i) = \omega^i$
- Gate $i$'s right wire: $\text{id}(b_i) = k_1 \omega^i$
- Gate $i$'s output wire: $\text{id}(c_i) = k_2 \omega^i$

where $k_1, k_2$ are distinct constants separating the three wire columns.

The grand product check becomes:

$$\prod_{w \in \text{wires}} \left( \text{value}(w) + \beta \cdot \text{id}(w) + \gamma \right) = \prod_{w \in \text{wires}} \left( \text{value}(w) + \beta \cdot \sigma(\text{id}(w)) + \gamma \right)$$

The left side combines each wire's value with its own identity. The right side combines each wire's value with its *permuted* identity.

To see why this works, consider two wires that should be equal: $c_1$ (output of gate 1, identity $k_2\omega^1$) and $a_2$ (left input of gate 2, identity $\omega^2$), both holding value $v$. The permutation swaps their identities: $\sigma(k_2\omega^1) = \omega^2$, $\sigma(\omega^2) = k_2\omega^1$.

Left side:

$$(v + \beta \cdot k_2\omega^1 + \gamma)(v + \beta \cdot \omega^2 + \gamma)$$

Right side (using $\sigma(k_2\omega^1) = \omega^2$ and $\sigma(\omega^2) = k_2\omega^1$):

$$(v + \beta \cdot \sigma(k_2\omega^1) + \gamma)(v + \beta \cdot \sigma(\omega^2) + \gamma) = (v + \beta \cdot \omega^2 + \gamma)(v + \beta \cdot k_2\omega^1 + \gamma)$$

Same factors, just reordered, so the products match.

Now suppose a cheating prover violates the copy constraint by putting value $v$ at $c_1$ but value $v' \neq v$ at $a_2$. The left side becomes:

$$(v + \beta \cdot k_2\omega^1 + \gamma)(v' + \beta \cdot \omega^2 + \gamma)$$

The right side becomes:

$$(v + \beta \cdot \omega^2 + \gamma)(v' + \beta \cdot k_2\omega^1 + \gamma)$$

These are different factors, so the products don't match. The $\beta$ term tags each value with its location, so the check detects when two positions that should hold equal values actually don't.

If $c_1 = a_2$ (copy constraint holds), the term for $c_1$ on the right equals the term for $a_2$ on the left; they cancel in the product. If $c_1 \neq a_2$, no cancellation occurs; the products differ.

### The Accumulator Polynomial

Computing a product over $3n$ terms naively requires $O(n)$ work per verification query, which is not succinct. PLONK encodes the product as a polynomial.

The **accumulator polynomial** $Z(X)$ computes a running product across all gates. It starts at 1, and at each gate multiplies in a ratio: numerator terms use the wire's own identity, denominator terms use the permuted identity. If all copy constraints hold, numerators and denominators cancel across the full circuit, and the accumulator returns to 1.

Define $Z(X)$ recursively:

**Initialization**: $Z(\omega) = 1$

**Recursion**: For domain points $\omega^i$:

$$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{(a_i + \beta \omega^i + \gamma)(b_i + \beta k_1\omega^i + \gamma)(c_i + \beta k_2\omega^i + \gamma)}{(a_i + \beta S_{\sigma_1}(\omega^i) + \gamma)(b_i + \beta S_{\sigma_2}(\omega^i) + \gamma)(c_i + \beta S_{\sigma_3}(\omega^i) + \gamma)}$$

The **permutation polynomials** $S_{\sigma_1}, S_{\sigma_2}, S_{\sigma_3}$ encode where $\sigma$ maps each wire's identity. For each gate $i$:

- $S_{\sigma_1}(\omega^i) = \sigma(\omega^i)$: where the left wire of gate $i$ maps to
- $S_{\sigma_2}(\omega^i) = \sigma(k_1\omega^i)$: where the right wire of gate $i$ maps to
- $S_{\sigma_3}(\omega^i) = \sigma(k_2\omega^i)$: where the output wire of gate $i$ maps to

If wire $c_1$ (identity $k_2\omega^1$) connects to wire $a_2$ (identity $\omega^2$), then $S_{\sigma_3}(\omega^1) = \omega^2$. Unconnected wires map to themselves: if $a_1$ has no copy constraint, $S_{\sigma_1}(\omega^1) = \omega^1$.

**The permutation constraints**:

1. **Initialization**: $Z(\omega) = 1$

   We need this constraint to hold only at the first domain point, not everywhere. Recall from Chapter 5 that $L_1(X)$ is the Lagrange basis polynomial that equals 1 at $\omega$ and 0 at all other roots of unity. Multiplying by $L_1(X)$ "activates" the constraint only where we want it:

   $$(Z(X) - 1) \cdot L_1(X) = 0$$

   At $X = \omega$: $(Z(\omega) - 1) \cdot 1 = 0$, so $Z(\omega) = 1$ is enforced.
   At other $X = \omega^i$: $(Z(\omega^i) - 1) \cdot 0 = 0$, satisfied regardless of $Z(\omega^i)$.

2. **Recursion**: The step-by-step product relation holds across the domain.

   At each gate $i$, the accumulator must satisfy:

   $$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{(a_i + \beta \omega^i + \gamma)(b_i + \beta k_1\omega^i + \gamma)(c_i + \beta k_2\omega^i + \gamma)}{(a_i + \beta S_{\sigma_1}(\omega^i) + \gamma)(b_i + \beta S_{\sigma_2}(\omega^i) + \gamma)(c_i + \beta S_{\sigma_3}(\omega^i) + \gamma)}$$

   As a polynomial identity, this becomes:

   $$Z(X\omega) \cdot \text{(denominator terms)} = Z(X) \cdot \text{(numerator terms)}$$

   Evaluating at $X = \omega^i$ gives the recurrence: $Z(X\omega)$ evaluated at $\omega^i$ equals $Z(\omega^{i+1})$.

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

The $(15 + \beta k_2\omega + \gamma)$ term appears in both numerator and denominator of step 2, so it cancels immediately (wire $c_2$ is a fixed point).

The interesting cancellations happen across steps. Consider wire $c_1$ (value 5, identity $k_2$):

- Step 1 numerator: $(5 + \beta k_2 + \gamma)$: the value plus its own identity
- Step 2 denominator: $(5 + \beta \cdot S_{\sigma_1}(\omega) + \gamma) = (5 + \beta k_2 + \gamma)$

Why does step 2's denominator have $k_2$? Because $S_{\sigma_1}(\omega)$ asks "where does wire $a_2$ map under $\sigma$?" Since $c_1 = a_2$ is a copy constraint, $\sigma$ maps $a_2$'s identity ($\omega$) to $c_1$'s identity ($k_2$). So $S_{\sigma_1}(\omega) = k_2$.

Similarly for wire $b_1 = b_2$ (value 3):

- Step 1 numerator: $(3 + \beta k_1 + \gamma)$
- Step 2 denominator: $(3 + \beta \cdot S_{\sigma_2}(\omega) + \gamma) = (3 + \beta k_1 + \gamma)$

Here $S_{\sigma_2}(\omega) = k_1$ because $\sigma$ maps $b_2$'s identity ($k_1\omega$) to $b_1$'s identity ($k_1$).

The converse cancellations work the same way: step 1's denominator terms match step 2's numerator terms because the permutation is symmetric (if $\sigma$ maps $a \to b$, it also maps $b \to a$).

Every term cancels. The result: $Z(\omega^2) = 1$.

Since $\omega^2 = 1$ for $n = 2$, we have $Z(1) = 1$ as required. The accumulator returns to its starting value, confirming all copy constraints hold.

### What If a Constraint Were Violated?

Suppose the prover cheats: sets $a_2 = 7$ instead of $5$ (breaking $c_1 = a_2$).

The term $(5 + \beta k_2 + \gamma)$ from $c_1$ no longer matches $(7 + \beta k_2 + \gamma)$ from the fraudulent $a_2$. No cancellation occurs. The accumulator ends at a value $\neq 1$, and the constraint $(Z(X) - 1) \cdot L_n(X) = 0$ fails.

The random challenges $\beta, \gamma$ ensure this failure is detectable with overwhelming probability.

## The Full Protocol

The core ideas are now in place: the gate equation checks local correctness, the permutation argument enforces wiring via a grand product, and the accumulator polynomial encodes this product for efficient verification. This section specifies the complete protocol with KZG commitments. It can be skipped on first reading without losing the conceptual thread.

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

   The **gate constraint** is $Q_L(X)a(X) + Q_R(X)b(X) + Q_O(X)c(X) + Q_M(X)a(X)b(X) + Q_C(X)$, the polynomial identity from earlier that encodes all gate equations. The **permutation recursion** forces the accumulator to update correctly at each step: the polynomial form of "$Z(\omega^{i+1}) = Z(\omega^i) \cdot \frac{\text{numerator}}{\text{denominator}}$" from the grand product. The **permutation initialization** is the boundary condition: the accumulator must start at 1, encoded as $(Z(X) - 1) \cdot L_1(X)$ where $L_1$ is the Lagrange polynomial that equals 1 at $\omega$ and 0 elsewhere.

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
4. Computes batched opening proofs (we explain the linearization trick in the verification section below)

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

The combined constraint polynomial $P(X)$ contains products like $Q_M(X) \cdot a(X) \cdot b(X)$. The verifier has commitments $[Q_M]_1$, $[a]_1$, $[b]_1$ but cannot compute $[Q_M \cdot a \cdot b]_1$ from these—there's no way to multiply group elements to get a commitment to a product of polynomials.

The linearization trick solves this. Once the prover sends evaluations $a(\zeta), b(\zeta)$ as field elements, these become scalars. The verifier can compute:

$$[Q_M]_1 \cdot a(\zeta) \cdot b(\zeta)$$

This scalar multiplication is possible and gives the right contribution at point $\zeta$. The verifier constructs the linearized commitment $[r]_1$:

- **Gate constraint**: $[Q_L]_1 \cdot a(\zeta) + [Q_R]_1 \cdot b(\zeta) + [Q_O]_1 \cdot c(\zeta) + [Q_M]_1 \cdot a(\zeta)b(\zeta) + [Q_C]_1$
- **Permutation recursion** (scaled by $\alpha$): Terms involving $[Z]_1$, the permutation polynomials, and the evaluated witness values
- **Permutation initialization** (scaled by $\alpha^2$): $(Z(\zeta) - 1) \cdot L_1(\zeta)$

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

PLONK's use of roots of unity (multiplicative subgroup of order $2^k$) is not arbitrary. Three properties make them essential:

- Polynomial operations (interpolation, multiplication, division) run in $O(n \log n)$ via FFT. Without roots of unity, these cost $O(n^2)$.
- The vanishing polynomial has a simple form: $Z_H(X) = X^n - 1$. Compact representation, efficient evaluation.
- The accumulator's recursive relation compares $Z(X)$ and $Z(X\omega)$. Multiplication by $\omega$ shifts through the domain cyclically, which is essential for encoding the step-by-step product check.

Groth16 uses an arithmetic progression $\{1, 2, \ldots, m\}$ because its prover doesn't interpolate; it computes linear combinations of precomputed basis polynomials. The FFT advantage doesn't apply.

## Comparison: PLONK vs. Groth16

The preceding sections developed these architectural differences in detail. Here's a side-by-side summary:

| Aspect | Groth16 | PLONK |
|--------|---------|-------|
| Witness role | Coefficients weighting basis polynomials | Evaluations interpolated into polynomials |
| Copy constraints | Implicit (R1CS matrix reuses indices) | Explicit (permutation argument) |
| Setup | Circuit-specific (basis polynomials in SRS) | Universal (only powers of $\tau$) |
| Constraint form | $(a \cdot w)(b \cdot w) = c \cdot w$ | $Q_L a + Q_R b + Q_O c + Q_M ab + Q_C = 0$ |
| Proof size | 128 bytes | ~500 bytes |
| Verification | 3 pairings | 2 pairings + ~15 scalar muls |
| Prover work | MSM-dominated | FFT + MSM |
| Extensibility | Fixed | Custom gates, lookups |


## Custom Gates and Extensions

PLONK's gate equation generalizes naturally. Custom gates aren't exclusive to PLONKish systems—Spartan's CCS (Customizable Constraint Systems) also supports arbitrary polynomial constraints, generalizing both R1CS and PLONKish arithmetization. But PLONK variants were the first to deploy custom gates widely in production.

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

"UltraPLONK" denotes PLONK variants combining custom gates and lookup arguments. These systems achieve dramatic efficiency gains for real-world circuits: composite gates encode multiple operations simultaneously (e.g., $a + b = c$ and $d \cdot e = f$ in one gate), the permutation argument extends to prove set membership in lookup tables, and Poseidon-specific gates reduce hash computation by 10-20× compared to vanilla PLONK. The architecture remains a polynomial IOP compiled with KZG (or alternatives)—the IOP grows more sophisticated, but the verification structure persists.

Aztec Labs, co-founded by Zac Williamson (one of PLONK's creators), developed UltraPLONK in their Barretenberg library. Their system has since evolved to Honk, which replaces the univariate polynomial IOP with sum-check over multilinear polynomials (similar to Spartan's approach). Honk retains PLONKish arithmetization but gains the memory efficiency of sum-check (Chapter 21 explains why: sum-check's linear memory access pattern is cache-friendly, unlike FFT's butterfly shuffles). For on-chain verification, Aztec compresses Honk proofs into UltraPLONK proofs; UltraPLONK's simpler verifier (fewer selector polynomials, no multilinear machinery) reduces gas costs. Their Goblin PLONK technique further optimizes recursive proof composition by deferring expensive elliptic curve operations rather than computing them at each recursion layer.


## Security Considerations

### Trusted Setup

PLONK's universality doesn't eliminate trust; it redistributes it.

The SRS still encodes secret $\tau$. If known, proofs can be forged. The advantage is logistical: one ceremony covers all circuits. Updates strengthen security without coordination.

Production deployments (Aztec, zkSync, Scroll) run multi-party ceremonies with hundreds of participants. The 1-of-N trust model, where security holds if any participant is honest, provides strong guarantees.

### Soundness Assumptions

PLONK's security depends on the polynomial commitment scheme used:

- **With KZG**: Security relies on pairing-based assumptions (q-SDH, discrete log). These are well-studied but would break under quantum computers.
- **With FRI**: Security relies only on collision-resistant hashing. Fewer assumptions, and potentially quantum-resistant, but larger proofs.


## Key Takeaways

1. **Universal setup**: One ceremony works for all circuits up to a size bound. This comes from treating witness values as polynomial evaluations (interpolated at proving time) rather than coefficients (baked into setup).

2. **Separation of concerns**: Gate constraints check local correctness (each gate's equation holds). Copy constraints check global wiring (connected wires hold equal values). Each has its own polynomial mechanism.

3. **The permutation argument**: All copy constraints reduce to one polynomial identity. The accumulator polynomial computes a running product; if all constraints hold, it returns to 1.

4. **Roots of unity**: FFT enables $O(n \log n)$ polynomial operations. The shift structure ($Z(X)$ vs $Z(X\omega)$) encodes the accumulator's step-by-step recursion.

5. **The linearization trick**: The verifier can't compute commitments to polynomial products. Linearization uses the prover's evaluation values to turn polynomial multiplications into scalar multiplications of commitments.

6. **Proof size vs setup trade-off**: ~500 bytes (vs Groth16's 128 bytes) buys universality. Whether this trade-off makes sense depends on deployment constraints.

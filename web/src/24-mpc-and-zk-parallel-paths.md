# Chapter 24: MPC and ZK: Parallel Paths

In 1982, Andrew Yao posed a puzzle that sounded like a parlor game. Two millionaires meet at a party. Each wants to know who is richer, but neither wants to reveal their actual wealth. Is there a protocol that determines who has more money without either party learning anything else?

The question seems impossible. To compare two numbers, someone must see both numbers. A trusted third party could collect the figures, announce the winner, and burn the evidence. But what if there is no trusted party? What if the millionaires trust no one, not even each other?

The stakes extend far beyond money. Satellite operators need to check if their orbits will collide without revealing classified trajectories. Banks need to detect money laundering across institutions without exposing customer data. Nuclear inspectors need to verify warhead counts without learning weapon designs. In each case, the computation requires data that no single party can be trusted to see.

Yao proved the comparison can be done. Not by clever social arrangements or legal contracts, but by cryptography alone. The protocol he constructed, now called *garbled circuits*, allows two parties to jointly compute any function on their private inputs while revealing nothing but the output. Neither party sees the other's input. The trusted third party dissolves into mathematics.

This was the birth of **Secure Multiparty Computation** (MPC). The field expanded rapidly. In 1988, Ben-Or, Goldwasser, and Wigderson showed that with an honest majority of participants, MPC could achieve *information-theoretic* security: no computational assumption required, just the mathematics of secret sharing. The same year, Chaum, Crépeau, and Damgård proved that with dishonest majorities, MPC remained possible under cryptographic assumptions. By the early 1990s, the core theoretical question was settled: any function computable by a circuit could be computed securely by mutually distrustful parties.

The philosophical implications are striking. Computation, it turns out, does not require a single trusted processor. It can be *distributed* across adversaries who share nothing but a communication channel and a willingness to follow a protocol. The output emerges from the collaboration, but the inputs remain private. This is coordination without trust, agreement without revelation.

### Why MPC Belongs in This Book

Throughout this book, we've focused on trust between prover and verifier. The verifier need not believe the prover is honest; the proof itself carries the evidence. But there's another trust relationship we've quietly assumed: the prover has access to the witness. What if the witness is too sensitive to give to any single party?

Consider a company that wants to prove its financial reserves exceed its liabilities without revealing the actual figures to the auditor, the proving service, or anyone else. The company holds the witness (the books), but generating a ZK proof requires computation. If the company lacks the infrastructure to prove locally, it faces a dilemma: outsource the proving and expose the witness, or don't prove at all.

MPC offers an escape. The company secret-shares its witness among multiple proving servers. Each server sees only meaningless fragments. Together, they compute the proof without any single server learning the books. The witness never exists in one place. Trust is distributed rather than concentrated.

This is one of several approaches to the "who runs the prover?" problem:

**Prove locally.** Keep the witness on your own hardware. No trust required, but you need sufficient compute. For lightweight proofs this works; for zkVM-scale computation it may not.

**Distribute via MPC.** Secret-share the witness among multiple servers. No single server learns anything. Requires the servers not to collude (honest majority or computational assumptions). This chapter develops the techniques.

**Hardware enclaves (TEEs).** Run the prover inside a Trusted Execution Environment like Intel SGX or ARM TrustZone. The enclave attests that it ran the correct code on hidden inputs. Trust shifts from the server operator to the hardware manufacturer: not trustless, but a different trust assumption.

MPC and ZK also connect at a deeper level. MPC techniques directly yield ZK constructions through the "MPC-in-the-head" paradigm: simulate an MPC protocol inside the prover's mind, commit to the simulated parties' views, and let the verifier audit a subset. The parallel paths converge into a single construction.

This chapter traces both paths. We begin with the MPC problem itself, then develop two foundational approaches: secret-sharing protocols and garbled circuits. We examine oblivious transfer, the cryptographic primitive that enables input privacy. Finally, we show how MPC becomes ZK through the in-the-head transformation, completing the circle between these two pillars of programmable cryptography.



## The MPC Problem

The formal setting: $n$ parties hold private inputs $x_1, \ldots, x_n$. They want to learn $f(x_1, \ldots, x_n)$ for some agreed-upon function $f$, but nothing else. A trusted third party could collect everything, compute, and announce the result. MPC achieves the same outcome without the trusted party.

What does "nothing else" mean precisely? The security definition captures this through simulation: whatever a coalition of corrupt parties learns from the protocol, they could have computed from their own inputs and the output alone. The protocol leaks nothing beyond what the function itself reveals.

### Who Might Cheat, and How?

The adversary model shapes everything. A **semi-honest** (or passive) adversary follows the protocol faithfully but tries to extract information from the messages it observes. Think of a curious employee who logs everything but doesn't forge packets. A **malicious** (or active) adversary can deviate arbitrarily: send wrong values, abort early, collude with others. Think of a compromised machine running modified software.

Most efficient protocols assume semi-honest adversaries. Malicious security is achievable but roughly doubles the cost, requiring authentication on shares and consistency checks at gates. The SPDZ protocol (pronounced "speedz") pioneered practical malicious security, discussed later in this chapter.

### How Many Can Collude?

Protocols specify a threshold $t$: security holds as long as at most $t$ of the $n$ parties are corrupt. The critical boundary is $t = n/2$.

With an **honest majority** ($t < n/2$), protocols can achieve information-theoretic security. No computational assumption, no cryptographic hardness. Even an unbounded adversary learns nothing. The mathematics of secret sharing suffices.

With a **dishonest majority** ($t < n$, potentially $t = n-1$), information-theoretic security becomes impossible. If all but one party collude, they can simulate the entire protocol among themselves. Cryptographic assumptions become necessary: the adversary *could* break the scheme given infinite time, but doing so requires solving hard problems.



## Secret-Sharing MPC

The BGW protocol, named after Ben-Or, Goldwasser, and Wigderson, takes a direct approach: secret-share each input, compute on the shares, and reconstruct only the output. To understand how this works, we need to understand what secret sharing actually does.

### Shamir's Secret Sharing

The idea is elegant (Appendix A covers the full details, including reconstruction formulas and security properties). To share a secret $s$ among $n$ parties with threshold $t$, construct a random polynomial of degree $t-1$ that passes through the point $(0, s)$:

$$P(X) = s + a_1 X + a_2 X^2 + \cdots + a_{t-1} X^{t-1}$$

The coefficients $a_1, \ldots, a_{t-1}$ are chosen uniformly at random. The secret $s$ is the constant term, recoverable as $P(0)$.

Each party $i$ receives the share $s_i = P(i)$, the polynomial evaluated at their index. Any $t$ parties can pool their shares and use Lagrange interpolation to recover the polynomial, hence the secret. But $t-1$ shares reveal nothing: a degree $t-1$ polynomial is determined by $t$ points, so with only $t-1$ points, every possible secret is equally consistent with the observed shares.

**Concrete example.** Share the secret $s = 7$ among 3 parties with threshold $t = 2$. Choose a random linear polynomial passing through $(0, 7)$, say $P(X) = 7 + 3X$. The shares are:

- Party 1: $s_1 = P(1) = 10$
- Party 2: $s_2 = P(2) = 13$
- Party 3: $s_3 = P(3) = 16$

Any two parties can reconstruct. Parties 1 and 3, holding $(1, 10)$ and $(3, 16)$, interpolate: the unique line through these points is $P(X) = 7 + 3X$, so $P(0) = 7$. But party 1 alone, holding only $(1, 10)$, knows nothing. Any line through $(1, 10)$ could have any $y$-intercept. The secret could be anything.

### Setup

Each party $i$ secret-shares their input $x_i$ by constructing a random polynomial $P_i(X)$ with $P_i(0) = x_i$ and sending share $P_i(j)$ to party $j$. After this initial exchange, party $j$ holds one share of every input: $P_1(j), P_2(j), \ldots, P_n(j)$. No single party can reconstruct any input, but the distributed shares encode everything needed to compute.

### Linear Operations

Here's where the magic happens. Shamir sharing is *linear*. If parties hold shares of secrets $a$ and $b$ encoded by polynomials $P_a$ and $P_b$, then adding the shares gives valid shares of $a + b$.

Why? Party $j$ holds $P_a(j)$ and $P_b(j)$. When they compute $P_a(j) + P_b(j)$, this equals $(P_a + P_b)(j)$, the evaluation of the sum polynomial at $j$. The sum polynomial $P_a + P_b$ has constant term $P_a(0) + P_b(0) = a + b$. So the parties now hold valid Shamir shares of $a + b$, without any communication.

The same holds for scalar multiplication. If party $j$ holds share $P_a(j)$ and multiplies it by a public constant $c$, the result $c \cdot P_a(j)$ is the evaluation of the polynomial $c \cdot P_a$ at $j$. This polynomial has constant term $c \cdot a$. Each party scales locally; no messages needed.

**Concrete example continued.** The previous example shared $a = 7$ via $P(X) = 7 + 3X$, giving shares $(10, 13, 16)$. Now suppose another party wants to share their private input $b = 5$. They construct $Q(X) = 5 + 2X$ and distribute:

- Party 1: $q_1 = Q(1) = 7$
- Party 2: $q_2 = Q(2) = 9$
- Party 3: $q_3 = Q(3) = 11$

After this exchange, each party holds two shares: party 1 holds $(s_1 = 10, q_1 = 7)$, party 2 holds $(s_2 = 13, q_2 = 9)$, party 3 holds $(s_3 = 16, q_3 = 11)$. Nobody knows $a = 7$ or $b = 5$ except the original owners.

To compute shares of $a + b$, each party adds their shares locally: party 1 computes $10 + 7 = 17$, party 2 computes $13 + 9 = 22$, party 3 computes $16 + 11 = 27$. These are evaluations of $(P + Q)(X) = 12 + 5X$ at points $1, 2, 3$. Interpolating any two recovers $(P + Q)(0) = 12 = a + b$. The sum was computed without anyone learning the inputs.

Addition and scalar multiplication are free. The cost of MPC concentrates entirely on multiplication.

### Multiplication: The Challenge

Multiplication breaks the easy pattern. The product of two shares is *not* a valid share of the product. Shamir sharing uses polynomials of degree $t-1$. If parties locally multiply their shares $P_a(j) \cdot P_b(j)$, they get evaluations of the product polynomial $P_a \cdot P_b$, which has degree $2(t-1)$. This polynomial does encode $ab$ at zero, but the threshold has effectively doubled: now $2t-1$ parties are needed to reconstruct, not $t$. Repeated multiplications would make the degree explode.

> **The Paint Analogy**
>
> Adding secret shares is like adding cups of the same color paint: if I have 1 cup of Red and you have 1 cup of Red, together we have 2 cups of Red. Easy.
>
> Multiplying is like mixing colors: Red times Blue makes Purple. You can't un-mix paint to recover the original colors. Worse, the "shade" of your result depends on both inputs in a non-linear way.
>
> Beaver Triples are like pre-mixed paint samples from a store. We don't know the exact shades (the store mixed them secretly), but we know that Sample A mixed with Sample B produces Sample C. When we need to multiply our real secret colors, we use these pre-mixed samples as a reference point, adjusting our result without ever revealing the original colors we started with.

Donald Beaver's solution is elegant. Before the computation begins, distribute shares of random *triples* $(u, v, w)$ satisfying $w = u \cdot v$. Nobody knows $u$, $v$, or $w$ individually, but everyone holds valid shares of all three.

To describe the protocol, we use bracket notation: $[a]$ means "the parties collectively hold Shamir shares of $a$," with each party holding one evaluation $P_a(j)$. To multiply $[a]$ by $[b]$ using a triple:

1. Parties compute $[\alpha] = [a] - [u]$ and $[\beta] = [b] - [v]$ locally (subtraction is linear, so each party $j$ subtracts their shares)
2. Parties reconstruct $\alpha$ and $\beta$ publicly by pooling shares (these values are masked by the random $u$ and $v$, so they reveal nothing about $a$ or $b$)
3. Parties compute $[ab] = [w] + \alpha \cdot [v] + \beta \cdot [u] + \alpha\beta$ locally (each party $j$ uses their shares of $w$, $v$, $u$ plus the now-public $\alpha$, $\beta$)

The algebra works because $ab = (u + \alpha)(v + \beta) = w + \alpha v + \beta u + \alpha\beta$. Each triple enables one multiplication and is consumed in the process. A preprocessing phase generates triples before inputs are known.

### Circuit Evaluation

With these building blocks, any arithmetic circuit can be evaluated. Share the inputs. Process gates in topological order: addition gates require no communication, multiplication gates consume one Beaver triple each. After the final gate, reconstruct the output by combining shares.

The communication cost is $O(n^2)$ field elements per multiplication (each party sends one message to each other party). Round complexity equals the circuit's multiplicative depth, since multiplications at the same depth can proceed in parallel.

## Garbled Circuits

Secret-sharing MPC generalizes naturally to $n$ parties, but requires rounds proportional to circuit depth. Each multiplication forces a round of communication. For deep circuits or high-latency networks, this cost compounds. Is there another approach, one that computes the entire circuit in constant rounds regardless of depth?

Yao's garbled circuits achieve exactly this for the **two-party** case. The approach is fundamentally asymmetric: one party (the *garbler*) encrypts the entire circuit and hands it to the other (the *evaluator*), who evaluates it blindly. The evaluator learns the output without learning any intermediate values, not even the structure of the gates they're evaluating.

### The Core Idea: Labels as Passwords

The key insight is to replace bits with passwords. Each wire in the circuit carries not a 0 or 1, but a random cryptographic label. For each wire, the garbler creates two labels: one that "means 0" and one that "means 1." The evaluator receives exactly one label per wire, the one corresponding to the actual value, but cannot tell which meaning it carries.

Why does this help? The evaluator computes the entire circuit without ever learning any intermediate values. They hold passwords that encode the computation, but the passwords themselves reveal nothing. A random 128-bit string looks the same whether it means 0 or 1.

### Garbling a Single Gate

How do gates compute on passwords instead of bits? The garbler precomputes all possible outputs and encrypts them so only the correct one can be recovered.

Consider an AND gate with input wires $L$ (left) and $R$ (right) and output wire $O$. The garbler generates six random labels, each a 128-bit string that doubles as a symmetric encryption key:

- Wire $L$: labels $L_0$ and $L_1$ (meaning "left input is 0" and "left input is 1")
- Wire $R$: labels $R_0$ and $R_1$
- Wire $O$: labels $O_0$ and $O_1$

The garbler creates these labels, so they know which label corresponds to which bit. The subscript in $L_0$ is the garbler's private bookkeeping: "this is the label I'll use when the left input is 0." The evaluator never sees this subscript. They receive a label like `9c2b...` with no indication of whether it means 0 or 1.

The plain truth table for AND is:

| Left | Right | Output |
|------|-------|--------|
| 0    | 0     | 0      |
| 0    | 1     | 0      |
| 1    | 0     | 0      |
| 1    | 1     | 1      |

The garbler transforms this into a *garbled table* by encrypting each output label under the corresponding input labels:

| Encrypted Entry |
|-----------------|
| $\text{Enc}_{L_0, R_0}(O_0)$ |
| $\text{Enc}_{L_0, R_1}(O_0)$ |
| $\text{Enc}_{L_1, R_0}(O_0)$ |
| $\text{Enc}_{L_1, R_1}(O_1)$ |

The encryption $\text{Enc}_{L_a, R_b}(O_c)$ uses both input labels as the key. Only someone who knows *both* $L_a$ and $R_b$ can decrypt the corresponding row.

But there's a problem: if the table rows stay in this order, the evaluator learns which row they decrypted and hence learns the input bits. The solution is simple: **randomly shuffle the rows**. After shuffling, the garbled table might look like:

| Shuffled Encrypted Entry |
|--------------------------|
| $\text{Enc}_{L_1, R_1}(O_1)$ |
| $\text{Enc}_{L_0, R_0}(O_0)$ |
| $\text{Enc}_{L_1, R_0}(O_0)$ |
| $\text{Enc}_{L_0, R_1}(O_0)$ |

Now the evaluator, holding one label for each input wire, tries to decrypt each row. Only one decryption succeeds (the one matching their labels), revealing the output label. They learn nothing about which row succeeded because the encryption includes authentication: wrong keys produce random garbage, not a valid label.

### Hash-Indexed Tables

There's an elegant alternative to random shuffling. Instead of listing ciphertexts in random order and trying all four, use the hash of the input labels as a row index:

| Row Index | Encrypted Entry |
|-----------|-----------------|
| $H(L_0, R_0)$ | $\text{Enc}_{L_0, R_0}(O_0)$ |
| $H(L_0, R_1)$ | $\text{Enc}_{L_0, R_1}(O_0)$ |
| $H(L_1, R_0)$ | $\text{Enc}_{L_1, R_0}(O_0)$ |
| $H(L_1, R_1)$ | $\text{Enc}_{L_1, R_1}(O_1)$ |

The evaluator, holding labels $L_a$ and $R_b$, computes $H(L_a, R_b)$ and looks up that row directly. No trial decryptions needed. The hash reveals nothing about which row was accessed since the evaluator doesn't know the other labels to compute their hashes.

This structure scales better: instead of trying all rows, the evaluator does one hash and one decryption per gate. For circuits with millions of gates, the difference matters.

### How the Evaluator Proceeds

With either approach (shuffled tables with trial decryption, or hash-indexed tables with direct lookup), the evaluator follows the same pattern. They hold one label per input wire, use those labels to decrypt exactly one entry from the garbled table, and obtain the output label. The output label becomes input to the next gate. The evaluator never learns which bit any label represents; they just propagate opaque 128-bit strings through the circuit.

### Chaining Gates Together

A single gate is not a computation. How do labels propagate through a circuit?

The key is consistency: the output labels of one gate become the input labels of subsequent gates. The garbler ensures that the labels generated as outputs of gate $G_1$ are the same labels used as inputs in gate $G_2$. The evaluator, holding one label per wire, can evaluate gate after gate, each time recovering exactly one output label to feed forward.

**Example: A tiny circuit.** Consider computing $(a \land b) \lor c$, which requires an AND gate followed by an OR gate.

```
       a ──┐
            ├── AND ──┬── t
       b ──┘          │
                      ├── OR ── output
       c ─────────────┘
```

The intermediate wire $t$ connects AND's output to OR's input. The garbler:

1. Generates labels for wires $a$, $b$, $c$, $t$, and $output$ (two labels per wire)
2. Creates a garbled table for AND using $a$'s and $b$'s labels as input keys, encrypting $t$'s labels as outputs
3. Creates a garbled table for OR using $t$'s and $c$'s labels as input keys, encrypting $output$'s labels as outputs
4. Sends both garbled tables to the evaluator

The consistency between gates requires no "enforcement" since the garbler controls construction. The labels $t_0$ and $t_1$ are created once, then used in two places: as the encrypted outputs of the AND table, and as the decryption keys indexed in the OR table. When the evaluator decrypts the AND gate and obtains (say) $t_0$, that exact string appears as an index in the OR table. The garbler wired them together at construction time.

The evaluator:

1. Receives labels for $a$, $b$, $c$ (via oblivious transfer for their inputs, directly for the garbler's inputs)
2. Evaluates the AND gate, obtaining a label for $t$
3. Uses the $t$ label plus the $c$ label to evaluate the OR gate
4. Obtains a label for the output wire

At the final output, the garbler reveals the mapping: "If your output label is $X$, the result is 0; if it's $Y$, the result is 1." Only now does the evaluator learn the actual output bit. This isn't a security breach: the whole point is for both parties to learn $f(a, b)$. The protection is that intermediate wire mappings stay hidden, so the evaluator learns only the final answer, not the computation path that produced it.

### A Concrete Walkthrough

The abstract description may still feel mysterious. Let's trace through a complete example with actual values: computing $a \land b$ where the garbler holds $a = 1$ and the evaluator holds $b = 0$.

**Setup.** The garbler generates random labels:

- Wire $a$: $L_0 = \texttt{3a7f...}$, $L_1 = \texttt{9c2b...}$
- Wire $b$: $R_0 = \texttt{5e81...}$, $R_1 = \texttt{d4a3...}$
- Wire $out$: $O_0 = \texttt{72f9...}$, $O_1 = \texttt{1b6e...}$

**Garbling.** The garbled table (before shuffling):

| Input Labels | Output Label | Ciphertext |
|--------------|--------------|------------|
| $L_0, R_0$   | $O_0$        | $\text{Enc}_{\texttt{3a7f...,5e81...}}(\texttt{72f9...})$ |
| $L_0, R_1$   | $O_0$        | $\text{Enc}_{\texttt{3a7f...,d4a3...}}(\texttt{72f9...})$ |
| $L_1, R_0$   | $O_0$        | $\text{Enc}_{\texttt{9c2b...,5e81...}}(\texttt{72f9...})$ |
| $L_1, R_1$   | $O_1$        | $\text{Enc}_{\texttt{9c2b...,d4a3...}}(\texttt{1b6e...})$ |

After random shuffling, the garbler sends the four ciphertexts in jumbled order.

**Evaluation.** The two input labels arrive through different channels:

- *Garbler's input*: The garbler knows their own input is 1, so they simply send $L_1 = \texttt{9c2b...}$ directly. No special protocol needed.
- *Evaluator's input*: The garbler holds both $R_0$ and $R_1$ but must not learn which the evaluator needs. The evaluator knows their bit is 0 but cannot reveal this. Via oblivious transfer, the evaluator receives $R_0 = \texttt{5e81...}$ without the garbler learning which label was transferred, and without the evaluator learning $R_1$.

The evaluator tries decrypting each of the four ciphertexts with key $(\texttt{9c2b..., 5e81...})$. Only one decrypts successfully, yielding $O_0 = \texttt{72f9...}$.

**Output.** The garbler reveals: "Output label $\texttt{72f9...}$ means 0." The evaluator learns the result: $1 \land 0 = 0$.

What did the evaluator learn? Only the output. They never learned that their label $R_0$ "meant 0" or that the garbler's input was 1. The computation proceeded entirely on encrypted values.

### Yao's Protocol (Two Parties)

With the mechanics clear, here's the full protocol:

Party A (the garbler) has input $x$. Party B (the evaluator) has input $y$. They want to compute $f(x, y)$.

In the **garbling phase**, A transforms the circuit into an encrypted version. For each wire $w$, A generates two random labels: $K_w^0$ (representing the bit 0) and $K_w^1$ (representing 1). For each gate, A creates a garbled table: four encryptions encoding the gate's truth table, randomly shuffled. A sends the garbled circuit (all garbled tables) to B.

In the **evaluation phase**, B learns the output without learning intermediate values. A sends the labels for their own input wires (the $K_w^{x_w}$ values corresponding to their actual input $x$). B obtains labels for their input wires via *oblivious transfer* (explained below), a primitive that lets B receive the label for their bit without A learning which bit B chose. Now B holds one label per input wire. For each gate, B uses the two input labels as decryption keys, recovering exactly one output label from the garbled table. Gate by gate, B propagates labels through the circuit until reaching the output wires. The final labels map to the output bits.

### Why It's Secure

B learns only one label per wire: the one corresponding to the actual computation path. The other label remains hidden. Since labels are random, B cannot distinguish $K_w^0$ from $K_w^1$ and learns nothing about intermediate values, only the output.

A learns nothing about B's input because the oblivious transfer hides B's choice. A sees only the garbled circuit and the labels for their own input.

### The Free-XOR Optimization

The basic protocol requires four encryptions per gate: one for each row of the truth table, covering all four input combinations $(0,0), (0,1), (1,0), (1,1)$. Can we do better for certain gate types?

A beautiful optimization makes XOR gates essentially free. The idea is to impose a global structure on all labels so that XOR "just works" algebraically, requiring no garbled table at all.

**The constraint.** The garbler chooses a random global secret $\Delta$ (a 128-bit string kept hidden from the evaluator). For *every* wire $w$ in the circuit, the garbler ensures:
$$K_w^1 = K_w^0 \oplus \Delta$$

That is, the two labels for any wire differ by exactly $\Delta$. The garbler picks $K_w^0$ randomly, then derives $K_w^1$ by XORing with $\Delta$. This constraint propagates through the entire circuit.

**Why this helps.** Consider an XOR gate: the output bit equals $a \oplus b$ where $a$ and $b$ are the input bits. The garbler defines the output labels as:
$$O_0 = L_0 \oplus R_0$$

Since the $\Delta$-constraint must also hold for the output wire, we need $O_1 = O_0 \oplus \Delta$. Let's verify this is consistent:
$$O_1 = O_0 \oplus \Delta = L_0 \oplus R_0 \oplus \Delta$$

**The magic.** The evaluator holds labels $L_a$ and $R_b$ (one for each input wire, corresponding to bits $a$ and $b$ that they don't know). They simply XOR them: $L_a \oplus R_b$. Why does this produce the correct output label $O_{a \oplus b}$?

- If $a = 0, b = 0$: evaluator computes $L_0 \oplus R_0 = O_0$ $\checkmark$ (and $0 \oplus 0 = 0$)
- If $a = 0, b = 1$: evaluator computes $L_0 \oplus R_1 = L_0 \oplus (R_0 \oplus \Delta) = O_0 \oplus \Delta = O_1$ $\checkmark$ (and $0 \oplus 1 = 1$)
- If $a = 1, b = 0$: evaluator computes $L_1 \oplus R_0 = (L_0 \oplus \Delta) \oplus R_0 = O_0 \oplus \Delta = O_1$ $\checkmark$ (and $1 \oplus 0 = 1$)
- If $a = 1, b = 1$: evaluator computes $L_1 \oplus R_1 = (L_0 \oplus \Delta) \oplus (R_0 \oplus \Delta) = L_0 \oplus R_0 = O_0$ $\checkmark$ (and $1 \oplus 1 = 0$)

In each case, the XOR of the input labels produces exactly the output label for bit $a \oplus b$. No encryption, no garbled table, no communication for that gate. The evaluator performs a single XOR operation and obtains the correct output label.

**Why is it secure?** The evaluator can't exploit the $\Delta$ structure because they never learn $\Delta$ itself. They see only one label per wire, a random-looking 128-bit string. Without knowing $\Delta$, they can't compute the other label or detect the relationship between wires.

This matters enormously in practice. XOR is the most common operation in many computations. Free-XOR reduces circuit size by 30-50% in typical applications.

### Complexity

Communication is $O(|C|)$, proportional to the circuit size, since each non-XOR gate requires a constant-size garbled table. (XOR gates are free.) Computation uses only symmetric-key operations (AES), making garbled circuits fast in practice. The protocol runs in constant rounds: one round to send the garbled circuit, one for oblivious transfers. This makes garbled circuits attractive when network latency dominates, since secret-sharing MPC requires rounds proportional to circuit depth.

## Oblivious Transfer

Garbled circuits solve almost all of the two-party computation problem, but leave one gap: how does the evaluator receive labels for their own input bits? The garbler knows both labels for each input wire ($K_w^0$ and $K_w^1$), but must give the evaluator exactly one, the one corresponding to their actual bit. The garbler cannot learn which bit the evaluator chose, and the evaluator cannot learn the other label.

This is *oblivious transfer* (OT): a sender holds two messages $m_0$ and $m_1$, a receiver holds a choice bit $b$, and after the protocol the receiver learns $m_b$ and nothing else while the sender learns nothing about $b$.

The requirement sounds contradictory. How can the sender give one message without knowing which? How can the receiver receive one without learning the other? Several elegant constructions make this possible.

### Construction from Commutative Encryption

Imagine an encryption scheme where the order of encryption and decryption doesn't matter:
$$\text{Dec}_b(\text{Dec}_a(\text{Enc}_b(\text{Enc}_a(x)))) = x$$

A physical metaphor: a box locked with two padlocks. Alice locks it with her padlock and sends it to Bob. Bob adds his padlock and sends it back. Alice removes her lock (Bob's lock doesn't block her). She sends it back. Bob removes his lock and opens the box. The message traveled securely without either party ever having full access.

Mathematically, exponentiation in a finite group provides commutative encryption: encrypt message $g$ with key $a$ by computing $g^a$. Decrypt by taking an $a$-th root. The order of operations doesn't matter since $(g^a)^b = (g^b)^a = g^{ab}$.

**The OT protocol.** Alice has $n$ messages $x_1, \ldots, x_n$. Bob wants $x_i$ without Alice learning $i$.

1. Alice encrypts all messages with her key $a$ and sends: $\text{Enc}_a(x_1), \ldots, \text{Enc}_a(x_n)$ in order
2. Bob picks out $\text{Enc}_a(x_i)$, encrypts it with his key $b$, and sends back $\text{Enc}_b(\text{Enc}_a(x_i))$
3. Alice decrypts with her key, obtaining $\text{Enc}_b(x_i)$, and sends it to Bob
4. Bob decrypts with his key to recover $x_i$

Why is Bob protected? Alice sees only a doubly-encrypted blob. She doesn't know Bob's key $b$, so she can't decrypt it to see which message he chose.

Why is Alice protected? Bob receives only one singly-encrypted message ($\text{Enc}_b(x_i)$ in step 3). The other $n-1$ messages remain encrypted under Alice's key, which Bob doesn't have.

### Construction from Diffie-Hellman

The commutative encryption approach requires three message rounds. Can we do better?

A more efficient construction reduces this using Diffie-Hellman key exchange. Work in a group $\mathbb{G}$ of prime order $q$ with generator $g$. The sender chooses random $a$ and sends $A = g^a$. The receiver, depending on their choice bit $b$, responds strategically: if $b = 0$, choose random $k$ and send $B = g^k$; if $b = 1$, send $B = A \cdot g^k = g^{a+k}$ for random $k$.

The sender computes two keys: $K_0 = B^a$ and $K_1 = (B \cdot A^{-1})^a$. Then the sender encrypts both messages, $c_0 = \text{Enc}_{K_0}(m_0)$ and $c_1 = \text{Enc}_{K_1}(m_1)$, and sends both ciphertexts.

The receiver can compute only one key. If $b = 0$, the receiver knows $k$ and can compute $K_0 = A^k = g^{ak}$, which equals $B^a$ since $B = g^k$. But $K_1 = (B/A)^a = g^{(k-a)a}$ requires knowing the discrete log of $B/A$, which the receiver doesn't have. The receiver decrypts $c_0$ and learns $m_0$. If $b = 1$, the situation reverses: the receiver can compute $K_1$ but not $K_0$.

The sender sees only $B$, a random group element that reveals nothing about whether the receiver chose $b = 0$ or $b = 1$.

### OT Extension

Both constructions require public-key operations: exponentiations in a group. For a single OT this is fast enough, but garbled circuits need one OT per input bit. A circuit with a million input bits would require a million exponentiations.

OT extension, pioneered by the IKNP protocol, breaks this barrier. A small number of base OTs ($\kappa$, the security parameter, typically 128) enable an unlimited number of extended OTs using only symmetric-key operations. The amortized cost drops to a few AES calls per OT. This makes garbled circuits practical even for inputs with millions of bits.

## Mixing Protocols

We now have two complete approaches to MPC: secret-sharing (optimal for arithmetic operations, but requires rounds proportional to depth) and garbled circuits (constant rounds, but expensive per gate). Neither dominates the other. Which should we use?

The answer, increasingly, is both. Real computations don't fit neatly into one paradigm. A machine learning inference might need field arithmetic for the linear layers (where secret-sharing MPC excels) but comparisons for activation functions (where Boolean circuits are better). The most efficient approach often switches representations mid-computation.

Modern MPC frameworks like ABY and MP-SPDZ support three representations: **A**rithmetic sharing for field operations, **B**oolean sharing for bitwise operations and comparisons, and **Y**ao's garbled circuits for complex Boolean functions that would require deep circuits in other representations.

Conversion protocols translate between representations. Arithmetic-to-Boolean (A2B) converts additive shares of a field element into XOR-shares of its bit representation. Boolean-to-Arithmetic (B2A) reverses the process, using oblivious transfer to handle the carry bits that arise when interpreting binary as an integer. Yao conversions (A2Y, Y2A, B2Y, Y2B) interface with garbled circuits.

The design problem becomes: given a computation, which operations should use which representation? The answer depends on the operation mix and the network characteristics. Deep multiplicative chains favor secret sharing (low communication per multiplication). Complex comparisons favor garbled circuits (constant rounds). The optimal decomposition is often hand-tuned for critical applications.

## MPC-in-the-Head: Where the Paths Converge

This chapter opened by observing that MPC and ZK developed in parallel, addressing different trust problems. But the connection runs deeper than shared history. MPC protocols can be *compiled* into zero-knowledge proofs through a transformation called "MPC-in-the-head."

The idea exploits a strange symmetry. In MPC, multiple real parties compute on secret-shared inputs, and the security guarantee is that no coalition learns more than the output. In MPC-in-the-head, a single prover *simulates* an MPC protocol entirely inside their own mind, playing all the parties simultaneously. The security guarantee transforms: instead of protecting inputs from other parties, it protects the witness from the verifier.

The construction works as follows. The prover secret-shares the witness among $n$ *imaginary* parties. Then the prover simulates the MPC protocol that would compute $R(x, w)$, playing all $n$ roles simultaneously. Each simulated party has a "view": the messages it sent and received, its random tape, its share of the witness. The prover commits to all $n$ views.

Think of the prover as a one-person theater troupe performing a conversation between three characters (Alice, Bob, Charlie). The prover writes out the full script: what Alice said to Bob, what Bob said to Charlie, what Charlie said to Alice. Then they seal each character's script in a separate envelope.

The verifier challenges: "Open the views of parties $i$ and $j$." (Show me Alice and Bob's envelopes.) The prover reveals those two views. The verifier checks consistency: do the messages that party $i$ claims to have sent match what party $j$ claims to have received? Did both parties follow the protocol correctly given their views? Does the MPC output equal 1? If Alice's script says she sent "7" to Bob, but Bob's script says he received "9" from Alice, the prover is caught lying. By randomly checking different pairs, the verifier catches any inconsistency in the performance.

Why is this sound? If the witness is invalid, the MPC would output 0. For the prover to fake acceptance, they must forge views where the MPC appears to output 1. But faking a valid MPC execution requires consistency across all parties. If any pair of views is inconsistent (messages don't match, or a party deviated from the protocol), the verifier catches it. A cheating prover can make some pairs consistent, but not all. The random challenge catches an inconsistent pair with constant probability. Repeat to amplify.

Why is this zero-knowledge? Opening $t-1$ views of a $t$-threshold MPC reveals nothing about the secret (by the MPC privacy guarantee). The verifier sees only a subset of views, not enough to reconstruct the witness.

### Instantiations

**ZKBoo and ZKB++** use 3-party secret sharing. The verifier opens 2 of 3 parties, giving a soundness error of $1/3$ per repetition. These schemes excel at proving knowledge of hash preimages, where the circuit structure is fixed and well-optimized.

**Ligero** combines MPC-in-the-head with Reed-Solomon codes, achieving proof size $O(\sqrt{n})$ for circuits with $n$ gates. This is sublinear, better than naive approaches though not as succinct as polynomial-based SNARKs.

**Limbo** and subsequent work push practical performance further, targeting real-world deployment for specific statement classes.



## Threshold Cryptography

MPC computes arbitrary functions on distributed inputs. But some functions appear so frequently that they deserve specialized treatment. Chief among these: cryptographic operations. What if the *key itself* is secret-shared?

Threshold cryptography applies MPC machinery to distribute cryptographic keys. Instead of a single party holding a signing or decryption key, $n$ parties each hold a share. Any $t$ of them can cooperate to sign or decrypt, but no coalition of fewer than $t$ learns anything about the key. The secret never exists in one place.

### Threshold Signatures

Consider the problem of institutional key custody. A cryptocurrency exchange holds billions in assets. A single signing key is a single point of failure: theft, coercion, insider attack. The traditional solution is multisig, where the blockchain verifies $t$-of-$n$ separate signatures. But multisig reveals the signing structure on-chain and requires protocol-level support.

Threshold signatures solve this differently. The $n$ parties hold shares of a single signing key $sk$. When $t$ cooperate, they produce a single signature that looks identical to a signature from a solo signer. The blockchain sees nothing unusual. The distribution is invisible.

**FROST** implements threshold Schnorr signatures with particular elegance. The protocol has two phases. In the first, parties jointly generate shares of a random nonce $k$ using Feldman's verifiable secret sharing (Appendix A). Each party contributes randomness, and the distributed nonce emerges without anyone learning its value. In the second phase, each party computes a partial signature using their share of $k$ and their share of $sk$. These partial signatures combine via Lagrange interpolation, the same reconstruction formula from Shamir's scheme. The result is a valid Schnorr signature.

The linearity of Schnorr makes this work. A Schnorr signature has the form $s = k + e \cdot x$ where $e$ is the challenge hash. If parties hold shares $k_i$ and $x_i$, they compute partial signatures $s_i = k_i + e \cdot x_i$. Lagrange interpolation reconstructs $s = k + e \cdot x$ exactly. FROST inherits Feldman's verifiability: parties can detect if someone contributes malformed shares during the nonce generation, catching cheaters before they can disrupt signing.

One important caveat: FROST's nonce generation phase requires **synchronous coordination**. All participating signers must be online simultaneously to jointly generate the nonce shares and exchange their commitments. If a signer goes offline during this phase, the protocol stalls. This synchronicity constraint can be problematic in real-world deployments where signers span different time zones or operate on unreliable networks.

**ROAST** addresses this limitation by wrapping FROST in a robust, asynchronous coordinator. Instead of requiring all $t$ signers to be online at once, ROAST has a coordinator that adaptively selects responsive signers. The coordinator maintains multiple concurrent signing sessions and gracefully handles signers who fail to respond. If a signer times out, the coordinator simply starts a new session with a different signer subset. The first session to complete produces the signature. ROAST doesn't modify FROST's cryptography; it adds a session management layer that tolerates network asynchrony and unresponsive parties, making threshold signing practical for geographically distributed deployments.

Threshold ECDSA is more complex. ECDSA signatures involve a modular inversion step, $s = k^{-1}(z + r \cdot x)$, and inversion is not linear. Computing it on shared values requires a full MPC protocol for the inversion, adding rounds and computational overhead. Protocols like GG18 and GG20 solve this but at higher cost than FROST.

### Threshold Decryption

The same distribution principle applies to decryption. Parties hold shares of a decryption key. When a ciphertext arrives, each party contributes a partial decryption using their share. The threshold combines these contributions to recover the plaintext, but no party ever holds the full key.

This structure appears in voting systems, where an encrypted ballot should only be decrypted after polls close and only if enough trustees cooperate. It appears in key escrow, where law enforcement access requires multiple parties to agree. And it appears in distributed custody systems, where no single server compromise can steal user funds.

## Practical Considerations

The theoretical protocols are complete: given enough time and bandwidth, any function can be computed securely. But theory and practice diverge. What determines whether an MPC deployment actually works?

### Communication Patterns

The network topology shapes everything. MPC protocols differ in how parties communicate, and the choice significantly affects performance. In a star topology, all parties route messages through a central dealer or combiner. This simplifies coordination but creates a bottleneck and a single point of failure. In full connectivity, every party communicates directly with every other party. This eliminates the central bottleneck but requires $O(n^2)$ connections. Broadcast protocols have each message go to all parties simultaneously, useful when the computation requires everyone to see the same values (like reconstructing a shared secret).

The bottleneck inversion between ZK and MPC deserves emphasis. In ZK, the bottleneck is usually **compute**: the prover performs heavy cryptographic work (MSMs, FFTs, hashes) and sends relatively small proofs. In MPC, the bottleneck is almost always **bandwidth**: many parties do lightweight operations but exchange massive amounts of data. A ZK prover might spend 10 seconds computing and 10 milliseconds sending. An MPC protocol might spend 10 milliseconds computing and 10 seconds sending. This inversion dictates architecture: you can run a ZK prover on a single powerful machine, but you can't run high-speed MPC over a 4G connection.

Network latency often dominates the cost of MPC. A protocol that requires 100 rounds of communication will be slow even if each round sends only a few bytes. This is why garbled circuits, with their constant round complexity, often outperform secret-sharing MPC for interactive applications despite sending more data. The design choice depends on whether bandwidth or latency is the limiting factor.

### Preprocessing vs. Online

A key optimization divides MPC into two phases. The preprocessing phase generates correlated randomness before the actual inputs are known. Beaver triples for multiplication, OT correlations for garbled circuits, and random sharings for masking all fall into this category. The online phase consumes this preprocessed material to compute on the real inputs.

This separation has practical benefits. Preprocessing can happen during idle time, spreading the computational cost across hours or days. When the actual computation is needed, the online phase runs quickly using the stockpiled randomness. For applications like sealed-bid auctions, where parties submit bids that must be processed immediately, the preprocessing model allows sub-second latency despite the underlying cryptographic complexity.

Where does the preprocessing come from? One option is a trusted dealer who generates and distributes the correlated randomness. This is simple but reintroduces trust. Another option is to generate the preprocessing via MPC itself, a slower process that pays the full cost but requires no trusted party. A third option uses hardware: trusted execution environments can generate the randomness with attestation that the correct distribution was used.

### Malicious Security

Everything so far assumes semi-honest adversaries: parties who follow the protocol faithfully but try to extract information from what they observe. What if an adversary can deviate arbitrarily, sending malformed messages or aborting at strategic moments?

Adding security against malicious adversaries roughly doubles the computational cost.

For secret-sharing MPC, malicious security requires authenticating every share. The SPDZ protocol attaches a Message Authentication Code (MAC) to each shared value. When shares are combined or reconstructed, the MACs are verified. A cheating party who modifies a share will fail the MAC check with overwhelming probability.

Consistency checks at each gate catch parties who compute incorrectly. The SPDZ preprocessing includes authenticated triples, and the online phase verifies that multiplications respect the triple structure.

For garbled circuits, malicious security faces a different challenge. The semi-honest protocol assumes the garbler constructs the circuit correctly. A malicious garbler could create a circuit that computes the wrong function, leaking information about the evaluator's input. How can the evaluator verify the circuit without being able to inspect it?

**Cut-and-choose** solves this with redundancy. The garbler creates $s$ independent garbled circuits for the same function (typically $s = 40$ or more). The evaluator randomly partitions these circuits: select a fraction (say, half) to *check* and the rest to *evaluate*.

For checked circuits, the garbler reveals everything: all labels, all randomness used during garbling. The evaluator reconstructs the circuit from scratch and verifies it matches what was sent. If any checked circuit is malformed, the evaluator aborts and the garbler is caught cheating.

For evaluated circuits, the protocol proceeds normally. The evaluator computes on all of them and takes the majority output. Even if the garbler cheated on some evaluated circuits, majority voting ensures correctness as long as most circuits are honest.

The security argument: the garbler doesn't know which circuits will be checked. If they cheat on $k$ circuits, the probability that *all* cheated circuits end up in the evaluated set (avoiding detection) is roughly $(1/2)^k$. Cheating is exponentially unlikely to succeed.

**Point-and-permute** is a simpler optimization that improves efficiency without full cut-and-choose. The garbler appends a random "pointer bit" to each label. The four rows of a garbled table are sorted by these pointer bits rather than randomly shuffled. The evaluator, holding input labels with their pointer bits, immediately knows which row to decrypt without trying all four. This reduces decryption work from 4 attempts to 1.

These overheads explain why many practical deployments assume semi-honest adversaries when the trust model permits it. Malicious security is achievable, but it comes at a cost.

## Key Takeaways

1. **MPC eliminates trusted third parties**: Any function computable by a circuit can be computed jointly by mutually distrustful parties, revealing only the output. The theoretical result is complete; practical efficiency is the ongoing challenge.

2. **Two paradigms, different tradeoffs**: Secret-sharing MPC (BGW) handles $n$ parties and makes linear operations free, but requires communication rounds proportional to circuit depth. Garbled circuits achieve constant rounds for two parties, but require communication proportional to circuit size.

3. **Multiplication is the bottleneck**: In secret-sharing MPC, addition and scalar multiplication need no communication. Multiplication consumes preprocessed Beaver triples and forces a round of interaction. Circuit design should minimize multiplicative depth.

4. **Oblivious transfer is fundamental**: OT lets a sender transmit one of two messages without learning which was received, and lets the receiver learn one without accessing the other. This seemingly impossible primitive underlies garbled circuits and much else. OT extension makes it practical at scale.

5. **Free-XOR transforms garbled circuit efficiency**: By constraining labels so that $K_w^1 = K_w^0 \oplus \Delta$ for a global secret $\Delta$, XOR gates require no garbled table at all. This reduces circuit size by 30-50% in typical applications.

6. **MPC-in-the-head bridges MPC and ZK**: Simulate an MPC protocol in your head, commit to all party views, let the verifier audit a random pair. MPC privacy becomes ZK; MPC correctness becomes soundness. This compiler yields practical ZK proofs (ZKBoo, Ligero) without polynomial machinery.

7. **Threshold cryptography distributes trust**: Secret-share a signing or decryption key among $n$ parties. Any $t$ can operate; fewer than $t$ learn nothing. The key never exists in one place. FROST makes threshold Schnorr practical; ROAST adds asynchrony.

8. **Preprocessing separates costs**: Generate Beaver triples and OT correlations during idle time. The online phase consumes this stockpile, achieving low latency when inputs arrive. The split enables sub-second MPC for time-sensitive applications.

9. **Malicious security is achievable but costly**: SPDZ authenticates shares with MACs; cut-and-choose forces honest garbling. Both roughly double the work. Choose based on your trust model.

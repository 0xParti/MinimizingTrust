# Chapter 25: MPC and ZK parallel paths

In 1982, Andrew Yao posed a puzzle that sounded like a parlor game. Two millionaires meet at a party. Each wants to know who is richer, but neither wants to reveal their actual wealth. Is there a protocol that determines who has more money without either party learning anything else?

The question seems impossible. To compare two numbers, someone must see both numbers. A trusted third party could collect the figures, announce the winner, burn the evidence. But what if there is no trusted party? What if the millionaires trust no one, not even each other?

The same tension appears wherever private data meets joint computation. Satellite operators want to check if their orbits will collide, but their trajectories are classified. Banks want to detect money laundering across institutions without opening their books to each other. Nuclear inspectors want to verify warhead counts without learning weapon designs. The underlying problem is always the same: the computation requires inputs that no single party should see.

Yao proved the comparison can be done. Not by clever social arrangements or legal contracts, but by cryptography alone. The protocol he constructed, now called *garbled circuits*, allows two parties to jointly compute any function on their private inputs while revealing nothing but the output. Neither party sees the other's input. The trusted third party dissolves into mathematics.

This was the birth of **Secure Multiparty Computation** (MPC). The field expanded rapidly. In 1988, Ben-Or, Goldwasser, and Wigderson showed that with an honest majority of participants, MPC could achieve *information-theoretic* security with no computational assumption required, just the mathematics of secret sharing. The same year, Chaum, Crépeau, and Damgård proved that with dishonest majorities, MPC remained possible under cryptographic assumptions. By the early 1990s, the core theoretical question was settled. Any function computable by a circuit could be computed securely by mutually distrustful parties.

Computation, it turns out, does not require a single trusted processor. It can be *distributed* across adversaries who share nothing but a communication channel and a willingness to follow a protocol. The output emerges from the collaboration, but the inputs remain private.

### Why MPC belongs in this book

Throughout this book, we've focused on trust between prover and verifier. The verifier need not believe the prover is honest; the proof itself carries the evidence. But there's another trust relationship we've quietly assumed: the prover has access to the witness. What if the witness is too sensitive to give to any single party?

Consider a company that wants to prove its financial reserves exceed its liabilities without revealing the actual figures to the auditor, the proving service, or anyone else. The company holds the witness (the books), but generating a ZK proof requires computation. If the company lacks the infrastructure to prove locally, it faces a dilemma. Outsource the proving and expose the witness, or don't prove at all.

MPC offers an escape. The company secret-shares its witness among multiple proving servers. Each server sees only meaningless fragments. Together, they compute the proof without any single server learning the books. The witness never exists in one place. Trust is distributed rather than concentrated.

This is one of several approaches to the "who runs the prover?" problem:

**Prove locally.** Keep the witness on your own hardware. No trust required, but you need sufficient compute. For lightweight proofs this works; for zkVM-scale computation it may not.

**Distribute via MPC.** The approach just described. Requires the servers not to collude (honest majority or computational assumptions). This chapter develops the techniques.

**Hardware enclaves (TEEs).** Run the prover inside a Trusted Execution Environment like Intel SGX or ARM TrustZone. The enclave attests that it ran the correct code on hidden inputs. Trust shifts from the server operator to the hardware manufacturer, not trustless but a different trust assumption.

(Chapter 27 discusses a fourth approach, computing on encrypted data via FHE, as part of the broader programmable cryptography landscape.)

MPC and ZK also connect at a deeper level. MPC techniques directly yield ZK constructions through the "MPC-in-the-head" paradigm, where the prover simulates an MPC protocol inside their own mind, commits to the simulated parties' views, then lets the verifier audit a subset. The parallel paths converge into a single construction.



## The MPC problem

The intuition from Yao's millionaires is clear enough, but building protocols requires a precise target. What exactly does it mean to compute "securely"?

The formal setting has $n$ parties holding private inputs $x_1, \ldots, x_n$. They want to learn $f(x_1, \ldots, x_n)$ for some agreed-upon function $f$, but nothing else. A trusted third party could collect everything, compute, then announce the result. MPC must achieve the same outcome without the trusted party. The question is what "nothing else" means, and against whom.

The answer uses the same simulation paradigm that defines zero-knowledge (Chapter 17). There, a proof is zero-knowledge if a simulator can produce a transcript indistinguishable from a real one without access to the witness. Here, an MPC protocol is secure if a simulator, given only the corrupt parties' inputs and the output, can produce a view indistinguishable from what those parties actually observed during the protocol. If such a simulator exists, the protocol leaks nothing beyond what the function itself reveals. The corrupt parties could have generated everything they saw on their own.

Two parameters shape what kind of security is achievable: the adversary's behavior and the number of corrupt parties.

### Adversary models

A **semi-honest** (or passive) adversary follows the protocol faithfully but tries to extract information from the transcript. Think of a curious employee who logs every packet but never forges one. A **malicious** (or active) adversary can deviate arbitrarily by sending wrong values, aborting early, or colluding with others. Think of a compromised machine running modified software.

Most efficient protocols assume semi-honest adversaries. Malicious security is achievable at higher cost, as we'll see later in this chapter.

### Collusion thresholds

How many parties can be corrupt before security breaks? Protocols specify a threshold $t$ so that security holds as long as at most $t$ of the $n$ parties are corrupt. The dividing line is $t = n/2$.

With an **honest majority** ($t < n/2$), protocols can achieve information-theoretic security. No computational assumption, no cryptographic hardness. Even an unbounded adversary learns nothing. The mathematics of secret sharing suffices.

With a **dishonest majority** ($t < n$, potentially $t = n-1$), information-theoretic security becomes impossible. If all but one party collude, they hold enough information to reconstruct any secret shared among the group. Cryptographic assumptions become necessary because the adversary *could* break the scheme given infinite time, but doing so requires solving hard problems.

With the adversary model and threshold specified, the problem is precise. The question that remains is how to actually build such a protocol.



## Secret-sharing MPC

The most natural approach is to keep data distributed throughout the entire computation. The BGW protocol, named after Ben-Or, Goldwasser, and Wigderson, does exactly this. Secret-share each input, compute on the shares, reconstruct only the output. To understand how this works, we need to understand what secret sharing actually does.

### Shamir's secret sharing

Shamir's scheme (Appendix A covers the full details, including reconstruction formulas and security properties) distributes a secret $s$ among $n$ parties with threshold $t$ by constructing a random univariate polynomial of degree $t-1$ that passes through the point $(0, s)$:

$$P(X) = s + a_1 X + a_2 X^2 + \cdots + a_{t-1} X^{t-1}$$

The coefficients $a_1, \ldots, a_{t-1}$ are chosen uniformly at random. The secret $s$ is the constant term, recoverable as $P(0)$.

Each party $i$ receives the share $s_i = P(i)$, the polynomial evaluated at their index. Any $t$ parties can pool their shares and use Lagrange interpolation to recover the polynomial, hence the secret. But $t-1$ shares reveal nothing. A degree $t-1$ polynomial is determined by $t$ points, so with only $t-1$ points, every possible secret is equally consistent with the observed shares.

**Concrete example.** Share the secret $s = 7$ among 3 parties with threshold $t = 2$. Choose a random linear polynomial passing through $(0, 7)$, say $P(X) = 7 + 3X$. The shares are:

- Party 1: $s_1 = P(1) = 10$
- Party 2: $s_2 = P(2) = 13$
- Party 3: $s_3 = P(3) = 16$

Any two parties can reconstruct. Parties 1 and 3, holding $(1, 10)$ and $(3, 16)$, interpolate to find the unique line through these points: $P(X) = 7 + 3X$, so $P(0) = 7$. But party 1 alone, holding only $(1, 10)$, knows nothing. Any line through $(1, 10)$ could have any $y$-intercept. The secret could be anything.

### Setup

Each party $i$ secret-shares their input $x_i$ by constructing a random polynomial $P_i(X)$ with $P_i(0) = x_i$ then sending share $P_i(j)$ to party $j$. After this initial exchange, party $j$ holds one share of every input: $P_1(j), P_2(j), \ldots, P_n(j)$. No single party can reconstruct any input, but the distributed shares encode everything needed to compute.

### Linear operations

Shamir sharing is *linear*, which makes addition and scalar multiplication free. If parties hold shares of secrets $a$ and $b$ encoded by polynomials $P_a$ and $P_b$, then adding the shares gives valid shares of $a + b$.

Party $j$ holds $P_a(j)$ and $P_b(j)$. When they compute $P_a(j) + P_b(j)$, this equals $(P_a + P_b)(j)$, the evaluation of the sum polynomial at $j$. The sum polynomial $P_a + P_b$ has constant term $P_a(0) + P_b(0) = a + b$. So the parties now hold valid Shamir shares of $a + b$, without any communication.

The same holds for scalar multiplication. If party $j$ holds share $P_a(j)$ and multiplies it by a public constant $c$, the result $c \cdot P_a(j)$ is the evaluation of the polynomial $c \cdot P_a$ at $j$. This polynomial has constant term $c \cdot a$. Each party scales locally; no messages needed.

What this means in practice is that two parties can add their secrets without ever revealing them. Return to the earlier example: we shared $a = 7$ via $P(X) = 7 + 3X$, giving shares $(10, 13, 16)$. Now a second party shares their private input $b = 5$ by constructing $Q(X) = 5 + 2X$ and distributing:

- Party 1: $q_1 = Q(1) = 7$
- Party 2: $q_2 = Q(2) = 9$
- Party 3: $q_3 = Q(3) = 11$

After this exchange, each party holds two shares: party 1 holds $(s_1 = 10, q_1 = 7)$, party 2 holds $(s_2 = 13, q_2 = 9)$, party 3 holds $(s_3 = 16, q_3 = 11)$. Nobody knows $a = 7$ or $b = 5$ except the original owners.

To compute shares of $a + b$, each party adds their shares locally: party 1 computes $10 + 7 = 17$, party 2 computes $13 + 9 = 22$, party 3 computes $16 + 11 = 27$. These are evaluations of $(P + Q)(X) = 12 + 5X$ at points $1, 2, 3$. Interpolating any two recovers $(P + Q)(0) = 12 = a + b$. The sum was computed without anyone learning the inputs.

Addition and scalar multiplication are free. The cost of MPC concentrates entirely on multiplication.

### Multiplication

Multiplication breaks the easy pattern. The product of two shares is *not* a valid share of the product. Shamir sharing uses polynomials of degree $t-1$. If parties locally multiply their shares $P_a(j) \cdot P_b(j)$, they get evaluations of the product polynomial $P_a \cdot P_b$, which has degree $2(t-1)$. This polynomial does encode $ab$ at zero, but the threshold has effectively doubled so that $2t-1$ parties are now needed to reconstruct, not $t$. Repeated multiplications would make the degree explode.

Donald Beaver's solution resolves this through preprocessed randomness. Before the computation begins, distribute shares of random *triples* $(u, v, w)$ satisfying $w = u \cdot v$. Nobody knows $u$, $v$, or $w$ individually, but everyone holds valid shares of all three.

To describe the protocol, we use bracket notation: $[a]$ means "the parties collectively hold Shamir shares of $a$," with each party holding one evaluation $P_a(j)$. To multiply $[a]$ by $[b]$ using a triple:

1. Parties compute $[\alpha] = [a] - [u]$ and $[\beta] = [b] - [v]$ locally (subtraction is linear, so each party $j$ subtracts their shares)
2. Parties reconstruct $\alpha$ and $\beta$ publicly by pooling shares (these values are masked by the random $u$ and $v$, so they reveal nothing about $a$ or $b$)
3. Parties compute $[ab] = [w] + \alpha \cdot [v] + \beta \cdot [u] + \alpha\beta$ locally (each party $j$ uses their shares of $w$, $v$, $u$ plus the now-public $\alpha$, $\beta$)

The algebra works because $ab = (u + \alpha)(v + \beta) = w + \alpha v + \beta u + \alpha\beta$. Since $\alpha$, $\beta$, and $\alpha\beta$ are now public scalars, party $j$ can compute their share of $ab$ locally as $w_j + \alpha \cdot v_j + \beta \cdot u_j + \alpha\beta$. This is a linear combination of valid Shamir shares, so the result is itself a valid Shamir share of $ab$. No single party learns $ab$, but together the parties hold shares of a polynomial whose constant term is $ab$, ready to feed into subsequent gates.

Intermediate values are never reconstructed. Each triple enables exactly one multiplication because $\alpha$ and $\beta$ are now public; reusing the same triple with different inputs would leak information. A fresh triple is needed for every multiplication gate, generated during a preprocessing phase before inputs are known.

### Circuit evaluation

With these building blocks, any arithmetic circuit can be evaluated. Share the inputs, process gates in topological order so that addition gates require no communication while multiplication gates consume one Beaver triple each, then reconstruct only the final output.

The reconstruction step works like the earlier Shamir example, but now all parties contribute shares of the *same* value. Suppose the circuit's output wire carries the shared value $[y]$, with party $j$ holding share $R(j)$ for some degree $t-1$ polynomial $R$ with $R(0) = y$. Each party broadcasts their share. Given any $t$ shares, Lagrange interpolation recovers $R(0) = y$. Before this moment, no party knew $y$; after it, everyone does. This is the only point in the entire protocol where a shared value becomes public.

The communication cost is $O(n^2)$ field elements per multiplication (each party sends one message to each other party). Round complexity equals the circuit's multiplicative depth, since multiplications at the same depth can proceed in parallel.

## Garbled circuits

Secret-sharing MPC generalizes naturally to $n$ parties, but requires rounds proportional to circuit depth. Each multiplication forces a round of communication. For deep circuits or high-latency networks, this cost compounds quickly. Yao's garbled circuits take a completely different approach, designed specifically for the **two-party** case. There are no thresholds, no secret sharing, no multiple rounds of interaction. Instead, one round of communication suffices regardless of circuit depth.

The setting is two parties, say Alice and Bob, each holding a private input. Neither trusts the other. They agree on a function $f$ and want to learn $f(x_A, x_B)$ without revealing their inputs to each other. The protocol assigns asymmetric roles: Alice becomes the *garbler*, who encrypts the entire circuit before sending it, and Bob becomes the *evaluator*, who runs the encrypted circuit blindly.

The evaluator needs one label per input wire, but the two parties' inputs arrive through different channels. For the garbler's own input wires, the garbler knows their bits, so they simply send the corresponding labels directly. For the evaluator's input wires, the garbler holds both labels but must not learn which bit the evaluator has. A primitive called *oblivious transfer* (developed later in this chapter) lets the evaluator receive the label matching their bit without the garbler learning which one was chosen. The evaluator learns nothing beyond the final output; the garbler learns nothing about the evaluator's input.

### Labels as passwords

If the evaluator must compute on the garbler's circuit without learning what the wires carry, something must replace the raw bits. The idea is to use passwords. Each wire in the circuit carries not a 0 or 1, but a random cryptographic label. For each wire, the garbler creates two labels: one that "means 0" and one that "means 1." The evaluator receives exactly one label per wire, the one corresponding to the actual value, but cannot tell which meaning it carries.

This separation between *holding* a value and *knowing* a value is what makes garbled circuits work. The evaluator holds passwords that encode the computation, but a random 128-bit string looks the same whether it means 0 or 1.

### Garbling a single gate

Each gate computes on passwords instead of bits by having the garbler precompute all possible outputs and encrypt them so only the correct one can be recovered.

Consider an AND gate with input wires $L$ (left) and $R$ (right) and output wire $O$. Suppose Alice (the garbler) holds the left input and Bob (the evaluator) holds the right input. Alice generates all six labels herself, two per wire, each a 128-bit string that doubles as a symmetric encryption key:

- Wire $L$: labels $L_0$ and $L_1$ (meaning "left input is 0" and "left input is 1")
- Wire $R$: labels $R_0$ and $R_1$
- Wire $O$: labels $O_0$ and $O_1$

Alice knows which label corresponds to which bit; the subscript in $L_0$ is her private bookkeeping. Bob will eventually receive exactly one label per wire: for wire $L$, Alice sends the label matching her own bit; for wire $R$, Bob obtains the label matching his bit via oblivious transfer (the primitive introduced above, detailed in its own section below). He ends up holding two labels (one per input wire) but has no way to tell which bit either one represents. He never learns the other label for either wire.

The plain truth table for AND is:

| Left | Right | Output |
|------|-------|--------|
| 0    | 0     | 0      |
| 0    | 1     | 0      |
| 1    | 0     | 0      |
| 1    | 1     | 1      |

Alice now uses *all* her labels to build the garbled table, covering every possible input combination. She can do this because she created all six labels. The table encodes what the correct output label would be for each pair of inputs, encrypted so that only someone holding the right pair can recover it:

| Encrypted Entry |
|-----------------|
| $\text{Enc}_{L_0, R_0}(O_0)$ |
| $\text{Enc}_{L_0, R_1}(O_0)$ |
| $\text{Enc}_{L_1, R_0}(O_0)$ |
| $\text{Enc}_{L_1, R_1}(O_1)$ |

The encryption $\text{Enc}_{L_a, R_b}(O_c)$ is a symmetric-key operation (AES in practice) that uses both input labels as the key. Only someone who knows *both* $L_a$ and $R_b$ can decrypt the corresponding row.

This table has a flaw in its current form. If the rows stay in this order, the evaluator learns which row they decrypted and hence learns the input bits. The fix is to **randomly shuffle the rows**. After shuffling, the garbled table might look like:

| Shuffled Encrypted Entry |
|--------------------------|
| $\text{Enc}_{L_1, R_1}(O_1)$ |
| $\text{Enc}_{L_0, R_0}(O_0)$ |
| $\text{Enc}_{L_1, R_0}(O_0)$ |
| $\text{Enc}_{L_0, R_1}(O_0)$ |

Now Bob holds one label for each input wire. He tries to decrypt each of the four rows using his two labels as the key. Recall that each row was encrypted under a *specific pair* of labels via AES. AES decryption with the wrong key doesn't fail gracefully; it produces random-looking bytes. To tell valid from garbage, each row includes a small authentication tag (a known padding pattern or checksum) alongside the output label. When Bob decrypts with the correct pair, the tag checks out and he recovers the output label. When he decrypts with the wrong pair, the tag is garbled and he knows to discard the result. Exactly one row matches his labels, so he recovers exactly one output label.

This doesn't leak which inputs were used. Bob knows *a* row succeeded, but the rows are shuffled and he doesn't know what bit his labels represent. The position of the successful row tells him nothing about Alice's input or his own in the context of the truth table.

### Hash-indexed tables

Random shuffling forces the evaluator to try all four rows per gate. A more efficient approach uses the hash of the input labels as a row index:

| Row Index | Encrypted Entry |
|-----------|-----------------|
| $H(L_0, R_0)$ | $\text{Enc}_{L_0, R_0}(O_0)$ |
| $H(L_0, R_1)$ | $\text{Enc}_{L_0, R_1}(O_0)$ |
| $H(L_1, R_0)$ | $\text{Enc}_{L_1, R_0}(O_0)$ |
| $H(L_1, R_1)$ | $\text{Enc}_{L_1, R_1}(O_1)$ |

The evaluator, holding labels $L_a$ and $R_b$, computes $H(L_a, R_b)$ and looks up that row directly. No trial decryptions needed. The hash reveals nothing about which row was accessed since the evaluator doesn't know the other labels to compute their hashes.

This structure scales better. Instead of trying all rows, the evaluator does one hash and one decryption per gate. For circuits with millions of gates, the difference matters.

### Chaining gates together

A single gate is not a computation. With either table approach (shuffled or hash-indexed), the evaluator decrypts one entry per gate and obtains an output label. That output label becomes input to the next gate. Labels propagate through the circuit because the garbler ensures consistency: the output labels of one gate are the same labels used as inputs in the next. The evaluator, holding one label per wire, evaluates gate after gate, each time recovering exactly one output label to feed forward.

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

At the final output, the garbler reveals the mapping: "If your output label is $X$, the result is 0; if it's $Y$, the result is 1." Only now does the evaluator learn the actual output bit. This isn't a security breach since the whole point is for both parties to learn $f(a, b)$. The protection is that intermediate wire mappings stay hidden, so the evaluator learns only the final answer, not the computation path that produced it.

### A concrete walkthrough

Let's trace a complete example to see how Alice (garbler) and Bob (evaluator) actually interact. They want to compute $a \land b$ where Alice holds $a = 1$ and Bob holds $b = 0$.

**Step 1: Alice creates the garbled circuit (offline, before any communication).** Alice generates all labels for all wires, including Bob's input wire. She doesn't know Bob's input, so she creates labels for both possibilities:

- Wire $a$ (Alice's input): $L_0 = \texttt{3a7f...}$, $L_1 = \texttt{9c2b...}$
- Wire $b$ (Bob's input): $R_0 = \texttt{5e81...}$, $R_1 = \texttt{d4a3...}$
- Wire $out$: $O_0 = \texttt{72f9...}$, $O_1 = \texttt{1b6e...}$

She builds the garbled table, encrypting each output label under the pair of input labels that would produce it:

| Input Labels | Output Label | Ciphertext |
|--------------|--------------|------------|
| $L_0, R_0$   | $O_0$        | $\text{Enc}_{\texttt{3a7f...,5e81...}}(\texttt{72f9...})$ |
| $L_0, R_1$   | $O_0$        | $\text{Enc}_{\texttt{3a7f...,d4a3...}}(\texttt{72f9...})$ |
| $L_1, R_0$   | $O_0$        | $\text{Enc}_{\texttt{9c2b...,5e81...}}(\texttt{72f9...})$ |
| $L_1, R_1$   | $O_1$        | $\text{Enc}_{\texttt{9c2b...,d4a3...}}(\texttt{1b6e...})$ |

She randomly shuffles the rows and sends the four ciphertexts to Bob. At this point Bob has the encrypted circuit but no labels. He cannot decrypt anything yet.

**Step 2: Bob receives his input labels.** Two things happen through different channels:

- *Alice's input*: Alice knows her bit is $a = 1$, so she sends $L_1 = \texttt{9c2b...}$ to Bob. She does not send $L_0$. Bob receives this label but has no way to tell it corresponds to the bit 1 rather than 0.
- *Bob's input*: Alice holds both $R_0$ and $R_1$ but must not learn Bob's bit. Bob knows he wants $R_0$ (his bit is 0) but cannot tell Alice which one. Via oblivious transfer, Bob receives $R_0 = \texttt{5e81...}$ without Alice learning he chose it, and without Bob learning $R_1$.

Bob now holds exactly one label per input wire: $\texttt{9c2b...}$ for wire $a$ and $\texttt{5e81...}$ for wire $b$.

**Step 3: Bob evaluates.** Bob tries to decrypt each of the four shuffled ciphertexts using his two labels as the key. Each row was encrypted under a *specific pair* of labels. Bob's pair is $(\texttt{9c2b..., 5e81...})$. Only the row that was encrypted under exactly this pair, the row corresponding to $(L_1, R_0)$, decrypts successfully, yielding $O_0 = \texttt{72f9...}$. The other three rows, encrypted under different label pairs, produce garbage when Bob tries them. He cannot decrypt them because he doesn't hold $L_0$ or $R_1$.

**Step 4: Output.** Alice reveals the output mapping: "Label $\texttt{72f9...}$ means 0, label $\texttt{1b6e...}$ means 1." Bob sees he holds $\texttt{72f9...}$, so the result is $1 \land 0 = 0$.

What did Bob learn? Only the output. He never learned that $\texttt{9c2b...}$ "meant 1" or that Alice's input was 1. He never saw $L_0$, $R_1$, or $O_1$. What did Alice learn? Nothing about Bob's input, because oblivious transfer hid his choice. She knows the result (Bob can share it) but not which of Bob's bits produced it.

### Complexity

The basic protocol requires four encryptions per gate (one per truth-table row). An optimization called **Free-XOR** eliminates the garbled table entirely for XOR gates by constraining all label pairs to differ by a global secret $\Delta$; the evaluator simply XORs input labels to obtain the output label with no encryption needed. Since XOR is the most common gate in many circuits, this significantly reduces communication in practice.

Communication is $O(|C|)$, proportional to the circuit size. Computation uses only symmetric-key operations (AES). The protocol runs in constant rounds regardless of circuit depth: one round to send the garbled circuit, one for oblivious transfers.

## Oblivious transfer

The garbled circuits walkthrough relied on a primitive we haven't yet built: a way for Bob to receive one of Alice's two labels without Alice learning which one he chose. This is **oblivious transfer** (OT). In its general form, a sender holds two messages $m_0$ and $m_1$, a receiver holds a choice bit $b$, and after the protocol the receiver learns $m_b$ and nothing else while the sender learns nothing about $b$.

The requirement sounds contradictory. Several constructions make it possible.

### Construction from commutative encryption

Imagine an encryption scheme where the order of encryption and decryption doesn't matter:
$$\text{Dec}_b(\text{Dec}_a(\text{Enc}_b(\text{Enc}_a(x)))) = x$$

Exponentiation in a finite group provides exactly this. Encrypt message $g$ with key $a$ by computing $g^a$. Decrypt by taking an $a$-th root. The order of encryption doesn't matter since $(g^a)^b = (g^b)^a = g^{ab}$, so either party can decrypt their layer without needing the other to go first.

**The OT protocol.** Alice has $n$ messages $x_1, \ldots, x_n$. Bob wants $x_i$ without Alice learning $i$.

1. Alice encrypts all messages with her key $a$ and sends them in order: $\text{Enc}_a(x_1), \ldots, \text{Enc}_a(x_n)$
2. Bob knows he wants the $i$-th message, so he takes the $i$-th ciphertext from the list (he can't read it, but he knows its position). He encrypts it with his own key $b$ and sends back $\text{Enc}_b(\text{Enc}_a(x_i))$
3. Alice decrypts with her key, obtaining $\text{Enc}_b(x_i)$, and sends it to Bob
4. Bob decrypts with his key to recover $x_i$

Bob is protected because Alice sees only a doubly-encrypted blob. She doesn't know Bob's key $b$, so she can't decrypt it to see which message he chose.

Alice is protected because Bob receives only one singly-encrypted message ($\text{Enc}_b(x_i)$ in step 3). The other $n-1$ messages remain encrypted under Alice's key, which Bob doesn't have.

### Construction from Diffie-Hellman

The commutative encryption approach requires three rounds of communication between Alice and Bob. A construction based on Diffie-Hellman key exchange reduces this to two rounds by exploiting the fact that the receiver's choice bit can be hidden inside a group element.

Work in a group $\mathbb{G}$ of prime order $q$ with generator $g$. The sender chooses random $a$ and sends $A = g^a$. The receiver embeds their choice bit $b$ into their response: if $b = 0$, choose random $k$ and send $B = g^k$; if $b = 1$, send $B = A \cdot g^k = g^{a+k}$ for random $k$. Either way, the sender sees a random-looking group element $B$ and cannot tell which case applies.

The sender computes two keys: $K_0 = B^a$ and $K_1 = (B \cdot A^{-1})^a$. Then the sender encrypts both messages, $c_0 = \text{Enc}_{K_0}(m_0)$ and $c_1 = \text{Enc}_{K_1}(m_1)$, and sends both ciphertexts.

The receiver can compute only one key. If $b = 0$, the receiver knows $k$ and can compute $K_0 = A^k = g^{ak}$, which equals $B^a$ since $B = g^k$. But $K_1 = (B/A)^a = g^{(k-a)a}$ requires knowing the discrete log of $B/A$, which the receiver doesn't have. The receiver decrypts $c_0$ and learns $m_0$. If $b = 1$, the situation reverses: the receiver can compute $K_1$ but not $K_0$.

The sender sees only $B$, a random group element that reveals nothing about whether the receiver chose $b = 0$ or $b = 1$.

Both constructions require public-key operations (exponentiations), which is fine for a handful of OTs but problematic when garbled circuits need one OT per input bit. **OT extension** (the IKNP protocol) solves this by using a small number of base OTs (typically 128) to bootstrap an unlimited number of extended OTs using only symmetric-key operations. The amortized cost drops to a few AES calls per OT, making garbled circuits practical even for million-bit inputs.

## Mixing protocols

Real computations rarely fit neatly into one paradigm. A machine learning inference might need field arithmetic for the linear layers (where secret-sharing MPC excels) but comparisons for activation functions (where garbled circuits handle more efficiently). The most practical approach switches representations mid-computation, using each paradigm where it performs best.

Modern MPC frameworks formalize this by supporting three representations: arithmetic sharing for field operations, Boolean sharing for bitwise operations and comparisons, and Yao's garbled circuits for complex Boolean functions. Conversion protocols translate between them. Arithmetic-to-Boolean (A2B) converts additive shares of a field element into XOR-shares of its bit representation. Boolean-to-Arithmetic (B2A) reverses the process, using oblivious transfer to handle the carry bits that arise when interpreting binary as an integer.

The design problem becomes partitioning a computation so that each segment uses its most efficient representation. Deep multiplicative chains favor arithmetic sharing. Complex comparisons favor Boolean or Yao representations. The optimal decomposition is often hand-tuned for applications where performance matters.

## MPC-in-the-head

Everything so far has developed MPC as a tool for private computation among real parties. But this is a book about proof systems, and the MPC machinery we've built turns out to produce zero-knowledge proofs through an unexpected route, one that bypasses polynomial commitments, pairings, and algebraic IOPs entirely.

The transformation is called "MPC-in-the-head," and it rests on a symmetry between MPC security and zero-knowledge. In a real MPC protocol, multiple parties compute on secret-shared inputs with the guarantee that no coalition learns more than the output. MPC-in-the-head takes this guarantee and repurposes it: the prover secret-shares the witness among $n$ *imaginary* parties, then simulates the MPC protocol that would compute $R(x, w)$ entirely inside their own mind, playing all $n$ roles. Each simulated party accumulates a "view" consisting of the messages it sent and received, its random tape, and its share of the witness. The prover commits to all $n$ views. What was privacy against colluding parties becomes zero-knowledge against the verifier.

Think of a one-person theater troupe performing a three-character scene. The prover writes out the full script: what Alice said to Bob, what Bob said to Charlie, what Charlie said to Alice. Then they seal each character's script in a separate envelope.

The verifier picks two envelopes at random and checks whether the scripts agree. Do the messages that party $i$ claims to have sent match what party $j$ claims to have received? Did both follow the protocol correctly? Does the output equal 1? If Alice's script says she sent "7" to Bob but Bob's script says he received "9," the inconsistency is caught. By checking different random pairs across repetitions, the verifier catches any forged execution with high probability.

Soundness holds because a cheating prover cannot forge consistency across all pairs of views. If the witness is invalid, the honest MPC would output 0. To fake acceptance, the prover must manufacture views where the protocol appears to output 1, but any inconsistency between a pair of views (mismatched messages, or a party that deviated from the protocol rules) gets caught when the verifier opens that pair. A cheating prover can make *some* pairs consistent, but not all. Each random challenge catches an inconsistent pair with constant probability; repetition amplifies.

Zero-knowledge follows directly from MPC privacy. The number of views the verifier opens must stay below the reconstruction threshold $t$ of the underlying secret sharing scheme. In a $t$-threshold scheme, any $t-1$ shares are consistent with every possible secret, so opening $t-1$ views reveals nothing about the witness. The choice of $t$ controls the tradeoff: higher thresholds allow opening more views (better soundness per repetition) while still preserving zero-knowledge. In the simplest case, 3-party additive sharing requires all 3 shares to reconstruct ($t = 3$), so opening 2 views is safe. Those 2 views suffice to check one pair for consistency, giving soundness error $1/3$ per round, driven down by repetition.

### Instantiations

**ZKBoo and ZKB++** use 3-party secret sharing. The verifier opens 2 of 3 parties, giving a soundness error of $1/3$ per repetition. These schemes excel at proving knowledge of hash preimages, where the circuit structure is fixed and well-optimized.

**Ligero** combines MPC-in-the-head with Reed-Solomon codes, achieving proof size $O(\sqrt{n})$ for circuits with $n$ gates. This is sublinear, better than naive approaches though not as succinct as polynomial-based SNARKs.

**Limbo** and subsequent work push practical performance further, targeting real-world deployment for specific statement classes.

MPC-in-the-head shows that MPC techniques can build proof systems. But MPC also has direct applications of its own, and the most widely deployed is threshold cryptography.



## Threshold cryptography

MPC computes arbitrary functions on distributed inputs, but some functions appear so frequently that they deserve specialized protocols. The most important special case is cryptographic key operations. A single signing key or decryption key creates a single point of failure, and the compromise of that one key invalidates all the security built on top of it. MPC provides a way to eliminate that single point by distributing the key itself.

Threshold cryptography applies this idea directly. Instead of a single party holding a signing or decryption key, $n$ parties each hold a share. Any $t$ of them can cooperate to sign or decrypt, but no coalition of fewer than $t$ learns anything about the key. The secret never exists in one place.

### Threshold key operations

A cryptocurrency exchange holding billions in assets cannot afford to store a signing key on a single machine. The traditional defense is multisig, where the blockchain verifies $t$-of-$n$ separate signatures. But multisig reveals the signing structure on-chain and requires protocol-level support. Threshold signatures take a different approach: the $n$ parties hold shares of a single signing key $sk$, and when $t$ cooperate they produce a single signature indistinguishable from one generated by a solo signer. The blockchain sees nothing unusual. The distribution is invisible.

The reason Schnorr signatures lend themselves to this is linearity. A Schnorr signature has the form $s = k + e \cdot x$ where $k$ is a nonce, $e$ is the challenge hash, and $x$ is the signing key. If parties hold Shamir shares $k_i$ and $x_i$, they compute partial signatures $s_i = k_i + e \cdot x_i$. Lagrange interpolation reconstructs $s = k + e \cdot x$ exactly, the same reconstruction used throughout this chapter.

**FROST** builds a complete threshold Schnorr protocol around this observation. In the first phase, parties jointly generate shares of the nonce $k$ using Feldman's verifiable secret sharing (Appendix A), so that each party contributes randomness without anyone learning the full nonce. In the second phase, each party computes their partial signature and the results combine via interpolation. Feldman's verifiability lets parties detect malformed shares during nonce generation, catching cheaters before they can disrupt signing.

FROST requires **synchronous coordination** during nonce generation: all participating signers must be online simultaneously to exchange commitments. If a signer drops offline, the protocol stalls. **ROAST** wraps FROST in an asynchronous coordinator that adaptively selects responsive signers, maintains concurrent sessions, and starts fresh with a different subset when someone times out. The first session to complete produces the signature. ROAST doesn't modify FROST's cryptography; it adds a session management layer that makes threshold signing practical across time zones and unreliable networks.

Threshold ECDSA is harder. ECDSA signatures involve a modular inversion step, $s = k^{-1}(z + r \cdot x)$, and inversion is not linear. Computing it on shared values requires a full MPC protocol for the inversion, adding rounds and computational overhead. Protocols like GG18 and GG20 solve this but at higher cost than FROST.

The same distribution principle applies beyond signing. Threshold decryption (used in e-voting systems like Helios and Belenios via threshold ElGamal) splits a decryption key so that encrypted ballots can only be opened after polls close and only if enough trustees cooperate. The pattern generalizes: any cryptographic operation that depends on a secret key can, in principle, be distributed so that the key never exists in one place.

## Practical considerations

The protocols developed in this chapter are theoretically complete. Given enough time and bandwidth, any function can be computed securely. But deploying MPC in practice introduces constraints that the theory abstracts away.

### Communication is the bottleneck

MPC and ZK have opposite performance profiles. A ZK prover performs heavy local computation (MSMs, FFTs, hashes) but sends a small proof. An MPC protocol does lightweight computation at each party but exchanges massive amounts of data between them. A ZK prover might spend 10 seconds computing and 10 milliseconds sending; an MPC protocol might spend 10 milliseconds computing and 10 seconds sending. You can run a ZK prover on a single powerful machine, but you can't run high-speed MPC over a slow network.

Within MPC, the binding constraint is usually either bandwidth or latency, and which one dominates determines the protocol choice. If bandwidth is cheap but latency is high (parties on different continents), garbled circuits win because they run in constant rounds despite sending more data. If bandwidth is limited but latency is low (parties in the same data center), secret-sharing MPC wins because each round sends less. The network, not the cryptography, is usually what makes MPC slow.

### Preprocessing vs. online

MPC protocols are slow when inputs arrive because every operation pays a cryptographic cost. For latency-sensitive applications like sealed-bid auctions, where parties submit bids that must be processed immediately, this cost is unacceptable. The solution is to separate the computation into two phases. The preprocessing phase generates correlated randomness before the actual inputs are known. Beaver triples for multiplication, OT correlations for garbled circuits, random sharings for masking all fall into this category. The online phase consumes this preprocessed material to compute on the real inputs. 

Because none of this preprocessed material depends on the actual inputs, it can be generated during idle time, spreading the heavy cryptographic work across hours or days. When inputs finally arrive, the online phase consumes the stockpiled randomness and runs fast, achieving sub-second latency despite the underlying complexity.

Where does the preprocessing come from? In production systems (cryptocurrency custody platforms, private computation services built on SPDZ), the parties typically generate it themselves via OT extensions or homomorphic encryption, paying the full cost upfront but requiring no trusted party. A simpler alternative is a trusted dealer who generates and distributes the correlated randomness, though this reintroduces a single point of trust that MPC was designed to eliminate. Hybrid approaches using trusted execution environments as hardware-backed dealers are emerging in the wallet and custody space but remain less established.

### Malicious security

Everything so far assumes semi-honest adversaries who follow the protocol faithfully but try to extract information from what they observe. Real deployments often face adversaries who can deviate arbitrarily, sending malformed messages or aborting at strategic moments. Adding security against such adversaries requires mechanisms to detect cheating.

For secret-sharing MPC, the main tool is authentication. The SPDZ protocol attaches a Message Authentication Code (MAC) to each shared value. When shares are combined or reconstructed, the MACs are verified. A cheating party who modifies a share will fail the MAC check with overwhelming probability. The SPDZ preprocessing includes authenticated Beaver triples so that the online phase can verify multiplications respect the triple structure. Recent work has brought the communication cost of malicious SPDZ close to the semi-honest baseline, narrowing a gap that was once a factor of two.

For garbled circuits, the problem is different. The semi-honest protocol assumes the garbler constructs the circuit correctly, but a malicious garbler could create a circuit that computes the wrong function, leaking information about the evaluator's input. Early solutions used **cut-and-choose**, where the garbler creates dozens of independent garbled circuits and the evaluator randomly selects some to verify and the rest to evaluate. This works but is expensive. Modern protocols use **authenticated garbling**, which achieves malicious security with a single garbled circuit by attaching authentication tags to each wire label, reducing the overhead substantially.

In practice, malicious security is standard for high-value operations. Cryptocurrency custody platforms (Fireblocks, Coinbase) use malicious-secure threshold signature protocols, since a compromised signing ceremony could mean direct financial loss. General-purpose malicious-secure MPC remains more expensive and is less common in production, though the cost gap continues to shrink.

## Key takeaways

1. **MPC eliminates trusted third parties.** Any function computable by a circuit can be computed jointly by mutually distrustful parties, revealing only the output. Security is defined through simulation: whatever a corrupt coalition observes, it could have generated from its own inputs and the output alone.

2. **MPC solves the "who runs the prover?" problem.** When a witness is too sensitive for any single party, secret-sharing it among multiple proving servers lets them jointly compute a ZK proof without any server learning the witness.

3. **Two paradigms with different tradeoffs.** Secret-sharing MPC (BGW) handles $n$ parties with free linear operations but rounds proportional to multiplicative depth. Garbled circuits achieve constant rounds for two parties but communicate proportional to circuit size. The network, not the cryptography, usually determines which wins.

4. **MPC-in-the-head bridges MPC and ZK.** Simulate an MPC protocol inside the prover's mind, commit to all party views, let the verifier audit a random subset. MPC privacy becomes zero-knowledge; MPC correctness becomes soundness. This yields proof systems (ZKBoo, Ligero) that bypass polynomial machinery entirely.

5. **Threshold cryptography distributes key operations.** Secret-share a signing or decryption key among $n$ parties so that any $t$ can operate but fewer than $t$ learn nothing. FROST makes threshold Schnorr practical; ROAST adds asynchrony. This is the most widely deployed application of MPC.

6. **Malicious security is production-ready for high-value operations.** SPDZ authenticates shares with MACs; authenticated garbling verifies circuit construction. Cryptocurrency custody platforms use malicious-secure threshold signatures as standard, while general-purpose malicious MPC continues to close the cost gap with semi-honest protocols.

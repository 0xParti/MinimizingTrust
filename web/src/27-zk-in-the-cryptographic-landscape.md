# Chapter 27: ZK in the Cryptographic Landscape

In 1943, a resistance fighter in occupied France needs to send a message to London. She writes it in cipher, slips it into a dead letter drop, and waits. A courier retrieves it, carries it across the Channel, and a cryptographer at Bletchley Park decrypts it. The message travels safely because no one who intercepts it can read it.

For the next fifty years, this was cryptography's entire mission: move secrets from A to B without anyone in between learning them. Telegraph, radio, internet. The medium changed; the problem stayed the same. Encrypt, transmit, decrypt. A message sealed or opened, a secret stored or revealed.

Then computers stopped being message carriers and became *thinkers*. The question changed. It was no longer enough to ask "can I send a secret?" Now we needed to ask: "can I *use* a secret without exposing it?"

This is the dream of **programmable cryptography**: not just secure storage and transmission, but secure *computation*. Mathematics that thinks while blindfolded.

The dream took many forms. "Can I prove I know a secret without revealing it?" led to zero-knowledge proofs. "Can we compute together while keeping our inputs private?" led to secure multiparty computation. "Can I encrypt data so someone else can compute on it?" led to fully homomorphic encryption. "Can I publish a program that reveals nothing about how it works?" led to program obfuscation.

These aren't just different techniques; they're different philosophies about who computes, who learns, and what trust means. For decades they developed in parallel, each with its own community, its own breakthroughs, its own brick walls.

This book taught you the path that arrived first: zero-knowledge proofs. Of the four dreams, ZK is the only one that reached satisfying practicality. Understanding *why* ZK succeeded where others struggled illuminates both the landscape and the road ahead.


## Why ZK Arrived First

The most important asymmetry is structural: the prover works in the clear. In ZK, the expensive cryptographic operations happen *after* the computation, not during it. The prover computes at native speed, then invests work in generating a proof. In FHE, every operation pays the cryptographic tax. In program obfuscation, the program itself becomes the cryptographic object. This difference compounds across millions of operations.

ZK also benefited from mathematical serendipity. SNARKs exploit polynomial arithmetic over finite fields, exactly what elliptic curves, pairings, and FFTs handle efficiently. The tools developed for other purposes (error-correcting codes, number theory, algebraic geometry) turned out to fit the ZK problem beautifully. FHE and obfuscation involve noise management and lattice arithmetic that fight against efficient computation rather than harmonizing with it.

The theory developed steadily over thirty years. The path from GMR (1985) to PCPs (1992) to IOPs (2016) to practical SNARKs (2016-2020) was long but each step built on the previous. The sum-check protocol from 1991 became the heart of modern systems. Polynomial commitments from 2010 enabled succinctness. The pieces accumulated until they clicked together.

Finally, blockchain created urgent demand. Scalability, privacy, trustless verification: billions of dollars flowed into ZK research. The ecosystem grew with companies, open-source libraries, educational materials, and developer tools. FHE has applications but no comparable catalyst. Program obfuscation has no applications that couldn't wait until it works, a chicken-and-egg problem that starves it of engineering investment.

Secure multiparty computation (MPC) also reached practicality, though with different trade-offs. Chapter 25 covers MPC in depth: secret sharing, garbled circuits, oblivious transfer, and how MPC techniques yield ZK proofs through the "MPC-in-the-head" paradigm. This chapter focuses on the two dreams that remain partially unfulfilled: computing on encrypted data, and making programs incomprehensible.



## Gentry's Miracle: Computing on Ciphertexts

For thirty years, cryptographers wondered: is fully homomorphic encryption even possible?

The question wasn't idle. A homomorphic encryption scheme lets you compute on ciphertexts, encrypting $x$ and $y$ to produce a ciphertext of $x + y$ without knowing $x$ or $y$. Many schemes could do *some* operations. RSA is multiplicatively homomorphic: $E(m_1) \cdot E(m_2) = E(m_1 \cdot m_2)$. Paillier is additively homomorphic: encryption has the form $E(m) = g^m \cdot r^n \mod n^2$ for random $r$, so multiplying ciphertexts yields $E(m_1) \cdot E(m_2) = g^{m_1 + m_2} \cdot (r_1 r_2)^n = E(m_1 + m_2)$. But a scheme that handles *both* addition and multiplication (and therefore any computation) required something no one knew how to build.

Craig Gentry's 2009 thesis changed everything.

### The Core Idea: Learning With Errors

Modern FHE rests on a problem called **Learning With Errors (LWE)**. The intuition is simple: linear equations are easy to solve, but linear equations with noise are hard.

> **The Radio Noise Analogy**
>
> Imagine you're trying to tune into a radio station. If the signal comes through perfectly clear, you hear every word. But add static, and suddenly comprehension becomes difficult. Add enough static, and the voice becomes indistinguishable from random noise.
>
> LWE works the same way. The "signal" is a linear equation. Without noise, anyone can solve it. But add a small random error to each equation, and the system becomes unsolvable. The legitimate receiver has a "filter" (the secret key) that strips away the static. Everyone else hears only noise.

**The easy problem.** Suppose I give you equations like $3x + 2y = 17$ and $5x + y = 19$. You solve for $x$ and $y$ immediately. This is high school algebra. Even with hundreds of variables, Gaussian elimination solves it in polynomial time.

**The hard problem.** Now suppose each equation has a small random error: $3x + 2y \approx 17$ and $5x + y \approx 19$, where "$\approx$" means "equals, plus or minus a little noise." Suddenly the problem becomes believed to be intractable. The errors compound; you can't tell whether a near-solution is wrong or just obscured by noise. This is LWE: given noisy linear equations, recover the unknowns.

**Why this enables encryption.** The secret key is a vector $\vec{s}$ (the "unknowns" in our linear system). The modulus $q$ is a public parameter. To encrypt a single bit $m \in \{0, 1\}$:

1. Pick a fresh random vector $\vec{a}$ (the "coefficients," different for each encryption)
2. Pick small random noise $e$
3. Compute $b = \langle \vec{a}, \vec{s} \rangle + e + m \cdot \lfloor q/2 \rfloor$
4. The ciphertext is $(\vec{a}, b)$. Both values are public, sent to whoever will compute on them

The message bit $m$ gets encoded as a large shift: if $m = 0$, we add nothing; if $m = 1$, we add $q/2$ (half the modulus). This creates a big gap between encodings of $0$ and $1$. The noise $e$ is tiny by comparison: it obscures the exact value but not which half of the range we're in.

**Decryption.** Someone who knows $\vec{s}$ computes $b - \langle \vec{a}, \vec{s} \rangle = e + m \cdot \lfloor q/2 \rfloor$. The noise $e$ is small (say, less than $q/10$), so rounding to the nearest multiple of $q/2$ recovers $m$ exactly: values near $0$ decrypt to $0$; values near $q/2$ decrypt to $1$.

**Security.** An attacker sees many ciphertexts $(\vec{a}_i, b_i)$ and wants to recover $\vec{s}$. But each $b_i$ is a noisy linear combination of $\vec{s}$. Solving noisy linear equations is the LWE problem, believed hard even for quantum computers. This quantum resistance is why lattice-based cryptography (including FHE) is central to post-quantum cryptographic standards.

### The Noise Problem

The magic (and the curse) lies in how operations affect the error. A concrete example makes this vivid.

**Setup.** Say our modulus is $q = 1000$. We encode bit $0$ as values near $0$, and bit $1$ as values near $500$ (that's $q/2$). Fresh ciphertexts have noise around $\pm 10$. Decryption works by asking: "Is this value closer to $0$ or to $500$?"

**Fresh encryption.** Encrypt two bits, both equal to $1$:

- Ciphertext $c_1$ decrypts to $500 + 7 = 507$ (the $7$ is noise)
- Ciphertext $c_2$ decrypts to $500 - 4 = 496$ (the $-4$ is noise)

Both decrypt correctly: $507$ is closer to $500$ than to $0$, so it's a $1$. Same for $496$.

**Addition.** Add the ciphertexts to compute $1 + 1 = 0$ (in binary, with carry). The noises add:

- Result decrypts to $(507 + 496) \mod 1000 = 1003 \mod 1000 = 3$

Noise is now $7 + (-4) = 3$. Still small. Decryption works: $3$ is close to $0$, giving the correct answer.

**Multiplication.** Here's where trouble starts. Multiplying ciphertexts (through a clever but complex construction) multiplies the noises:

- After one multiplication: noise $\approx 7 \times 4 = 28$
- After two multiplications: noise $\approx 28 \times 10 = 280$
- After three multiplications: noise $\approx 280 \times 10 = 2800$

But our "safety margin" is only $250$ (values must stay closer to their target than to the other option). After just a few multiplications, the noise exceeds the margin. A value that should decrypt to $1$ (near $500$) might land at $500 + 280 = 780$, which is closer to $1000 \equiv 0$ than to $500$. Decryption returns garbage.

This is the **noise budget**: every FHE scheme has a limit on how much computation can be performed before the ciphertext becomes useless. Addition is cheap (noise grows linearly). Multiplication is expensive (noise grows multiplicatively, which becomes exponential in circuit depth).

### Bootstrapping: The Key Insight

Gentry's breakthrough was **bootstrapping**: a way to produce a fresh, low-noise ciphertext from a noisy one, without ever decrypting in the clear.

**The problem.** Continuing our example: you have a ciphertext encoding the bit $1$, but the noise has grown to $280$. The internal value is $500 + 280 = 780$. One more multiplication and you'll cross into garbage territory. You need to somehow reduce the noise from $280$ back down to something small like $10$, while keeping the message ($1$) intact, and without ever exposing the plaintext.

**The key observation.** Decryption *is itself a computation*. It takes a ciphertext and a secret key, does some arithmetic (subtract the mask, then round), and outputs the plaintext bit. If we could run this computation homomorphically, on encrypted inputs, we'd get an encrypted output.

**The clever trick.** Here's the setup:

- You have a noisy ciphertext $c$ (noise $= 280$, encoding bit $1$)
- You also have, as a public parameter, an encryption of the secret key: $\text{Enc}(\vec{s})$

Now do the following:

1. Treat your noisy ciphertext $c$ as public data (it's already encrypted, so this is safe)
2. Run the decryption circuit homomorphically, using $\text{Enc}(\vec{s})$ as the key input
3. The circuit computes: "subtract the mask, round to nearest $0$ or $500$, output the bit"
4. Since the key was encrypted, the output is also encrypted: you get $\text{Enc}(1)$

**What got "reset"?** The output $\text{Enc}(1)$ is a *fresh* ciphertext. Its noise comes only from the bootstrapping computation itself (say, noise $= 50$), not from the $280$ that had accumulated before. The message is the same ($1$), but the noise dropped from $280$ to $50$. You've bought yourself room for more multiplications.

**Why does this work?** The old noise ($280$) was inside ciphertext $c$. When you run decryption homomorphically, that $280$ gets processed by the rounding step, which absorbs it (rounding $780$ to $500$ gives $1$, correctly). The *new* noise ($50$) comes from the homomorphic operations in the bootstrapping circuit, which is much smaller than $280$ because the decryption circuit is shallow.

**The catch.** The decryption circuit must be simple enough that running it homomorphically doesn't itself exhaust the noise budget. If decryption required deep circuits, bootstrapping would add more noise than it removes. Gentry's construction carefully designs decryption to be "bootstrappable," but the cost is significant: early implementations took minutes per bootstrap.

**The payoff.** With bootstrapping, there's no depth limit. Compute until noise gets dangerous, bootstrap to refresh, continue. Any computation becomes possible, one refresh at a time.

### Modern Schemes

The fifteen years since Gentry's thesis have seen real improvements, but FHE remains far from practical for general use.

**TFHE** (Torus FHE) optimizes for Boolean circuits. It achieves "programmable bootstrapping": the bootstrap operation itself can compute a function, giving gate-by-gate evaluation in ~10-50ms per gate on modern hardware. Good for bit-level operations, but 10ms per gate means a circuit with a million gates takes hours.

**BGV/BFV** optimize for integer arithmetic. They exploit "batching": a single ciphertext can encode thousands of values, and operations apply to all simultaneously (SIMD-style parallelism). One multiplication computes thousands of products. This helps for embarrassingly parallel workloads, but many real computations don't parallelize cleanly.

**CKKS** accepts approximate arithmetic. Instead of exact integers, it works with fixed-point real numbers, allowing small errors in exchange for efficiency. This makes it suitable for machine learning inference, where tiny numerical errors don't affect results. But "suitable" is relative: encrypted inference on a small neural network still takes seconds to minutes, versus milliseconds in the clear.

**The honest assessment.** Current overhead sits at roughly $10^3$ to $10^4$ times native computation. Early implementations were a million times slower; today's best are "only" a thousand times slower. This is genuine progress, but a thousand-fold slowdown is still brutal. A computation that takes 1 second in the clear takes 15 minutes encrypted. A 1-minute computation becomes a full day.

For narrow applications (simple queries on encrypted databases, basic encrypted analytics), FHE is starting to see deployment. But for general computation, the overhead remains prohibitive. Nobody is running encrypted video processing or encrypted large-language-model inference.

**Will it ever be practical?** Unknown. The optimists point to the trajectory: million-fold → thousand-fold in 15 years. Another 15 years might bring another few orders of magnitude. Hardware acceleration (custom FPGAs, ASICs) could help. The pessimists note that the overhead may be fundamental: noise management and ciphertext expansion might have irreducible costs. ZK proofs found clever ways around their bottlenecks; FHE might not.

> **Why Hardware Acceleration Matters**
>
> FHE's core operations are polynomial arithmetic and Number Theoretic Transforms (NTTs) over large integers. CPUs execute these operations sequentially, one instruction at a time. But NTTs are massively parallelizable: the same operation applied to thousands of coefficients simultaneously.
>
> Custom hardware (FPGAs, ASICs) can exploit this parallelism directly. Where a CPU computes one multiplication, a dedicated chip computes thousands in the same clock cycle. Companies like Intel, DARPA, and several startups are building FHE accelerators that promise 100-1000× speedups over software implementations.
>
> If these accelerators deliver, FHE's effective overhead drops from 1000× to 1-10×. That's the difference between "research curiosity" and "production deployment."

Libraries like Microsoft SEAL, OpenFHE, and Zama's Concrete have made FHE accessible to researchers and adventurous practitioners. But "accessible" doesn't mean "deployable at scale."



## The Holy Grail That Wasn't

Program obfuscation is the most ambitious dream of all. Not just computing on secrets, but making *programs themselves* into secrets.

### The Dream: Virtual Black-Box Obfuscation

The strongest notion is **virtual black-box (VBB) obfuscation**. The idea: transform a program's source code into a form that still runs correctly, but reveals nothing about *how* it works.

**A concrete example.** Suppose you have a program that checks passwords:

```
def check(password):
    return password == "hunter2"
```

An obfuscator would transform this into something like:

```
def check_obfuscated(password):
    # 10,000 lines of incomprehensible bit manipulation
    # that somehow still returns True iff password == "hunter2"
```

The obfuscated version works identically (returns True for "hunter2", False for everything else), but someone reading the code can't figure out what the secret password is. They can *use* the program, but they can't *understand* it.

**The formal requirement.** An obfuscator $\mathcal{O}$ satisfies VBB if for any program $P$:

1. **Functionality**: $\mathcal{O}(P)(x) = P(x)$ for all inputs $x$
2. **Black-box security**: Anything efficiently computable from $\mathcal{O}(P)$ is also efficiently computable given only oracle access to $P$

In plain terms: having the obfuscated code gives you no advantage over having a locked box that runs the program. You can query the box with inputs and see outputs, but that's it. Any information you could extract from the obfuscated code, you could also get just by running it on test inputs. The code is in front of you, but it's as opaque as a black box.

**Why this would be transformative.** With VBB obfuscation, you could:

- Ship proprietary algorithms to untrusted machines. The code runs locally, but competitors can't reverse-engineer it.
- Distribute a SNARK prover with a witness baked in. Anyone can generate proofs, but no one can extract the witness.
- Build "time-lock" encryption: a program that decrypts a message only after a certain date, with no way to extract the key early.
- Create software licenses that are actually enforceable: the program checks the license, and there's no way to patch out the check.

### The Impossibility

In 2001, Barak, Goldreich, Impagliazzo, Rudich, Sahai, Vadhan, and Yang proved that **VBB obfuscation is impossible** in general.

The key insight: some programs are inherently "unobfuscatable." The proof constructs a pair of programs $P_0$ and $P_1$ that:

- Have identical input-output behavior on almost all inputs
- Can be distinguished by examining their *code*

No obfuscator can hide which program was obfuscated. The distinguishing property survives any transformation that preserves functionality.

The construction is diabolically clever. Program $P_b$ behaves normally on most inputs, but if given *its own code* as input, it outputs $b$. This self-reference traps any obfuscator:

$$P_b(\mathcal{O}(P_b)) = b$$

Any obfuscation of $P_b$ must output $b$ when fed itself, revealing which program it came from. No amount of code transformation can hide this.

### The Weaker Notion: Indistinguishability Obfuscation

A weaker notion survived. **Indistinguishability obfuscation (iO)** guarantees only:

If programs $P_0$ and $P_1$ compute the *same function* (identical outputs on all inputs), then their obfuscations are computationally indistinguishable:

$$\mathcal{O}(P_0) \approx_c \mathcal{O}(P_1)$$

You cannot tell which equivalent implementation was obfuscated.

This seems weak: you're only hiding the *implementation details*, not the *function*. Given two different implementations of the same algorithm, you can't tell which one was used. So what?

### Why iO Is Powerful

At first, iO sounds useless. "You can't tell which of two equivalent implementations was obfuscated." Who cares? If they compute the same function, why does it matter which one you started with?

**The lightbulb moment.** The power of iO comes from *what you can hide inside equivalent programs*.

Consider two programs that both output "Hello, World!":

```
Program A: print("Hello, World!")

Program B:
    secret_key = 0x7a3f...  # 256-bit key, embedded in the code
    if sha256(input) == target:
        return decrypt(secret_key, ciphertext)
    print("Hello, World!")
```

Program B has a secret key hidden inside it. On every normal input, it behaves identically to Program A (just prints the greeting). But if you find an input whose hash matches `target`, it decrypts and returns a hidden message.

Here's the magic: *these programs compute the same function* (assuming finding the hash preimage is computationally infeasible). No efficient algorithm can find an input that distinguishes them. So by iO, their obfuscations are indistinguishable.

This means you can take Program B, obfuscate it, and publish the result. The secret key is *in the code*, but no one can extract it. The obfuscated program is indistinguishable from an obfuscation of the trivial Program A, which contains no secrets at all. The key is hidden in plain sight.

**The utopia iO promises.** With efficient iO, you could build almost any cryptographic primitive imaginable. The most striking is *witness encryption*: encrypt a message so that only someone who knows a solution to a puzzle can decrypt it. Not a specific person with a specific key, but *anyone* who can solve the puzzle. "This message can be read by whoever proves P ≠ NP." "This inheritance unlocks for whoever finds my will." The decryption key doesn't exist until someone produces the witness.

$$\text{WE.Enc}(\text{statement}, m) \to c \qquad \text{WE.Dec}(c, \text{witness}) \to m$$

> **The Time Capsule Analogy: Witness Encryption vs ZK**
>
> Think of witness encryption as a time capsule with a puzzle lock. You seal a message inside and inscribe a mathematical challenge on the outside. Anyone who solves the puzzle can open the capsule and read the message. You don't need to know *who* will solve it, or *when*. The lock itself enforces the access rule.
>
> Zero-knowledge works in the opposite direction. Instead of "prove you can solve this to read the secret," ZK says "prove you already solved this without showing your solution." WE grants access based on future knowledge. ZK demonstrates existing knowledge.
>
> The duality is precise: both are parameterized by an NP statement. WE encrypts *to* the statement (anyone with a witness can decrypt). ZK proves *about* the statement (I have a witness, but you won't learn it).

Witness encryption reveals a beautiful duality with zero-knowledge. A ZK proof says "I know a witness for statement $x$" without revealing it. Witness encryption says "only someone who knows a witness can read this" without specifying who. One proves knowledge; the other grants access based on knowledge. They're two sides of the same coin, formalized through the same NP relation.

The applications cascade from there. *Functional encryption* lets you give someone a key that computes $f(m)$ from an encryption of $m$, without learning $m$ itself. A hospital holds encrypted patient records; a researcher gets a key that computes "average age of diabetic patients" but reveals nothing else. Not "decrypt or don't," but fine-grained access to computations on secrets. *Deniable encryption* lets you encrypt a message, then later produce fake randomness that makes it look like you encrypted something completely different. Under coercion, you reveal the fake randomness; the adversary decrypts and sees an innocent message. True plausible deniability, mathematically guaranteed. You could even build *self-destructing programs*: code that works for a while, then stops, not because of a flag you can patch out, but because the cryptographic structure makes continued execution impossible after a deadline.

iO is the "master tool" of cryptography. Given iO, you can build almost anything. The constraint isn't imagination; it's efficiency.

### The Construction and Its Costs

In 2021, Jain, Lin, and Sahai finally constructed iO from well-founded assumptions. The theoretical question was settled: iO exists, assuming standard cryptographic hardness (variants of LWE and related problems).

The construction is intricate. It uses **branching programs** as the computational model: a restricted form of computation where the program's state follows a path through a graph based on input bits. The obfuscation encodes these transitions in algebraic noise:

- Matrix encodings hide the transition structure
- Randomized self-reduction prevents reverse-engineering
- Careful algebraic constraints preserve evaluability

The intuition: the program becomes a maze of matrix operations that computes correctly but reveals no structure.

### The Practical Wall

Current constructions are not merely slow; they are *cosmologically* slow.

Obfuscating a circuit of size $n$ requires operations scaling as $2^{O(n)}$. Not polynomial, not quasi-polynomial: exponential. For any program larger than a few hundred gates, the computational cost exceeds what the observable universe could perform.

Unlike FHE, which improved from $10^{12}\times$ overhead to $10^3\times$ in fifteen years, iO has no clear path to practicality. The exponential blowup appears inherent to current techniques.

**The lesson**: Not every theoretically possible primitive becomes practical. Some are waiting for new mathematical insights. Some may never arrive.



## The Convergence

The boundaries between these approaches are dissolving.

The most natural combination is zkFHE. A server computes on encrypted data using FHE, but how does the client know the server computed correctly? The server generates a ZK proof of correct FHE evaluation. The client verifies without decrypting intermediate results, getting both privacy and verifiability in one protocol.

Private machine learning illustrates the complementary strengths. ZK can prove correct inference without revealing model or input (Chapter 26 discusses the challenges). FHE allows the model owner to receive encrypted queries and return encrypted responses, never seeing the actual data. These aren't competing approaches; they're different trust models for different deployments. Similarly, MPC protocols let multiple parties compute together (Chapter 25), and ZK can prove they followed the protocol honestly without revealing individual contributions. Threshold signatures, distributed key management, collaborative computation with verification: the primitives compose.

Even the line between proving and computing is blurring. The folding and accumulation techniques from Chapter 23 let incrementally verifiable computation fold claims together, deferring expensive proof work. Is this ZK, or a new form of verifiable computation? The categories no longer carve nature at its joints.

The dream of programmable cryptography is fragmenting into specialized tools. ZK handles verification without revelation. MPC enables joint computation. FHE supports outsourced computation on secrets. Each occupies a niche; together they cover territory no single approach could reach.

Hardware approaches offer yet another trade-off. Trusted Execution Environments (TEEs) like Intel SGX and ARM TrustZone rely on hardware isolation rather than cryptographic protection: a "secure enclave" that even the operating system cannot inspect. TEEs are fast (near-native speed) but require trusting the hardware manufacturer, and side-channel attacks have repeatedly compromised their guarantees. The cryptographic approaches avoid this trust assumption at the cost of computational overhead.



## Key Takeaways

1. **Programmable cryptography is the broader dream.** ZK proofs answer "can I prove without revealing?" but parallel questions led to MPC (joint computation), FHE (computing on encrypted data), and program obfuscation (hiding implementation). Each represents a different philosophy about who computes, who learns, and what trust means.

2. **ZK succeeded first because of structural advantages.** The prover works in the clear, paying the cryptographic cost only *after* computation. FHE pays the cost on *every operation*. This asymmetry, combined with algebraic serendipity (polynomials fit FFTs, pairings, and elliptic curves) and blockchain funding, explains why ZK reached practicality first.

3. **FHE is real but slow.** Gentry's 2009 breakthrough proved fully homomorphic encryption possible. Bootstrapping refreshes noisy ciphertexts by homomorphically evaluating decryption. Current schemes run ~1000× slower than native computation. Practical for narrow applications; general computation remains out of reach.

4. **Program obfuscation hit a wall.** Virtual black-box obfuscation is impossible in general (Barak et al. 2001). The weaker notion, indistinguishability obfuscation (iO), exists theoretically but requires exponential computation. iO would be cryptography's "master tool," but practicality is not on the horizon.

5. **The primitives are converging.** zkFHE combines encrypted computation with verifiable correctness. MPC and ZK compose for honest-protocol proofs. Folding blurs the line between proving and computing. The boundaries between approaches are dissolving as researchers combine techniques.

6. **Trust models differ.** ZK: prover sees data, verifier learns only validity. MPC: parties jointly compute, no one sees others' inputs. FHE: server computes blindly, client holds decryption key. Choose based on who you trust and what you're hiding from whom.


## Summary: The Landscape at a Glance

| Approach | Who computes? | Who learns result? | Trust assumption | Status |
|----------|---------------|-------------------|------------------|--------|
| ZK | Prover | Verifier | Soundness of proofs | Practical |
| MPC | All parties jointly | All parties | Threshold honesty | Practical |
| FHE | Untrusted server | Client only | Encryption security | Emerging (~1000× overhead) |
| iO | Anyone | Anyone | Obfuscation security | Theoretical only |



## Looking Forward

This book taught you zero-knowledge proofs: the first branch of programmable cryptography to reach satisfying practicality. But ZK is not the whole story. It's the *first* story to reach an ending.

The dream that animated GMR, Gentry, and generations of cryptographers was more ambitious: computation on secrets as natural as computation in the clear. We're not there yet. FHE is still a thousand times too slow for most applications. iO remains a theoretical curiosity. The locked room stays partly locked.

But the trajectory is clear. ZK proofs were impractical in 2010, expensive in 2016, and routine in 2024. FHE follows a similar curve, perhaps a decade behind. The tools are converging; the applications are multiplying.

You've learned the part of the story that's already been written. The rest is still being discovered.

# Chapter 27: ZK in the cryptographic landscape

In 1943, a resistance fighter in occupied France needs to send a message to London. She writes it in cipher, slips it into a dead letter drop, and waits. A courier retrieves it, carries it across the Channel, and a cryptographer at Bletchley Park decrypts it. The message travels safely because no one who intercepts it can read it.

For the next fifty years, this was cryptography's entire mission: move secrets from A to B without anyone in between learning them. Telegraph, radio, internet. The medium changed; the problem stayed the same. Encrypt, transmit, decrypt. A message sealed or opened, a secret stored or revealed.

Then computers stopped being message carriers and became *thinkers*. The question changed. It was no longer enough to ask "can I send a secret?" Now we needed to ask: "can I *use* a secret without exposing it?"

This is the dream of **programmable cryptography**: secure *computation* on secrets. The dream took many forms. "Can I prove I know a secret without revealing it?" led to zero-knowledge proofs. "Can we compute together while keeping our inputs private?" led to secure multiparty computation. "Can I encrypt data so someone else can compute on it?" led to fully homomorphic encryption. "Can I publish a program that reveals nothing about how it works?" led to program obfuscation.

These are different philosophies about who computes, who learns, and what trust means. For decades they developed in parallel, each with its own community, its own breakthroughs, its own brick walls.

This book taught you the path that arrived first: zero-knowledge proofs. ZK reached general practicality before the others. MPC is deployed for high-value operations like threshold signing (Chapter 25). FHE works for narrow applications and is improving rapidly. Program obfuscation remains theoretical. Understanding *why* ZK progressed fastest illuminates both the landscape and the road ahead.


## Why ZK arrived first

The most important asymmetry is structural: the prover works in the clear. In ZK, the expensive cryptographic operations happen *after* the computation, not during it. The prover computes at native speed, then invests work in generating a proof. In fully homomorphic encryption (developed in the next section), every arithmetic operation carries cryptographic overhead because the data stays encrypted throughout. In program obfuscation, the program itself becomes the cryptographic object. This difference compounds across millions of operations.

ZK also benefited from mathematical serendipity. SNARKs exploit polynomial arithmetic over finite fields, exactly what elliptic curves, pairings, and FFTs handle efficiently. The tools developed for other purposes (error-correcting codes, number theory, algebraic geometry) turned out to fit the ZK problem well. FHE and obfuscation involve noise management and lattice arithmetic that fight against efficient computation rather than harmonizing with it.

The theory developed steadily over thirty years. The path from GMR (1985) to PCPs (1992) to IOPs (2016) to practical SNARKs (2016-2020) was long but each step built on the previous. The sum-check protocol from 1991 became the heart of modern systems. Polynomial commitments from 2010 enabled succinctness. The pieces accumulated until they clicked together.

Finally, blockchain created urgent demand. Scalability, privacy, trustless verification: billions of dollars flowed into ZK research. The ecosystem grew rapidly. FHE has applications but no comparable catalyst. Program obfuscation has no applications that couldn't wait until it works, a chicken-and-egg problem that starves it of engineering investment.

MPC also reached practicality, though with different trade-offs. Chapter 25 covers MPC in depth. This chapter focuses on the two dreams that remain partially unfulfilled: computing on encrypted data, and making programs incomprehensible.



## Computing on ciphertexts

In 1978, Rivest, Adleman, and Dertouzos asked whether an encryption scheme could support computation on ciphertexts. They called it a "privacy homomorphism": encrypt data, compute on the ciphertexts, decrypt and get the correct result, all without the server ever seeing the plaintext. The question was whether this could work for *arbitrary* computations, not just a narrow class.

For thirty years, the answer was partial. RSA turned out to be multiplicatively homomorphic (the product of ciphertexts decrypts to the product of plaintexts) but couldn't do addition. Paillier (1999) achieved additive homomorphism but couldn't do multiplication. ElGamal was multiplicative too. Every scheme could do one operation or the other, never both. Since addition and multiplication together are enough to compute any function, the gap between "partially homomorphic" and "fully homomorphic" was the gap between a curiosity and a revolution.

Craig Gentry's 2009 thesis closed that gap.

### Learning with errors

Modern FHE rests on the **Learning With Errors (LWE)** problem, which admits two readings. Algebraically, LWE says that solving a system of linear equations becomes intractable when each equation carries a small random error. This is the view that matters for building encryption: the noise is what makes ciphertexts indistinguishable.

Geometrically, LWE is a lattice problem. A *lattice* is a regular grid of points in high-dimensional space (integer combinations of basis vectors), and recovering the secret from noisy equations amounts to finding a close lattice point through the noise. This is the view that matters for *analyzing* security: hardness reductions from worst-case lattice problems (finding shortest vectors, closest vectors) are what give us confidence that LWE resists both classical and quantum attacks. No quantum algorithm is known to solve these lattice problems efficiently.

LWE and its structured variants (Ring-LWE, Module-LWE) underlie the NIST post-quantum encryption standard ML-KEM. As Chapter 26 notes, recent constructions like Hachi are bringing lattice-based polynomial commitments into the ZK landscape as well.

LWE enables encryption by encoding a message bit as a large shift in a noisy inner product. The secret key is a vector $\vec{s}$. To encrypt a bit $m \in \{0, 1\}$, pick a random vector $\vec{a}$, pick small noise $e$, and compute $b = \langle \vec{a}, \vec{s} \rangle + e + m \cdot \lfloor q/2 \rfloor$. The ciphertext is $(\vec{a}, b)$. The bit $m$ creates a large gap (adding $q/2$ or nothing); the noise obscures the exact value but not which half of the range we're in. Decryption subtracts the mask $\langle \vec{a}, \vec{s} \rangle$ and rounds. An attacker who doesn't know $\vec{s}$ faces the LWE problem.

### The noise problem

The difficulty of FHE lies in how operations affect the error. A concrete example makes this vivid.

Say our modulus is $q = 1000$. We encode bit $0$ as values near $0$, bit $1$ as values near $500$ (that's $q/2$). Fresh ciphertexts have noise around $\pm 10$. Decryption asks: "Is this value closer to $0$ or to $500$?"

Encrypt two bits, both equal to $1$. Ciphertext $c_1$ decrypts to $500 + 7 = 507$ (the $7$ is noise). Ciphertext $c_2$ decrypts to $500 - 4 = 496$. Both decrypt correctly since $507$ and $496$ are closer to $500$ than to $0$.

Addition is safe. The noises add: $(507 + 496) \mod 1000 = 3$. Noise is $7 + (-4) = 3$, still small. But multiplication is where trouble starts. Multiplying ciphertexts multiplies the noises: after one multiplication, noise $\approx 28$; after two, $\approx 280$; after three, $\approx 2800$. The safety margin is only $250$ (values must stay closer to their target than to the alternative). After a few multiplications, noise overwhelms signal and decryption returns garbage.

This is the **noise budget**: every FHE scheme has a limit on how much computation can be performed before the ciphertext becomes useless. Addition is cheap (noise grows linearly). Multiplication is expensive (noise grows multiplicatively, becoming exponential in circuit depth).

### Bootstrapping

The noise budget imposes a depth limit on computation. Gentry's breakthrough was **bootstrapping**: a way to reset the noise without ever decrypting in the clear.

Return to the example. The ciphertext encoding bit $1$ has accumulated noise of $280$. One more multiplication and decryption fails. The noise must come down while the message stays intact, and the plaintext must never be exposed.

The naive fix would be to decrypt the ciphertext and re-encrypt it fresh. But that exposes the plaintext, defeating the purpose. Bootstrapping achieves the same effect without ever leaving ciphertext space, by exploiting the fact that decryption is itself a computation (subtract the mask, round, output the bit). If we run this computation *homomorphically* on an encrypted copy of the secret key, the rounding step absorbs the old noise internally and the output emerges as a fresh ciphertext.

Concretely, publish an encryption of the secret key, $\text{Enc}(\vec{s})$, as a public parameter. Given the noisy ciphertext $c$, treat it as public data (it is already encrypted) and evaluate the decryption circuit homomorphically with $\text{Enc}(\vec{s})$ as the key input. Inside the homomorphic evaluation, the rounding step absorbs the old noise ($780$ rounds to $500$, giving $1$ correctly). Since the key was encrypted, the output is also encrypted: $\text{Enc}(1)$ with fresh noise of perhaps $50$ instead of the accumulated $280$. The plaintext was never exposed.

This only works if the decryption circuit is shallow enough that running it homomorphically doesn't exhaust the noise budget it is trying to restore. Gentry's construction designs decryption to be "bootstrappable," but the cost is significant; early implementations took minutes per bootstrap. The payoff is that there is no longer a depth limit. Compute until noise grows dangerous, bootstrap to refresh, continue. Any computation becomes possible, one refresh at a time.

### Current state

The fifteen years since Gentry's thesis have produced both real improvements and real deployments. FHE is no longer a research curiosity. Apple ships it on a billion phones (Live Caller ID Lookup, iOS 18) for private database queries. Microsoft uses it in Edge's Password Monitor for private set intersection against breach databases. Google's Private Join and Compute handles encrypted advertising attribution. CryptoLab partners with Samsung for encrypted health analytics on Galaxy devices. These deployments share a pattern: the computations are shallow (one or two multiplication depths), the data is structured, and the workloads are embarrassingly parallel.

Three scheme families cover different workload shapes. **TFHE** optimizes for Boolean circuits through "programmable bootstrapping," where the bootstrap itself computes a function. On modern CPUs, gate evaluation takes roughly 10ms; on GPUs (Zama's TFHE-rs on H100 hardware), bootstrapping has dropped below 1ms. **BGV/BFV** optimize for integer arithmetic by batching thousands of values into a single ciphertext with SIMD-style parallelism. **CKKS** accepts approximate arithmetic on fixed-point real numbers, trading small errors for efficiency in workloads like ML inference where exact precision isn't needed.

For the shallow, parallel workloads that current deployments target, FHE overhead is manageable. For general computation the overhead remains $10^3$ to $10^4$ times native, depending on the workload and scheme. Early implementations were a million times slower; the trajectory is encouraging. Hardware acceleration through custom FPGAs and ASICs (programs like DARPA's DPRIVE) could deliver another 100-1000× improvement. But the overhead may have irreducible components: noise management and ciphertext expansion impose costs that shrink with better engineering but may never vanish entirely.

Libraries like Microsoft SEAL, OpenFHE, and Zama's Concrete have made FHE accessible to developers. NIST has begun a standardization process for FHE through its Multi-Party Threshold Schemes call, signaling institutional readiness for wider adoption.



## Program obfuscation

Program obfuscation is the most ambitious dream of programmable cryptography. Not just computing on secrets, but making *programs themselves* into secrets.

### Virtual black-box obfuscation

The strongest notion is **virtual black-box (VBB) obfuscation**: transform a program's source code into a form that still runs correctly but reveals nothing about *how* it works. A password checker would still accept the correct password and reject all others, but someone reading the obfuscated code could not figure out what the secret password is.

Formally, an obfuscator $\mathcal{O}$ satisfies VBB if for any program $P$:

1. **Functionality**: $\mathcal{O}(P)(x) = P(x)$ for all inputs $x$
2. **Black-box security**: Anything efficiently computable from $\mathcal{O}(P)$ is also efficiently computable given only oracle access to $P$

Having the obfuscated code gives you no advantage over having a locked box that runs the program. The code is in front of you, but it's as opaque as a black box.

### The impossibility result

In 2001, Barak, Goldreich, Impagliazzo, Rudich, Sahai, Vadhan, and Yang proved that **VBB obfuscation is impossible** in general. Some programs are inherently "unobfuscatable." The proof constructs a pair of programs $P_0$ and $P_1$ that have identical input-output behavior on almost all inputs but can be distinguished by examining their code. The construction exploits self-reference: program $P_b$ behaves normally on most inputs, but if given *its own code* as input, it outputs $b$.

$$P_b(\mathcal{O}(P_b)) = b$$

Any obfuscation of $P_b$ must output $b$ when fed itself, revealing which program it came from. No amount of code transformation can hide this.

### Indistinguishability obfuscation

A weaker notion survived. **Indistinguishability obfuscation (iO)** guarantees only that if programs $P_0$ and $P_1$ compute the *same function* (identical outputs on all inputs), then their obfuscations are computationally indistinguishable:

$$\mathcal{O}(P_0) \approx_c \mathcal{O}(P_1)$$

This seems weak. You're only hiding implementation details, not the function itself. The power comes from what you can hide inside equivalent programs.

Consider two programs that both output "Hello, World!":

```
Program A: print("Hello, World!")

Program B:
    secret_key = 0x7a3f...  # 256-bit key, embedded in the code
    if sha256(input) == target:
        return decrypt(secret_key, ciphertext)
    print("Hello, World!")
```

Program B has a secret key hidden inside it. On every normal input, it behaves identically to Program A. But if you find an input whose hash matches `target`, it decrypts and returns a hidden message. These programs compute the same function (assuming finding the hash preimage is computationally infeasible), so by iO their obfuscations are indistinguishable. The secret key is *in the code*, but no one can extract it. The obfuscated program is indistinguishable from an obfuscation of the trivial Program A, which contains no secrets at all.

With efficient iO, you could build almost any cryptographic primitive. The most striking is *witness encryption*: encrypt a message so that only someone who knows a solution to a puzzle can decrypt it. Not a specific person with a specific key, but *anyone* who can solve the puzzle.

$$\text{WE.Enc}(\text{statement}, m) \to c \qquad \text{WE.Dec}(c, \text{witness}) \to m$$

Witness encryption has a precise duality with zero-knowledge. A ZK proof says "I know a witness for statement $x$" without revealing it. Witness encryption says "only someone who knows a witness can read this" without specifying who. Both are parameterized by an NP statement. ZK proves *about* the statement; WE encrypts *to* it.

Beyond witness encryption, iO enables *functional encryption* (keys that compute $f(m)$ from encrypted $m$ without learning $m$ itself), *deniable encryption* (produce fake randomness that makes a ciphertext look like it encrypts a different message), and many other primitives. iO acts as a universal building block: given iO, you can construct almost any cryptographic tool. The constraint is not imagination but efficiency.

### Construction and costs

In 2021, Jain, Lin, and Sahai constructed iO from well-founded assumptions (variants of LWE and related problems). The theoretical question was settled: iO exists. The construction uses branching programs as the computational model, encoding state transitions in matrix operations obscured by algebraic noise.

For years, all known constructions were exponentially slow: obfuscating a circuit of size $n$ required operations scaling as $2^{O(n)}$, making anything beyond toy circuits infeasible. That began to change in 2025 with **Diamond iO** (eprint 2025/236), a lattice-based construction that replaces the costly recursive functional-encryption bootstrapping of earlier schemes with direct matrix operations. Diamond iO is simple enough to implement, and the Machina iO team produced the first end-to-end benchmarks: obfuscating the simplest possible circuit (depth 0, a single input bit, no multiplications) already takes about 16 minutes and produces a 6.3 GB program; at depth 10, obfuscation takes two hours and produces 20 GB. Evaluation of the obfuscated program takes minutes. These numbers are far from practical for general use, but they are *finite* rather than cosmological. The same could be said of early FHE implementations circa 2011.

One way to sidestep the overhead is to obfuscate as little as possible. The Diamond iO team suggests obfuscating only a small constant-depth circuit whose job is to verify a ZK proof and decrypt a ciphertext, then letting FHE handle the actual application logic. The obfuscated piece stays tiny; iO contributes only what it uniquely provides (hiding the decryption key). The trajectory from "impossible to implement" to "first benchmarks" took four years. How far the next four take us is an open question.

A separate line of work has extended obfuscation to quantum programs. At FOCS 2025, Er-Cheng Tang received the Machtey Award for the first quantum state obfuscation scheme for unitary quantum programs, opening a direction that classical iO cannot address.



## Convergence

The boundaries between ZK, MPC, FHE, and obfuscation are dissolving as researchers combine techniques.

The most natural combination is zkFHE. A server computes on encrypted data using FHE, but how does the client know the server computed correctly? The server generates a ZK proof of correct FHE evaluation. The client verifies without decrypting intermediate results, getting both privacy and verifiability in one protocol.

MPC and ZK compose similarly. Multiple parties compute together (Chapter 25) while ZK proves they followed the protocol honestly without revealing individual contributions. Threshold signatures, distributed key management, collaborative computation with verification: the primitives compose naturally.

Even the line between proving and computing is blurring. The folding and accumulation techniques from Chapter 23 let incrementally verifiable computation fold claims together, deferring expensive proof work. ZK handles verification without revelation. MPC enables joint computation. FHE supports outsourced computation on secrets. Each occupies a niche; together they cover territory no single approach could reach.

Trusted Execution Environments (TEEs) like Intel SGX and ARM TrustZone offer a non-cryptographic alternative: hardware isolation at near-native speed, but requiring trust in the hardware manufacturer. Side-channel attacks have repeatedly compromised their guarantees. The cryptographic approaches avoid this trust assumption at the cost of computational overhead.


## The landscape at a glance

| Approach | Who computes? | Who learns result? | Trust assumption | Status |
|----------|---------------|-------------------|------------------|--------|
| ZK | Prover | Verifier | Soundness of proofs | Practical |
| MPC | All parties jointly | All parties | Threshold honesty | Practical (threshold signing, custody) |
| FHE | Untrusted server | Client only | Encryption security | Deployed for narrow workloads (~1000× general overhead) |
| iO | Anyone | Anyone | Obfuscation security | First implementations (far from practical) |


## Key takeaways

1. **ZK's structural advantage is that the prover works in the clear.** The cryptographic cost comes *after* computation, not during it. FHE pays per operation; iO pays per program gate. This asymmetry, combined with algebraic serendipity and blockchain funding, explains why ZK reached general practicality first.

2. **FHE is deployed for shallow, parallel workloads.** Apple, Microsoft, and Google ship FHE in production. Bootstrapping enables arbitrary-depth computation by homomorphically evaluating decryption. The overhead (~1000× for general computation, sub-millisecond per gate on GPU for TFHE) continues to shrink but may have irreducible components.

3. **iO moved from theory to first implementation.** VBB obfuscation is impossible (Barak et al. 2001), but iO exists (Jain-Lin-Sahai 2021). Diamond iO (2025) produced the first benchmarks. The programs are gigabytes and take hours to obfuscate, but the gap between "impossible" and "merely impractical" is where progress begins.

4. **Trust models determine tool selection.** ZK: the prover sees data, the verifier learns only validity. MPC: parties jointly compute, no one sees others' inputs. FHE: the server computes blindly, the client holds the decryption key. The choice depends on who you trust and what you're hiding from whom.

5. **The primitives compose.** zkFHE gives encrypted computation with verifiable correctness. MPC + ZK proves honest protocol execution. iO + FHE lets you obfuscate a tiny verifier and outsource computation. No single approach covers the full landscape; together they do.

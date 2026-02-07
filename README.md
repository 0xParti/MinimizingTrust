<p align="center">
  <img src="images/others/frontLandscape.png" alt="zkBook Cover">
</p>

<h1 align="center">Minimizing Trust, Maximizing Truth</h1>
<p align="center"><em>The Architecture of Verifiable Secrets</em></p>
<p align="center">by <strong>particle</strong></p>

---

## About

A comprehensive guide to Zero-Knowledge Proofs, covering:
- Foundations: polynomials, sum-check protocol, multilinear extensions
- Core protocols: GKR, polynomial commitments, FRI
- SNARK systems: Groth16, PLONK, STARKs
- Zero-knowledge techniques and optimizations
- Advanced topics: recursion, composition, practical considerations

## Read the Book

- **PDF**: [Download zkBook.pdf](zkBook.pdf)
- **Online**: [Read online](https://0xparti.github.io/zkBook/)

## Building from Source

### PDF Version

```bash
cd pandoc
./build.sh
```

Requires: [Pandoc](https://pandoc.org/), [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template), XeLaTeX

### Web Version

```bash
cd web
mdbook serve --open
```

Requires: [mdBook](https://rust-lang.github.io/mdBook/)

## Repository Structure

```
zkBook/
├── images/cover/     # Cover images
├── pandoc/           # PDF compilation source
├── web/              # mdBook web version
└── zkBook.pdf        # Pre-built PDF
```

---

<p align="center">
  <img src="images/others/backLandscape.png" alt="zkBook Back Cover">
</p>

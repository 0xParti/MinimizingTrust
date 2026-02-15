<p align="center">
  <img src="web/src/images/frontLandscape.png" alt="zkBook Cover">
</p>

<h1 align="center">Minimizing Trust</h1>
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

### PDF/EPUB

```bash
cd compile
./build-pdf.sh      # Build PDF
./build-epub.sh     # Build EPUB
```

Requires: [Pandoc](https://pandoc.org/), [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template), [mermaid-filter](https://github.com/raghur/mermaid-filter), XeLaTeX

### Web Version

```bash
cd web
mdbook serve --open
```

Requires: [mdBook](https://rust-lang.github.io/mdBook/)

## Repository Structure

```
zkBook/
├── compile/          # PDF/EPUB build scripts
├── web/src/images/   # All images (shared by web, PDF, EPUB)
├── web/              # mdBook web version
├── zkBook.pdf        # Pre-built PDF
└── zkBook.epub       # Pre-built EPUB
```

---

<p align="center">
  <img src="web/src/images/backLandscape.png" alt="zkBook Back Cover">
</p>

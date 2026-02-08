#!/bin/bash

# Build script for zkBook EPUB
# Concatenates all chapters and compiles with pandoc

cd "$(dirname "$0")"

# Create combined markdown (no LaTeX frontmatter for EPUB)
cat > /tmp/zkBook_epub.md << 'HEADER'
---
title: "Minimizing Trust, Maximizing Truth"
subtitle: "The Architecture of Verifiable Secrets"
author: "particle"
toc: true
toc-depth: 2
---

HEADER

# Append all chapters
for chapter in \
    ../web/src/01-the-trust-problem.md \
    ../web/src/02-the-alchemical-power-of-polynomials.md \
    ../web/src/03-the-sum-check-protocol.md \
    ../web/src/04-multilinear-extensions.md \
    ../web/src/05-univariate-polynomials-and-finite-fields.md \
    ../web/src/06-commitment-schemes.md \
    ../web/src/07-the-gkr-protocol.md \
    ../web/src/08-from-circuits-to-polynomials.md \
    ../web/src/09-polynomial-commitment-schemes.md \
    ../web/src/10-hash-based-commitments-and-fri.md \
    ../web/src/11-the-snark-recipe.md \
    ../web/src/12-groth16.md \
    ../web/src/13-plonk.md \
    ../web/src/14-lookup-arguments.md \
    ../web/src/15-starks.md \
    ../web/src/16-sigma-protocols.md \
    ../web/src/17-the-zero-knowledge-property.md \
    ../web/src/18-making-proofs-zero-knowledge.md \
    ../web/src/19-fast-sum-check-proving.md \
    ../web/src/20-minimizing-commitment-costs.md \
    ../web/src/21-the-two-classes-of-piops.md \
    ../web/src/22-composition-and-recursion.md \
    ../web/src/23-choosing-a-snark.md \
    ../web/src/24-mpc-and-zk-parallel-paths.md \
    ../web/src/25-frontiers-and-open-problems.md \
    ../web/src/26-zk-in-the-cryptographic-landscape.md \
    ../web/src/appendix-a-cryptographic-primitives.md \
    ../web/src/appendix-b-historical-timeline.md \
    ../web/src/appendix-c-field-equations-cheat-sheet.md
do
    echo "" >> /tmp/zkBook_epub.md
    # Convert ```mermaid to ```{.mermaid width=600} for EPUB (PNG format, default)
    sed 's/^```mermaid$/```{.mermaid width=600}/' "$chapter" >> /tmp/zkBook_epub.md
    echo "" >> /tmp/zkBook_epub.md
done

# Build EPUB with MathML for proper math rendering
MERMAID_FILTER_WIDTH=600 pandoc /tmp/zkBook_epub.md \
    --epub-cover-image=../images/cover/zkBookCover.png \
    --mathml \
    -F mermaid-filter \
    -o ../zkBook.epub

echo "Built zkBook.epub"

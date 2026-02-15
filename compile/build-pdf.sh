#!/bin/bash

# Build script for zkBook PDF
# Concatenates all chapters and compiles with pandoc/eisvogel

cd "$(dirname "$0")"

# Create header with frontmatter
cat > /tmp/zkBook_pdf.md << 'HEADER'
---
titlepage: true
titlepage-background: "../web/src/images/zkBookCover.png"
titlepage-text-color: "FFFFFF00"
titlepage-rule-height: 0
toc: false
toc-depth: 2
link-citations: true
book: true
classoption: openright
header-includes:
  - \usepackage{graphicx}
  - \usepackage{eso-pic}
---

<!-- Page 2: Anverse image (full page like cover) -->
\newpage
\thispagestyle{empty}
\AddToShipoutPictureBG*{\includegraphics[width=\paperwidth,height=\paperheight]{../web/src/images/zkBookAnverse.png}}
\null

<!-- Page 3: Title page -->
\newpage
\thispagestyle{empty}
\begin{center}
\vspace*{3cm}
{\Huge\bfseries Minimizing Trust}\\[1cm]
{\Large\itshape The Architecture of Verifiable Secrets}\\[2cm]
{\large particle}\\[4cm]
\vfill
\end{center}

<!-- Page 4: TOC -->
\newpage
\tableofcontents

<!-- Empty page after TOC -->
\newpage
\thispagestyle{empty}
\mbox{}

HEADER

# Append all chapters
for chapter in \
    ../web/src/01-the-trust-problem.md \
    ../web/src/02-the-power-of-polynomials.md \
    ../web/src/03-the-sum-check-protocol.md \
    ../web/src/04-multilinear-extensions.md \
    ../web/src/05-univariate-polynomials-and-finite-fields.md \
    ../web/src/06-commitment-schemes.md \
    ../web/src/07-the-gkr-protocol.md \
    ../web/src/08-from-circuits-to-polynomials.md \
    ../web/src/09-polynomial-commitment-schemes.md \
    ../web/src/10-hash-based-poly-commitments-and-fri.md \
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
    ../web/src/appendix-c-field-equations-cheat-sheet.md \
    ../web/src/appendix-d-advanced-polynomial-commitment-schemes.md
do
    echo "" >> /tmp/zkBook_pdf.md
    # Convert ```mermaid to ```{.mermaid format=pdf width=600} for proper PDF sizing
    sed 's/^```mermaid$/```{.mermaid format=pdf width=600}/' "$chapter" >> /tmp/zkBook_pdf.md
    echo "" >> /tmp/zkBook_pdf.md
done

# Build PDF
MERMAID_FILTER_WIDTH=600 pandoc /tmp/zkBook_pdf.md \
    --template=eisvogel \
    -F mermaid-filter \
    -o ../zkBook.pdf \
    --pdf-engine=xelatex

echo "Built zkBook.pdf"

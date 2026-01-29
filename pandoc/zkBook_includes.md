---
titlepage: true
titlepage-background: "../images/cover/zkBookCover.png"
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
\AddToShipoutPictureBG*{\includegraphics[width=\paperwidth,height=\paperheight]{../images/cover/zkBookAnverse.png}}
\null

<!-- Page 3: Title page -->
\newpage
\thispagestyle{empty}
\begin{center}
\vspace*{3cm}
{\Huge\bfseries Minimizing Trust, Maximizing Truth}\\[1cm]
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

!include ../web/src/01-the-trust-problem.md

!include ../web/src/02-the-alchemical-power-of-polynomials.md

!include ../web/src/03-the-sum-check-protocol.md

!include ../web/src/04-multilinear-extensions.md

!include ../web/src/05-univariate-polynomials-and-finite-fields.md

!include ../web/src/06-commitment-schemes.md

!include ../web/src/07-the-gkr-protocol.md

!include ../web/src/08-from-circuits-to-polynomials.md

!include ../web/src/09-polynomial-commitment-schemes.md

!include ../web/src/10-hash-based-commitments-and-fri.md

!include ../web/src/11-the-snark-recipe.md

!include ../web/src/12-groth16.md

!include ../web/src/13-plonk.md

!include ../web/src/14-lookup-arguments.md

!include ../web/src/15-starks.md

!include ../web/src/16-sigma-protocols.md

!include ../web/src/17-the-zero-knowledge-property.md

!include ../web/src/18-making-proofs-zero-knowledge.md

!include ../web/src/19-fast-sum-check-proving.md

!include ../web/src/20-minimizing-commitment-costs.md

!include ../web/src/21-the-two-classes-of-piops.md

!include ../web/src/22-composition-and-recursion.md

!include ../web/src/23-choosing-a-snark.md

!include ../web/src/24-mpc-and-zk-parallel-paths.md

!include ../web/src/25-frontiers-and-open-problems.md

!include ../web/src/26-zk-in-the-cryptographic-landscape.md

!include ../web/src/appendix-a-cryptographic-primitives.md

!include ../web/src/appendix-b-historical-timeline.md

!include ../web/src/appendix-c-field-equations-cheat-sheet.md

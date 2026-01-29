# Compiling the Book

From this directory (`pandoc/`), run:

```bash
./build.sh
```

This script automatically:
- Concatenates all chapters from `web/src/`
- Filters out mermaid diagrams (not supported in PDF)
- Compiles with pandoc/eisvogel

### Requirements

- [Pandoc](https://pandoc.org/)
- [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template)
- XeLaTeX (via TeX Live or MacTeX)

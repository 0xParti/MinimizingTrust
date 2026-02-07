# Compiling the Book

From this directory (`pandoc/`), run:

```bash
./build.sh
```

This script automatically:
- Concatenates all chapters from `web/src/`
- Converts mermaid diagrams for PDF rendering
- Compiles with pandoc/eisvogel

### Requirements

- [Pandoc](https://pandoc.org/)
- [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template)
- [mermaid-filter](https://github.com/raghur/mermaid-filter) (`npm install -g mermaid-filter`)
- XeLaTeX (via TeX Live or MacTeX)

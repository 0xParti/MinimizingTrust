# Compiling the Book

From this directory (`compile/`), run:

```bash
./build-pdf.sh      # Build PDF
./build-epub.sh     # Build EPUB
```

These scripts automatically:
- Concatenate all chapters from `web/src/`
- Convert mermaid diagrams for proper rendering
- Compile with pandoc

### Requirements

- [Pandoc](https://pandoc.org/)
- [Eisvogel template](https://github.com/Wandmalfarbe/pandoc-latex-template) (PDF only)
- [mermaid-filter](https://github.com/raghur/mermaid-filter) (`npm install -g mermaid-filter`)
- XeLaTeX (via TeX Live or MacTeX) (PDF only)
- [librsvg](https://wiki.gnome.org/Projects/LibRsvg) (`brew install librsvg` on macOS)

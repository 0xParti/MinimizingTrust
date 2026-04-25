#!/bin/bash

# Build both PDF and EPUB
cd "$(dirname "$0")"

./build-pdf.sh
./build-epub.sh

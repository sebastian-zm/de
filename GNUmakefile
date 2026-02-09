# GNUmakefile for converting markdown files to epub and pdf using pandock
# pandock = podman run --rm -v "$(pwd):/data" pandoc/latex

PANDOCK = podman run --rm -v "$$(pwd):/data:Z" pandoc/latex

SRC_DIR = src
OUT_DIR = out

# Find all markdown files in src
MD_FILES = $(wildcard $(SRC_DIR)/*.md)

# Generate target filenames
EPUB_FILES = $(patsubst $(SRC_DIR)/%.md,$(OUT_DIR)/%.epub,$(MD_FILES))
PDF_FILES = $(patsubst $(SRC_DIR)/%.md,$(OUT_DIR)/%.pdf,$(MD_FILES))

# Default target
.PHONY: all
all: epub pdf

# Target to build all epub files
.PHONY: epub
epub: $(EPUB_FILES)

# Target to build all pdf files
.PHONY: pdf
pdf: $(PDF_FILES)

# Rule to convert .md to .epub
$(OUT_DIR)/%.epub: $(SRC_DIR)/%.md
	@echo "Converting $< to $@..."
	$(PANDOCK) $< -o $@

# Rule to convert .md to .pdf
$(OUT_DIR)/%.pdf: $(SRC_DIR)/%.md
	@echo "Converting $< to $@..."
	$(PANDOCK) $< -o $@

# Clean targets
.PHONY: clean
clean:
	rm -f $(EPUB_FILES) $(PDF_FILES)

.PHONY: clean-epub
clean-epub:
	rm -f $(EPUB_FILES)

.PHONY: clean-pdf
clean-pdf:
	rm -f $(PDF_FILES)

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make epub        - Convert all .md files to .epub"
	@echo "  make pdf         - Convert all .md files to .pdf"
	@echo "  make all         - Convert all .md files to both .epub and .pdf"
	@echo "  make clean       - Remove all generated .epub and .pdf files"
	@echo "  make clean-epub  - Remove all generated .epub files"
	@echo "  make clean-pdf   - Remove all generated .pdf files"
	@echo ""
	@echo "Markdown files found:"
	@echo "  $(MD_FILES)"

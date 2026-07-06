# Skill Download Requirements

This note lists what must be installed or downloaded to use each repo-local skill under `.agents/skills`.
Skills with no external downloads still appear here so individual skills can be selected without guessing.

## atomic-commit

Required:
- Git CLI.

Optional:
- None.

## docx

Required for the core workflows described in `docx/SKILL.md`:
- Pandoc, for extracting `.docx` content to Markdown.
- Node.js and npm.
- npm package `docx`, installed globally with `npm install -g docx`, for creating new `.docx` files.
- LibreOffice, for `.doc` to `.docx` conversion and document-to-PDF rendering.
- Poppler, especially `pdftoppm`, for converting rendered PDFs to page images.

Required for editing, validation, comments, and tracked-change workflows:
- Shared office helper scripts, including `scripts/office/unpack.py`, `scripts/office/pack.py`, `scripts/office/validate.py`, `scripts/office/soffice.py`, `scripts/accept_changes.py`, and `scripts/comment.py`. These are referenced by the skill, but this repo's `docx` skill folder does not currently include a `scripts/` directory.

Optional:
- None beyond the workflow-specific helpers above.

## feature-planner

Required:
- None beyond normal file read/write access.

Optional:
- Git CLI, useful when repository state informs the plan.
- Ripgrep (`rg`), useful for fast repository search.

## model-test-pipeline

Required:
- Repository-specific model dependencies and test runners discovered during preflight.
- Sub-agent capability, because the workflow requires three parallel research sub-agents.

Optional, depending on detected econometric stack:
- R and relevant R packages, for TRAMO-SEATS or R-based checks.
- CmdStan or CmdStanPy tooling, for Stan-based Bayesian models.
- Python scientific stack commonly used by model repos, such as `numpy`, `pandas`, `statsmodels`, `scipy`, `scikit-learn`, or `pytest`, only when the target repository requires them.

## pdf

Required for common PDF workflows:
- Python package `pypdf`, for merge, split, rotate, watermark, encryption, and fillable forms.
- Python package `pdfplumber`, for text and table extraction.
- Python package `reportlab`, for creating PDFs.
- Python package `pandas`, when exporting extracted tables to spreadsheet-friendly outputs.
- Python package `pdf2image`, for PDF-to-image conversion used by form analysis and output verification.
- Poppler tools, especially `pdftotext`, `pdfimages`, and `pdftoppm`.
- `qpdf`, for command-line PDF manipulation, repair, splitting, encryption, and decryption.

Optional:
- Python package `pypdfium2`, for fast PDF rendering and image generation.
- Python package `Pillow`, used by validation-image helper scripts.
- Python package `pytesseract`, plus the Tesseract OCR engine, for scanned-PDF OCR.
- JavaScript package `pdf-lib`, for advanced PDF creation, editing, and form workflows.
- `pdftk`, only if you want the alternate CLI workflows documented by the skill.
- ImageMagick, for zoom crops during non-fillable or hybrid PDF form placement workflows.

## plan-executor

Required:
- Whatever dependencies are named by the implementation plan being executed.

Optional:
- Git CLI, useful for inspecting changed files and diffs.
- Project-specific test, lint, build, and runtime tools.

## plan-closeout

Required:
- Git CLI, for commit, status, diff, and recent-history discovery.

Optional:
- Ripgrep (`rg`), preferred for documentation discovery.
- Project-specific validation tools needed to confirm the completed plan.

## pptx

Required for the core workflows described in `pptx/SKILL.md`:
- Python package `markitdown[pptx]`, for extracting presentation text.
- Python package `Pillow`, for thumbnail grids.
- Python package `defusedxml`, used by bundled PPTX XML helper scripts.
- Python package `lxml`, used by bundled PPTX/Office XML validators.
- Node.js and npm.
- npm package `pptxgenjs`, installed globally with `npm install -g pptxgenjs`, for creating decks from scratch.
- LibreOffice, for rendering `.pptx` files to PDF for QA.
- Poppler, especially `pdftoppm`, for converting presentation PDFs to slide images.

Optional:
- npm packages `react-icons`, `react`, `react-dom`, and `sharp`, if using the icon/image workflow documented in `pptx/pptxgenjs.md`.

## prd-writer

Required:
- None beyond normal file read/write access.

Optional:
- Git CLI and ripgrep (`rg`), useful when deriving requirements from repository context.

## project-bootstrap

Required:
- `uv`, for dependency installation and Python command execution.
- Docker with Docker Compose, for starting the database service.
- Project dependencies resolved by `uv sync`.
- Alembic, installed through the project environment, for migrations.
- Uvicorn, installed through the project environment, for running the app.
- `curl`, for health endpoint checks.

Optional:
- None.

## repo-primer

Required:
- None beyond normal file read access.

Optional:
- Ripgrep (`rg`), preferred for fast file discovery.
- Git CLI, for branch, status, and recent commit context.

## repo-docs-bootstrap

Required:
- None beyond normal file read/write access.

Optional:
- Ripgrep (`rg`), preferred for documentation and source discovery.
- Git CLI, useful for recent-history and current-state context.

## rules-template-author

Required:
- None beyond normal file read/write access.

Optional:
- Ripgrep (`rg`) and Git CLI, useful for repository analysis.

## russian-human-rewriter

Required:
- None beyond normal file read/write access.

Optional:
- Sub-agent capability if the user requests a second pass or independent style review.

## speech-human-writing

Required:
- None.

Optional:
- None.

## speech-humanizer

Required:
- None.

Optional:
- None.

## statquest-ultimate

Required:
- None.

Optional:
- None. The bundled reference file `statquest-ultimate/references/topic-coverage-map.md` is local and does not need downloading.

## subagent-verify

Required:
- Sub-agent capability, because the skill is explicitly an independent-review workflow.

Optional:
- Git CLI, for changed-file and diff discovery.
- Project-specific test, lint, build, and artifact validation tools needed for the work being reviewed.

## Suggested Partial Installs

For only document work:
- `docx`: install Pandoc, LibreOffice, Poppler, Node.js/npm, and `npm install -g docx`.
- `pptx`: install `pip install "markitdown[pptx]" Pillow defusedxml lxml`, LibreOffice, Poppler, Node.js/npm, and `npm install -g pptxgenjs`.
- `pdf`: install `pip install pypdf pdfplumber reportlab pandas pdf2image pypdfium2 Pillow`, plus Poppler and `qpdf`.

For only repo workflow skills:
- `repo-primer`, `feature-planner`, `plan-executor`, `prd-writer`, `rules-template-author`, and `atomic-commit`: install Git and ripgrep. Plan execution may still require project-specific dependencies.

For only writing/explanation skills:
- `russian-human-rewriter`, `speech-human-writing`, `speech-humanizer`, and `statquest-ultimate`: no downloads required unless sub-agent review is requested.

For verification/model testing:
- `subagent-verify`: requires sub-agent capability plus the target project's validation tools.
- `model-test-pipeline`: requires sub-agent capability plus the target model repo's runtime stack and optional R/CmdStan tooling when relevant.

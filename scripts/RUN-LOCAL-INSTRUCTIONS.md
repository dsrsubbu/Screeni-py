RUN-LOCAL — Run Screeni-py locally without Docker

Purpose

This document explains the run-local branch helpers and how to run Screeni-py on a developer machine that cannot use Docker.

Branch

- run-local (already created and pushed to origin)

Files added (run-local)

- scripts/setup_run_local.sh — Creates a .venv, attempts to pip install -r requirements.txt; on failure installs a minimal workable set (skips native extensions like TA-Lib and chromadb) and installs dev tools (pytest, flake8).
- scripts/run_local.sh — Starts the Streamlit GUI (--gui) or runs the legacy CLI (--cli). Uses the venv if present.
- Makefile targets: local-setup, local-run-gui, local-run-cli (wrappers around the scripts).
- Supporting files already in the branch: .github/copilot-setup-steps.yml and documentation updates.

Quick start (recommended)

1. Checkout the branch:
   - git checkout run-local

2. Create virtualenv & install dependencies (Python 3.13 recommended):
   - bash scripts/setup_run_local.sh
   - or: make local-setup

3. Activate the venv (optional for run_local script which prepends the venv):
   - source .venv/bin/activate

4. Start the GUI:
   - bash scripts/run_local.sh --gui
   - or: make local-run-gui
   - Streamlit listens on port 8501 by default.

5. Start the CLI:
   - bash scripts/run_local.sh --cli
   - or: make local-run-cli

6. Run tests / lint (after venv is ready):
   - pytest -v
   - flake8 src/ test/

Notes and limitations

- Python version: pyproject.toml targets Python >=3.13. Use 3.13 to match CI where possible. Older Python versions may work but are not guaranteed.
- Native packages: TA-Lib, chromadb, and some TA packages require native binaries/wheels. The setup script falls back to a minimal set if compilation or binary installs fail. See INSTALLATION.md for TA-Lib platform steps.
- The setup script attempts a full pip install; if it fails the script installs a reduced set that supports the core GUI and most screening logic. Manually install missing packages if you need advanced features.
- Config files: the Streamlit app reads src/screenipy.yaml. Helper scripts used for smoke tests may back up/restore this file; the local-run scripts do not overwrite it.
- CI parity: CI uses `uv` to sync dependencies and runs on Python 3.13; follow CI steps if you want closer parity.

Troubleshooting

- streamlit import errors: ensure .venv is activated or PATH contains .venv/bin; run pip install streamlit inside venv.
- TA-Lib errors: install system libraries and use the supported wheel for your platform; consult INSTALLATION.md.
- If tests fail due to missing optional dependencies, install them manually into the venv.

Next steps

- Create a PR from run-local -> main when you are ready to merge local-run support.

If anything here is unclear or you want the scripts to auto-install TA wheels for common OSes, say which OS to prioritize and the assistant will add it.

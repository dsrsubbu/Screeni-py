#!/usr/bin/env bash
set -euo pipefail

VENV_DIR=".venv"
PYTHON=${PYTHON:-python3}
REQ_FILE="requirements.txt"
DEV_PACKAGES="pytest flake8"

echo "Creating virtualenv in $VENV_DIR using $PYTHON"
if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "Error: $PYTHON not found. Install Python 3.13 (recommended) or adjust PYTHON env var."
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv..."
  "$PYTHON" -m venv "$VENV_DIR"
fi

PIP="$VENV_DIR/bin/pip"
PY_BIN="$VENV_DIR/bin/python"

# Upgrade pip and wheel
"$PIP" install --upgrade pip setuptools wheel

echo "Attempting to install all dependencies from $REQ_FILE"
if "$PIP" install -r "$REQ_FILE"; then
  echo "Installed full requirements from $REQ_FILE"
else
  echo "Full install failed. Installing a minimal workable set (skipping native extensions like ta-lib)."
  # Minimal set for running Streamlit UI and core logic (no ta-lib, no chromadb)
  "$PIP" install streamlit pandas numpy requests pyyaml yfinance openpyxl plotly Pillow mplfinance tabulate joblib httpx num2words
  echo "Installed fallback minimal packages. If you need enhanced features (TA-Lib, chromadb), install them manually."
fi

# Install dev tools
"$PIP" install $DEV_PACKAGES

echo "Setup complete. Activate with: source $VENV_DIR/bin/activate"
echo "Run GUI: bash scripts/run_local.sh --gui"
exit 0

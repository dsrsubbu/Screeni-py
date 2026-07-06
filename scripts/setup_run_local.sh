#!/usr/bin/env bash
set -euo pipefail

VENV_DIR=".venv"
PYTHON=${PYTHON:-python3}
REQ_FILE="requirements.txt"
DEV_PACKAGES="pytest flake8"
MINIMAL_PACKAGES="streamlit pandas numpy requests pyyaml yfinance openpyxl plotly Pillow mplfinance tabulate joblib httpx num2words"

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
UV_BIN="$VENV_DIR/bin/uv"

# Upgrade pip and wheel
"$PIP" install --upgrade pip setuptools wheel

# Try to install uv into the venv (preferred — matches CI)
UV_INSTALLED=0
if "$PIP" install --upgrade uv 2>/dev/null; then
  if [ -x "$UV_BIN" ]; then
    UV_INSTALLED=1
    echo "uv installed into virtualenv: $UV_BIN"
  else
    # uv binary not found in venv, but package install succeeded; try to locate uv in venv PATH
    if [ -x "$(dirname "$PIP")/uv" ]; then
      UV_BIN="$(dirname "$PIP")/uv"
      UV_INSTALLED=1
    fi
  fi
fi

# If uv is available in the venv, prefer it and run uv sync --group dev
if [ "$UV_INSTALLED" -eq 1 ] && "$UV_BIN" --version >/dev/null 2>&1; then
  echo "Running: $UV_BIN sync --group dev"
  if "$UV_BIN" sync --group dev; then
    echo "uv sync completed"
    # CI also installs some TA extras explicitly; attempt same (non-fatal)
    "$UV_BIN" pip install ta || true
    "$UV_BIN" pip install --no-deps advanced-ta || true
    "$UV_BIN" pip install --no-deps pandas-ta-remake || true
  else
    echo "uv sync failed — falling back to pip install -r $REQ_FILE"
    if ! "$PIP" install -r "$REQ_FILE"; then
      echo "pip install -r failed. Installing minimal package set."
      "$PIP" install $MINIMAL_PACKAGES
      echo "Installed minimal packages (no native TA binaries)."
    fi
  fi
else
  # uv not available — use pip install as before
  echo "uv not available in venv. Attempting pip install -r $REQ_FILE"
  if "$PIP" install -r "$REQ_FILE"; then
    echo "Installed full requirements from $REQ_FILE"
  else
    echo "Full install failed. Installing a minimal workable set (skipping native extensions like ta-lib)."
    "$PIP" install $MINIMAL_PACKAGES
    echo "Installed fallback minimal packages. If you need enhanced features (TA-Lib, chromadb), install them manually."
  fi
fi

# Install dev tools
"$PIP" install $DEV_PACKAGES

echo "Setup complete. Activate with: source $VENV_DIR/bin/activate"
echo "Run GUI: bash scripts/run_local.sh --gui"
exit 0

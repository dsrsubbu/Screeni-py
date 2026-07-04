#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---gui}"
VENV_DIR=".venv"
PY_BIN="$VENV_DIR/bin/python"
STREAMLIT_BIN="$VENV_DIR/bin/streamlit"

if [ -d "$VENV_DIR" ]; then
  export PATH="$VENV_DIR/bin:$PATH"
fi

case "$MODE" in
  --gui)
    echo "Starting Streamlit GUI on 8501..."
    if command -v streamlit >/dev/null 2>&1; then
      streamlit run src/streamlit_app.py --server.port=8501 --server.address=0.0.0.0
    else
      echo "streamlit not available in PATH. Activate venv or run scripts/setup_run_local.sh"
      exit 1
    fi
    ;;
  --cli)
    if [ -x "$PY_BIN" ]; then
      "$PY_BIN" src/screenipy.py --cli
    else
      python3 src/screenipy.py --cli
    fi
    ;;
  *)
    echo "Usage: $0 [--gui|--cli]"
    exit 2
    ;;
esac

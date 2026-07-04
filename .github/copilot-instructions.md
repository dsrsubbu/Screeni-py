# Copilot instructions — Screeni-py

This file is a concise guide for future Copilot sessions working on Screeni-py. It collects the project's build/test/lint commands, the high-level architecture, and repository-specific conventions (sourced from README.md, CONTRIBUTING.md, pyproject.toml and the CI workflows).

---

## Quick commands (build / run / test / lint)

Environment notes:
- CI uses Python 3.13 (see .github/workflows/workflow-test.yml). CONTRIBUTING.md mentions older guidance (3.9) — prefer the CI configuration for reproducing tests.
- CI uses the `uv` tool (astral-sh/setup-uv) to sync dependencies and run commands. Reproducing CI locally with `uv` yields the closest parity.

Using the Docker image (recommended for quick runs):
- Pull and run published image: `docker run -p 8501:8501 joshipranjal/screeni-py:latest`
- Build and run locally: `make build` then `make interactive-run` or `make run` (Makefile wraps docker usage).

Run the GUI locally (non-Docker):
- From repo root: `./run_screenipy.sh --gui` (this runs Streamlit on port 8501)
- CLI mode: `./run_screenipy.sh --cli`

Install dependencies (two common approaches):
- CI-parity (recommended):
  - Install `uv` locally (used in CI)
  - `uv sync --group dev`
  - The CI also runs a few explicit installs for TA packages:
    - `uv pip install ta`
    - `uv pip install --no-deps advanced-ta`
    - `uv pip install --no-deps pandas-ta-remake`
- Classic pip/venv (works for development):
  - `python -m venv .venv && source .venv/bin/activate`
  - `pip install -r requirements.txt`
  - Install dev tools: `pip install pytest flake8`
  - See INSTALLATION.md for platform-specific TA-Lib instructions (native build/wheels).

Run tests:
- Full test suite (from repo root): `pytest -v` or `cd test && pytest -v`
- CI runs: `cd test && uv run pytest -v`
- Run a single test (example):
  - `pytest test/test_database.py::TestDatabaseInit::test_creates_db_file`
  - You can also target a test function or class: `pytest test/test_llm_config.py::test_provider_openai`

Linting / static checks:
- flake8 is configured via `.flake8` (max line length 127). Run locally:
  - `flake8 src/ test/`
- The CI runs a two-step check (syntax/undefined names + relaxed full run):
  - `uv run flake8 src/ test/ --count --select=E9,F63,F7,F82 --show-source --statistics`
  - `uv run flake8 src/ test/ --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics`

Packaging / build:
- Docker-based packaging used for releases (see Dockerfile & .github/workflows/workflow-build-matrix.yml).
- Optional Python wheel build (repo uses setuptools/pyproject): `python -m build` (install `build` first).

---

## High-level architecture (big picture)

- Purpose: Screeni-py is a GUI-first NSE stock-screener (Streamlit) with a legacy CLI. Primary entrypoints:
  - GUI: `src/streamlit_app.py` (served on port 8501)
  - CLI: `src/screenipy.py` (invoked by `run_screenipy.sh --cli`)

- Core layers:
  - `src/classes/` — core domain logic and utilities (Fetcher, Screener, ScreenipyTA, Database, ConfigManager, etc.). This is where screening algorithms and persistence live.
  - `src/agents/` — agent framework, tool adapters and persona YAMLs (`src/agents/personas/*.yaml`). Agent loader reads persona files to configure AI-driven agents.
  - `src/ui/` — UI components used by the Streamlit app (tabs, charts, etc.). `src/static/` contains JS/CSS assets (TableFilter) and is served by a small internal static server.
  - Persistence: SQLite is used via `classes/Database` (DB file path is configurable). A simple Chroma store is present under `src/chromadb_store/chroma.sqlite3` for vector storage.
  - LLM/AI: LLM configuration is persisted via BrowserConfigStore and `screenipy.yaml`. The app integrates with OpenAI/Anthropic/litellm via configured providers.

- Packaging & distribution:
  - Primary distribution in this repo is via Docker (Dockerfile + Makefile + GitHub build workflow).
  - CI runs tests on Python 3.13 and uses `uv` to manage environment parity.

---

## Key repo conventions and patterns (not obvious from a single file)

- src-as-top-level: code lives under `src/` but is NOT always installed as a package in day-to-day development. Tests modify sys.path to include `src/` (see `test/*` fixtures). When running tests from the repo root, `pytest` will pick up tests that rely on `src` being on PYTHONPATH.

- Persona-driven agents: `src/agents/personas/*.yaml` define AI persona metadata referenced by `agent_loader`. New personas should follow existing YAML fields; tests assume these files exist.

- LLM keys and config handling:
  - Streamlit UI uses `BrowserConfigStore` to persist LLM defaults to browser localStorage and mirrors non-sensitive fields to `screenipy.yaml` when the user opts to remember keys.
  - Environment fallback: `SCREENIPY_API_KEY` is read when the user doesn't remember the key in localStorage.

- Static asset serving:
  - `streamlit_app.py` spawns a small local static file server on port 8000 to serve JS/CSS under `src/static/` for the TableFilter widget. Keep static assets under `src/static/`.

- DB and migration behavior:
  - `classes/Database` handles SQLite storage and contains helper code to migrate old pickle exports (`*.pkl`) into the DB (the tests exercise this behavior).
  - Tests use temporary DB paths (fixtures) — avoid hardcoding production DB paths in tests.

- TA/technical dependencies:
  - TA-Lib and some TA packages require native binaries or special wheels. CI installs some TA packages via `uv pip install` and the repo includes a `.github/dependencies/` directory with packaged artifacts used in workflow contexts. Consult INSTALLATION.md when encountering build errors for TA libraries.

- Flake8 config & style: `.flake8` sets max line length to 127 and excludes `src/static/` and vendor artifacts.

- CI specifics (useful for automated sessions):
  - Workflow: `.github/workflows/workflow-test.yml` — sets up Python 3.13, uses `uv`, runs flake8 and pytest.
  - Docker multi-arch builds are handled in `workflow-build-matrix.yml`.

---

## Where to look next

- README.md — usage, Docker quick-start and videos
- INSTALLATION.md — platform-specific install notes (TA-Lib)
- CONTRIBUTING.md — contribution workflow and expectations (some references are older)
- .github/workflows/* — exact CI commands for lint/test/build

---

If something in this file is out-of-date or you want additional coverage (for example: more granular test-running patterns, packaging steps, or more detail about agent/persona schema), say which area to expand and a Copilot session can add it.

---

Optional: Streamlit MCP test server (added)

- Files added for Copilot-driven smoke tests:
  - `.github/workflows/copilot-setup-steps.yml` — Copilot setup job that installs Python 3.13, `uv`, syncs dependencies and installs Streamlit/TA extras. Copilot cloud agent will run these steps before starting so it can run UI smoke tests in-session.
  - `scripts/start_streamlit_smoke_test.sh` — Helper that overlays a minimal `kite_mcp` config (backs up `src/screenipy.yaml`), starts Streamlit on port 8501 (default), waits for an HTTP response, and writes a PID file. Usage: `bash scripts/start_streamlit_smoke_test.sh` (optional args: PORT MCP_URL).
  - `scripts/stop_streamlit_smoke_test.sh` — Stops the server started by the helper and restores the backed-up config.
  - `screenipy.mcp.local.yaml` — Minimal example config pointing `kite_mcp` to `http://127.0.0.1:3900/mcp`.

Quick usage (developer machine):
- Ensure deps installed (see Quick commands section above).
- Start server: `bash scripts/start_streamlit_smoke_test.sh`
- Verify UI at: `http://127.0.0.1:8501`
- Stop & restore config: `bash scripts/stop_streamlit_smoke_test.sh`

If you'd like, Copilot can also add a Playwright-based end-to-end job or a GitHub Actions workflow that runs the smoke test on push/PR.

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

run_step() {
  local label="$1"
  shift
  echo "==> $label"
  if "$@"; then
    echo "PASS: $label"
  else
    local rc=$?
    echo "FAIL: $label (exit $rc)"
    status=$rc
  fi
}

run_step "ruff check (src/, tests/)" uv run ruff check src tests
run_step "ruff format --check (src/, tests/)" uv run ruff format --check src tests

mypy_targets=("src")
if find tests -type f -name '*.py' -print -quit | grep -q .; then
  mypy_targets+=("tests")
fi
run_step "mypy (${mypy_targets[*]})" uv run mypy "${mypy_targets[@]}"

run_step "pytest (tests/)" uv run pytest -q

if [ "$status" -ne 0 ]; then
  echo "Verification failed (exit $status)"
  exit "$status"
fi

echo "All verification checks passed."

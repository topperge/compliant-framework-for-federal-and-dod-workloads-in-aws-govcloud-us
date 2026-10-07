#!/usr/bin/env bash
# Offline checks for every module and live layer: fmt, validate, and the
# mock-provider plan tests in live/*/tests. No AWS credentials needed.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

terraform fmt -recursive -check "$ROOT"

for dir in "$ROOT"/modules/* "$ROOT"/live/*; do
  echo "==> ${dir#"$ROOT"/}"
  terraform -chdir="$dir" init -backend=false -input=false >/dev/null
  terraform -chdir="$dir" validate -no-color
  if [[ -d "$dir/tests" ]]; then
    terraform -chdir="$dir" test -no-color
  fi
done

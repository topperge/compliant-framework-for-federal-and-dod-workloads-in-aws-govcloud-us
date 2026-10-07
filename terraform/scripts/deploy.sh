#!/usr/bin/env bash
#
# Applies the Compliant Framework Terraform layers in dependency order. This is
# the Terraform replacement for the CodeBuild/CodePipeline orchestration of the
# CloudFormation version (buildspec.yml, core-pipeline, environment-pipeline-*).
#
# Usage:
#   scripts/deploy.sh <layer> [terraform args...]
#
# Layers:
#   commercial        live/01-commercial-accounts  (commercial payer credentials)
#   organization      live/02-govcloud-organization
#   core              live/03-core
#   environment ENV   live/04-environment, one state per environment
#   baselines [ENV]   live/05-account-baseline, one state per member account
#   all               organization, core, every environment, every baseline
#
# Environment:
#   CONFIG_FILE   framework config (default: config/framework.yaml)
#   BACKEND_HCL   S3 backend settings (default: backend.hcl, see live/00-tfstate)
#   COMMERCIAL_BACKEND_HCL  backend settings for the commercial layer, which
#                 cannot use GovCloud credentials (default: backend-commercial.hcl)
#   TF_ACTION     plan | apply (default: apply)
#
# GovCloud layers run with credentials for the GovCloud central (organization
# management) account; member accounts are reached through
# account_access_role_name.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$(realpath "${CONFIG_FILE:-$ROOT/config/framework.yaml}")"
BACKEND_HCL="$(realpath "${BACKEND_HCL:-$ROOT/backend.hcl}")"
COMMERCIAL_BACKEND_HCL="$(realpath "${COMMERCIAL_BACKEND_HCL:-$ROOT/backend-commercial.hcl}")"
TF_ACTION="${TF_ACTION:-apply}"

config_query() {
  python3 - "$CONFIG_FILE" "$1" <<'PY'
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1]))
query = sys.argv[2]
if query == "environments":
    print("\n".join(cfg.get("environments", {})))
elif query.startswith("accounts:"):
    # member accounts of one environment that receive the account baseline
    env = cfg["environments"][query.split(":", 1)[1]]
    ids = [env["transit"]["account_id"], env["management_services"]["account_id"]]
    ids += [t["account_id"] for t in env.get("tenants", [])]
    seen = []
    for i in map(str, ids):
        if i not in seen:
            seen.append(i)
    print("\n".join(seen))
PY
}

run() {
  local dir="$1" key="$2"; shift 2
  echo "==> $dir ($key)"
  terraform -chdir="$ROOT/$dir" init -input=false -reconfigure \
    -backend-config="$BACKEND_HCL" -backend-config="key=$key"
  local extra=()
  [[ "$TF_ACTION" == "apply" ]] && extra+=(-auto-approve)
  terraform -chdir="$ROOT/$dir" "$TF_ACTION" -input=false \
    -var "config_file=$CONFIG_FILE" "${extra[@]}" "$@"
}

layer_environment() {
  local env="$1"; shift
  run live/04-environment "compliant-framework/environment/$env.tfstate" -var "environment=$env" "$@"
}

layer_baselines() {
  local envs=("$@")
  [[ ${#envs[@]} -eq 0 ]] && mapfile -t envs < <(config_query environments)
  for env in "${envs[@]}"; do
    for account in $(config_query "accounts:$env"); do
      run live/05-account-baseline "compliant-framework/account-baseline/$account.tfstate" \
        -var "environment=$env" -var "account_id=$account"
    done
  done
}

layer="${1:-}"; shift || true
case "$layer" in
  commercial)   BACKEND_HCL="$COMMERCIAL_BACKEND_HCL" run live/01-commercial-accounts "compliant-framework/commercial-accounts.tfstate" "$@" ;;
  organization) run live/02-govcloud-organization "compliant-framework/govcloud-organization.tfstate" "$@" ;;
  core)         run live/03-core "compliant-framework/core.tfstate" "$@" ;;
  environment)  env="${1:?environment name required}"; shift; layer_environment "$env" "$@" ;;
  baselines)    layer_baselines "$@" ;;
  all)
    "$0" organization
    "$0" core
    for env in $(config_query environments); do layer_environment "$env"; done
    layer_baselines
    ;;
  *) sed -n '2,25p' "$0"; exit 1 ;;
esac

#!/usr/bin/env bash
# Uploads the six iOS signing secrets to GitHub environments. Nothing is
# printed: passwords/tokens are read with hidden prompts, the .p8 key is read
# from its file, and every value is piped straight into `gh secret set`.
#
# Usage:
#   bash scripts/set-ios-secrets.sh <AuthKey_XXXX.p8> <KEY_ID> <ISSUER_ID> [environment...]
# Environments default to: dev dev-preview staging
# Run it with bash (it uses bash's read -p), not zsh. See docs/RELEASE_SETUP.md section 3.
set -euo pipefail

REPO="Paypadi-ng/paypadi"
MATCH_URL="https://github.com/Paypadi-ng/ios-certificates.git"

p8=${1:?usage: $0 <AuthKey.p8> <KEY_ID> <ISSUER_ID> [environment...]}
key_id=${2:?missing KEY_ID}
issuer_id=${3:?missing ISSUER_ID}
shift 3
envs=("$@"); (( ${#envs[@]} )) || envs=(dev dev-preview staging)

[[ -f "$p8" ]] || { echo "not found: $p8" >&2; exit 1; }
grep -q "BEGIN PRIVATE KEY" "$p8" || { echo "$p8 doesn't look like an App Store Connect .p8 key" >&2; exit 1; }
[[ "$key_id" =~ ^[A-Z0-9]{10}$ ]] || { echo "KEY_ID should be 10 characters, e.g. ABC123DEFG" >&2; exit 1; }
[[ "$issuer_id" =~ ^[0-9a-f-]{36}$ ]] || { echo "ISSUER_ID should be a UUID" >&2; exit 1; }

read -r -p "GitHub username that owns the read-only token: " gh_user
read -r -s -p "Fine-grained token (read-only Contents on ios-certificates): " gh_pat; echo
read -r -s -p "match passphrase (MATCH_PASSWORD): " match_pw; echo
[[ -n "$gh_user" && -n "$gh_pat" && -n "$match_pw" ]] || { echo "all three are required" >&2; exit 1; }

# Check the token can actually read the certificates repo before uploading.
if ! git -c credential.helper= ls-remote "https://${gh_user}:${gh_pat}@github.com/Paypadi-ng/ios-certificates.git" >/dev/null 2>&1; then
  echo "that token can't read Paypadi-ng/ios-certificates — not uploading" >&2; exit 1
fi

for env in "${envs[@]}"; do
  echo "▶ iOS secrets → environment '$env'"
  printf '%s' "$match_pw"   | gh secret set MATCH_PASSWORD                  --repo "$REPO" --env "$env"
  printf '%s' "$MATCH_URL"  | gh secret set MATCH_GIT_URL                   --repo "$REPO" --env "$env"
  printf '%s' "${gh_user}:${gh_pat}" | base64 | tr -d '\n' \
                            | gh secret set MATCH_GIT_BASIC_AUTHORIZATION   --repo "$REPO" --env "$env"
  printf '%s' "$key_id"     | gh secret set APP_STORE_CONNECT_API_KEY_ID    --repo "$REPO" --env "$env"
  printf '%s' "$issuer_id"  | gh secret set APP_STORE_CONNECT_API_ISSUER_ID --repo "$REPO" --env "$env"
  base64 -i "$p8" | tr -d '\n' \
                            | gh secret set APP_STORE_CONNECT_API_KEY_BASE64 --repo "$REPO" --env "$env"
done
unset gh_pat match_pw

echo "Done. Secrets now set:"
for env in "${envs[@]}"; do
  printf '  %-12s ' "$env"
  gh api "repos/$REPO/environments/$env/secrets" --jq '[.secrets[].name] | join(", ")'
done

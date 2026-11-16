#!/usr/bin/env bash
# Uploads one flavor's Android upload-signing secrets to GitHub environments,
# straight from the local keystore + key-<flavor>.properties. Values are piped
# into `gh secret set` and never printed.
#
# Usage:  bash scripts/set-android-signing-secrets.sh <flavor> <environment>...
#   bash scripts/set-android-signing-secrets.sh dev     dev dev-preview
#   bash scripts/set-android-signing-secrets.sh staging staging
#   bash scripts/set-android-signing-secrets.sh prod    prod-build prod
set -euo pipefail

REPO="Paypadi-ng/paypadi"
ANDROID_DIR="$(cd "$(dirname "$0")/.." && pwd)/android"

flavor=${1:?usage: $0 <dev|staging|prod> <environment>...}; shift
(( $# )) || { echo "usage: $0 <dev|staging|prod> <environment>..." >&2; exit 1; }
case "$flavor" in dev|staging|prod) ;; *) echo "unknown flavor: $flavor" >&2; exit 1 ;; esac

props="$ANDROID_DIR/key-$flavor.properties"
[[ -f "$props" ]] || { echo "missing $props" >&2; exit 1; }
prop() { sed -n "s/^$1=//p" "$props"; }

keystore=$(prop storeFile)
[[ -f "$keystore" ]] || { echo "keystore not found: $keystore" >&2; exit 1; }

# Refuse to upload a key whose password doesn't open it.
keytool -list -keystore "$keystore" -storepass "$(prop storePassword)" \
  -alias "$(prop keyAlias)" >/dev/null 2>&1 \
  || { echo "properties don't match $keystore — not uploading" >&2; exit 1; }

for env in "$@"; do
  echo "▶ $flavor signing → environment '$env'"
  base64 -i "$keystore" | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPO" --env "$env"
  prop storePassword | tr -d '\n' | gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$REPO" --env "$env"
  prop keyAlias      | tr -d '\n' | gh secret set ANDROID_KEY_ALIAS         --repo "$REPO" --env "$env"
  prop keyPassword   | tr -d '\n' | gh secret set ANDROID_KEY_PASSWORD      --repo "$REPO" --env "$env"
done

echo "Done. Secrets now set:"
for env in "$@"; do
  printf '  %-12s ' "$env"
  gh api "repos/$REPO/environments/$env/secrets" --jq '[.secrets[].name] | join(", ")'
done

#!/bin/bash
#
# Requires: bash, curl, jq

set -e

# Parse command line arguments
TARGET="$1" # Optional target parameter

# Validate target if provided
if [[ -n "$TARGET" ]] && [[ ! "$TARGET" =~ ^(stable|latest|[0-9]+\.[0-9]+\.[0-9]+(-[^[:space:]]+)?)$ ]]; then
  echo "Usage: $0 [stable|latest|VERSION]" >&2
  exit 1
fi

DOWNLOAD_BASE_URL="https://downloads.claude.ai/claude-code-releases"

download_file() {
  local url="$1"
  local output="$2"

  if [ -n "$output" ]; then
    curl -fsSL -o "$output" "$url"
  else
    curl -fsSL "$url"
  fi
}

generate_info() {
  # Detect Rosetta 2 on macOS: if the shell is running as x64 under Rosetta on an ARM Mac,
  # download the native arm64 binary instead of the x64 one
  os="$1"

  case "${2}" in
  x86_64 | amd64) arch="x64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
  esac

  platform="${os}-${arch}"

  # Always download latest version (which has the most up-to-date installer)
  version=$(download_file "$DOWNLOAD_BASE_URL/latest")

  # Reject non-version content (e.g. an HTML error page) before it reaches the manifest URL
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "Failed to get a valid version from downloads.claude.ai (got unexpected content)." >&2
    echo "This can happen if the download service is unreachable or not available in your region - see https://www.anthropic.com/supported-countries" >&2
    exit 1
  fi

  # Download manifest and extract checksum
  manifest_json=$(download_file "$DOWNLOAD_BASE_URL/$version/manifest.json")
  checksum=$(echo "$manifest_json" | jq -r ".platforms[\"$platform\"].checksum // empty")

  # Validate checksum format (SHA256 = 64 hex characters)
  if [ -z "$checksum" ] || [[ ! "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
    echo "Platform $platform not found in manifest" >&2
    exit 1
  fi

  download_url="$DOWNLOAD_BASE_URL/$version/$platform/claude"
  cat <<EOF
  {
    "version": "$version",
    "platform": "$platform",
    "url": "$download_url",
    "checksum": "$checksum"
  }
EOF

}

os="linux"
arches=(
  x86_64
  aarch64
)

results=()
for arch in "${arches[@]}"; do
  results+=("$(generate_info "${os}" "${arch}")")
done
printf '%s\n' "${results[@]}" | jq -s .

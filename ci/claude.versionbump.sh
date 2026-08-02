#!/bin/bash
#
# Requires: bash, curl, jq, awk, sed
# (also invokes ./claude.metadata.sh, which requires curl and jq)

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SPEC_FILE="claude-code.spec"
SOURCES_FILE="SOURCES"
MAINTAINER="Package Maintainer <maintainer@example.com>"

metadata_json="$(./claude.metadata.sh)"

new_version="$(jq -r '.[0].version' <<<"$metadata_json")"
current_version="$(awk '/^Version:/{print $2}' "$SPEC_FILE")"

if [[ "$new_version" == "$current_version" ]]; then
  echo "Already up to date ($current_version)" >&2
  exit 0
fi

echo "Bumping version: $current_version -> $new_version" >&2

sed -i "s/^Version:.*/Version:        $new_version/" "$SPEC_FILE"

while IFS=$'\t' read -r platform checksum; do
  case "$platform" in
  linux-x64) rpm_arch="x86_64" ;;
  linux-arm64) rpm_arch="aarch64" ;;
  *)
    echo "Unknown platform in metadata: $platform" >&2
    exit 1
    ;;
  esac
  sed -i "s/^SHA256 (claude-${rpm_arch}) = .*/SHA256 (claude-${rpm_arch}) = ${checksum}/" "$SOURCES_FILE"
done < <(jq -r '.[] | [.platform, .checksum] | @tsv' <<<"$metadata_json")

changelog_date="$(LC_ALL=C date +'%a %b %d %Y')"
release_field="$(awk '/^Release:/{print $2}' "$SPEC_FILE")"
release_num="${release_field%%[^0-9]*}"

awk -v date="$changelog_date" -v maintainer="$MAINTAINER" -v version="$new_version" -v release="$release_num" '
/^%changelog/{
  print
  print "* " date " " maintainer " - " version "-" release
  print "- Updated to official Claude Code release version " version "."
  next
}
{ print }
' "$SPEC_FILE" >"${SPEC_FILE}.tmp" && mv "${SPEC_FILE}.tmp" "$SPEC_FILE"

echo "Updated $SPEC_FILE and $SOURCES_FILE to version $new_version" >&2

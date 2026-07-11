#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <archive.zip> <plugin-manifest.json> <archive.zip.sha256>" >&2
  exit 2
fi

archive="$(realpath "$1")"
manifest="$(realpath "$2")"
checksum="$(realpath "$3")"

[[ -f "$archive" && -f "$manifest" && -f "$checksum" ]]
(
  cd "$(dirname "$checksum")"
  sha256sum --check "$(basename "$checksum")"
)

embedded_manifest="$(mktemp)"
trap 'rm -f "$embedded_manifest"' EXIT
unzip -p "$archive" plugin-manifest.json > "$embedded_manifest"
cmp --silent "$manifest" "$embedded_manifest"

jq -e '
  .schema_version == 1
  and (.id | type == "string" and length > 0)
  and (.kind | IN("optional_plugin", "game_mode", "mode_modifier"))
  and (.version | type == "string" and length > 0)
  and (.build_revision | test("^[0-9a-f]{40}$"))
  and (.required_paths | type == "array" and length > 0)
  and (.restart_policy | IN("process", "map_change"))
' "$manifest" >/dev/null

mapfile -t entries < <(unzip -Z1 "$archive")
for entry in "${entries[@]}"; do
  if [[ "$entry" == /* || "$entry" == *\\* || "$entry" == "../"* || "$entry" == *"/../"* ]]; then
    echo "unsafe archive entry: $entry" >&2
    exit 1
  fi
  case "$entry" in
    addons/*|plugin-manifest.json|LICENSE|LICENSE.md|README.md) ;;
    *) echo "unexpected archive root entry: $entry" >&2; exit 1 ;;
  esac
done

if printf '%s\n' "${entries[@]}" | grep -Fq 'CounterStrikeSharp.API.dll'; then
  echo "archive must not bundle CounterStrikeSharp.API.dll" >&2
  exit 1
fi

while IFS= read -r required_path; do
  if ! printf '%s\n' "${entries[@]}" | grep -Fxq "$required_path"; then
    echo "missing required path: $required_path" >&2
    exit 1
  fi
done < <(jq -r '.required_paths[]' "$manifest")

echo "validated $(basename "$archive") for plugin $(jq -r '.id' "$manifest")"


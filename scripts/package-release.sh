#!/usr/bin/env bash
set -euo pipefail

tag="${1:?release tag is required, for example v1.2.3-mbsifu.1}"
output_arg="${2:-artifacts}"
if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-mbsifu\.[0-9]+$ ]]; then
  echo "invalid release tag: ${tag}" >&2
  exit 2
fi

if [[ "${tag%%-mbsifu.*}" != "v3.1.1" ]]; then
  echo "release tag ${tag} does not match project version v3.1.1" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$(mkdir -p "${repo_root}/${output_arg}" && cd "${repo_root}/${output_arg}" && pwd)"
staging="${repo_root}/.release-staging"
build_output="${repo_root}/build-output"
dotnet="${DOTNET:-dotnet}"
rm -rf "${staging}" "${build_output}"
mkdir -p "${staging}/addons"

"${dotnet}" build "${repo_root}/RetakesPlugin/RetakesPlugin.csproj" -c Release --nologo
plugin_dir="${staging}/addons/counterstrikesharp/plugins/RetakesPlugin"
shared_dir="${staging}/addons/counterstrikesharp/shared/RetakesPluginShared"
mkdir -p "${plugin_dir}" "${shared_dir}"
install -m 0644 "${build_output}/addons/counterstrikesharp/plugins/RetakesPlugin/RetakesPlugin.dll" "${plugin_dir}/RetakesPlugin.dll"
install -m 0644 "${build_output}/addons/counterstrikesharp/plugins/RetakesPlugin/RetakesPlugin.deps.json" "${plugin_dir}/RetakesPlugin.deps.json"
install -m 0644 "${build_output}/addons/counterstrikesharp/shared/RetakesPluginShared/RetakesPluginShared.dll" "${shared_dir}/RetakesPluginShared.dll"
install -m 0644 "${build_output}/addons/counterstrikesharp/shared/RetakesPluginShared/RetakesPluginShared.deps.json" "${shared_dir}/RetakesPluginShared.deps.json"
cp -a "${repo_root}/RetakesPlugin/lang" "${plugin_dir}/lang"
cp -a "${repo_root}/RetakesPlugin/map_config" "${plugin_dir}/map_config"
cp "${repo_root}/README.md" "${staging}/README.md"
cp "${repo_root}/LICENSE" "${staging}/LICENSE"
jq --arg version "${tag#v}" --arg build_revision "$(git -C "${repo_root}" rev-parse HEAD)" \
  '.version = $version | .build_revision = $build_revision' \
  "${repo_root}/packaging/plugin-manifest.json" > "${staging}/plugin-manifest.json"
cp "${staging}/plugin-manifest.json" "${output_dir}/plugin-manifest.json"

source_date_epoch="${SOURCE_DATE_EPOCH:-$(git -C "${repo_root}" show -s --format=%ct HEAD)}"
find "${staging}" -type f -exec touch -d "@${source_date_epoch}" {} +

archive="${output_dir}/cs2-retakes-${tag}-linux-x64.zip"
rm -f "${archive}" "${archive}.sha256"
(
  cd "${staging}"
  find . -type f -print | LC_ALL=C sort | zip -X -q "${archive}" -@
)
(
  cd "${output_dir}"
  sha256sum "$(basename "${archive}")" > "$(basename "${archive}").sha256"
)

"${repo_root}/scripts/validate-release.sh" "${archive}" "${output_dir}/plugin-manifest.json" "${archive}.sha256"
echo "created ${archive}"

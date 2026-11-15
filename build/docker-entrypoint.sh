#!/usr/bin/env bash
set -euo pipefail
[ "$(uname -m)" = x86_64 ] || { echo 'This build requires an x86_64 Linux container' >&2; exit 1; }
[ -d /output ] && [ -w /output ] || { echo 'Mount a writable /output directory' >&2; exit 1; }
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cd "$work"
echo 'Downloading the latest official Claude Desktop from the signed Anthropic APT repository.'
apt-get update
apt-get download claude-desktop:amd64
mapfile -t packages < <(find . -maxdepth 1 -type f -name 'claude-desktop_*_amd64.deb')
[ "${#packages[@]}" -eq 1 ] || { echo 'Expected exactly one downloaded package' >&2; exit 1; }
export DEB_FILE="${packages[0]}"
version=$(dpkg-deb -f "$DEB_FILE" Version)
[[ "$version" =~ ^[A-Za-z0-9.+~:-]+$ ]] || { echo 'Invalid package version' >&2; exit 1; }
sha256sum "$DEB_FILE"
echo 'Installing runtime, SDK and Electron BaseApp from Flathub.'
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive --assumeyes --no-related flathub \
  org.freedesktop.Platform/x86_64/26.08 \
  org.freedesktop.Sdk/x86_64/26.08 \
  org.electronjs.Electron2.BaseApp/x86_64/26.08
cp /opt/claude-build/reference.tar .
export OSTREE_REPO="$HOME/.local/share/flatpak/repo"
if ostree --repo="$OSTREE_REPO" rev-parse runtime/org.electronjs.Electron2.BaseApp/x86_64/26.08 >/dev/null 2>&1; then
  export BASE_REF=runtime/org.electronjs.Electron2.BaseApp/x86_64/26.08
else
  export BASE_REF=app/org.electronjs.Electron2.BaseApp/x86_64/26.08
fi
bash /opt/claude-build/rebuild.sh
read -r engine_version engine_sha < <(node /opt/claude-build/extract-engine.cjs unpacked/usr/lib/claude-desktop/resources/app.asar)
[[ "$engine_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$engine_sha" =~ ^[a-f0-9]{64}$ ]] || { echo 'Invalid embedded engine manifest' >&2; exit 1; }
echo "Downloading required Claude Code $engine_version"
curl -fL --retry 3 "https://downloads.claude.ai/claude-code-releases/$engine_version/linux-x64/claude.zst" -o claude-engine.zst
printf '%s  %s\n' "$engine_sha" claude-engine.zst | sha256sum -c -
printf '%s\n%s\n' "$engine_version" "$engine_sha" > engine-info.txt
cp /opt/claude-build/open3p.sh /opt/claude-build/install-and-open.sh .
printf 'Desktop version: %s\nDesktop package SHA-256: %s\nClaude Code version: %s\nClaude Code compressed SHA-256: %s\nRuntime: 26.08\n' "$version" "$(sha256sum "$DEB_FILE" | cut -d' ' -f1)" "$engine_version" "$engine_sha" > BUILD-INFO.txt
tar -cf claude-desktop-offline.tar claude-desktop-offline.flatpak freedesktop-platform-26.08.flatpak open3p.sh install-and-open.sh claude-engine.zst engine-info.txt BUILD-INFO.txt
sha256sum claude-desktop-offline.tar > SHA256SUMS
dest="/output/claude-desktop-${version//:/-}-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir "$dest"
cp claude-desktop-offline.tar SHA256SUMS BUILD-INFO.txt "$dest/"
echo "Build completed: $dest. Test on a compatible machine before deployment."

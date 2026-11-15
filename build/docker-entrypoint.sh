#!/usr/bin/env bash
set -euo pipefail

input=/input/claude-desktop.deb
output=/output
: "${DEB_SHA256:?Provide the expected SHA-256 as DEB_SHA256}"
[[ "$DEB_SHA256" =~ ^[0-9a-fA-F]{64}$ ]] || { echo 'Invalid SHA-256' >&2; exit 1; }
[ "$(uname -m)" = x86_64 ] || { echo 'This build requires an x86_64 Linux container' >&2; exit 1; }
[ -f "$input" ] || { echo 'Missing /input/claude-desktop.deb' >&2; exit 1; }
[ -d "$output" ] && [ -w "$output" ] || { echo 'Mount a writable /output directory' >&2; exit 1; }
for f in claude-desktop-offline.flatpak freedesktop-platform-26.08.flatpak claude-desktop-offline.tar SHA256SUMS; do
  [ ! -e "$output/$f" ] || { echo "Refusing to overwrite $output/$f" >&2; exit 1; }
done
printf '%s  %s\n' "$DEB_SHA256" "$input" | sha256sum -c -
echo 'Installing runtime, SDK and Electron BaseApp from Flathub; network access is required.'
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive --assumeyes flathub \
  org.freedesktop.Platform/x86_64/26.08 \
  org.freedesktop.Sdk/x86_64/26.08 \
  org.electronjs.Electron2.BaseApp/x86_64/26.08

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cd "$work"
cp "$input" claude-desktop_5.11492.5_amd64.deb
cp /opt/claude-build/reference.tar .
export OSTREE_REPO="$HOME/.local/share/flatpak/repo"
if ostree --repo="$OSTREE_REPO" rev-parse runtime/org.electronjs.Electron2.BaseApp/x86_64/26.08 >/dev/null 2>&1; then
  export BASE_REF=runtime/org.electronjs.Electron2.BaseApp/x86_64/26.08
else
  export BASE_REF=app/org.electronjs.Electron2.BaseApp/x86_64/26.08
fi
bash /opt/claude-build/rebuild.sh
cp /opt/claude-build/open3p.sh /opt/claude-build/install-and-open.sh .
tar -cf claude-desktop-offline.tar claude-desktop-offline.flatpak freedesktop-platform-26.08.flatpak open3p.sh install-and-open.sh
sha256sum claude-desktop-offline.flatpak freedesktop-platform-26.08.flatpak claude-desktop-offline.tar > SHA256SUMS
cp claude-desktop-offline.flatpak freedesktop-platform-26.08.flatpak claude-desktop-offline.tar SHA256SUMS "$output/"
echo 'Build artifacts written to /output. Test them on a compatible machine before deployment.'

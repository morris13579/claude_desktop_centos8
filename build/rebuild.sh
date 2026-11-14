#!/usr/bin/env bash
# Reconstructed recipe: run in a new build directory; see README limitations.
set -euo pipefail
: "${OSTREE_REPO:?Set OSTREE_REPO to the Flatpak OSTree repository}"
: "${BASE_REF:=runtime/org.electronjs.Electron2.BaseApp/x86_64/26.08}"
[ -f claude-desktop_5.11492.5_amd64.deb ] || { echo "Missing Debian package" >&2; exit 1; }
[ -f reference.tar ] || { echo "Missing reference.tar" >&2; exit 1; }
for dir in base-checkout unpacked claude-build app-repo package-reference; do
  [ ! -e "$dir" ] || { echo "Refusing to overwrite $dir; use a fresh directory" >&2; exit 1; }
done
ostree --repo="$OSTREE_REPO" checkout --user-mode "$BASE_REF" base-checkout
mkdir -p unpacked package-reference claude-build/files claude-build/export
(cd unpacked; ar x ../claude-desktop_5.11492.5_amd64.deb data.tar.xz; tar -xf data.tar.xz)
tar -xf reference.tar -C package-reference
cp -a base-checkout/files/. claude-build/files/
mkdir -p claude-build/files/lib/claude-desktop
cp -a unpacked/usr/lib/claude-desktop/. claude-build/files/lib/claude-desktop/
mkdir -p claude-build/files/bin claude-build/files/share/applications claude-build/files/share/metainfo claude-build/files/share/icons/hicolor/256x256/apps
sed 's@/app/extra/claude-desktop@/app/lib/claude-desktop@g' package-reference/claude-desktop-wrapper > claude-build/files/bin/claude-desktop
chmod 755 claude-build/files/bin/claude-desktop
cp package-reference/*.desktop claude-build/files/share/applications/
cp package-reference/*.xml claude-build/files/share/metainfo/
cp package-reference/*.png claude-build/files/share/icons/hicolor/256x256/apps/
cat > claude-build/metadata <<'META'
[Application]
name=com.anthropic.ClaudeDesktop
runtime=org.freedesktop.Platform/x86_64/26.08
sdk=org.freedesktop.Sdk/x86_64/26.08
[Instance]
devel=true
META
flatpak build-finish --command=claude-desktop --share=ipc --share=network --socket=fallback-x11 --socket=wayland --socket=pulseaudio --device=dri --talk-name=org.freedesktop.Notifications --talk-name=org.kde.StatusNotifierWatcher --talk-name=org.freedesktop.secrets claude-build
flatpak build-export app-repo claude-build stable
flatpak build-bundle app-repo claude-desktop-offline.flatpak com.anthropic.ClaudeDesktop stable
flatpak build-bundle --runtime "$OSTREE_REPO" freedesktop-platform-26.08.flatpak org.freedesktop.Platform 26.08
sha256sum claude-desktop-offline.flatpak freedesktop-platform-26.08.flatpak

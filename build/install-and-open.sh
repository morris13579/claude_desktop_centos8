#!/bin/bash
set -eu
cd "$(dirname "$0")"
command -v flatpak >/dev/null || { echo "Flatpak is required; install it offline first." >&2; exit 1; }
[ "$(uname -m)" = x86_64 ] || { echo "This package requires x86_64." >&2; exit 1; }
command -v zstd >/dev/null || { echo "zstd is required." >&2; exit 1; }
engine_version=$(sed -n '1p' engine-info.txt)
engine_sha=$(sed -n '2p' engine-info.txt)
printf '%s\n' "$engine_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo 'Invalid engine version' >&2; exit 1; }
printf '%s\n' "$engine_sha" | grep -Eq '^[a-f0-9]{64}$' || { echo 'Invalid engine checksum' >&2; exit 1; }
printf '%s  %s\n' "$engine_sha" claude-engine.zst | sha256sum -c -
config="$HOME/.var/app/com.anthropic.ClaudeDesktop/config/Claude-3p"
if [ -e "$config/configLibrary" ] || [ -e "$config/claude_desktop_config.json" ]; then
  echo "Existing Claude 3p configuration detected; refusing to overwrite." >&2
  exit 1
fi
flatpak install --user --noninteractive --no-deps ./freedesktop-platform-26.08.flatpak
flatpak install --user --noninteractive --no-deps ./claude-desktop-offline.flatpak
engine_dir="$config/claude-code/$engine_version/${engine_sha:0:12}"
if [ -e "$engine_dir/claude" ] || [ -e "$engine_dir/.verified" ]; then
  echo 'An existing Desktop engine was found; refusing to overwrite.' >&2
  exit 1
fi
mkdir -p "$engine_dir"
zstd -d -c claude-engine.zst > "$engine_dir/claude"
chmod 755 "$engine_dir/claude"
printf '%s' "$engine_sha" > "$engine_dir/.verified"
chmod 600 "$engine_dir/.verified"
bash ./open3p.sh

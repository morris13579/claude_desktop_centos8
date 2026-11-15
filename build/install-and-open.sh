#!/bin/bash
set -eu
cd "$(dirname "$0")"
command -v flatpak >/dev/null || { echo "Flatpak is required; install it offline first." >&2; exit 1; }
[ "$(uname -m)" = x86_64 ] || { echo "This package requires x86_64." >&2; exit 1; }
config="$HOME/.var/app/com.anthropic.ClaudeDesktop/config/Claude-3p"
if [ -e "$config/configLibrary" ] || [ -e "$config/claude_desktop_config.json" ]; then
  echo "Existing Claude 3p configuration detected; refusing to overwrite." >&2
  exit 1
fi
flatpak install --user --noninteractive --no-deps ./freedesktop-platform-26.08.flatpak
flatpak install --user --noninteractive --no-deps ./claude-desktop-offline.flatpak
bash ./open3p.sh

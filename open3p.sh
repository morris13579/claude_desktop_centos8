#!/bin/bash
set -eu
config="$HOME/.var/app/com.anthropic.ClaudeDesktop/config/Claude-3p"
if [ -e "$config/configLibrary" ] || [ -e "$config/claude_desktop_config.json" ]; then echo 'EXISTING 3P CONFIG - STOP'; exit 1; fi
mkdir -p "$config/configLibrary"
chmod 700 "$config" "$config/configLibrary"
printf '%s\n' '{"appliedId":"00000000-0000-4000-8000-000000000114","entries":[{"id":"00000000-0000-4000-8000-000000000114","name":"Gateway"}]}' > "$config/configLibrary/_meta.json"
printf '%s\n' '{"inferenceProvider":"gateway","inferenceGatewayBaseUrl":"http://127.0.0.1:18777","inferenceGatewayApiKey":"local-test-only","inferenceGatewayAuthScheme":"x-api-key","inferenceModels":[{"name":"claude-sonnet-4-6"}],"modelDiscoveryEnabled":false,"chatTabEnabled":true}' > "$config/configLibrary/00000000-0000-4000-8000-000000000114.json"
printf '%s\n' '{"deploymentMode":"3p"}' > "$config/claude_desktop_config.json"
chmod 600 "$config/configLibrary/"*.json "$config/claude_desktop_config.json"
flatpak kill com.anthropic.ClaudeDesktop 2>/dev/null || true
flatpak run --env=ZYPAK_ZYGOTE_STRATEGY_SPAWN=0 com.anthropic.ClaudeDesktop --disable-gpu > open3p.log 2>&1 &

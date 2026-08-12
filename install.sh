#!/usr/bin/env bash
# Pixel Office installer — copies the plugin into ~/.hermes (profile-aware).
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Pixel Office into $HERMES_HOME"

# Backend plugin
rm -rf "$HERMES_HOME/plugins/pixel-office"
mkdir -p "$HERMES_HOME/plugins"
cp -r "$SRC" "$HERMES_HOME/plugins/pixel-office"
# Don't ship the repo's own .git into the plugins dir
rm -rf "$HERMES_HOME/plugins/pixel-office/.git"

# Desktop pane
rm -rf "$HERMES_HOME/desktop-plugins/pixel-office"
mkdir -p "$HERMES_HOME/desktop-plugins/pixel-office"
cp "$SRC/desktop/plugin.js" "$HERMES_HOME/desktop-plugins/pixel-office/plugin.js"

# TUI dock widget
mkdir -p "$HERMES_HOME/tui-widgets"
cp "$SRC/tui-widgets/office.mjs" "$HERMES_HOME/tui-widgets/office.mjs"

echo
echo "Done. Next steps:"
echo "  1. Add 'pixel-office' to plugins.enabled in $HERMES_HOME/config.yaml"
echo "     (if it's not already there)"
echo "  2. Restart hermes (or: systemctl --user restart hermes-gateway)"
echo "  3. Open http://127.0.0.1:8113 once any agent runs"
echo
echo "Try the whip right away:"
echo "  hermes office whip"

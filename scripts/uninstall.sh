#!/bin/bash
set -e

echo ""
echo "🗑️  Uninstalling xcoder..."
echo ""

INSTALL_DIR="${XCODER_DIR:-$HOME/.xcoder-src}"
BIN_DIR="$HOME/.local/bin"

# Remove global link
rm -f "$BIN_DIR/xcoder"
echo "✅ Removed $BIN_DIR/xcoder"

# Ask to remove source
read -p "Remove source directory ($INSTALL_DIR)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -rf "$INSTALL_DIR"
  echo "✅ Removed $INSTALL_DIR"
fi

# Ask to remove config
read -p "Remove config (~/.xcoder)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -rf "$HOME/.xcoder"
  echo "✅ Removed ~/.xcoder"
fi

echo ""
echo "Done. Remove PATH entry from ~/.zshrc or ~/.bashrc manually if needed."
echo ""

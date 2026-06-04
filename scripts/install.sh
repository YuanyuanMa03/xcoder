#!/bin/bash
set -e

echo ""
echo " ██╗  ██╗ ██████╗██╗      █████╗ ██╗    ██╗"
echo " ╚██╗██╔╝██╔════╝██║     ██╔══██╗██║    ██║"
echo "  ╚███╔╝ ██║     ██║     ███████║██║ █╗ ██║"
echo "  ██╔██╗ ██║     ██║     ██╔══██║██║███╗██║"
echo " ██╔╝ ██╗╚██████╗███████╗██║  ██║╚███╔███╔╝"
echo " ╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝"
echo ""
echo "  超越人类与 AI 的边界"
echo ""

# Detect package manager
if command -v bun &> /dev/null; then
  PKG="bun"
  echo "✅ Bun $(bun --version)"
elif command -v node &> /dev/null; then
  NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
  if [ "$NODE_VER" -lt 18 ]; then
    echo "❌ Node.js >= 18 required (found: $(node -v))"
    echo "   Install: https://nodejs.org"
    exit 1
  fi
  PKG="node"
  echo "✅ Node.js $(node -v)"
else
  echo "❌ Need Bun or Node.js >= 18"
  echo "   Install Bun: curl -fsSL https://bun.sh/install | bash"
  echo "   Install Node: https://nodejs.org"
  exit 1
fi

# Install dir
INSTALL_DIR="${XCODER_DIR:-$HOME/.xcoder-src}"

# Clone or update
echo ""
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "📦 Updating xcoder..."
  cd "$INSTALL_DIR"
  git pull --quiet
else
  echo "📦 Cloning xcoder..."
  git clone --quiet https://github.com/YuanyuanMa03/xcoder.git "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# Install deps
echo "📥 Installing dependencies..."
if [ "$PKG" = "bun" ]; then
  bun install --frozen-lockfile 2>/dev/null || bun install
else
  npm ci 2>/dev/null || npm install
fi

# Build
echo "🔨 Building..."
if [ "$PKG" = "bun" ]; then
  bun run build
else
  node build.ts
fi

# Verify build
if [ ! -f "dist/cli-node.js" ]; then
  echo "❌ Build failed: dist/cli-node.js not found"
  exit 1
fi

chmod +x dist/cli-node.js

# Link globally
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/dist/cli-node.js" "$BIN_DIR/xcoder"

# Ensure PATH
SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  if [ -n "$SHELL_RC" ]; then
    echo '' >> "$SHELL_RC"
    echo '# xcoder' >> "$SHELL_RC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  fi
  export PATH="$BIN_DIR:$PATH"
  echo "✅ Added $BIN_DIR to PATH"
fi

echo ""
echo "✅ xcoder installed!"
echo ""
echo "   xcoder --version    # $(xcoder --version 2>/dev/null || echo 'open a new terminal')"
echo "   xcoder              # start"
echo "   /login             # configure API on first use"
echo ""

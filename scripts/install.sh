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

# ── Detect OS ──
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *)      echo "❌ 不支持的系统: $OS"; exit 1 ;;
esac

# ── Auto-install Git ──
if command -v git &> /dev/null; then
  echo "✅ $(git --version)"
else
  echo "📥 Git 未安装，正在自动安装..."
  if [ "$PLATFORM" = "macos" ]; then
    if command -v brew &> /dev/null; then
      brew install git
    else
      xcode-select --install 2>/dev/null || true
      echo "⚠️  请在弹出的窗口中确认安装 Xcode Command Line Tools"
      echo "   安装完成后请重新运行此脚本"
      exit 1
    fi
  else
    if command -v apt-get &> /dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y -qq git
    elif command -v yum &> /dev/null; then
      sudo yum install -y git
    elif command -v dnf &> /dev/null; then
      sudo dnf install -y git
    elif command -v pacman &> /dev/null; then
      sudo pacman -S --noconfirm git
    else
      echo "❌ 无法自动安装 Git，请手动安装"
      exit 1
    fi
  fi
  echo "✅ $(git --version)"
fi

# ── Auto-install Node.js ──
HAS_NODE=false
if command -v node &> /dev/null; then
  NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
  if [ "$NODE_VER" -ge 18 ]; then
    HAS_NODE=true
    echo "✅ Node.js $(node -v)"
  else
    echo "⚠️  Node.js 版本过低 (需要 >= 18, 当前: $(node -v))"
  fi
fi

if [ "$HAS_NODE" = false ]; then
  echo "📥 Node.js 未安装，正在自动安装..."
  if [ "$PLATFORM" = "macos" ]; then
    if command -v brew &> /dev/null; then
      brew install node
    else
      echo "⚠️  需要 Homebrew 来安装 Node.js"
      echo "   安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
  else
    if command -v apt-get &> /dev/null; then
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - 2>/dev/null
      sudo apt-get install -y -qq nodejs
    elif command -v yum &> /dev/null; then
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - 2>/dev/null
      sudo yum install -y nodejs
    elif command -v dnf &> /dev/null; then
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - 2>/dev/null
      sudo dnf install -y nodejs
    elif command -v pacman &> /dev/null; then
      sudo pacman -S --noconfirm nodejs npm
    fi
  fi
  if command -v node &> /dev/null; then
    NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VER" -ge 18 ]; then
      HAS_NODE=true
      echo "✅ Node.js $(node -v)"
    fi
  fi
fi

# ── Auto-install Bun ──
HAS_BUN=false
if command -v bun &> /dev/null; then
  HAS_BUN=true
  echo "✅ Bun $(bun --version)"
else
  echo "📥 Bun 未安装，正在自动安装..."
  if curl -fsSL https://bun.sh/install | bash 2>/dev/null; then
    # bun installs to ~/.bun/bin, source it for current session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    if command -v bun &> /dev/null; then
      HAS_BUN=true
      echo "✅ Bun $(bun --version)"
    fi
  fi
  if [ "$HAS_BUN" = false ]; then
    echo "⚠️  Bun 安装失败，将使用 Node.js"
  fi
fi

if [ "$HAS_BUN" = false ] && [ "$HAS_NODE" = false ]; then
  echo ""
  echo "❌ 需要 Node.js >= 18 或 Bun，两者均安装失败"
  echo "   请手动安装后重试"
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
if [ "$HAS_BUN" = true ]; then
  bun install --frozen-lockfile 2>/dev/null || bun install || echo "⚠️  Some postinstall scripts failed (non-fatal), continuing..."
else
  npm ci 2>/dev/null || npm install || echo "⚠️  Some postinstall scripts failed (non-fatal), continuing..."
fi

if [ ! -d "node_modules" ]; then
  echo "❌ Dependency install failed: node_modules not found"
  exit 1
fi

# Build
echo "🔨 Building..."
if [ "$HAS_BUN" = true ]; then
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

# Also add bun to PATH in shell rc if installed
if [ "$HAS_BUN" = true ] && [ -n "$SHELL_RC" ]; then
  if ! grep -q 'bun/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export BUN_INSTALL="$HOME/.bun"' >> "$SHELL_RC"
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$SHELL_RC"
  fi
fi

echo ""
echo "✅ xcoder installed!"
echo ""
echo "   xcoder --version    # $(xcoder --version 2>/dev/null || echo 'open a new terminal')"
echo "   xcoder              # start"
echo "   /login             # configure API on first use"
echo ""

#!/bin/bash
set -e

echo ""
echo "██╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗"
echo "╚██╗██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗"
echo " ╚███╔╝ ██║     ██║   ██║██║  ██║█████╗  ██████╔╝"
echo " ██╔██╗ ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗"
echo "██╔╝ ██╗╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║"
echo "╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝"
echo ""
echo "  超越人类与 AI 的边界"
echo ""

OS="$(uname -s)"
ARCH="$(uname -m)"

# ── Auto-install Node.js ──
HAS_NODE=false
if command -v node &>/dev/null; then
    NODE_VER=$(node -v | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_VER" -ge 18 ]; then
        HAS_NODE=true
        echo "✅ Node.js $(node -v)"
    else
        echo "⚠️  Node.js 版本过低 (需要 >= 18, 当前: $(node -v))"
    fi
fi

if [ "$HAS_NODE" = false ]; then
    echo "📥 Node.js 未安装，正在自动安装..."
    installed=false

    case "$OS" in
        Darwin)
            # Method 1: Homebrew
            if [ "$installed" = false ] && command -v brew &>/dev/null; then
                brew install node && installed=true
            fi

            # Method 2: Download pkg directly
            if [ "$installed" = false ]; then
                echo "   Homebrew 不可用，直接下载 Node.js 安装包..."
                LATEST_LTS=$(curl -fsSL https://nodejs.org/dist/index.json | python3 -c "
import json,sys
data=json.load(sys.stdin)
print(next(v['version'] for v in data if v.get('lts')))" 2>/dev/null)
                if [ "$ARCH" = "arm64" ]; then
                    NODE_URL="https://nodejs.org/dist/$LATEST_LTS/node-$LATEST_LTS-darwin-arm64.pkg"
                else
                    NODE_URL="https://nodejs.org/dist/$LATEST_LTS/node-$LATEST_LTS-darwin-x64.pkg"
                fi
                echo "   下载 Node.js $LATEST_LTS..."
                PKG_PATH="/tmp/node-installer.pkg"
                curl -fsSL "$NODE_URL" -o "$PKG_PATH" && \
                    sudo installer -pkg "$PKG_PATH" -target / && \
                    installed=true
                rm -f "$PKG_PATH"
            fi
            ;;
        Linux)
            # Method 1: apt
            if [ "$installed" = false ] && command -v apt-get &>/dev/null; then
                curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null && \
                    sudo apt-get install -y -qq nodejs && installed=true
            fi

            # Method 2: yum
            if [ "$installed" = false ] && command -v yum &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - 2>/dev/null && \
                    sudo yum install -y nodejs && installed=true
            fi

            # Method 3: dnf
            if [ "$installed" = false ] && command -v dnf &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - 2>/dev/null && \
                    sudo dnf install -y nodejs && installed=true
            fi

            # Method 4: pacman
            if [ "$installed" = false ] && command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm nodejs npm && installed=true
            fi

            # Method 5: Download binary directly
            if [ "$installed" = false ]; then
                echo "   包管理器不可用，直接下载 Node.js 二进制..."
                LATEST_LTS=$(curl -fsSL https://nodejs.org/dist/index.json | python3 -c "
import json,sys
data=json.load(sys.stdin)
print(next(v['version'] for v in data if v.get('lts')))" 2>/dev/null)
                if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                    NODE_TAR="node-$LATEST_LTS-linux-arm64"
                else
                    NODE_TAR="node-$LATEST_LTS-linux-x64"
                fi
                NODE_URL="https://nodejs.org/dist/$LATEST_LTS/${NODE_TAR}.tar.xz"
                echo "   下载 Node.js $LATEST_LTS..."
                INSTALL_DIR="/usr/local"
                curl -fsSL "$NODE_URL" | sudo tar -xJ -C "$INSTALL_DIR" --strip-components=1 && installed=true
            fi
            ;;
        *)
            echo "❌ 不支持的系统: $OS"
            exit 1
            ;;
    esac

    if [ "$installed" = true ] && command -v node &>/dev/null; then
        echo "✅ Node.js $(node -v)"
    else
        echo ""
        echo "❌ 自动安装失败，请手动安装 Node.js:"
        echo "   https://nodejs.org/"
        echo ""
        echo "   安装完成后重新运行此脚本即可"
        exit 1
    fi
fi

# Install via npm
echo ""
echo "📦 安装 xcoder..."
npm install -g @yuanyuan20031001/xcoder

if [ $? -ne 0 ]; then
    echo "❌ npm 安装失败，请检查网络连接"
    exit 1
fi

echo ""
echo "✅ 安装完成!"
echo ""
echo "🚀 开始使用:"
echo "   xcoder              # 启动"
echo "   xcoder --version    # 查看版本"
echo ""
echo "📝 首次配置:"
echo "   启动后输入 /login 配置 API"
echo ""

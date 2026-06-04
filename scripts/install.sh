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
    case "$OS" in
        Darwin)
            if command -v brew &>/dev/null; then
                brew install node
            else
                echo "❌ 需要 Homebrew，请先安装: https://brew.sh"
                exit 1
            fi
            ;;
        Linux)
            if command -v apt-get &>/dev/null; then
                curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - 2>/dev/null
                sudo apt-get install -y -qq nodejs
            elif command -v yum &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - 2>/dev/null
                sudo yum install -y nodejs
            elif command -v dnf &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - 2>/dev/null
                sudo dnf install -y nodejs
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm nodejs npm
            else
                echo "❌ 无法自动安装 Node.js，请手动安装: https://nodejs.org"
                exit 1
            fi
            ;;
        *)
            echo "❌ 不支持的系统: $OS"
            exit 1
            ;;
    esac

    if command -v node &>/dev/null; then
        echo "✅ Node.js $(node -v)"
    else
        echo "❌ Node.js 安装失败，请手动安装: https://nodejs.org"
        exit 1
    fi
fi

# Install via npm
echo ""
echo "📦 安装 xcoder..."
npm install -g @yuanyuan20031001/xcoder

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

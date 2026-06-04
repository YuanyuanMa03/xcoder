# xcoder Windows Installer (from source)
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "██╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗"
Write-Host "╚██╗██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗"
Write-Host " ╚███╔╝ ██║     ██║   ██║██║  ██║█████╗  ██████╔╝"
Write-Host " ██╔██╗ ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗"
Write-Host "██╔╝ ██╗╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║"
Write-Host "╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝"
Write-Host ""
Write-Host "  超越人类与 AI 的边界"
Write-Host ""
Write-Host "📦 从源码安装 xcoder (Windows)..."
Write-Host ""

# Refresh PATH from registry so tools installed by winget/npm/bun are visible
# in the current session without requiring a terminal restart.
function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

Refresh-Path

# ── Auto-install Git ──
$HAS_GIT = $false
try {
    $gitVer = git --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $HAS_GIT = $true
        Write-Host "✅ $gitVer"
    }
} catch {}

if (-not $HAS_GIT) {
    Write-Host "📥 Git 未安装，正在自动安装..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install Git.Git --accept-source-agreements --accept-package-agreements --silent
        Refresh-Path
        try {
            $gitVer = git --version
            Write-Host "✅ $gitVer"
        } catch {
            Write-Host "❌ Git 安装失败，请手动安装: https://git-scm.com/download/win"
            exit 1
        }
    } else {
        Write-Host "❌ 需要 Git，请手动安装: https://git-scm.com/download/win"
        exit 1
    }
}

# ── Auto-install Node.js ──
$HAS_NODE = $false
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVer = node -v 2>$null
    $major = [int]($nodeVer -replace 'v(\d+).*', '$1')
    if ($major -ge 18) {
        $HAS_NODE = $true
        Write-Host "✅ Node.js $nodeVer"
    } else {
        Write-Host "⚠️  Node.js 版本过低 (需要 >= 18, 当前: $nodeVer)"
    }
}

if (-not $HAS_NODE) {
    Write-Host "📥 Node.js 未安装，正在自动安装..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent
        Refresh-Path
        if (Get-Command node -ErrorAction SilentlyContinue) {
            $nodeVer = node -v
            Write-Host "✅ Node.js $nodeVer"
            $HAS_NODE = $true
        } else {
            Write-Host "⚠️  Node.js 安装后仍未检测到，继续尝试..."
        }
    } else {
        Write-Host "⚠️  winget 不可用，跳过 Node.js 自动安装"
    }
}

# ── Auto-install Bun ──
$HAS_BUN = $false
try {
    $bunVer = bun --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $HAS_BUN = $true
        Write-Host "✅ Bun $bunVer"
    }
} catch {}

if (-not $HAS_BUN) {
    Write-Host "📥 Bun 未安装，正在自动安装..."
    try {
        powershell -c "irm bun.sh/install.ps1 | iex"
        Refresh-Path
        $bunVer = bun --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $HAS_BUN = $true
            Write-Host "✅ Bun $bunVer"
        }
    } catch {
        Write-Host "⚠️  Bun 安装失败，将使用 Node.js"
    }
}

if (-not $HAS_BUN -and -not $HAS_NODE) {
    Write-Host ""
    Write-Host "❌ 需要 Node.js >= 18 或 Bun，两者均安装失败"
    Write-Host "   请手动安装后重试"
    exit 1
}

# Clone repo
$INSTALL_DIR = "$env:USERPROFILE\.xcoder-src"
Write-Host ""
Write-Host "📥 克隆仓库到 $INSTALL_DIR..."

if (Test-Path $INSTALL_DIR) {
    Write-Host "   目录已存在，更新中..."
    Set-Location $INSTALL_DIR
    git pull
} else {
    git clone https://github.com/YuanyuanMa03/xcoder.git $INSTALL_DIR
    Set-Location $INSTALL_DIR
}

# Install dependencies
Write-Host ""
Write-Host "📥 安装依赖..."
if ($HAS_BUN) {
    # Postinstall scripts (e.g. chrome-mcp) may fail on Windows bun — non-fatal
    try { bun install } catch {
        Write-Host "⚠️  部分 postinstall 脚本失败（非致命），继续安装..."
    }
} else {
    try { npm install } catch {
        Write-Host "⚠️  部分 postinstall 脚本失败（非致命），继续安装..."
    }
}

if (-not (Test-Path "node_modules")) {
    Write-Host "❌ 依赖安装失败: node_modules 不存在"
    exit 1
}

# Build
Write-Host ""
Write-Host "🔨 构建..."
if ($HAS_BUN) {
    bun run build
} else {
    node build.ts
}

# Verify
if (-not (Test-Path "dist\cli-node.js")) {
    Write-Host "❌ 构建失败: dist\cli-node.js 不存在"
    exit 1
}

# Global install
Write-Host ""
Write-Host "🔗 全局安装..."

$installBin = "$env:LOCALAPPDATA\xcoder"
if (-not (Test-Path $installBin)) {
    New-Item -ItemType Directory -Path $installBin -Force | Out-Null
}

# Create batch wrapper
$batchContent = "@echo off`nnode `"$INSTALL_DIR\dist\cli-node.js`" %*"
Set-Content -Path "$installBin\xcoder.cmd" -Value $batchContent

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$installBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installBin", "User")
    $env:Path = "$env:Path;$installBin"
    Write-Host "✅ 已添加到 PATH"
}

# Refresh PATH again so xcoder is immediately available
Refresh-Path

Write-Host ""
Write-Host "✅ xcoder 已全局安装!"
Write-Host ""
Write-Host "🚀 开始使用:"
Write-Host "   xcoder              # 启动"
Write-Host "   xcoder --version    # 查看版本"
Write-Host ""
Write-Host "📝 首次配置:"
Write-Host "   启动后输入 /login 配置 API"
Write-Host ""
Write-Host "🔄 更新:"
Write-Host "   cd $INSTALL_DIR"
Write-Host "   git pull"
if ($HAS_BUN) {
    Write-Host "   bun install && bun run build"
} else {
    Write-Host "   npm install && node build.ts"
}
Write-Host ""

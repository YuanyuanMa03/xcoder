# xcoder Windows Installer
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

# Refresh PATH from registry
function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

Refresh-Path

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
            Write-Host "❌ Node.js 安装失败，请手动安装: https://nodejs.org"
            exit 1
        }
    } else {
        Write-Host "❌ winget 不可用，请手动安装 Node.js: https://nodejs.org"
        exit 1
    }
}

# Install via npm
Write-Host ""
Write-Host "📦 安装 xcoder..."
npm install -g @yuanyuan20031001/xcoder

Write-Host ""
Write-Host "✅ 安装完成!"
Write-Host ""
Write-Host "🚀 开始使用:"
Write-Host "   xcoder              # 启动"
Write-Host "   xcoder --version    # 查看版本"
Write-Host ""
Write-Host "📝 首次配置:"
Write-Host "   启动后输入 /login 配置 API"
Write-Host ""

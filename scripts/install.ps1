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

# Refresh PATH from registry so newly installed tools are visible immediately
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
    $installed = $false

    # Method 1: winget (Windows 10 1709+)
    if (-not $installed -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        try {
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent
            Refresh-Path
            if (Get-Command node -ErrorAction SilentlyContinue) {
                $installed = $true
            }
        } catch {}
    }

    # Method 2: Download MSI directly
    if (-not $installed) {
        Write-Host "   winget 不可用，直接下载 Node.js 安装包..."
        $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        # Get latest LTS version from Node.js API
        $ltsInfo = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing
        $latestLts = ($ltsInfo | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
        $nodeUrl = "https://nodejs.org/dist/$latestLts/node-$latestLts-$arch.msi"
        Write-Host "   下载 Node.js $latestLts..."
        $msiPath = "$env:TEMP\node-installer.msi"

        try {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $msiPath -UseBasicParsing
            Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait -NoNewWindow
            Refresh-Path
            if (Get-Command node -ErrorAction SilentlyContinue) {
                $installed = $true
            }
            Remove-Item $msiPath -ErrorAction SilentlyContinue
        } catch {
            Write-Host "   ⚠️  自动下载安装失败: $_"
        }
    }

    if ($installed) {
        $nodeVer = node -v
        Write-Host "✅ Node.js $nodeVer"
    } else {
        Write-Host ""
        Write-Host "❌ 自动安装失败，请手动安装 Node.js:"
        Write-Host "   https://nodejs.org/"
        Write-Host ""
        Write-Host "   安装完成后重新运行此脚本即可"
        exit 1
    }
}

# Install via npm
Write-Host ""
Write-Host "📦 安装 xcoder..."
npm install -g @yuanyuan20031001/xcoder

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm 安装失败，请检查网络连接"
    exit 1
}

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

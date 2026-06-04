# xcoder Windows Uninstaller
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🐾 卸载 xcoder (Windows)..."
Write-Host ""

# Remove from install directory
$installDir = "$env:LOCALAPPDATA\xcoder"
$cmdPath = "$installDir\xcoder.cmd"

if (Test-Path $cmdPath) {
    Remove-Item $cmdPath -Force
    Write-Host "✅ 已移除 $cmdPath"
} else {
    Write-Host "⚠️  $cmdPath 不存在"
}

# Remove from PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -like "*$installDir*") {
    $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $installDir }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "✅ 已从 PATH 移除"
}

# Ask about source directory
$sourceDir = "$env:USERPROFILE\.xcoder-src"
if (Test-Path $sourceDir) {
    Write-Host ""
    $confirm = Read-Host "是否删除源码目录 $sourceDir? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Remove-Item $sourceDir -Recurse -Force
        Write-Host "✅ 已删除 $sourceDir"
    } else {
        Write-Host "⏭  保留 $sourceDir"
    }
}

# Ask about config
$xcoderDir = "$env:USERPROFILE\.xcoder"
if (Test-Path $xcoderDir) {
    Write-Host ""
    $confirm = Read-Host "是否删除配置文件 $xcoderDir? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Remove-Item $xcoderDir -Recurse -Force
        Write-Host "✅ 已删除 $xcoderDir"
    } else {
        Write-Host "⏭  保留 $xcoderDir"
    }
}

Write-Host ""
Write-Host "✅ xcoder 卸载完成!"
Write-Host ""
Write-Host "注意: 请重启终端使 PATH 变更生效"
Write-Host ""

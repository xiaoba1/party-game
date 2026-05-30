# 聚会游戏集 - 一键运行脚本
# 双击或在 PowerShell 中运行: .\scripts\run.ps1

$ErrorActionPreference = "Stop"

$FlutterRoot = "E:\flutter"
if (-not (Test-Path "$FlutterRoot\bin\flutter.bat")) {
    Write-Host "正在安装 Flutter SDK 到 E:\flutter ..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FlutterRoot
}

$env:Path = "$FlutterRoot\bin;" + $env:Path

# 写入用户 PATH（只需一次）
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$FlutterRoot\bin*") {
    [Environment]::SetEnvironmentVariable('Path', "$FlutterRoot\bin;$userPath", 'User')
    Write-Host "已将 Flutter 加入系统 PATH"
}

Set-Location $PSScriptRoot\..

Write-Host ">>> flutter pub get"
flutter pub get

Write-Host ""
Write-Host ">>> 可用设备:"
flutter devices

Write-Host ""
Write-Host ">>> 启动 App（连接手机或模拟器后自动安装）"
Write-Host "    按 r 热重载，按 q 退出"
flutter run

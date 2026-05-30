# 构建 Android APK（安装包，可发给朋友直接装手机）
# 运行: .\scripts\build-apk.ps1

$ErrorActionPreference = "Stop"
$env:Path = "E:\flutter\bin;" + $env:Path
Set-Location $PSScriptRoot\..

Write-Host ">>> 构建 Release APK ..."
flutter build apk --release

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host ""
    Write-Host "构建成功！APK 路径:"
    Write-Host (Resolve-Path $apk)
} else {
    Write-Host "构建失败，请先安装 Android Studio 并运行 flutter doctor"
}

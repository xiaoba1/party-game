@echo off
chcp 65001 >nul
echo ========================================
echo   聚会游戏集 - 获取安装包指南
echo ========================================
echo.
echo 本地打包容易因网络卡住，请用【GitHub 云打包】：
echo.
echo   1. 在 github.com 创建空仓库
echo   2. 在本目录打开 PowerShell，执行：
echo.
echo      git init
echo      git add .
echo      git commit -m "init"
echo      git branch -M main
echo      git remote add origin https://github.com/你的用户名/仓库名.git
echo      git push -u origin main
echo.
echo   3. 打开仓库 Actions 页，等打包完成，下载 party-game-apk
echo.
echo 详细说明见: docs\如何获取安装包.md
echo.
start docs\如何获取安装包.md
pause

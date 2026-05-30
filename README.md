# 聚会游戏集 (Party Game)

离线聚会游戏 App，支持 Android / iOS。

## 快速开始（不用自己装环境）

**本地 Gradle 打包容易因网络失败，请用云打包：**

1. 双击运行 [`获取安装包.bat`](获取安装包.bat) 查看图文说明  
2. 或阅读 [`docs/如何获取安装包.md`](docs/如何获取安装包.md)  
3. 把代码推到 GitHub → Actions 自动打 APK → 下载安装

## 功能

- 玩家档案（昵称随时更改）
- 惩罚/奖励库 + 转盘模板
- 罚酒计数（直和 / 累计模式）
- 幸运转盘、摇骰子、真心话大冒险、随机点名
- WiFi/热点扫码联机、谁是卧底
- 扑克小游戏、聚会战报、数据导入导出

## 开发运行（环境已安装在 E:\flutter）

```powershell
cd e:\TraeCode\game
flutter pub get
flutter run          # 连接安卓手机 USB 调试
flutter run -d chrome  # 浏览器（部分功能依赖 SQLite，以手机为准）
```

## 技术栈

Flutter 3 + Riverpod + go_router + sqflite

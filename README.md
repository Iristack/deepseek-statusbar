# DeepSeek Status Bar

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2026%2B-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.10%2B-F05138?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green?logo=open-source-initiative" alt="License">
  <img src="https://img.shields.io/github/stars/zoisite/DeepSeekStatusBar?style=social" alt="GitHub Stars">
</p>

**DeepSeek Status Bar** 是一款轻量级 macOS 菜单栏应用，无需打开浏览器即可随时查看 [DeepSeek API](https://platform.deepseek.com) 账户余额。零依赖、零配置、开箱即用。

---

## 目录

- [为什么需要它](#为什么需要它)
- [功能](#功能)
- [快速开始](#快速开始)
- [安装](#安装)
  - [下载安装（推荐）](#下载安装推荐)
  - [从源码构建](#从源码构建)
- [使用方法](#使用方法)
- [预览](#预览)
- [常见问题](#常见问题)
- [架构概览](#架构概览)
- [隐私与安全](#隐私与安全)
- [本地化](#本地化)
- [贡献](#贡献)
- [许可证](#许可证)

---

## 为什么需要它

在使用 DeepSeek API 进行开发时，余额用尽是常见痛点——它通常发生在你最不想停下来的时刻。每次查余额都要登录网页、点进控制台，流程繁琐。

这个菜单栏小工具把余额直接放在你眼前。看一眼菜单栏就够了。

## 功能

- **菜单栏实时显示** — 币种、总余额、赠送余额、充值余额一目了然
- **自动刷新** — 可配置 60–3600 秒轮询间隔，默认 30 分钟
- **钥匙串存储** — API Key 写入 macOS Keychain，每次按需读取，绝不在内存中缓存
- **中英双语** — 支持英文和简体中文，跟随系统语言自动切换
- **零依赖** — 纯 SwiftUI + Foundation + Combine + Security 框架，无需 SPM / CocoaPods / Carthage
- **沙盒安全** — 启用 App Sandbox，仅开放外网访问

## 快速开始

```bash
# 1. 从 Releases 下载最新 .dmg
# 2. 拖入 /Applications，启动
# 3. 菜单栏 → 设置 → 粘贴 API Key → 应用
```

完成。余额即刻出现在菜单栏上。

## 安装

### 下载安装（推荐）

从 [Releases](https://github.com/zoisite/DeepSeekStatusBar/releases) 页面下载最新 `.dmg`，拖入 `/Applications` 文件夹后启动即可。

> 首次启动时，macOS 可能弹出安全提示。在「系统设置 → 隐私与安全性」中允许运行即可。

### 从源码构建

```bash
git clone https://github.com/zoisite/DeepSeekStatusBar.git
cd DeepSeekStatusBar
xcodebuild -project DeepSeekStatusBar.xcodeproj -scheme DeepSeekStatusBar build
```

构建产物路径：`DerivedData/.../Build/Products/Debug/DeepSeekStatusBar.app`，移至 `/Applications` 或直接运行。

无需安装任何外部依赖，项目完全自包含。

## 使用方法

| 步骤 | 操作 |
|------|------|
| 1 | 启动应用，菜单栏出现余额信息 |
| 2 | 首次启动显示 **「请设置 API Key」** |
| 3 | 点击菜单栏图标 → **设置…** → 粘贴你的 [DeepSeek API Key](https://platform.deepseek.com/api_keys) → 点击 **应用** |
| 4 | 应用立即拉取余额，之后按配置的间隔自动刷新 |

### 菜单栏面板

| 项目 | 说明 | 快捷键 |
|------|------|--------|
| 余额行 | 币种、总余额、赠送余额、充值余额 | - |
| 手动刷新 | 立即拉取最新余额 | - |
| 设置… | 打开设置窗口 | `⌘,` |
| 退出 | 退出应用 | `⌘Q` |

### 设置选项

| 分类 | 说明 |
|------|------|
| 账户 | 输入或更新 API Key（写入 Keychain） |
| 刷新间隔 | 60–3600 秒，默认 1800（30 分钟） |

> 点击 **「应用」** 之前所有修改仅为本地草稿——点击后才会写入 Keychain 并重置定时器。

## 常见问题

<details>
<summary><strong>支持 macOS 14 或更低版本吗？</strong></summary>

目前最低支持 macOS 26.0。`MenuBarExtra` 是 macOS 26 引入的 SwiftUI API，在旧版本中不可用。未来可能考虑用 `NSStatusBar` 兼容旧系统。
</details>

<details>
<summary><strong>API Key 安全吗？</strong></summary>

安全。Key 存储在 macOS Keychain 中（`kSecClassGenericPassword`，`kSecAttrAccessibleAfterFirstUnlock`），每次刷新时按需读取，不会持久保存在 ViewModel 属性或内存缓存中。详见 [隐私与安全](#隐私与安全)。
</details>

<details>
<summary><strong>多久刷新一次合适？</strong></summary>

默认 30 分钟对大多数场景足够。高频调用时建议设为 600 秒（10 分钟）。最短间隔为 60 秒，请注意 DeepSeek API 的速率限制。
</details>

<details>
<summary><strong>换了 API Key 后数据不更新？</strong></summary>

在设置中粘贴新的 API Key 后，务必点击 **「应用」** 按钮。仅粘贴而不点击应用不会生效——这是草稿-应用模式的设计。
</details>

<details>
<summary><strong>网络断了会怎样？</strong></summary>

网络错误不会清空已有的余额数据。菜单栏中过期的数据总好过没有数据。网络恢复后下次定时刷新会自动更新。
</details>

<details>
<summary><strong>如何彻底卸载？</strong></summary>

将 `DeepSeekStatusBar.app` 拖入废纸篓。API Key 存储在 Keychain 中，如需一并清除，打开「钥匙串访问」搜索 `xin.iristack.deepseek.status.bar` 并删除。
</details>

## 架构概览

```
MenuBarExtra  →  BillingViewModel  →  BillingService  →  DeepSeek API
    (App)          @MainActor              (struct)       /user/balance
                  @Published 状态          URLSession
                       │
                       ▼
                KeychainService
                    (enum)
```

**MVVM** 架构，共 6 个源文件：

| 文件 | 职责 |
|------|------|
| `DeepSeekModels.swift` | API 响应模型 — `BalanceResponse` + `BalanceInfo`（Decodable） |
| `KeychainService.swift` | 通过 Security 框架封装 Keychain 增删查 |
| `BillingService.swift` | HTTP 客户端 — `GET /user/balance`，Bearer 认证，单例 URLSession |
| `BillingViewModel.swift` | `@MainActor ObservableObject` — 状态管理、定时器、一次性数据迁移 |
| `SettingsView.swift` | 设置界面 — 草稿-应用模式，SecureField 输入 |
| `DeepSeekStatusBarApp.swift` | `@main` 入口 — `MenuBarExtra` + `Settings` 场景 |

更多技术细节见 [CLAUDE.md](CLAUDE.md)（面向 AI 助手的开发文档）。

## 隐私与安全

- API Key 仅存储在 **macOS Keychain**（`kSecClassGenericPassword`，`kSecAttrAccessibleAfterFirstUnlock`）
- 每次刷新按需读取 Key，不持久化在任何属性或内存缓存中
- 仅发起一个外网请求：`GET https://api.deepseek.com/user/balance`（Bearer 认证）
- **零数据采集**：无埋点、无遥测、无第三方 SDK
- App Sandbox 已启用，仅开放外网访问权限

## 本地化

共 26 条本地化字符串，源语言为英文，已翻译为简体中文（zh-Hans）。欢迎贡献更多语言。

## 贡献

欢迎提 Issue 和 Pull Request！

- 新功能请先开 Issue 讨论方案
- Bug 修复可直接提 PR
- 翻译贡献请参考 `Localizable.xcstrings`

## 许可证

[MIT License](LICENSE) — 自由使用、修改、分发。

---

<p align="center">
  <img src="./image/038d377f8d9c47ec51a83e99f57cda7b.jpg" alt="Platform">
</p>

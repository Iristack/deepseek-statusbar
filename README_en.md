# DeepSeek Status Bar

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2026%2B-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.10%2B-F05138?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green?logo=open-source-initiative" alt="License">
  <img src="https://img.shields.io/github/stars/zoisite/DeepSeekStatusBar?style=social" alt="GitHub Stars">
</p>

**DeepSeek Status Bar** is a lightweight macOS menu bar app that keeps your [DeepSeek API](https://platform.deepseek.com) account balance visible at all times. Zero dependencies, zero configuration — just launch and go.

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Download (Recommended)](#download-recommended)
  - [Build from Source](#build-from-source)
- [Usage](#usage)
- [Preview](#preview)
- [FAQ](#faq)
- [Architecture](#architecture)
- [Privacy & Security](#privacy--security)
- [Localization](#localization)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Exists

Running out of API credits mid-development is painful — and it always happens at the worst time. Checking your balance normally means logging into a web dashboard and navigating through menus.

This menu bar app puts your balance right where you can see it. One glance at the menu bar is all it takes.

## Features

- **At-a-glance balance** — currency, total, granted, and top-up breakdown right in the menu bar
- **Auto-refresh** — configurable polling interval from 60 to 3600 seconds (default: 30 minutes)
- **Keychain-backed** — API key stored in macOS Keychain, read on-demand, never held in memory
- **Bilingual** — English and Simplified Chinese, follows system language automatically
- **Zero dependencies** — pure SwiftUI + Foundation + Combine + Security framework. No SPM, CocoaPods, or Carthage
- **Sandboxed** — App Sandbox enabled, only outgoing network access granted

## Quick Start

```bash
# 1. Download the latest .dmg from Releases
# 2. Drag to /Applications, launch
# 3. Menu bar → Settings → paste API Key → Apply
```

Done. Your balance appears in the menu bar immediately.

## Installation

### Download (Recommended)

Download the latest `.dmg` from the [Releases](https://github.com/zoisite/DeepSeekStatusBar/releases) page. Drag the app to `/Applications` and launch.

> On first launch, macOS may show a security warning. Allow it in **System Settings → Privacy & Security**.

### Build from Source

```bash
git clone https://github.com/zoisite/DeepSeekStatusBar.git
cd DeepSeekStatusBar
xcodebuild -project DeepSeekStatusBar.xcodeproj -scheme DeepSeekStatusBar build
```

The built app is at `DerivedData/.../Build/Products/Debug/DeepSeekStatusBar.app`. Move it to `/Applications` or run it directly.

No external dependencies needed — the project is fully self-contained.

## Usage

| Step | Action |
|------|--------|
| 1 | Launch the app — balance info appears in the menu bar |
| 2 | First launch shows **"Please set API Key"** |
| 3 | Click menu bar icon → **Settings…** → paste your [DeepSeek API Key](https://platform.deepseek.com/api_keys) → click **Apply** |
| 4 | The app fetches your balance immediately, then refreshes automatically on the configured interval |

### Menu Bar Panel

| Item | Description | Shortcut |
|------|-------------|----------|
| Balance rows | Currency, total balance, granted balance, top-up balance | - |
| Refresh | Manually fetch the latest balance | - |
| Settings… | Open the Settings window | `⌘,` |
| Quit | Quit the app | `⌘Q` |

### Settings

| Section | Description |
|---------|-------------|
| Account | Enter or update your API key (stored in Keychain) |
| Refresh Interval | 60–3600 seconds, default 1800 (30 minutes) |

> Changes are **draft-only** until you click **Apply** — this triggers the Keychain write and resets the timer.

## FAQ

<details>
<summary><strong>Does it support macOS 14 or earlier?</strong></summary>

Currently, macOS 26.0 is the minimum requirement. `MenuBarExtra` is a SwiftUI API introduced in macOS 26 and is unavailable on older systems. A future version may add `NSStatusBar` support for backward compatibility.
</details>

<details>
<summary><strong>Is my API key safe?</strong></summary>

Yes. The key is stored in the macOS Keychain (`kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlock`). It is read on-demand for each refresh and never persisted in a ViewModel property or in-memory cache. See [Privacy & Security](#privacy--security).
</details>

<details>
<summary><strong>What refresh interval should I use?</strong></summary>

The default 30 minutes works well for most use cases. For high-frequency API usage, consider 600 seconds (10 minutes). The minimum is 60 seconds — be mindful of DeepSeek API rate limits.
</details>

<details>
<summary><strong>I changed my API key but the balance didn't update?</strong></summary>

After pasting a new API key in Settings, you must click **Apply**. Pasting alone does not commit the change — this is by design (draft-and-apply pattern).
</details>

<details>
<summary><strong>What happens when the network is down?</strong></summary>

Network errors do not clear existing balance data — stale data in the menu bar is better than no data. The next successful auto-refresh will update the display automatically.
</details>

<details>
<summary><strong>How do I fully uninstall?</strong></summary>

Drag `DeepSeekStatusBar.app` to the Trash. The API key is stored in Keychain — to remove it as well, open **Keychain Access**, search for `xin.iristack.deepseek.status.bar`, and delete the entry.
</details>

## Architecture

```
MenuBarExtra  →  BillingViewModel  →  BillingService  →  DeepSeek API
    (App)          @MainActor              (struct)       /user/balance
                  @Published state         URLSession
                       │
                       ▼
                KeychainService
                    (enum)
```

**MVVM** with 6 source files:

| File | Role |
|------|------|
| `DeepSeekModels.swift` | API response models — `BalanceResponse` + `BalanceInfo` (Decodable) |
| `KeychainService.swift` | Keychain CRUD via Security framework |
| `BillingService.swift` | HTTP client — `GET /user/balance` with Bearer auth, singleton URLSession |
| `BillingViewModel.swift` | `@MainActor ObservableObject` — state, timer, one-shot data migration |
| `SettingsView.swift` | Settings UI — draft-and-apply, SecureField input |
| `DeepSeekStatusBarApp.swift` | `@main` entry point — `MenuBarExtra` + `Settings` scenes |

For detailed technical documentation, see [CLAUDE.md](CLAUDE.md) (AI-assistant-oriented dev docs).

## Privacy & Security

- API key stored exclusively in **macOS Keychain** (`kSecClassGenericPassword`, `kSecAttrAccessibleAfterFirstUnlock`)
- Key read on-demand per refresh — never persisted in any property or in-memory cache
- Exactly one outbound network call: `GET https://api.deepseek.com/user/balance` (Bearer auth)
- **Zero data collection**: no analytics, no telemetry, no third-party SDKs
- App Sandbox enabled with only outgoing network entitlement

## Localization

26 localized strings in English (source) and Simplified Chinese (zh-Hans). Contributions for additional languages are welcome.

## Contributing

Issues and pull requests are welcome!

- For new features, please open an issue first to discuss the approach
- Bug fixes can go straight to PR
- For translations, see `Localizable.xcstrings`

## License

[MIT License](LICENSE) — use, modify, and distribute freely.

---

<p align="center">
  <img src="./image/038d377f8d9c47ec51a83e99f57cda7b.jpg" alt="Platform">
</p>

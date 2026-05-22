# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
xcodebuild -project DeepSeekStatusBar.xcodeproj -scheme DeepSeekStatusBar build
```

No external dependencies — SwiftUI + Foundation + Combine + Security (Keychain). No SPM, CocoaPods, or Carthage. Deployment target: macOS 26.0.

## Architecture

macOS **menu bar app** (`MenuBarExtra`) displaying DeepSeek API account balance. **MVVM** with 6 source files:

- **`DeepSeekModels.swift`** — `BalanceResponse` + `BalanceInfo` (Decodable, snake_case CodingKeys).
- **`KeychainService.swift`** — `enum` wrapping `SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete`. `save()` auto-deletes before add for overwrite semantics. `loadApiKey()` migrates legacy key items transparently (old service name `xin.iristack.deepseek--status-bar` → current `xin.iristack.deepseek.status.bar`).
- **`BillingService.swift`** — Singleton struct + `BillingServiceError` enum (LocalizedError: `missingAPIKey`, `networkError`, `httpError`, `invalidResponse`). `fetchBalance(apiKey:)` calls `GET https://api.deepseek.com/user/balance` with Bearer auth. Reuses a single `URLSession` with 30s/60s timeouts.
- **`BillingViewModel.swift`** — `@MainActor ObservableObject`. Published: `balanceInfos`, `isLoading`, `errorMessage`. `refresh()` has a concurrency guard (`guard !isLoading else { return }`). Persists only `@AppStorage("refreshIntervalSeconds")` (non-sensitive). API key read from Keychain on-demand via `KeychainService.loadApiKey()`. Auto-refresh timer. Network errors do **not** clear existing `balanceInfos`. Legacy `UserDefaults` → Keychain migration in `init()`.
- **`SettingsView.swift`** — `NavigationSplitView` with sidebar (Account/Refresh Settings) + `Form` detail pane. Draft-and-apply: changes committed only on explicit "Apply" via `KeychainService.save()` + `Notification.Name.settingsDidApply`. Keychain save errors shown as red text. `draftRefreshInterval` bound via custom `Binding<String>` with range validation (60–3600).
- **`DeepSeekStatusBarApp.swift`** — `@main` App with `MenuBarExtra` scene + `Settings` scene. `MenuBarExtraContent` is a separate `View` struct inside the same file (balance rows, manual refresh button with `ProgressView`, SettingsLink, Quit button).

## Data flow

```
init() → UserDefaults→Keychain migration (one-shot) → load @AppStorage interval → start timer → refresh()
  → KeychainService.loadApiKey()  (handles legacy service-name migration transparently)
    → BillingService.shared.fetchBalance(apiKey:)
      → GET api.deepseek.com/user/balance → decode BalanceResponse
    → update @Published state → MenuBarExtra.label reads statusText
```

Settings Apply → `KeychainService.save()` + post `.settingsDidApply` notification → ViewModel restarts timer.

## Key details

- **Bundle ID**: `xin.iristack.deepseek.status.bar`.
- **Keychain service name**: `xin.iristack.deepseek.status.bar` (legacy: `xin.iristack.deepseek--status-bar`; `loadApiKey()` migrates on read via `migrateIfNeeded()`).
- **Localization**: 26 entries in `Localizable.xcstrings` (en source + zh-Hans). View strings use SwiftUI `Text` (auto-localized). Programmatic strings use `String(localized:)`.
- **App Sandbox**: Enabled. Outgoing network enabled. No special Keychain entitlement needed — sandbox auto-scopes to bundle ID.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** project-wide. `BillingService` is a struct so unaffected.
- **File system sync**: `PBXFileSystemSynchronizedRootGroup` — new Swift files auto-discovered.
- Timer/notification closures use `[weak self]`.
- `KeychainService.loadApiKey()` is called on-demand (in `statusText` computed property and `refresh()`), not cached in a ViewModel property, minimizing memory exposure.
- This file is gitignored (`.gitignore` line: `CLAUDE.md`). User-facing documentation is in `README.md` (zh) and `README_en.md` (en).

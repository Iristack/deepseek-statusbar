import Foundation
import Combine
import SwiftUI

@MainActor
final class BillingViewModel: ObservableObject {
    @Published var balanceInfos: [BalanceInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @AppStorage("refreshIntervalSeconds") private var refreshIntervalSeconds: Int = 1800

    private var timer: Timer?
    private var settingsObserver: NSObjectProtocol?

    init() {
        let legacyKey = "deepseekApiKey"
        if let oldKey = UserDefaults.standard.string(forKey: legacyKey), !oldKey.isEmpty {
            let currentKey = KeychainService.loadApiKey() ?? ""
            if currentKey.isEmpty {
                KeychainService.save(apiKey: oldKey)
            }
            UserDefaults.standard.removeObject(forKey: legacyKey)
        }

        let interval = TimeInterval(refreshIntervalSeconds)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .settingsDidApply,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.restartTimer()
            }
        }

        Task { await refresh() }
    }

    deinit {
        timer?.invalidate()
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        let newInterval = TimeInterval(refreshIntervalSeconds)
        timer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let key = (KeychainService.loadApiKey() ?? "").trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else {
                balanceInfos = []
                throw BillingServiceError.missingAPIKey
            }
            let response = try await BillingService.shared.fetchBalance(apiKey: key)
            if response.isAvailable {
                balanceInfos = response.balanceInfos
                errorMessage = nil
            } else {
                if !response.balanceInfos.isEmpty {
                    balanceInfos = response.balanceInfos
                }
                errorMessage = String(localized: "Account balance unavailable",
                                      comment: "Error when API reports balance is unavailable")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var statusText: String {
        let storedKey = KeychainService.loadApiKey() ?? ""
        let hasKey = !storedKey.isEmpty

        if isLoading {
            return String(localized: "Loading\u{2026}", comment: "Menu bar status while loading")
        }
        if errorMessage != nil, balanceInfos.isEmpty {
            return String(localized: "Error", comment: "Menu bar status on error")
        }
        if balanceInfos.isEmpty && !hasKey {
            return String(localized: "Please set API Key", comment: "Menu bar prompt when API key is not set")
        }
        if balanceInfos.isEmpty && hasKey {
            return String(localized: "No balance data", comment: "Menu bar status when no balance info available")
        }
        return balanceInfos.map { "\($0.currency) \($0.totalBalance)" }.joined(separator: ", ")
    }
}

import SwiftUI

@main
struct DeepSeekStatusBarApp: App {
    @StateObject private var billingVM = BillingViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraContent(viewModel: billingVM)
        } label: {
            Text(billingVM.statusText)
        }

        Settings {
            SettingsView()
        }
    }
}

struct MenuBarExtraContent: View {
    @ObservedObject var viewModel: BillingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = viewModel.errorMessage, viewModel.balanceInfos.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            } else if viewModel.balanceInfos.isEmpty && !viewModel.isLoading {
                Text("No balance data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.balanceInfos) { info in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Currency: \(info.currency)")
                            Text("Balance: \(info.totalBalance)")
                            Text("Granted: \(info.grantedBalance)")
                            Text("Top-up: \(info.toppedUpBalance)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    Divider()
                }
            }

            Divider()

            // New manual refresh button
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }
                    Text("Refresh")
                }
            }
            .disabled(viewModel.isLoading)

            Divider()

            SettingsLink {
                Text("Settings…")
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(minWidth: 240)
    }
}

import SwiftUI

struct SettingsView: View {
    @AppStorage("refreshIntervalSeconds") private var savedRefreshInterval: Int = 1800

    @State private var draftApiKey: String = ""
    @State private var draftRefreshInterval: Int = 1800

    @State private var selectedItem: SettingsItem = .account
    @State private var saveError: String?

    enum SettingsItem: String, CaseIterable, Identifiable {
        case account = "Account"
        case refresh = "Refresh Settings"
        var id: String { rawValue }
    }

    private var refreshBinding: Binding<String> {
        Binding<String>(
            get: { String(draftRefreshInterval) },
            set: { newValue in
                if let value = Int(newValue), value >= 60, value <= 3600 {
                    draftRefreshInterval = value
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                ForEach(SettingsItem.allCases) { item in
                    Label(LocalizedStringKey(item.rawValue), systemImage: item.systemImage)
                        .tag(item)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 200)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                Form {
                    switch selectedItem {
                    case .account:
                        Section("API Key") {
                            SecureField("DeepSeek API Key", text: $draftApiKey)
                                .textFieldStyle(.roundedBorder)
                            Text("Click \"Apply\" at the bottom right to take effect.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .refresh:
                        Section("Refresh Settings") {
                            HStack {
                                Text("Interval (seconds):")
                                TextField("", text: refreshBinding)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Text("Enter an integer between 60 and 3600, then click \"Apply\" to reset the timer.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)

                if let error = saveError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                HStack {
                    Spacer()
                    Button("Apply") {
                        applyChanges()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding([.trailing, .bottom])
            }
        }
        .frame(minWidth: 500, minHeight: 300)
        .onAppear {
            draftApiKey = KeychainService.loadApiKey() ?? ""
            draftRefreshInterval = savedRefreshInterval
        }
    }

    private func applyChanges() {
        let status = KeychainService.save(apiKey: draftApiKey)
        if status != errSecSuccess {
            saveError = String(localized: "Failed to save API Key to Keychain (error \(status)).",
                               comment: "Keychain save error alert")
            return
        }
        saveError = nil
        savedRefreshInterval = draftRefreshInterval
        NotificationCenter.default.post(name: .settingsDidApply, object: nil)
    }
}

extension Notification.Name {
    static let settingsDidApply = Notification.Name("SettingsDidApply")
}

private extension SettingsView.SettingsItem {
    var systemImage: String {
        switch self {
        case .account: return "key"
        case .refresh: return "arrow.clockwise"
        }
    }
}


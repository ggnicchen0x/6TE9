import SwiftUI

struct CompassHomeView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    appCard
                    deviceStatusCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button { onOpenLogs() } label: {
                            Image(systemName: "apple.terminal.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                        Button { onOpenSettings() } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
        }
    }

    private var appCard: some View {
        HStack(spacing: 14) {
            AppLogo(size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("Compass")
                    .font(.body.weight(.bold))
                Text("Your iPhone, ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Supported")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12), in: Capsule())

                Text("v\(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var deviceStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device status")
                .font(.headline.weight(.bold))
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                statusRow(icon: "iphone", label: "Hardware model", value: AppInfo.displayMachineName)
                Divider().padding(.leading, 44)
                statusRow(icon: "gear", label: "iOS Version", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                Divider().padding(.leading, 44)
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28)
                    Text("Exploit compatibility")
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(appState.isSupported ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(appState.isSupported ? "Supported" : "Unsupported")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(appState.isSupported ? .green : .red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
    }

    private func statusRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}

import SwiftUI

struct FFAccountView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var entranceShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard
                    deviceInfoCard
                    appInfoCard
                    supportCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .opacity(entranceShown ? 1 : 0)
            .offset(y: entranceShown ? 0 : 10)
            .onAppear {
                guard !entranceShown, !reduceMotion else {
                    entranceShown = true
                    return
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    entranceShown = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onOpenSettings()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Compass User")
                    .font(.title3.weight(.bold))
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.caption)
                    Text("Active")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    AppTheme.accent.opacity(0.12),
                    in: Capsule()
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var deviceInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "iphone", title: "Device")
            infoRow(label: "Model", value: AppInfo.displayMachineName)
            Divider()
            infoRow(label: "iOS Version", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
            Divider()
            infoRow(label: "Backend", value: SandboxAccess.backend.displayName)
            Divider()
            infoRow(label: "App Group", value: appGroupStatus)
            Divider()
            HStack {
                Text("Supported")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: appState.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.isSupported ? .green : .red)
                    Text(appState.isSupported ? "Yes" : "No")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(appState.isSupported ? .green : .red)
                }
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "app.fill", title: "App Info")
            infoRow(label: "Version", value: appVersion)
            Divider()
            infoRow(label: "Target Games", value: "Free Fire MAX, Free Fire TH")
            Divider()
            HStack {
                Text("Patches Available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(FFPatchCatalog.allEntries().count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "questionmark.circle", title: "Support")
            supportRow(icon: "arrow.counterclockwise", title: "Respring Device") {
                RespringButton()
            }
            Divider()
            NavigationLink {
                SandboxDiagnosticsView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "stethoscope")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 24)
                    Text("Sandbox Diagnostics")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            Divider()
            NavigationLink {
                LogView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "apple.terminal.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 24)
                    Text("View Logs")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.subheadline.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func supportRow<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)
            content()
            Spacer()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var appGroupStatus: String {
        guard SandboxAccess.needsWorseQuery else { return "Not Required" }
        return SandboxAccess.appGroup ?? "Missing"
    }
}

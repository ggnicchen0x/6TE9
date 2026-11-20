import SwiftUI

struct FFAccountView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var entranceShown = false
    @State private var licenseKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoggedIn = ByteAuthService.shared.isLoggedIn
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard
                    if isLoggedIn {
                        licenseInfoCard
                        logoutCard
                    } else {
                        loginCard
                    }
                    deviceInfoCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Profile")
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
                    Button { onOpenSettings() } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .alert("Login Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
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
                    Image(systemName: isLoggedIn ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(isLoggedIn ? AppTheme.accent : .secondary)
                        .font(.caption)
                    Text(isLoggedIn ? "Licensed" : "Not Logged In")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isLoggedIn ? AppTheme.accent : .secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (isLoggedIn ? AppTheme.accent : Color.gray).opacity(0.12),
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

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader(icon: "key.fill", title: "License Login")

            VStack(alignment: .leading, spacing: 8) {
                Text("LICENSE KEY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent.opacity(0.7))

                    TextField("", text: $licenseKey, prompt: Text("BYTE-XXXX-XXXX-XXXX").foregroundColor(.secondary.opacity(0.5)))
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit { performLogin() }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            licenseKey.isEmpty ? Color(uiColor: .separator) : AppTheme.accent.opacity(0.4),
                            lineWidth: 0.5
                        )
                )
            }

            Button(action: performLogin) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.body.weight(.semibold))
                    }
                    Text(isLoading ? "Authenticating..." : "Login")
                        .font(.body.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            licenseKey.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AppTheme.accent.opacity(0.3)
                                : AppTheme.accent
                        )
                )
            }
            .disabled(isLoading || licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var licenseInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "key.fill", title: "License")
            if let key = ByteAuthService.shared.savedLicenseKey {
                infoRow(label: "Key", value: key)
            }
            Divider()
            infoRow(label: "Status", value: "Active")
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var logoutCard: some View {
        Button(role: .destructive) {
            ByteAuthService.shared.logout()
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoggedIn = false
            }
            NotificationCenter.default.post(name: .byteDidLogout, object: nil)
        } label: {
            HStack {
                Spacer()
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.body.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.red)
            .padding(.vertical, 14)
            .background(
                Color.red.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
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

    private func performLogin() {
        let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            let result = await ByteAuthService.shared.login(licenseKey: key)
            await MainActor.run {
                isLoading = false
                if result.success {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoggedIn = true
                    }
                } else {
                    errorMessage = result.error
                    showError = true
                }
            }
        }
    }
}

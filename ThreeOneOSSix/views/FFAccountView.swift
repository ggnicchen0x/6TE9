import SwiftUI

private let cardFill = Color(white: 0.11)

struct FFAccountView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var entranceShown = false
    @State private var licenseKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoggedIn = ByteAuthService.shared.isLoggedIn
    @AppStorage("selectedGame") private var selectedGame = FFGameVariant.ffth.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoggedIn {
                        profileCardLoggedIn
                        licenseInfoCard
                        gameSelectionCard
                        logoutCard
                    } else {
                        profileCardLoggedOut
                        loginCard
                        getKeyCard
                    }
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
                            .foregroundStyle(AppTheme.accent)
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

    // MARK: - Logged Out State

    private var profileCardLoggedOut: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.16))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("No membership")
                .font(.title3.weight(.bold))

            Text("Activate your key to use Compass")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(accentBarCard(cornerRadius: 16))
    }

    private var getKeyCard: some View {
        Button {
            if let url = URL(string: "https://t.me/nxvoid12") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.20), AppTheme.accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: "key.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Get Key")
                        .font(.subheadline.weight(.semibold))
                    Text("Contact @nxvoid12 on Telegram")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(accentBarCard(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logged In State

    private var profileCardLoggedIn: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text("Compass User")
                .font(.title3.weight(.bold))

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Licensed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(accentBarCard(cornerRadius: 16))
    }

    private var licenseInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "key.fill", title: "License")
            if let key = ByteAuthService.shared.savedLicenseKey {
                infoRow(label: "Key", value: key)
            }
            Divider()
            infoRow(label: "Status", value: "Active", valueColor: .green)
        }
        .padding(16)
        .background(
            cardFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var gameSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(white: 0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: "gamecontroller.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game")
                        .font(.subheadline.weight(.semibold))
                    Text("Choose which game's products appear in the list.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                gameOption(
                    id: FFGameVariant.ffth.rawValue,
                    name: "Free Fire",
                    assetName: "FFIcon",
                    color: AppTheme.accent
                )
                gameOption(
                    id: FFGameVariant.ffmax.rawValue,
                    name: "Free Fire MAX",
                    assetName: "FFMaxIcon",
                    color: AppTheme.accent
                )
            }

            launchButton
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.015), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
    }

    private var launchButton: some View {
        Button {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/\(selectedGame)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Launch \(selectedGameVariant?.shortName ?? "Game")")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.accent)
            )
        }
    }

    private var selectedGameVariant: FFGameVariant? {
        FFGameVariant(rawValue: selectedGame)
    }

    private func gameOption(id: String, name: String, assetName: String, color: Color) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedGame = id
            }
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            selectedGame == id
                                ? color.opacity(0.15)
                                : Color(white: 0.16)
                        )
                        .frame(height: 70)
                        .overlay(
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        )

                    if selectedGame == id {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(6)
                    }
                }

                Text(name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(selectedGame == id ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        selectedGame == id ? color : Color.white.opacity(0.08),
                        lineWidth: selectedGame == id ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Login Card

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
                        .fill(Color(white: 0.16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            licenseKey.isEmpty ? Color.white.opacity(0.08) : AppTheme.accent.opacity(0.4),
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
            cardFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    // MARK: - Logout

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
            .foregroundStyle(AppTheme.accent)
            .padding(.vertical, 14)
            .background(
                AppTheme.accent.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
    }

    // MARK: - Shared Components

    private func accentBarCard(cornerRadius: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(cardFill)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            HStack(spacing: 0) {
                AppTheme.accent
                    .frame(width: 3.5)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
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

    private func infoRow(label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor ?? .primary)
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

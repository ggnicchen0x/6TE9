import SwiftUI
import PhotosUI

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
    @State private var showNamePrompt = false
    @State private var nameInput = ""
    @State private var profileImage: UIImage? = ByteAuthService.shared.profileImage
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @AppStorage("selectedGame") private var selectedGame = FFGameVariant.ffth.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void
    let onLaunchGame: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoggedIn {
                        profileCardLoggedIn
                        licenseInfoCard
                        gameSelectionCard
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
            .navigationTitle(language.text("account.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(white: 0.06), for: .navigationBar)
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
            .alert(language.text("account.login_failed"), isPresented: $showError) {
                Button(language.text("common.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? language.text("account.unknown_error"))
            }
            .alert(language.text("account.welcome"), isPresented: $showNamePrompt) {
                TextField(language.text("account.name_placeholder"), text: $nameInput)
                Button(language.text("account.save")) {
                    let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        ByteAuthService.shared.setUserName(trimmed)
                    }
                }
                Button(language.text("account.skip"), role: .cancel) {}
            } message: {
                Text(language.text("account.name_prompt"))
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

            Text(language.text("account.no_membership"))
                .font(.title3.weight(.bold))

            Text(language.text("account.activate_key"))
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
                    Text(language.text("account.get_key"))
                        .font(.subheadline.weight(.semibold))
                    Text(language.text("account.get_key_subtitle"))
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
            Button {
                showPhotoPicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let img = profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.accent.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(.white)
                            )
                    }

                    ZStack {
                        Circle()
                            .fill(Color(white: 0.12))
                            .frame(width: 26, height: 26)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        let cropped = cropToSquare(img)
                        ByteAuthService.shared.setProfileImage(cropped)
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                profileImage = cropped
                            }
                        }
                    }
                }
            }

            Text(ByteAuthService.shared.userName ?? language.text("account.default_name"))
                .font(.title3.weight(.bold))

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text(language.text("account.licensed"))
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

    private func cropToSquare(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let x = (image.size.width - side) / 2
        let y = (image.size.height - side) / 2
        let rect = CGRect(x: x, y: y, width: side, height: side)
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private var licenseInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "key.fill", title: language.text("account.license"))
            if let key = ByteAuthService.shared.savedLicenseKey {
                infoRow(label: language.text("account.key"), value: key)
            }
            Divider()
            if ByteAuthService.shared.isLifetime {
                infoRow(label: language.text("account.expiry"), value: language.text("account.lifetime"), valueColor: .green)
            } else if let days = ByteAuthService.shared.daysRemaining {
                infoRow(label: language.text("account.expiry"), value: language.text("account.days", days), valueColor: days > 7 ? .green : .orange)
            } else {
                infoRow(label: language.text("account.expiry"), value: language.text("account.active"), valueColor: .green)
            }
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
                    Text(language.text("account.game"))
                        .font(.subheadline.weight(.semibold))
                    Text(language.text("account.game_subtitle"))
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
            onLaunchGame()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.subheadline.weight(.semibold))
                Text(language.text("account.launch", selectedGameVariant?.shortName ?? language.text("account.game")))
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
            cardHeader(icon: "key.fill", title: language.text("account.license_login"))

            VStack(alignment: .leading, spacing: 8) {
                Text(language.text("account.license_key_label"))
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
                    Text(isLoading ? language.text("account.authenticating") : language.text("account.login"))
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
                    if ByteAuthService.shared.userName == nil {
                        nameInput = ""
                        showNamePrompt = true
                    }
                } else {
                    errorMessage = result.error
                    showError = true
                }
            }
        }
    }
}

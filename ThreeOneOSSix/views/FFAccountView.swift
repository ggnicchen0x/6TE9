import SwiftUI
import PhotosUI

private let cardFill = AppTheme.cardFill

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
    @State private var glowRotation: Double = 0
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
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
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
            .onReceive(NotificationCenter.default.publisher(for: .byteDidLogin)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoggedIn = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .byteDidLogout)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoggedIn = false
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
            .overlay {
                if showNamePrompt {
                    namePromptOverlay
                }
            }
        }
    }

    // MARK: - Name Prompt Overlay

    private var namePromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent)
                }

                Text(language.text("account.welcome"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(language.text("account.name_prompt"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                TextField(language.text("account.name_placeholder"), text: $nameInput)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 4)

                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showNamePrompt = false
                        }
                    } label: {
                        Text(language.text("account.skip"))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Button {
                        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            ByteAuthService.shared.setUserName(trimmed)
                        }
                        withAnimation(.easeOut(duration: 0.2)) {
                            showNamePrompt = false
                        }
                    } label: {
                        Text(language.text("account.save"))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(white: 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }

    // MARK: - Logged Out State

    private var profileCardLoggedOut: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Color(white: 0.4))
            }

            Text(language.text("account.no_membership"))
                .font(.title3.weight(.medium))

            Text(language.text("account.activate_key"))
                .font(.caption)
                .foregroundStyle(Color(white: 0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AccentBarCard(cornerRadius: 16))
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
                                colors: [AppTheme.accent.opacity(0.18), AppTheme.accent.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: "key.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("account.get_key"))
                        .font(.subheadline.weight(.medium))
                    Text(language.text("account.get_key_subtitle"))
                        .font(.caption)
                        .foregroundStyle(Color(white: 0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(white: 0.3))
            }
            .padding(14)
            .background(AccentBarCard(cornerRadius: 14))
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
                    ZStack {
                        if profileImage != nil {
                            glowRing
                        }

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
                                        colors: [AppTheme.accent.opacity(0.7), AppTheme.accent.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.9))
                                )
                        }
                    }

                    ZStack {
                        Circle()
                            .fill(Color(white: 0.1))
                            .frame(width: 26, height: 26)
                        Circle()
                            .strokeBorder(Color(white: 0.2), lineWidth: 0.5)
                            .frame(width: 26, height: 26)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(white: 0.7))
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
                .font(.title3.weight(.medium))

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.statusGreen)
                    .font(.caption)
                Text(language.text("account.licensed"))
                    .font(.caption)
                    .foregroundStyle(AppTheme.statusGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.statusGreen.opacity(0.10), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AccentBarCard(cornerRadius: 16))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }
        }
    }

    // MARK: - Animated Glow Ring

    private var glowRing: some View {
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        AppTheme.accent.opacity(0.0),
                        AppTheme.accent.opacity(0.6),
                        AppTheme.accent,
                        AppTheme.accent.opacity(0.6),
                        AppTheme.accent.opacity(0.0)
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                lineWidth: 2.5
            )
            .frame(width: 94, height: 94)
            .rotationEffect(.degrees(glowRotation))
            .blur(radius: 3)
            .overlay(
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                AppTheme.accent.opacity(0.0),
                                AppTheme.accent.opacity(0.4),
                                AppTheme.accent.opacity(0.8),
                                AppTheme.accent.opacity(0.4),
                                AppTheme.accent.opacity(0.0)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(glowRotation))
            )
    }

    private func cropToSquare(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let x = (image.size.width - side) / 2
        let y = (image.size.height - side) / 2
        let rect = CGRect(x: x, y: y, width: side, height: side)
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - License Info

    private var licenseInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(icon: "key.fill", title: language.text("account.license"))
            if let key = ByteAuthService.shared.savedLicenseKey {
                infoRow(label: language.text("account.key"), value: key, valueFont: .caption.monospaced())
            }
            Divider().overlay(Color(white: 0.15))
            if ByteAuthService.shared.isLifetime {
                infoRow(label: language.text("account.expiry"), value: language.text("account.lifetime"), valueColor: AppTheme.statusGreen)
            } else if let days = ByteAuthService.shared.daysRemaining {
                infoRow(label: language.text("account.expiry"), value: language.text("account.days", days), valueColor: days > 7 ? AppTheme.statusGreen : .orange)
            } else {
                infoRow(label: language.text("account.expiry"), value: language.text("account.active"), valueColor: AppTheme.statusGreen)
            }
        }
        .padding(16)
        .background(
            cardFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }

    // MARK: - Game Selection

    private var gameSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(white: 0.09))
                        .frame(width: 36, height: 36)
                    Image(systemName: "gamecontroller.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.45))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("account.game"))
                        .font(.subheadline.weight(.medium))
                    Text(language.text("account.game_subtitle"))
                        .font(.caption2)
                        .foregroundStyle(Color(white: 0.45))
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }

    private var launchButton: some View {
        Button {
            onLaunchGame()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.subheadline.weight(.medium))
                Text(language.text("account.launch", selectedGameVariant?.shortName ?? language.text("account.game")))
                    .font(.subheadline.weight(.medium))
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
                                ? color.opacity(0.12)
                                : Color(white: 0.08)
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
                            .foregroundStyle(AppTheme.statusGreen)
                            .padding(6)
                    }
                }

                Text(name)
                    .font(.caption)
                    .foregroundStyle(selectedGame == id ? .primary : Color(white: 0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        selectedGame == id ? color.opacity(0.6) : Color.white.opacity(0.06),
                        lineWidth: selectedGame == id ? 1 : 0.5
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
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color(white: 0.4))
                    .tracking(1.2)

                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent.opacity(0.6))

                    TextField("", text: $licenseKey, prompt: Text("BYTE-XXXX-XXXX-XXXX").foregroundColor(Color(white: 0.3)))
                        .font(.callout.monospaced())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit { performLogin() }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(white: 0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            licenseKey.isEmpty ? Color.white.opacity(0.06) : AppTheme.accent.opacity(0.3),
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
                            .font(.body.weight(.medium))
                    }
                    Text(isLoading ? language.text("account.authenticating") : language.text("account.login"))
                        .font(.body.weight(.medium))
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

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.statusGreen)
                Text("\(MobileGestaltService.readUDID() != nil ? "UDID" : "Device ID"): \(ByteAuthService.shared.deviceIdentifier().prefix(12))...")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            cardFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }

    // MARK: - Shared Components


    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.caption.weight(.medium))
                .textCase(.uppercase)
                .foregroundStyle(Color(white: 0.45))
                .tracking(0.5)
        }
        .padding(.bottom, 4)
    }

    private func infoRow(label: String, value: String, valueFont: Font = .subheadline, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.45))
            Spacer()
            Text(value)
                .font(valueFont)
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

import SwiftUI

struct ByteLoginView: View {
    @State private var licenseKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var keyFieldFocused = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var formOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onLoginSuccess: () -> Void

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    logoSection
                        .padding(.bottom, 40)

                    loginCard
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)

                    footerText
                        .padding(.bottom, 40)

                    Spacer(minLength: 20)
                }
                .frame(minHeight: UIScreen.main.bounds.height)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            guard !reduceMotion else {
                logoScale = 1
                logoOpacity = 1
                formOpacity = 1
                return
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                formOpacity = 1
            }
        }
        .alert("Login Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [
                    AppTheme.accent.opacity(0.15),
                    AppTheme.accent.opacity(0.05),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    AppTheme.accent.opacity(0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.accent.opacity(0.3),
                                AppTheme.accent.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)

                Group {
                    if let icon = UIImage(named: "AppIcon60x60")
                        ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                        ?? UIImage(named: "AppIcon") {
                        Image(uiImage: icon)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(AppTheme.accent)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 20, y: 8)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            VStack(spacing: 6) {
                Text("Byte External")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Authenticate to continue")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .opacity(logoOpacity)
        }
    }

    private var loginCard: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LICENSE KEY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(1.5)

                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.accent.opacity(0.7))

                    TextField("", text: $licenseKey, prompt: Text("BYTE-XXXX-XXXX-XXXX").foregroundColor(.white.opacity(0.2)))
                        .font(.body.monospaced())
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit { performLogin() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            licenseKey.isEmpty
                                ? Color.white.opacity(0.08)
                                : AppTheme.accent.opacity(0.4),
                            lineWidth: 1
                        )
                )
            }

            Button(action: performLogin) {
                HStack(spacing: 10) {
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
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            licenseKey.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AppTheme.accent.opacity(0.3)
                                : AppTheme.accent
                        )
                )
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 12, y: 6)
            }
            .disabled(isLoading || licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .opacity(formOpacity)
    }

    private var footerText: some View {
        VStack(spacing: 6) {
            Text("Byte External v\(appVersion)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.25))
            Text("Purchase keys from authorized resellers")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.15))
        }
        .opacity(formOpacity)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
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
                    onLoginSuccess()
                } else {
                    errorMessage = result.error
                    showError = true
                }
            }
        }
    }
}

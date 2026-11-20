import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    var onComplete: () -> Void

    @State private var currentStep = 0

    private let totalSteps = 4

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 8)

                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)

                Spacer()

                Group {
                    switch currentStep {
                    case 0: languageStep
                    case 1: welcomeStep
                    case 2: versionsStep
                    case 3: readyStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                bottomControls
                    .padding(.bottom, 16)
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? AppTheme.accent : Color.white.opacity(0.15))
                    .frame(width: step <= currentStep ? 28 : 20, height: 4)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Language

    private var languageStep: some View {
        VStack(spacing: 32) {
            AppLogo(size: 64)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("Choose your language")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text("You can change this later in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }

            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        languageCode = lang.rawValue
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(lang.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(languageCode == lang.rawValue ? AppTheme.accent : Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if languageCode == lang.rawValue {
                                    Circle()
                                        .fill(AppTheme.accent)
                                        .frame(width: 16, height: 16)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                languageCode == lang.rawValue ? AppTheme.accent : Color.white.opacity(0.1),
                                lineWidth: languageCode == lang.rawValue ? 1.5 : 0.5
                            )
                    )
                    .padding(.horizontal, 28)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Step 2: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: 100, height: 100)
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 20, y: 8)
                AppLogo(size: 80)
            }

            VStack(spacing: 10) {
                Text("Welcome to Compass")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text("Developed by nxvoid")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.accent)
                    .font(.caption)
                Text("Compass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                AppTheme.accent.opacity(0.15),
                in: Capsule()
            )
        }
    }

    // MARK: - Step 3: Supported iOS Versions

    private var versionsStep: some View {
        VStack(spacing: 28) {
            Image(systemName: "iphone")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.accent)
                .padding(20)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )

            VStack(spacing: 8) {
                Text("Supported iOS versions")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Compass allows only the exact build IDs listed in Settings.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 8) {
                versionBadge(title: "iOS 17", detail: ExploitSupportPolicy.verifiedIOS17Range)
                versionBadge(title: "iOS 18", detail: ExploitSupportPolicy.verifiedIOS18Range)
                versionBadge(title: "iOS 26", detail: "\(ExploitSupportPolicy.verifiedIOS26BadQueryRange)")
                versionBadge(title: "iOS 27", detail: ExploitSupportPolicy.verifiedIOS27Range)
            }
            .padding(.horizontal, 28)

            Text("This device: iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    private func versionBadge(title: String, detail: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Step 4: Ready

    private var readyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text("Compass is ready to use.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if currentStep > 0 && currentStep < totalSteps - 1 {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                            Text("Back")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.accent)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 28)
            } else if currentStep == 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.accent)
                    )
                }
                .padding(.horizontal, 28)

                Text("Select a language to continue.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                            Text("Back")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        onComplete()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.accent)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 28)
            }
        }
    }
}

private extension AppLanguage {
    var subtitle: String {
        switch self {
        case .english: return "International"
        case .vietnamese: return "Việt Nam"
        case .simplifiedChinese: return "中国"
        case .korean: return "대한민국"
        }
    }
}

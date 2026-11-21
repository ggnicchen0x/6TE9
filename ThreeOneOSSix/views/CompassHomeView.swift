import SwiftUI

struct PulsingDot: View {
    @State private var isPulsing = false

    var color: Color
    var size: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 2.2, height: size * 2.2)
                .scaleEffect(isPulsing ? 1.0 : 0.5)
                .opacity(isPulsing ? 0.0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

private let cardFill = AppTheme.cardFill

struct CompassHomeView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let offer = appState.updateOffer {
                        updateBanner(offer)
                    }
                    appCard
                    deviceStatusSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(
                ZStack {
                    Color.black
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.35)
                    )
                    .ignoresSafeArea()
                }
            )
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { appState.checkForUpdates() }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(white: 0.06), for: .navigationBar)
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
        HStack(spacing: 12) {
            AppLogo(size: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text("Compass")
                    .font(.callout.weight(.semibold))
                Text("Your iPhone, ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: appState.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(appState.isSupported ? AppTheme.statusGreen : .red)
                    Text(appState.isSupported ? "Supported" : "Unsupported")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(appState.isSupported ? AppTheme.statusGreen : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (appState.isSupported ? AppTheme.statusGreen : Color.red).opacity(0.12),
                    in: Capsule()
                )

                Text("v\(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(AppTheme.cardGradientOpacity),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(AppTheme.cardBorderOpacity), lineWidth: 0.5)
            }
        )
    }

    private var deviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device status")
                .font(.footnote.weight(.bold))

            VStack(spacing: 0) {
                row(icon: "iphone", label: "Hardware model", value: AppInfo.displayMachineName)
                Divider().padding(.leading, 44)
                row(icon: "gearshape", label: "iOS Version", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                Divider().padding(.leading, 44)

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(width: 26)
                    Text("Exploit compatibility")
                        .font(.footnote)
                        .lineLimit(1)
                        .layoutPriority(-1)
                    Spacer(minLength: 4)
                    HStack(spacing: 5) {
                        PulsingDot(color: appState.isSupported ? AppTheme.statusGreen : .red)
                        Text(appState.isSupported ? "Supported" : "Unsupported")
                            .font(.footnote)
                            .foregroundStyle(appState.isSupported ? AppTheme.statusGreen : .red)
                    }
                    .fixedSize()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardFill)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(AppTheme.cardGradientOpacity),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(AppTheme.cardBorderOpacity), lineWidth: 0.5)
                }
            )
        }
    }

    private func row(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 26)
            Text(label)
                .font(.footnote)
            Spacer()
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func updateBanner(_ offer: AppUpdateChecker.Offer) -> some View {
        Button {
            UIApplication.shared.open(offer.url)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.title3)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("New version detected: v\(offer.version)")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Check Out Notice")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                }
            )
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}

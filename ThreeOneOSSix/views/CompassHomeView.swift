import SwiftUI

struct PulsingDot: View {
    @State private var isPulsing = false

    var color: Color
    var size: CGFloat = 7

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

private let cardFill = Color(white: 0.11)

struct CompassHomeView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    appCard
                    deviceStatusSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(
                ZStack {
                    Color.black
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
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
        HStack(spacing: 10) {
            AppLogo(size: 42)

            VStack(alignment: .leading, spacing: 1) {
                Text("Compass")
                    .font(.footnote.weight(.semibold))
                Text("Your iPhone, ready.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 3) {
                    Image(systemName: appState.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(appState.isSupported ? .green : .red)
                    Text(appState.isSupported ? "Supported" : "Unsupported")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(appState.isSupported ? .green : .red)
                }

                Text("v\(appVersion)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardFill)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }
        )
    }

    private var deviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device status")
                .font(.footnote.weight(.semibold))

            VStack(spacing: 0) {
                row(icon: "iphone", label: "Hardware model", value: AppInfo.displayMachineName)
                Divider().padding(.leading, 38)
                row(icon: "gearshape", label: "iOS Version", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                Divider().padding(.leading, 38)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("Exploit compatibility")
                        .font(.caption)
                    Spacer()
                    HStack(spacing: 5) {
                        PulsingDot(color: appState.isSupported ? .green : .red)
                        Text(appState.isSupported ? "Supported" : "Unsupported")
                            .font(.caption)
                            .foregroundStyle(appState.isSupported ? .green : .red)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(cardFill)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.025),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                }
            )
        }
    }

    private func row(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}

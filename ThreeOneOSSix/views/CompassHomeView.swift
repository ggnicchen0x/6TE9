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

struct CompassHomeView: View {
    @EnvironmentObject private var appState: AppState
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    appCard
                    deviceStatusSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(
                ZStack {
                    AppTheme.pageBackground
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
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
        HStack(spacing: 12) {
            AppLogo(size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Compass")
                    .font(.body.weight(.semibold))
                Text("Your iPhone, ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: appState.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(appState.isSupported ? .green : .red)
                    Text(appState.isSupported ? "Supported" : "Unsupported")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(appState.isSupported ? .green : .red)
                }

                Text("v\(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
    }

    private var deviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device status")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                row(icon: "iphone", label: "Hardware model", value: AppInfo.displayMachineName)
                Divider().padding(.leading, 42)
                row(icon: "gearshape", label: "iOS Version", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                Divider().padding(.leading, 42)

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("Exploit compatibility")
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 6) {
                        PulsingDot(color: appState.isSupported ? .green : .red)
                        Text(appState.isSupported ? "Supported" : "Unsupported")
                            .font(.subheadline)
                            .foregroundStyle(appState.isSupported ? .green : .red)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
        }
    }

    private func row(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}

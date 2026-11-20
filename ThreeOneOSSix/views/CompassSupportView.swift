import SwiftUI

struct CompassSupportView: View {
    @Environment(\.appLanguage) private var language
    @State private var entranceShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    telegramCards
                    faqCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Support")
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
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "headphones.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent)

            Text("Need Help?")
                .font(.title3.weight(.bold))

            Text("Reach out to us on Telegram for support, updates, and community.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var telegramCards: some View {
        VStack(spacing: 12) {
            telegramLink(
                icon: "person.fill.questionmark",
                title: "Contact Support",
                subtitle: "@nxvoid12",
                url: "https://t.me/nxvoid12"
            )

            telegramLink(
                icon: "megaphone.fill",
                title: "Updates Channel",
                subtitle: "@byteios",
                url: "https://t.me/byteios"
            )
        }
    }

    private func telegramLink(icon: String, title: String, subtitle: String, url: String) -> some View {
        Button {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var faqCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text("FAQ")
                    .font(.subheadline.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            faqRow(q: "How do I get a license key?", a: "Contact support on Telegram to purchase a key.")
            Divider()
            faqRow(q: "My device isn't supported?", a: "Check Settings for exact supported iOS builds.")
            Divider()
            faqRow(q: "App crashes on launch?", a: "Re-sign the app with an App Group entitlement.")
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func faqRow(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(q)
                .font(.subheadline.weight(.medium))
            Text(a)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

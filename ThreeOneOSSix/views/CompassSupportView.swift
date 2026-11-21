import SwiftUI

struct CompassSupportView: View {
    @Environment(\.appLanguage) private var language
    @State private var entranceShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    telegramCards
                    faqCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle(language.text("support.title"))
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
        }
    }

    private var headerCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.accent)
            }

            Text(language.text("support.need_help"))
                .font(.title3.weight(.bold))

            Text(language.text("support.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardFill)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(AppTheme.cardBorderOpacity), lineWidth: 0.5)
            }
        )
    }

    private var telegramCards: some View {
        VStack(spacing: 10) {
            telegramLink(
                icon: "person.fill.questionmark",
                title: language.text("support.contact"),
                subtitle: "@nxvoid12",
                url: "https://t.me/nxvoid12"
            )

            telegramLink(
                icon: "megaphone.fill",
                title: language.text("support.updates"),
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
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accent.opacity(0.20),
                                    AppTheme.accent.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.cardFill)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(AppTheme.cardGradientOpacity),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(AppTheme.cardBorderOpacity), lineWidth: 0.5)
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var faqCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 24, height: 24)
                    Image(systemName: "questionmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                }
                Text(language.text("support.faq"))
                    .font(.subheadline.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)

            faqRow(q: language.text("support.faq_q1"), a: language.text("support.faq_a1"))
            Divider()
            faqRow(q: language.text("support.faq_q2"), a: language.text("support.faq_a2"))
            Divider()
            faqRow(q: language.text("support.faq_q3"), a: language.text("support.faq_a3"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardFill)
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

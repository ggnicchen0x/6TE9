import SwiftUI

struct ByteSplashView: View {
    @State private var progress: CGFloat = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var loadingOpacity: Double = 0

    private let accentColor = AppTheme.accent

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let logoSide = min(geo.size.width * 0.35, 140.0)
                let innerSide = logoSide * 0.786
                let iconSide = logoSide * 0.5

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 6)
                            .frame(width: logoSide, height: logoSide)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                accentColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: logoSide, height: logoSide)
                            .rotationEffect(.degrees(-90))

                        ZStack {
                            Circle()
                                .fill(AppTheme.cardFill)
                                .frame(width: innerSide, height: innerSide)

                            Circle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                .frame(width: innerSide, height: innerSide)

                            AppLogo(size: iconSide)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Text("Compass")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                        .opacity(textOpacity)

                    Text(AppInfo.displayMachineName)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.top, 4)
                        .opacity(textOpacity)

                    VStack(spacing: 2) {
                        Text("by")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .tracking(1.5)
                        Text("Nicchen")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .padding(.top, 14)
                    .opacity(textOpacity)

                    Spacer()

                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.white.opacity(0.5))
                            .scaleEffect(0.8)
                        Text("Loading")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .opacity(loadingOpacity)
                    .padding(.bottom, 60)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                loadingOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 3.0).delay(0.3)) {
                progress = 0.78
            }
        }
    }
}

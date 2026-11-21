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

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            accentColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    ZStack {
                        Circle()
                            .fill(AppTheme.cardFill)
                            .frame(width: 110, height: 110)

                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            .frame(width: 110, height: 110)

                        AppLogo(size: 70)
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

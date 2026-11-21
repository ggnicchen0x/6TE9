import SwiftUI
import CoreLocation

struct CompassLockView: View {
    @StateObject private var headingManager = HeadingManager()
    @AppStorage("compass.unlock_degree") private var unlockDegree: Int = 0
    @State private var unlocked = false
    @State private var holdTimer: Timer?
    @State private var holdProgress: Double = 0
    @State private var showUnlockFlash = false

    var onUnlock: () -> Void

    private let tolerance: Double = 3
    private let holdDuration: Double = 1.5

    private var isOnTarget: Bool {
        let diff = abs(heading - Double(unlockDegree))
        let wrapped = min(diff, 360 - diff)
        return wrapped <= tolerance
    }

    private var heading: Double {
        headingManager.heading
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    compassDial
                        .rotationEffect(.degrees(-heading))

                    crosshair

                    if isOnTarget {
                        Circle()
                            .stroke(AppTheme.statusGreen, lineWidth: 3)
                            .frame(width: 280, height: 280)
                            .transition(.opacity)
                    }

                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(AppTheme.statusGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 290, height: 290)
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 300, height: 300)
                .animation(.easeInOut(duration: 0.15), value: isOnTarget)

                Spacer().frame(height: 40)

                Text("\(Int(heading))\u{00B0} \(cardinalDirection)")
                    .font(.system(size: 56, weight: .light, design: .default))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                if let coord = headingManager.coordinate {
                    Text(formatCoordinate(coord))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 8)
                }

                if !headingManager.placeName.isEmpty {
                    Text(headingManager.placeName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }

                if headingManager.altitude != 0 {
                    Text("\(Int(headingManager.altitude)) m Elevation")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 2)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: isOnTarget ? "checkmark.circle.fill" : "location.north.fill")
                        .foregroundStyle(isOnTarget ? AppTheme.statusGreen : .white.opacity(0.4))
                    Text(isOnTarget ? "Hold steady..." : "Point to \(unlockDegree)\u{00B0} \(cardinalName(for: Double(unlockDegree)))")
                        .font(.subheadline)
                        .foregroundStyle(isOnTarget ? AppTheme.statusGreen : .white.opacity(0.4))
                }
                .padding(.bottom, 50)
            }

            if showUnlockFlash {
                Color.white.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear {
            headingManager.start()
        }
        .onDisappear {
            headingManager.stop()
            holdTimer?.invalidate()
        }
        .onChange(of: isOnTarget) { onTarget in
            if onTarget {
                startHoldTimer()
            } else {
                cancelHoldTimer()
            }
        }
    }

    // MARK: - Compass Dial

    private var compassDial: some View {
        ZStack {
            ForEach(0..<360, id: \.self) { deg in
                let isMajor = deg % 30 == 0
                let isMinor = deg % 10 == 0
                if isMajor || isMinor {
                    Rectangle()
                        .fill(isMajor ? Color.white : Color.white.opacity(0.4))
                        .frame(width: isMajor ? 2 : 1, height: isMajor ? 16 : 8)
                        .offset(y: -125)
                        .rotationEffect(.degrees(Double(deg)))
                }
            }

            ForEach(0..<12, id: \.self) { i in
                let deg = i * 30
                let label = degreeLabel(deg)
                Text(label)
                    .font(.system(size: label.count <= 2 ? 16 : 14, weight: .bold))
                    .foregroundStyle(labelColor(deg))
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(deg)))
            }

            Triangle()
                .fill(Color.red)
                .frame(width: 12, height: 10)
                .offset(y: -140)
                .rotationEffect(.degrees(0))
        }
    }

    private var crosshair: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 20)
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 20, height: 1)
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Hold Timer

    private func startHoldTimer() {
        holdProgress = 0
        let interval: Double = 0.03
        let steps = holdDuration / interval
        var tick = 0.0

        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            tick += 1
            withAnimation(.linear(duration: interval)) {
                holdProgress = tick / steps
            }
            if tick >= steps {
                timer.invalidate()
                triggerUnlock()
            }
        }
    }

    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }

    private func triggerUnlock() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        withAnimation(.easeIn(duration: 0.15)) {
            showUnlockFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            headingManager.stop()
            onUnlock()
        }
    }

    // MARK: - Helpers

    private var cardinalDirection: String {
        cardinalName(for: heading)
    }

    private func cardinalName(for deg: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((deg + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return dirs[idx % 8]
    }

    private func degreeLabel(_ deg: Int) -> String {
        switch deg {
        case 0: return "N"
        case 90: return "E"
        case 180: return "S"
        case 270: return "W"
        default: return "\(deg)"
        }
    }

    private func labelColor(_ deg: Int) -> Color {
        deg == 0 ? .red : .white
    }

    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        let lat = coord.latitude
        let lon = coord.longitude
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon >= 0 ? "E" : "W"
        let absLat = abs(lat)
        let absLon = abs(lon)
        let latDeg = Int(absLat)
        let latMin = Int((absLat - Double(latDeg)) * 60)
        let latSec = Int(((absLat - Double(latDeg)) * 60 - Double(latMin)) * 60)
        let lonDeg = Int(absLon)
        let lonMin = Int((absLon - Double(lonDeg)) * 60)
        let lonSec = Int(((absLon - Double(lonDeg)) * 60 - Double(lonMin)) * 60)
        return "\(latDeg)\u{00B0}\(latMin)\u{2032}\(latSec)\u{2033} \(latDir)  \(lonDeg)\u{00B0}\(lonMin)\u{2032}\(lonSec)\u{2033} \(lonDir)"
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

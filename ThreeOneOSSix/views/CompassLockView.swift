import SwiftUI
import CoreLocation

struct CompassLockView: View {
    @StateObject private var headingManager = HeadingManager()
    @AppStorage("compass.unlock_degree") private var unlockDegree: Int = 0
    @State private var unlocked = false
    @State private var holdTimer: Timer?
    @State private var isUnlocked = false
    @State private var ringProgress: Double = 0
    @State private var showUnlockFlash = false

    var onUnlock: () -> Void

    private let tolerance: Double = 3.5
    private let holdDuration: Double = 2.0

    private var isOnTarget: Bool {
        let diff = abs(heading - Double(unlockDegree))
        let wrapped = min(diff, 360 - diff)
        return wrapped <= tolerance
    }

    private var heading: Double {
        headingManager.heading
    }

    var body: some View {
        GeometryReader { geo in
            let dialSize = dialSize(for: geo.size)
            let s = dialSize / 320

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        compassDial(scale: s)
                            .rotationEffect(.degrees(-heading))

                        centerReticle(scale: s)

                        topIndexMarker(scale: s)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                AppTheme.statusGreen,
                                style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round)
                            )
                            .frame(width: 308 * s, height: 308 * s)
                            .rotationEffect(.degrees(-90))
                            .opacity(ringProgress > 0 ? 1 : 0)
                    }
                    .frame(width: dialSize, height: dialSize)

                    Spacer().frame(height: 36 * s)

                    Text("\(Int(heading))\u{00B0} \(cardinalDirection)")
                        .font(.system(size: min(60 * s, 72), weight: .light, design: .default))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    if let coord = headingManager.coordinate {
                        Text(formatCoordinate(coord))
                            .font(.system(size: min(17 * s, 22), weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                    }

                    if !headingManager.placeName.isEmpty {
                        Text(headingManager.placeName)
                            .font(.system(size: min(21 * s, 28), weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.top, 4)
                    }

                    if headingManager.altitude != 0 {
                        Text(formatElevation(headingManager.altitude))
                            .font(.system(size: min(17 * s, 22), weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.top, 2)
                    }

                    Spacer()
                }

                if showUnlockFlash {
                    Color.white.opacity(0.2)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
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
            guard !isUnlocked else { return }
            if onTarget {
                startHoldTimer()
            } else {
                cancelHoldTimer()
            }
        }
    }

    private func dialSize(for size: CGSize) -> CGFloat {
        let shorter = min(size.width, size.height)
        let available = shorter - 48
        return min(max(available * 0.75, 220), 500)
    }

    // MARK: - Top Fixed Index Marker (12 o'clock)
    private func topIndexMarker(scale s: CGFloat) -> some View {
        Rectangle()
            .fill(ringProgress > 0 ? AppTheme.statusGreen : Color.white)
            .frame(width: 2.5, height: 30 * s)
            .offset(y: -140 * s)
    }

    // MARK: - Center Reticle / Level Crosshair (Fixed)
    private func centerReticle(scale s: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 60 * s, height: 60 * s)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 104 * s, height: 0.8)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 0.8, height: 104 * s)

            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 14 * s, height: 0.8)

            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 0.8, height: 14 * s)
        }
    }

    // MARK: - Compass Dial (Rotates)
    private func compassDial(scale s: CGFloat) -> some View {
        ZStack {
            ForEach(0..<180, id: \.self) { i in
                let deg = i * 2
                let isMajor = deg % 30 == 0
                let isMedium = deg % 10 == 0
                let len: CGFloat = (isMajor ? 13 : (isMedium ? 9.5 : 5.5)) * s
                let wid: CGFloat = (isMajor ? 1.8 : (isMedium ? 1.2 : 0.8)) * s
                let opacity: Double = isMajor ? 1.0 : (isMedium ? 0.8 : 0.45)

                Rectangle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: wid, height: len)
                    .offset(y: -128 * s + len / 2)
                    .rotationEffect(.degrees(Double(deg)))
            }

            Triangle()
                .fill(Color(red: 0.95, green: 0.25, blue: 0.2))
                .frame(width: 8 * s, height: 7 * s)
                .offset(y: -136 * s)

            ForEach(0..<12, id: \.self) { i in
                let deg = i * 30
                Text("\(deg)")
                    .font(.system(size: 14 * s, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: (deg == 0 ? -148 : -146) * s)
                    .rotationEffect(.degrees(Double(deg)))
            }

            ForEach(["N": 0, "E": 90, "S": 180, "W": 270].sorted(by: { $0.value < $1.value }), id: \.key) { key, deg in
                Text(key)
                    .font(.system(size: 24 * s, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: -75 * s)
                    .rotationEffect(.degrees(Double(deg)))
            }
        }
    }

    // MARK: - Silent Hold Timer (2 Seconds)
    private func startHoldTimer() {
        cancelHoldTimer()
        holdTimer = Timer.scheduledTimer(withTimeInterval: holdDuration, repeats: false) { _ in
            triggerUnlock()
        }
    }

    private func cancelHoldTimer() {
        guard !isUnlocked else { return }
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private func triggerUnlock() {
        guard !isUnlocked else { return }
        isUnlocked = true

        let startHaptic = UIImpactFeedbackGenerator(style: .medium)
        startHaptic.impactOccurred()

        let duration: Double = 0.55
        let interval: Double = 0.016
        let totalSteps = duration / interval
        var currentStep = 0.0

        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { animTimer in
            currentStep += 1
            ringProgress = min(1.0, currentStep / totalSteps)

            if currentStep >= totalSteps {
                animTimer.invalidate()

                let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
                heavyHaptic.impactOccurred()

                withAnimation(.easeIn(duration: 0.15)) {
                    showUnlockFlash = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    headingManager.stop()
                    onUnlock()
                }
            }
        }
    }

    // MARK: - Helpers
    private var cardinalDirection: String {
        cardinalName(for: heading)
    }

    private func cardinalName(for deg: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let normalized = (deg.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let idx = Int((normalized + 22.5) / 45) % 8
        return dirs[idx]
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
        return "\(latDeg)°\(latMin)'\(latSec)\" \(latDir) \(lonDeg)°\(lonMin)'\(lonSec)\" \(lonDir)"
    }

    private func formatElevation(_ alt: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let numStr = formatter.string(from: NSNumber(value: Int(alt))) ?? "\(Int(alt))"
        return "\(numStr) m Elevation"
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

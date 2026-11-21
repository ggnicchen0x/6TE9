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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Compass Dial & Reticle
                ZStack {
                    // Rotating Dial (ticks, numbers, cardinals, red north marker)
                    compassDial
                        .rotationEffect(.degrees(-heading))

                    // Fixed Center Reticle / Level Crosshair (does not rotate)
                    centerReticle

                    // Fixed Top Heading Index Line (12 o'clock)
                    topIndexMarker

                    // Green confirmation ring only shown AFTER 2-second hold completes
                    if isUnlocked && ringProgress > 0 {
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                AppTheme.statusGreen,
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                            )
                            .frame(width: 308, height: 308)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 320, height: 320)

                Spacer().frame(height: 36)

                // MARK: - Heading & Direction Text
                Text("\(Int(heading))\u{00B0} \(cardinalDirection)")
                    .font(.system(size: 60, weight: .light, design: .default))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // MARK: - Coordinates
                if let coord = headingManager.coordinate {
                    Text(formatCoordinate(coord))
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                }

                // MARK: - Place Name
                if !headingManager.placeName.isEmpty {
                    Text(headingManager.placeName)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }

                // MARK: - Elevation
                if headingManager.altitude != 0 {
                    Text(formatElevation(headingManager.altitude))
                        .font(.system(size: 17, weight: .regular))
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

    // MARK: - Top Fixed Index Marker (12 o'clock)
    private var topIndexMarker: some View {
        Rectangle()
            .fill(isUnlocked ? AppTheme.statusGreen : Color.white)
            .frame(width: 2.5, height: 30)
            .offset(y: -140)
    }

    // MARK: - Center Reticle / Level Crosshair (Fixed)
    private var centerReticle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 60, height: 60)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 104, height: 0.8)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 0.8, height: 104)

            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 14, height: 0.8)

            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 0.8, height: 14)
        }
    }

    // MARK: - Compass Dial (Rotates)
    private var compassDial: some View {
        ZStack {
            // 180 tick marks (every 2 degrees)
            ForEach(0..<180, id: \.self) { i in
                let deg = i * 2
                let isMajor = deg % 30 == 0
                let isMedium = deg % 10 == 0
                let len: CGFloat = isMajor ? 13 : (isMedium ? 9.5 : 5.5)
                let wid: CGFloat = isMajor ? 1.8 : (isMedium ? 1.2 : 0.8)
                let opacity: Double = isMajor ? 1.0 : (isMedium ? 0.8 : 0.45)

                Rectangle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: wid, height: len)
                    .offset(y: -128 + len / 2)
                    .rotationEffect(.degrees(Double(deg)))
            }

            // Red triangle at 0° (North)
            Triangle()
                .fill(Color(red: 0.95, green: 0.25, blue: 0.2))
                .frame(width: 8, height: 7)
                .offset(y: -136)
                .rotationEffect(.degrees(0))

            // Outer degree numbers: 0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330
            ForEach(0..<12, id: \.self) { i in
                let deg = i * 30
                Text("\(deg)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: deg == 0 ? -148 : -146)
                    .rotationEffect(.degrees(Double(deg)))
            }

            // Cardinal letters inside tick ring: N, E, S, W
            ForEach(["N": 0, "E": 90, "S": 180, "W": 270].sorted(by: { $0.value < $1.value }), id: \.key) { key, deg in
                Text(key)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: -75)
                    .rotationEffect(.degrees(Double(deg)))
            }
        }
    }

    // MARK: - Silent Hold Timer (2 Seconds)
    private func startHoldTimer() {
        cancelHoldTimer()
        // Silently wait for 2 full seconds while holding steady on target degree
        holdTimer = Timer.scheduledTimer(withTimeInterval: holdDuration, repeats: false) { _ in
            triggerUnlock()
        }
    }

    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private func triggerUnlock() {
        isUnlocked = true
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        withAnimation(.easeOut(duration: 0.35)) {
            ringProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeIn(duration: 0.15)) {
                showUnlockFlash = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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

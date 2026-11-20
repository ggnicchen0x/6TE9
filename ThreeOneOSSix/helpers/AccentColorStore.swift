import SwiftUI
import UIKit

final class AccentColorStore: ObservableObject {
    static let shared = AccentColorStore()

    private static let redKey = "byte_accent_r"
    private static let greenKey = "byte_accent_g"
    private static let blueKey = "byte_accent_b"

    @Published var red: CGFloat {
        didSet { save() }
    }
    @Published var green: CGFloat {
        didSet { save() }
    }
    @Published var blue: CGFloat {
        didSet { save() }
    }

    var accentColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    var darkUIColor: UIColor {
        UIColor(red: min(1, red + 0.05), green: min(1, green + 0.05), blue: min(1, blue + 0.05), alpha: 1)
    }

    var lightUIColor: UIColor {
        UIColor(red: max(0, red - 0.08), green: max(0, green - 0.08), blue: max(0, blue - 0.08), alpha: 1)
    }

    var hexString: String {
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.redKey) != nil {
            self.red = CGFloat(defaults.double(forKey: Self.redKey))
            self.green = CGFloat(defaults.double(forKey: Self.greenKey))
            self.blue = CGFloat(defaults.double(forKey: Self.blueKey))
        } else {
            // Default purple: #7B4AEB
            self.red = 0.482
            self.green = 0.290
            self.blue = 0.922
        }
    }

    func applyHex(_ hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let val = UInt64(cleaned, radix: 16) else { return }
        red = CGFloat((val >> 16) & 0xFF) / 255.0
        green = CGFloat((val >> 8) & 0xFF) / 255.0
        blue = CGFloat(val & 0xFF) / 255.0
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(Double(red), forKey: Self.redKey)
        defaults.set(Double(green), forKey: Self.greenKey)
        defaults.set(Double(blue), forKey: Self.blueKey)
    }
}

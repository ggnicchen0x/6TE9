import SwiftUI
import UIKit

final class AccentColorStore: ObservableObject {
    static let shared = AccentColorStore()

    private static let hueKey = "byte_accent_hue"
    private static let satKey = "byte_accent_sat"
    private static let briKey = "byte_accent_bri"

    struct AccentPreset: Identifiable {
        let id: String
        let name: String
        let hue: CGFloat
        let saturation: CGFloat
        let brightness: CGFloat

        var color: Color {
            Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    static let presets: [AccentPreset] = [
        AccentPreset(id: "purple", name: "Purple", hue: 0.73, saturation: 0.72, brightness: 0.92),
        AccentPreset(id: "violet", name: "Violet", hue: 0.78, saturation: 0.65, brightness: 0.96),
        AccentPreset(id: "blue", name: "Blue", hue: 0.60, saturation: 0.70, brightness: 0.95),
        AccentPreset(id: "cyan", name: "Cyan", hue: 0.52, saturation: 0.65, brightness: 0.92),
        AccentPreset(id: "teal", name: "Teal", hue: 0.47, saturation: 0.60, brightness: 0.85),
        AccentPreset(id: "green", name: "Green", hue: 0.38, saturation: 0.65, brightness: 0.85),
        AccentPreset(id: "lime", name: "Lime", hue: 0.25, saturation: 0.60, brightness: 0.90),
        AccentPreset(id: "yellow", name: "Yellow", hue: 0.13, saturation: 0.65, brightness: 0.95),
        AccentPreset(id: "orange", name: "Orange", hue: 0.08, saturation: 0.75, brightness: 0.95),
        AccentPreset(id: "red", name: "Red", hue: 0.0, saturation: 0.70, brightness: 0.92),
        AccentPreset(id: "pink", name: "Pink", hue: 0.92, saturation: 0.55, brightness: 0.95),
        AccentPreset(id: "rose", name: "Rose", hue: 0.95, saturation: 0.60, brightness: 0.90),
    ]

    @Published var hue: CGFloat {
        didSet { save() }
    }
    @Published var saturation: CGFloat {
        didSet { save() }
    }
    @Published var brightness: CGFloat {
        didSet { save() }
    }

    var accentColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var uiColor: UIColor {
        UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

    var darkUIColor: UIColor {
        UIColor(hue: hue, saturation: max(0.3, saturation - 0.1), brightness: min(1.0, brightness + 0.05), alpha: 1)
    }

    var lightUIColor: UIColor {
        UIColor(hue: hue, saturation: min(1.0, saturation + 0.1), brightness: max(0.5, brightness - 0.1), alpha: 1)
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.hueKey) != nil {
            self.hue = CGFloat(defaults.double(forKey: Self.hueKey))
            self.saturation = CGFloat(defaults.double(forKey: Self.satKey))
            self.brightness = CGFloat(defaults.double(forKey: Self.briKey))
        } else {
            self.hue = 0.73
            self.saturation = 0.72
            self.brightness = 0.92
        }
    }

    func applyPreset(_ preset: AccentPreset) {
        hue = preset.hue
        saturation = preset.saturation
        brightness = preset.brightness
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(Double(hue), forKey: Self.hueKey)
        defaults.set(Double(saturation), forKey: Self.satKey)
        defaults.set(Double(brightness), forKey: Self.briKey)
    }
}

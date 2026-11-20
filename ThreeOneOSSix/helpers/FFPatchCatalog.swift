import Foundation

enum FFGameVariant: String, CaseIterable, Identifiable {
    case ffmax = "com.dts.freefiremax"
    case ffth = "com.dts.freefireth"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ffmax: return "Free Fire MAX"
        case .ffth: return "Free Fire TH"
        }
    }

    var shortName: String {
        switch self {
        case .ffmax: return "FFMAX"
        case .ffth: return "FFTH"
        }
    }

    var resourceFolder: String {
        switch self {
        case .ffmax: return "FFMAX"
        case .ffth: return "FFTH"
        }
    }
}

enum FFCheatCategory: String, CaseIterable, Identifiable {
    case aimbotHead
    case aimbotNeck
    case aimbotChest
    case aimbotDrag
    case holoWeapons
    case holoCharacter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aimbotHead: return "Aimbot Head"
        case .aimbotNeck: return "Aimbot Neck"
        case .aimbotChest: return "Aimbot Chest"
        case .aimbotDrag: return "Aimbot Drag"
        case .holoWeapons: return "Holo Weapons"
        case .holoCharacter: return "Holo Character"
        }
    }

    var icon: String {
        switch self {
        case .aimbotHead: return "scope"
        case .aimbotNeck: return "target"
        case .aimbotChest: return "shield.fill"
        case .aimbotDrag: return "hand.draw.fill"
        case .holoWeapons: return "sparkle"
        case .holoCharacter: return "person.fill"
        }
    }

    var section: FFCheatSection {
        switch self {
        case .aimbotHead, .aimbotNeck, .aimbotChest, .aimbotDrag:
            return .aimbot
        case .holoWeapons, .holoCharacter:
            return .visuals
        }
    }
}

enum FFCheatSection: String, CaseIterable, Identifiable {
    case aimbot
    case visuals

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aimbot: return "Aimbot"
        case .visuals: return "Visuals"
        }
    }

    var icon: String {
        switch self {
        case .aimbot: return "scope"
        case .visuals: return "eye.fill"
        }
    }
}

struct FFCheatEntry: Identifiable {
    let id = UUID()
    let category: FFCheatCategory
    let variant: FFGameVariant
    let hasAntenna: Bool
    let filename: String
    let resourcePath: String
}

enum FFPatchCatalog {
    private struct PatchMapping {
        let pattern: String
        let category: FFCheatCategory
        let hasAntenna: Bool
    }

    private static let ffmaxMappings: [PatchMapping] = [
        PatchMapping(pattern: "AIMBOT CABEZA - ANTENA FFMAX", category: .aimbotHead, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT CABEZA SIN ANTENA FFMAX", category: .aimbotHead, hasAntenna: false),
        PatchMapping(pattern: "AIMBOT CUELLO - ANTENA FFMAX", category: .aimbotNeck, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT CUELLO SN ANTENA FFMAX", category: .aimbotNeck, hasAntenna: false),
        PatchMapping(pattern: "AIMBOT PECHO - ANTENA FFMAX", category: .aimbotChest, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT DRAG - ANTENA FFMAX", category: .aimbotDrag, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT DRAG SIN ANTENA FFMAX", category: .aimbotDrag, hasAntenna: false),
        PatchMapping(pattern: "HOLO ARMAS BORDES FFMAX", category: .holoWeapons, hasAntenna: false),
    ]

    private static let ffthMappings: [PatchMapping] = [
        PatchMapping(pattern: "AIMBOT CABEZA - ANTENA FFTH", category: .aimbotHead, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT CABEZA SIN ANTENA FFTH", category: .aimbotHead, hasAntenna: false),
        PatchMapping(pattern: "AIMBOT CUELLO - ANTENA FFTH", category: .aimbotNeck, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT CUELLO SN ANTENA FFTH", category: .aimbotNeck, hasAntenna: false),
        PatchMapping(pattern: "AIMBOT PECHO - ANTENA FFTH", category: .aimbotChest, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT PECHO SN ANTENA  FFTH", category: .aimbotChest, hasAntenna: false),
        PatchMapping(pattern: "AIMBOT DRAG - ANTENA FFTH", category: .aimbotDrag, hasAntenna: true),
        PatchMapping(pattern: "AIMBOT DRAG SIN ANTENA FFTH", category: .aimbotDrag, hasAntenna: false),
        PatchMapping(pattern: "HOLOGRAMA ARMAS BORDES FFTH", category: .holoWeapons, hasAntenna: false),
        PatchMapping(pattern: "HOLOGRAMA PERSONAJE FFTH", category: .holoCharacter, hasAntenna: false),
    ]

    static func entries(for variant: FFGameVariant) -> [FFCheatEntry] {
        let mappings: [PatchMapping]
        switch variant {
        case .ffmax: mappings = ffmaxMappings
        case .ffth: mappings = ffthMappings
        }
        return mappings.compactMap { mapping in
            let filename = mapping.pattern + ".3105"
            let folder = variant.resourceFolder
            guard Bundle.main.path(
                forResource: mapping.pattern,
                ofType: "3105",
                inDirectory: "Patches/\(folder)"
            ) != nil else {
                return nil
            }
            return FFCheatEntry(
                category: mapping.category,
                variant: variant,
                hasAntenna: mapping.hasAntenna,
                filename: filename,
                resourcePath: "Patches/\(folder)/\(filename)"
            )
        }
    }

    static func allEntries() -> [FFCheatEntry] {
        FFGameVariant.allCases.flatMap { entries(for: $0) }
    }

    static func patchData(for entry: FFCheatEntry) -> Data? {
        let folder = entry.variant.resourceFolder
        let name = entry.filename.replacingOccurrences(of: ".3105", with: "")
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "3105",
            subdirectory: "Patches/\(folder)"
        ) else { return nil }
        return try? Data(contentsOf: url)
    }
}

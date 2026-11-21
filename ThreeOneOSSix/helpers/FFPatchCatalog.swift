import Foundation

enum FFGameVariant: String, CaseIterable, Identifiable {
    case ffmax = "com.dts.freefiremax"
    case ffth = "com.dts.freefireth"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ffmax: return "Free Fire MAX"
        case .ffth: return "Free Fire"
        }
    }

    var shortName: String {
        switch self {
        case .ffmax: return "FF MAX"
        case .ffth: return "FF"
        }
    }

    var resourceFolder: String {
        switch self {
        case .ffmax: return "FFMAX"
        case .ffth: return "FFTH"
        }
    }

    var catalogKey: String {
        switch self {
        case .ffmax: return "ffmax"
        case .ffth: return "ffth"
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
    let id: String
    let category: FFCheatCategory
    let variant: FFGameVariant
    let hasAntenna: Bool
    let featureID: String
    let displayLabel: String
}

private func inferCategory(from featureID: String, name: String) -> FFCheatCategory {
    let lower = featureID.lowercased() + " " + name.lowercased()
    if lower.contains("holo") || lower.contains("visual") || lower.contains("character") || lower.contains("skin") {
        if lower.contains("character") || lower.contains("personaje") { return .holoCharacter }
        return .holoWeapons
    }
    if lower.contains("head") { return .aimbotHead }
    if lower.contains("neck") { return .aimbotNeck }
    if lower.contains("chest") || lower.contains("body") { return .aimbotChest }
    if lower.contains("drag") { return .aimbotDrag }
    return .aimbotDrag
}

enum FFPatchCatalog {

    @MainActor
    static var cloudFeatures: [CloudPatchFeature] = []

    @MainActor
    static var lastFetchError: Error?

    @MainActor
    static func refreshCatalog() async {
        do {
            cloudFeatures = try await CloudPatchService.shared.fetchCatalog(forceRefresh: true)
            lastFetchError = nil
        } catch {
            lastFetchError = error
        }
    }

    @MainActor
    static func loadCatalogIfNeeded() async {
        if cloudFeatures.isEmpty {
            await refreshCatalog()
        }
    }

    @MainActor
    static func entries(for variant: FFGameVariant) -> [FFCheatEntry] {
        return cloudFeatures.compactMap { feature in
            let hasVariantFile: Bool
            if feature.files != nil {
                hasVariantFile = feature.filename(for: variant) != nil
            } else {
                hasVariantFile = true
            }
            guard hasVariantFile else { return nil }

            let category = inferCategory(from: feature.id, name: feature.name)
            let hasAntenna = feature.name.lowercased().contains("antena")
                || feature.name.lowercased().contains("antenna")

            return FFCheatEntry(
                id: "\(variant.rawValue):\(feature.id)",
                category: category,
                variant: variant,
                hasAntenna: hasAntenna,
                featureID: feature.id,
                displayLabel: feature.name
            )
        }
    }

    @MainActor
    static func allEntries() -> [FFCheatEntry] {
        FFGameVariant.allCases.flatMap { entries(for: $0) }
    }

    static func patchData(for entry: FFCheatEntry) async throws -> Data {
        try await CloudPatchService.shared.fetchPatch(featureID: entry.featureID)
    }
}

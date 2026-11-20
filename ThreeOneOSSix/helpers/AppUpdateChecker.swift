import Foundation

enum AppUpdateChecker {
    struct Offer: Identifiable {
        let id = UUID()
        let version: String
        let url: URL
    }

    enum CheckOutcome {
        case upToDate
        case updateAvailable(Offer)
        case failure(FailureReason)
    }

    enum FailureReason: Equatable {
        case offline
        case httpStatus(Int)
        case badResponse
        case other(String)

        var localizationKey: String {
            switch self {
            case .offline: return "update.failure.offline"
            case .httpStatus: return "update.failure.http"
            case .badResponse: return "update.failure.bad_response"
            case .other: return "update.failure.other"
            }
        }
    }

    static func check() async -> Offer? { nil }
    static func checkIgnoringDismissal() async -> Offer? { nil }
    static func checkWithOutcome() async -> CheckOutcome { .upToDate }
    static func throttledForegroundCheck() async -> Offer? { nil }
    static func dismiss(version: String) {}

    static func normalize(_ version: String) -> String {
        var value = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.lowercased().hasPrefix("v") { value.removeFirst() }
        return value
    }

    static func isNewer(_ remote: String, than local: String) -> Bool {
        let remoteParts = numericParts(normalize(remote))
        let localParts = numericParts(normalize(local))
        let count = max(remoteParts.count, localParts.count)
        for i in 0..<count {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r != l { return r > l }
        }
        return false
    }

    private static func numericParts(_ version: String) -> [Int] {
        let core = version.split(separator: "-").first.map(String.init) ?? version
        return core.split(separator: ".").compactMap { Int($0.filter(\.isNumber)) }
    }
}

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
    }

    static func check() async -> Offer? { nil }
    static func checkIgnoringDismissal() async -> Offer? { nil }
    static func checkWithOutcome() async -> CheckOutcome { .upToDate }
    static func throttledForegroundCheck() async -> Offer? { nil }
    static func dismiss(version: String) {}
}

import CommonCrypto
import Foundation
import UIKit

enum CloudPatchError: LocalizedError {
    case notAuthenticated
    case serverError(Int, String?)
    case networkError(Error)
    case invalidResponse
    case patchNotFound(String)
    case signingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Authentication required."
        case .serverError(let code, let detail): return detail ?? "Server error (\(code))."
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid server response."
        case .patchNotFound(let name): return "Patch not found: \(name)"
        case .signingFailed: return "Request signing failed."
        }
    }
}

struct CloudPatchFeature: Identifiable, Codable {
    let id: String
    let name: String
    let file: String?
    let files: [String: String]?

    func filename(for variant: FFGameVariant) -> String? {
        if let files = files {
            switch variant {
            case .ffmax: return files["ffmax"]
            case .ffth: return files["ffth"]
            }
        }
        return file
    }
}

struct CloudCatalogResponse: Codable {
    let status: String
    let features: [CloudPatchFeature]
}

final class CloudPatchService {
    static let shared = CloudPatchService()

    private let baseURL = "http://fi7.bot-hosting.cloud:25037"
    private static let hmacKey = "byte_compass_v2"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    // MARK: - Catalog

    private var cachedCatalog: CloudCatalogResponse?
    private var catalogFetchTime: Date?

    func fetchCatalog(forceRefresh: Bool = false) async throws -> [CloudPatchFeature] {
        if !forceRefresh,
           let cached = cachedCatalog,
           let fetchTime = catalogFetchTime,
           Date().timeIntervalSince(fetchTime) < 300 {
            return cached.features
        }

        guard let url = URL(string: "\(baseURL)/api/v1/patches/catalog") else {
            throw CloudPatchError.invalidResponse
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: URLRequest(url: url))
        } catch {
            throw CloudPatchError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CloudPatchError.invalidResponse
        }

        let catalog = try JSONDecoder().decode(CloudCatalogResponse.self, from: data)
        cachedCatalog = catalog
        catalogFetchTime = Date()
        return catalog.features
    }

    // MARK: - Patch Fetch

    func fetchPatch(featureID: String) async throws -> Data {
        if let cached = cachedPatchData(featureID: featureID) {
            return cached
        }

        guard let token = UserDefaults.standard.string(forKey: "byte_auth_token") else {
            throw CloudPatchError.notAuthenticated
        }

        let deviceHash = deviceIdentifier()
        let timestamp = Int(Date().timeIntervalSince1970)
        let message = "\(featureID):\(deviceHash):\(timestamp)"

        guard let signature = hmacSHA256(message: message, key: Self.hmacKey) else {
            throw CloudPatchError.signingFailed
        }

        guard let url = URL(string: "\(baseURL)/api/v2/patches/fetch") else {
            throw CloudPatchError.invalidResponse
        }

        let body: [String: Any] = [
            "feature_name": featureID,
            "token": token,
            "device_hash": deviceHash,
            "timestamp": timestamp,
            "signature": signature,
            "app_version": appVersion()
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CloudPatchError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CloudPatchError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            break
        case 401:
            throw CloudPatchError.notAuthenticated
        case 404:
            throw CloudPatchError.patchNotFound(featureID)
        default:
            let detail = parseErrorDetail(data)
            throw CloudPatchError.serverError(http.statusCode, detail)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let patchB64 = json["patch_data"] as? String,
           let patchData = Data(base64Encoded: patchB64) {
            cachePatchData(featureID: featureID, data: patchData)
            return patchData
        }

        if data.count > 16 {
            cachePatchData(featureID: featureID, data: data)
            return data
        }

        throw CloudPatchError.patchNotFound(featureID)
    }

    // MARK: - Cache

    private var cacheDir: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = caches.appendingPathComponent("CloudPatches", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func cachedPatchData(featureID: String) -> Data? {
        guard let dir = cacheDir else { return nil }
        let file = dir.appendingPathComponent("\(featureID).3105")
        return try? Data(contentsOf: file)
    }

    private func cachePatchData(featureID: String, data: Data) {
        guard let dir = cacheDir else { return }
        let file = dir.appendingPathComponent("\(featureID).3105")
        try? data.write(to: file, options: .atomic)
    }

    func clearCache() {
        guard let dir = cacheDir else { return }
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        cachedCatalog = nil
        catalogFetchTime = nil
    }

    // MARK: - Signing

    private func hmacSHA256(message: String, key: String) -> String? {
        guard let messageData = message.data(using: .utf8),
              let keyData = key.data(using: .utf8) else { return nil }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { msgBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBytes.baseAddress, keyData.count,
                    msgBytes.baseAddress, messageData.count,
                    &digest
                )
            }
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Helpers

    private func deviceIdentifier() -> String {
        if let id = UIDevice.current.identifierForVendor?.uuidString {
            return id
        }
        let key = "byte_device_fallback_id"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }

    private func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.6"
    }

    private func parseErrorDetail(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["detail"] as? String ?? json["error"] as? String
    }
}

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
    let safe_status: Bool?
}

final class CloudPatchService {
    static let shared = CloudPatchService()

    private let baseURL = "http://fi7.bot-hosting.cloud:25037"
    private static let hmacKey: String = {
        let encoded: [UInt8] = [
            0x5a, 0x58, 0x59, 0x5c, 0x36, 0x21, 0x24, 0x28,
            0x2a, 0x36, 0x3a, 0x20, 0x2e, 0x36, 0x02, 0x50,
            0x51, 0x5b, 0x5a, 0x01, 0x03, 0x0d, 0x51, 0x50,
            0x5b, 0x5a, 0x01, 0x03, 0x02, 0x1a, 0x0d, 0x0f,
            0x5e, 0x51, 0x5b, 0x5a, 0x5d
        ]
        let mask: UInt8 = 0x69
        return String(bytes: encoded.map { $0 ^ mask }, encoding: .utf8) ?? ""
    }()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = ["Accept-Encoding": "gzip, deflate"]
        config.urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 0)
        config.httpMaximumConnectionsPerHost = 4
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Catalog

    private(set) var isSafe: Bool = true
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
        isSafe = catalog.safe_status ?? true
        return catalog.features
    }

    // MARK: - Patch Fetch

    func fetchPatch(featureID: String) async throws -> Data {
        if let cached = cachedPatchData(featureID: featureID) {
            return cached
        }

        guard let token = ByteAuthService.shared.authToken else {
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
            evictCacheIfNeeded()
            return patchData
        }

        if data.count > 16 {
            cachePatchData(featureID: featureID, data: data)
            evictCacheIfNeeded()
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
        let hashFile = dir.appendingPathComponent("\(featureID).sha256")
        guard let data = try? Data(contentsOf: file) else { return nil }
        if let storedHash = try? String(contentsOf: hashFile, encoding: .utf8) {
            let computed = sha256Hex(data)
            if computed != storedHash {
                try? FileManager.default.removeItem(at: file)
                try? FileManager.default.removeItem(at: hashFile)
                return nil
            }
        }
        return data
    }

    private func cachePatchData(featureID: String, data: Data) {
        guard let dir = cacheDir else { return }
        let file = dir.appendingPathComponent("\(featureID).3105")
        let hashFile = dir.appendingPathComponent("\(featureID).sha256")
        try? data.write(to: file, options: .atomic)
        try? sha256Hex(data).write(to: hashFile, atomically: true, encoding: .utf8)
    }

    private func sha256Hex(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { ptr in
            _ = CC_SHA256(ptr.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static let maxCacheBytes: UInt64 = 50 * 1024 * 1024

    func clearCache() {
        guard let dir = cacheDir else { return }
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        cachedCatalog = nil
        catalogFetchTime = nil
    }

    private func evictCacheIfNeeded() {
        guard let dir = cacheDir else { return }
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var entries: [(url: URL, size: UInt64, date: Date)] = []
        var total: UInt64 = 0
        for file in files where file.pathExtension == "3105" {
            let vals = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let size = UInt64(vals?.fileSize ?? 0)
            let date = vals?.contentModificationDate ?? .distantPast
            entries.append((file, size, date))
            total += size
        }

        guard total > Self.maxCacheBytes else { return }
        entries.sort { $0.date < $1.date }
        for entry in entries {
            guard total > Self.maxCacheBytes else { break }
            let hashFile = entry.url.deletingPathExtension().appendingPathExtension("sha256")
            try? fm.removeItem(at: entry.url)
            try? fm.removeItem(at: hashFile)
            total -= entry.size
        }
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
        ByteAuthService.shared.deviceIdentifier()
    }

    private func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.1"
    }

    private func parseErrorDetail(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["detail"] as? String ?? json["error"] as? String
    }
}

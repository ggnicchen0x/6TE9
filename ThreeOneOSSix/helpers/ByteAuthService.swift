import Foundation
import UIKit
import Security
import CommonCrypto

extension Notification.Name {
    static let byteDidLogout = Notification.Name("byteDidLogout")
    static let byteDidLogin = Notification.Name("byteDidLogin")
}

final class ByteAuthService {
    static let shared = ByteAuthService()

    private let baseURL = "https://fi7.bot-hosting.cloud:25037"
    private let session = URLSession(configuration: {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        c.timeoutIntervalForResource = 30
        return c
    }())

    private init() {
        migrateUserDefaultsToKeychain()
    }

    private static let keychainService = "CompassAuth"
    private static let tokenKey = "byte_auth_token"
    private static let licenseKey = "byte_license_key"
    private static let expiresKey = "byte_license_expires"
    private static let loginTimeKey = "byte_login_time"
    private static let userNameKey = "byte_user_name"

    // MARK: - Keychain Helpers

    private func keychainRead(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Self.keychainService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ref: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess,
              let data = ref as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else { return nil }
        return value
    }

    private func keychainWrite(_ account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Self.keychainService
        ]
        SecItemDelete(query as CFDictionary)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Self.keychainService,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func keychainDelete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: Self.keychainService
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func migrateUserDefaultsToKeychain() {
        let defaults = UserDefaults.standard
        for key in [Self.tokenKey, Self.licenseKey, Self.expiresKey] {
            if let value = defaults.string(forKey: key), keychainRead(key) == nil {
                keychainWrite(key, value: value)
                defaults.removeObject(forKey: key)
            }
        }
    }

    var isLoggedIn: Bool {
        keychainRead(Self.tokenKey) != nil
    }

    var authToken: String? {
        keychainRead(Self.tokenKey)
    }

    var savedLicenseKey: String? {
        keychainRead(Self.licenseKey)
    }

    var expiresAt: String? {
        keychainRead(Self.expiresKey)
    }

    var userName: String? {
        UserDefaults.standard.string(forKey: Self.userNameKey)
    }

    func setUserName(_ name: String) {
        UserDefaults.standard.set(name, forKey: Self.userNameKey)
    }

    private var profileImageURL: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docs.appendingPathComponent("compass_profile.jpg")
    }

    var profileImage: UIImage? {
        guard let url = profileImageURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func setProfileImage(_ image: UIImage?) {
        guard let url = profileImageURL else { return }
        if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: url)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    var daysRemaining: Int? {
        guard let raw = expiresAt, raw.uppercased() != "LIFETIME" else { return nil }

        var date: Date?

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        date = iso.date(from: raw)

        if date == nil {
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: raw)
        }

        if date == nil {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(identifier: "UTC")
            for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss"] {
                f.dateFormat = fmt
                if let d = f.date(from: raw) { date = d; break }
            }
        }

        guard let expiry = date else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return max(days, 0)
    }

    var isLifetime: Bool {
        expiresAt?.uppercased() == "LIFETIME"
    }

    struct LoginResult {
        let success: Bool
        let token: String?
        let expiresAt: String?
        let error: String?
    }

    func login(licenseKey: String) async -> LoginResult {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/login") else {
            return LoginResult(success: false, token: nil, expiresAt: nil, error: "Invalid server URL.")
        }

        let deviceHash = deviceIdentifier()
        let body: [String: Any] = [
            "key": licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            "device_hash": deviceHash,
            "device_name": AppInfo.displayMachineName,
            "device_model": AppInfo.displayMachineName,
            "os_version": "iOS \(AppInfo.osVersion)"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return LoginResult(success: false, token: nil, expiresAt: nil, error: "No response from server.")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return LoginResult(success: false, token: nil, expiresAt: nil, error: "Invalid server response.")
            }

            if http.statusCode == 200, json["success"] as? Bool == true {
                let token = json["token"] as? String ?? ""
                let expires = json["expires_at"] as? String ?? "LIFETIME"

                keychainWrite(Self.tokenKey, value: token)
                keychainWrite(Self.licenseKey, value: licenseKey.uppercased())
                keychainWrite(Self.expiresKey, value: expires)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.loginTimeKey)

                return LoginResult(success: true, token: token, expiresAt: expires, error: nil)
            } else {
                let detail = json["detail"] as? String ?? "Login failed."
                return LoginResult(success: false, token: nil, expiresAt: nil, error: detail)
            }
        } catch {
            return LoginResult(success: false, token: nil, expiresAt: nil, error: "Network error: \(error.localizedDescription)")
        }
    }

    func logout() {
        keychainDelete(Self.tokenKey)
        keychainDelete(Self.licenseKey)
        keychainDelete(Self.expiresKey)
        UserDefaults.standard.removeObject(forKey: Self.loginTimeKey)
        UserDefaults.standard.removeObject(forKey: Self.userNameKey)
        setProfileImage(nil)
    }

    func handleActivationURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return }

        let key = queryItems.first(where: { $0.name == "key" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let udid = queryItems.first(where: { $0.name == "udid" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let token = queryItems.first(where: { $0.name == "token" })?.value

        if let udid = udid, !udid.isEmpty {
            saveUDIDToKeychain(udid)
        }

        if let key = key, !key.isEmpty, let token = token, !token.isEmpty {
            keychainWrite(Self.tokenKey, value: token)
            keychainWrite(Self.licenseKey, value: key)
            keychainWrite(Self.expiresKey, value: "LIFETIME")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.loginTimeKey)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .byteDidLogin, object: nil)
            }
        }
    }

    func saveUDIDToKeychain(_ udid: String) {
        let tag = "com.compass.hardware_udid"
        let service = "CompassAuth"
        guard let data = udid.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func getHardwareUDID() -> String? {
        let tag = "com.compass.hardware_udid"
        let service = "CompassAuth"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let val = String(data: data, encoding: .utf8),
           !val.isEmpty {
            return val
        }
        return nil
    }

    func deviceIdentifier() -> String {
        if let udid = MobileGestaltService.readUDID() {
            saveUDIDToKeychain(udid)
            return udid
        }

        if let stored = getHardwareUDID() {
            return stored
        }

        let tag = "com.compass.device_identifier"
        let service = "CompassAuth"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let st = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if st == errSecSuccess,
           let data = dataTypeRef as? Data,
           let savedId = String(data: data, encoding: .utf8),
           !savedId.isEmpty {
            return savedId
        }

        let id = buildStableFingerprint()

        if let data = id.data(using: .utf8) {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: tag,
                kSecAttrService as String: service,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            SecItemDelete(query as CFDictionary)
            SecItemAdd(addQuery as CFDictionary, nil)
        }

        return id
    }

    private func buildStableFingerprint() -> String {
        let vendor = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let model = AppInfo.machineName
        let totalDisk = totalDiskBytes()
        let totalRAM = ProcessInfo.processInfo.physicalMemory

        let raw = "\(vendor)|\(model)|\(totalDisk)|\(totalRAM)"
        return sha256Hex(raw)
    }

    private func totalDiskBytes() -> UInt64 {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ), let total = attrs[.systemSize] as? UInt64 else { return 0 }
        return total
    }

    private func sha256Hex(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else { return UUID().uuidString }
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { ptr in
            _ = CC_SHA256(ptr.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

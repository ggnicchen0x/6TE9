import Foundation
import UIKit

extension Notification.Name {
    static let byteDidLogout = Notification.Name("byteDidLogout")
}

final class ByteAuthService {
    static let shared = ByteAuthService()

    private let baseURL = "http://fi7.bot-hosting.cloud:25037"
    private let session = URLSession(configuration: {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        c.timeoutIntervalForResource = 30
        return c
    }())

    private init() {}

    private static let tokenKey = "byte_auth_token"
    private static let licenseKey = "byte_license_key"
    private static let expiresKey = "byte_license_expires"
    private static let loginTimeKey = "byte_login_time"
    private static let userNameKey = "byte_user_name"

    var isLoggedIn: Bool {
        UserDefaults.standard.string(forKey: Self.tokenKey) != nil
    }

    var savedLicenseKey: String? {
        UserDefaults.standard.string(forKey: Self.licenseKey)
    }

    var expiresAt: String? {
        UserDefaults.standard.string(forKey: Self.expiresKey)
    }

    var userName: String? {
        UserDefaults.standard.string(forKey: Self.userNameKey)
    }

    func setUserName(_ name: String) {
        UserDefaults.standard.set(name, forKey: Self.userNameKey)
    }

    var daysRemaining: Int? {
        guard let raw = expiresAt, raw.uppercased() != "LIFETIME" else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: raw) ?? {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            f.timeZone = TimeZone(identifier: "UTC")
            return f.date(from: raw)
        }()
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
            "device_name": UIDevice.current.name,
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

                UserDefaults.standard.set(token, forKey: Self.tokenKey)
                UserDefaults.standard.set(licenseKey.uppercased(), forKey: Self.licenseKey)
                UserDefaults.standard.set(expires, forKey: Self.expiresKey)
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
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: Self.licenseKey)
        UserDefaults.standard.removeObject(forKey: Self.expiresKey)
        UserDefaults.standard.removeObject(forKey: Self.loginTimeKey)
        UserDefaults.standard.removeObject(forKey: Self.userNameKey)
    }

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
}

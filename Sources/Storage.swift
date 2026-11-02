import Foundation
import Security
import Darwin

struct AccountState: Codable, Equatable, Sendable {
    let username: String
    let revision: UUID
}

enum Storage {
    static var group: String { Bundle.main.object(forInfoDictionaryKey: "PulseAppGroup") as? String ?? "" }
    static func root() throws -> URL {
        guard !group.isEmpty, !group.contains("$("), let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { throw PulseError.message("App Group unavailable. Check signing and entitlements.") }
        return root
    }
    // Serialize account changes and cache commits across the host and extension.
    static func locked<T>(_ operation: (URL) throws -> T) throws -> T {
        let root = try root()
        let fd = open(root.appendingPathComponent("account.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw PulseError.message("Cannot lock account storage.") }
        defer { close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw PulseError.message("Cannot lock account storage.") }
        defer { flock(fd, LOCK_UN) }
        return try operation(root)
    }
    static func state(at root: URL) throws -> AccountState {
        let url = root.appendingPathComponent("account.json")
        if FileManager.default.fileExists(atPath: url.path) { return try JSONDecoder().decode(AccountState.self, from: Data(contentsOf: url)) }
        // Preserve the existing account and Keychain account name from the legacy cache.
        let snapshot = try? JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: root.appendingPathComponent("snapshot.json")))
        let state = AccountState(username: snapshot?.username ?? "", revision: UUID())
        try JSONEncoder().encode(state).write(to: url, options: .atomic)
        return state
    }
    static func account() throws -> AccountState { try locked { try state(at: $0) } }
    static var username: String { (try? account().username) ?? "" }
    static func read() -> Snapshot? {
        try? locked { root in
            let account = try state(at: root)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: root.appendingPathComponent("snapshot.json")))
            guard !account.username.isEmpty, snapshot.username == account.username else { throw PulseError.message("No cached activity for this account.") }
            return snapshot
        }
    }
    static func query(username: String) -> [String: Any] {
        [kSecUseDataProtectionKeychain as String: true, kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "GitHubPulse", kSecAttrAccount as String: username,
         kSecAttrAccessGroup as String: Bundle.main.object(forInfoDictionaryKey: "PulseKeychainGroup") as? String ?? ""]
    }
    static func token(username: String) throws -> String? {
        var q = query(username: username); q[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) else { throw PulseError.message("Keychain read failed (\(status)).") }
        return token
    }
    static func deleteToken(username: String) throws {
        guard !username.isEmpty else { return }
        let status = SecItemDelete(query(username: username) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw PulseError.message("Keychain deletion failed (\(status)).") }
    }
    static func connect(username: String, token: String) throws {
        let name = try GitHub.validateUsername(username)
        try locked { root in
            let old = try state(at: root)
            if !token.isEmpty {
                let data = Data(token.utf8), q = query(username: name)
                var status = SecItemUpdate(q as CFDictionary, [kSecValueData as String: data] as CFDictionary)
                if status == errSecItemNotFound {
                    var add = q; add[kSecValueData as String] = data
                    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                    status = SecItemAdd(add as CFDictionary, nil)
                }
                guard status == errSecSuccess else { throw PulseError.message("Keychain write failed (\(status)).") }
            }
            guard try self.token(username: name) != nil else { throw PulseError.message("Enter a GitHub token for this account.") }
            if old.username != name { try deleteToken(username: old.username) }
            let next = AccountState(username: name, revision: UUID())
            try JSONEncoder().encode(next).write(to: root.appendingPathComponent("account.json"), options: .atomic)
            if old.username != name { try clearCache(at: root) }
        }
    }
    static func clearCache(at root: URL) throws {
        let url = root.appendingPathComponent("snapshot.json")
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
    static func disconnect() throws {
        try locked { root in
            let old = try state(at: root)
            try deleteToken(username: old.username)
            try JSONEncoder().encode(AccountState(username: "", revision: UUID())).write(to: root.appendingPathComponent("account.json"), options: .atomic)
            try clearCache(at: root)
        }
    }
    static func commit(_ result: Snapshot, account: AccountState, at root: URL) throws -> Snapshot {
        guard try state(at: root) == account else { throw PulseError.message("Account changed during refresh. Please try again.") }
        try JSONEncoder().encode(result).write(to: root.appendingPathComponent("snapshot.json"), options: .atomic)
        return result
    }
    static func refresh() async throws -> Snapshot {
        let account = try account()
        let result = try await GitHub.fetch(username: account.username, token: token(username: account.username) ?? "")
        return try locked { root in
return try commit(result, account: account, at: root)
        }
    }
}

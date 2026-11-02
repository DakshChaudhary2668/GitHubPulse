import Foundation
@main struct StorageChecks {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = Snapshot(username: "legacy-user", days: [], synced: Date())
        try JSONEncoder().encode(snapshot).write(to: root.appendingPathComponent("snapshot.json"))
        let account = try Storage.state(at: root)
        assert(account.username == "legacy-user")
        let reread = try Storage.state(at: root)
        assert(reread == account)
        _ = try Storage.commit(snapshot, account: account, at: root)
        let disconnected = AccountState(username: "", revision: UUID())
        try JSONEncoder().encode(disconnected).write(to: root.appendingPathComponent("account.json"))
        try Storage.clearCache(at: root)
        do { _ = try Storage.commit(snapshot, account: account, at: root); assertionFailure("Stale refresh restored cache") } catch {}
        assert(!FileManager.default.fileExists(atPath: root.appendingPathComponent("snapshot.json").path))
        print("Passed: legacy account migration, stable revision, cache commit/removal, stale-refresh rejection")
    }
}

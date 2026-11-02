import SwiftUI
import WidgetKit

@main struct PulseApp: App {
    var body: some Scene { WindowGroup("GitHub Pulse") { SettingsView() }.windowResizability(.contentSize) }
}
struct SettingsView: View {
    @State private var token = ""
    @State private var username = Storage.username
    @State private var confirmingDisconnect = false
    @State private var snapshot = Storage.read()
    @State private var status = ""
    @State private var busy = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("GitHub Pulse").font(.title2.bold())
            PulseCard(snapshot: snapshot).frame(width: 360, height: 180)
            TextField("GitHub username", text: $username).textFieldStyle(.roundedBorder).disabled(busy)
            SecureField("GitHub personal access token", text: $token).textFieldStyle(.roundedBorder)
            HStack {
                Button(busy ? "Syncing…" : "Save & refresh") { Task { await refresh() } }.disabled(busy)
                Link("Create token", destination: URL(string: "https://github.com/settings/tokens")!)
                Spacer()
                Link("Profile ↗", destination: URL(string: "https://github.com/\(Storage.username)")!)
            }
            Text(status.isEmpty ? ((try? Storage.token(username: Storage.username)) == nil ? "Token not configured" : "Token stored in Keychain") : status).font(.caption).textSelection(.enabled)
            Text("Use a classic token with read:user. Private activity depends on GitHub permissions and your profile visibility settings. Your token is stored only in Keychain.").font(.caption).foregroundStyle(.secondary)
            Button("Disconnect GitHub", role: .destructive) { confirmingDisconnect = true }.disabled(busy || Storage.username.isEmpty)
                .confirmationDialog("Disconnect GitHub?", isPresented: $confirmingDisconnect) {
                    Button("Disconnect", role: .destructive) { disconnect() }
                } message: { Text("Removes the saved token and cached activity from this Mac. Revoke the token separately on GitHub if needed.") }
            Text("Add to desktop").font(.headline)
            Text("Control-click the desktop → Edit Widgets → GitHub Pulse. Drag the medium widget below your wallpaper text. macOS chooses refresh times; refresh opportunities are requested every 30 minutes.").font(.callout).foregroundStyle(.secondary)
        }.padding(24).frame(width: 408).preferredColorScheme(.dark)
    }
    @MainActor func disconnect() {
        do { try Storage.disconnect(); token = ""; username = ""; snapshot = nil; status = "Disconnected. Revoke the token on GitHub if you no longer need it." }
        catch { snapshot = Storage.read(); status = error.localizedDescription }
        WidgetCenter.shared.reloadAllTimelines()
    }
    @MainActor func refresh() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            try Storage.connect(username: username, token: token.trimmingCharacters(in: .whitespacesAndNewlines)); token = ""
            snapshot = Storage.read()
            WidgetCenter.shared.reloadAllTimelines()
            let result = try await Storage.refresh()
            snapshot = result; status = "Synced successfully."
            WidgetCenter.shared.reloadAllTimelines()
        } catch { status = error.localizedDescription + (snapshot == nil ? "" : " Showing cached data.") }
    }
}

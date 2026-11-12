import SwiftUI
import WidgetKit
import AVFoundation

@main struct PulseApp: App {
    var body: some Scene {
        WindowGroup("GitHub Pulse", id: "main") {
            SettingsView()
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        }
        .windowResizability(.contentSize)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
struct SettingsView: View {
    @AppStorage("widgetAppearance", store: UserDefaults(suiteName: Storage.group)) private var appearance = "system"
    private let speech = PulseSpeech.shared.synthesizer
    @State private var token = ""
    @State private var username = Storage.username
    @State private var confirmingDisconnect = false
    @State private var snapshot = Storage.read()
    @State private var status = ""
    @State private var busy = false
    @State private var previewSize = "Medium"
    @State private var glassPreview = true
    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("GitHub Pulse").font(.title2.bold())
            Picker("Widget preview", selection: $previewSize) {
                ForEach(["Small", "Medium", "Large"], id: \.self) { Text($0) }
            }.pickerStyle(.segmented)
            Picker("Appearance (all widgets)", selection: Binding(get: { appearance }, set: { value in
                guard value != appearance else { return }
                UserDefaults(suiteName: Storage.group)?.set(Date().timeIntervalSince1970, forKey: "appearanceChangedAt")
                appearance = value
                WidgetCenter.shared.reloadTimelines(ofKind: "GitHubPulse")
            })) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
                Text("Transparent").tag("transparent")
            }.pickerStyle(.segmented)
            Toggle("Glass host preview", isOn: $glassPreview)
            PulseCard(snapshot: snapshot, large: previewSize == "Large", small: previewSize == "Small", glass: glassPreview)
                .frame(width: previewSize == "Small" ? 164 : 344, height: previewSize == "Large" ? 344 : 164)
                .frame(maxWidth: .infinity)
            Text("Preview changes immediately here. Resize the desktop widget separately using its context menu. Small and Large are square macOS widget formats; Medium is rectangular. Desktop glass and tint follow macOS widget appearance settings.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Speak contributions", systemImage: "speaker.wave.2") { speakContributions() }
                    .disabled(snapshot == nil || busy)
                Button("Stop speaking") { speech.stopSpeaking(at: .immediate) }
            }
            Text("Reads cached activity aloud on this Mac. No additional API key is needed.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("GitHub username", text: $username).textFieldStyle(.roundedBorder).disabled(busy)
            SecureField("GitHub personal access token", text: $token).textFieldStyle(.roundedBorder)
            HStack {
                Button(busy ? "Syncing…" : "Save & refresh") { Task { await refresh() } }.disabled(busy)
                Link("Create token", destination: URL(string: "https://github.com/settings/tokens")!)
                Spacer()
                Link("Profile ↗", destination: URL(string: "https://github.com/\(Storage.username)")!)
            }
            Text(status.isEmpty ? ((try? Storage.token(username: Storage.username)) == nil ? "Token not configured" : "Token stored in Keychain") : status).font(.caption).textSelection(.enabled)
            Text("Use a classic token with read:user. Private activity depends on GitHub permissions and your profile visibility settings. Your token is stored only in Keychain.").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button("Disconnect GitHub", role: .destructive) { confirmingDisconnect = true }.disabled(busy || Storage.username.isEmpty)
                .confirmationDialog("Disconnect GitHub?", isPresented: $confirmingDisconnect) {
                    Button("Disconnect", role: .destructive) { disconnect() }
                } message: { Text("Removes the saved token and cached activity from this Mac. Revoke the token separately on GitHub if needed.") }
            Text("Add to desktop").font(.headline)
            Text("Control-click the desktop → Edit Widgets → GitHub Pulse. Choose Small, Medium or Large and place it on your desktop. macOS chooses refresh times; refresh opportunities are requested every 30 minutes.").font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(24)
        }.frame(width: 408, height: previewSize == "Large" ? 780 : 700)
        .onOpenURL { url in
            guard url.scheme == "githubpulse", url.host == "speak", url.path.isEmpty,
                  url.query == nil, url.fragment == nil else { return }
            speakContributions()
        }
        .onDisappear { speech.stopSpeaking(at: .immediate) }
    }
    @MainActor private func speakContributions() {
        speech.stopSpeaking(at: .immediate)
        // Read storage at the time of the action, never a count supplied by a URL.
        snapshot = Storage.read()
        guard !busy, snapshot != nil else { return }
        PulseSpeech.shared.speak()
    }
    @MainActor func disconnect() {
        speech.stopSpeaking(at: .immediate)
        do { try Storage.disconnect(); token = ""; username = ""; snapshot = nil; status = "Disconnected. Revoke the token on GitHub if you no longer need it." }
        catch { snapshot = Storage.read(); status = error.localizedDescription }
        WidgetCenter.shared.reloadAllTimelines()
    }
    @MainActor func refresh() async {
        guard !busy else { return }; speech.stopSpeaking(at: .immediate); busy = true; defer { busy = false }
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

import SwiftUI
import WidgetKit
import AVFoundation
import Combine

@main struct PulseApp: App {
    init() {
        PulseDesktopPanel.shared.startObservingAppearance()
    }

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
    @ObservedObject private var desktopPanel = PulseDesktopPanel.shared
    @AppStorage("frostedPanelBackground") private var frostedPanelBackground = true
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
            Toggle("Transparent desktop panel", isOn: Binding(
                get: { desktopPanel.isVisible },
                set: { if $0 { desktopPanel.show() } else { desktopPanel.hide() } }
            ))
            Toggle("Frosted panel background", isOn: $frostedPanelBackground)
                .disabled(!desktopPanel.isVisible || appearance != "transparent")
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
            Text("Transparent opens the desktop panel. Turn off frosting for a clear background. Keep GitHub Pulse running to use the panel.")
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
        .onChange(of: previewSize) { _, value in PulseDesktopPanel.shared.resize(value) }
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
        NotificationCenter.default.post(name: .pulseStorageChanged, object: nil)
    }
    @MainActor func refresh() async {
        guard !busy else { return }; speech.stopSpeaking(at: .immediate); busy = true; defer { busy = false }
        do {
            try Storage.connect(username: username, token: token.trimmingCharacters(in: .whitespacesAndNewlines)); token = ""
            snapshot = Storage.read()
            NotificationCenter.default.post(name: .pulseStorageChanged, object: nil)
            WidgetCenter.shared.reloadAllTimelines()
            let result = try await Storage.refresh()
            snapshot = result; status = "Synced successfully."
            NotificationCenter.default.post(name: .pulseStorageChanged, object: nil)
            WidgetCenter.shared.reloadAllTimelines()
        } catch { status = error.localizedDescription + (snapshot == nil ? "" : " Showing cached data.") }
    }
}

extension Notification.Name {
    static let pulseStorageChanged = Notification.Name("PulseStorageChanged")
}

@MainActor final class PulseDesktopPanel: ObservableObject {
    static let shared = PulseDesktopPanel()
    @Published private(set) var isVisible = false
    private var panel: NSPanel?
    private var size = "Medium"
    private let defaults = UserDefaults(suiteName: Storage.group)
    private var lastAppearance: String?
    private var appearanceObserver: AnyCancellable?

    func startObservingAppearance() {
        // A native widget can change the shared preference from another process.
        appearanceObserver = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            let appearance = defaults?.string(forKey: "widgetAppearance") ?? "system"
            guard appearance != lastAppearance else { return }
            lastAppearance = appearance
            if appearance == "transparent", panel?.isVisible != true { show() }
        }
    }

    func show() {
        guard !isVisible else { return }
        if panel == nil {
            let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 344, height: 164), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            window.title = "GitHub Pulse Desktop"
            window.setAccessibilityLabel("GitHub Pulse transparent desktop panel")
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.isMovableByWindowBackground = true
            window.hidesOnDeactivate = false
            window.isReleasedWhenClosed = false
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            // Start away from the lower-right area used by the desktop widget.
            let frameName = "PulseDesktopPanelPosition"
            if !window.setFrameUsingName(frameName), let screen = NSScreen.main {
                window.setFrameTopLeftPoint(NSPoint(x: screen.visibleFrame.minX + 24, y: screen.visibleFrame.maxY - 24))
            }
            window.setFrameAutosaveName(frameName)
            panel = window
        }
        updateContent()
        panel?.orderFrontRegardless()
        isVisible = true
    }

    func resize(_ size: String) {
        self.size = size
        if panel?.isVisible == true { updateContent() }
    }

    func hide() {
        panel?.orderOut(nil)
        panel?.contentView = nil
        lastAppearance = defaults?.string(forKey: "widgetAppearance") ?? "system"
        isVisible = false
    }

    private func updateContent() {
        guard let panel else { return }
        let dimensions = NSSize(width: size == "Small" ? 164 : 344, height: size == "Large" ? 344 : 164)
        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        panel.contentView = NSHostingView(rootView: DesktopPulseCard(size: size))
        panel.setContentSize(dimensions)
        panel.setFrameTopLeftPoint(topLeft)
    }
}

private struct DesktopPulseCard: View {
    let size: String
    @AppStorage("frostedPanelBackground") private var frostedPanelBackground = true
    @AppStorage("widgetAppearance", store: UserDefaults(suiteName: Storage.group)) private var appearance = "system"
    @State private var snapshot = Storage.read()
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    var body: some View {
        PulseCard(snapshot: snapshot, desktop: true, large: size == "Large", small: size == "Small")
            .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
            .background {
                if appearance == "light" { Color.white }
                else if appearance == "dark" { Color.black }
                else if appearance == "system" { Color(nsColor: .windowBackgroundColor) }
                else if reduceTransparency || contrast == .increased { Color.black }
                else if frostedPanelBackground { DesktopFrost() }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contextMenu {
                Button("Hide desktop panel") { PulseDesktopPanel.shared.hide() }
            }
            .onReceive(timer) { _ in reloadSnapshot() }
            .onReceive(NotificationCenter.default.publisher(for: .pulseStorageChanged)) { _ in reloadSnapshot() }
    }

    private func reloadSnapshot() {
        snapshot = Storage.read()
    }
}

private struct DesktopFrost: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

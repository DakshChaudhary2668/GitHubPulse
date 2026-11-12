import SwiftUI
import WidgetKit
import AVFoundation
import Darwin
import OSLog

@main struct PulseEntry {
    @MainActor static func main() {
        if CommandLine.arguments.contains("--desktop-panel") {
            PulseDesktopPanel.shared.runHelper()
        } else {
            PulseApp.main()
        }
    }
}

struct PulseApp: App {
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
    @State private var username: String
    @State private var connectedUsername: String
    @State private var tokenConfigured: Bool?
    @State private var confirmingDisconnect = false
    @State private var snapshot = Storage.read()
    @State private var status = ""
    @State private var busy = false
    @AppStorage("desktopPanelSize", store: UserDefaults(suiteName: Storage.group)) private var previewSize = "Medium"
    @State private var glassPreview = true

    init() {
        let savedUsername = Storage.username
        _username = State(initialValue: savedUsername)
        _connectedUsername = State(initialValue: savedUsername)
    }

    private var connectionStatus: String {
        if !status.isEmpty { return status }
        guard let tokenConfigured else { return "Checking Keychain…" }
        return tokenConfigured ? "Token stored in Keychain" : "Token not configured"
    }

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("GitHub Pulse").font(.title2.bold())
            Toggle("Show desktop panel", isOn: Binding(
                get: { desktopPanel.isVisible },
                set: { if $0 { desktopPanel.show() } else { desktopPanel.hide() } }
            ))
            if appearance == "transparent" {
                Toggle("Frosted panel background", isOn: $frostedPanelBackground)
                    .disabled(!desktopPanel.isVisible)
            }
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
            Text("Transparent opens the desktop panel. Turn off frosting for a clear background. The panel stays open when you quit GitHub Pulse.")
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
                Link("Profile ↗", destination: URL(string: "https://github.com/\(connectedUsername)")!)
            }
            Text(connectionStatus).font(.caption).textSelection(.enabled)
            Text("Use a classic token with read:user. Private activity depends on GitHub permissions and your profile visibility settings. Your token is stored only in Keychain.").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button("Disconnect GitHub", role: .destructive) { confirmingDisconnect = true }.disabled(busy || connectedUsername.isEmpty)
                .confirmationDialog("Disconnect GitHub?", isPresented: $confirmingDisconnect) {
                    Button("Disconnect", role: .destructive) { disconnect() }
                } message: { Text("Removes the saved token and cached activity from this Mac. Revoke the token separately on GitHub if needed.") }
            Text("Add to desktop").font(.headline)
            Text("Control-click the desktop → Edit Widgets → GitHub Pulse. Choose Small, Medium or Large and place it on your desktop. macOS chooses refresh times; refresh opportunities are requested every 30 minutes.").font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(24)
        }.frame(width: 408, height: previewSize == "Large" ? 780 : 700)
        .task(id: connectedUsername) {
            let name = connectedUsername
            let configured = await Task.detached {
                !name.isEmpty && (try? Storage.token(username: name)) != nil
            }.value
            if !Task.isCancelled { tokenConfigured = configured }
        }
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
        do { try Storage.disconnect(); token = ""; username = ""; connectedUsername = ""; snapshot = nil; status = "Disconnected. Revoke the token on GitHub if you no longer need it." }
        catch { snapshot = Storage.read(); status = error.localizedDescription }
        WidgetCenter.shared.reloadAllTimelines()
    }
    @MainActor func refresh() async {
        guard !busy else { return }; speech.stopSpeaking(at: .immediate); busy = true; defer { busy = false }
        do {
            try Storage.connect(username: username, token: token.trimmingCharacters(in: .whitespacesAndNewlines)); token = ""
            connectedUsername = Storage.username
            snapshot = Storage.read()
            WidgetCenter.shared.reloadAllTimelines()
            let result = try await Storage.refresh()
            snapshot = result; status = "Synced successfully."
            WidgetCenter.shared.reloadAllTimelines()
        } catch { status = error.localizedDescription + (snapshot == nil ? "" : " Showing cached data.") }
    }
}

@MainActor final class PulseDesktopPanel: ObservableObject {
    static let shared = PulseDesktopPanel()
    @Published private(set) var isVisible = false
    @Published private(set) var snapshot: Snapshot?
    private var panel: NSPanel?
    private let defaults = UserDefaults(suiteName: Storage.group)
    private var lastAppearance: String?
    private var settingsObserver: PanelPreferenceObserver?
    private var frostObserver: PanelPreferenceObserver?
    private var cacheObserver: DispatchSourceFileSystemObject?
    private let logger = Logger(subsystem: "GitHubPulse", category: "DesktopPanel")

    func startObservingAppearance() {
        guard let defaults, settingsObserver == nil else { return }
        lastAppearance = defaults.string(forKey: "widgetAppearance")
        settingsObserver = PanelPreferenceObserver(defaults, keys: ["widgetAppearance", "desktopPanelEnabled"]) { [weak self] in
            self?.settingsChanged()
        }
        if defaults.object(forKey: "desktopPanelEnabled") == nil {
            defaults.set(lastAppearance == "transparent", forKey: "desktopPanelEnabled")
        }
        if defaults.bool(forKey: "desktopPanelEnabled") { show() }
    }

    private func settingsChanged() {
        isVisible = defaults?.bool(forKey: "desktopPanelEnabled") ?? false
        let appearance = defaults?.string(forKey: "widgetAppearance")
        guard appearance != lastAppearance else { return }
        lastAppearance = appearance
        if appearance == "transparent", !isVisible { show() }
    }

    func show() {
        guard let defaults, let executable = Bundle.main.executableURL else { return }
        defaults.set(true, forKey: "desktopPanelEnabled")
        let helper = Process()
        helper.executableURL = executable
        helper.arguments = ["--desktop-panel"]
        helper.standardInput = FileHandle.nullDevice
        helper.standardOutput = FileHandle.nullDevice
        helper.standardError = FileHandle.nullDevice
        do {
            try helper.run()
            isVisible = true
        } catch {
            defaults.set(false, forKey: "desktopPanelEnabled")
            isVisible = false
            logger.error("Could not start the desktop panel helper.")
        }
    }

    func hide() {
        defaults?.set(false, forKey: "desktopPanelEnabled")
        isVisible = false
    }

    func runHelper() {
        guard let defaults, let root = try? Storage.root(),
              defaults.bool(forKey: "desktopPanelEnabled") else { return }
        // Opening the main app again must not create a second desktop panel.
        let lock = open(root.appendingPathComponent("desktop-panel.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard lock >= 0 else { return }
        defer { close(lock) }
        guard flock(lock, LOCK_EX | LOCK_NB) == 0 else { return }
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        settingsObserver = PanelPreferenceObserver(defaults, keys: ["widgetAppearance", "desktopPanelEnabled", "desktopPanelSize"]) { [weak self] in
            self?.updateHelper()
        }
        frostObserver = PanelPreferenceObserver(.standard, keys: ["frostedPanelBackground"]) { [weak self] in
            self?.updateHelper()
        }
        // Watch the directory so atomically replaced cache files still send updates.
        let directory = open(root.path, O_EVTONLY)
        if directory >= 0 {
            let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: directory, eventMask: .write, queue: .main)
            source.setEventHandler { [weak self] in
                Task { @MainActor in self?.reloadSnapshot() }
            }
            source.setCancelHandler { close(directory) }
            source.resume()
            cacheObserver = source
        }
        reloadSnapshot()
        guard defaults.bool(forKey: "desktopPanelEnabled") else { return }
        showWindow()
        application.run()
    }

    private func updateHelper() {
        guard defaults?.bool(forKey: "desktopPanelEnabled") == true else {
            panel?.orderOut(nil)
            cacheObserver?.cancel()
            NSApplication.shared.terminate(nil)
            return
        }
        updateContent()
    }

    private func reloadSnapshot() {
        let latest = Storage.read()
        if latest != snapshot { snapshot = latest }
    }

    private func showWindow() {
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
        logger.info("Desktop panel helper displayed its window.")
    }

    private func updateContent() {
        guard let panel else { return }
        let size = defaults?.string(forKey: "desktopPanelSize") ?? "Medium"
        let dimensions = NSSize(width: size == "Small" ? 164 : 344, height: size == "Large" ? 344 : 164)
        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        let content = NSHostingView(rootView: DesktopPulseCard(size: size, dimensions: dimensions, model: self))
        content.sizingOptions = []
        panel.contentView = content
        panel.setContentSize(dimensions)
        panel.setFrameTopLeftPoint(topLeft)
    }
}

private final class PanelPreferenceObserver: NSObject {
    private let defaults: UserDefaults
    private let keys: [String]
    private let changed: @MainActor @Sendable () -> Void

    init(_ defaults: UserDefaults, keys: [String], changed: @escaping @MainActor @Sendable () -> Void) {
        self.defaults = defaults
        self.keys = keys
        self.changed = changed
        super.init()
        for key in keys { defaults.addObserver(self, forKeyPath: key, options: [], context: nil) }
    }

    deinit {
        for key in keys { defaults.removeObserver(self, forKeyPath: key) }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        Task { @MainActor [changed] in changed() }
    }
}

private struct DesktopPulseCard: View {
    let size: String
    let dimensions: NSSize
    @ObservedObject var model: PulseDesktopPanel
    @AppStorage("frostedPanelBackground") private var frostedPanelBackground = true
    @AppStorage("widgetAppearance", store: UserDefaults(suiteName: Storage.group)) private var appearance = "system"
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private var isClear: Bool {
        appearance == "transparent" && !frostedPanelBackground && !reduceTransparency && contrast != .increased
    }
    var body: some View {
        PulseCard(snapshot: model.snapshot, desktop: true, large: size == "Large", small: size == "Small")
            .frame(width: dimensions.width, height: dimensions.height)
            .shadow(color: isClear ? .black.opacity(0.6) : .clear, radius: 2, y: 1)
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

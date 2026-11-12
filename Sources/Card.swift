import SwiftUI
import WidgetKit
import AppIntents
import AVFoundation
import OSLog

struct PulseCard: View {
    let snapshot: Snapshot?
    var failed = false
    var widget = false
    var desktop = false
    var large = false
    var small = false
    var glass = true
    @AppStorage("widgetAppearance", store: UserDefaults(suiteName: Storage.group)) private var appearance = "system"
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.widgetRenderingMode) private var renderingMode
    private var ink: Color {
        if desktop && appearance == "transparent" { return .white }
        if widget && renderingMode != .fullColor { return .primary }
        return appearance == "light" ? .black : (appearance == "dark" ? .white : .primary)
    }
    private var mutedInk: Color { ink.opacity(0.75) }
    private var nextAppearance: String {
        switch appearance {
        case "system": "light"
        case "light": "dark"
        case "dark": "transparent"
        default: "system"
        }
    }
    private var stale: Bool { failed || snapshot.map { Date().timeIntervalSince($0.synced) > 3600 } ?? true }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if let snapshot {
                let days = snapshot.visible()
                let activeDays = days.reduce(0) { $0 + (($1?.contributionCount ?? 0) > 0 ? 1 : 0) }
                Spacer(minLength: 0)
                if large {
                    largeActivity(snapshot, days: days, activeDays: activeDays)
                } else if small {
                    HStack(spacing: 6) {
                        VStack(spacing: 0) {
                            avatar(size: 32)
                            HStack(spacing: 0) { themeButton; speaker }
                        }
                        Spacer(minLength: 0)
                        HStack(spacing: 8) {
                            metric("\(snapshot.annualTotal)", label: "Past year", size: 13)
                            metric("\(snapshot.streak())", label: "Day streak", size: 12)
                        }.fixedSize(horizontal: true, vertical: false)
                    }
                    heatmap(days).frame(width: 99, height: 48).frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 6) {
                        heatmap(days)
                        VStack(alignment: .leading, spacing: large ? 8 : 4) {
                            metric("\(snapshot.annualTotal)", label: "Past year", size: large ? 24 : 16)
                            metric("\(snapshot.streak())", label: "Day streak", size: large ? 18 : 12)
                        }.fixedSize(horizontal: true, vertical: false)
                        avatar(size: 88)
                    }.frame(maxWidth: .infinity)
                }
                Spacer(minLength: 0)
                footer(snapshot, activeDays: activeDays)
            } else {
                Text("Connect GitHub").font(small ? .subheadline.bold() : .headline)
                Text("Open GitHub Pulse to add your token securely.").font(.caption).foregroundStyle(mutedInk)
                Spacer(minLength: 0)
            }
        }
        .padding(small ? 10 : (large ? 16 : 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(ink)
        .modifier(PulseSurface(enabled: !widget && !desktop, glass: glass, transparent: appearance == "transparent", solid: appearance == "light" ? .white : (appearance == "dark" ? .black : nil)))
        .modifier(PulseHostScheme(enabled: !widget, scheme: appearance == "light" ? .light : (appearance == "dark" ? .dark : systemScheme)))
    }
    private var header: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot?.username ?? "GitHub Pulse")
                    .font(.system(size: small ? 14 : (large ? 18 : 15), weight: .bold))
                    .lineLimit(small ? 2 : 1).minimumScaleFactor(small ? 0.8 : 0.75)
                    .fixedSize(horizontal: false, vertical: true)
                if !small {
                    Text(snapshot == nil ? "GitHub" : (stale ? "Cached activity" : "GitHub activity"))
                        .font(.system(size: 10)).foregroundStyle(mutedInk)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, !small && !large ? 3 : 0)
            if large {
                VStack(spacing: 4) {
                    HStack(spacing: 8) { themeButton; if (widget || desktop) && snapshot != nil { speaker } }
                    avatar(size: 96)
                }
            } else if !small {
                Group {
                    HStack(spacing: 2) { themeButton; if (widget || desktop) && snapshot != nil { speaker } }
                }.frame(width: 88).padding(.top, 3)
            }
        }
    }
    private func largeActivity(_ snapshot: Snapshot, days: [Day?], activeDays: Int) -> some View {
        let periodTotal = days.reduce(0) { $0 + ($1?.contributionCount ?? 0) }
        return VStack(spacing: 4) {
            HStack(alignment: .top) {
                metric("\(snapshot.annualTotal)", label: "Past year", size: 20)
                Spacer()
                metric("\(snapshot.streak())", label: "Day streak", size: 20)
            }
            heatmap(days).frame(width: 191, height: 94)
                .frame(maxWidth: .infinity)
            HStack(alignment: .top) {
                metric("\(periodTotal)", label: "In 14 weeks", size: 18)
                Spacer()
                metric("\(activeDays)", label: "Active days", size: 18)
            }
        }
    }
    private var themeButton: some View {
        let icon = Image(systemName: appearance == "light" ? "sun.max" : (appearance == "dark" ? "moon" : "circle.lefthalf.filled"))
            .font(.caption).padding(4)
        return Group {
            if desktop {
                Button { SetPulseAppearance.apply(nextAppearance) } label: { icon }
            } else {
                Button(intent: SetPulseAppearance(appearance: nextAppearance)) { icon }
            }
        }.buttonStyle(.plain)
            .accessibilityLabel("Appearance: \(appearance). Switch to \(nextAppearance)")
    }
    private var speaker: some View {
        let icon = Image(systemName: "speaker.wave.2").font(.caption).padding(4)
        return Group {
            if desktop {
                Button { PulseSpeech.shared.speak() } label: { icon }
            } else {
                Button(intent: SpeakPulseContributions()) { icon }
            }
        }.buttonStyle(.plain).accessibilityLabel("Speak contributions")
    }
    private func avatar(size: CGFloat) -> some View {
        Group {
            if let data = snapshot?.avatar, let image = NSImage(data: data) {
                if #available(macOS 15.0, *) {
                    // Preserve photo detail when macOS tints inactive desktop widgets.
                    Image(nsImage: image).resizable()
                        .widgetAccentedRenderingMode(.desaturated)
                        .scaledToFill()
                } else {
                    Image(nsImage: image).renderingMode(.original).resizable().scaledToFill()
                }
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().foregroundStyle(mutedInk)
            }
        }.frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
    private func metric(_ value: String, label: String, size: CGFloat = 24) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: size, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(label).font(.system(size: small ? 8 : (large ? 11 : 9))).foregroundStyle(mutedInk)
        }.accessibilityElement(children: .combine)
    }
    private func heatmap(_ days: [Day?]) -> some View {
        HStack(spacing: !small && !large ? 2 : 3) {
            ForEach(0..<14) { week in
                VStack(spacing: !small && !large ? 2 : 3) {
                    ForEach(0..<7) { row in
                        let day = days.indices.contains(week * 7 + row) ? days[week * 7 + row] : nil
                        RoundedRectangle(cornerRadius: large ? 2 : 1)
                            .fill(cellColor(day))
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: !small && !large ? 9 : nil, height: !small && !large ? 9 : nil)
                            .opacity(cellOpacity(day))
                            .widgetAccentable(day.map { $0.contributionCount > 0 } ?? false)
                            .accessibilityLabel(day.map { "\($0.date): \($0.contributionCount) contributions" } ?? "Date unavailable")
                    }
                }
            }
        }.accessibilityElement(children: .contain)
    }
    private func cellColor(_ day: Day?) -> Color {
        guard let day, day.contributionCount > 0 else { return ink.opacity(contrast == .increased ? 0.22 : 0.09) }
        if widget && renderingMode != .fullColor { return .primary }
        let levels = ["FIRST_QUARTILE", "SECOND_QUARTILE", "THIRD_QUARTILE", "FOURTH_QUARTILE"]
        let colors: [Color] = [Color(red: 0.08, green: 0.38, blue: 0.19), Color(red: 0.10, green: 0.52, blue: 0.23), Color(red: 0.12, green: 0.68, blue: 0.28), Color(red: 0.15, green: 0.83, blue: 0.33)]
        return colors[levels.firstIndex(of: day.contributionLevel) ?? 0]
    }
    private func cellOpacity(_ day: Day?) -> Double {
        guard let day else { return 0.3 }
        guard widget && renderingMode != .fullColor && day.contributionCount > 0 else { return 1 }
        return ["FIRST_QUARTILE": 0.4, "SECOND_QUARTILE": 0.6, "THIRD_QUARTILE": 0.8, "FOURTH_QUARTILE": 1.0][day.contributionLevel] ?? 1
    }
    private func footer(_ snapshot: Snapshot, activeDays: Int) -> some View {
        HStack(spacing: 3) {
            Group {
                Text(large ? "Graph: 14 weeks" : (small ? "\(activeDays) active" : "\(activeDays) active days"))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel(large ? "Graph: 14 weeks" : "\(activeDays) active days in the displayed 14 weeks")
                Spacer(minLength: 3)
            }
            if !small { Text(stale ? "Cached" : "Synced") }
            Text(snapshot.synced, style: desktop ? .time : .relative).lineLimit(1).minimumScaleFactor(0.8)
        }.font(.system(size: small ? 8 : 9)).foregroundStyle(mutedInk)
    }
}

// Materials are host-only; WidgetKit owns its supported background rendering.
struct PulseSurface: ViewModifier {
    var enabled = true
    var glass = true
    var transparent = false
    var solid: Color? = nil
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    func body(content: Content) -> some View {
        if !enabled { content }
        else if !glass || reduceTransparency || contrast == .increased {
            content.background(solid ?? Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 20))
        } else if #available(macOS 26.0, *) {
            content.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// Static highlights work in WidgetKit without unsupported live blur effects.
struct PulseGlassTint: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.10))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.18), .clear, .white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.48), .white.opacity(0.08), .white.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75)
            }
            .accessibilityHidden(true)
    }
}

struct SetPulseAppearance: AppIntent {
    static let title: LocalizedStringResource = "Change widget appearance"
    static let openAppWhenRun = false
    @Parameter(title: "Appearance") var appearance: String
    init() {}
    init(appearance: String) { self.appearance = appearance }
    func perform() async throws -> some IntentResult {
        Self.apply(appearance)
        return .result()
    }

    static func apply(_ appearance: String) {
        guard ["system", "light", "dark", "transparent"].contains(appearance), !Storage.group.isEmpty,
              let defaults = UserDefaults(suiteName: Storage.group) else { return }
        guard defaults.string(forKey: "widgetAppearance") != appearance else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: "appearanceChangedAt")
        defaults.set(appearance, forKey: "widgetAppearance")
        // WidgetKit reloads after an extension intent; only host actions need this request.
        if Bundle.main.bundleURL.pathExtension != "appex" {
            WidgetCenter.shared.reloadTimelines(ofKind: "GitHubPulse")
        }
    }
}

@MainActor final class PulseSpeech: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = PulseSpeech()
    let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "GitHubPulse", category: "Speech")
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let count = NSApplication.shared.windows.filter(\.isVisible).count
            self.logger.info("Local speech started; visible host windows: \(count)")
        }
    }
    func speak() {
        synthesizer.stopSpeaking(at: .immediate)
        guard let snapshot = Storage.read() else { return }
        let utterance = AVSpeechUtterance(string: snapshot.speechSummary())
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

struct SpeakPulseContributions: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Speak contributions"
    static let openAppWhenRun = false
    @MainActor func perform() async throws -> some IntentResult {
        PulseSpeech.shared.speak()
        return .result()
    }
}

private struct PulseHostScheme: ViewModifier {
    let enabled: Bool
    let scheme: ColorScheme
    func body(content: Content) -> some View {
        if enabled { content.environment(\.colorScheme, scheme) }
        else { content }
    }
}

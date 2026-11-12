import SwiftUI
import WidgetKit
struct Entry: TimelineEntry { let date: Date; let snapshot: Snapshot?; var failed = false }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: Date(), snapshot: Storage.read())) }
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
        let now = Date()
        let changedAt = UserDefaults(suiteName: Storage.group)?.object(forKey: "appearanceChangedAt") as? Double
        if let cached = Storage.read(),
           let next = WidgetRefreshPolicy.cachedRefreshDate(synced: cached.synced, appearanceChangedAt: changedAt.map { Date(timeIntervalSince1970: $0) }, now: now) {
            completion(Timeline(entries: [Entry(date: now, snapshot: cached)], policy: .after(next)))
            return
        }
        Task {
            var snapshot = Storage.read(), failed = false
            do { snapshot = try await Storage.refresh() } catch { snapshot = Storage.read(); failed = true }
            completion(Timeline(entries: [Entry(date: Date(), snapshot: snapshot, failed: failed)], policy: .after(Date().addingTimeInterval(1800))))
        }
    }
}
struct WidgetCard: View {
    @AppStorage("widgetAppearance", store: UserDefaults(suiteName: Storage.group)) private var appearance = "system"
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private var backgroundOpacity: Double { reduceTransparency || contrast == .increased ? 1 : 0.20 }
    @Environment(\.widgetFamily) private var family
    let entry: Entry
    var body: some View {
        PulseCard(snapshot: entry.snapshot, failed: entry.failed, widget: true, large: family == .systemLarge, small: family == .systemSmall)
            .containerBackground(for: .widget) {
                if appearance == "transparent" && !reduceTransparency && contrast != .increased { PulseGlassTint() }
                else if appearance == "light" { Color.white }
                else if appearance == "dark" { Color.black }
                else { Color(nsColor: .windowBackgroundColor).opacity(backgroundOpacity) }
            }
            .widgetURL(URL(string: "https://github.com/\(entry.snapshot?.username ?? "")"))
    }
}
@main struct PulseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GitHubPulse", provider: Provider()) { entry in
            WidgetCard(entry: entry)
        }.configurationDisplayName("GitHub Pulse").description("Your last 14 weeks on GitHub.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
            .containerBackgroundRemovable(false)
            .contentMarginsDisabled()
    }
}

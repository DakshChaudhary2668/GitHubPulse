import SwiftUI
import WidgetKit
struct Entry: TimelineEntry { let date: Date; let snapshot: Snapshot?; var failed = false }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: Date(), snapshot: Storage.read())) }
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
        if let cached = Storage.read(), Date().timeIntervalSince(cached.synced) < 1800 {
            completion(Timeline(entries: [Entry(date: Date(), snapshot: cached)], policy: .after(cached.synced.addingTimeInterval(1800))))
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
    @Environment(\.widgetFamily) private var family
    let entry: Entry
    var body: some View {
        PulseCard(snapshot: entry.snapshot, failed: entry.failed, widget: true, large: family == .systemLarge, small: family == .systemSmall)
            .containerBackground(for: .widget) {
                if appearance == "light" { Color.white }
                else if appearance == "dark" { Color.black }
                else { Color(nsColor: .windowBackgroundColor) }
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
            .containerBackgroundRemovable(true)
            .contentMarginsDisabled()
    }
}

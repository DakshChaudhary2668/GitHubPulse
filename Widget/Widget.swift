import SwiftUI
import WidgetKit
struct Entry: TimelineEntry { let date: Date; let snapshot: Snapshot?; var failed = false }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: Date(), snapshot: Storage.read())) }
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
        Task {
            var snapshot = Storage.read(), failed = false
            do { snapshot = try await Storage.refresh() } catch { snapshot = Storage.read(); failed = true }
            completion(Timeline(entries: [Entry(date: Date(), snapshot: snapshot, failed: failed)], policy: .after(Date().addingTimeInterval(1800))))
        }
    }
}
struct WidgetCard: View {
    @Environment(\.widgetFamily) private var family
    let entry: Entry
    var body: some View {
        PulseCard(snapshot: entry.snapshot, failed: entry.failed, widget: true, large: family == .systemLarge)
            .environment(\.colorScheme, .dark)
            .containerBackground(for: .widget) { Color(white: 0.025) }
            .widgetURL(URL(string: "https://github.com/\(entry.snapshot?.username ?? "")"))
    }
}
@main struct PulseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GitHubPulse", provider: Provider()) { entry in
            WidgetCard(entry: entry)
        }.configurationDisplayName("GitHub Pulse").description("Your last 14 weeks on GitHub.")
            .supportedFamilies([.systemMedium, .systemLarge])
            .containerBackgroundRemovable(false)
            .contentMarginsDisabled()
    }
}

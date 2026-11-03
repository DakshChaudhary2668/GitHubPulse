import SwiftUI
import WidgetKit

struct PulseCard: View {
    let snapshot: Snapshot?
    var failed = false
    var widget = false
    var large = false
    var small = false
    var glass = true
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.widgetRenderingMode) private var renderingMode
    private var stale: Bool { failed || snapshot.map { Date().timeIntervalSince($0.synced) > 3600 } ?? true }
    private var days: [Day?] { snapshot?.visible() ?? [] }
    private var periodTotal: Int { days.compactMap { $0 }.reduce(0) { $0 + $1.contributionCount } }
    private var activeDays: Int { days.compactMap { $0 }.filter { $0.contributionCount > 0 }.count }
    var body: some View {
        VStack(alignment: .leading, spacing: small ? 4 : (large ? 8 : 6)) {
            header
            if let snapshot {
                Spacer(minLength: 0)
                HStack(spacing: small ? 8 : 14) {
                    heatmap
                    if !small && !large { Spacer(minLength: 12) }
                    VStack(alignment: .leading, spacing: small || !large ? 4 : 8) {
                        metric("\(snapshot.annualTotal)", label: "Past year", size: small ? 13 : (large ? 28 : 16))
                        metric("\(snapshot.streak())", label: "Day streak", size: small ? 12 : (large ? 22 : 12))
                    }.fixedSize(horizontal: true, vertical: false)
                }
                Spacer(minLength: 0)
                footer(snapshot)
            } else {
                Text("Connect GitHub").font(small ? .subheadline.bold() : .headline)
                Text("Open GitHub Pulse to add your token securely.").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .padding(small ? 10 : 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.primary)
        .modifier(PulseSurface(enabled: !widget, glass: glass))
    }
    private var header: some View {
        HStack(spacing: 10) {
            Group {
                if let data = snapshot?.avatar, let image = NSImage(data: data) {
                    Image(nsImage: image).resizable().scaledToFill()
                } else { Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().foregroundStyle(.secondary) }
            }.frame(width: small ? 24 : (large ? 38 : 32), height: small ? 24 : (large ? 38 : 32)).clipShape(Circle()).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot?.username ?? "GitHub Pulse").font(.system(size: small ? 11 : 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.75)
                if !small { Text(snapshot == nil ? "GitHub" : (stale ? "Cached activity" : "GitHub activity")).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
            if widget && !small && snapshot != nil {
                Link(destination: URL(string: "githubpulse://speak")!) {
                    Image(systemName: "speaker.wave.2").font(.caption)
                        .padding(4)
                }.accessibilityLabel("Speak contributions in GitHub Pulse")
            }
        }
    }
    private func metric(_ value: String, label: String, size: CGFloat = 24) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: size, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(label).font(.system(size: small ? 8 : (large ? 11 : 9))).foregroundStyle(.secondary)
        }.accessibilityElement(children: .combine)
    }
    private var heatmap: some View {
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
        guard let day, day.contributionCount > 0 else { return Color.primary.opacity(contrast == .increased ? 0.22 : 0.09) }
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
    private func footer(_ snapshot: Snapshot) -> some View {
        HStack(spacing: 3) {
            if !small { Text("Graph: 14 weeks"); Spacer(minLength: 4) }
            Text(stale ? "Cached" : "Synced")
            Text(snapshot.synced, style: .relative).lineLimit(1).minimumScaleFactor(0.8)
        }.font(.system(size: 10)).foregroundStyle(.secondary)
    }
}

// Materials are host-only; WidgetKit owns its supported background rendering.
struct PulseSurface: ViewModifier {
    var enabled = true
    var glass = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    func body(content: Content) -> some View {
        if !enabled { content }
        else if !glass || reduceTransparency || contrast == .increased {
            content.background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 20))
        } else if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

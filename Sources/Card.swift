import SwiftUI

struct PulseCard: View {
    let snapshot: Snapshot?
    var failed = false
    var widget = false
    var large = false
    private var stale: Bool { failed || snapshot.map { Date().timeIntervalSince($0.synced) > 3600 } ?? true }
    private let greens: [Color] = [Color(red: 0.06, green: 0.14, blue: 0.10), Color(red: 0.05, green: 0.29, blue: 0.15), Color(red: 0.02, green: 0.46, blue: 0.20), Color(red: 0.05, green: 0.65, blue: 0.25), Color(red: 0.12, green: 0.85, blue: 0.32)]
    var body: some View {
        VStack(alignment: .leading, spacing: large ? 22 : 6) {
            HStack(spacing: 9) {
                if let data = snapshot?.avatar, let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFill().frame(width: large ? 72 : 44, height: large ? 72 : 44).clipShape(Circle()) }
                else { Image(systemName: "person.crop.circle").font(.system(size: large ? 68 : 40)).frame(width: large ? 72 : 44, height: large ? 72 : 44) }
                VStack(alignment: .leading, spacing: 2) { Text(snapshot?.username ?? "GitHub Pulse").font(.system(size: 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8); Text("GitHub").font(.caption).foregroundStyle(.secondary) }
                Spacer(minLength: 0)
                if !stale, let snapshot, snapshot.streak() > 0 { Circle().fill(.green).frame(width: 6, height: 6).accessibilityLabel("Recent activity") }
            }
            if let snapshot {
                HStack(alignment: .center, spacing: 12) {
                    let days = snapshot.visible()
                    HStack(spacing: 3) {
                        ForEach(0..<14) { week in
                            VStack(spacing: 3) { ForEach(0..<7) { row in
                                let day = days[week * 7 + row]
                                RoundedRectangle(cornerRadius: 2).fill(color(day)).frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).opacity(day == nil ? 0.25 : 1).accessibilityLabel(day.map { "\($0.date): \($0.contributionCount) contributions" } ?? "Outside available dates")
                            } }
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(snapshot.annualTotal)").font(.system(size: 20, weight: .semibold)).monospacedDigit()
                        Text("Past year").font(.system(size: 9)).foregroundStyle(.secondary)
                        Text("\(snapshot.streak()) days").font(.system(size: 14, weight: .semibold)).monospacedDigit()
                        Text("Current streak").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                HStack { Text("Graph: 14 weeks"); Spacer(); Text(stale ? "Cached ·" : "Synced"); Text(snapshot.synced, style: .relative) }.font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                Text("Connect GitHub").font(.headline)
                Text("Open GitHub Pulse to securely add your token.").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }.foregroundStyle(.white).padding(large ? 20 : 14).frame(maxWidth: .infinity, maxHeight: .infinity).background(widget ? Color.clear : Color(white: 0.025), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(widget ? 0 : 0.25), lineWidth: 0.5))
    }
    func color(_ day: Day?) -> Color { let levels = ["NONE", "FIRST_QUARTILE", "SECOND_QUARTILE", "THIRD_QUARTILE", "FOURTH_QUARTILE"]; return greens[levels.firstIndex(of: day?.contributionLevel ?? "NONE") ?? 0] }
}

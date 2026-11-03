import Foundation
let now = ISO8601DateFormatter().date(from: "2026-11-03T12:00:00Z")!
func day(_ date: String, _ count: Int) -> Day { Day(date: date, contributionCount: count, contributionLevel: count == 0 ? "NONE" : "FIRST_QUARTILE") }
let snapshot = Snapshot(username: "test", days: [day("2026-11-01", 3), day("2026-11-02", 2), day("2026-11-03", 0)], synced: now)
assert(snapshot.streak(now: now) == 2)
assert(snapshot.visible(now: now).count == 98)
assert(snapshot.visible(now: now)[91]?.date == "2026-11-01")
assert(Snapshot(username: "test", days: [], synced: now).streak(now: now) == 0)
assert(Snapshot(username: "test", days: [day("2026-11-03", 1)], synced: now).streak(now: now) == 1)
let data = try JSONEncoder().encode(snapshot)
let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
assert(decoded.days.count == 3)
print("Passed: streak grace day, empty history, active today, Sunday alignment, 98 cells, Codable round-trip")

let annual = Snapshot(username: "test", days: [day("2026-01-01", 8), day("2026-11-02", 2)], synced: now, totalContributions: 17)
assert(annual.annualTotal == 17)
assert(annual.visible(now: now).compactMap { $0 }.reduce(0) { $0 + $1.contributionCount } == 2)
assert(decoded.annualTotal == 5)
let annualDecoded = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(annual))
assert(annualDecoded.annualTotal == 17)
print("Passed: API annual total, graph period separation, legacy cache fallback, annual total round-trip")

for name in ["octocat", "a", "my-name", String(repeating: "a", count: 39)] {
    let validated = try GitHub.validateUsername(name)
    assert(validated == name)
}
for name in ["", "-name", "name-", "a--b", "a/b", "a\"}", "a b", "é", String(repeating: "a", count: 40)] {
    do { _ = try GitHub.validateUsername(name); assertionFailure("Invalid username accepted") } catch {}
}
let trimmed = try GitHub.validateUsername(" octocat\n")
assert(trimmed == "octocat")
let missingToday = Snapshot(username: "test", days: [day("2026-11-02", 2)], synced: now)
assert(missingToday.streak(now: now) == 1)
let broken = Snapshot(username: "test", days: [day("2026-10-31", 3), day("2026-11-01", 0), day("2026-11-02", 2)], synced: now)
assert(broken.streak(now: now) == 1)
print("Passed: username trust boundary and streak gaps")

assert(annual.speechSummary(now: now).hasPrefix("17 GitHub contributions. 1-day streak. Synced at "))
let single = Snapshot(username: "example", days: [], synced: now, totalContributions: 1)
assert(single.speechSummary(now: now).hasPrefix("1 GitHub contribution. 0-day streak. Synced at "))
assert(snapshot.speechSummary(now: now).contains("5 GitHub contributions"))
assert(snapshot.speechSummary(now: now).contains("2-day streak"))
print("Passed: concise spoken annual total, legacy count, singular contribution and streak")

let oldSync = Snapshot(username: "test", days: [], synced: now.addingTimeInterval(-86400), totalContributions: 17)
assert(oldSync.speechSummary(now: now) != Snapshot(username: "test", days: [], synced: now, totalContributions: 17).speechSummary(now: now))
assert(!oldSync.speechSummary(now: now).contains("Cached"))
print("Passed: speech includes distinct sync date for older data without cache introduction")

let refreshNow = Date(timeIntervalSince1970: 2_000_000_000)
assert(WidgetRefreshPolicy.cachedRefreshDate(synced: refreshNow.addingTimeInterval(-100), appearanceChangedAt: nil, now: refreshNow) == refreshNow.addingTimeInterval(1700))
assert(WidgetRefreshPolicy.cachedRefreshDate(synced: refreshNow.addingTimeInterval(-4000), appearanceChangedAt: refreshNow, now: refreshNow) == refreshNow.addingTimeInterval(15))
assert(WidgetRefreshPolicy.cachedRefreshDate(synced: refreshNow.addingTimeInterval(-4000), appearanceChangedAt: refreshNow.addingTimeInterval(-15), now: refreshNow) == nil)
assert(WidgetRefreshPolicy.cachedRefreshDate(synced: refreshNow.addingTimeInterval(-4000), appearanceChangedAt: refreshNow.addingTimeInterval(60), now: refreshNow) == nil)
assert(WidgetRefreshPolicy.cachedRefreshDate(synced: refreshNow.addingTimeInterval(-4000), appearanceChangedAt: nil, now: refreshNow) == nil)
print("Passed: theme reload uses cached activity without network wait; normal refresh resumes and future timestamps are rejected")

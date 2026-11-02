import Foundation

struct Day: Codable, Sendable { let date: String; let contributionCount: Int; let contributionLevel: String }
struct Snapshot: Codable, Sendable {
    let username: String
    let days: [Day]
    let synced: Date
    var avatar: Data?
    var totalContributions: Int?
    var annualTotal: Int { totalContributions ?? days.reduce(0) { $0 + $1.contributionCount } }
    static var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    static func key(_ date: Date) -> String { let f = DateFormatter(); f.calendar = calendar; f.timeZone = calendar.timeZone; f.dateFormat = "yyyy-MM-dd"; return f.string(from: date) }
    func visible(now: Date = Date()) -> [Day?] {
        let c = Self.calendar, today = c.startOfDay(for: now)
        let sunday = c.date(byAdding: .day, value: -(c.component(.weekday, from: today) - 1) - 91, to: today)!
        let map = Dictionary(days.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
        return (0..<98).map { map[Self.key(c.date(byAdding: .day, value: $0, to: sunday)!)] }
    }
    func streak(now: Date = Date()) -> Int {
        let map = Dictionary(days.map { ($0.date, $0.contributionCount) }, uniquingKeysWith: { a, _ in a })
        var date = Self.calendar.startOfDay(for: now), count = 0
        if map[Self.key(date), default: 0] == 0 { date = Self.calendar.date(byAdding: .day, value: -1, to: date)! }
        while map[Self.key(date), default: 0] > 0 { count += 1; date = Self.calendar.date(byAdding: .day, value: -1, to: date)! }
        return count
    }
}
enum PulseError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}
struct GitHub {
    static func validateUsername(_ value: String) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.range(of: "^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$", options: .regularExpression) != nil,
              !name.contains("--") else { throw PulseError.message("Enter a valid GitHub username (1–39 letters, numbers or single hyphens).") }
        return name
    }
    static func request(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PulseError.message("No server response.") }
        guard http.statusCode == 200 else { throw PulseError.message(http.statusCode == 401 ? "Token rejected. Update your GitHub token." : "GitHub returned HTTP \(http.statusCode). Check permissions or rate limits and retry later.") }
        return data
    }
    static func fetch(username: String, token: String) async throws -> Snapshot {
        let username = try validateUsername(username)
        guard !token.isEmpty else { throw PulseError.message("Add a GitHub token to sync contributions.") }
        var r = URLRequest(url: URL(string: "https://api.github.com/graphql")!); r.httpMethod = "POST"; r.timeoutInterval = 25
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let query = "query { user(login: \"\(username)\") { contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount contributionLevel } } } } } }"
        r.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
        struct Reply: Decodable {
            struct Payload: Decodable { struct User: Decodable { struct Collection: Decodable { struct Calendar: Decodable { struct Week: Decodable { let contributionDays: [Day] }; let weeks: [Week]; let totalContributions: Int }; let contributionCalendar: Calendar }; let contributionsCollection: Collection }; let user: User? }; let data: Payload?
        }
        let reply = try JSONDecoder().decode(Reply.self, from: await request(r))
        guard let calendar = reply.data?.user?.contributionsCollection.contributionCalendar else { throw PulseError.message("GitHub could not return contributions. Check token permissions and account access.") }
        var snapshot = Snapshot(username: username, days: calendar.weeks.flatMap(\.contributionDays), synced: Date(), totalContributions: calendar.totalContributions)
        struct Profile: Decodable { let avatar_url: URL }
        let profile = try JSONDecoder().decode(Profile.self, from: await request(URLRequest(url: URL(string: "https://api.github.com/users/\(username)")!)))
        if profile.avatar_url.scheme == "https", profile.avatar_url.host == "avatars.githubusercontent.com" {
            snapshot.avatar = try? await request(URLRequest(url: profile.avatar_url))
        }
        return snapshot
    }
}

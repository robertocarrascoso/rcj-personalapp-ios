import Foundation
import Observation

struct Habit: Codable, Identifiable {
    var id = UUID()
    let title: String
    let target: Int?
}
enum GoalGroup: String, Codable, CaseIterable, Identifiable {
    case kill, gym, personal
    var id: Self { self }

    var title: String {
        switch self {
        case .kill: "Kill List"
        case .gym: "Gym Goals"
        case .personal: "Personal"
        }
    }

    var icon: String {
        switch self {
        case .kill: "flag.checkered"
        case .gym: "dumbbell.fill"
        case .personal: "person.fill"
        }
    }
}
struct Goal: Codable, Identifiable {
    var id = UUID()
    let title: String
    var group: GoalGroup
    var done = false
}
struct TrackPoint: Codable, Identifiable {
    let latitude: Double
    let longitude: Double
    let time: Date
    var id: Date { time }
}
struct Walk: Codable, Identifiable {
    var id = UUID()
    let start: Date
    var end: Date?
    var meters = 0.0
    var points: [TrackPoint] = []
}
struct PersonalData: Codable {
    var habits: [Habit] = []
    var goals: [Goal] = []
    var log: [String: [UUID: Int]] = [:]
    var walks: [Walk] = []
    var recording: Walk?
}
struct PersonalSeed: Decodable {
    struct HabitSeed: Decodable { let title: String; let target: Int? }
    struct GoalSeed: Decodable { let title: String; let group: GoalGroup }
    let habits: [HabitSeed]
    let goals: [GoalSeed]

    func makeData() throws -> PersonalData {
        guard habits.count <= 100, goals.count <= 300,
              habits.allSatisfy({ Store.validTitle($0.title) && ($0.target.map { (1...1440).contains($0) } ?? true) }),
              goals.allSatisfy({ Store.validTitle($0.title) }) else { throw CocoaError(.fileReadCorruptFile) }
        return PersonalData(habits: habits.map { Habit(title: $0.title, target: $0.target) },
                            goals: goals.map { Goal(title: $0.title, group: $0.group) })
    }
}
struct DayScore: Identifiable {
    let date: Date
    let completed: Int
    var id: Date { date }
}
@Observable final class Store {
    private(set) var data = PersonalData()
    private(set) var loadFailed = false
    var error: String?
    private let url: URL

    init(url: URL = URL.applicationSupportDirectory.appending(path: "RCJ/data.json"), seedURL: URL? = nil) {
        self.url = url
        do {
            var folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try folder.setResourceValues(values)
            if FileManager.default.fileExists(atPath: url.path) {
                data = try JSONDecoder().decode(PersonalData.self, from: Data(contentsOf: url))
            } else if let seedURL {
                try save(JSONDecoder().decode(PersonalSeed.self, from: Data(contentsOf: seedURL)).makeData())
            }
            if var walk = data.recording {
                var next = data
                if walk.points.count >= 2 {
                    walk.end = walk.points.last?.time
                    next.walks.insert(walk, at: 0)
                }
                next.recording = nil
                try save(next)
            }
        } catch {
            loadFailed = true
            self.error = "No se pudieron abrir tus datos. Se conserva el archivo original."
        }
    }

    private func save(_ next: PersonalData) throws {
        let bytes = try JSONEncoder().encode(next)
        #if os(iOS)
        try bytes.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        #else
        try bytes.write(to: url, options: .atomic)
        #endif
        data = next
    }

    @discardableResult
    func update(_ change: (inout PersonalData) -> Void) -> Bool {
        guard !loadFailed else {
            error = "El archivo de datos no está disponible."
            return false
        }
        var next = data
        change(&next)
        do { try save(next); return true }
        catch { self.error = "No se pudo guardar el cambio. Vuelve a intentarlo."; return false }
    }

    static func validTitle(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && title.count <= 180
    }

    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    func amount(_ habit: Habit, on date: Date) -> Int {
        data.log[Self.key(date)]?[habit.id] ?? 0
    }
    func completed(_ habit: Habit, on date: Date) -> Bool {
        amount(habit, on: date) >= (habit.target ?? 1)
    }
    @discardableResult
    func set(_ value: Int, habit: Habit, on date: Date) -> Bool {
        guard (0...1440).contains(value), data.habits.contains(where: { $0.id == habit.id }) else { return false }
        return update {
            let day = Self.key(date)
            var entries = $0.log[day] ?? [:]
            entries[habit.id] = value == 0 ? nil : value
            $0.log[day] = entries.isEmpty ? nil : entries
        }
    }

    func recentDays(_ count: Int, through end: Date = .now) -> [DayScore] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: end)
        return (0..<count).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: end) else { return nil }
            return DayScore(date: day, completed: data.habits.filter { completed($0, on: day) }.count)
        }
    }
    func streak(through end: Date = .now) -> Int {
        guard !data.habits.isEmpty else { return 0 }
        let cal = Calendar.current
        var day = cal.startOfDay(for: end)
        if !data.habits.allSatisfy({ completed($0, on: day) }) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var length = 0
        while data.habits.allSatisfy({ completed($0, on: day) }) {
            length += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: day), previous < day else { break }
            day = previous
        }
        return length
    }
    func summary(days: Int) -> ProgressSummary {
        ProgressSummary(days: days, habitCompletions: recentDays(days).reduce(0) { $0 + $1.completed },
                        habitOpportunities: days * data.habits.count,
                        goalsCompleted: data.goals.filter(\.done).count, goalsTotal: data.goals.count)
    }
}

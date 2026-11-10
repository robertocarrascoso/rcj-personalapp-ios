import Foundation
import Observation
#if os(iOS)
import UIKit
#endif

// modelos y el json donde se guarda todo, en el iphone

struct Habit: Codable, Identifiable {
    var id = UUID()
    let title: String
    let target: Int?
}
enum GoalGroup: String, Codable, CaseIterable, Identifiable {
    case kill, gym, muscleapp
    var id: Self { self }

    var title: String {
        switch self {
        case .kill: "Kill List"
        case .gym: "Gym Goals"
        case .muscleapp: "MuscleApp"
        }
    }

    var icon: String {
        switch self {
        case .kill: "flag.checkered"
        case .gym: "dumbbell.fill"
        case .muscleapp: "bolt.fill"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if value == "personal" { self = .kill }
        else if let group = Self(rawValue: value) { self = group }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Categoría desconocida") }
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
struct Trip: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var flag = "✈️"
    var notes = ""
    var visited = false
    var countryCode: String?
    var resolvedCountryCode: String? { countryCode ?? CountryAtlas.code(for: flag) }

    var isValid: Bool {
        Store.validTitle(title) && flag.count <= 8 && notes.count <= 100_000 &&
        (countryCode.map(CountryAtlas.validCode) ?? true)
    }
}
struct PersonalData: Codable {
    var habits: [Habit] = []
    var goals: [Goal] = []
    var log: [String: [UUID: Int]] = [:]
    var walks: [Walk] = []
    var recording: Walk?
    var stepGoal: Int?
    var trips: [Trip]?
    var goalsOrganized: Bool?
    var doneTopicIDs: [String]?
    var topicSession: TopicSession?
}
struct TopicSession: Codable, Equatable {
    var topicID: String
    var endsAt: Date
}
struct PersonalSeed: Decodable {
    struct HabitSeed: Decodable { let title: String; let target: Int? }
    struct GoalSeed: Decodable { let title: String; let group: GoalGroup }
    let habits: [HabitSeed]
    let goals: [GoalSeed]
    let trips: [Trip]?

    func makeData() throws -> PersonalData {
        guard habits.count <= 100, goals.count <= 300,
              habits.allSatisfy({ Store.validTitle($0.title) && ($0.target.map { (1...1440).contains($0) } ?? true) }),
              goals.allSatisfy({ Store.validTitle($0.title) }),
              (trips?.count ?? 0) <= 500, (trips ?? []).allSatisfy(\.isValid),
              Set((trips ?? []).map(\.id)).count == (trips?.count ?? 0) else { throw CocoaError(.fileReadCorruptFile) }
        return PersonalData(habits: habits.map { Habit(title: $0.title, target: $0.target) },
                            goals: goals.map { Goal(title: $0.title, group: $0.group) }, trips: trips)
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
    private let seedURL: URL?
    private var waitingForUnlock = false
    #if os(iOS)
    private var unlockObserver: NSObjectProtocol?
    #endif

    init(url: URL = URL.applicationSupportDirectory.appending(path: "RCJ/data.json"), seedURL: URL? = nil) {
        self.url = url
        self.seedURL = seedURL
        load()
        #if os(iOS)
        unlockObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.waitingForUnlock else { return }
            self.load()
        }
        #endif
    }

    private func load() {
        do {
            var folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try folder.setResourceValues(values)
            let exists = FileManager.default.fileExists(atPath: url.path)
            var next = PersonalData()
            var changed = !exists
            if exists {
                next = try JSONDecoder().decode(PersonalData.self, from: Data(contentsOf: url))
                allowUseWhileLocked()
            } else if let seedURL {
                next = try JSONDecoder().decode(PersonalSeed.self, from: Data(contentsOf: seedURL)).makeData()
            }
            // goals viejos que hablan de muscleapp pasan a esa categoria
            if next.goalsOrganized != true {
                for index in next.goals.indices {
                    if ["muscleapp", "trainer", "tiktok"].contains(where: { next.goals[index].title.localizedStandardContains($0) }) {
                        next.goals[index].group = .muscleapp
                    }
                }
                next.goalsOrganized = true
                changed = true
            }
            if next.trips == nil, let seedURL {
                next.trips = try JSONDecoder().decode(PersonalSeed.self, from: Data(contentsOf: seedURL)).makeData().trips ?? []
                changed = true
            }
            if var walk = next.recording {
                if walk.points.count >= 2 {
                    walk.end = walk.points.last?.time
                    next.walks.insert(walk, at: 0)
                }
                next.recording = nil
                changed = true
            }
            if changed { try save(next) } else { data = next }
            loadFailed = false
            waitingForUnlock = false
            error = nil
        } catch {
            if Self.isProtectedDataError(error) {
                waitingForUnlock = true
                loadFailed = false
            } else {
                waitingForUnlock = false
                loadFailed = true
                self.error = "No se pudieron abrir tus datos. Se conserva el archivo original."
            }
        }
    }

    private func allowUseWhileLocked() {
        #if os(iOS)
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
        #endif
    }

    private static func isProtectedDataError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == NSCocoaErrorDomain && ns.code == NSFileReadNoPermissionError { return true }
        if ns.domain == NSPOSIXErrorDomain && (ns.code == EPERM || ns.code == EACCES) { return true }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error { return isProtectedDataError(underlying) }
        return false
    }

    // escribe el json y luego actualiza lo que se ve
    private func save(_ next: PersonalData) throws {
        let bytes = try JSONEncoder().encode(next)
        #if os(iOS)
        try bytes.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try bytes.write(to: url, options: .atomic)
        #endif
        data = next
    }

    @discardableResult
    func update(_ change: (inout PersonalData) -> Void) -> Bool {
        guard !loadFailed, !waitingForUnlock else {
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

    @discardableResult
    func saveTrip(_ trip: Trip) -> Bool {
        guard trip.isValid else { return false }
        var trips = data.trips ?? []
        if let index = trips.firstIndex(where: { $0.id == trip.id }) { trips[index] = trip }
        else {
            guard trips.count < 500 else { return false }
            trips.append(trip)
        }
        return update { $0.trips = trips }
    }

    var countryStatuses: [String: CountryTravelStatus] {
        var statuses: [String: CountryTravelStatus] = [:]
        for trip in data.trips ?? [] {
            guard let code = trip.resolvedCountryCode else { continue }
            if trip.visited { statuses[code] = .visited }
            else if statuses[code] == nil { statuses[code] = .wanted }
        }
        return statuses
    }

    @discardableResult
    func markCountry(_ country: Country, visited: Bool) -> Bool {
        var trip = data.trips?.first {
            $0.resolvedCountryCode == country.code && $0.title.localizedStandardCompare(country.name) == .orderedSame
        } ?? Trip(title: country.name, flag: country.flag, countryCode: country.code)
        trip.visited = visited
        return saveTrip(trip)
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

    var dailyStepGoal: Int { data.stepGoal ?? 8_000 }

    func setDailyStepGoal(_ steps: Int) -> Bool {
        guard steps > 0 else { return false }
        return update { $0.stepGoal = steps }
    }

    var doneTopicIDs: Set<String> { Set(data.doneTopicIDs ?? []) }

    @discardableResult
    func beginTopic(_ id: String) -> Bool {
        let id = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard data.topicSession == nil, !id.isEmpty, !doneTopicIDs.contains(id) else { return false }
        return update {
            $0.topicSession = TopicSession(topicID: id, endsAt: .now.addingTimeInterval(15 * 60))
        }
    }

    @discardableResult
    func completeTopic() -> Bool {
        guard let id = data.topicSession?.topicID else { return false }
        return update {
            var done = $0.doneTopicIDs ?? []
            if !done.contains(id) { done.append(id) }
            $0.doneTopicIDs = done
            $0.topicSession = nil
        }
    }

    @discardableResult
    func cancelTopic() -> Bool {
        guard data.topicSession != nil else { return false }
        return update { $0.topicSession = nil }
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
    // dias seguidos con todos los habitos hechos. si hoy faltan, empieza desde ayer
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
}

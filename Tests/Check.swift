import Foundation

// prueba que guardar, la racha y el mapa no petan

@main enum Check {
    static func main() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let seed = directory.appending(path: "seed.json")
        let url = directory.appending(path: "store/data.json")
        try Data(#"{"habits":[{"title":"Example duration","target":30},{"title":"Example checkbox"}],"goals":[{"title":"Example goal","group":"gym"}]}"#.utf8).write(to: seed)
        let store = Store(url: url, seedURL: seed)
        precondition(!store.loadFailed && store.data.habits.count == 2 && store.data.goals.count == 1)
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -1, to: .now)!
        let duration = store.data.habits[0], check = store.data.habits[1]
        store.set(29, habit: duration, on: date)
        store.set(1, habit: check, on: date)
        precondition(!store.completed(duration, on: date) && !store.completed(check, on: .now))
        store.set(30, habit: duration, on: date)
        precondition(store.streak() == 1)
        precondition(store.recentDays(2).reduce(0) { $0 + $1.completed } == 2)
        let goal = store.data.goals[0]
        precondition(goal.group == .gym)
        precondition(store.update {
            $0.goals[0].done = true
            $0.goals[0].group = .muscleapp
        })
        let reopened = Store(url: url, seedURL: seed)
        precondition(reopened.data.goals[0].done && reopened.completed(duration, on: date))
        precondition(reopened.data.goals[0].id == goal.id && reopened.data.goals[0].group == .muscleapp)
        precondition(reopened.amount(duration, on: date) == 30 && reopened.amount(duration, on: .now) == 0)
        precondition(reopened.completed(check, on: date) && !reopened.completed(check, on: .now))
        precondition(reopened.dailyStepGoal == 8_000 && !reopened.setDailyStepGoal(0))
        precondition(reopened.setDailyStepGoal(6_500))
        precondition(Store(url: url).dailyStepGoal == 6_500)
        reopened.set(0, habit: check, on: date)
        precondition(reopened.streak() == 0)
        let corrupt = Data("corrupt".utf8)
        try corrupt.write(to: url)
        let damaged = Store(url: url, seedURL: seed)
        let after = try Data(contentsOf: url)
        precondition(damaged.loadFailed && !damaged.update { $0.goals = [] } && after == corrupt)

        let legacyURL = directory.appending(path: "legacy/data.json")
        try FileManager.default.createDirectory(at: legacyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let legacy = PersonalData(goals: [Goal(title: "Sacar Modo Trainer", group: .kill, done: true),
                                          Goal(title: "Subir 15 TikToks al día", group: .kill),
                                          Goal(title: "Redes de MuscleApp", group: .kill),
                                          Goal(title: "Leer más", group: .kill)])
        let trainerID = legacy.goals[0].id
        var legacyJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
        legacyJSON.removeValue(forKey: "trips")
        legacyJSON.removeValue(forKey: "goalsOrganized")
        var legacyGoals = legacyJSON["goals"] as! [[String: Any]]
        legacyGoals[3]["group"] = "personal"
        legacyJSON["goals"] = legacyGoals
        try JSONSerialization.data(withJSONObject: legacyJSON).write(to: legacyURL)
        let trip = Trip(title: "Irlanda", flag: "🇮🇪", notes: "Dos visitas", visited: true)
        let tripSeed: [String: Any] = ["habits": [], "goals": [],
                                      "trips": try JSONSerialization.jsonObject(with: JSONEncoder().encode([trip]))]
        try JSONSerialization.data(withJSONObject: tripSeed).write(to: seed)
        let migrated = Store(url: legacyURL, seedURL: seed)
        precondition(!migrated.loadFailed && migrated.data.goals.count == 4)
        precondition(migrated.data.goals.prefix(3).allSatisfy { $0.group == .muscleapp })
        precondition(migrated.data.goals[0].id == trainerID && migrated.data.goals[0].done)
        precondition(migrated.data.goals[3].group == .kill && migrated.data.trips == [trip])
        var editedTrip = trip
        editedTrip.notes = "Vuelo y hotel\nhttps://example.com"
        precondition(migrated.saveTrip(editedTrip))
        editedTrip.title = " "
        precondition(!migrated.saveTrip(editedTrip))
        editedTrip = trip
        editedTrip.notes = String(repeating: "x", count: 100_001)
        precondition(!migrated.saveTrip(editedTrip))
        precondition(migrated.update { $0.goals[0].group = .kill })
        let migratedAgain = Store(url: legacyURL, seedURL: seed)
        precondition(!migratedAgain.loadFailed && migratedAgain.data.trips?.count == 1)
        precondition(migratedAgain.data.trips?.first?.notes == "Vuelo y hotel\nhttps://example.com")
        precondition(migratedAgain.data.goals[0].group == .kill)
        precondition(migratedAgain.saveTrip(Trip(title: "Roma", flag: "🇮🇹")))
        precondition(Store(url: legacyURL).data.trips?.count == 2)

        let atlas = try CountryAtlas(url: URL(fileURLWithPath: "RCJ/Countries.json"))
        precondition(atlas.countries.count > 230)
        let spain = atlas.countries.first { $0.code == "ES" }!
        let usa = atlas.countries.first { $0.code == "US" }!
        precondition(spain.flag == "🇪🇸" && CountryAtlas.code(for: "🇮🇨") == "ES")
        precondition(CountryAtlas.code(for: "✈️") == nil && !CountryAtlas.validCode("bad"))
        precondition(atlas.country(latitude: 40.4168, longitude: -3.7038)?.code == "ES")
        precondition(atlas.country(latitude: 0, longitude: -30) == nil)
        precondition(atlas.country(latitude: .nan, longitude: 0) == nil)
        precondition(atlas.countries.contains { $0.code == "SG" })
        let holed = Country(code: "ZZ", name: "Test", latitude: 2, longitude: 2,
                            polygons: [[[[0,0],[10,0],[10,10],[0,10],[0,0]],
                                        [[3,3],[7,3],[7,7],[3,7],[3,3]]]])
        precondition(holed.contains(latitude: 2, longitude: 2) && !holed.contains(latitude: 5, longitude: 5))
        let travelStore = Store(url: directory.appending(path: "atlas/data.json"))
        let ny = Trip(title: "New York", flag: "🇺🇸", notes: "Reservas pendientes")
        precondition(travelStore.saveTrip(ny) && travelStore.countryStatuses["US"] == .wanted)
        precondition(travelStore.markCountry(usa, visited: true))
        precondition(travelStore.countryStatuses["US"] == .visited)
        precondition(travelStore.data.trips?.first { $0.id == ny.id } == ny)
        precondition(travelStore.markCountry(usa, visited: true) && travelStore.data.trips?.count == 2)
        precondition(travelStore.markCountry(spain, visited: false))
        let travelReopened = Store(url: directory.appending(path: "atlas/data.json"))
        precondition(travelReopened.countryStatuses["US"] == .visited && travelReopened.countryStatuses["ES"] == .wanted)
        precondition(travelReopened.data.trips?.first { $0.id == ny.id }?.notes == ny.notes)
        var reassigned = ny
        reassigned.countryCode = "ES"
        precondition(reassigned.resolvedCountryCode == "ES" && travelReopened.saveTrip(reassigned))
        reassigned.countryCode = "invalid"
        precondition(!travelReopened.saveTrip(reassigned))
        let invalidAtlas = directory.appending(path: "countries.json")
        try Data(#"[{"code":"ZZ","name":"Invalid","latitude":0,"longitude":0,"polygons":[[[[0]]]]}]"#.utf8).write(to: invalidAtlas)
        precondition((try? CountryAtlas(url: invalidAtlas)) == nil)
        let topicURL = directory.appending(path: "topics/data.json")
        let topics = Store(url: topicURL)
        precondition(topics.beginTopic("Impulso específico"))
        precondition(!topics.beginTopic("Otro"))
        precondition(topics.completeTopic() && topics.doneTopicIDs.contains("Impulso específico"))
        precondition(!topics.beginTopic("Impulso específico") && topics.beginTopic("Otro"))
        precondition(Store(url: topicURL).data.topicSession?.topicID == "Otro")
        precondition(Store(url: topicURL).doneTopicIDs.contains("Impulso específico"))
        print("OK: habitos, goals, viajes, mapa y temas.")
    }
}

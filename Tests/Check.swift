import CryptoKit
import Foundation

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
        precondition(store.streak() == 1 && store.summary(days: 2).habitCompletions == 2)
        let goal = store.data.goals[0]
        precondition(goal.group == .gym)
        precondition(store.update {
            $0.goals[0].done = true
            $0.goals[0].group = .personal
        })
        let reopened = Store(url: url, seedURL: seed)
        precondition(reopened.data.goals[0].done && reopened.completed(duration, on: date))
        precondition(reopened.data.goals[0].id == goal.id && reopened.data.goals[0].group == .personal)
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

        let key = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let wrongKey = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let original = PhoneRequest()
        let sealed = try Wire.seal(original, key: key, fromPhone: true)
        let decoded = try Wire.open(PhoneRequest.self, sealed, key: key, fromPhone: true)
        precondition(decoded.challenge == original.challenge)
        precondition((try? Wire.open(PhoneRequest.self, sealed, key: key, fromPhone: false)) == nil)
        precondition((try? Wire.open(PhoneRequest.self, sealed, key: wrongKey, fromPhone: true)) == nil)
        var tampered = sealed
        tampered[15] ^= 1
        precondition((try? Wire.open(PhoneRequest.self, tampered, key: key, fromPhone: true)) == nil)
        precondition(Pairing.privateIPv4("192.168.1.20") && !Pairing.privateIPv4("8.8.8.8") &&
                     !Pairing.privateIPv4("192.168.1.020") && !Pairing.privateIPv4("192.168.256.5"))
        precondition(!Approval(id: UUID(), consumer: .grok, days: 7, expires: .distantPast).valid)
        precondition(!Approval(id: UUID(), consumer: .grok, days: 31, expires: .now.addingTimeInterval(60)).valid)
        let gate = RequestGate(consumer: .grok, days: 7)
        let request = gate.reply(PhoneRequest()).approval!
        let summary = ProgressSummary(days: 7, habitCompletions: 3, habitOpportunities: 14,
                                      goalsCompleted: 1, goalsTotal: 2)
        precondition(gate.result == nil && request.consumer == .grok)
        precondition(gate.reply(PhoneRequest(decision: UUID(), summary: summary)).accepted != true && gate.result == nil)
        precondition(gate.reply(PhoneRequest(decision: request.id, summary: summary)).accepted == true)
        let approved = try gate.result?.get()
        precondition(approved?.habitCompletions == 3)
        precondition(gate.reply(PhoneRequest(decision: request.id, summary: summary)).accepted != true)
        let denied = RequestGate(consumer: .mcp, days: 7)
        let denialID = denied.reply(PhoneRequest()).approval!.id
        precondition(denied.reply(PhoneRequest(decision: denialID)).accepted == true)
        precondition((try? denied.result?.get()) == nil)
        print("OK: hábitos, persistencia, racha, cifrado, caducidad, aprobación, rechazo y antirrepetición.")
    }
}

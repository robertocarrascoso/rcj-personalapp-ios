import Foundation

final class RequestGate {
    private let approval: Approval
    private let lock = NSLock()
    private var outcome: Result<ProgressSummary, WireError>?

    init(consumer: Consumer, days: Int) {
        approval = Approval(id: UUID(), consumer: consumer, days: days, expires: .now.addingTimeInterval(120))
    }
    var expired: Bool { !approval.valid }
    var result: Result<ProgressSummary, WireError>? { lock.withLock { outcome } }

    func reply(_ message: PhoneRequest) -> MacReply {
        lock.withLock {
            var reply = MacReply(challenge: message.challenge)
            guard outcome == nil, approval.valid else { return reply }
            if let decision = message.decision {
                guard decision == approval.id else { return reply }
                if let summary = message.summary {
                    guard summary.days == approval.days,
                          (0...approval.days * 100).contains(summary.habitOpportunities),
                          (0...summary.habitOpportunities).contains(summary.habitCompletions),
                          (0...300).contains(summary.goalsTotal),
                          (0...summary.goalsTotal).contains(summary.goalsCompleted) else { return reply }
                    outcome = .success(summary)
                } else { outcome = .failure(.refused) }
                reply.accepted = true
            } else if message.summary == nil {
                reply.approval = approval
            }
            return reply
        }
    }
}

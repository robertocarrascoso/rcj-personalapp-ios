import CryptoKit
import Foundation
import Network

struct ProgressSummary: Codable {
    let days: Int
    let habitCompletions: Int
    let habitOpportunities: Int
    let goalsCompleted: Int
    let goalsTotal: Int
}

enum WireError: Error { case invalid, connection, expired, refused }

struct Pairing: Codable {
    let host: String
    let key: Data
    static let port: NWEndpoint.Port = 49273

    static func privateIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        let bytes = parts.compactMap { UInt8($0) }
        guard parts.count == 4, bytes.count == 4, bytes.map(String.init).joined(separator: ".") == host else { return false }
        return bytes[0] == 10 || (bytes[0] == 172 && (16...31).contains(bytes[1])) || (bytes[0] == 192 && bytes[1] == 168)
    }
    var valid: Bool { Self.privateIPv4(host) && key.count == 32 }
}

enum Consumer: String, Codable { case grok, mcp
    var title: String { self == .grok ? "Grok" : "Cliente MCP" }
}
struct Approval: Codable {
    let id: UUID
    let consumer: Consumer
    let days: Int
    let expires: Date
    var valid: Bool { (1...30).contains(days) && expires > .now && expires.timeIntervalSinceNow < 180 }
}
struct PhoneRequest: Codable {
    var challenge = UUID()
    var decision: UUID?
    var summary: ProgressSummary?
}
struct MacReply: Codable {
    let challenge: UUID
    var approval: Approval?
    var accepted: Bool?
}

enum Wire {
    static let maxBytes = 8_192
    static let queue = DispatchQueue(label: "com.rcj.bridge.network")
    static func seal<T: Encodable>(_ payload: T, key: Data, fromPhone: Bool) throws -> Data {
        let data = try JSONEncoder().encode(payload)
        let box = try AES.GCM.seal(data, using: SymmetricKey(data: key), authenticating: aad(fromPhone))
        guard let bytes = box.combined, bytes.count <= maxBytes else { throw WireError.invalid }
        return bytes
    }
    static func open<T: Decodable>(_ type: T.Type, _ data: Data, key: Data, fromPhone: Bool) throws -> T {
        guard data.count <= maxBytes, key.count == 32 else { throw WireError.invalid }
        let box = try AES.GCM.SealedBox(combined: data)
        let bytes = try AES.GCM.open(box, using: SymmetricKey(data: key), authenticating: aad(fromPhone))
        return try JSONDecoder().decode(type, from: bytes)
    }
    private static func aad(_ fromPhone: Bool) -> Data {
        Data((fromPhone ? "rcj-v1/phone" : "rcj-v1/mac").utf8)
    }
    static func send(_ data: Data, through connection: NWConnection, completion: @escaping (NWError?) -> Void) {
        var size = UInt32(data.count).bigEndian
        var frame = withUnsafeBytes(of: &size) { Data($0) }
        frame.append(data)
        connection.send(content: frame, completion: .contentProcessed(completion))
    }
    static func receive(_ connection: NWConnection, completion: @escaping (Data?) -> Void) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { header, _, _, error in
            guard error == nil, let header, header.count == 4 else { completion(nil); return }
            let size = header.reduce(0) { ($0 << 8) | Int($1) }
            guard (28...maxBytes).contains(size) else { completion(nil); return }
            connection.receive(minimumIncompleteLength: size, maximumLength: size) { data, _, _, error in
                completion(error == nil && data?.count == size ? data : nil)
            }
        }
    }
    static func exchange(_ message: PhoneRequest, pairing: Pairing) async throws -> MacReply {
        guard pairing.valid else { throw WireError.invalid }
        let data = try seal(message, key: pairing.key, fromPhone: true)
        let reply: Data = try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let connection = NWConnection(host: .init(pairing.host), port: Pairing.port, using: .tcp)
                var finished = false
                func complete(_ data: Data?) {
                    guard !finished else { return }
                    finished = true
                    connection.stateUpdateHandler = nil
                    connection.cancel()
                    if let data { continuation.resume(returning: data) }
                    else { continuation.resume(throwing: WireError.connection) }
                }
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        send(data, through: connection) { error in
                            if error != nil { complete(nil) } else { receive(connection, completion: complete) }
                        }
                    case .failed, .cancelled: complete(nil)
                    default: break
                    }
                }
                connection.start(queue: queue)
                queue.asyncAfter(deadline: .now() + 5) { complete(nil) }
            }
        }
        let result = try open(MacReply.self, reply, key: pairing.key, fromPhone: false)
        guard result.challenge == message.challenge else { throw WireError.invalid }
        return result
    }
}

import CoreFoundation
import CryptoKit
import Foundation
import Network
import os

private let toolName = "get_progress_summary"
private let toolDescription = "Read aggregate habit and goal completion after an explicit approval on the owner's iPhone."
private let schema: [String: Any] = [
    "type": "object",
    "properties": ["days": ["type": "integer", "minimum": 1, "maximum": 30]],
    "required": ["days"], "additionalProperties": false
]
private let pairFile = URL.homeDirectory.appending(path: ".rcj-personalapp/bridge.json")
private let help = """
RCJ · puente local
  swift run rcj-bridge pair <IPv4 privada del Mac>
      Pega el código que aparece en RCJ → IA → Vincular.
      Ejecutarlo otra vez rota la clave. Mantén el código en privado.
  swift run rcj-bridge mcp
      Transporte stdio. Configura el directorio de este proyecto como cwd.
      Herramienta: get_progress_summary, con days entre 1 y 30.
  swift run rcj-bridge grok "<pregunta>"
      Usa XAI_API_KEY y XAI_MODEL del entorno del Mac.
      Cuando pida el resumen, abre RCJ → IA → Buscar solicitud.
El puente escucha en el Mac solo mientras hay una consulta. Usa la misma Wi-Fi.
"""

private func log(_ message: String) { FileHandle.standardError.write(Data((message + "\n").utf8)) }

private func askPhone(days: Int, consumer: Consumer) async throws -> ProgressSummary {
    guard (1...30).contains(days) else { throw WireError.invalid }
    let pairing = try JSONDecoder().decode(Pairing.self, from: Data(contentsOf: pairFile))
    guard pairing.valid else { throw WireError.invalid }
    let gate = RequestGate(consumer: consumer, days: days)
    let params = NWParameters.tcp
    params.requiredLocalEndpoint = .hostPort(host: .init(pairing.host), port: Pairing.port)
    let listener = try NWListener(using: params)
    defer { listener.cancel() }
    // Límite de conexiones simultáneas; los paquetes inválidos se cierran sin respuesta.
    let active = OSAllocatedUnfairLock(initialState: 0)
    listener.newConnectionHandler = { connection in
        let available = active.withLock { count in
            guard count < 12 else { return false }
            count += 1
            return true
        }
        guard available else { connection.cancel(); return }
        let closed = OSAllocatedUnfairLock(initialState: false)
        let close: @Sendable () -> Void = {
            guard closed.withLock({ done in
                guard !done else { return false }
                done = true
                return true
            }) else { return }
            active.withLock { $0 -= 1 }
            connection.stateUpdateHandler = nil
            connection.cancel()
        }
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                Wire.receive(connection) { data in
                    guard let data,
                          let request = try? Wire.open(PhoneRequest.self, data, key: pairing.key, fromPhone: true),
                          let response = try? Wire.seal(gate.reply(request), key: pairing.key, fromPhone: false) else {
                        close(); return
                    }
                    Wire.send(response, through: connection) { _ in close() }
                }
            case .failed, .cancelled: close()
            default: break
            }
        }
        connection.start(queue: Wire.queue)
        Wire.queue.asyncAfter(deadline: .now() + 5) { close() }
    }
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        let started = OSAllocatedUnfairLock(initialState: false)
        let finish: @Sendable (Error?) -> Void = { error in
            guard started.withLock({ done in
                guard !done else { return false }
                done = true
                return true
            }) else { return }
            listener.stateUpdateHandler = nil
            if let error { continuation.resume(throwing: error) }
            else { continuation.resume() }
        }
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready: finish(nil)
            case .failed(let error): finish(error)
            case .cancelled: finish(WireError.connection)
            default: break
            }
        }
        listener.start(queue: Wire.queue)
        Wire.queue.asyncAfter(deadline: .now() + 5) { finish(WireError.connection) }
    }
    log("Solicitud pendiente. Abre RCJ → IA → Buscar solicitud. Caduca en 2 min.")
    while !gate.expired {
        if let outcome = gate.result { return try outcome.get() }
        try await Task.sleep(for: .milliseconds(200))
    }
    if let outcome = gate.result { return try outcome.get() }
    throw WireError.expired
}

private func daysFrom(_ input: Any?) -> Int? {
    guard let values = input as? [String: Any], values.count == 1,
          let n = values["days"] as? NSNumber,
          CFGetTypeID(n) != CFBooleanGetTypeID(),
          (1...30).contains(n.intValue), n.doubleValue == Double(n.intValue) else { return nil }
    return n.intValue
}
private func summaryText(_ value: ProgressSummary) throws -> String {
    String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
}

private func mcp() async {
    var initialized = false
    while let line = readLine() {
        var response: [String: Any] = ["jsonrpc": "2.0", "id": NSNull()]
        guard line.utf8.count <= 65_536,
              let request = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any],
              request["jsonrpc"] as? String == "2.0", let method = request["method"] as? String else {
            response["error"] = ["code": -32600, "message": "Invalid request"] as [String: Any]
            emit(response)
            continue
        }
        guard let id = request["id"], id is String || id is NSNumber else { continue }
        response["id"] = id
        let params = request["params"] as? [String: Any]
        switch method {
        case "initialize":
            let requested = params?["protocolVersion"] as? String
            let version: String = ["2024-11-05", "2025-03-26", "2025-06-18", "2025-11-25"].first { $0 == requested } ?? "2025-11-25"
            response["result"] = ["protocolVersion": version, "capabilities": ["tools": [:] as [String: Any]],
                                  "serverInfo": ["name": "rcj-bridge", "version": "1.0"]] as [String: Any]
            initialized = true
        case "ping":
            response["result"] = [:] as [String: Any]
        case "tools/list" where initialized:
            response["result"] = ["tools": [[
                "name": toolName, "description": toolDescription, "inputSchema": schema,
                "annotations": ["readOnlyHint": true, "destructiveHint": false, "openWorldHint": false]
            ] as [String: Any]]]
        case "tools/call" where initialized:
            guard params?["name"] as? String == toolName, let days = daysFrom(params?["arguments"]) else {
                response["error"] = ["code": -32602, "message": "Expected get_progress_summary with days in 1...30"] as [String: Any]
                emit(response)
                continue
            }
            do {
                let summary = try await askPhone(days: days, consumer: .mcp)
                response["result"] = ["content": [["type": "text", "text": try summaryText(summary)]]]
            } catch {
                response["result"] = ["content": [["type": "text", "text": userMessage(error)]], "isError": true] as [String: Any]
            }
        default:
            response["error"] = ["code": -32601, "message": "Method not found"] as [String: Any]
        }
        emit(response)
    }
}

private func emit(_ response: [String: Any]) {
    guard var bytes = try? JSONSerialization.data(withJSONObject: response) else { return }
    bytes.append(10)
    FileHandle.standardOutput.write(bytes)
}

private func grok(_ prompt: String) async throws {
    let env = ProcessInfo.processInfo.environment
    guard let key = env["XAI_API_KEY"], !key.isEmpty, let model = env["XAI_MODEL"], !model.isEmpty else {
        log("Configura XAI_API_KEY y XAI_MODEL en el entorno del Mac.")
        throw WireError.invalid
    }
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 60
    let session = URLSession(configuration: config)
    defer { session.invalidateAndCancel() }
    func request(input: [[String: Any]], tools: [[String: Any]]) async throws -> [[String: Any]] {
        var req = URLRequest(url: URL(string: "https://api.x.ai/v1/responses")!)
        req.httpMethod = "POST"
        req.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "input": input, "tools": tools, "store": false, "parallel_tool_calls": false
        ])
        let (bytes, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let object = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let output = object["output"] as? [[String: Any]] else {
            if let http = response as? HTTPURLResponse { log("La API de xAI respondió con HTTP \(http.statusCode).") }
            throw WireError.connection
        }
        return output
    }
    let initial: [[String: Any]] = [
        ["role": "developer", "content": "Responde en español. Para preguntas sobre el progreso del usuario, usa la herramienta get_progress_summary. No inventes datos."],
        ["role": "user", "content": prompt]
    ]
    let first = try await request(input: initial, tools: [[
        "type": "function", "name": toolName, "description": toolDescription, "parameters": schema, "strict": true
    ]])
    let calls = first.filter { $0["type"] as? String == "function_call" }
    let output: [[String: Any]]
    if !calls.isEmpty {
        guard calls.count == 1, let call = calls.first, call["name"] as? String == toolName,
              let id = call["call_id"] as? String, let args = call["arguments"] as? String, args.utf8.count <= 4096,
              let days = daysFrom(try JSONSerialization.jsonObject(with: Data(args.utf8))) else { throw WireError.invalid }
        let summary = try await askPhone(days: days, consumer: .grok)
        output = try await request(input: initial + first + [[
            "type": "function_call_output", "call_id": id, "output": try summaryText(summary)
        ]], tools: [])
    } else { output = first }
    let answer = output.filter { $0["type"] as? String == "message" }
        .flatMap { $0["content"] as? [[String: Any]] ?? [] }
        .compactMap { $0["text"] as? String }.joined(separator: "\n")
    guard !answer.isEmpty else { throw WireError.invalid }
    print(answer)
}

private func userMessage(_ error: Error) -> String {
    switch error as? WireError {
    case .expired: return "La solicitud caducó sin aprobación."
    case .refused: return "Solicitud rechazada en el iPhone."
    case .invalid: return "Configuración o solicitud no válida."
    default: return "No se pudo completar la consulta. Comprueba la vinculación, la Wi-Fi o el puerto del Mac."
    }
}

@main private enum BridgeMain {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        do {
            switch arguments.first {
            case "pair" where arguments.count == 2:
                guard Pairing.privateIPv4(arguments[1]) else { throw WireError.invalid }
                umask(0o077)
                let directory = pairFile.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                        attributes: [.posixPermissions: 0o700])
                try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
                let key = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
                let config = try JSONEncoder().encode(Pairing(host: arguments[1], key: key))
                try config.write(to: pairFile, options: .atomic)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: pairFile.path)
                print(config.base64EncodedString())
            case "mcp" where arguments.count == 1: await mcp()
            case "grok" where arguments.count == 2 && !arguments[1].isEmpty: try await grok(arguments[1])
            default: print(help)
            }
        } catch {
            log(userMessage(error))
            exit(1)
        }
    }
}

import CryptoKit
import LocalAuthentication
import Security
import SwiftUI

private enum BridgeKeychain {
    static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.robertocarrascoso.rcjpersonalapp",
        kSecAttrAccount as String: "bridge-v1"
    ]

    static func load() -> Pairing? {
        var request = query
        request[kSecReturnData as String] = true
        var value: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &value) == errSecSuccess, let bytes = value as? Data else { return nil }
        return try? JSONDecoder().decode(Pairing.self, from: bytes)
    }
    static func save(_ pairing: Pairing) throws {
        var item = query
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        let bytes = try JSONEncoder().encode(pairing)
        item[kSecValueData as String] = bytes
        let result = SecItemAdd(item as CFDictionary, nil)
        if result == errSecDuplicateItem {
            guard SecItemUpdate(query as CFDictionary, [kSecValueData as String: bytes] as CFDictionary) == errSecSuccess else {
                throw WireError.invalid
            }
        } else if result != errSecSuccess { throw WireError.invalid }
    }
    static func remove() -> Bool {
        let result = SecItemDelete(query as CFDictionary)
        return result == errSecSuccess || result == errSecItemNotFound
    }
}

struct BridgeView: View {
    let store: Store
    @State private var pairing = BridgeKeychain.load()
    @State private var input = ""
    @State private var pending: Approval?
    @State private var busy = false
    @State private var status = ""
    @State private var confirming = false

    var body: some View {
        Dashboard(label: "04 / CONTROL", title: "Puente IA", subtitle: "Tú decides qué sale de tu iPhone.") {
            Panel {
                if let pairing {
                    Label("Mac vinculado · \(pairing.host)", systemImage: "lock.shield").font(.headline)
                    Text("Conecta ambos dispositivos a la misma Wi-Fi. Lanza una consulta en el Mac y búscala aquí.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Buscar solicitud", systemImage: "arrow.clockwise") { Task { await poll(pairing) } }
                        .buttonStyle(.glassProminent).disabled(busy)
                    Button("Desvincular", role: .destructive) {
                        if BridgeKeychain.remove() {
                            self.pairing = nil; pending = nil; status = "Puente desvinculado."
                        } else { status = "No se pudo desvincular el puente." }
                    }.buttonStyle(.glass).disabled(busy)
                } else {
                    Text("Vincula tu Mac").font(.headline)
                    Text("Genera el código de vinculación en el Mac con el comando pair del puente. Pégalo aquí y confirma.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    SecureField("Código de vinculación", text: $input)
                        .textContentType(nil).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .padding(12).background(.white.opacity(0.08), in: .rect(cornerRadius: 10))
                    Button("Vincular", systemImage: "key.horizontal") { Task { await link() } }
                        .buttonStyle(.glassProminent).disabled(input.isEmpty || busy)
                }
                if busy { ProgressView() }
                if !status.isEmpty { Text(status).font(.subheadline).foregroundStyle(.secondary) }
            }
            if let pending, let pairing {
                Panel {
                    Text("Solicitud de \(pending.consumer.title)").font(.headline)
                    Text("Quiere el total de hábitos completados en \(pending.days) días y el número de objetivos logrados.").font(.subheadline)
                    Text(pending.consumer == .grok ? "Al aprobar, estos totales se enviarán a xAI. No se incluyen nombres, pasos ni rutas." :
                            "Se entregan los totales al cliente MCP del Mac. No se incluyen nombres, pasos ni rutas.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Compartir resumen", systemImage: "checkmark.shield") { confirming = true }
                        .buttonStyle(.glassProminent).disabled(busy || store.loadFailed)
                    Button("Rechazar", role: .destructive) { Task { await answer(pending, pairing: pairing, allow: false) } }
                        .buttonStyle(.glass).disabled(busy)
                }
            }
        }
        .confirmationDialog("¿Compartir este resumen?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Confirmar identidad y compartir") {
                if let pending, let pairing { Task { await answer(pending, pairing: pairing, allow: true) } }
            }
        }
    }

    private func link() async {
        busy = true
        defer { busy = false }
        let code = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.utf8.count <= 300, let bytes = Data(base64Encoded: code),
              let candidate = try? JSONDecoder().decode(Pairing.self, from: bytes), candidate.valid else {
            status = "El código de vinculación no es válido."
            return
        }
        do {
            guard try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Vincular tu Mac") else { return }
            try BridgeKeychain.save(candidate)
            pairing = candidate
            input = ""
            status = "Puente vinculado."
        } catch { status = "No se pudo vincular. Comprueba Face ID o el código del iPhone." }
    }

    private func poll(_ pairing: Pairing) async {
        busy = true
        pending = nil
        defer { busy = false }
        do {
            let reply = try await Wire.exchange(PhoneRequest(), pairing: pairing)
            if let request = reply.approval, request.valid { pending = request; status = "" }
            else { status = "No hay ninguna solicitud pendiente." }
        } catch { status = "No se encontró el puente. Comprueba la Wi-Fi y que el Mac está esperando una consulta." }
    }

    private func answer(_ request: Approval, pairing: Pairing, allow: Bool) async {
        busy = true
        defer { busy = false }
        do {
            if allow {
                guard !store.loadFailed,
                      try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Compartir un resumen con \(request.consumer.title)") else { return }
            }
            guard request.valid else { pending = nil; status = "La solicitud ha caducado."; return }
            let summary = allow ? store.summary(days: request.days) : nil
            let reply = try await Wire.exchange(PhoneRequest(decision: request.id, summary: summary), pairing: pairing)
            pending = nil
            status = reply.accepted == true ? (allow ? "Resumen compartido." : "Solicitud rechazada.") : "La solicitud ya no está activa."
        } catch { status = "No se pudo confirmar la decisión. Busca la solicitud de nuevo." }
    }
}

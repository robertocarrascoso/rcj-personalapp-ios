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
    @State private var showingSetup = false

    var body: some View {
        Dashboard(label: "04 / CONTROL", title: "IA", subtitle: "Conexión opcional con Grok y otras herramientas.") {
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
                    SectionLine(title: "¿Para qué sirve?", icon: "lock.shield")
                    Text("Tu Mac hace de puente entre la IA y el iPhone. Solo envía los totales de hábitos y objetivos que apruebes con Face ID o código.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("Puedes usar Hábitos, Goals y Actividad sin configurar esta conexión.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    DisclosureGroup(isExpanded: $showingSetup) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conecta ambos dispositivos a la misma Wi-Fi. En el Mac, abre Terminal en la carpeta del proyecto y sustituye IP_DEL_MAC por su IP local:")
                            Text(verbatim: "swift run rcj-bridge pair IP_DEL_MAC")
                                .font(.caption.monospaced()).textSelection(.enabled)
                            Text("Pega aquí el código que devuelve Terminal y confirma tu identidad.")
                            SecureField("Código de conexión", text: $input)
                                .textContentType(nil).textInputAutocapitalization(.never).autocorrectionDisabled()
                                .padding(12).background(.white.opacity(0.08), in: .rect(cornerRadius: 10))
                            Button("Conectar Mac", systemImage: "key.horizontal") { Task { await link() } }
                                .buttonStyle(.glassProminent).disabled(input.isEmpty || busy)
                        }
                        .font(.subheadline)
                        .padding(.top, 12)
                    } label: {
                        Label("Configurar conexión", systemImage: "laptopcomputer")
                            .font(.headline).frame(minHeight: 44)
                    }
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

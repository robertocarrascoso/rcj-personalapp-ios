import SwiftUI
import Charts
import MapKit

private let wine = Color(red: 0.48, green: 0.075, blue: 0.17)
private let highlight = Color(red: 0.99, green: 0.44, blue: 0.55)

@main struct RCJApp: App {
    @State private var store: Store
    @State private var activity: Activity
    @Environment(\.scenePhase) private var phase

    init() {
        let store = Store(seedURL: Bundle.main.url(forResource: "PersonalSeed", withExtension: "json"))
        _store = State(initialValue: store)
        _activity = State(initialValue: Activity(store: store))
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Hábitos", systemImage: "checkmark.circle") { HabitsView(store: store) }
                Tab("Goals", systemImage: "flag.checkered") { GoalsView(store: store) }
                Tab("Actividad", systemImage: "figure.walk") { ActivityView(store: store, activity: activity) }
                Tab("IA", systemImage: "sparkles") { BridgeView(store: store) }
            }
            .preferredColorScheme(.dark)
            .tint(highlight)
            .task(id: phase) {
                if phase == .active { await activity.refreshSteps() }
            }
            .alert("RCJ", isPresented: Binding(
                get: { store.error != nil }, set: { if !$0 { store.error = nil } }
            )) {
                Button("Vale", role: .cancel) { store.error = nil }
            } message: { Text(store.error ?? "") }
        }
    }
}

struct Dashboard<Content: View>: View {
    let label: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(label).font(.caption.weight(.semibold)).tracking(3).foregroundStyle(highlight)
                        Text(title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image("Brand").resizable().frame(width: 46, height: 46)
                        .clipShape(.rect(cornerRadius: 13)).accessibilityHidden(true)
                }
                content
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 20).padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .background {
            LinearGradient(colors: [Color(red: 0.29, green: 0.028, blue: 0.085), .black, .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        }
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 13) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.24), in: .rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.10)) }
    }
}
struct SectionLine: View {
    let title: String
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if let action {
                Button(action: action) {
                    Image(systemName: "plus").fontWeight(.semibold).frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Añadir a \(title)")
            }
        }
    }
}
struct CheckLine: View {
    let title: String
    var detail: String? = nil
    let done: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(done ? highlight : .secondary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundStyle(.white)
                    if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(done ? .isSelected : [])
    }
}

private struct HabitsView: View {
    let store: Store
    @State private var date = Calendar.current.startOfDay(for: .now)
    @State private var editing: Habit?
    @State private var adding = false
    @State private var minutes = ""
    @State private var title = ""
    @State private var target = ""
    private var calendar: Calendar { .current }
    private var done: Int { store.data.habits.filter { store.completed($0, on: date) }.count }

    var body: some View {
        Dashboard(label: "01 / DISCIPLINA", title: "Hábitos", subtitle: "Marca lo que haces. Mira cómo avanzas.") {
            Panel {
                HStack {
                    Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                        .accessibilityLabel("Día anterior")
                    DatePicker("Día del registro", selection: $date, in: ...Date.now, displayedComponents: .date)
                        .labelsHidden().frame(maxWidth: .infinity)
                    Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .accessibilityLabel("Día siguiente").disabled(calendar.isDateInToday(date))
                }.buttonStyle(.glass)
                Text("\(done) / \(store.data.habits.count)").font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityLabel("\(done) de \(store.data.habits.count) hábitos completados")
                ProgressView(value: Double(done), total: Double(max(1, store.data.habits.count)))
                    .tint(highlight)
            }
            Panel {
                SectionLine(title: "Tu lista") { title = ""; target = ""; adding = true }
                if store.data.habits.isEmpty { Text("Añade tu primer hábito para empezar.").foregroundStyle(.secondary) }
                ForEach(store.data.habits) { habit in
                    CheckLine(title: habit.title, detail: habit.target.map { "\(store.amount(habit, on: date)) / \($0) min" },
                              done: store.completed(habit, on: date)) {
                        if habit.target != nil {
                            minutes = String(store.amount(habit, on: date))
                            editing = habit
                        } else {
                            store.set(store.completed(habit, on: date) ? 0 : 1, habit: habit, on: date)
                        }
                    }
                }
            }
            Panel {
                SectionLine(title: "Últimos 7 días")
                if !store.data.habits.isEmpty {
                    Chart(store.recentDays(7)) { day in
                        BarMark(x: .value("Día", day.date, unit: .day), y: .value("Hábitos", day.completed))
                            .foregroundStyle(highlight.gradient).cornerRadius(4)
                            .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue("\(day.completed) hábitos")
                    }
                    .chartYScale(domain: 0...max(1, store.data.habits.count))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) }
                    }
                    .frame(height: 136)
                }
                Label("\(store.streak()) días de racha", systemImage: "flame")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(highlight)
            }
        }
        .sheet(item: $editing) { habit in
            EntryForm(title: habit.title, canSave: Int(minutes).map { (0...1440).contains($0) } == true) {
                guard let value = Int(minutes) else { return false }
                return store.set(value, habit: habit, on: date)
            } fields: {
                TextField("Minutos", text: $minutes).keyboardType(.numberPad)
            }
        }
        .sheet(isPresented: $adding) {
            EntryForm(title: "Nuevo hábito", canSave: Store.validTitle(title) &&
                      (target.isEmpty || Int(target).map { (1...1440).contains($0) } == true) &&
                      store.data.habits.count < 100) {
                store.update { $0.habits.append(Habit(title: title.trimmingCharacters(in: .whitespacesAndNewlines), target: Int(target))) }
            } fields: {
                TextField("Nombre", text: $title)
                TextField("Objetivo en minutos (opcional)", text: $target).keyboardType(.numberPad)
            }
        }
    }

    private func move(_ days: Int) {
        if let next = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: date)), next <= .now {
            date = next
        }
    }
}

private struct EntryForm<Fields: View>: View {
    let title: String
    let canSave: Bool
    let save: () -> Bool
    @ViewBuilder var fields: Fields
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form { fields }
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") { if save() { dismiss() } }.disabled(!canSave)
                    }
                }
        }.presentationDetents([.medium, .large])
    }
}

private struct GoalsView: View {
    let store: Store
    @State private var adding: GoalGroup?
    @State private var deleting: Goal?
    @State private var title = ""

    var body: some View {
        Dashboard(label: "02 / DIRECCIÓN", title: "Goals", subtitle: "Tus próximos hitos, a tu ritmo.") {
            ForEach(GoalGroup.allCases) { group in
                let goals = store.data.goals.filter { $0.group == group }
                let done = goals.filter(\.done).count
                Panel {
                    SectionLine(title: group.title) { title = ""; adding = group }
                    Text("\(done) de \(goals.count) conseguidos").font(.subheadline).foregroundStyle(.secondary)
                    ProgressView(value: Double(done), total: Double(max(1, goals.count))).tint(highlight)
                    if goals.isEmpty { Text("Todavía no hay objetivos.").foregroundStyle(.secondary) }
                    ForEach(goals) { goal in
                        CheckLine(title: goal.title, done: goal.done) {
                            store.update {
                                if let index = $0.goals.firstIndex(where: { $0.id == goal.id }) { $0.goals[index].done.toggle() }
                            }
                        }
                        .contextMenu { Button("Eliminar", systemImage: "trash", role: .destructive) { deleting = goal } }
                    }
                }
            }
        }
        .sheet(item: $adding) { group in
            EntryForm(title: "Nuevo objetivo", canSave: Store.validTitle(title) && store.data.goals.count < 300) {
                store.update { $0.goals.append(Goal(title: title.trimmingCharacters(in: .whitespacesAndNewlines), group: group)) }
            } fields: { TextField("Objetivo", text: $title) }
        }
        .alert("¿Eliminar objetivo?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Cancelar", role: .cancel) { deleting = nil }
            Button("Eliminar", role: .destructive) {
                if let deleting { store.update { $0.goals.removeAll { $0.id == deleting.id } } }
                deleting = nil
            }
        } message: { Text(deleting?.title ?? "") }
    }
}

private struct ActivityView: View {
    let store: Store
    let activity: Activity
    @State private var selected: Walk?
    @State private var discard = false

    var body: some View {
        Dashboard(label: "03 / MOVIMIENTO", title: "Actividad", subtitle: "Tus pasos y recorridos a pie.") {
            Panel {
                SectionLine(title: "Pasos de hoy")
                Text(activity.steps.last?.count?.formatted() ?? "—")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityLabel(activity.steps.last?.count.map { "\($0) pasos hoy" } ?? "Sin datos de pasos")
                if activity.loadingSteps { ProgressView() }
                if !activity.stepStatus.isEmpty { Text(activity.stepStatus).font(.subheadline).foregroundStyle(.secondary) }
                Button("Actualizar desde Salud", systemImage: "heart.text.clipboard") {
                    Task { await activity.refreshSteps(ask: true) }
                }.buttonStyle(.glass).disabled(activity.loadingSteps)
                if activity.steps.contains(where: { $0.count != nil }) {
                    Chart(activity.steps) { day in
                        if let count = day.count {
                            BarMark(x: .value("Día", day.date, unit: .day), y: .value("Pasos", count))
                                .foregroundStyle(highlight.gradient).cornerRadius(4)
                                .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                                .accessibilityValue("\(count) pasos")
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) }
                    }
                    .frame(height: 128)
                    Text("Últimos 7 días · Salud").font(.caption).foregroundStyle(.secondary)
                }
            }
            Panel {
                SectionLine(title: "Caminata GPS")
                if let walk = store.data.recording {
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        let seconds = max(0, Int(timeline.date.timeIntervalSince(walk.start)))
                        Label("\(seconds / 60):\(String(format: "%02d", seconds % 60)) · \(distance(walk.meters))",
                              systemImage: "record.circle")
                            .font(.headline.monospacedDigit()).foregroundStyle(highlight)
                    }
                    Text(walk.points.isEmpty ? "Buscando señal GPS…" : "Grabando · puedes bloquear el iPhone.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Guardar caminata", systemImage: "stop.fill") { activity.finish(save: true) }
                        .buttonStyle(.glassProminent).tint(wine)
                    Button("Descartar", role: .destructive) { discard = true }.buttonStyle(.glass)
                } else {
                    Text("Registra distancia, duración y recorrido. El historial queda en el iPhone.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Iniciar caminata", systemImage: "play.fill") { activity.start() }
                        .buttonStyle(.glassProminent).tint(wine)
                }
            }
            Panel {
                SectionLine(title: "Historial")
                if store.data.walks.isEmpty { Text("Tus caminatas guardadas aparecerán aquí.").foregroundStyle(.secondary) }
                ForEach(store.data.walks) { walk in
                    Button { selected = walk } label: {
                        HStack {
                            Label(walk.start.formatted(date: .abbreviated, time: .shortened), systemImage: "map")
                            Spacer()
                            Text(distance(walk.meters)).monospacedDigit()
                        }
                        .frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }
            }
        }
        .confirmationDialog("¿Descartar la caminata en curso?", isPresented: $discard, titleVisibility: .visible) {
            Button("Descartar", role: .destructive) { activity.finish(save: false) }
        }
        .alert("Caminata", isPresented: Binding(
            get: { activity.routeError != nil }, set: { if !$0 { activity.routeError = nil } }
        )) {
            Button("Vale", role: .cancel) { activity.routeError = nil }
        } message: { Text(activity.routeError ?? "") }
        .sheet(item: $selected) { walk in
            NavigationStack {
                let coordinates = walk.points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                Map { MapPolyline(coordinates: coordinates).stroke(highlight, lineWidth: 5) }
                    .navigationTitle(distance(walk.meters)).navigationBarTitleDisplayMode(.inline)
                    .safeAreaInset(edge: .bottom) {
                        let minutes = max(0, Int((walk.end ?? walk.start).timeIntervalSince(walk.start)) / 60)
                        Text("\(minutes) min · \(walk.start.formatted(date: .abbreviated, time: .shortened))")
                            .padding().glassEffect()
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { selected = nil } }
                    }
            }
        }
    }
    private func distance(_ meters: Double) -> String { (meters / 1000).formatted(.number.precision(.fractionLength(2))) + " km" }
}

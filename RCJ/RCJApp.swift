import SwiftUI
import Charts
import MapKit
import UIKit

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
                Tab("Hábitos", systemImage: "checkmark.circle") {
                    NavigationStack { HabitsView(store: store) }
                }
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
    var icon: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon).foregroundStyle(highlight).accessibilityHidden(true)
            }
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
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
    var icon: String? = nil
    let done: Bool
    var strikesWhenDone = false
    var editDetail: (() -> Void)? = nil
    let action: () -> Void

    var body: some View {
        if let editDetail {
            HStack(spacing: 0) {
                Button(action: editDetail) {
                    rowLabel.contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Edita los minutos")
                Button(action: action) {
                    tick.frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(done ? "Desmarcar \(title)" : "Marcar \(title) como hecho")
            }
        } else {
            Button(action: action) {
                HStack(spacing: 0) {
                    rowLabel
                    tick.frame(width: 44, height: 44).accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(done ? .isSelected : [])
        }
    }

    private var rowLabel: some View {
        HStack(spacing: 13) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(highlight).frame(width: 28).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .strikethrough(strikesWhenDone && done)
                    .foregroundStyle(.white.opacity(strikesWhenDone && done ? 0.65 : 1))
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private var tick: some View {
        Image(systemName: done ? "checkmark.circle.fill" : "circle")
            .font(.title3).foregroundStyle(done ? highlight : .secondary)
            .contentTransition(strikesWhenDone ? .symbolEffect : .identity)
    }
}

private struct HabitsView: View {
    let store: Store
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var today = Calendar.current.startOfDay(for: .now)
    @State private var selectedDay: Date?
    @State private var editing: MinuteEntry?
    @State private var adding = false
    @State private var minutes = ""
    @State private var title = ""
    @State private var target = ""
    private struct MinuteEntry: Identifiable {
        let habit: Habit
        let date: Date
        var id: UUID { habit.id }
    }

    private var calendar: Calendar { .current }
    private var date: Date { selectedDay ?? today }
    private var done: Int { store.data.habits.filter { store.completed($0, on: date) }.count }

    var body: some View {
        Dashboard(label: "01 / DISCIPLINA", title: "Hábitos", subtitle: "Marca lo que haces. Mira cómo avanzas.") {
            VStack(spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        dateControls
                        Spacer(minLength: 0)
                        dayCount
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        dateControls
                        dayCount
                    }
                }
                ProgressView(value: Double(done), total: Double(max(1, store.data.habits.count)))
                    .tint(highlight).accessibilityHidden(true)
            }

            NavigationLink {
                HabitStatistics(store: store)
            } label: {
                Label("Ver estadísticas", systemImage: "chart.bar.xaxis")
                    .frame(minHeight: 32)
            }
            .buttonStyle(.glass)

            SectionLine(title: "Tu registro", icon: "list.bullet") {
                title = ""
                target = ""
                adding = true
            }

            if store.data.habits.isEmpty {
                Text("Añade tu primer hábito para empezar.").foregroundStyle(.secondary)
            } else {
                habitSection("Lista diaria", icon: "checkmark.circle", habits: store.data.habits.filter { $0.target == nil })
                habitSection("Objetivos de tiempo", icon: "timer", habits: store.data.habits.filter { $0.target != nil })
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in refreshToday() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in refreshToday() }
        .onChange(of: phase, initial: true) { _, phase in
            if phase == .active { refreshToday() }
        }
        .sheet(item: $editing) { entry in
            EntryForm(title: entry.habit.title, canSave: Int(minutes).map { (0...1440).contains($0) } == true) {
                guard let value = Int(minutes) else { return false }
                return saveAmount(value, habit: entry.habit, on: entry.date)
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

    private var dateControls: some View {
        HStack(spacing: 2) {
            dayArrow("chevron.left", label: "Día anterior", offset: -1)
            DatePicker("Día del registro", selection: Binding(get: { date }, set: selectDay),
                       in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.compact).labelsHidden()
            dayArrow("chevron.right", label: "Día siguiente", offset: 1)
                .disabled(selectedDay == nil)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var dayCount: some View {
        Label {
            Text("\(done)/\(store.data.habits.count)")
                .contentTransition(.numericText(value: Double(done)))
        } icon: {
            Image(systemName: "checkmark.circle.fill")
        }
        .font(.subheadline.weight(.semibold)).monospacedDigit()
        .foregroundStyle(.secondary)
        .accessibilityLabel("\(done) de \(store.data.habits.count) hábitos completados")
    }

    private func dayArrow(_ icon: String, label: String, offset: Int) -> some View {
        Button { move(offset) } label: {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func habitSection(_ title: String, icon: String, habits: [Habit]) -> some View {
        if !habits.isEmpty {
            let ordered = habits.sorted { first, second in
                !store.completed(first, on: date) && store.completed(second, on: date)
            }
            Panel {
                SectionLine(title: title, icon: icon)
                VStack(spacing: 2) {
                    ForEach(ordered) { habit in
                        VStack(spacing: 2) {
                            CheckLine(title: habit.title,
                                      detail: habit.target.map { "\(store.amount(habit, on: date)) / \($0) min" },
                                      icon: habit.target == nil ? nil : "clock",
                                      done: store.completed(habit, on: date), strikesWhenDone: true,
                                      editDetail: habit.target == nil ? nil : { editMinutes(habit) }) {
                                let day = selectedDay ?? calendar.startOfDay(for: .now)
                                let amount = store.completed(habit, on: day) ? 0 : (habit.target ?? 1)
                                _ = saveAmount(amount, habit: habit, on: day)
                            }
                            Divider().opacity(habit.id == ordered.last?.id ? 0 : 1)
                        }
                    }
                }
            }
        }
    }

    private func saveAmount(_ amount: Int, habit: Habit, on day: Date) -> Bool {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
            store.set(amount, habit: habit, on: day)
        }
    }

    private func refreshToday() {
        today = calendar.startOfDay(for: .now)
        if let selectedDay, calendar.startOfDay(for: selectedDay) >= today {
            self.selectedDay = nil
        }
    }

    private func selectDay(_ day: Date) {
        refreshToday()
        let day = calendar.startOfDay(for: day)
        selectedDay = day < today ? day : nil
    }

    private func move(_ days: Int) {
        refreshToday()
        if let next = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: date)) {
            selectDay(next)
        }
    }

    private func editMinutes(_ habit: Habit) {
        refreshToday()
        minutes = String(store.amount(habit, on: date))
        editing = MinuteEntry(habit: habit, date: date)
    }
}

private struct HabitStatistics: View {
    let store: Store

    var body: some View {
        Dashboard(label: "HÁBITOS", title: "Estadísticas", subtitle: "Tu progreso de los últimos siete días.") {
            Panel {
                SectionLine(title: "Hábitos completados", icon: "chart.bar.xaxis")
                if store.data.habits.isEmpty {
                    Text("Añade un hábito para empezar a ver tu progreso.").foregroundStyle(.secondary)
                } else {
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
                    .frame(height: 180)
                }
            }
            Panel {
                SectionLine(title: "Racha actual", icon: "flame.fill")
                let streak = store.streak()
                Text(streak == 1 ? "1 día" : "\(streak) días")
                    .font(.title2.weight(.bold)).monospacedDigit()
                Text("Completa todos tus hábitos del día para mantener la racha.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
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

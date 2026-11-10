import SwiftUI
import Charts
import MapKit
import UIKit

// habitos, goals, pasos y viajes. se queda todo en el iphone

let wine = Color(white: 0.42)
let highlight = Color.white
let surface = Color(white: 0.07)

// un linear suave en negro se parte en bandas. la malla se ve y baja hasta el negro
private struct AppBackground: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
                SIMD2<Float>(0, 0.42), SIMD2<Float>(0.5, 0.36), SIMD2<Float>(1, 0.48),
                SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1)
            ],
            colors: [
                Color(white: 0.34), Color(white: 0.16), Color(white: 0.28),
                Color(white: 0.12), Color(white: 0.04), Color(white: 0.08),
                .black, .black, .black
            ]
        )
        .ignoresSafeArea()
    }
}

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
                Tab("Pasos", systemImage: "figure.walk") { ActivityView(store: store, activity: activity) }
                Tab("Viajes", systemImage: "airplane") {
                    NavigationStack { TripsView(store: store) }
                }
                Tab("Memoria", systemImage: "lightbulb") {
                    TopicsView(store: store)
                }
            }
            .preferredColorScheme(.dark)
            .tint(highlight)
            .background(AppBackground())
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

// pantalla base: titulo, scroll y el fondo. centered deja el contenido en el medio
struct Dashboard<Content: View, Accessory: View>: View {
    let title: String
    var centered = false
    var accessory: Accessory
    var content: Content

    init(title: String, centered: Bool = false, @ViewBuilder accessory: () -> Accessory, @ViewBuilder content: () -> Content) {
        self.title = title
        self.centered = centered
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        Group {
            if centered {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 12) {
                            header
                            Spacer(minLength: 0)
                            content
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: 620, minHeight: geo.size.height, alignment: .center)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        content
                    }
                    .frame(maxWidth: 620)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title).font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            accessory
            Spacer(minLength: 0)
            Image("Brand").resizable().frame(width: 30, height: 30)
                .clipShape(.rect(cornerRadius: 9)).accessibilityHidden(true)
        }
    }
}

extension Dashboard where Accessory == EmptyView {
    init(title: String, centered: Bool = false, @ViewBuilder content: () -> Content) {
        self.init(title: title, centered: centered, accessory: { EmptyView() }, content: content)
    }
}

// boton con texto negro o blanco. el cristal con tinte blanco se comia la etiqueta
struct CapsuleButton: ButtonStyle {
    var prominent = false
    var destructive = false

    func makeBody(configuration: Configuration) -> some View {
        CapsuleButtonLabel(configuration: configuration, prominent: prominent, destructive: destructive)
    }
}

private struct CapsuleButtonLabel: View {
    let configuration: ButtonStyle.Configuration
    var prominent: Bool
    var destructive: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let foreground: Color = prominent ? .black : (destructive ? Color(red: 1, green: 0.48, blue: 0.44) : .white)
        let fill: Color = prominent ? .white : (destructive ? Color(red: 1, green: 0.36, blue: 0.32).opacity(0.18) : Color.white.opacity(0.14))
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(fill, in: .capsule)
            .opacity(!isEnabled ? 0.38 : configuration.isPressed ? 0.72 : 1)
    }
}

// tarjeta
struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surface, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16).strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.035)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            }
    }
}
// titulo de seccion. el + solo sale si hay accion
struct SectionLine: View {
    let title: String
    var icon: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon).font(.subheadline.weight(.semibold)).foregroundStyle(highlight)
                    .frame(width: 28, height: 28)
                    .background(wine.opacity(0.22), in: .rect(cornerRadius: 8)).accessibilityHidden(true)
            }
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Spacer()
            if let action {
                Button(action: action) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.14), in: .rect(cornerRadius: 8))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Añadir a \(title)")
            }
        }
    }
}
// fila para marcar. si hay minutos, el texto abre el editor
struct CheckLine: View {
    let title: String
    var detail: String? = nil
    var icon: String? = nil
    let done: Bool
    var strikesWhenDone = false
    var mark: String? = nil
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
        HStack(spacing: 10) {
            if let mark {
                Text(mark).font(.title3).frame(width: 28).accessibilityHidden(true)
            } else if let icon {
                Image(systemName: icon)
                    .foregroundStyle(highlight).frame(width: 28).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(done ? .regular : .medium))
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

// habitos de hoy
private struct HabitsView: View {
    let store: Store
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var today = Calendar.current.startOfDay(for: .now)
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

    var body: some View {
        Dashboard(title: "Hábitos", accessory: {
            Button {
                title = ""
                target = ""
                adding = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(highlight)
                    .background(wine.opacity(0.22), in: .rect(cornerRadius: 7))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Añadir hábito")
        }) {
            if store.data.habits.isEmpty {
                Text("Añade tu primer hábito para empezar.").foregroundStyle(.secondary)
            } else {
                let daily = store.data.habits.filter { $0.target == nil }
                let timed = store.data.habits.filter { $0.target != nil }
                VStack(alignment: .leading, spacing: 28) {
                    habitSection("Lista diaria", icon: "checkmark.circle", habits: daily)
                    habitSection("Objetivos de tiempo", icon: "timer", habits: timed)
                }
            }

            NavigationLink {
                HabitStatistics(store: store)
            } label: {
                HStack {
                    Label("Ver estadísticas", systemImage: "chart.bar.xaxis")
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain).foregroundStyle(highlight)
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

    @ViewBuilder
    private func habitSection(_ title: String, icon: String, habits: [Habit]) -> some View {
        if !habits.isEmpty {
            let ordered = habits.sorted { first, second in
                !store.completed(first, on: today) && store.completed(second, on: today)
            }
            Panel {
                SectionLine(title: title, icon: icon)
                VStack(spacing: 4) {
                    ForEach(ordered) { habit in
                        VStack(spacing: 4) {
                            CheckLine(title: habit.title,
                                      detail: habit.target.map { "\(store.amount(habit, on: today)) / \($0) min" },
                                      done: store.completed(habit, on: today), strikesWhenDone: true,
                                      mark: habitEmoji(habit.title, timed: habit.target != nil),
                                      editDetail: habit.target == nil ? nil : { editMinutes(habit) }) {
                                let amount = store.completed(habit, on: today) ? 0 : (habit.target ?? 1)
                                _ = saveAmount(amount, habit: habit, on: today)
                            }
                            Divider().opacity(habit.id == ordered.last?.id ? 0 : 0.35)
                        }
                    }
                }
            }
        }
    }

    private func habitEmoji(_ title: String, timed: Bool) -> String {
        let name = title.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if name.contains("gym") || name.contains("entren") { return "💪" }
        if name.contains("creat") { return "💊" }
        if name.contains("dorm") { return "😴" }
        if name.contains("leer") || name.contains("libro") { return "📖" }
        if name.contains("estudi") || name.contains("linkia") || name.contains("clase") { return "📚" }
        if name.contains("muscle") { return "⚡" }
        if name.contains("agua") { return "💧" }
        if name.contains("camin") { return "🚶" }
        return timed ? "⏱️" : "✅"
    }

    private func saveAmount(_ amount: Int, habit: Habit, on day: Date) -> Bool {
        return withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
            store.set(amount, habit: habit, on: day)
        }
    }

    private func refreshToday() {
        today = Calendar.current.startOfDay(for: .now)
    }

    private func editMinutes(_ habit: Habit) {
        refreshToday()
        minutes = String(store.amount(habit, on: today))
        editing = MinuteEntry(habit: habit, date: today)
    }
}

// grafica de 7 dias y la racha
private struct HabitStatistics: View {
    let store: Store

    var body: some View {
        Dashboard(title: "Estadísticas") {
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

// formulario para crear o editar
private struct EntryForm<Fields: View>: View {
    let title: String
    let canSave: Bool
    let save: () -> Bool
    @ViewBuilder var fields: Fields
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 10) { fields }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 14))
            HStack(spacing: 12) {
                Button("Cancelar", role: .cancel) { dismiss() }
                    .buttonStyle(CapsuleButton())
                Button("Guardar") { if save() { dismiss() } }
                    .buttonStyle(CapsuleButton(prominent: true))
                    .disabled(!canSave)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(280), .medium])
        .presentationBackground(.clear)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Guardar") { if save() { dismiss() } }.disabled(!canSave)
            }
        }
    }
}

// goals por grupos. mantener pulsado para mover o borrar
private struct GoalsView: View {
    let store: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var category: GoalGroup = .kill
    @State private var adding: GoalGroup?
    @State private var deleting: Goal?
    @State private var title = ""

    var body: some View {
        let goals = store.data.goals.filter { $0.group == category }
        let done = goals.filter(\.done).count

        Dashboard(title: "Goals") {
            Picker("Categoría de objetivos", selection: $category) {
                ForEach(GoalGroup.allCases) { group in
                    Text(group.title).tag(group)
                }
            }
            .pickerStyle(.segmented)

            if category == .kill {
                goalList(goals, done: done)
            } else {
                Panel { goalList(goals, done: done) }
            }
        }
        .sheet(item: $adding) { group in
            EntryForm(title: "Nuevo objetivo · \(group.title)", canSave: Store.validTitle(title) && store.data.goals.count < 300) {
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

    private func goalList(_ goals: [Goal], done: Int) -> some View {
        let ordered = goals.sorted { !$0.done && $1.done }
        return VStack(alignment: .leading, spacing: 10) {
            SectionLine(title: category.title, icon: category.icon) {
                title = ""
                adding = category
            }
            Text("\(done) de \(goals.count) conseguidos").font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: Double(done), total: Double(max(1, goals.count))).tint(highlight)
            if goals.isEmpty {
                Label("Todavía no hay objetivos. Pulsa + para añadir uno.", systemImage: "flag")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            VStack(spacing: 2) {
                ForEach(ordered) { goal in
                    if goal.id != ordered.first?.id { Divider() }
                    CheckLine(title: goal.title, done: goal.done, strikesWhenDone: true) {
                        withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
                            store.update { move(&$0, id: goal.id) }
                        }
                    }
                    .contextMenu {
                        Menu("Mover a", systemImage: "folder") {
                            ForEach(GoalGroup.allCases.filter { $0 != goal.group }) { destination in
                                Button(destination.title, systemImage: destination.icon) {
                                    store.update {
                                        if let index = $0.goals.firstIndex(where: { $0.id == goal.id }) {
                                            $0.goals[index].group = destination
                                        }
                                    }
                                }
                            }
                        }
                        Button("Eliminar", systemImage: "trash", role: .destructive) { deleting = goal }
                    }
                }
            }
        }
    }

    private func move(_ data: inout PersonalData, id: UUID) {
        guard let index = data.goals.firstIndex(where: { $0.id == id }) else { return }
        var goal = data.goals.remove(at: index)
        goal.done.toggle()
        if goal.done {
            data.goals.append(goal)
        } else if let firstDone = data.goals.firstIndex(where: { $0.group == goal.group && $0.done }) {
            data.goals.insert(goal, at: firstDone)
        } else {
            data.goals.append(goal)
        }
    }
}

// pasos de salud y caminatas con gps
private struct ActivityView: View {
    let store: Store
    let activity: Activity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: Walk?
    @State private var discard = false
    @State private var editingStepGoal = false
    @State private var stepGoalText = ""

    private var todaySteps: Int? {
        guard let last = activity.steps.last, Calendar.current.isDateInToday(last.date) else { return nil }
        return last.count
    }

    var body: some View {
        Dashboard(title: "Pasos de hoy") {
            Text(todaySteps?.formatted() ?? "—")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(reduceMotion ? .identity : .numericText(value: Double(todaySteps ?? 0)))
                .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: todaySteps)
                .accessibilityLabel(todaySteps.map { "\($0) pasos hoy" } ?? "Sin datos de pasos")
            Label("Meta diaria de \(store.dailyStepGoal.formatted()) pasos", systemImage: "target")
                .font(.subheadline).foregroundStyle(.secondary)
            if let count = todaySteps {
                ProgressView(value: Double(min(count, store.dailyStepGoal)), total: Double(store.dailyStepGoal))
                    .tint(highlight)
                    .accessibilityLabel("Progreso de la meta de pasos")
                if count >= store.dailyStepGoal {
                    Label("Meta alcanzada", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(highlight)
                }
            }
            if activity.loadingSteps { ProgressView() }
            if !activity.stepStatus.isEmpty { Text(activity.stepStatus).font(.subheadline).foregroundStyle(.secondary) }
            HStack(spacing: 0) {
                Button {
                    Task { await activity.refreshSteps(ask: true) }
                } label: {
                    Label("Actualizar pasos", systemImage: "heart.text.clipboard")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.plain)
                .foregroundStyle(activity.loadingSteps ? Color.secondary : highlight)
                .disabled(activity.loadingSteps)

                Divider().frame(height: 18)

                Button {
                    stepGoalText = String(store.dailyStepGoal)
                    editingStepGoal = true
                } label: {
                    Label("Editar meta", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(highlight)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .background(surface, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14).strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.035)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            }
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
            Panel {
                SectionLine(title: "Caminata GPS", icon: "location.fill")
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
                        .buttonStyle(CapsuleButton(prominent: true))
                    Button("Descartar", role: .destructive) { discard = true }
                        .buttonStyle(CapsuleButton(destructive: true))
                } else {
                    Text("Registra distancia, duración y recorrido. El historial queda en el iPhone.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Iniciar caminata", systemImage: "play.fill") { activity.start() }
                        .buttonStyle(CapsuleButton(prominent: true))
                }
            }
            Panel {
                SectionLine(title: "Historial", icon: "clock.arrow.circlepath")
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
        .sheet(isPresented: $editingStepGoal) {
            EntryForm(title: "Meta diaria de pasos", canSave: (Int(stepGoalText) ?? 0) > 0) {
                guard let goal = Int(stepGoalText) else { return false }
                return withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
                    store.setDailyStepGoal(goal)
                }
            } fields: {
                TextField("Pasos al día", text: $stepGoalText).keyboardType(.numberPad)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task { await activity.refreshSteps() }
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

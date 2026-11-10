import SwiftUI

// viajes: mapa o lista, y las notas de cada uno

struct TripsView: View {
    let store: Store
    @State private var showMap = true
    @State private var selectedCode: String?
    @State private var choosingCountry = false
    @State private var editing: Trip?
    private var trips: [Trip] { store.data.trips ?? [] }
    private var atlas: CountryAtlas? { try? CountryAtlas.bundled.get() }

    var body: some View {
        Group {
            if showMap, let atlas {
                mapScreen(atlas)
            } else {
                Dashboard(title: "Viajes") {
                    viewControls
                    if showMap {
                        Label("No se pudo cargar el mapa. Tus viajes siguen disponibles en la lista.", systemImage: "exclamationmark.triangle")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if trips.isEmpty {
                        ContentUnavailableView("Tu próximo destino", systemImage: "airplane",
                                               description: Text("Pulsa + para añadir un viaje."))
                    } else {
                        tripSection("Pendientes", trips: trips.filter { !$0.visited })
                        tripSection("Visitados", trips: trips.filter(\.visited))
                    }
                }
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(item: $editing) { trip in TripEditor(store: store, trip: trip) }
        .sheet(isPresented: $choosingCountry) {
            NavigationStack {
                CountryPicker(countries: atlas?.countries ?? [], statuses: store.countryStatuses) {
                    selectedCode = $0.code
                }
            }
        }
    }

    private var viewControls: some View {
        HStack(spacing: 12) {
            Picker("Vista de viajes", selection: $showMap) {
                Label("Mapa", systemImage: "map").tag(true)
                Label("Lista", systemImage: "list.bullet").tag(false)
            }.pickerStyle(.segmented)
            if showMap, atlas != nil {
                Button("Buscar país", systemImage: "magnifyingglass") { choosingCountry = true }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44).buttonStyle(.glass)
            }
            Button("Nuevo destino", systemImage: "plus") { editing = Trip(title: "") }
                .labelStyle(.iconOnly).frame(width: 44, height: 44).buttonStyle(.glass)
        }
    }

    private func mapScreen(_ atlas: CountryAtlas) -> some View {
        TravelMap(atlas: atlas, statuses: store.countryStatuses, selectedCode: $selectedCode)
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Text("Viajes").font(.system(.title2, design: .rounded, weight: .bold))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Image("Brand").resizable().frame(width: 30, height: 30)
                            .clipShape(.rect(cornerRadius: 9)).accessibilityHidden(true)
                    }
                    viewControls
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { legend }
                        VStack(alignment: .leading, spacing: 4) { legend }
                    }
                    if selectedCode == nil {
                        Text("Toca un país para marcarlo o añadir un destino.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(.regularMaterial, in: .rect(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .overlay(alignment: .bottom) {
                if let country = atlas.countries.first(where: { $0.code == selectedCode }) {
                    ScrollView { countryPanel(country) }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(maxHeight: 240)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
    }

    @ViewBuilder private var legend: some View {
        Label("\(store.countryStatuses.values.filter { $0 == .wanted }.count) por visitar", systemImage: "flag.fill")
            .foregroundStyle(highlight)
        Label("\(store.countryStatuses.values.filter { $0 == .visited }.count) visitados", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
    }

    private func countryPanel(_ country: Country) -> some View {
        let related = trips.filter { $0.resolvedCountryCode == country.code }
        return Panel {
            HStack(spacing: 10) {
                Text(country.flag).font(.title2).accessibilityHidden(true)
                Text(country.name).font(.headline).accessibilityAddTraits(.isHeader)
                Spacer()
                if store.countryStatuses[country.code] == .visited {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).accessibilityLabel("País visitado")
                }
            }
            HStack(spacing: 12) {
                Button("Quiero ir", systemImage: "flag") { store.markCountry(country, visited: false) }
                    .buttonStyle(CapsuleButton())
                    .disabled(store.countryStatuses[country.code] != nil)
                Button("Visitado", systemImage: "checkmark") { store.markCountry(country, visited: true) }
                    .buttonStyle(CapsuleButton(prominent: true))
                    .disabled(store.countryStatuses[country.code] == .visited)
            }
            ForEach(related) { trip in tripRow(trip) }
            Button("Añadir lugar", systemImage: "plus") {
                editing = Trip(title: "", flag: country.flag, countryCode: country.code)
            }.buttonStyle(CapsuleButton())
        }
    }

    @ViewBuilder private func tripSection(_ title: String, trips: [Trip]) -> some View {
        if !trips.isEmpty {
            Panel {
                Text("\(title) · \(trips.count)").font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary).accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    ForEach(trips) { trip in
                        if trip.id != trips.first?.id { Divider().opacity(0.5) }
                        tripRow(trip)
                    }
                }
            }
        }
    }

    private func tripRow(_ trip: Trip) -> some View {
        NavigationLink { TripDetail(store: store, id: trip.id) } label: {
            HStack(spacing: 10) {
                Text(trip.flag).font(.title3).accessibilityHidden(true)
                Text(trip.title).font(.callout.weight(.medium))
                Spacer(minLength: 4)
                if !trip.notes.isEmpty {
                    Image(systemName: "note.text").font(.caption).foregroundStyle(.secondary).accessibilityLabel("Con notas")
                }
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .frame(minHeight: 44).contentShape(.rect)
        }.buttonStyle(.plain)
    }
}

private struct CountryPicker: View {
    let countries: [Country]
    let statuses: [String: CountryTravelStatus]
    let select: (Country) -> Void
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss
    private var filtered: [Country] {
        countries.filter { query.isEmpty || $0.name.localizedStandardContains(query) || $0.code.localizedStandardContains(query) }
    }

    var body: some View {
        List(filtered) { country in
            Button {
                select(country)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Text(country.flag).accessibilityHidden(true)
                    Text(country.name).foregroundStyle(.primary)
                    Spacer()
                    if let status = statuses[country.code] {
                        Image(systemName: status == .visited ? "checkmark.circle.fill" : "flag.fill")
                            .foregroundStyle(status == .visited ? .green : highlight)
                            .accessibilityLabel(status == .visited ? "Visitado" : "Quiero ir")
                    }
                }.frame(minHeight: 44)
            }
        }
        .searchable(text: $query, prompt: "País o código")
        .overlay { if filtered.isEmpty { ContentUnavailableView.search(text: query) } }
        .navigationTitle("Países").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
    }
}

private struct TripDetail: View {
    let store: Store
    let id: UUID
    @State private var editing: Trip?

    private var trip: Trip? { store.data.trips?.first { $0.id == id } }

    var body: some View {
        Group {
            if let trip {
                Dashboard(title: trip.title) {
                    Panel {
                        HStack(spacing: 12) {
                            Text(trip.flag).font(.title2).accessibilityHidden(true)
                            Toggle("Visitado", isOn: Binding(get: { trip.visited }, set: { visited in
                                var next = trip
                                next.visited = visited
                                store.saveTrip(next)
                            }))
                        }
                    }
                    Panel {
                        SectionLine(title: "Información", icon: "text.alignleft")
                        if trip.notes.isEmpty {
                            Text("Guarda aquí ideas, sitios que visitar, vuelos, alojamiento o cualquier detalle del viaje.")
                                .foregroundStyle(.secondary).lineSpacing(3)
                            Button("Añadir información", systemImage: "plus") { editing = trip }
                                .buttonStyle(CapsuleButton(prominent: true))
                        } else {
                            Text((try? AttributedString(markdown: trip.notes,
                                  options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(trip.notes))
                                .font(.body).lineSpacing(3).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Editar viaje", systemImage: "pencil") { editing = trip }
                    }
                }
            } else {
                ContentUnavailableView("Viaje no disponible", systemImage: "airplane")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .sheet(item: $editing) { trip in TripEditor(store: store, trip: trip) }
    }
}

private struct TripEditor: View {
    let store: Store
    let original: Trip
    @State private var trip: Trip
    @State private var discarding = false
    @Environment(\.dismiss) private var dismiss

    init(store: Store, trip: Trip) {
        self.store = store
        original = trip
        _trip = State(initialValue: trip)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Destino") {
                    TextField("Nombre del viaje", text: $trip.title)
                    if let atlas = try? CountryAtlas.bundled.get() {
                        NavigationLink {
                            CountryPicker(countries: atlas.countries, statuses: store.countryStatuses) { country in
                                trip.countryCode = country.code
                                trip.flag = country.flag
                            }
                        } label: {
                            HStack {
                                Text("País")
                                Spacer()
                                Text(atlas.countries.first { $0.code == trip.resolvedCountryCode }.map { "\($0.flag) \($0.name)" } ?? "Seleccionar")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if trip.resolvedCountryCode == nil {
                        Text("Selecciona un país para situar el destino en el mapa.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle("Ya he estado aquí", isOn: $trip.visited)
                }
                Section {
                    TextEditor(text: $trip.notes).frame(minHeight: 280)
                        .accessibilityLabel("Información del viaje")
                } header: {
                    Text("Información del viaje")
                } footer: {
                    Text("Ideas, itinerario, reservas y enlaces. Los cambios se guardan en este iPhone al pulsar Guardar.")
                }
                if trip.notes.count > 100_000 {
                    Text("Las notas pueden tener hasta 100.000 caracteres.").foregroundStyle(highlight)
                }
            }
            .navigationTitle(original.title.isEmpty ? "Nuevo viaje" : "Editar viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        if trip != original { discarding = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        trip.title = trip.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if store.saveTrip(trip) { dismiss() }
                    }
                    .disabled(!trip.isValid || (original.title.isEmpty && trip.resolvedCountryCode == nil) || ((store.data.trips?.count ?? 0) >= 500 &&
                              store.data.trips?.contains(where: { $0.id == trip.id }) != true))
                }
            }
            .confirmationDialog("¿Descartar los cambios?", isPresented: $discarding, titleVisibility: .visible) {
                Button("Descartar cambios", role: .destructive) { dismiss() }
            }
        }
        .interactiveDismissDisabled(trip != original)
        .presentationDetents([.large])
    }
}

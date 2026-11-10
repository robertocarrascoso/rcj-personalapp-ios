import CoreLocation
import HealthKit
import MapKit
import Observation

// pasos de la app Salud y la ruta si grabas una caminata

struct StepDay: Identifiable {
    let date: Date
    let count: Int?
    var id: Date { date }
}

@MainActor @Observable final class Activity: NSObject, CLLocationManagerDelegate {
    private let health = HKHealthStore()
    private let location = CLLocationManager()
    private let store: Store
    private var starting = false
    private var healthEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "stepsRequested") }
        set { UserDefaults.standard.set(newValue, forKey: "stepsRequested") }
    }
    private(set) var steps: [StepDay] = []
    private(set) var stepStatus = "Conecta Salud para ver tus pasos."
    private(set) var loadingSteps = false
    var routeError: String?

    init(store: Store) {
        self.store = store
        super.init()
        location.delegate = self
        location.activityType = .fitness
        location.desiredAccuracy = kCLLocationAccuracyBest
        location.distanceFilter = 8
        location.pausesLocationUpdatesAutomatically = false
        location.allowsBackgroundLocationUpdates = true
        location.showsBackgroundLocationIndicator = true
    }

    // pide los pasos de los ultimos 7 dias. ask = true saca el permiso
    func refreshSteps(ask: Bool = false) async {
        guard ask || healthEnabled, !loadingSteps else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            stepStatus = "Salud no está disponible en este dispositivo."
            return
        }
        loadingSteps = true
        defer { loadingSteps = false }
        do {
            let type = HKQuantityType(.stepCount)
            if ask {
                try await health.requestAuthorization(toShare: [], read: [type])
                healthEnabled = true
            }
            let cal = Calendar.current
            let now = Date.now
            let today = cal.startOfDay(for: now)
            guard let from = cal.date(byAdding: .day, value: -6, to: today) else { return }
            let predicate = HKQuery.predicateForSamples(withStart: from, end: now)
            let query = HKStatisticsCollectionQueryDescriptor(
                predicate: .quantitySample(type: type, predicate: predicate),
                options: .cumulativeSum, anchorDate: today, intervalComponents: DateComponents(day: 1)
            )
            let result = try await query.result(for: health)
            var days: [StepDay] = []
            result.enumerateStatistics(from: from, to: today) { stat, _ in
                days.append(StepDay(date: stat.startDate, count: stat.sumQuantity().map { Int($0.doubleValue(for: .count())) }))
            }
            steps = days
            stepStatus = days.contains { $0.count != nil } ? "" : "Sin datos de pasos. Revisa el acceso en Salud."
        } catch {
            stepStatus = "No se pudieron leer los pasos. Revisa el acceso en Salud."
        }
    }

    func start() {
        guard store.data.recording == nil, !starting else { return }
        switch location.authorizationStatus {
        case .notDetermined:
            starting = true
            location.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            guard location.accuracyAuthorization == .fullAccuracy else {
                routeError = "Activa Ubicación exacta en Ajustes para grabar la ruta."
                return
            }
            if store.update({ $0.recording = Walk(start: .now) }) { location.startUpdatingLocation() }
        default: routeError = "Permite el acceso a Ubicación en Ajustes para grabar."
        }
    }

    func finish(save: Bool) {
        guard var walk = store.data.recording else { return }
        if save && walk.points.count < 2 {
            routeError = "Aún faltan puntos GPS. Puedes seguir caminando o descartar la grabación."
            return
        }
        walk.end = .now
        if store.update({
            if save { $0.walks.insert(walk, at: 0) }
            $0.recording = nil
        }) { location.stopUpdatingLocation() }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard manager.authorizationStatus != .notDetermined else { return }
            if starting {
                starting = false
                start()
            } else if store.data.recording != nil,
                      ![.authorizedAlways, .authorizedWhenInUse].contains(manager.authorizationStatus) {
                location.stopUpdatingLocation()
                routeError = "Se perdió el permiso de ubicación. Puedes guardar o descartar el tramo grabado."
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations samples: [CLLocation]) {
        Task { @MainActor in
            guard var walk = store.data.recording else { return }
            var changed = false
            for point in samples where point.horizontalAccuracy >= 0 && point.horizontalAccuracy <= 35 && point.timestamp >= walk.start {
                if let last = walk.points.last {
                    let elapsed = point.timestamp.timeIntervalSince(last.time)
                    let distance = point.distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
                    guard elapsed > 0, distance >= 5, distance / elapsed <= 12 else { continue }
                    // si el gps se corta un rato, ese salto no cuenta como distancia
                    if elapsed <= 90 { walk.meters += distance }
                }
                walk.points.append(.init(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude, time: point.timestamp))
                changed = true
            }
            if changed && !store.update({ $0.recording = walk }) { location.stopUpdatingLocation() }
        }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code != .locationUnknown else { return }
        Task { @MainActor in routeError = "No se pudo seguir grabando con el GPS. Revisa Ubicación." }
    }
}

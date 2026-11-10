import MapKit
import SwiftUI

// mapa a pantalla completa. la bandera solo sale en países con viaje

struct TravelMap: View {
    let atlas: CountryAtlas
    let statuses: [String: CountryTravelStatus]
    @Binding var selectedCode: String?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25, longitude: 10),
                           span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)))
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25, longitude: 10),
        span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360))
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var coloredCountries: [Country] {
        atlas.countries.filter { statuses[$0.code] != nil || $0.code == selectedCode }
    }

    private var labeledCountries: [Country] {
        atlas.countries.filter { country in
            guard statuses[country.code] != nil else { return false }
            if country.code == selectedCode { return true }
            guard abs(country.latitude - region.center.latitude) < region.span.latitudeDelta / 2 else { return false }
            let difference = abs(country.longitude - region.center.longitude)
            return min(difference, 360 - difference) < region.span.longitudeDelta / 2
        }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                ForEach(coloredCountries) { country in
                    ForEach(country.polygons.indices, id: \.self) { index in
                        MapPolygon(polygon(country.polygons[index]))
                            .foregroundStyle(color(country).opacity(country.code == selectedCode ? 0.65 : 0.4))
                            .stroke(country.code == selectedCode ? .white : color(country),
                                    lineWidth: country.code == selectedCode ? 2 : 0.8)
                    }
                }
                ForEach(labeledCountries) { country in
                    Annotation(country.name, coordinate: CLLocationCoordinate2D(latitude: country.latitude, longitude: country.longitude)) {
                        Button { selectedCode = country.code } label: {
                            Text(country.flag).font(.title3)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial, in: .circle)
                                .overlay { Circle().strokeBorder(country.code == selectedCode ? .white : .clear, lineWidth: 2) }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(country.name)
                        .accessibilityValue(statuses[country.code] == .visited ? "Visitado" : statuses[country.code] == .wanted ? "Quiero ir" : "Sin marcar")
                        .accessibilityHint("Selecciona el país para ver o añadir destinos")
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
            .onMapCameraChange(frequency: .onEnd) { region = $0.region }
            .onTapGesture { point in
                guard let coordinate = proxy.convert(point, from: .local) else { return }
                selectedCode = atlas.country(latitude: coordinate.latitude, longitude: coordinate.longitude)?.code
            }
            .onChange(of: selectedCode) { _, code in
                guard let country = atlas.countries.first(where: { $0.code == code }) else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                    position = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: country.latitude, longitude: country.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 24, longitudeDelta: 32)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Mapa de destinos")
    }

    private func color(_ country: Country) -> Color {
        statuses[country.code] == .visited ? .green : statuses[country.code] == .wanted ? highlight : .gray
    }

    private func polygon(_ rings: [[[Double]]]) -> MKPolygon {
        let holes = rings.dropFirst().map { ring in
            let points = ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            return MKPolygon(coordinates: points, count: points.count)
        }
        let points = rings[0].map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        return MKPolygon(coordinates: points, count: points.count, interiorPolygons: holes)
    }
}

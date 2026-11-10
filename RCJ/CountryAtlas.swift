import Foundation

// paises y sus bordes, para saber que has tocado en el mapa

struct Country: Decodable, Identifiable {
    let code: String
    let name: String
    let latitude: Double
    let longitude: Double
    let polygons: [[[[Double]]]]
    var id: String { code }
    var flag: String { String(String.UnicodeScalarView(code.unicodeScalars.compactMap { UnicodeScalar($0.value + 127397) })) }

    // mira si el punto cae dentro del pais, sin contar los agujeros
    func contains(latitude: Double, longitude: Double) -> Bool {
        polygons.contains { polygon in
            guard let exterior = polygon.first, Self.contains(exterior, x: longitude, y: latitude) else { return false }
            return !polygon.dropFirst().contains { Self.contains($0, x: longitude, y: latitude) }
        }
    }

    private static func contains(_ ring: [[Double]], x: Double, y: Double) -> Bool {
        var inside = false
        var previous = ring[ring.count - 1]
        for point in ring {
            if (point[1] > y) != (previous[1] > y),
               x < (previous[0] - point[0]) * (y - point[1]) / (previous[1] - point[1]) + point[0] {
                inside.toggle()
            }
            previous = point
        }
        return inside
    }
}

struct CountryAtlas {
    let countries: [Country]
    static let bundled = Result { () throws -> CountryAtlas in
        guard let url = Bundle.main.url(forResource: "Countries", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try CountryAtlas(url: url)
    }

    init(url: URL) throws {
        let decoded = try JSONDecoder().decode([Country].self, from: Data(contentsOf: url))
        guard !decoded.isEmpty, Set(decoded.map(\.code)).count == decoded.count,
              decoded.allSatisfy({ country in
                  Self.validCode(country.code) && !country.name.isEmpty &&
                  (-90...90).contains(country.latitude) && (-180...180).contains(country.longitude) &&
                  !country.polygons.isEmpty && country.polygons.allSatisfy { polygon in
                      !polygon.isEmpty && polygon.allSatisfy { ring in
                          ring.count >= 4 && ring.allSatisfy { point in
                              point.count == 2 && (-180...180).contains(point[0]) && (-90...90).contains(point[1])
                          }
                      }
                  }
              }) else { throw CocoaError(.fileReadCorruptFile) }
        countries = decoded.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func country(latitude: Double, longitude: Double) -> Country? {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        return countries.first { $0.contains(latitude: latitude, longitude: longitude) }
    }

    static func validCode(_ code: String) -> Bool {
        code.unicodeScalars.count == 2 && code.unicodeScalars.allSatisfy { (65...90).contains($0.value) }
    }

    static func code(for flag: String) -> String? {
        let scalars = flag.unicodeScalars
        guard scalars.count == 2, scalars.allSatisfy({ (127462...127487).contains($0.value) }) else { return nil }
        let code = String(String.UnicodeScalarView(scalars.compactMap { UnicodeScalar($0.value - 127397) }))
        return code == "IC" ? "ES" : code
    }
}

enum CountryTravelStatus {
    case wanted, visited
}

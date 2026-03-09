import Foundation

enum CityService {
    static func searchCities(country: String? = nil, query: String = "") async throws -> [City] {
        var path = "/cities"
        var params: [String] = []
        if let country {
            params.append("country=\(country)")
        }
        if !query.isEmpty {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            params.append("q=\(encoded)")
        }
        if !params.isEmpty {
            path += "?" + params.joined(separator: "&")
        }
        return try await APIClient.shared.get(path)
    }

    static func listCountries() async throws -> [Country] {
        try await APIClient.shared.get("/countries")
    }
}

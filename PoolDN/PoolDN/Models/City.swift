import Foundation

struct City: Codable, Identifiable {
    let id: String
    let name: String
    let countryCode: String
    let countryName: String?
}

struct Country: Codable, Identifiable {
    var id: String { code }
    let code: String
    let name: String
}

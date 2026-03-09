import Foundation

struct APIErrorResponse: Codable {
    let error: String
    let details: [ValidationError]?
}

struct ValidationError: Codable {
    let message: String
    let path: [String]?
}

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case conflict(String)
    case validationError(String)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Please sign in to continue"
        case .forbidden:
            return "You don't have permission"
        case .notFound:
            return "Not found"
        case .conflict(let message):
            return message
        case .validationError(let message):
            return message
        case .serverError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        }
    }
}

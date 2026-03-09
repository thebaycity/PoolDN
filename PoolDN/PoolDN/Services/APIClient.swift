import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        self.baseURL = AppConfig.apiBaseURL
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }

    private var authToken: String? {
        KeychainHelper.load(forKey: AppConfig.tokenKey)
    }

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        // Log request
        #if DEBUG
        var logMessage = "📡 \(method) \(path)"
        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            logMessage += "\n   Body: \(bodyString)"
        }
        print(logMessage)
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }

        #if DEBUG
        let responsePreview = String(data: data.prefix(500), encoding: .utf8) ?? "<binary>"
        print("📡 \(method) \(path) → \(httpResponse.statusCode)\n   Response: \(responsePreview)")
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 409:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.conflict(errorResponse?.error ?? "Conflict")
        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error ?? "Server error")
        }
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request("GET", path: path)
    }

    func post<T: Decodable>(_ path: String, body: (any Encodable)? = nil, authenticated: Bool = true) async throws -> T {
        try await request("POST", path: path, body: body, authenticated: authenticated)
    }

    func put<T: Decodable>(_ path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request("PUT", path: path, body: body)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request("DELETE", path: path)
    }

    func upload<T: Decodable>(
        path: String,
        imageData: Data,
        filename: String = "avatar.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        #if DEBUG
        print("📡 POST \(path) [upload \(imageData.count) bytes]")
        #endif

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }

        #if DEBUG
        let responsePreview = String(data: data.prefix(500), encoding: .utf8) ?? "<binary>"
        print("📡 POST \(path) → \(httpResponse.statusCode)\n   Response: \(responsePreview)")
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error ?? "Upload failed")
        }
    }
}

private struct EmptyResponse: Decodable {}

import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let total: Int
    let hasMore: Bool
}

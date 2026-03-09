import Foundation

enum AppConfig {
    #if DEBUG
    static let apiBaseURL = "https://toan.thebaycity.dev/api"
    #else
    static let apiBaseURL = "https://pooldn-api.workers.dev/api"
    #endif

    static let keychainService = "com.pooldn.app"
    static let tokenKey = "auth_token"
}

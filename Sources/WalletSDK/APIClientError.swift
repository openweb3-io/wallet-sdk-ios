import Foundation

public enum APIClientError: LocalizedError {
    case missingCredentials
    case invalidServerURL
    case authenticationFailed(String)
    case networkError(any Error)
    case invalidResponse
    case decodingError(any Error)
    case tokenExpired
    case rateLimitExceeded
    case serverError(statusCode: Int, message: String)
    case invalidRequest(String)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Verifier and IdToken are required"
        case .invalidServerURL:
            return "Invalid server URL"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .tokenExpired:
            return "Access token has expired"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        }
    }
}

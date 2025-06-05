import Foundation

public struct APIClientOptions {
    public let verifier: String
    public let idToken: String
    public let serverUrl: String
    public let debug: Bool
    public let timeout: TimeInterval
    public let maxRetries: Int

    public init(
        verifier: String,
        idToken: String,
        serverUrl: String,
        debug: Bool = false,
        timeout: TimeInterval = 300,
        maxRetries: Int = 3
    ) {
        self.verifier = verifier
        self.idToken = idToken
        self.serverUrl = serverUrl
        self.debug = debug
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
}

import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

public class APIClient {
    private let client: Client
    private let authorization: String
    
    public init(options: APIClientOptions) async throws {
        guard let serverURL = URL(string: options.serverUrl) else {
            throw APIClientError.invalidServerURL
        }
        
        let authClient = Client(
            serverURL: serverURL,
            transport: URLSessionTransport()
        )
        
        let authOptions: [String: OpenAPIValueContainer] = [
            "id_token": OpenAPIValueContainer(stringLiteral: options.idToken)
        ]
        
        let credentials = Operations.V1_users_Auth.Input.Body.json(
            .init(
                options: .init(additionalProperties: authOptions),
                verifier: options.verifier
            )
        )
        
        let authResponse = try await authClient.v1_users_Auth(.init(body: credentials))
        let authResult: String
        
        switch authResponse {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                guard let accessToken = result.accessToken, !accessToken.isEmpty else {
                    throw APIClientError.authenticationFailed("Invalid credentials")
                }
                authResult = "Bearer \(accessToken)"
            }
        case .badRequest(let error):
            throw APIClientError.authenticationFailed("Bad request: \(error)")
        case .notFound(let error):
            throw APIClientError.authenticationFailed("Not found: \(error)")
        case .internalServerError(let error):
            throw APIClientError.authenticationFailed("Server error: \(error)")
        case .unauthorized:
            throw APIClientError.authenticationFailed("Invalid credentials")
        case .undocumented(let statusCode, _):
            throw APIClientError.serverError(statusCode: statusCode, message: "Authentication failed")
        }
        
        self.authorization = authResult
        
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.timeoutIntervalForRequest = options.timeout
        urlSessionConfig.timeoutIntervalForResource = options.timeout
        
        let authMiddleware = AuthHeaderMiddleware(authorization: authResult)
        
        let transport = URLSessionTransport(
            configuration: .init(session: URLSession(configuration: urlSessionConfig))
        )
        
        self.client = Client(
            serverURL: serverURL,
            transport: transport,
            middlewares: [authMiddleware]
        )
    }

    public func getAccounts(input: Operations.V1_accounts_List.Input) async throws
        -> Components.Schemas.PageAccount
    {
        let response = try await client.v1_accounts_List(input)

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let pageAccount):
                return pageAccount
            }
        case .code102(_):
            throw APIClientError.serverError(statusCode: 102, message: "Processing")
        case .badRequest(_):
            throw APIClientError.invalidRequest("Bad request")
        case .internalServerError(_):
            throw APIClientError.serverError(statusCode: 500, message: "Internal server error")
        case .undocumented(let statusCode, _):
            throw APIClientError.serverError(statusCode: statusCode, message: "Undocumented error")
        }
    }

    public func getWalletsBalance(input: Operations.V1_wallets_getBalance.Input) async throws
        -> Components.Schemas.Balance
    {
        let response = try await client.v1_wallets_getBalance(input)

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let balance):
                return balance
            }
        case .code102(_):
            throw APIClientError.serverError(statusCode: 102, message: "Processing")
        case .internalServerError(_):
            throw APIClientError.serverError(statusCode: 500, message: "Internal server error")
        case .undocumented(let statusCode, _):
            throw APIClientError.serverError(
                statusCode: statusCode, message: "Failed to get wallets")
        }
    }

    public func listWalletsBalanceHistory(input: Operations.V1_wallets_ListBalanceHistory.Input) async throws
        -> Components.Schemas.ListBalanceHistoryResponse
    {
        let response = try await client.v1_wallets_ListBalanceHistory(input)

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let balances):
                return balances
            }
        case .code102(_):
            throw APIClientError.serverError(statusCode: 102, message: "Processing")
        case .badRequest(_):
            throw APIClientError.invalidRequest("Bad request")
        case .internalServerError(_):
            throw APIClientError.serverError(statusCode: 500, message: "Internal server error")
        case .undocumented(let statusCode, _):
            throw APIClientError.serverError(
                statusCode: statusCode, message: "Failed to get wallets")
        }
    }

    public func getCurrencies(input: Operations.V1_currencies_List.Input) async throws
        -> Components.Schemas.CursorPageCurrency
    {
        let response = try await client.v1_currencies_List(input)

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let cursorPageCurrency):
                return cursorPageCurrency
            }
        case .code102(_):
            throw APIClientError.serverError(statusCode: 102, message: "Processing")
        case .badRequest(_):
            throw APIClientError.invalidRequest("Bad request")
        case .internalServerError(_):
            throw APIClientError.serverError(statusCode: 500, message: "Internal server error")
        case .undocumented(let statusCode, _):
            throw APIClientError.serverError(
                statusCode: statusCode, message: "Failed to get currencies")
        }
    }
}

private struct AuthHeaderMiddleware: ClientMiddleware {
    let authorization: String
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = authorization
        return try await next(request, body, baseURL)
    }
}

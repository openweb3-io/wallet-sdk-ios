import XCTest
@testable import WalletSDK
import OpenAPIRuntime

final class APIClientTests: XCTestCase {
    private var client: APIClient!
    private var options: APIClientOptions!
    
    private func getEnvironmentVariable(_ name: String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[name] else {
            throw XCTSkip("Environment variable \(name) not set")
        }
        return value
    }
    
    override func setUp() async throws {
        try await super.setUp()
        
        do {
            options = APIClientOptions(
                verifier: try getEnvironmentVariable("VERIFIER"),
                idToken: try getEnvironmentVariable("ID_TOKEN"),
                serverUrl: try getEnvironmentVariable("SERVER_URL")
            )
            
            client = try await APIClient(options: options)
            XCTAssertNotNil(client, "APIClient should be initialized successfully")
        } catch let error as APIClientError {
            switch error {
            case .authenticationFailed(let message):
                throw XCTSkip("Authentication failed: \(message) - Skipping tests as credentials might be expired")
            default:
                XCTFail("Failed to initialize APIClient: \(error)")
            }
        } catch {
            if let skipError = error as? XCTSkip {
                throw skipError
            }
            XCTFail("Unexpected error during initialization: \(error)")
        }
    }
    
    func testGetAccounts() async throws {
        try XCTSkipIf(client == nil, "Client not initialized")
        
        let input = Operations.V1_accounts_List.Input(
            query: .init(page: 1, size: 10)
        )
        
        do {
            let pageAccount = try await client.getAccounts(input: input)
            XCTAssertNotNil(pageAccount.total)
            let accountCount = pageAccount.items?.count ?? 0
            print("Successfully retrieved accounts: \(accountCount) accounts")
        } catch let error as APIClientError {
            switch error {
            case .authenticationFailed(let message):
                throw XCTSkip("Authentication failed: \(message)")
            default:
                XCTFail("Failed to get accounts: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetWalletsBalance() async throws {
        try XCTSkipIf(client == nil, "Client not initialized")
        
        let input = Operations.V1_wallets_getBalance.Input()
        
        do {
            let balance = try await client.getWalletsBalance(input: input)
            XCTAssertNotNil(balance)
            print("Wallet balance timestamp: \(balance.timestamp ?? "N/A")")
            print("Wallet balance USDT: \(balance.usdtBalance ?? "N/A")")
        } catch let error as APIClientError {
            switch error {
            case .authenticationFailed(let message):
                throw XCTSkip("Authentication failed: \(message)")
            default:
                XCTFail("Failed to get wallet balance: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetCurrencies() async throws {
        try XCTSkipIf(client == nil, "Client not initialized")
        
        let input = Operations.V1_currencies_List.Input(
            query: .init(cursor: nil, limit: 10, rated: false)
        )
        
        do {
            let cursorPageCurrency = try await client.getCurrencies(input: input)
            XCTAssertNotNil(cursorPageCurrency.hasNext)
            let currencyCount = cursorPageCurrency.items?.count ?? 0
            print("Successfully retrieved currencies: \(currencyCount) currencies")
        } catch let error as APIClientError {
            switch error {
            case .authenticationFailed(let message):
                throw XCTSkip("Authentication failed: \(message)")
            default:
                XCTFail("Failed to get currencies: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

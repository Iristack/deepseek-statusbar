import Foundation

enum BillingServiceError: LocalizedError {
    case missingAPIKey
    case networkError(String)
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return String(localized: "API Key is not set. Please enter it in Settings.",
                          comment: "BillingServiceError: missing API key")
        case .networkError(let msg):
            return String(localized: "Network error: \(msg)",
                          comment: "BillingServiceError: network failure")
        case .httpError(let code):
            return String(localized: "Server error (\(code))",
                          comment: "BillingServiceError: HTTP error")
        case .invalidResponse:
            return String(localized: "Invalid response format",
                          comment: "BillingServiceError: unparseable response")
        }
    }
}

struct BillingService {
    static let shared = BillingService()

    private let endpoint = "https://api.deepseek.com/user/balance"
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        return URLSession(configuration: config)
    }()

    func fetchBalance(apiKey: String) async throws -> BalanceResponse {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BillingServiceError.missingAPIKey
        }

        guard let url = URL(string: endpoint) else {
            throw BillingServiceError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let cleanedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        request.addValue("Bearer \(cleanedKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BillingServiceError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw BillingServiceError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(BalanceResponse.self, from: data)
            
        } catch let urlError as URLError {
            throw BillingServiceError.networkError(urlError.localizedDescription)
        } catch {
            throw BillingServiceError.networkError(error.localizedDescription)
        }
    }
}

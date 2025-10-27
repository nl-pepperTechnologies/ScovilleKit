//
//  ScovilleNetwork.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

/// Handles all outbound API calls.
/// Actor-isolated to ensure thread-safe access to the shared instance.
actor ScovilleNetwork {
    static let shared = ScovilleNetwork()
    private init() {}

    private let baseURL = URL(string: "https://pixelwonders.nl/api")!

    enum NetworkError: Error {
        case invalidResponse
        case requestFailed(Error)
    }

    /// Performs a POST request to the given endpoint.
    /// e.g. `/v2/analytics/track` or `/v2/devices/register`
    nonisolated func post<T: Encodable>(
        endpoint: String,
        apiKey: String,
        body: T,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-App-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        // URLSession is thread-safe and not actor-isolated.
        // Mark this method `nonisolated` so it can be called from @MainActor Scoville.
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(NetworkError.requestFailed(error)))
                return
            }

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            completion(.success(()))
        }.resume()
    }
}

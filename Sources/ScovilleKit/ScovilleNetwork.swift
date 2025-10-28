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
    private var customURL: URL?

    private var currentURL: URL {
        customURL ?? baseURL
    }

    nonisolated func getCurrentBaseURL() async -> URL {
        await ScovilleNetwork.shared.currentBaseURL()
    }

    func currentBaseURL() -> URL {
        return currentURL
    }
    
    func configureBaseURL(url: String) {
        if let parsed = URL(string: url) {
            customURL = parsed
            print("🌐 [ScovilleKit] Custom API URL set to \(parsed)")
        } else {
            customURL = nil
            print("⚠️ [ScovilleKit] Invalid URL string, reverting to default.")
        }
    }

    func configureBaseURL(url: URL) {
        customURL = url
        print("🌐 [ScovilleKit] Custom API URL set to \(url)")
    }

    enum NetworkError: Error {
        case invalidResponse
        case requestFailed(Error)
    }

    /// Performs a POST request to the given endpoint (async/await version).
    /// e.g. `v2/analytics/track` or `v2/devices/register` (leading slash optional)
    func post<T: Encodable & Sendable>(
        endpoint: String,
        apiKey: String,
        body: T
    ) async -> Result<Void, Error> {
        let trimmedEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = currentURL.appendingPathComponent(trimmedEndpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-App-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return .failure(error)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                #if DEBUG
                print("[ScovilleKit] \(response)")
                #endif
                return .failure(NetworkError.invalidResponse)
            }
            return .success(())
        } catch {
            return .failure(NetworkError.requestFailed(error))
        }
    }

    /// Completion-based convenience wrapper for non-async callers.
    /// This version avoids data race warnings by ensuring Sendable isolation.
    nonisolated func post<T: Encodable & Sendable>(
        endpoint: String,
        apiKey: String,
        body: T,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) {
        Task {
            let result = await ScovilleNetwork.shared.post(endpoint: endpoint, apiKey: apiKey, body: body)
            completion(result)
        }
    }
    
    /// Performs a GET request to the given endpoint.
    /// e.g. `v2/heartbeat` or `v2/apps`
    func get(
        endpoint: String,
        apiKey: String
    ) async -> Result<Data, Error> {
        let trimmedEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = currentURL.appendingPathComponent(trimmedEndpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-App-Key")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                #if DEBUG
                print("[ScovilleKit] ❌ GET \(url.absoluteString)")
                print("[ScovilleKit] Response: \(response)")
                if let http = response as? HTTPURLResponse {
                    print("[ScovilleKit] Status code: \(http.statusCode)")
                }
                #endif
                return .failure(NetworkError.invalidResponse)
            }
            return .success(data)
        } catch {
            return .failure(NetworkError.requestFailed(error))
        }
    }

    /// Completion-based convenience wrapper for GET requests.
    nonisolated func get(
        endpoint: String,
        apiKey: String,
        completion: @escaping @Sendable (Result<Data, Error>) -> Void
    ) {
        Task {
            let result = await ScovilleNetwork.shared.get(endpoint: endpoint, apiKey: apiKey)
            completion(result)
        }
    }
}

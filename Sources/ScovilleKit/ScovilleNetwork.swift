//
//  ScovilleNetwork.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

actor ScovilleNetwork {
    static let shared = ScovilleNetwork()
    private init() {}

    private let baseURL = URL(string: "https://pixelwonders.nl/api")!
    private var customURL: URL?

    // MARK: - Ephemeral Session (no cookies, no caching)
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.httpCookieStorage = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config, delegate: RedirectBlocker(), delegateQueue: nil)
    }()

    private var currentURL: URL {
        customURL ?? baseURL
    }

    nonisolated func getCurrentBaseURL() async -> URL {
        await ScovilleNetwork.shared.currentBaseURL()
    }

    func currentBaseURL() -> URL {
        currentURL
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

    // MARK: - POST
    func post<T: Encodable & Sendable>(
        endpoint: String,
        apiKey: String,
        body: T
    ) async -> Result<Void, Error> {
        let trimmed = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = currentURL.appendingPathComponent(trimmed)

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
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                #if DEBUG
                print("[ScovilleKit] ❌ POST failed (\((response as? HTTPURLResponse)?.statusCode ?? 0)) → \(url)")
                #endif
                return .failure(NetworkError.invalidResponse)
            }
            #if DEBUG
            print("[ScovilleKit] ✅ POST OK → \(url)")
            #endif
            return .success(())
        } catch {
            return .failure(NetworkError.requestFailed(error))
        }
    }

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

    // MARK: - GET
    func get(
        endpoint: String,
        apiKey: String
    ) async -> Result<Data, Error> {
        let trimmed = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = currentURL.appendingPathComponent(trimmed)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-App-Key")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                #if DEBUG
                print("[ScovilleKit] ❌ GET failed (\((response as? HTTPURLResponse)?.statusCode ?? 0)) → \(url)")
                #endif
                return .failure(NetworkError.invalidResponse)
            }
            return .success(data)
        } catch {
            return .failure(NetworkError.requestFailed(error))
        }
    }

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

// MARK: - Redirect Blocker
private final class RedirectBlocker: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Stop auto-following 302 → surfaces actual Laravel redirect in logs
        completionHandler(nil)
    }
}

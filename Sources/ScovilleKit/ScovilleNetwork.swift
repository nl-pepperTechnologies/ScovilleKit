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

    // MARK: - Ephemeral session (no cookies, no caching)
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

    private var currentURL: URL { customURL ?? baseURL }

    nonisolated func getCurrentBaseURL() async -> URL {
        await ScovilleNetwork.shared.currentBaseURL()
    }

    func currentBaseURL() -> URL {
        currentURL
    }

    // MARK: - Base URL Configuration
    func configureBaseURL(url: String) async {
        if let parsed = URL(string: url) {
            customURL = parsed
            await ScovilleLogger.shared.success(.network, "Custom API URL set to \(parsed)")
        } else {
            customURL = nil
            await ScovilleLogger.shared.warning(.network, "Invalid URL string provided — reverted to default base URL.")
        }
    }

    enum NetworkError: Error {
        case invalidResponse(Int)
        case requestFailed(Error)
    }

    // MARK: - POST
    func post<T: Encodable & Sendable>(
        endpoint: String,
        apiKey: String,
        body: T
    ) async -> Result<Void, Error> {
        if Task.isCancelled { return .failure(CancellationError()) }

        let trimmed = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = currentURL.appendingPathComponent(trimmed)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-App-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            await ScovilleLogger.shared.error(.network, "Failed to encode POST body for \(endpoint): \(error.localizedDescription)")
            return .failure(error)
        }

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                await ScovilleLogger.shared.error(.network, "POST → \(endpoint) invalid response type.")
                return .failure(NetworkError.invalidResponse(-1))
            }

            guard 200..<300 ~= http.statusCode else {
                await ScovilleLogger.shared.error(.network, "POST → \(endpoint) failed (\(http.statusCode)) — \(url.absoluteString)")
                return .failure(NetworkError.invalidResponse(http.statusCode))
            }

            await ScovilleLogger.shared.success(.network, "POST OK → \(url.absoluteString)")
            return .success(())
        } catch {
            if Task.isCancelled { return .failure(CancellationError()) }
            await ScovilleLogger.shared.error(.network, "POST request to \(endpoint) failed: \(error.localizedDescription)")
            return .failure(NetworkError.requestFailed(error))
        }
    }

    // MARK: - GET
    func get(
        endpoint: String,
        apiKey: String
    ) async -> Result<Data, Error> {
        if Task.isCancelled { return .failure(CancellationError()) }

        let trimmed = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = currentURL.appendingPathComponent(trimmed)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-App-Key")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                await ScovilleLogger.shared.error(.network, "GET → \(endpoint) invalid response type.")
                return .failure(NetworkError.invalidResponse(-1))
            }

            guard 200..<300 ~= http.statusCode else {
                await ScovilleLogger.shared.error(.network, "GET → \(endpoint) failed (\(http.statusCode)) — \(url.absoluteString)")
                return .failure(NetworkError.invalidResponse(http.statusCode))
            }

            await ScovilleLogger.shared.success(.network, "GET OK → \(url.absoluteString)")
            return .success(data)
        } catch {
            if Task.isCancelled { return .failure(CancellationError()) }
            await ScovilleLogger.shared.error(.network, "GET request to \(endpoint) failed: \(error.localizedDescription)")
            return .failure(NetworkError.requestFailed(error))
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
        Task {
            await ScovilleLogger.shared.warning(.network, "🚫 Blocked 302 redirect → \(response.url?.absoluteString ?? "unknown")")
        }
        completionHandler(nil)
    }
}

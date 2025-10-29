//
//  Scoville.swift
//  ScovilleKit
//

import Foundation

@MainActor
public enum Scoville {
    private static var configuration: Configuration?
    private static let storage = ScovilleStorage()

    // MARK: - Initialization
    public static func configure(apiKey: String) {
        let info = Bundle.main.scovilleInfo
        let uuid = storage.ensureUUID()

        configuration = Configuration(
            apiKey: apiKey,
            bundleId: info.bundleId,
            version: info.version,
            build: info.build,
            uuid: uuid
        )

        Task {
            await ScovilleLogger.shared.success(.configuration, "Configured for \(info.bundleId) — version \(info.version) (\(info.build))")
        }
    }

    public static func configureAPI(url: String) {
        Task {
            await ScovilleNetwork.shared.configureBaseURL(url: url)
            await ScovilleLogger.shared.log(.network, "Custom API base URL set to \(url)")
        }
    }

    // MARK: - Event Tracking
    public static func track(_ event: AnalyticsEventName, parameters: [String: Any] = [:]) {
        guard let config = configuration else {
            Task {
                await ScovilleLogger.shared.warning(.configuration, "Scoville not configured yet — call configure(apiKey:) first. Tried logging: \(event.rawValue)")
            }
            return
        }

        let eventName = event.rawValue
        let payload = EventPayload(
            uuid: config.uuid,
            eventName: eventName,
            parameters: parameters,
            bundleId: config.bundleId,
            version: config.version,
            build: config.build
        )

        Task.detached {
            guard !Task.isCancelled else { return }
            let result = await ScovilleNetwork.shared.post(
                endpoint: "/v2/analytics/track",
                apiKey: config.apiKey,
                body: payload
            )

            await ScovilleLogger.shared.log(.analytics, "Attempting to track event: \(eventName)")

            switch result {
            case .success:
                await ScovilleLogger.shared.success(.analytics, "Event '\(eventName)' tracked successfully")
            case .failure(let error):
                let base = await ScovilleNetwork.shared.getCurrentBaseURL()
                await ScovilleLogger.shared.error(.analytics, """
                Failed to track '\(eventName)'
                ├─ URL: \(base.appendingPathComponent("v2/analytics/track"))
                ├─ Error: \(error.localizedDescription)
                └─ Payload: \(payload)
                """)
            }
        }
    }

    public static func track(_ eventName: String, parameters: [String: Any] = [:]) {
        track(StandardEvent(eventName), parameters: parameters)
    }

    // MARK: - Device Registration
    public static func registerDevice(token: String?) {
        guard let config = configuration else {
            Task {
                await ScovilleLogger.shared.warning(.configuration, "Scoville not configured yet — call configure(apiKey:) first. Device Registration failed..")
            }
            return
        }

        let payload = DevicePayload(
            uuid: config.uuid,
            token: token, // ✅ Optional
            platform: "ios",
            version: config.version,
            build: config.build,
            bundleId: config.bundleId
        )

        Task.detached {
            let result = await ScovilleNetwork.shared.post(
                endpoint: "/v2/devices/register",
                apiKey: config.apiKey,
                body: payload
            )

            switch result {
            case .success:
                await ScovilleLogger.shared.success(.device, "Device registered successfully")
            case .failure(let error):
                await ScovilleLogger.shared.error(.device, "Device registration failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Debug
    public static func debugPrintStatus() {
        guard let config = configuration else {
            print("[ScovilleKit][Config] ⚠️ Not configured — call Scoville.configure(apiKey:) first.")
            return
        }

        Task {
            let base = await ScovilleNetwork.shared.getCurrentBaseURL()
            await ScovilleLogger.shared.log(.lifecycle, """
            🧠 Status Report
            ├─ App: \(config.bundleId)
            ├─ Version: \(config.version) (\(config.build))
            ├─ UUID: \(config.uuid)
            └─ API Base URL: \(base.absoluteString)
            """)
        }
    }

    // MARK: - Diagnostics
    @discardableResult
    public static func testHeartbeat(
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) -> Task<Void, Never> {
        guard let config = configuration else {
            Task {
                await ScovilleLogger.shared.warning(.configuration, "Cannot send heartbeat — not configured.")
            }
            completion(.failure(NSError(
                domain: "ScovilleKit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "ScovilleKit not configured"]
            )))
            return Task {}
        }

        return Task.detached {
            guard !Task.isCancelled else { return }
            await ScovilleLogger.shared.log(.network, "💓 Sending heartbeat to /v2/heartbeat …")

            let result = await ScovilleNetwork.shared.get(
                endpoint: "/v2/heartbeat",
                apiKey: config.apiKey
            )

            switch result {
            case .success(let data):
                await ScovilleLogger.shared.success(.network, "Heartbeat successful — configuration and network OK")
                if let json = String(data: data, encoding: .utf8) {
                    await ScovilleLogger.shared.log(.network, "Response: \(json)")
                }
                completion(.success(()))
            case .failure(let error):
                await ScovilleLogger.shared.error(.network, "Heartbeat failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Configuration Model
private extension Scoville {
    struct Configuration: Sendable {
        let apiKey: String
        let bundleId: String
        let version: String
        let build: String
        let uuid: String
    }
}

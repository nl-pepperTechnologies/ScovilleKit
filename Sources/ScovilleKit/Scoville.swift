//
//  Scoville.swift
//  ScovilleKit
//

import Foundation

@MainActor
public enum Scoville {
    private static var configuration: Configuration?
    private static let storage = ScovilleStorage()
    private static let logger = ScovilleLogger()

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

        logger.log("✅ Scoville configured for \(info.bundleId) — version \(info.version) (\(info.build))")
    }
    
    public static func configureAPI(url: String) {
            Task {
                await ScovilleNetwork.shared.configureBaseURL(url: url)
            }
        }

    // MARK: - Event Tracking
    public static func track(_ event: AnalyticsEventName, parameters: [String: Any] = [:]) {
        guard let config = configuration else {
            logger.log("⚠️ Scoville not configured yet — call configure(apiKey:) first.")
            return
        }

        let eventName = event.rawValue  // capture only the string (Sendable)
        let payload = EventPayload(
            uuid: config.uuid,
            eventName: eventName,
            parameters: parameters,
            bundleId: config.bundleId,
            version: config.version,
            build: config.build
        )

        ScovilleNetwork.shared.post(
            endpoint: "/v2/analytics/track",
            apiKey: config.apiKey,
            body: payload
        ) { result in
            // hop back to main actor for logging
            Task { @MainActor in
                switch result {
                case .success:
                    logger.log("📊 Event '\(eventName)' tracked successfully.")
                case .failure(let error):
                    logger.log("❌ Failed to track '\(eventName)': \(error.localizedDescription)")
                }
            }
        }
    }

    public static func track(_ eventName: String, parameters: [String: Any] = [:]) {
        track(StandardEvent(eventName), parameters: parameters)
    }

    // MARK: - Device Registration
    public static func registerDevice(token: String) {
        guard let config = configuration else {
            logger.log("⚠️ Scoville not configured yet — call configure(apiKey:) first.")
            return
        }

        let payload = DevicePayload(
            uuid: config.uuid,
            token: token,
            platform: "ios",
            version: config.version,
            build: config.build,
            bundleId: config.bundleId
        )

        ScovilleNetwork.shared.post(
            endpoint: "/v2/devices/register",
            apiKey: config.apiKey,
            body: payload
        ) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    logger.log("📡 Device registered successfully.")
                case .failure(let error):
                    logger.log("❌ Device registration failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Debug
    public static func debugPrintStatus() {
        let prefix = "[ScovilleKit]"

        guard let config = configuration else {
            print("\(prefix) ⚠️ Not configured — call Scoville.configure(apiKey:) first.")
            return
        }

        // Fetch current API URL (using the actor)
        Task {
            let base = await ScovilleNetwork.shared.getCurrentBaseURL()

            print("""
            \(prefix) 🧠 Status Report
            \(prefix) ├─ App: \(config.bundleId)
            \(prefix) ├─ Version: \(config.version) (\(config.build))
            \(prefix) ├─ UUID: \(config.uuid)
            \(prefix) └─ API Base URL: \(base.absoluteString)
            """)
        }
    }
    
    // MARK: - Diagnostics
    @discardableResult
    public static func testHeartbeat(
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) -> Task<Void, Never> {
        guard let config = configuration else {
            print("[ScovilleKit] ⚠️ Cannot send heartbeat — not configured.")
            completion(.failure(NSError(
                domain: "ScovilleKit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "ScovilleKit not configured"]
            )))
            return Task {}
        }

        print("[ScovilleKit] 💓 Sending heartbeat to /v2/heartbeat …")

        struct HeartbeatPayload: Codable, Sendable {
            let uuid: String
            let bundleId: String
            let version: String
            let build: String
        }

        let payload = HeartbeatPayload(
            uuid: config.uuid,
            bundleId: config.bundleId,
            version: config.version,
            build: config.build
        )

        // Perform request
        return Task {
            await ScovilleNetwork.shared.post(
                endpoint: "/v2/heartbeat",
                apiKey: config.apiKey,
                body: payload
            ) { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        print("[ScovilleKit] ✅ Heartbeat successful — configuration and network OK.")
                        completion(.success(()))
                    case .failure(let error):
                        print("[ScovilleKit] ❌ Heartbeat failed: \(error.localizedDescription) (\(error))")
                        completion(.failure(error))
                    }
                }
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

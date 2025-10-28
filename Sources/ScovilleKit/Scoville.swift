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
        if let config = configuration {
            logger.log("""
            🧠 ScovilleKit Status:
            UUID: \(config.uuid)
            App: \(config.bundleId)
            Version: \(config.version) (\(config.build))
            """)
        } else {
            logger.log("⚠️ ScovilleKit not configured.")
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

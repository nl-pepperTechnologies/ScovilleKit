//
//  EventPayload.swift
//  ScovilleKit
//

import Foundation

/// Payload for `/v2/analytics/track`
struct EventPayload: Codable, Sendable {
    let uuid: String
    let event_name: String
    let parameters: [String: AnalyticsValue]
    let bundle_id: String
    let version: String
    let build: String

    init(
        uuid: String,
        eventName: String,
        parameters: [String: Any],
        bundleId: String,
        version: String,
        build: String
    ) {
        self.uuid = uuid
        self.event_name = eventName
        self.parameters = parameters.compactMapValues { value in
            switch value {
            case let v as String: return .string(v)
            case let v as Int: return .int(v)
            case let v as Double: return .double(v)
            case let v as Bool: return .bool(v)
            default: return nil
            }
        }
        self.bundle_id = bundleId
        self.version = version
        self.build = build
    }
}

//
//  EventPayload.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

/// Payload for `/v2/analytics/track`
struct EventPayload: Codable {
    let uuid: String
    let eventName: String
    let parameters: [String: AnyCodable]
    let bundleId: String
    let version: String
    let build: String

    init(uuid: String, eventName: String, parameters: [String: Any], bundleId: String, version: String, build: String) {
        self.uuid = uuid
        self.eventName = eventName
        self.parameters = parameters.mapValues { AnyCodable($0) }
        self.bundleId = bundleId
        self.version = version
        self.build = build
    }
}

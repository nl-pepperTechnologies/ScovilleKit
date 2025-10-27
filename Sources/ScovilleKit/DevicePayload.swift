//
//  DevicePayload.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

/// Payload for `/v2/devices/register`
struct DevicePayload: Codable {
    let uuid: String
    let token: String
    let platform: String
    let version: String
    let build: String
    let bundleId: String
}

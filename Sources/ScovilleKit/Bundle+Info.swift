//
//  Bundle+Info.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

extension Bundle {
    var scovilleInfo: (bundleId: String, version: String, build: String) {
        let id = bundleIdentifier ?? "unknown"
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return (id, version, build)
    }
}

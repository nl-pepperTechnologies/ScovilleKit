//
//  ScovilleLogger.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

/// Structured log categories for consistent namespacing.
enum ScovilleLogCategory: String, Sendable {
    case device = "Device"
    case network = "Network"
    case analytics = "Analytics"
    case configuration = "Config"
    case lifecycle = "Lifecycle"
    case warning = "Warning"
}

/// Concurrency-safe developer logger for ScovilleKit.
/// Usage:
/// ```swift
/// await ScovilleLogger.shared.log(.device, "Registered successfully")
/// ```
actor ScovilleLogger {
    static let shared = ScovilleLogger()

    private var isEnabled = true

    func enable(_ value: Bool = true) {
        isEnabled = value
    }

    func log(_ category: ScovilleLogCategory, _ message: String) {
        guard isEnabled else { return }
        print("[ScovilleKit][\(category.rawValue)] \(message)")
    }

    func success(_ category: ScovilleLogCategory, _ message: String) {
        log(category, "✅ \(message)")
    }

    func warning(_ category: ScovilleLogCategory, _ message: String) {
        log(category, "⚠️ \(message)")
    }

    func error(_ category: ScovilleLogCategory, _ message: String) {
        log(category, "❌ \(message)")
    }
}

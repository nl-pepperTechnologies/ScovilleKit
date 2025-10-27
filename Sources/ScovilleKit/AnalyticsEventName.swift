//
//  AnalyticsEventName.swift
//  ScovilleKit
//

import Foundation

/// Protocol representing any analytics event name.
/// Conforming types must be immutable and thread-safe.
public protocol AnalyticsEventName: Sendable {
    var rawValue: String { get }
}

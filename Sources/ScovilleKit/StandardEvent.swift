//
//  StandardEvent.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

/// Common event names shared across Pepper Technologies apps.
/// Immutable and Sendable for safe use across concurrency domains.
public struct StandardEvent: AnalyticsEventName, Sendable {
    public let rawValue: String

    /// Create a custom standard event.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: - Shared Events (Common Across Apps)

    public static let appOpened = StandardEvent("AppOpened")
    public static let adImpression = StandardEvent("AdImpression")

    // Ad Clicks
    public static let bannerAdClicked = StandardEvent("BannerAdClicked")
    public static let nativeAdClicked = StandardEvent("NativeAdClicked")
    public static let backupAdClicked = StandardEvent("BackupAdClicked")
    public static let interAdClicked = StandardEvent("InterAdClicked")

    // Ad Loads
    public static let bannerAdLoaded = StandardEvent("BannerAdLoaded")
    public static let nativeAdLoaded = StandardEvent("NativeAdLoaded")
    public static let backupAdLoaded = StandardEvent("BackupAdLoaded")
    public static let interAdLoaded = StandardEvent("InterAdLoaded")
}

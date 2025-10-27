//
//  ScovilleLogger.swift
//  ScovilleKit
//
//  Created by Pepper Technologies
//

import Foundation

/// Simple debug logger for Scoville output.
final class ScovilleLogger {
    var isEnabled = true

    func log(_ message: String) {
        guard isEnabled else { return }
        print("[ScovilleKit] \(message)")
    }
}

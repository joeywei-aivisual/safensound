//
//  CheckInStatus.swift
//  safensound
//

import SwiftUI

enum CheckInStatus {
    case normal
    case warning // Within 3 hours of threshold
    case expired // Past threshold
    
    var displayText: String {
        switch self {
        case .normal:
            return String(localized: "Normal")
        case .warning:
            return String(localized: "Warning")
        case .expired:
            return String(localized: "Expired")
        }
    }
    
    var color: Color {
        switch self {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .expired:
            return .red
        }
    }
}

//
//  EmergencyContact.swift
//  safensound
//

import Foundation

struct EmergencyContact: Codable, Identifiable, Equatable {
    var id: String
    var email: String
    var name: String? // Optional, can be inferred from email
    
    init(id: String = UUID().uuidString, email: String, name: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
    }
}

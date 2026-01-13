//
//  safensoundApp.swift
//  safensound
//
//  Created by Joey Wei on 1/12/26.
//

import SwiftUI
import CoreData

@main
struct safensoundApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

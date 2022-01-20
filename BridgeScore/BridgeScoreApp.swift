//
//  BridgeScoreApp.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/01/2022.
//

import SwiftUI

@main
struct BridgeScoreApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

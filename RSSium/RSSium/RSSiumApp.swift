//
//  RSSiumApp.swift
//  RSSium
//
//  Created by 小暮成男 on 2025/07/15.
//

import SwiftUI

@main
struct RSSiumApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

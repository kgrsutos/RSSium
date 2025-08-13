//
//  ContentView.swift
//  RSSium
//
//  Created by 小暮成男 on 2025/07/15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FeedListView()
                .tabItem {
                    Label("Feeds", systemImage: "rss")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}

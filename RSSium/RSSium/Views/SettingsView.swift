import SwiftUI

struct SettingsView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @AppStorage("refreshInterval") private var refreshInterval: Double = 60
    @AppStorage("showUnreadOnly") private var showUnreadOnly: Bool = false
    @AppStorage("enableBackgroundRefresh") private var enableBackgroundRefresh: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Network") {
                    HStack {
                        Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        Text("Network Status")
                        Spacer()
                        Text(networkMonitor.isConnected ? "Connected" : "Offline")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Feed Settings") {
                    HStack {
                        Text("Refresh Interval")
                        Spacer()
                        Text("\(Int(refreshInterval)) minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $refreshInterval, in: 15...240, step: 15) {
                        Text("Refresh Interval")
                    }
                    .accessibilityValue("\(Int(refreshInterval)) minutes")
                    
                    Toggle("Background Refresh", isOn: $enableBackgroundRefresh)
                        .accessibilityLabel("Enable background refresh")
                        .accessibilityHint("Automatically refresh feeds when app is in background")
                    
                    Toggle("Show Unread Only", isOn: $showUnreadOnly)
                        .accessibilityLabel("Show unread articles only")
                        .accessibilityHint("Filter to show only unread articles in feed lists")
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
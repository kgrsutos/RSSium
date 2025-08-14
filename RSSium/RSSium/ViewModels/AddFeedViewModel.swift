import Foundation
import SwiftUI

@MainActor
class AddFeedViewModel: ObservableObject {
    @Published var url = ""
    @Published var customTitle = ""
    @Published var useCustomTitle = false
    @Published var isValidating = false
    @Published var isValid = false
    @Published var validationMessage = ""
    @Published var previewTitle = ""
    
    private let rssService: RSSService
    private let networkMonitor: NetworkMonitor
    
    init(rssService: RSSService, networkMonitor: NetworkMonitor) {
        self.rssService = rssService
        self.networkMonitor = networkMonitor
    }
    
    var isURLValid: Bool {
        !url.isEmpty && rssService.validateFeedURL(url)
    }
    
    var finalTitle: String {
        useCustomTitle && !customTitle.isEmpty ? customTitle : previewTitle
    }
    
    var canSubmit: Bool {
        isURLValid && !finalTitle.isEmpty && !isValidating && networkMonitor.isConnected
    }
    
    func validateFeed() async {
        guard isURLValid else {
            isValid = false
            validationMessage = "Please enter a valid URL"
            previewTitle = ""
            return
        }
        
        guard networkMonitor.isConnected else {
            isValid = false
            validationMessage = "Network connection is required to validate feeds"
            previewTitle = ""
            return
        }
        
        isValidating = true
        validationMessage = ""
        previewTitle = ""
        
        do {
            let channel = try await rssService.fetchAndParseFeed(from: url)
            await MainActor.run {
                self.isValid = true
                self.previewTitle = channel.title
                self.validationMessage = "Feed found: \(channel.title)"
            }
        } catch let error as RSSError {
            await MainActor.run {
                self.isValid = false
                self.previewTitle = ""
                self.validationMessage = self.formatErrorMessage(error)
            }
        } catch {
            await MainActor.run {
                self.isValid = false
                self.previewTitle = ""
                self.validationMessage = "Failed to validate feed: \(error.localizedDescription)"
            }
        }
        
        isValidating = false
    }
    
    func reset() {
        url = ""
        customTitle = ""
        useCustomTitle = false
        isValidating = false
        isValid = false
        validationMessage = ""
        previewTitle = ""
    }
    
    private func formatErrorMessage(_ error: RSSError) -> String {
        switch error {
        case .networkError(let underlyingError):
            if let urlError = underlyingError as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet connection"
                case .timedOut:
                    return "Request timed out"
                case .cannotFindHost:
                    return "Cannot find server"
                case .cannotConnectToHost:
                    return "Cannot connect to server"
                default:
                    return error.localizedDescription
                }
            }
            return error.localizedDescription
        default:
            return error.localizedDescription
        }
    }
}
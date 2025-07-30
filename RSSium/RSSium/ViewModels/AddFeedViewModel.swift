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
    
    init(rssService: RSSService = .shared) {
        self.rssService = rssService
    }
    
    var isURLValid: Bool {
        !url.isEmpty && rssService.validateFeedURL(url)
    }
    
    var finalTitle: String {
        useCustomTitle && !customTitle.isEmpty ? customTitle : previewTitle
    }
    
    var canSubmit: Bool {
        isURLValid && !finalTitle.isEmpty && !isValidating
    }
    
    func validateFeed() async {
        guard isURLValid else {
            isValid = false
            validationMessage = "Please enter a valid URL"
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
                self.validationMessage = error.localizedDescription
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
}
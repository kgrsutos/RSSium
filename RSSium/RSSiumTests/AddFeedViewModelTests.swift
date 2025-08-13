import Testing
@testable import RSSium

struct AddFeedViewModelTests {
    
    // Create test services for isolated testing
    @MainActor
    private func createTestServices() -> (RSSService, NetworkMonitor) {
        let rssService = RSSService.shared
        let networkMonitor = NetworkMonitor.shared
        return (rssService, networkMonitor)
    }
    
    @Test("Initial state should be empty")
    @MainActor func initialState() async {
        let (rssService, networkMonitor) = createTestServices()
        let viewModel = AddFeedViewModel(rssService: rssService, networkMonitor: networkMonitor)
        #expect(viewModel.url.isEmpty)
        #expect(viewModel.customTitle.isEmpty)
        #expect(viewModel.useCustomTitle == false)
        #expect(viewModel.isValidating == false)
        #expect(viewModel.isValid == false)
        #expect(viewModel.validationMessage.isEmpty)
        #expect(viewModel.previewTitle.isEmpty)
    }
    
    @Test("isURLValid should validate URL format")
    @MainActor func isURLValidValidation() async {
        let (rssService, networkMonitor) = createTestServices()
        let viewModel = AddFeedViewModel(rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.url = ""
        #expect(viewModel.isURLValid == false)
        
        viewModel.url = "invalid-url"
        #expect(viewModel.isURLValid == false)
        
        viewModel.url = "https://example.com/feed.xml"
        #expect(viewModel.isURLValid == true)
        
        viewModel.url = "http://example.com/feed.xml"
        #expect(viewModel.isURLValid == true)
    }
    
    @Test("finalTitle should return custom title when enabled")
    @MainActor func finalTitleWithCustomTitle() async {
        let (rssService, networkMonitor) = createTestServices()
        let viewModel = AddFeedViewModel(rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.previewTitle = "Preview Title"
        viewModel.customTitle = "Custom Title"
        viewModel.useCustomTitle = false
        
        #expect(viewModel.finalTitle == "Preview Title")
        
        viewModel.useCustomTitle = true
        #expect(viewModel.finalTitle == "Custom Title")
        
        viewModel.customTitle = ""
        #expect(viewModel.finalTitle == "Preview Title")
    }
    
    @Test("canSubmit should validate all requirements")
    @MainActor func canSubmitValidation() async {
        let (rssService, networkMonitor) = createTestServices()
        let viewModel = AddFeedViewModel(rssService: rssService, networkMonitor: networkMonitor)
        
        #expect(viewModel.canSubmit == false)
        
        viewModel.url = "https://example.com/feed.xml"
        #expect(viewModel.canSubmit == false) // no title
        
        viewModel.previewTitle = "Test Title"
        #expect(viewModel.canSubmit == true)
        
        viewModel.isValidating = true
        #expect(viewModel.canSubmit == false)
        
        viewModel.isValidating = false
        #expect(viewModel.canSubmit == true)
        
        viewModel.url = "invalid-url"
        #expect(viewModel.canSubmit == false)
    }
    
    @Test("validate feed with invalid URL should set error")
    @MainActor func validateFeedInvalidURL() async {
        let (rssService, networkMonitor) = createTestServices()
        let viewModel = AddFeedViewModel(rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.url = "invalid-url"
        
        await viewModel.validateFeed()
        
        #expect(viewModel.isValid == false)
        #expect(viewModel.previewTitle.isEmpty)
        #expect(viewModel.validationMessage == "Please enter a valid URL")
    }
    
    @Test("reset should clear all fields")
    @MainActor func resetClearsAllFields() async {
        let (rssService, networkMonitor) = createTestServices()
        let viewModel = AddFeedViewModel(rssService: rssService, networkMonitor: networkMonitor)
        
        viewModel.url = "https://example.com/feed.xml"
        viewModel.customTitle = "Custom Title"
        viewModel.useCustomTitle = true
        viewModel.isValidating = true
        viewModel.isValid = true
        viewModel.validationMessage = "Valid feed"
        viewModel.previewTitle = "Preview Title"
        
        viewModel.reset()
        
        #expect(viewModel.url.isEmpty)
        #expect(viewModel.customTitle.isEmpty)
        #expect(viewModel.useCustomTitle == false)
        #expect(viewModel.isValidating == false)
        #expect(viewModel.isValid == false)
        #expect(viewModel.validationMessage.isEmpty)
        #expect(viewModel.previewTitle.isEmpty)
    }
}
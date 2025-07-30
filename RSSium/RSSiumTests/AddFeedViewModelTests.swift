import XCTest
import Testing
@testable import RSSium

struct AddFeedViewModelTests {
    
    @Test("Initial state should be empty")
    func initialState() async {
        let viewModel = await AddFeedViewModel()
        
        await MainActor.run {
            #expect(viewModel.url.isEmpty)
            #expect(viewModel.customTitle.isEmpty)
            #expect(viewModel.useCustomTitle == false)
            #expect(viewModel.isValidating == false)
            #expect(viewModel.isValid == false)
            #expect(viewModel.validationMessage.isEmpty)
            #expect(viewModel.previewTitle.isEmpty)
        }
    }
    
    @Test("isURLValid should validate URL format")
    func isURLValidValidation() async {
        let viewModel = await AddFeedViewModel()
        
        await MainActor.run {
            viewModel.url = ""
            #expect(viewModel.isURLValid == false)
            
            viewModel.url = "invalid-url"
            #expect(viewModel.isURLValid == false)
            
            viewModel.url = "https://example.com/feed.xml"
            #expect(viewModel.isURLValid == true)
            
            viewModel.url = "http://example.com/feed.xml"
            #expect(viewModel.isURLValid == true)
        }
    }
    
    @Test("finalTitle should return custom title when enabled")
    func finalTitleWithCustomTitle() async {
        let viewModel = await AddFeedViewModel()
        
        await MainActor.run {
            viewModel.previewTitle = "Preview Title"
            viewModel.customTitle = "Custom Title"
            viewModel.useCustomTitle = false
            
            #expect(viewModel.finalTitle == "Preview Title")
            
            viewModel.useCustomTitle = true
            #expect(viewModel.finalTitle == "Custom Title")
            
            viewModel.customTitle = ""
            #expect(viewModel.finalTitle == "Preview Title")
        }
    }
    
    @Test("canSubmit should validate all requirements")
    func canSubmitValidation() async {
        let viewModel = await AddFeedViewModel()
        
        await MainActor.run {
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
    }
    
    @Test("validate feed with invalid URL should set error")
    func validateFeedInvalidURL() async {
        let viewModel = await AddFeedViewModel()
        
        await MainActor.run {
            viewModel.url = "invalid-url"
        }
        
        await viewModel.validateFeed()
        
        await MainActor.run {
            #expect(viewModel.isValid == false)
            #expect(viewModel.previewTitle.isEmpty)
            #expect(viewModel.validationMessage == "Please enter a valid URL")
        }
    }
    
    @Test("reset should clear all fields")
    func resetClearsAllFields() async {
        let viewModel = await AddFeedViewModel()
        
        await MainActor.run {
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
}
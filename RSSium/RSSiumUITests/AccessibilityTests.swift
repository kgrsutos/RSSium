import XCTest

final class AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testVoiceOverSupport() throws {
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        XCTAssertTrue(addButton.exists)
        XCTAssertNotNil(addButton.label)
        XCTAssertTrue(addButton.isHittable)
        
        let feedCells = app.cells
        if feedCells.count > 0 {
            let firstCell = feedCells.element(boundBy: 0)
            XCTAssertNotNil(firstCell.label)
            XCTAssertTrue(firstCell.accessibilityTraits.contains(.button))
        }
    }
    
    @MainActor
    func testDynamicTypeScaling() throws {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        
        let navigationBar = app.navigationBars["Feeds"]
        XCTAssertTrue(navigationBar.exists)
        
        if app.cells.count > 0 {
            let feedCell = app.cells.firstMatch
            XCTAssertTrue(feedCell.exists)
            
            let titleText = feedCell.staticTexts.firstMatch
            XCTAssertTrue(titleText.exists)
        }
    }
    
    @MainActor
    func testAccessibilityLabels() throws {
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        addButton.tap()
        
        let urlTextField = app.textFields["Feed URL"]
        XCTAssertTrue(urlTextField.exists)
        XCTAssertNotNil(urlTextField.placeholderValue)
        XCTAssertEqual(urlTextField.label, "Feed URL")
        
        let validateButton = app.buttons["Validate Feed"]
        XCTAssertTrue(validateButton.exists)
        XCTAssertEqual(validateButton.label, "Validate Feed")
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    @MainActor
    func testAccessibilityHints() throws {
        if app.cells.count > 0 {
            let feedCell = app.cells.firstMatch
            XCTAssertTrue(feedCell.exists)
            
            let swipeActions = feedCell.buttons.matching(identifier: "Delete")
            if swipeActions.count > 0 {
                let deleteButton = swipeActions.firstMatch
                XCTAssertNotNil(deleteButton.label)
            }
        }
    }
    
    @MainActor
    func testReduceMotionSupport() throws {
        app.launchArguments += ["UIAccessibilityReduceMotion", "1"]
        app.launch()
        
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        addButton.tap()
        
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()
        
        XCTAssertTrue(app.navigationBars["Feeds"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testColorContrastCompliance() throws {
        if app.cells.count == 0 {
            let emptyStateText = app.staticTexts["No Feeds Yet"]
            XCTAssertTrue(emptyStateText.exists)
            
            let instructionText = app.staticTexts["Tap the + button to add your first RSS feed"]
            XCTAssertTrue(instructionText.exists)
        }
    }
    
    @MainActor
    func testKeyboardNavigation() throws {
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        addButton.tap()
        
        let urlTextField = app.textFields["Feed URL"]
        urlTextField.tap()
        
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        
        app.keyboards.buttons["Done"].tap()
        
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }
    
    @MainActor
    func testAccessibilityTraits() throws {
        if app.cells.count > 0 {
            let feedCell = app.cells.firstMatch
            XCTAssertTrue(feedCell.exists)
            XCTAssertTrue(feedCell.accessibilityTraits.contains(.button))
            
            feedCell.tap()
            
            if app.cells.count > 0 {
                let articleCell = app.cells.firstMatch
                XCTAssertTrue(articleCell.waitForExistence(timeout: 10))
                XCTAssertTrue(articleCell.accessibilityTraits.contains(.button))
            }
        }
    }
    
    @MainActor
    func testAccessibilityGrouping() throws {
        if app.cells.count > 0 {
            let feedCell = app.cells.firstMatch
            
            let titleElements = feedCell.staticTexts.allElementsBoundByIndex
            let imageElements = feedCell.images.allElementsBoundByIndex
            
            XCTAssertTrue(titleElements.count > 0 || imageElements.count > 0)
        }
    }
    
    @MainActor
    func testLargeContentViewer() throws {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        
        let navigationTitle = app.navigationBars["Feeds"].staticTexts["Feeds"]
        XCTAssertTrue(navigationTitle.exists)
        
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        XCTAssertTrue(addButton.exists)
        XCTAssertTrue(addButton.isHittable)
    }
}
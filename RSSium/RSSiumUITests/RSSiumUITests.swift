//
//  RSSiumUITests.swift
//  RSSiumUITests
//
//  Created by 小暮成男 on 2025/07/15.
//

import XCTest

final class RSSiumUITests: XCTestCase {
    
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
    func testAddNewFeed() throws {
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()
        
        let urlTextField = app.textFields["Feed URL"]
        XCTAssertTrue(urlTextField.exists)
        urlTextField.tap()
        urlTextField.typeText("https://feeds.feedburner.com/TechCrunch")
        
        let validateButton = app.buttons["Validate Feed"]
        XCTAssertTrue(validateButton.exists)
        validateButton.tap()
        
        let feedExists = app.staticTexts["TechCrunch"].waitForExistence(timeout: 10)
        XCTAssertTrue(feedExists)
        
        let addFeedButton = app.buttons["Add Feed"]
        XCTAssertTrue(addFeedButton.exists)
        addFeedButton.tap()
        
        let feedInList = app.cells.containing(.staticText, identifier: "TechCrunch").element
        XCTAssertTrue(feedInList.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testNavigateToArticles() throws {
        let feedCell = app.cells.firstMatch
        if feedCell.waitForExistence(timeout: 5) {
            feedCell.tap()
            
            let articlesNavigationBar = app.navigationBars.element(boundBy: 0)
            XCTAssertTrue(articlesNavigationBar.waitForExistence(timeout: 5))
            
            let articleCell = app.cells.firstMatch
            XCTAssertTrue(articleCell.waitForExistence(timeout: 10))
        }
    }
    
    @MainActor
    func testReadArticle() throws {
        let feedCell = app.cells.firstMatch
        if feedCell.waitForExistence(timeout: 5) {
            feedCell.tap()
            
            let articleCell = app.cells.firstMatch
            if articleCell.waitForExistence(timeout: 10) {
                articleCell.tap()
                
                let articleContent = app.scrollViews.firstMatch
                XCTAssertTrue(articleContent.waitForExistence(timeout: 5))
                
                let openInBrowserButton = app.buttons["Open in Browser"]
                XCTAssertTrue(openInBrowserButton.exists)
            }
        }
    }
    
    @MainActor
    func testDeleteFeed() throws {
        let feedCell = app.cells.firstMatch
        if feedCell.waitForExistence(timeout: 5) {
            feedCell.swipeLeft()
            
            let deleteButton = app.buttons["Delete"]
            XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
            deleteButton.tap()
        }
    }
    
    @MainActor
    func testRefreshFeed() throws {
        let feedCell = app.cells.firstMatch
        if feedCell.waitForExistence(timeout: 5) {
            let startCoordinate = feedCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endCoordinate = feedCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 2.0))
            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            
            sleep(2)
        }
    }
    
    @MainActor
    func testEmptyState() throws {
        if app.cells.count == 0 {
            let emptyStateText = app.staticTexts["No Feeds Yet"]
            XCTAssertTrue(emptyStateText.exists)
            
            let instructionText = app.staticTexts["Tap the + button to add your first RSS feed"]
            XCTAssertTrue(instructionText.exists)
        }
    }
    
    @MainActor
    func testAddFeedValidation() throws {
        let addButton = app.navigationBars["Feeds"].buttons["Add"]
        addButton.tap()
        
        let urlTextField = app.textFields["Feed URL"]
        urlTextField.tap()
        urlTextField.typeText("invalid-url")
        
        let validateButton = app.buttons["Validate Feed"]
        validateButton.tap()
        
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5))
        
        let okButton = errorAlert.buttons["OK"]
        okButton.tap()
    }
    
    @MainActor
    func testMarkArticleAsRead() throws {
        let feedCell = app.cells.firstMatch
        if feedCell.waitForExistence(timeout: 5) {
            let initialUnreadCount = getUnreadCount(from: feedCell)
            
            feedCell.tap()
            
            let articleCell = app.cells.firstMatch
            if articleCell.waitForExistence(timeout: 10) {
                articleCell.tap()
                
                app.navigationBars.buttons.element(boundBy: 0).tap()
                
                app.navigationBars.buttons.element(boundBy: 0).tap()
                
                let updatedUnreadCount = getUnreadCount(from: feedCell)
                XCTAssertLessThan(updatedUnreadCount, initialUnreadCount)
            }
        }
    }
    
    private func getUnreadCount(from cell: XCUIElement) -> Int {
        let unreadBadge = cell.descendants(matching: .staticText).matching(NSPredicate(format: "label MATCHES '[0-9]+'")).firstMatch
        if unreadBadge.exists {
            return Int(unreadBadge.label) ?? 0
        }
        return 0
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

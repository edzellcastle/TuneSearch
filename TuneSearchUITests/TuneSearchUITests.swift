//
//  TuneSearchUITests.swift
//  TuneSearchUITests
//
//  Created by David Lindsay on 5/22/17.
//  Copyright © 2017 Tapinfuse. All rights reserved.
//

import XCTest

class TuneSearchUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOne() {

        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let searchController = tablesQuery.searchFields["Search"]
        searchController.tap()
        let searchSearchField = app.searchFields["Search"]
        searchSearchField.typeText("A")
        let lKey = app.keys["l"]
        lKey.tap()
        lKey.tap()
        app.keys["m"].tap()
        app.keys["a"].tap()
        app.keys["n"].tap()
        
        app.typeText("\n")
    }
    
    func testTwo() {
        
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let searchController = tablesQuery.searchFields["Search"]
        searchController.tap()
        app.searchFields["Search"].typeText("Albert king")
        app.typeText("\n")
   
        tablesQuery.children(matching: .cell).element(boundBy: 7).children(matching: .other).element.swipeDown()
        tablesQuery.children(matching: .cell).element(boundBy: 7).children(matching: .other).element.swipeUp()
    }
}

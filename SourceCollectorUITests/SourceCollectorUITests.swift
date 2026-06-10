//
//  SourceCollectorUITests.swift
//  SourceCollectorUITests
//

import XCTest

final class SourceCollectorUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func test_appLaunches_showsRecentProjectsHeader() throws {
        XCTAssertTrue(app.staticTexts["Recent Projects"].exists)
    }

    @MainActor
    func test_appLaunches_showsProjectPathField() throws {
        let pathField = app.textFields["projectPathField"]
        XCTAssertTrue(pathField.exists)
    }

    @MainActor
    func test_appLaunches_showsChooseFolderButton() throws {
        XCTAssertTrue(app.buttons["Choose Folder"].exists)
    }

    @MainActor
    func test_appLaunches_showsLoadButton() throws {
        XCTAssertTrue(app.buttons["Load"].exists)
    }

    @MainActor
    func test_appLaunches_showsFileTypeToggles() throws {
        let swiftToggle = app.checkBoxes["toggle_swift"]
        XCTAssertTrue(swiftToggle.exists)
        XCTAssertEqual(swiftToggle.value as? Int, 1)

        let ktToggle = app.checkBoxes["toggle_kt"]
        XCTAssertTrue(ktToggle.exists)
        XCTAssertEqual(ktToggle.value as? Int, 1)
    }

    @MainActor
    func test_appLaunches_showsSelectAllButton() throws {
        XCTAssertTrue(app.buttons["Select All"].exists)
    }

    @MainActor
    func test_copySelectedButton_disabledWhenNoFiles() throws {
        let copyButton = app.buttons["copySelectedButton"]
        XCTAssertTrue(copyButton.exists)
        XCTAssertFalse(copyButton.isEnabled)
    }

    @MainActor
    func test_toggleFileType_disablesExtension() throws {
        let swiftToggle = app.checkBoxes["toggle_swift"]
        XCTAssertTrue(swiftToggle.exists)

        swiftToggle.click()
        XCTAssertEqual(swiftToggle.value as? Int, 0)

        swiftToggle.click()
        XCTAssertEqual(swiftToggle.value as? Int, 1)
    }

    @MainActor
    func test_typeInPathField() throws {
        let pathField = app.textFields["projectPathField"]
        pathField.click()
        pathField.typeText("/tmp/test/path")
        XCTAssertEqual(pathField.value as? String, "/tmp/test/path")
    }

    @MainActor
    func test_appLaunches_showsFileTypesHeader() throws {
        XCTAssertTrue(app.staticTexts["File Types"].exists)
    }

    @MainActor
    func test_loadButton_withEmptyPath_doesNotCrash() throws {
        app.buttons["Load"].click()
        let copyButton = app.buttons["copySelectedButton"]
        XCTAssertFalse(copyButton.isEnabled)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

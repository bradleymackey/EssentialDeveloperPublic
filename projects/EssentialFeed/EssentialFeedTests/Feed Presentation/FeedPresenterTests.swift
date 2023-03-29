//
//  FeedPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 01/03/2023.
//

import XCTest
import EssentialFeed

class FeedPresenterTests: XCTestCase {
    
    func test_title_isLocalized() {
        XCTAssertEqual(FeedPresenter.title, localized("FEED_VIEW_TITLE"))
    }
    
    func test_map_createsViewModel() {
        let feed = uniqueFeed().models
        
        let viewModel = FeedPresenter.map(feed)
        
        XCTAssertEqual(viewModel.feed, feed)
    }
    
}

// MARK: - Helpers

extension FeedPresenterTests {
    
    private func localized(_ key: String, table: String = "Feed", file: StaticString = #file, line: UInt = #line) -> String {
        let bundle = Bundle(for: FeedPresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        // NOTE:
        // We don't want to test for a specific localized string, because this data is volatile.
        // We just want to check that the localized value actually exists.
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
    
}

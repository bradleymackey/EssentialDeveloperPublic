//
//  FeedViewControllerTests+Localizations.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 21/02/2023.
//

import Foundation
import XCTest
import EssentialFeediOS

extension FeedUIIntegrationTests {
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: FeedViewController.self)
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

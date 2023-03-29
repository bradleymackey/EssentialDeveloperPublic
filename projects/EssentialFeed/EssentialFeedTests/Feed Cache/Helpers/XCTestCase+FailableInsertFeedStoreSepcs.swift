//
//  XCTestCase+FailableInsertFeedStoreSepcs.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 17/05/2022.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert((uniqueFeed().local, Date()), to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert((uniqueFeed().local, Date()), to: sut)
        
        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
}

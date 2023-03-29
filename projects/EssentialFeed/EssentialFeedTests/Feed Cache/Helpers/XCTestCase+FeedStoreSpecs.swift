//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 17/05/2022.
//

import Foundation
import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: any FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var retrievedError: Error?
        sut.insert(cache.feed, at: cache.timestamp) { insertionError in
            retrievedError = insertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return retrievedError
    }
    
    @discardableResult
    func deleteCache(from sut: any FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var retrievedError: Error?
        sut.deleteCachedFeed { deletionError in
            retrievedError = deletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        return retrievedError
    }
    
    func expect(_ sut: any FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
                break
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
}

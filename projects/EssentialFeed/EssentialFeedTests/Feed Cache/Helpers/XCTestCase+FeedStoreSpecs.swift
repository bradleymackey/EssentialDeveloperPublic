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

     func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         expect(sut, toRetrieve: .success(.none), file: file, line: line)
     }

     func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         expect(sut, toRetrieve: .success(.none), file: file, line: line)
         expect(sut, toRetrieve: .success(.none), file: file, line: line)
     }

     func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         let feed = uniqueFeed().local
         let timestamp = Date()

         insert((feed, timestamp), to: sut)

         expect(sut, toRetrieve: .success(.init(feed: feed, timestamp: timestamp)), file: file, line: line)
     }

     func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         let feed = uniqueFeed().local
         let timestamp = Date()

         insert((feed, timestamp), to: sut)

         expect(sut, toRetrieve: .success(.init(feed: feed, timestamp: timestamp)), file: file, line: line)
         expect(sut, toRetrieve: .success(.init(feed: feed, timestamp: timestamp)), file: file, line: line)
     }

     func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         let insertionError = insert((uniqueFeed().local, Date()), to: sut)

         XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
     }

     func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert((uniqueFeed().local, Date()), to: sut)

         let insertionError = insert((uniqueFeed().local, Date()), to: sut)

         XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
     }

     func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert((uniqueFeed().local, Date()), to: sut)

         let latestFeed = uniqueFeed().local
         let latestTimestamp = Date()
         insert((latestFeed, latestTimestamp), to: sut)

         expect(sut, toRetrieve: .success(.init(feed: latestFeed, timestamp: latestTimestamp)), file: file, line: line)
     }

     func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         let deletionError = deleteCache(from: sut)

         XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
     }

     func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         deleteCache(from: sut)

         expect(sut, toRetrieve: .success(.none), file: file, line: line)
     }

     func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert((uniqueFeed().local, Date()), to: sut)

         let deletionError = deleteCache(from: sut)

         XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
     }

     func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert((uniqueFeed().local, Date()), to: sut)

         deleteCache(from: sut)

         expect(sut, toRetrieve: .success(.none), file: file, line: line)
     }

     func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         var completedOperationsInOrder = [XCTestExpectation]()

         let op1 = expectation(description: "Operation 1")
         sut.insert(uniqueFeed().local, at: Date()) { _ in
             completedOperationsInOrder.append(op1)
             op1.fulfill()
         }

         let op2 = expectation(description: "Operation 2")
         sut.deleteCachedFeed { _ in
             completedOperationsInOrder.append(op2)
             op2.fulfill()
         }

         let op3 = expectation(description: "Operation 3")
         sut.insert(uniqueFeed().local, at: Date()) { _ in
             completedOperationsInOrder.append(op3)
             op3.fulfill()
         }

         waitForExpectations(timeout: 5.0)

         XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order", file: file, line: line)
     }
}

extension FeedStoreSpecs where Self: XCTestCase {
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: any FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var retrievedError: Error?
        sut.insert(cache.feed, at: cache.timestamp) { insertionResult in
            if case let Result.failure(error) = insertionResult {
                retrievedError = error
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return retrievedError
    }
    
    @discardableResult
    func deleteCache(from sut: any FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var retrievedError: Error?
        sut.deleteCachedFeed { deletionResult in
            if case let Result.failure(error) = deletionResult {
                retrievedError = error
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        return retrievedError
    }
    
    func expect(_ sut: any FeedStore, toRetrieve expectedResult: FeedStore.RetrievalResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(.none), .success(.none)),
                 (.failure, .failure):
                break
            case let (.success(.some(expected)), .success(.some(retrived))):
                XCTAssertEqual(retrived.feed, expected.feed, file: file, line: line)
                XCTAssertEqual(retrived.timestamp, expected.timestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
}

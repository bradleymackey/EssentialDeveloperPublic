//
//  CacheFeedUseCase.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 28/04/2022.
//

import XCTest
import EssentialFeed

/// Tests that the cache inserts and deletes entries accordingly.
final class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = uniqueFeed()
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        store.completeDeletion(with: deletionError)
        
        try? sut.save(items.models)
        
        // it's important not only to have tests that a method WAS called when it was supposed to,
        // but also to have tests to ensure that a method WAS NOT called when it was not supposed to.
        XCTAssertEqual(store.recievedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = uniqueFeed()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        store.completeDeletionSuccessfully()
        
        try? sut.save(items.models)
        
        XCTAssertEqual(
            store.recievedMessages,
            [.deleteCachedFeed, .insert(feed: items.local, timestamp: timestamp)]
        )
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
}

// MARK: - Helpers

extension CacheFeedUseCaseTests {
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        action()
        
        do {
            try sut.save(uniqueFeed().models)
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, expectedError?.domain, file: file, line: line)
            XCTAssertEqual(nsError.code, expectedError?.code, file: file, line: line)
        }
    }
}

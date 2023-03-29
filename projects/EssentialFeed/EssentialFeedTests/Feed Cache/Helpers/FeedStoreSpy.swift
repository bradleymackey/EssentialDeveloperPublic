//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 04/05/2022.
//

import Foundation
import EssentialFeed

final class FeedStoreSpy: FeedStore {
    private var deletionResult: Result<Void, Error>?
    private var insertionResult: Result<Void, Error>?
    private var retrievalResult: Result<CachedFeed?, Error>?
    
    enum RecievedMessage: Equatable {
        case deleteCachedFeed
        case insert(feed: [LocalFeedImage], timestamp: Date)
        case retrieve
    }
    
    /// Storing a list of messages allows us to test order that the operations were performed.
    /// This is impossible to do with two sepearate properties, as we cannot tell the order that
    /// they were called in.
    private(set) var recievedMessages = [RecievedMessage]()

    func deleteCachedFeed() throws {
        recievedMessages.append(.deleteCachedFeed)
        try deletionResult?.get()
    }
    
    func completeDeletion(with error: Error) {
        deletionResult = .failure(error)
    }
    
    func completeDeletionSuccessfully() {
        deletionResult = .success(())
    }
    
    func insert(_ feed: [LocalFeedImage], at date: Date) throws {
        recievedMessages.append(.insert(feed: feed, timestamp: date))
        try insertionResult?.get()
    }
    
    func completeInsertion(with error: Error) {
        insertionResult = .failure(error)
    }
    
    func completeInsertionSuccessfully() {
        insertionResult = .success(())
    }
    
    func retrieve() throws -> CachedFeed? {
        recievedMessages.append(.retrieve)
        return try retrievalResult?.get()
    }
    
    func completeRetrieval(with error: Error) {
        retrievalResult = .failure(error)
    }
    
    func completeRetrievalWithEmptyCache() {
        retrievalResult = .success(nil)
    }
    
    func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date) {
        retrievalResult = .success(.init(feed: feed, timestamp: timestamp))
    }
}

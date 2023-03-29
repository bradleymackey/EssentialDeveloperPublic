//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 04/05/2022.
//

import Foundation
import EssentialFeed

final class FeedStoreSpy: FeedStore {
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()
    
    enum RecievedMessage: Equatable {
        case deleteCachedFeed
        case insert(feed: [LocalFeedImage], timestamp: Date)
        case retrieve
    }
    
    /// Storing a list of messages allows us to test order that the operations were performed.
    /// This is impossible to do with two sepearate properties, as we cannot tell the order that
    /// they were called in.
    private(set) var recievedMessages = [RecievedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        recievedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feed: [LocalFeedImage], at date: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        recievedMessages.append(.insert(feed: feed, timestamp: date))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        recievedMessages.append(.retrieve)
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrievalCompletions[index](.success(.none))
    }
    
    func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrievalCompletions[index](.success(.init(feed: feed, timestamp: timestamp)))
    }
}

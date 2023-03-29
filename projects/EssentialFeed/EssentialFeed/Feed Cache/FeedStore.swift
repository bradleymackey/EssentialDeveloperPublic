//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 30/04/2022.
//

import Foundation


public enum CachedFeed {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalResult) -> Void
    
    typealias RetrievalResult = Result<CachedFeed, Error>
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible for dispatch to the appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible for dispatch to the appropriate threads, if needed.
    func insert(_ feed: [LocalFeedImage], at date: Date, completion: @escaping InsertionCompletion)
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible for dispatch to the appropriate threads, if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}


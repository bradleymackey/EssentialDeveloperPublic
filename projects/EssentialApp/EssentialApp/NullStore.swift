//
//  NullStore.swift
//  EssentialApp
//
//  Created by Bradley Mackey on 27/03/2023.
//

import Foundation
import EssentialFeed

class NullStore: FeedStore, FeedImageDataStore {
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completion(.success(()))
    }
    
    func insert(_ feed: [LocalFeedImage], at date: Date, completion: @escaping InsertionCompletion) {
        completion(.success(()))
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.success(nil))
    }
    
    func insert(_ data: Data, for url: URL) throws { }
    
    func retrieve(dataForURL url: URL) throws -> Data? { nil }
}


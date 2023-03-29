//
//  NullStore.swift
//  EssentialApp
//
//  Created by Bradley Mackey on 27/03/2023.
//

import Foundation
import EssentialFeed

class NullStore: FeedStore, FeedImageDataStore {
    func deleteCachedFeed() throws { }
    
    func insert(_ feed: [LocalFeedImage], at date: Date) throws { }
    
    func retrieve() throws -> CachedFeed? { nil }
    
    func insert(_ data: Data, for url: URL) throws { }
    
    func retrieve(dataForURL url: URL) throws -> Data? { nil }
}

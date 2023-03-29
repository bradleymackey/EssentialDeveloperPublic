//
//  CoreDataFeedStore+FeedStore.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 05/03/2023.
//

import CoreData

extension CoreDataFeedStore: FeedStore {
    public func retrieve() throws -> CachedFeed? {
        try performSync { context in
            Result {
                try ManagedCache.find(in: context).map {
                    CachedFeed(feed: $0.localFeed, timestamp: $0.timestamp)
                }
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], at date: Date) throws {
        try performSync { context in
            Result {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = date
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
                
                try context.save()
            } afterFailure: {
                context.rollback()
            }
        }
    }
    
    public func deleteCachedFeed() throws {
        try performSync { context in
            Result {
                try ManagedCache.deleteCache(in: context)
            } afterFailure: {
                context.rollback()
            }
        }
    }
}

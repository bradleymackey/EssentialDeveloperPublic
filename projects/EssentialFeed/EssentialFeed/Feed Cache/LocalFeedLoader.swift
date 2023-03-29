//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 30/04/2022.
//

import Foundation

// Frameworks don't make decisons, they just obey commands.
//
// The business logic (this LocalFeedLoader) is the 'what'.
// The frameworks are the 'how'.
//
// This is why we abstract the `FeedStore`, which is just an abstraction that will probably
// be a shim to a framework that supplies the storing logic, and it can easily be swapped out to
// a spy for testing.
//
// We don't want to test the framework, we just want to test the business logic!

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader: FeedCache {
    public typealias SaveResult = FeedCache.SaveResult
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        completion(SaveResult {
            try store.deleteCachedFeed()
            try store.insert(feed.toLocal(), at: currentDate())
        })
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = Swift.Result<[FeedImage], Error>
    public func load(completion: @escaping (LoadResult) -> Void) {
        completion(LoadResult {
            guard let cache = try store.retrieve() else {
                return []
            }
            guard FeedCachePolicy.validate(cache.timestamp, against: currentDate()) else {
                return []
            }
            return cache.feed.toModels()
        })
    }
}

extension LocalFeedLoader {
    public typealias ValidationResult = Result<Void, Error>
    
    private struct InvalidCacheError: Error {}
    
    public func validateCache(completion: @escaping (ValidationResult) -> Void) {
        completion(ValidationResult {
            do {
                if let cache = try store.retrieve(), !FeedCachePolicy.validate(cache.timestamp, against: currentDate()) {
                    throw InvalidCacheError()
                }
            } catch {
                try store.deleteCachedFeed()
            }
        })
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

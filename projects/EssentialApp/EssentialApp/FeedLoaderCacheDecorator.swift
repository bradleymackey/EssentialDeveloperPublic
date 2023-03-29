//
//  FeedLoaderCacheDecorator.swift
//  EssentialApp
//
//  Created by Bradley Mackey on 07/03/2023.
//

import Foundation
import EssentialFeed

@available(*, deprecated, message: "Use Combine for a universal abstraction")
public final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: any FeedLoader
    private let cache: any FeedCache
    
    public init(decoratee: any FeedLoader, cache: any FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        decoratee.load { [weak self] result in
            if case .success(let feed) = result {
                self?.cache.saveIgnoringResult(feed)
            }
            completion(result)
        }
    }
}

extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed) { _ in }
    }
}

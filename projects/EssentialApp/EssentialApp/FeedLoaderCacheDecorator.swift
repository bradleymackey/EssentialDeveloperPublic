//
//  FeedLoaderCacheDecorator.swift
//  EssentialApp
//
//  Created by Bradley Mackey on 07/03/2023.
//

import Foundation
import EssentialFeed

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
                self?.cache.save(feed) { _ in }
            }
            completion(result)
        }
    }
}

//
//  FeedLoaderStub.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 07/03/2023.
//

import Foundation
import EssentialFeed

/// A stub just returns a pre-specified value.
///
/// Stubs are much simpler than mocks or spys, but much more flexible, making them an easy
/// choice when we need to make some up-front decisions.
class FeedLoaderStub: FeedLoader {
    private let result: FeedLoader.Result
    
    init(result: FeedLoader.Result) {
        self.result = result
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completion(result)
    }
}

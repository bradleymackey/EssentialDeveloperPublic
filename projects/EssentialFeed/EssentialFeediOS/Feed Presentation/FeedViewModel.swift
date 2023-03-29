//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 17/02/2023.
//

import Foundation
import EssentialFeed

/// ViewModel can be stateful or stateless.
/// Stateful holds state (e.g. a boolean for the loading state), stateless would just pass the
/// loading state in a closure for example.
final class FeedViewModel {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.onLoadingStateChange?(false)
        }
    }
}

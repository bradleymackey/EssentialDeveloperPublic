//
//  FeedLoaderPresentationAdapter.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 21/02/2023.
//

import Combine
import Foundation
import EssentialFeed
import EssentialFeediOS

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    private let feedLoader: () -> AnyPublisher<[FeedImage], Error>
    private var cancellable: AnyCancellable?
    /// This is only optional to break a circular dependency.
    /// It's fine though, because this is at the composition layer.
    /// We're not leaking this composition detail into the adapters.
    ///
    /// (Constructor injection should be preferred whereever possible though!)
    var presenter: LoadResourcePresenter<[FeedImage], FeedViewAdapter>?
    
    init(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>) {
        self.feedLoader = feedLoader
    }
    
    func didRequestFeedRefresh() {
        presenter?.didStartLoading()
        cancellable = feedLoader().sink { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self?.presenter?.didFinishLoading(with: error)
            }
        } receiveValue: { [weak self] feed in
            self?.presenter?.didFinishLoading(with: feed)
        }
    }
}

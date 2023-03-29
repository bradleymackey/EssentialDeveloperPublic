//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 18/02/2023.
//

import EssentialFeed

/// - Note: this is a ViewModel used in MVP, so it should have no state.
/// It is used to send state updates via the abstraction for the view, `FeedLoadingView`.
/// It's also called "View Data", just basic data for display.
struct FeedLoadingViewModel {
    let isLoading: Bool
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

/// Note: ViewModel used by MVP, so no state.
struct FeedViewModel {
    let feed: [FeedImage]
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

final class FeedPresenter {
    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    
    func didStartLoadingFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView?.display(FeedViewModel(feed: feed))
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
}

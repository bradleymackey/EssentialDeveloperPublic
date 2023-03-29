//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 17/02/2023.
//

import Foundation
import EssentialFeed

/// This is public, because this is how other modules should create a `FeedViewController`.
/// Because some of `FeedViewController`'s dependencies are internal, we need to use this helper to create the
/// dependencies, then pass them to FeedViewController.
public enum FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = { [weak feedController] feed in
            // Adapter pattern to adapt [FeedImage] -> [FeedImageCellController]
            feedController?.tableModel = feed.map { model in
                FeedImageCellController(model: model, imageLoader: imageLoader)
            }
        }
        return feedController
    }
}


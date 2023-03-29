//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 17/02/2023.
//

import Foundation
import EssentialFeed
import EssentialFeediOS
import UIKit

// It's up to the compositon layer to:
//  - Organise, compose, and inject the instances correctly.
//  - Including memory management and object lifetime.
//  - That's why it's so important to have a compositon layer.
//  - Responsible for creating and instantiating objects.

/// This is public, because this is how other modules should create a `FeedViewController`.
/// Because some of `FeedViewController`'s dependencies are internal, we need to use this helper to create the
/// dependencies, then pass them to FeedViewController.
public enum FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader))
        
        let feedController = FeedViewController.makeWith(delegate: presentationAdapter, title: FeedPresenter.title)
        
        let presenter = FeedPresenter(
            feedView: FeedViewAdapter(
                controller: feedController,
                imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader)
            ),
            loadingView: WeakRefVirtualProxy(feedController),
            errorView: WeakRefVirtualProxy(feedController)
        )
        presentationAdapter.presenter = presenter
        return feedController
    }
}

private extension FeedViewController {
    static func makeWith(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.delegate = delegate
        feedController.title = title
        return feedController
    }
}


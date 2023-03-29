//
//  CommentsUIComposer.swift
//  EssentialApp
//
//  Created by Bradley Mackey on 26/03/2023.
//

import Foundation
import EssentialFeed
import EssentialFeediOS
import UIKit
import Combine

// It's up to the compositon layer to:
//  - Organise, compose, and inject the instances correctly.
//  - Including memory management and object lifetime.
//  - That's why it's so important to have a compositon layer.
//  - Responsible for creating and instantiating objects.

/// This is public, because this is how other modules should create a `FeedViewController`.
/// Because some of `FeedViewController`'s dependencies are internal, we need to use this helper to create the
/// dependencies, then pass them to FeedViewController.
public enum CommentsUIComposer {
    private typealias CommentsPresentationAdapter = LoadResourcePresentationAdapter<[ImageComment], CommentsViewAdapter>
    
    public static func commentsComposedWith(commentsLoader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ListViewController {
        let presentationAdapter = CommentsPresentationAdapter(loader: { commentsLoader().dispatchOnMainQueue() })
        
        let controller = makeCommentsController(title: ImageCommentsPresenter.title)
        controller.onRefresh = presentationAdapter.loadResource
        
        let presenter = LoadResourcePresenter(
            resourceView: CommentsViewAdapter(controller: controller),
            loadingView: WeakRefVirtualProxy(controller),
            errorView: WeakRefVirtualProxy(controller),
            mapper: { ImageCommentsPresenter.map($0) }
        )
        presentationAdapter.presenter = presenter
        return controller
    }
    
    private static func makeCommentsController(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.title = title
        return controller
    }
}

final class CommentsViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    
    init(controller: ListViewController) {
        self.controller = controller
    }
    
    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.display(viewModel.comments.map { viewModel in
            CellController(id: viewModel, ImageCommentCellController(model: viewModel))
        })
    }
}

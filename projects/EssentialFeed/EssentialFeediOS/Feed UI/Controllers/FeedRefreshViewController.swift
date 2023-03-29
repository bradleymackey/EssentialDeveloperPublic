//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit

/// Note: this is a "View Controller" because it's controlling a view.
/// It doesn't necessarily have to be a view that's the entire viewport!
/// Simple observation, but powerful!
/// As long as the main view can communicate with this in a meaningful way, this is a perfectly valid object!
///
/// This view controller just binds the view with the view model, it's the "Binding" layer between ViewModel and View.
/// All state management lives in the FeedViewModel, it's a platform-agnostic resuable component.
final class FeedRefreshViewController: NSObject {
    private(set) lazy var view: UIRefreshControl = binded(UIRefreshControl())
    
    private let viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onChange = { [weak self] viewModel in
            if viewModel.isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}

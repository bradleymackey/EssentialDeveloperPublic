//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    @IBOutlet private var view: UIRefreshControl?
    
    var delegate: FeedRefreshViewControllerDelegate?
    
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view?.beginRefreshing()
        } else {
            view?.endRefreshing()
        }
    }
    
    @IBAction func refresh() {
        delegate?.didRequestFeedRefresh()
    }
}

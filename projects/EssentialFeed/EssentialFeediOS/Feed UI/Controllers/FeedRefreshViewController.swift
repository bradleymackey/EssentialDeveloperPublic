//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit
import EssentialFeed

/// Note: this is a "View Controller" because it's controlling a view.
/// It doesn't necessarily have to be a view that's the entire viewport!
/// Simple observation, but powerful!
/// As long as the main view can communicate with this in a meaningful way, this is a perfectly valid object!
final class FeedRefreshViewController: NSObject {
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var onRefresh: (([FeedImage]) -> Void)?
    
    @objc func refresh() {
        view.beginRefreshing()
        feedLoader.load { [weak self] result in
            defer {
                self?.view.endRefreshing()
            }
            
            if let feed = try? result.get() {
                self?.onRefresh?(feed)
            }
        }
    }
}

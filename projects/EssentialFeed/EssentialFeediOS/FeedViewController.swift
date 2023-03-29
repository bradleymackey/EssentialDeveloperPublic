//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 07/08/2022.
//

import UIKit
import EssentialFeed

final public class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    // We can use a convenience init since we don't need any custom initialization.
    // This way, we don't need to implement the view controller's required initializers!
    public convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

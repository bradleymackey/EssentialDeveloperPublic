//
//  FeedViewController+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit
import EssentialFeediOS

extension FeedViewController {
    /// The fact that the user uses a `refreshControl` is an implementation detail.
    /// We can hide it from the tests using a method that just abstracts over some
    /// feed reload action, which can easily change/update later.
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at row: Int) -> FeedImageCell {
        guard let cell = feedImageView(at: row) as? FeedImageCell else {
            fatalError("Invalid index path!")
        }
        let dele = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        dele?.tableView?(tableView, willDisplay: cell, forRowAt: index)
        return cell
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell? {
        guard let cell = feedImageView(at: row) as? FeedImageCell else {
            fatalError("Invalid index path!")
        }
        let dele = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        dele?.tableView?(tableView, didEndDisplaying: cell, forRowAt: index)
        return cell
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    private var feedImagesSection: Int {
        0
    }
    
    var errorMessage: String? {
        errorView.message
    }
}

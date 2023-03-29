//
//  ListViewController+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit
import EssentialFeediOS

extension ListViewController {
//    public override func loadViewIfNeeded() {
//        super.loadViewIfNeeded()
//
//        Not needed because we use willDisplay to render images
//        This is a technique to prevent images loading ahead of time because there's not enough space
//        tableView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
//    }
    
    /// The fact that the user uses a `refreshControl` is an implementation detail.
    /// We can hide it from the tests using a method that just abstracts over some
    /// feed reload action, which can easily change/update later.
    func simulateUserInitiatedReload() {
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
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        guard numberOfRenderedFeedImageViews() > row else {
            return nil
        }
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    private var feedImagesSection: Int {
        0
    }
    
    func renderedFeedImageData(at index: Int) -> Data? {
        simulateFeedImageViewVisible(at: index).renderedImage
    }
    
    var errorMessage: String? {
        errorView.message
    }
    
    func simulateErrorViewTap() {
        errorView.simulateTap()
    }
}

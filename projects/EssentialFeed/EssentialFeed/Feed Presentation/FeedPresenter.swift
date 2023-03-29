//
//  FeedPresenter.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 01/03/2023.
//

public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

public final class FeedPresenter {
    public static var title: String {
        NSLocalizedString("FEED_VIEW_TITLE", tableName: "Feed", bundle: Bundle(for: FeedPresenter.self), comment: "Title for the feed view")
    }
    
    public static func map(_ feed: [FeedImage]) -> FeedViewModel {
        FeedViewModel(feed: feed)
    }
}


//
//  FeedPresenter.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 01/03/2023.
//

public final class FeedPresenter {
    public static var title: String {
        NSLocalizedString("FEED_VIEW_TITLE", tableName: "Feed", bundle: Bundle(for: FeedPresenter.self), comment: "Title for the feed view")
    }
}


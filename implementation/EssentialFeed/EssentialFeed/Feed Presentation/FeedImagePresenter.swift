//
//  FeedImagePresenter.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 01/03/2023.
//

import Foundation

public final class FeedImagePresenter {
    public static func map(_ image: FeedImage) -> FeedImageViewModel {
        FeedImageViewModel(
            description: image.description,
            location: image.location
        )
    }
}

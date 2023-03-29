//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 07/05/2022.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    FeedImage(
        id: UUID(),
        description: "any description",
        location: "any location",
        url: anyURL()
    )
}

func uniqueFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let local = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (items, local)
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        // easy to change without breaking clients or test methods
        //
        // strict with access control because we do not want clients depending on the exact value
        7
    }
}

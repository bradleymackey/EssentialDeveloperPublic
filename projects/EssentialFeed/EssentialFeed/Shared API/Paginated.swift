//
//  Paginated.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 26/03/2023.
//

import Foundation

// It's a choice depending on the team whether or not we want to couple this with Combine.
// Caio likes to only couple in the composition root, writing a helpful wrapper.
// This means we can just stick with Swift's first-class closure support.

public struct Paginated<Item> {
    public typealias LoadMoreCompletion = (Result<Self, Error>) -> Void
    
    public let items: [Item]
    /// A closure to fetch more items.
    ///
    /// This hides the implementation detail of how the paging actually occurs.
    public let loadMore: ((LoadMoreCompletion) -> Void)?
    
    public init(
        items: [Item],
        loadMore: ((LoadMoreCompletion) -> Void)? = nil
    ) {
        self.items = items
        self.loadMore = loadMore
    }
}


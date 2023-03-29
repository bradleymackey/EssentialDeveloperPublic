//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 12/04/2022.
//

import Foundation

public struct FeedItem {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
}

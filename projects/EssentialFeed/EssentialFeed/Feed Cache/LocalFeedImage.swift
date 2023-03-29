//
//  LocalFeedImage.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 30/04/2022.
//

import Foundation

/// A local representation of the feed item.
///
/// While it may look like we are duplicating code - we are not.
/// Local representations of feed items may need to store different information than the standard `FeedItem`.
/// For example, a timestamp when it was added to the database.
///
/// Data Transfer Object (DTO) -> this removes strong coupling between modules.
public struct LocalFeedImage: Equatable, Codable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}

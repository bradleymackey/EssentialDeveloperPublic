//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 12/04/2022.
//

import Foundation

public struct FeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    // Other modules may want to create this, so we need to create a public initializer.
    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}

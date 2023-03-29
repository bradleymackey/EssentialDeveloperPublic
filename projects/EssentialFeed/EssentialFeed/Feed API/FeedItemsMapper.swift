//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 14/04/2022.
//

import Foundation

// When we test this code, we don't import as 'testable', just the public interface.
// Therefore, we are only testing the public interface.
// This allows us to refactor any internal structures without breaking any tests.

public final class FeedItemsMapper {
    private struct Root: Decodable {
        private let items: [RemoteFeedItem]
        
        private struct RemoteFeedItem: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
        }
        
        var images: [FeedImage] {
            items.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        // We are decoding AND checking the status code here.
        // However, this is not a violation of the single responsibility principle because
        // this functionality is based on the API contract, which includes the status code.
        //
        // If the status code rule changes, it's a breaking change in the API contract and
        // we need to update the component to reflect the changes.
        //
        // If, for example, there was a 401 repsonse this component would simply reject the response (rather than handling reauthentication).
        // Another component would handle the authentication so that this component could
        // then fetch valid data from a 200 response.
        guard response.isOK else {
            throw Error.invalidData
        }
        
        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.images
        } catch {
            throw Error.invalidData
        }
    }
}


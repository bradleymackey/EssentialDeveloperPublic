//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 12/04/2022.
//

import Foundation

// Inject the HTTP client dependency to ensure there is not a strong coupling

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class FeedItemsMapper {
    private struct Root: Decodable {
        var items: [Item]
    }
    
    // We create a 'clone' of the FeedItem, that just handles the decoding for the RemoteFeedLoader.
    // This is because we don't want to tie the generic model 'FeedItem' to specific coding keys, which are context dependent on where the FeedItem is actually coming from.
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let imageURL: URL
        
        var item: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case description
            case location
            case imageURL = "image"
        }
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
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
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map(\.item)
    }
}


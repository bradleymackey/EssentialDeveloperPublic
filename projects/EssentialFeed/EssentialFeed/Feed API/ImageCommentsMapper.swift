//
//  ImageCommentsMapper.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 25/03/2023.
//

import Foundation

internal final class ImageCommentsMapper {
    private struct Root: Decodable {
        var items: [RemoteFeedItem]
    }
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
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
        guard isOK(response) else {
            throw RemoteImageCommentsLoader.Error.invalidData
        }
        
        do {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.items
        } catch {
            throw RemoteImageCommentsLoader.Error.invalidData
        }
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200 ..< 300).contains(response.statusCode)
    }
}

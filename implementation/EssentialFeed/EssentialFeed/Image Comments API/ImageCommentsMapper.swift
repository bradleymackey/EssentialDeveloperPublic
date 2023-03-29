//
//  ImageCommentsMapper.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 25/03/2023.
//

import Foundation

public final class ImageCommentsMapper {
    private struct Root: Decodable {
        private let items: [Comment]
        
        private struct Comment: Decodable {
            let id: UUID
            let message: String
            let created_at: Date
            let author: Author
        }
        
        private struct Author: Decodable {
            let username: String
        }
        
        var comments: [ImageComment] {
            items.map { ImageComment(id: $0.id, message: $0.message, createdAt: $0.created_at, username: $0.author.username) }
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [ImageComment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard isOK(response) else {
            throw Error.invalidData
        }
        
        do {
            let root = try decoder.decode(Root.self, from: data)
            return root.comments
        } catch {
            throw Error.invalidData
        }
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200 ..< 300).contains(response.statusCode)
    }
}

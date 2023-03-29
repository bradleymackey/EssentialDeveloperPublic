//
//  ImageCommentsMapperTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 25/03/2023.
//

import XCTest
@testable import EssentialFeed

// We test drive the implementation before implementing anything concrete.

class ImageCommentsMapperTests: XCTestCase {
    func test_map_throwsErrorOnNon2xxHTTPResponse() throws {
        let json = makeItemsJSON([])
        
        try invalidStatusCodes.forEach { code in
            XCTAssertThrowsError(try ImageCommentsMapper.map(json, from: HTTPURLResponse(statusCode: code)))
        }
    }
    
    func test_map_throwsErrorOn2xxHTTPResponseWithInvalidJSON() throws {
        let invalidJSON = Data("invalid json".utf8)

        try validStatusCodes.forEach { code in
            XCTAssertThrowsError(try ImageCommentsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: code)))
        }
    }
    
    func test_map_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList() throws {
        let emptyListJSON = makeItemsJSON([])
        
        try validStatusCodes.forEach { code in
            let result = try ImageCommentsMapper.map(emptyListJSON, from: HTTPURLResponse(statusCode: code))
            XCTAssertEqual(result, [])
        }
    }
    
    func test_map_deliversItemsOn2xxHTTPResponseWithJSONItems() throws {
        let item1 = makeItem(
            id: UUID(),
            message: "a message",
            createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
            username: "a username"
        )
        let item2 = makeItem(
            id: UUID(),
            message: "another message",
            createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
            username: "another username"
        )
        
        let items = [item1.json, item2.json]
        let json = makeItemsJSON(items)
        
        try validStatusCodes.forEach { code in
            let result = try ImageCommentsMapper.map(json, from: HTTPURLResponse(statusCode: code))
            XCTAssertEqual(result, [item1.model, item2.model])
        }
    }
}

// MARK: - Helpers

extension ImageCommentsMapperTests {
    
    private func makeItem(id: UUID, message: String, createdAt: (date: Date, iso8601String: String), username: String) -> (model: ImageComment, json: [String: Any]) {
        let item = ImageComment(
            id: id,
            message: message,
            createdAt: createdAt.date,
            username: username
        )
        let json: [String: Any] = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.iso8601String,
            "author": [
                "username": username,
            ],
        ]
        return (item, json)
    }
    
    private var validStatusCodes: [Int] {
        [200, 201, 202, 204, 250, 299]
    }
    
    private var invalidStatusCodes: [Int] {
        [100, 150, 199, 300, 400, 500, 599]
    }
}

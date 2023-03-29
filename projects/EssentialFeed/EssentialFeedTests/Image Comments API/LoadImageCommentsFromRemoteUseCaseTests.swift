//
//  LoadImageCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 25/03/2023.
//

import XCTest
@testable import EssentialFeed

// We test drive the implementation before implementing anything concrete.

class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
    func test_load_deliversErrorOnNon2xxResponse() {
        let (sut, client) = makeSUT()
        
        invalidStatusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let json = makeCommentsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn2xxResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        validStatusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let invalidJSON = Data("invalid json".utf8)
                client.complete(withStatusCode: code, data: invalidJSON, at: index)
            }
        }
    }
    
    func test_load_deliversNoItemsOn2xxResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        validStatusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .success([])) {
                let emptyListJSON = makeCommentsJSON([])
                client.complete(withStatusCode: code, data: emptyListJSON, at: index)
            }
        }
    }
    
    func test_load_deliversItemsOn2xxHTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
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
        
        let items = [item1, item2]
        
        validStatusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .success(items.map(\.model))) {
                let json = makeCommentsJSON(items.map(\.json))
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
}

// MARK: - Helpers

extension LoadImageCommentsFromRemoteUseCaseTests {
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteImageCommentsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func failure(_ error: RemoteImageCommentsLoader.Error) -> RemoteImageCommentsLoader.Result {
        .failure(error)
    }
    
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
    
    private func makeCommentsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(_ sut: RemoteImageCommentsLoader, toCompleteWith expectedResult: RemoteImageCommentsLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load to complete")
        sut.load { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(recievedItems), .success(expectedItems)):
                XCTAssertEqual(recievedItems, expectedItems, file: file, line: line)
            case let (.failure(recievedError as RemoteImageCommentsLoader.Error), .failure(expectedError as RemoteImageCommentsLoader.Error)):
                XCTAssertEqual(recievedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(recievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private var validStatusCodes: [Int] {
        [200, 201, 202, 204, 250, 299]
    }
    
    private var invalidStatusCodes: [Int] {
        [100, 150, 199, 300, 400, 500, 599]
    }
}

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
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://someurl.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromURL() {
        let url = URL(string: "https://someurl.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    // This error is not refactored to show the process of the design.
    func test_load_deliversErrorOnClientError() {
        // ARRANGE
        let (sut, client) = makeSUT()
        
        // ACT
        // (client and completions belongs to the 'act')
        // (part of the tests)
        var capturedResults = [RemoteImageCommentsLoader.Result]()
        sut.load(completion: { capturedResults.append($0) })
        
        // Complete after the load starts, making this code easy to
        // read (load starts, then the HTTPClient completes after that)
        //
        // Structuring the test this way is true to how the code runs,
        // from top to bottom - it doesn't require us to setup the error
        // before we call `load`, which could get very confusing.
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        // ASSERT
        XCTAssertEqual(capturedResults.count, 1)
        XCTAssertThrowsError(try capturedResults[0].get(), "Error state") { error in
            XCTAssertEqual(error as! RemoteImageCommentsLoader.Error, .connectivity)
        }
    }
    
    func test_load_deliversErrorOnNon2xxResponse() {
        let (sut, client) = makeSUT()
        
        invalidStatusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let json = makeFeedJSON([])
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
                let emptyListJSON = makeFeedJSON([])
                client.complete(withStatusCode: code, data: emptyListJSON, at: index)
            }
        }
    }
    
    func test_load_deliversItemsOn2xxHTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeFeedImage(
            id: UUID(),
            url: URL(string: "https://a-url.com")!
        )
        let item2 = makeFeedImage(
            id: UUID(),
            description: "a description",
            location: "a location",
            url: URL(string: "https://a-url-2.com")!
        )
        
        let items = [item1, item2]
        
        
        validStatusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .success(items.map(\.model))) {
                let json = makeFeedJSON(items.map(\.json))
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    // This is self-documenting for the completion block "we are thinking about this behaviour"
    // Need to think about this behaviour and how to handle it.
    func test_load_doesNotDeliverResultsAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteImageCommentsLoader? = RemoteImageCommentsLoader(url: url, client: client)
        
        var capturedResults = [RemoteImageCommentsLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeFeedJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
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
    
    private func failure(_ error: RemoteImageCommentsLoader.Error) -> FeedLoader.Result {
        .failure(error)
    }
    
    private func makeFeedImage(id: UUID, description: String? = nil, location: String? = nil, url: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(
            id: id,
            description: description,
            location: location,
            url: url
        )
        let itemJSON = [
            "id": item.id.uuidString,
            "image": item.url.absoluteString,
            "description": item.description,
            "location": item.location,
        ].compactMapValues { $0 }
        return (item, itemJSON)
    }
    
    private func makeFeedJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(_ sut: RemoteImageCommentsLoader, toCompleteWith expectedResult: FeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
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

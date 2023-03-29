//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 12/04/2022.
//

import XCTest
@testable import EssentialFeed

// We test drive the implementation before implementing anything concrete.

class RemoteFeedLoaderTests: XCTestCase {
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(url: url, client: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromURL() {
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        // ARRANGE
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        // ACT
        // (client and completions belongs to the 'act')
        // (part of the tests)
        var capturedResults = [RemoteFeedLoader.Result]()
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
        XCTAssertEqual(capturedResults, [.failure(.connectivity)])
    }
    
    func test_load_deliversErrorOnNon200Response() {
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        // Having a range of samples is usually good enough.
        // This tests a variety of condiditions without going overboard.
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200ResponseWithInvalidJSON() {
        // ARRANGE
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        // ACT, ASSERT
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200ResponseWithEmptyJSONList() {
        // ARRANGE
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        // ACT, ASSERT
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        // ARRANGE
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "https://a-url.com")!
        )
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://a-url-2.com")!
        )
        
        let items = [item1, item2]
        
        expect(sut, toCompleteWith: .success(items.map(\.model))) {
            let json = makeItemsJSON(items.map(\.json))
            client.complete(withStatusCode: 200, data: json)
        }
    }

}


// MARK: - Helpers

extension RemoteFeedLoaderTests {
    
    /// Move the test logic to a test type - the client spy.
    /// this mimicks the behaviour of the parent without having to actually make
    /// a network request.
    ///
    /// The `get` method will add a closure waiting to be completed.
    /// Then, some time later, you can `complete` the closure and the
    /// closure will be called with the provided update.
    ///
    /// We want to avoid 'stubbing' in this spy, to keep it's intent clear.
    /// For example, adding an `error` optional property that would always return an error within `get` would be stubbing.
    /// It also makes the flow of our program confusing because we would have to set the stubbed error before `get` is called, breaking the natural flow of our program and confusing us as developers.
    /// We only want the spy to capture values, then we can test them after.
    /// Capturing the values is more simple.
    class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        // ...get appends to the messages with a closure that
        // is waiting to be completed...
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        // ...complete methods will complete the response by calling
        // the specified closure
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
        }
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        let itemJSON = [
            "id": item.id.uuidString,
            "image": item.imageURL.absoluteString,
            "description": item.description,
            "location": item.location,
        ].compactMapValues { $0 }
        return (item, itemJSON)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
}

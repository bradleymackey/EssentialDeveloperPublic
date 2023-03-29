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
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load(completion: { capturedErrors.append($0) })
        
        // Complete after the load starts, making this code easy to
        // read (load starts, then the HTTPClient completes after that)
        //
        // Structuring the test this way is true to how the code runs,
        // from top to bottom - it doesn't require us to setup the error
        // before we call `load`, which could get very confusing.
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        // ASSERT
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200Response() {
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        // Having a range of samples is usually good enough.
        // This tests a variety of condiditions without going overboard.
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load(completion: { capturedErrors.append($0) })
            client.complete(withStatusCode: code, at: index)
            XCTAssertEqual(capturedErrors, [.invalidData])
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
        
        func complete(withStatusCode statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(response))
        }
    }
    
}

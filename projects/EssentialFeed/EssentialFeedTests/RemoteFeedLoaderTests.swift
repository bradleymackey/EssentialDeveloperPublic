//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 12/04/2022.
//

import XCTest

// We test drive the implementation before implementing anything concrete.

class RemoteFeedLoader {
    // Inject the HTTP client dependency to ensure there is not a strong coupling
    let client: HTTPClient
    let url: URL
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    func load() {
        client.get(from: url)
    }
}

// There's no reason that HTTPClient needs to be a singleton.
// We can extend URLSession
protocol HTTPClient {
    func get(from url: URL)
}

/// Move the test logic to a test type - the client spy.
/// this mimicks the behaviour of the parent without having to actually make
/// a network request.
class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        requestedURL = url
    }
}

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
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://someurl.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }

}

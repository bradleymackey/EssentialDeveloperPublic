//
//  FeedAcceptanceTests.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 14/03/2023.
//

import XCTest
import EssentialFeed
import EssentialFeediOS
@testable import EssentialApp

// Integration tests that would otherwise require UI tests.
// Implemented this way, they are much faster to run.

final class FeedAcceptanceTests: XCTestCase {
   
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() throws {
        let feed = try launch(httpClient: .online(stub: response), store: .empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 4)
        for i in 0..<4 {
            XCTAssertEqual(feed.renderedFeedImageData(at: i), makeImageData())
        }
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() throws {
        let sharedStore = InMemoryFeedStore.empty
        let onlineFeed = try launch(httpClient: .online(stub: response), store: sharedStore)
        for i in 0..<4 {
            onlineFeed.simulateFeedImageViewVisible(at: i)
        }
        
        let offlineFeed = try launch(httpClient: .offline, store: sharedStore)
        
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 4)
        for i in 0..<4 {
            XCTAssertEqual(offlineFeed.renderedFeedImageData(at: i), makeImageData())
        }
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() throws {
        let feed = try launch(httpClient: .offline, store: .empty)
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 0)
    }
    
    func test_onEnteringBackground_deletesExpiredFeedCache() throws {
        let store = InMemoryFeedStore.withExpiredFeedCache
        
        try enterBackground(with: store)
        
        XCTAssertNil(store.feedCache)
    }
    
    func test_onEnteringBackground_keepsNonExpiredFeedCache() throws {
        let store = InMemoryFeedStore.withNonExpiredFeedCache
        
        try enterBackground(with: store)
        
        XCTAssertNotNil(store.feedCache)
    }
}

// MARK: - Helpers

extension FeedAcceptanceTests {
    
    private func launch(
        httpClient: HTTPClientStub = .offline,
        store: InMemoryFeedStore = .empty
    ) throws -> ListViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        
        let nav = sut.window?.rootViewController as? UINavigationController
        let feed = try XCTUnwrap(nav?.topViewController as? ListViewController)
        return feed
    }
    
    private func enterBackground(with store: InMemoryFeedStore) throws {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first)
        sut.sceneWillResignActive(scene)
    }
    
    private class HTTPClientStub: HTTPClient {
        private class Task: HTTPClientTask {
            func cancel() {}
        }
        
        private let stub: (URL) -> HTTPClient.Result
        
        init(stub: @escaping (URL) -> HTTPClient.Result) {
            self.stub = stub
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            completion(stub(url))
            return Task()
        }
        
        struct OfflineError: Error {}
        
        static var offline: HTTPClientStub {
            HTTPClientStub(stub: { _ in .failure(OfflineError())})
        }
        
        static func online(stub: @escaping (URL) -> ((Data, HTTPURLResponse))) -> HTTPClientStub {
            HTTPClientStub(stub: { url in .success(stub(url))})
        }
    }
    
    private class InMemoryFeedStore: FeedStore, FeedImageDataStore {
        private(set) var feedCache: CachedFeed?
        private var feedImageDataCache: [URL: Data] = [:]
        
        init(feedCache: CachedFeed? = nil) {
            self.feedCache = feedCache
        }
        
        func deleteCachedFeed(completion: @escaping FeedStore.DeletionCompletion) {
            feedCache = nil
            completion(.success(()))
        }
        
        func insert(_ feed: [LocalFeedImage], at timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
            feedCache = CachedFeed(feed: feed, timestamp: timestamp)
            completion(.success(()))
        }
        
        func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
            completion(.success(feedCache))
        }
        
        func insert(_ data: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertionResult) -> Void) {
            feedImageDataCache[url] = data
            completion(.success(()))
        }
        
        func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
            completion(.success(feedImageDataCache[url]))
        }
        
        static var empty: InMemoryFeedStore {
            InMemoryFeedStore()
        }
        
        static var withExpiredFeedCache: InMemoryFeedStore {
            InMemoryFeedStore(feedCache: CachedFeed(feed: [], timestamp: .distantPast))
        }
        
        static var withNonExpiredFeedCache: InMemoryFeedStore {
            InMemoryFeedStore(feedCache: CachedFeed(feed: [], timestamp: .distantFuture))
        }
    }
    
    private func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.path {
        case "/image-1", "/image-2", "/image-3", "/image-4":
            return makeImageData()
            
        case "/essential-feed/v1/feed":
            return makeFeedData()
            
        default:
            return Data()
        }
    }
    
    private func makeImageData() -> Data {
        UIImage.make(withColor: .red).pngData()!
    }
    
    private func makeFeedData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-1"],
            ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-2"],
            ["id": "43502EAB-F2BA-4327-B714-5853A8F356D1", "image": "http://feed.com/image-3"],
            ["id": "14E89DAE-8B2B-48B8-8FB1-28C816414BB9", "image": "http://feed.com/image-4"],
        ]])
    }
    
}

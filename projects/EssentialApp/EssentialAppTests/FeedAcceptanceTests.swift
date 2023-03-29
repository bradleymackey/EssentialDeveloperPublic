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
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertTrue(feed.canLoadMoreFeed)
        
        feed.simulateLoadMoreFeedAction()
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 4)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertEqual(feed.renderedFeedImageData(at: 3), makeImageData3())
        XCTAssertTrue(feed.canLoadMoreFeed)
        
        feed.simulateLoadMoreFeedAction()
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 4)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertEqual(feed.renderedFeedImageData(at: 3), makeImageData3())
        XCTAssertFalse(feed.canLoadMoreFeed)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() throws {
        let sharedStore = InMemoryFeedStore.empty
        
        let onlineFeed = try launch(httpClient: .online(stub: response), store: sharedStore)
        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        onlineFeed.simulateFeedImageViewVisible(at: 2)
        onlineFeed.simulateLoadMoreFeedAction()
        onlineFeed.simulateFeedImageViewVisible(at: 3)
        
        let offlineFeed = try launch(httpClient: .offline, store: sharedStore)
        
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 4)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 3), makeImageData3())
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
    
    func test_onFeedImageSelection_displaysComments() throws {
        let comments = try showCommentsForFirstImage()
        
        XCTAssertEqual(comments.numberOfRenderedComments(), 1)
        XCTAssertEqual(comments.commentMessage(at: 0), makeCommentMessage())
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
    
    private func showCommentsForFirstImage() throws -> ListViewController {
        let feed = try launch(httpClient: .online(stub: response), store: .empty)
        
        feed.simulateTapOnFeedImage(at: 0)
        // Because of the animation, we need to advance the RunLoop
        RunLoop.current.run(until: Date())
        
        let nav = feed.navigationController
        return nav?.topViewController as! ListViewController
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
        case "/image-0": return makeImageData0()
        case "/image-1": return makeImageData1()
        case "/image-2": return makeImageData2()
        case "/image-3": return makeImageData3()
            
        case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false:
            return makeFirstFeedPage()
            
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=43502EAB-F2BA-4327-B714-5853A8F356D1") == true:
            return makeSecondFeedPage()
            
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=FFBFFEFF-A4B7-FFFF-B374-51BBAC8DB086") == true:
            return makeLastEmptyFeedPageData()
            
        case "/essential-feed/v1/image/2AB2AE66-A4B7-4A16-B374-51BBAC8DB086/comments":
            return makeCommentsData()
            
        default:
            return Data()
        }
    }
    
    private func makeImageData0() -> Data {
        UIImage.make(withColor: .red).pngData()!
    }
    
    private func makeImageData1() -> Data {
        UIImage.make(withColor: .blue).pngData()!
    }
    
    private func makeImageData2() -> Data {
        UIImage.make(withColor: .green).pngData()!
    }
    
    private func makeImageData3() -> Data {
        UIImage.make(withColor: .systemPink).pngData()!
    }
    
    private func makeFirstFeedPage() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
            ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"],
            ["id": "43502EAB-F2BA-4327-B714-5853A8F356D1", "image": "http://feed.com/image-2"],
        ]])
    }
    
    private func makeSecondFeedPage() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "FFBFFEFF-A4B7-FFFF-B374-51BBAC8DB086", "image": "http://feed.com/image-3"],
        ]])
    }
    
    private func makeCommentsData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            [
                "id": UUID().uuidString,
                "message": makeCommentMessage(),
                "created_at": "2023-03-20T10:00:59+0000",
                "author": [
                    "username": "a username"
                ]
            ],
        ]])
    }
    
    private func makeLastEmptyFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": []])
    }
    
    private func makeCommentMessage() -> String {
        "a test message, hello!"
    }
}

//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Bradley Mackey on 15/04/2022.
//

import XCTest
import EssentialFeed

/// These are end-to-end tests that are actually hitting the test server to
/// get results.
/// They are much slower than the bare unit tests, so we place them in this
/// seperate test target, run only when needed to verify the API.
class EssentialFeedAPIEndToEndTests: XCTestCase {
    
    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        switch getFeedResult() {
        case let .success(items)?:
            XCTAssertEqual(items.count, 8, "Expected 8 items in test feed")
            
            // we could just verbosely write out each line of code for
            // each test item, which could make it faster to find each error,
            // but I will just leave it like this for now
            items.enumerated().forEach { (index, item) in
                XCTAssertEqual(item, expectedImage(at: index), "unexpected item values at index \(index)")
            }
        case let .failure(error)?:
            XCTFail("Expected successful feed result, got \(error) instead")
        default:
            XCTFail("Expected successful feed result, got no result instead")
        }
    }
    
    func test_endToEndTestServerGETFeedImageDataResult_matchesFixedTestAccountData() {
        switch getFeedImageDataResult() {
        case let .success(data)?:
            XCTAssertFalse(data.isEmpty, "Expected non-empty image data")
            
        case let .failure(error)?:
            XCTFail("Expected successful image data result, got \(error) instead")
            
        default:
            XCTFail("Expected successful image data result, got no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func getFeedResult(file: StaticString = #filePath, line: UInt = #line) -> FeedLoader.Result? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        // an ephemeral session will ensure there is no sharing of cache state.
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for load completion")
        var recivedResult: FeedLoader.Result?
        loader.load { result in
            recivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10.0)
        return recivedResult
    }
    
    private func getFeedImageDataResult(file: StaticString = #file, line: UInt = #line) -> FeedImageDataLoader.Result? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed/73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let loader = RemoteFeedImageDataLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for load completion")
        
        var receivedResult: FeedImageDataLoader.Result?
        _ = loader.loadImageData(from: testServerURL) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        
        return receivedResult
    }
    
    private func expectedImage(at index: Int) -> FeedImage {
        return FeedImage(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            url: imageURL(at: index))
    }
    
    private func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }
    
    private func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    private func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    private func imageURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index+1).com")!
    }
}

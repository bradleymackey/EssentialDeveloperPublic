//
//  FeedImageDataLoaderWithFallbackCompositeTests.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 06/03/2023.
//

import XCTest
import EssentialFeed
import EssentialApp

class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    
    func test_init_doesNotLoadImageData() {
        let (_, primaryLoader, fallbackLoader) = makeSUT()
        
        XCTAssertTrue(primaryLoader.requestedURLs.isEmpty, "Expected no URLs in primary loader")
        XCTAssertTrue(fallbackLoader.requestedURLs.isEmpty, "Expected no URLs in fallback loader")
    }
    
    func test_loadImageData_deliversPrimaryImageOnPrimarySuccess() {
        let primaryData = uniqueImageData()
        let (sut, primaryLoader, _) = makeSUT()
        
        expect(sut, url: anyURL(), toCompleteWith: .success(primaryData)) {
            primaryLoader.complete(with: primaryData)
        }
    }
    
    func test_loadImageData_cancelsPrimaryLoaderTask() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()
        
        XCTAssertEqual(primaryLoader.cancelledURLs, [url])
        XCTAssertEqual(fallbackLoader.cancelledURLs, [])
    }
    
    func test_loadImageData_deliversFallbackImageOnPrimaryFailure() {
        let fallbackData = uniqueImageData()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        expect(sut, url: anyURL(), toCompleteWith: .success(fallbackData)) {
            primaryLoader.complete(with: anyNSError())
            fallbackLoader.complete(with: fallbackData)
        }
    }
    
    func test_loadImageData_cancelsFallbackLoaderTaskWhenUsingFallbackLoader() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        let task = sut.loadImageData(from: url) { _ in }
        primaryLoader.complete(with: anyNSError())
        task.cancel()
        
        XCTAssertEqual(primaryLoader.cancelledURLs, [])
        XCTAssertEqual(fallbackLoader.cancelledURLs, [url])
    }
    
    func test_loadImageData_primarySuccessRequestsDesiredURLFromPrimary() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        waitForImageLoad(sut, url: url) {
            primaryLoader.complete(with: anyData())
        }
        
        XCTAssertEqual(primaryLoader.requestedURLs, [url])
        XCTAssertEqual(fallbackLoader.requestedURLs, [])
    }
    
    func test_loadImageData_fallbackRequestsDesiredURLFromPrimaryThenSecondary() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        waitForImageLoad(sut, url: url) {
            primaryLoader.complete(with: anyNSError())
            fallbackLoader.complete(with: anyData())
        }
        
        XCTAssertEqual(primaryLoader.requestedURLs, [url])
        XCTAssertEqual(fallbackLoader.requestedURLs, [url])
    }
    
    func test_loadImageData_deliversFailureOnBothPrimaryAndSecondaryLoaderFailure() {
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        expect(sut, url: anyURL(), toCompleteWith: .failure(anyNSError())) {
            primaryLoader.complete(with: anyNSError())
            fallbackLoader.complete(with: anyNSError())
        }
    }
    
}

// MARK: - Helpers

extension FeedImageDataLoaderWithFallbackCompositeTests {
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedImageDataLoader, primary: FeedImageDataLoaderSpy, fallback: FeedImageDataLoaderSpy) {
        let primaryLoader = FeedImageDataLoaderSpy()
        let fallbackLoader = FeedImageDataLoaderSpy()
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryLoader, fallbackLoader)
    }
    
    private func waitForImageLoad(_ sut: FeedImageDataLoader, url: URL, when action: () -> Void) {
        let exp = expectation(description: "Wait for image data load")
        _ = sut.loadImageData(from: url) { result in
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: FeedImageDataLoader, url: URL, toCompleteWith expectedResult: FeedImageDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        _ = sut.loadImageData(from: url) { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(recievedFeed), .success(expectedFeed)):
                XCTAssertEqual(recievedFeed, expectedFeed, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail("Expected \(expectedResult), got \(recievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}

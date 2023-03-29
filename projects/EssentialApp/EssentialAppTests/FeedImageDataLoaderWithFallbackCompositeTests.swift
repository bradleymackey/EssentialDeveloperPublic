//
//  FeedImageDataLoaderWithFallbackCompositeTests.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 06/03/2023.
//

import XCTest
import EssentialFeed

class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader

    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    private class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = TaskWrapper()
        task.wrapped = primary.loadImageData(from: url) { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure:
                task.wrapped = self?.fallback.loadImageData(from: url, completion: completion)
            }
        }
        return task
    }
    
}

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
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedImageDataLoader, primary: LoaderSpy, fallback: LoaderSpy) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
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
    
    private class LoaderSpy: FeedImageDataLoader {
        init() {}
        
        private(set) var messages = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
        private(set) var cancelledURLs = [URL]()
        
        var requestedURLs: [URL] {
            messages.map(\.url)
        }
        
        private struct StubTask: FeedImageDataLoaderTask {
            let callback: () -> Void
            func cancel() {
                callback()
            }
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            messages.append((url, completion))
            return StubTask { [weak self] in
                self?.cancelledURLs.append(url)
            }
        }
        
        func complete(with data: Data, at index: Int = 0) {
            messages[index].completion(.success(data))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
    }
    
    private func uniqueImageData() -> Data {
        Data(UUID().uuidString.utf8)
    }
    
    private func anyData() -> Data {
        Data("any".utf8)
    }
}

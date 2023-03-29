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
    
    class Task: FeedImageDataLoaderTask {
        func cancel() {
            
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        _ = primary.loadImageData(from: url) { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure:
                _ = self?.fallback.loadImageData(from: url) { result in
                    completion(result)
                }
            }
        }
        return Task()
    }
    
}

class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    
    func test_load_deliversPrimaryImageOnPrimarySuccess() {
        let primaryData = uniqueImageData()
        let fallbackData = uniqueImageData()
        let (sut, _, _) = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))
        
        let exp = expectation(description: "Wait for image data load")
        _ = sut.loadImageData(from: anyURL()) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, primaryData)
                
            case .failure:
                XCTFail("Expected successful data load")
            }
        
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_deliversFallbackImageOnPrimaryFailure() {
        let fallbackData = uniqueImageData()
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackData))
        
        let exp = expectation(description: "Wait for image data load")
        _ = sut.loadImageData(from: anyURL()) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, fallbackData)
                
            case .failure:
                XCTFail("Expected successful data load")
            }
        
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_primarySuccessRequestsDesiredURLFromPrimary() {
        let primaryData = uniqueImageData()
        let fallbackData = uniqueImageData()
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))
        
        waitForImageLoad(sut, url: url)
        
        XCTAssertEqual(primaryLoader.requestedURLs, [url])
        XCTAssertEqual(fallbackLoader.requestedURLs, [])
    }
    
    func test_load_fallbackRequestsDesiredURLFromPrimaryThenSecondary() {
        let fallbackData = uniqueImageData()
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackData))
        
        waitForImageLoad(sut, url: url)
        
        XCTAssertEqual(primaryLoader.requestedURLs, [url])
        XCTAssertEqual(fallbackLoader.requestedURLs, [url])
    }
    
}

// MARK: - Helpers

extension FeedImageDataLoaderWithFallbackCompositeTests {
    
    private func makeSUT(primaryResult: FeedImageDataLoader.Result, fallbackResult: FeedImageDataLoader.Result, file: StaticString = #file, line: UInt = #line) -> (sut: FeedImageDataLoader, primary: LoaderSpy, fallback: LoaderSpy) {
        let primaryLoader = LoaderSpy(result: primaryResult)
        let fallbackLoader = LoaderSpy(result: fallbackResult)
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryLoader, fallbackLoader)
    }
    
    private func waitForImageLoad(_ sut: FeedImageDataLoader, url: URL) {
        let exp = expectation(description: "Wait for image data load")
        _ = sut.loadImageData(from: url) { result in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class LoaderSpy: FeedImageDataLoader {
        private let result: FeedImageDataLoader.Result
        init(result: FeedImageDataLoader.Result) {
            self.result = result
        }
        
        private(set) var requestedURLs = [URL]()
        
        private struct StubTask: FeedImageDataLoaderTask {
            func cancel() {}
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            requestedURLs.append(url)
            completion(result)
            return StubTask()
        }
    }
    
    private func uniqueImageData() -> Data {
        Data(UUID().uuidString.utf8)
    }
}

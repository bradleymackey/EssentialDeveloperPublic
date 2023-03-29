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
                _ = self?.fallback.loadImageData(from: url) { result in
                    completion(result)
                }
            }
        }
        return task
    }
    
}

class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    
    func test_init_doesNotLoadImageData() {
        let (_, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .success(anyData()), fallbackResult: .success(anyData()))
        
        XCTAssertTrue(primaryLoader.requestedURLs.isEmpty, "Expected no URLs in primary loader")
        XCTAssertTrue(fallbackLoader.requestedURLs.isEmpty, "Expected no URLs in fallback loader")
    }
    
    func test_loadImageData_deliversPrimaryImageOnPrimarySuccess() {
        let primaryData = uniqueImageData()
        let fallbackData = uniqueImageData()
        let (sut, _, _) = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))
        
        expect(sut, url: anyURL(), toCompleteWith: .success(primaryData))
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
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackData))
        
        expect(sut, url: anyURL(), toCompleteWith: .success(fallbackData))
    }
    
    func test_loadImageData_primarySuccessRequestsDesiredURLFromPrimary() {
        let primaryData = uniqueImageData()
        let fallbackData = uniqueImageData()
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))
        
        waitForImageLoad(sut, url: url)
        
        XCTAssertEqual(primaryLoader.requestedURLs, [url])
        XCTAssertEqual(fallbackLoader.requestedURLs, [])
    }
    
    func test_loadImageData_fallbackRequestsDesiredURLFromPrimaryThenSecondary() {
        let fallbackData = uniqueImageData()
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackData))
        
        waitForImageLoad(sut, url: url)
        
        XCTAssertEqual(primaryLoader.requestedURLs, [url])
        XCTAssertEqual(fallbackLoader.requestedURLs, [url])
    }
    
    func test_loadImageData_deliversFailureOnBothPrimaryAndSecondaryLoaderFailure() {
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .failure(anyNSError()))
        
        expect(sut, url: anyURL(), toCompleteWith: .failure(anyNSError()))
    }
    
}

// MARK: - Helpers

extension FeedImageDataLoaderWithFallbackCompositeTests {
    
    private func makeSUT(primaryResult: FeedImageDataLoader.Result = .success(Data()), fallbackResult: FeedImageDataLoader.Result = .success(Data()), file: StaticString = #file, line: UInt = #line) -> (sut: FeedImageDataLoader, primary: LoaderSpy, fallback: LoaderSpy) {
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
    
    private func expect(_ sut: FeedImageDataLoader, url: URL, toCompleteWith expectedResult: FeedImageDataLoader.Result, file: StaticString = #file, line: UInt = #line) {
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
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class LoaderSpy: FeedImageDataLoader {
        private let result: FeedImageDataLoader.Result
        init(result: FeedImageDataLoader.Result) {
            self.result = result
        }
        
        private(set) var requestedURLs = [URL]()
        private(set) var cancelledURLs = [URL]()
        
        private struct StubTask: FeedImageDataLoaderTask {
            let callback: () -> Void
            func cancel() {
                callback()
            }
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            requestedURLs.append(url)
            completion(result)
            return StubTask { [weak self] in
                self?.cancelledURLs.append(url)
            }
        }
    }
    
    private func uniqueImageData() -> Data {
        Data(UUID().uuidString.utf8)
    }
    
    private func anyData() -> Data {
        Data("any".utf8)
    }
}

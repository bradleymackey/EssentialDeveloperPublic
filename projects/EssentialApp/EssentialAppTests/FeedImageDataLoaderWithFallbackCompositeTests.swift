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

    init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
    }
    
    class Task: FeedImageDataLoaderTask {
        func cancel() {
            
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        _ = primary.loadImageData(from: url) { result in
            completion(result)
        }
        return Task()
    }
    
}

class FeedImageDataLoaderWithFallbackCompositeTests: XCTestCase {
    
    func test_load_deliversPrimaryImageOnPrimarySuccess() {
        let primaryData = uniqueImageData()
        let fallbackData = uniqueImageData()
        let primaryLoader = ImageDataLoaderStub(result: .success(primaryData))
        let fallbackLoader = ImageDataLoaderStub(result: .success(fallbackData))
        let sut = FeedImageDataLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        
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
    
}

// MARK: - Helpers

extension FeedImageDataLoaderWithFallbackCompositeTests {
    
    private class ImageDataLoaderStub: FeedImageDataLoader {
        private let result: FeedImageDataLoader.Result
        init(result: FeedImageDataLoader.Result) {
            self.result = result
        }
        
        private struct StubTask: FeedImageDataLoaderTask {
            func cancel() {}
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            completion(result)
            return StubTask()
        }
    }
    
    private func uniqueImageData() -> Data {
        Data(UUID().uuidString.utf8)
    }
    
    private func anyURL() -> URL {
        URL(string: "https://a-url.com")!
    }
}

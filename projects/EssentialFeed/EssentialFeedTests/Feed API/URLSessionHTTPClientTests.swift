//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 14/04/2022.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask
}

protocol HTTPDataTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        // we don't really want to test the internal 'resume' behaviour of URLSession
        // this is an implementation detail, but this test does work
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://any-url.com")!
        let expectedError = NSError(domain: "any error", code: 1)
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        
        session.stub(url: url, error: expectedError)
        
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for completion block")
        sut.get(from: url) { result in
            switch result {
            case let .failure(error as NSError):
                XCTAssertEqual(error, expectedError)
            default:
                XCTFail("Expected failure with \(expectedError), got \(result) instead")
            }
            
            exp.fulfill()
            
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: - Helpers
    
    private class HTTPSessionSpy: HTTPSession {
        private var stubs = [URL: Stub]()
        
        private struct Stub {
            let task: HTTPDataTask
            let error: Error?
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask {
            guard let stub = stubs[url] else {
                fatalError("Could not find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
        
        func stub(url: URL, task: HTTPDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
    }
    
    private class FakeURLSessionDataTask: HTTPDataTask {
        func resume() {
        }
    }
    private class URLSessionDataTaskSpy: HTTPDataTask {
        var resumeCallCount = 0
        func resume() {
            resumeCallCount += 1
        }
    }
    
}


//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 14/04/2022.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                fatalError("Invalid state.")
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "https://any-url.com")!
        let expectedError = NSError(domain: "any error", code: 1)
        
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: expectedError)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for completion block")
        sut.get(from: url) { result in
            switch result {
            case let .failure(error as NSError):
                XCTAssertEqual(error.domain, expectedError.domain)
                XCTAssertEqual(error.code, expectedError.code)
            default:
                XCTFail("Expected failure with \(expectedError), got \(result) instead")
            }
            
            exp.fulfill()
            
        }
        
        wait(for: [exp], timeout: 1)
        URLProtocolStub.stopInterceptingRequests()
    }
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }
        
        static func stopInterceptingRequests() {
            stubs = [:]
            URLProtocol.unregisterClass(Self.self)
        }
        
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }
        
        // Can this stub handle this request?
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return URLProtocolStub.stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
                return
            }
        
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // abstract method, must override
        override func stopLoading() {}
    }
}


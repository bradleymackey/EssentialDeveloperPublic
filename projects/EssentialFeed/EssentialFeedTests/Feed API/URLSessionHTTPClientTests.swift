//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 14/04/2022.
//

import XCTest
import EssentialFeed


class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGetRequestWithURL() {
        let url = anyURL()
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.setBehaviour(observeRequests: { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        })
        
        sut.get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        let task = makeSUT().get(from: url) { result in
            switch result {
            case let .failure(error as NSError) where error.code == URLError.cancelled.rawValue:
                break
                
            default:
                XCTFail("Expected cancelled result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        task.cancel()
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let expectedError = anyNSError()
        let recievedError = resultErrorFor(data: nil, response: nil, error: expectedError) as NSError?
        
        XCTAssertEqual(recievedError?.domain, expectedError.domain)
        XCTAssertEqual(recievedError?.code, expectedError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let recievedValues = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(recievedValues?.data, data)
        XCTAssertEqual(recievedValues?.response.url, response.url)
        XCTAssertEqual(recievedValues?.response.statusCode, response.statusCode)
    }
    
    // URLSession framework automatically populates with empty data when `data` is nil.
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()

        let recievedValues = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(recievedValues?.data, emptyData)
        XCTAssertEqual(recievedValues?.response.url, response.url)
        XCTAssertEqual(recievedValues?.response.statusCode, response.statusCode)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClient.Result {
        // stub, so the next request will return this dummy data
        URLProtocolStub.setBehaviour(stubResponseData: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        
        let exp = expectation(description: "Wait for result completion")
        var recievedResult: HTTPClient.Result!
        // request hitting the network should return the dummy data
        // the thing we are actually testing is this get method -> we want to make
        // sure the mapping from URLSession to our custom type is bug-free
        sut.get(from: anyURL()) { result in
            recievedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return recievedResult
    }
    
    private func anyData() -> Data {
        Data("any data".utf8)
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    /// A low-level listener that will intercept all URLSession traffic.
    /// It can be used to stub URLSession requests for all data, ensuring that no
    /// URLSession data hits the network during testing.
    ///
    /// Call the interception methods to start and stop the interception.
    private class URLProtocolStub: URLProtocol {
        private enum Behaviour {
            case stubResponse(Stub)
            case observeRequest((URLRequest) -> Void)
        }
        private static var behaviour: Behaviour?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }
        
        static func stopInterceptingRequests() {
            behaviour = nil
            URLProtocol.unregisterClass(Self.self)
        }

        static func setBehaviour(observeRequests observer: @escaping (URLRequest) -> Void) {
            behaviour = .observeRequest(observer)
        }
        
        /// Stub the current state of the URLProtocol stack.
        /// The next request made will have this data returned as it's response in the
        /// URLSession system.
        static func setBehaviour(stubResponseData data: Data?, response: URLResponse?, error: Error?) {
            let stub = Stub(data: data, response: response, error: error)
            behaviour = .stubResponse(stub)
        }
        
        // Return `true` so that we always repond to all requests (not just specific stubbed URLs)
        // This is because if there is a URL mismatch it's not obvious that it would be a URL error
        // (we would just get a generic network error) which is hard to debug.
        // So we will add that assertion elsewhere, in another test.
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            switch Self.behaviour {
            case let .observeRequest(observer):
                // If there's an observer, finish loading
                // then invoke the observer.
                client?.urlProtocolDidFinishLoading(self)
                return observer(request)
            case let .stubResponse(stub):
                // If there's a stub, respond with the stubbed data.
                if let data = stub.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                if let response = stub.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let error = stub.error {
                    client?.urlProtocol(self, didFailWithError: error)
                }
            case nil:
                // If there's no intercept behaiour currently set, do nothing.
                break
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // abstract method, must override
        override func stopLoading() {}
    }
}

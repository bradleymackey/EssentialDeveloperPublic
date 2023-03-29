//
//  HTTPClientSpy.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 02/03/2023.
//

import Foundation
import EssentialFeed

/// Move the test logic to a test type - the client spy.
/// this mimicks the behaviour of the parent without having to actually make
/// a network request.
///
/// The `get` method will add a closure waiting to be completed.
/// Then, some time later, you can `complete` the closure and the
/// closure will be called with the provided update.
///
/// We want to avoid 'stubbing' in this spy, to keep it's intent clear.
/// For example, adding an `error` optional property that would always return an error within `get` would be stubbing.
/// It also makes the flow of our program confusing because we would have to set the stubbed error before `get` is called, breaking the natural flow of our program and confusing us as developers.
/// We only want the spy to capture values, then we can test them after.
/// Capturing the values is more simple.
final class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        let callback: () -> Void
        func cancel() { callback() }
    }
    
    private var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
    private(set) var cancelledURLs = [URL]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append((url, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        messages[index].completion(.success((data, response)))
    }
}

//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 14/04/2022.
//

import Foundation

// NOTE: this could just be an extension on URLSession
// but extending types that you don't own could lead to namespace conflicts in the
// future with function names etc., so having our own adapter type gives us a bit more control

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct InvalidRepresentationError: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error = error {
                    throw error
                } else if let data = data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw InvalidRepresentationError()
                }
            })
        }.resume()
    }
}

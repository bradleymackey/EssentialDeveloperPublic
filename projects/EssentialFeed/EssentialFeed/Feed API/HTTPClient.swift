//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 12/04/2022.
//

import Foundation

// There's no reason that HTTPClient needs to be a singleton.
// We can extend URLSession
public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible for dispatch to the appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}


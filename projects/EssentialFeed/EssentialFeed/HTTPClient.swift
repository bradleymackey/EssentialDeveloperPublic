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
    func get(from url: URL, completion: @escaping (Error) -> Void)
}

//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 12/04/2022.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>
    func load(completion: @escaping (Result) -> Void)
}

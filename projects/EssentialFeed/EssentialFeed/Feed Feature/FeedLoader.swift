//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 12/04/2022.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

//
//  FeedCache.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 07/03/2023.
//

import Foundation

public protocol FeedCache {
    typealias SaveResult = Result<Void, Error>
    
    func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void)
}

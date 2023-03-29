//
//  FeedImageDataCache.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 07/03/2023.
//

import Foundation

public protocol FeedImageDataCache {
    func save(_ data: Data, for url: URL) throws
}


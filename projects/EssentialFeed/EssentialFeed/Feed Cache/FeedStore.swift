//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 30/04/2022.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedItem], at date: Date, completion: @escaping InsertionCompletion)
}


//
//  FeedImageViewModel.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 01/03/2023.
//

public struct FeedImageViewModel {
    public let description: String?
    public let location: String?
    
    public var hasLocation: Bool {
        return location != nil
    }
}

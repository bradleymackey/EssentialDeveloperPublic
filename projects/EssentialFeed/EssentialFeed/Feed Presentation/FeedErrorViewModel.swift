//
//  FeedErrorViewModel.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 01/03/2023.
//

public struct FeedErrorViewModel {
    public let message: String?
    
    static var noError: FeedErrorViewModel {
        FeedErrorViewModel(message: nil)
    }
    
    static func error(message: String) -> FeedErrorViewModel {
        FeedErrorViewModel(message: message)
    }
}

//
//  FeedErrorViewModel.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 01/03/2023.
//

import Foundation

struct FeedErrorViewModel {
    let message: String?
}

extension FeedErrorViewModel {
    static var noError: FeedErrorViewModel {
        FeedErrorViewModel(message: nil)
    }
    
    static func error(message: String) -> FeedErrorViewModel {
        FeedErrorViewModel(message: message)
    }
}


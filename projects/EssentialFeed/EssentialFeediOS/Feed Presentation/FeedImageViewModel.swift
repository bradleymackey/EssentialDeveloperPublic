//
//  FeedImageViewModel.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 17/02/2023.
//

import Foundation
import EssentialFeed

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        location != nil
    }
}

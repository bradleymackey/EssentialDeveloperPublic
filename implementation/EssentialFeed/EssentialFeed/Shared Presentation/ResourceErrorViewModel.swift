//
//  ResourceErrorViewModel.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 01/03/2023.
//

public struct ResourceErrorViewModel {
    public let message: String?
    
    static var noError: ResourceErrorViewModel {
        ResourceErrorViewModel(message: nil)
    }
    
    static func error(message: String) -> ResourceErrorViewModel {
        ResourceErrorViewModel(message: message)
    }
}

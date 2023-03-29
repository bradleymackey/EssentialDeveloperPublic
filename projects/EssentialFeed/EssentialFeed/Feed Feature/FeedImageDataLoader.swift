//
//  FeedImageDataLoader.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 16/02/2023.
//

import Foundation

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) throws -> Data
}

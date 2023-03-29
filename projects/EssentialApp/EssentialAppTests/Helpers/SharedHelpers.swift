//
//  SharedHelpers.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 06/03/2023.
//

import Foundation
import EssentialFeed

func anyURL() -> URL {
    URL(string: "https://a-url.com")!
}

func anyNSError() -> NSError {
    NSError(domain: "any", code: 101)
}

func anyData() -> Data {
    Data("any".utf8)
}

func uniqueImageData() -> Data {
    Data(UUID().uuidString.utf8)
}

func uniqueFeed() -> [FeedImage] {
    [FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())]
}

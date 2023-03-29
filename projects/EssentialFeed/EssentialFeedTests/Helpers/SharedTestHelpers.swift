//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 07/05/2022.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "domain", code: 1)
}

func anyURL() -> URL {
    URL(string: "https://google.com")!
}

//
//  SharedHelpers.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 06/03/2023.
//

import Foundation

func anyURL() -> URL {
    URL(string: "https://a-url.com")!
}

func anyNSError() -> NSError {
    NSError(domain: "any", code: 101)
}

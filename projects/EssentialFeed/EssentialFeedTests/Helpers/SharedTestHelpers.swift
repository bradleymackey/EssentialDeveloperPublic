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

func anyData() -> Data {
    Data("any data".utf8)
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
}

//
//  XCTestCase+FeedLoader.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 07/03/2023.
//

import XCTest
import EssentialFeed

protocol FeedLoaderTestCase: XCTestCase {}

extension FeedLoaderTestCase {
    func expect(_ sut: FeedLoader, toCompleteWith expectedResult: FeedLoader.Result, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(recievedFeed), .success(expectedFeed)):
                XCTAssertEqual(recievedFeed, expectedFeed, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail("Expected \(expectedResult), got \(recievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}

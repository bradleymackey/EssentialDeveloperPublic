//
//  HTTPURLResponse+StatusCode.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 02/03/2023.
//

import Foundation

extension HTTPURLResponse {
    private static var OK_200: Int { 200 }
    
    var isOK: Bool {
        statusCode == HTTPURLResponse.OK_200
    }
}

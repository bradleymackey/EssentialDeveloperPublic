//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 08/05/2022.
//

import Foundation

/// Policy is deterministic and has no side effect, just a namespace.
internal final class FeedCachePolicy {
    private init() {}
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static let maxCacheAgeInDays = 7
    
    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxAge
    }
}

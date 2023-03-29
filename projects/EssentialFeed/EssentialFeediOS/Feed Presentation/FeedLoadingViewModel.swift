//
//  FeedLoadingViewModel.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 19/02/2023.
//

import Foundation

/// - Note: this is a ViewModel used in MVP, so it should have no state.
/// It is used to send state updates via the abstraction for the view, `FeedLoadingView`.
/// It's also called "View Data", just basic data for display.
struct FeedLoadingViewModel {
    let isLoading: Bool
}

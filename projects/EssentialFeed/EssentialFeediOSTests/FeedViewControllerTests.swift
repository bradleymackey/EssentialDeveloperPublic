//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 07/08/2022.
//

import XCTest
import UIKit

final class FeedViewController: UIViewController {
    private var loader: FeedViewControllerTests.LoaderSpy?
    
    // We can use a convenience init since we don't need any custom initialization.
    // This way, we don't need to implement the view controller's required initializers!
    convenience init(loader: FeedViewControllerTests.LoaderSpy) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader?.load()
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        // Knowledge of 3rd party framework is needed.
        // We need to know what UIKit does when this method is called, so we can write our test correctly!
        // We shouldn't be testing the framework, just the implementation of our own code, we assume UIKit works perfectly.
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
}

// MARK: - Helpers

extension FeedViewControllerTests {
    
    final class LoaderSpy {
        private(set) var loadCallCount = 0
        
        func load() {
            loadCallCount += 1
        }
    }
    
}

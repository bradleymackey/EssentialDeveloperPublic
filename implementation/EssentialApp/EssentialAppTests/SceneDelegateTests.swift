//
//  SceneDelegateTests.swift
//  EssentialAppTests
//
//  Created by Bradley Mackey on 14/03/2023.
//

import XCTest
import EssentialFeediOS
// We choose to use a @testable import here (rather than testing the public interface)
// because the composition root does not ever need to be public!
@testable import EssentialApp

final class SceneDelegateTests: XCTestCase {
    
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        sut.window = window
        
        sut.configureWindow()
        
        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
    }
    
    func test_configureWindow_configuresRootViewController() {
        let sut = SceneDelegate()
        sut.window = UIWindow()
        
        sut.configureWindow()
        
        let root = sut.window?.rootViewController
        let rootNavigation = root as? UINavigationController
        let topController = rootNavigation?.topViewController
        
        XCTAssertNotNil(rootNavigation, "Expected NavigationController as root.")
        XCTAssertTrue(topController is ListViewController)
    }
    
}

private class UIWindowSpy: UIWindow {
  var makeKeyAndVisibleCallCount = 0
  override func makeKeyAndVisible() {
    makeKeyAndVisibleCallCount = 1
  }
}

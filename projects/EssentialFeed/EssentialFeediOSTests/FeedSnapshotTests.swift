//
//  FeedSnapshotTests.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 15/03/2023.
//

import XCTest
import EssentialFeediOS

class FeedSnapshotTests: XCTestCase {
    
    func test_emptyFeed() throws {
        let sut = try makeSUT()
        
        sut.display(emptyFeed())
        
        record(snapshot: sut.snapshot(), named: "EMPTY_FEED")
    }
    
}

// MARK: - Helpers

extension FeedSnapshotTests {
    
    private func makeSUT() throws -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = try XCTUnwrap(storyboard.instantiateInitialViewController() as? FeedViewController)
        controller.loadViewIfNeeded()
        return controller
    }
    
    private func emptyFeed() -> [FeedImageCellController] {
        return []
    }
    
    private func record(snapshot: UIImage, named name: String, file: StaticString = #file, line: UInt = #line) {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail("Failed to generate PNG snapshot", file: file, line: line)
            return
        }
        
        let snapshotURL = URL(filePath: String(describing: file))
            .deletingLastPathComponent()
            .appending(path: "snapshots")
            .appending(path: "\(name).png")
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try snapshotData.write(to: snapshotURL)
        } catch {
            XCTFail("Failed to record snapshot: \(error)", file: file, line: line)
        }
    }
}

extension UIViewController {
    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { action in
            view.layer.render(in: action.cgContext)
        }
    }
}

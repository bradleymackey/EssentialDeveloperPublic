//
//  FeedSnapshotTests.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 15/03/2023.
//

import XCTest
@testable import EssentialFeed
import EssentialFeediOS

class FeedSnapshotTests: XCTestCase {
    
    func test_feedWithContent() throws {
        let sut = try makeSUT()
        
        sut.display(feedWithContent())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_CONTENT_dark")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light, contentSize: .extraExtraExtraLarge)), named: "FEED_WITH_CONTENT_light_extraExtraExtraLarge")
    }
    
    func test_feedWithFailedImageLoading() throws {
        let sut = try makeSUT()
        
        sut.display(feedWithFailedImageLoading())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_FAILED_IMAGE_LOADING_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_FAILED_IMAGE_LOADING_dark")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light, contentSize: .extraExtraExtraLarge)), named: "FEED_WITH_FAILED_IMAGE_LOADING_light_extraExtraExtraLarge")
    }
    
    func test_feedWithLoadMoreIndicator() throws {
        let sut = try makeSUT()
        
        sut.display(feedWithLoadMoreIndicator())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_LOAD_MORE_INDICATOR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_LOAD_MORE_INDICATOR_dark")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light, contentSize: .extraExtraExtraLarge)), named: "FEED_WITH_LOAD_MORE_INDICATOR_light_extraExtraExtraLarge")
    }
    
    func test_feedWithLoadMoreError() throws {
        let sut = try makeSUT()
        
        sut.display(feedWithLoadMoreError())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_LOAD_MORE_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_LOAD_MORE_ERROR_dark")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light, contentSize: .extraExtraExtraLarge)), named: "FEED_WITH_LOAD_MORE_ERROR_light_extraExtraExtraLarge")
    }
}

// MARK: - Helpers

extension FeedSnapshotTests {
    
    private func makeSUT() throws -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = try XCTUnwrap(storyboard.instantiateInitialViewController() as? ListViewController)
        controller.loadViewIfNeeded()
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }
    
    private func emptyFeed() -> [FeedImageCellController] {
        return []
    }
    
    private func feedWithContent() -> [ImageStub] {
        return [
            ImageStub(description: "Testing 123", location: "Test\nTest2", image: UIImage.make(withColor: .red)),
            ImageStub(description: "Testing 456", location: "Test2\nTest3", image: UIImage.make(withColor: .blue)),
            ImageStub(description: "Testing 789", location: "Test7\nTest6", image: UIImage.make(withColor: .green)),
        ]
    }
    
    private func feedWithFailedImageLoading() -> [ImageStub] {
        return [
            ImageStub(description: nil, location: "Test\nTest2", image: nil),
            ImageStub(description: nil, location: "Test2\nTest3", image: nil),
            ImageStub(description: nil, location: "Test7\nTest6", image: nil),
        ]
    }
    
    private func feedWithLoadMoreIndicator() -> [CellController] {
        let loadMore = LoadMoreCellController(callback: {})
        loadMore.display(.init(isLoading: true))
        return feedWith(loadMore: loadMore)
    }
    
    private func feedWithLoadMoreError() -> [CellController] {
        let loadMore = LoadMoreCellController(callback: {})
        loadMore.display(.error(message: "This is a multiline\nerror message"))
        return feedWith(loadMore: loadMore)
    }
    
    private func feedWith(loadMore: LoadMoreCellController) -> [CellController] {
        let stub = feedWithContent().last!
        let cellController = FeedImageCellController(viewModel: stub.viewModel, delegate: stub, selection: {})
        stub.controller = cellController
        
        return [
            CellController(id: UUID(), cellController),
            CellController(id: UUID(), loadMore),
        ]
    }
}

private extension ListViewController {
    func display(_ stubs: [ImageStub]) {
        let cells: [CellController] = stubs.map { stub in
            let cellController = FeedImageCellController(viewModel: stub.viewModel, delegate: stub, selection: {})
            stub.controller = cellController
            return CellController(id: UUID(), cellController)
        }
        
        display(cells)
    }
}

private class ImageStub: FeedImageCellControllerDelegate {
    let viewModel: FeedImageViewModel
    let image: UIImage?
    weak var controller: FeedImageCellController?
    
    init(description: String?, location: String?, image: UIImage?) {
        self.viewModel = FeedImageViewModel(
            description: description,
            location: location)
        self.image = image
    }
    
    func didRequestImage() {
        controller?.display(ResourceLoadingViewModel(isLoading: false))
        if let image {
            controller?.display(image)
            controller?.display(ResourceErrorViewModel(message: .none))
        } else {
            controller?.display(ResourceErrorViewModel(message: "any"))
        }
    }
    
    func didCancelImageRequest() {
    }
    
    func didCreatePlaceholder() {
    }
}

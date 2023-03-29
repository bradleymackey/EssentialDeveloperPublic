//
//  LoadResourcePresentationAdapter.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 21/02/2023.
//

import Combine
import Foundation
import EssentialFeed
import EssentialFeediOS

final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: AnyCancellable?
    /// This is only optional to break a circular dependency.
    /// It's fine though, because this is at the composition layer.
    /// We're not leaking this composition detail into the adapters.
    ///
    /// (Constructor injection should be preferred whereever possible though!)
    var presenter: LoadResourcePresenter<Resource, View>?
    
    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }
    
    func loadResource() {
        presenter?.didStartLoading()
        cancellable = loader().sink { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self?.presenter?.didFinishLoading(with: error)
            }
        } receiveValue: { [weak self] feed in
            self?.presenter?.didFinishLoading(with: feed)
        }
    }
}

extension LoadResourcePresentationAdapter: FeedViewControllerDelegate {
    func didRequestFeedRefresh() {
        loadResource()
    }
}

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {
    func didCreatePlaceholder() {
        presenter?.didStartLoading()
    }
    
    func didRequestImage() {
        loadResource()
    }
    
    func didCancelImageRequest() {
        cancellable?.cancel()
        cancellable = nil
    }
}

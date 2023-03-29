//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit
import EssentialFeed

final class FeedImageCellController {
    private let viewModel: FeedImageViewModel
    
    init(viewModel: FeedImageViewModel) {
        self.viewModel = viewModel
    }
    
    func view() -> UITableViewCell {
        let cell = binded(FeedImageCell())
        return cell
    }
    
    func willDisplay() {
        viewModel.loadImageData()
    }
    
    func preload() {
        viewModel.loadImageData()
    }
    
    func cancelLoad() {
        viewModel.cancelImageDataLoad()
    }
    
    func binded(_ cell: FeedImageCell) -> FeedImageCell {
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        cell.feedImageView.image = nil
        cell.onRetry = viewModel.loadImageData
        viewModel.onImageLoad = { [weak cell] image in
            cell?.feedImageView.image = image
        }
        viewModel.onImageLoadingStateChange = { [weak cell] isLoading in
            cell?.feedImageContainer.isShimmering = isLoading
        }
        viewModel.onShouldRetryImageLoadStateChange = { [weak cell] shouldRetry in
            cell?.feedImageRetryButton.isHidden = !shouldRetry
        }
        return cell
    }
}


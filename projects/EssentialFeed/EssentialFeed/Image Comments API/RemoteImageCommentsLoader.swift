//
//  RemoteImageCommentsLoader.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 25/03/2023.
//

import Foundation

public typealias RemoteImageCommentsLoader = RemoteLoader<[ImageComment]>

extension RemoteImageCommentsLoader {
    convenience init(url: URL, client: HTTPClient) {
        self.init(url: url, client: client, mapper: ImageCommentsMapper.map)
    }
}

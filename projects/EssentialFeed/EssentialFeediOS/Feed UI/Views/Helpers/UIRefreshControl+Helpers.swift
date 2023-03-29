//
//  UIRefreshControl+Helpers.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 01/03/2023.
//

import UIKit

extension UIRefreshControl {
     func update(isRefreshing: Bool) {
         isRefreshing ? beginRefreshing() : endRefreshing()
     }
 }

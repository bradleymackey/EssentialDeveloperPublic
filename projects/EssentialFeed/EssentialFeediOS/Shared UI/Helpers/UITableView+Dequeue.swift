//
//  UITableView+Dequeue.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 19/02/2023.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        let cell = dequeueReusableCell(withIdentifier: identifier)
        return cell as! T
    }
}

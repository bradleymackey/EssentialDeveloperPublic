//
//  UIButton+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Bradley Mackey on 16/02/2023.
//

import UIKit

extension UIButton {
    func simulateTap() {
        simulate(event: .touchUpInside)
    }
}

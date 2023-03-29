//
//  ErrorView.swift
//  EssentialFeediOS
//
//  Created by Bradley Mackey on 01/03/2023.
//

import UIKit

public final class ErrorView: UIButton {
    public var message: String? {
        get { isVisible ? title(for: .normal) : nil }
    }
    
    private var isVisible: Bool {
        return alpha > 0
    }
    
    public var onHide: (() -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        backgroundColor = .errorBackgroundColor
        
        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        configureLabel()
        hideMessage()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        hideMessage()
    }
    
    private func configureLabel() {
        titleLabel?.textColor = .white
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        titleLabel?.font = .preferredFont(forTextStyle: .body)
    }
    
    func showAnimated(message: String) {
        setTitle(message, for: .normal)

        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    @objc func hideMessageAnimated() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = 0 },
            completion: { completed in
                if completed {
                    self.hideMessage()
                }
            })
    }
    
    private func hideMessage() {
        setTitle(nil, for: .normal)
        alpha = 0
        onHide?()
    }
}

extension UIColor {
    static var errorBackgroundColor: UIColor {
        UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}

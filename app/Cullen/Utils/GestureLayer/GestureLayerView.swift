//
//  GestureLayerView.swift
//  Cullen
//

import UIKit

final class GestureLayerView: UIView {

    var hitTestHandler: ((CGPoint) -> Bool)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Returns self when handler confirms capture, nil to pass touch further down the hit-test chain.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard hitTestHandler?(point) == true else {
            return nil
        }

        return self
    }
}

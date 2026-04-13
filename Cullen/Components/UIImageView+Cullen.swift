//
//  UIImageView+Cullen.swift
//  Cullen
//
//  Presentation Layer - UIKit counterpart to CullenImage
//

import UIKit
import Kingfisher


extension UIImageView {
    func setCullenImage(with url: URL?, completion: @escaping () -> Void = {}) {
        image = nil
        kf.indicatorType = .activity

        kf.setImage(with: url) { [weak self] result in
            switch result {
            case .success:
                break
            case .failure:
                self?.image = .cullenFailure
            }
            completion()
        }
    }
}


private extension UIImage {
    static let cullenFailure = UIImage(systemName: "exclamationmark.triangle.fill")?
        .withTintColor(.red, renderingMode: .alwaysOriginal)
}

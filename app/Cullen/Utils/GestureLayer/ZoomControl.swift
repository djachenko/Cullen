//
//  ZoomControl.swift
//  Cullen
//

import UIKit
import Combine

final class ZoomControl: ObservableObject {

    private(set) weak var scrollView: UIScrollView?

    func connect(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    // screenAnchor: nil → zoom to content center
    func zoom(to scale: CGFloat, screenAnchor: CGPoint? = nil) {
        guard let scrollView else { return }

        let imagePoint: CGPoint

        if let screenAnchor {
            let pointInScrollView = scrollView.convert(screenAnchor, from: nil)
            let contentPoint = CGPoint(
                x: pointInScrollView.x - scrollView.contentInset.left + scrollView.contentOffset.x,
                y: pointInScrollView.y - scrollView.contentInset.top + scrollView.contentOffset.y
            )
            imagePoint = CGPoint(
                x: contentPoint.x / scrollView.zoomScale,
                y: contentPoint.y / scrollView.zoomScale
            )
        } else {
            guard let imageView = scrollView.subviews.first else { return }
            imagePoint = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        }

        let w = scrollView.bounds.width / scale
        let h = scrollView.bounds.height / scale
        let rect = CGRect(
            x: imagePoint.x - w / 2,
            y: imagePoint.y - h / 2,
            width: w,
            height: h
        )
        scrollView.zoom(to: rect, animated: false)
    }

    func reset(animated: Bool = true) {
        scrollView?.setZoomScale(1, animated: animated)
    }
}

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
    func zoom(
        to scale: CGFloat,
        screenAnchor: CGPoint? = nil,
        animated: Bool = false
    ) {
        guard let scrollView,
              let imageView = scrollView.subviews.first else {
            return
        }

        let clampedScale = min(max(scale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)

        // Predict content insets after zoom (matches what centerImageView will compute).
        let newContentW = imageView.bounds.width * clampedScale
        let newContentH = imageView.bounds.height * clampedScale
        let newInsetX = max((scrollView.bounds.width - newContentW) / 2, 0)
        let newInsetY = max((scrollView.bounds.height - newContentH) / 2, 0)

        let targetOffset: CGPoint

        if let screenAnchor {
            let pointInSV = scrollView.convert(screenAnchor, from: nil)
            let currentScale = scrollView.zoomScale

            // pointInSV is already in content space (bounds.origin == contentOffset).
            let imagePoint = CGPoint(x: pointInSV.x / currentScale, y: pointInSV.y / currentScale)

            // contentOffset that places imagePoint exactly at screenAnchor after zoom.
            let dx = newInsetX + imagePoint.x * clampedScale - screenAnchor.x
            let dy = newInsetY + imagePoint.y * clampedScale - screenAnchor.y

            // Clamp to valid scroll range.
            let maxX = max(newContentW - scrollView.bounds.width + newInsetX, -newInsetX)
            let maxY = max(newContentH - scrollView.bounds.height + newInsetY, -newInsetY)

            targetOffset = CGPoint(
                x: min(max(dx, -newInsetX), maxX),
                y: min(max(dy, -newInsetY), maxY)
            )
        } else {
            targetOffset = CGPoint(x: -newInsetX, y: -newInsetY)
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                scrollView.zoomScale = clampedScale
                scrollView.contentOffset = targetOffset
            }
        } else {
            scrollView.setZoomScale(clampedScale, animated: false)
            scrollView.setContentOffset(targetOffset, animated: false)
        }
    }

    func reset(animated: Bool = true) {
        scrollView?.setZoomScale(1, animated: animated)
    }
}

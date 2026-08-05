//
//  GestureLayerCoordinator.swift
//  Cullen
//

import UIKit

final class GestureLayerCoordinator: NSObject {

    // MARK: - Entries

    private struct TapEntry {
        let recognizer: UITapGestureRecognizer
        var when: () -> Bool
        var action: (CGPoint) -> Void
    }

    private struct PanEntry {
        let recognizer: UIPanGestureRecognizer
        let filter: PanFilter
        var when: () -> Bool
        var onChanged: (CGPoint) -> Void
        var onEnded: (CGPoint, CGPoint) -> Void
    }

    private struct PinchEntry {
        let recognizer: UIPinchGestureRecognizer
        var when: () -> Bool
        var onChanged: (CGFloat, CGPoint) -> Void
    }

    private var taps: [TapEntry] = []
    private var pans: [PanEntry] = []
    private var pinches: [PinchEntry] = []

    // MARK: - Setup

    func install(on view: UIView, descriptors: [GestureDescriptor]) {
        for descriptor in descriptors {
            switch descriptor {
                case let d as GestureTap:
                    install(d, on: view)
                case let d as GesturePan:
                    install(d, on: view)
                case let d as GesturePinch:
                    install(d, on: view)
                default:
                    break
            }
        }

        wireTapChain()
    }

    // Replaces closures in-place so recognizers are not recreated on SwiftUI updates.
    func update(descriptors: [GestureDescriptor]) {
        var tapIdx = 0, panIdx = 0, pinchIdx = 0

        for descriptor in descriptors {
            if let d = descriptor as? GestureTap {
                if tapIdx < taps.count {
                    taps[tapIdx].when = d.when
                    taps[tapIdx].action = d.action
                }
                tapIdx += 1
            } else if let d = descriptor as? GesturePan {
                if panIdx < pans.count {
                    pans[panIdx].when = d.when
                    pans[panIdx].onChanged = d.onChanged
                    pans[panIdx].onEnded = d.onEnded
                }
                panIdx += 1
            } else if let d = descriptor as? GesturePinch {
                if pinchIdx < pinches.count {
                    pinches[pinchIdx].when = d.when
                    pinches[pinchIdx].onChanged = d.onChanged
                }
                pinchIdx += 1
            }
        }
    }

    // MARK: - Private install

    private func install(_ d: GestureTap, on view: UIView) {
        let r = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        r.numberOfTapsRequired = d.count
        r.delegate = self
        view.addGestureRecognizer(r)
        taps.append(TapEntry(recognizer: r, when: d.when, action: d.action))
    }

    private func install(_ d: GesturePan, on view: UIView) {
        let r = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        r.delegate = self
        view.addGestureRecognizer(r)

        pans.append(PanEntry(recognizer: r, filter: d.filter, when: d.when, onChanged: d.onChanged, onEnded: d.onEnded))
    }

    private func install(_ d: GesturePinch, on view: UIView) {
        let r = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        r.delegate = self
        view.addGestureRecognizer(r)

        pinches.append(PinchEntry(recognizer: r, when: d.when, onChanged: d.onChanged))
    }

    // Single-tap automatically requires double-tap to fail, double-tap requires triple-tap, etc.
    private func wireTapChain() {
        let sorted = taps.sorted { $0.recognizer.numberOfTapsRequired < $1.recognizer.numberOfTapsRequired }

        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                sorted[i].recognizer.require(toFail: sorted[j].recognizer)
            }
        }
    }

    // MARK: - Handlers

    @objc private func handleTap(_ r: UITapGestureRecognizer) {
        guard let entry = taps.first(where: { $0.recognizer === r }) else {
            return
        }

        let location = r.location(in: r.view?.window)
        entry.action(location)
    }

    @objc private func handlePan(_ r: UIPanGestureRecognizer) {
        guard let entry = pans.first(where: { $0.recognizer === r }) else {
            return
        }
        guard let view = r.view else {
            return
        }

        switch r.state {
            case .changed:
                entry.onChanged(r.translation(in: view))
            case .ended, .cancelled:
                entry.onEnded(r.translation(in: view), r.velocity(in: view))
            default:
                break
        }
    }

    @objc private func handlePinch(_ r: UIPinchGestureRecognizer) {
        guard let entry = pinches.first(where: { $0.recognizer === r }) else {
            return
        }

        // Window coordinates so ZoomControl can convert to any scrollView space.
        let location = r.location(in: r.view?.window)
        entry.onChanged(r.scale, location)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GestureLayerCoordinator: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ r: UIGestureRecognizer) -> Bool {
        if let tap = r as? UITapGestureRecognizer,
           let entry = taps.first(where: { $0.recognizer === tap }) {
            return entry.when()
        }

        if let pan = r as? UIPanGestureRecognizer,
           let entry = pans.first(where: { $0.recognizer === pan }) {
            guard entry.when() else { return false }

            let velocity = pan.velocity(in: pan.view)

            return switch entry.filter {
                case .horizontal:
                    abs(velocity.x) > abs(velocity.y)
                case .vertical:
                    abs(velocity.y) > abs(velocity.x)
                case .any:
                    true
            }
        }

        if let pinch = r as? UIPinchGestureRecognizer,
           let entry = pinches.first(where: { $0.recognizer === pinch }) {
            return entry.when()
        }

        return true
    }

    func gestureRecognizer(
        _ r: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        r is UIPinchGestureRecognizer || other is UIPinchGestureRecognizer
    }
}

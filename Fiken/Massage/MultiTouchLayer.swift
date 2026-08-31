import SwiftUI
import UIKit

/// Reports every active touch point. SwiftUI's gestures only ever describe one
/// finger, and this screen is built around four of them being down at once.
struct MultiTouchLayer: UIViewRepresentable {
    var onChange: ([CGPoint]) -> Void

    func makeUIView(context: Context) -> TouchReportingView {
        let view = TouchReportingView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: TouchReportingView, context: Context) {
        view.onChange = onChange
    }

    final class TouchReportingView: UIView {
        var onChange: (([CGPoint]) -> Void)?
        private var active: [ObjectIdentifier: CGPoint] = [:]

        override init(frame: CGRect) {
            super.init(frame: frame)
            isMultipleTouchEnabled = true
            backgroundColor = .clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not used") }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            record(touches)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            record(touches)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            remove(touches)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            remove(touches)
        }

        private func record(_ touches: Set<UITouch>) {
            for touch in touches {
                active[ObjectIdentifier(touch)] = touch.location(in: self)
            }
            onChange?(Array(active.values))
        }

        private func remove(_ touches: Set<UITouch>) {
            for touch in touches {
                active.removeValue(forKey: ObjectIdentifier(touch))
            }
            onChange?(Array(active.values))
        }
    }
}

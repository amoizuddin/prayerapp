import SwiftUI
import UIKit

/// Tells whether a finger is currently on the list, by asking the list's underlying
/// UIKit scroll view. SwiftUI doesn't expose this directly.
final class ScrollTracker {
    weak var scrollView: UIScrollView?

    var isTouching: Bool { scrollView?.isTracking ?? false }
}

/// An invisible view placed inside the list that finds the scroll view containing it.
struct ScrollViewFinder: UIViewRepresentable {
    let tracker: ScrollTracker

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        guard tracker.scrollView == nil else { return }
        DispatchQueue.main.async {
            var current = view.superview
            while let candidate = current, !(candidate is UIScrollView) {
                current = candidate.superview
            }
            tracker.scrollView = current as? UIScrollView
        }
    }
}

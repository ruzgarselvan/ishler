import SwiftUI
import AppKit

/// Reports horizontal two-finger trackpad swipes over the hosting window: +1 for a swipe left, -1 for a swipe right.
struct SwipeMonitor: NSViewRepresentable {
    let onSwipe: (Int) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.install(for: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) { context.coordinator.onSwipe = onSwipe }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) { coordinator.remove() }

    func makeCoordinator() -> Coordinator { Coordinator(onSwipe: onSwipe) }

    @MainActor
    final class Coordinator {
        var onSwipe: (Int) -> Void
        private var monitor: Any?
        private var accumulated: CGFloat = 0
        private var fired = false

        init(onSwipe: @escaping (Int) -> Void) { self.onSwipe = onSwipe }

        func install(for view: NSView) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self, weak view] event in
                MainActor.assumeIsolated {
                    if let self, let view, view.window != nil, event.window === view.window { self.handle(event) }
                }
                return event
            }
        }

        func remove() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        private func handle(_ event: NSEvent) {
            guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else { return }
            if event.phase.contains(.began) { accumulated = 0; fired = false }
            accumulated += event.scrollingDeltaX
            if !fired, abs(accumulated) > 30 {
                fired = true
                onSwipe(accumulated < 0 ? 1 : -1)
            }
            if event.phase.contains(.ended) || event.phase.contains(.cancelled) { accumulated = 0 }
        }
    }
}

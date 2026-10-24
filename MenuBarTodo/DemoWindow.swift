#if DEBUG
import AppKit
import SwiftUI

/// Debug aid for website screenshots: the menu bar panel in a plain window at a known position.
@MainActor
enum DemoWindow {
    private static var window: NSWindow?

    static func show(model: AppModel) {
        NSLog("ishler demo: show window")
        NSApp.setActivationPolicy(.regular)
        let view = PanelView().environment(model).modelContainer(model.store.container)
        let host = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(x: 120, y: 400, width: 320, height: 600),
                              styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentView = host
        window.setContentSize(host.fittingSize)
        window.setFrameTopLeftPoint(NSPoint(x: 120, y: 700))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Self.window = window

        // Without Screen Recording permission screencapture can't see our window, so draw the view into a PNG directly.
        if let out = ProcessInfo.processInfo.arguments.drop(while: { $0 != "-demoOut" }).dropFirst().first {
            Task {
                try? await Task.sleep(for: .seconds(4))
                host.layoutSubtreeIfNeeded()
                let bounds = host.bounds
                if let rep = host.bitmapImageRepForCachingDisplay(in: bounds) {
                    host.cacheDisplay(in: bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: out)) // run a copy re-signed without the sandbox so this path is writable
                }
                NSLog("ishler demo: captured \(out) rep=\(host.bitmapImageRepForCachingDisplay(in: bounds) != nil)")
                NSApp.terminate(nil)
            }
        }
    }
}
#endif

import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Global ⌃⌥N shortcut that opens a small floating "yeni iş" window over whatever app is in front.
@MainActor
final class QuickAdd {
    static let shared = QuickAdd()
    private var panel: QuickPanel?
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?

    func setEnabled(_ enabled: Bool) {
        if enabled, hotKey == nil {
            var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                DispatchQueue.main.async { MainActor.assumeIsolated { QuickAdd.shared.toggle() } }
                return noErr
            }, 1, &type, nil, &handler)
            RegisterEventHotKey(UInt32(kVK_ANSI_N), UInt32(controlKey | optionKey),
                                EventHotKeyID(signature: 0x6973686C, id: 1), GetApplicationEventTarget(), 0, &hotKey)
        } else if !enabled {
            if let hotKey { UnregisterEventHotKey(hotKey) }
            if let handler { RemoveEventHandler(handler) }
            hotKey = nil
            handler = nil
            panel?.orderOut(nil)
        }
    }

    func toggle() {
        if let panel, panel.isVisible { panel.orderOut(nil); return }
        let panel = QuickPanel(contentRect: NSRect(x: 0, y: 0, width: 460, height: 90),
                               styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = NSHostingView(rootView: QuickAddView(onClose: { [weak panel] in panel?.orderOut(nil) })
            .environment(AppModel.shared))
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - 230, y: frame.maxY - frame.height * 0.28))
        }
        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}

final class QuickPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }
}

private struct QuickAddView: View {
    let onClose: () -> Void

    var body: some View {
        EntryField(onAdded: onClose)
            .padding(14)
            .frame(width: 460)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .onExitCommand(perform: onClose)
    }
}

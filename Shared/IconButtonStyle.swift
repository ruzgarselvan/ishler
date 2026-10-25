import SwiftUI

/// Icon button with a roomy hit area and a hover/press highlight, so small glyphs are easy to hit.
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 28

    func makeBody(configuration: Configuration) -> some View {
        Label(configuration: configuration, size: size)
    }

    private struct Label: View {
        let configuration: Configuration
        let size: CGFloat
        @State private var hovering = false

        var body: some View {
            configuration.label
                .frame(width: size, height: size)
                .background(Color.primary.opacity(configuration.isPressed ? 0.16 : hovering ? 0.08 : 0), in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
        }
    }
}

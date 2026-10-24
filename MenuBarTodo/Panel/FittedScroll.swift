import SwiftUI

private struct HeightKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// A scroll view as tall as its content, up to `maxHeight`.
struct FittedScroll<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder var content: Content
    @State private var height: CGFloat = 0

    var body: some View {
        ScrollView {
            content.background(GeometryReader { Color.clear.preference(key: HeightKey.self, value: $0.size.height) })
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(height, maxHeight))
        .onPreferenceChange(HeightKey.self) { height = $0 }
    }
}

struct PanelHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.system(size: 13, weight: .semibold))
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").fontWeight(.semibold) }
                    .buttonStyle(.plain).foregroundStyle(Color.accentColor)
                Spacer()
            }
        }
    }
}

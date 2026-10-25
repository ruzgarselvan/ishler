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
        .mask {
            // Soft fade at the bottom edge when the content scrolls, so nothing is cut hard at the rounded corners.
            VStack(spacing: 0) {
                Color.black
                if height > maxHeight { LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 14) }
            }
        }
        .onPreferenceChange(HeightKey.self) { height = $0 }
    }
}

struct PanelHeader: View {
    let title: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.system(size: 13, weight: .semibold))
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("İşler")
                    }
                    .font(.system(size: 13))
                    .padding(.vertical, 6).padding(.trailing, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .keyboardShortcut(.cancelAction)
                Spacer()
            }
        }
    }
}

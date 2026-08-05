import AppKit
import SwiftUI

struct FrameSwatchPicker: View {
    @Binding var selection: FrameStyle?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(FrameStyle.all) { style in
                swatch(for: style)
            }
            noFrameSwatch
        }
        .padding(12)
        .frame(width: 250)
    }

    private func swatch(for style: FrameStyle) -> some View {
        Button {
            selection = style
        } label: {
            tile(isSelected: selection?.id == style.id) {
                if let art = FrameStyle.image(named: style.image) {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(9)
                }
            }
        }
        .buttonStyle(.plain)
        .help(style.name)
    }

    private var noFrameSwatch: some View {
        Button {
            selection = nil
        } label: {
            tile(isSelected: selection == nil) {
                GeometryReader { geo in
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width * 0.22, y: geo.size.height * 0.78))
                        path.addLine(to: CGPoint(x: geo.size.width * 0.78, y: geo.size.height * 0.22))
                    }
                    .stroke(Color.secondary.opacity(0.65), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                .padding(6)
            }
        }
        .buttonStyle(.plain)
        .help("No frame")
    }

    private func tile<Content: View>(
        isSelected: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
    }
}

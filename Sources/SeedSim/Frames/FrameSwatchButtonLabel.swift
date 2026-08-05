import SwiftUI

struct FrameSwatchButtonLabel: View {
    let style: FrameStyle?

    var body: some View {
        Group {
            if let style, let art = FrameStyle.image(named: style.image) {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(3)
            } else {
                GeometryReader { geo in
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width * 0.24, y: geo.size.height * 0.76))
                        path.addLine(to: CGPoint(x: geo.size.width * 0.76, y: geo.size.height * 0.24))
                    }
                    .stroke(
                        Color.secondary.opacity(0.7),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                }
                .padding(5)
            }
        }
        .frame(width: 30, height: 30)
        .background(Color.primary.opacity(0.07), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(Color.primary.opacity(0.15))
        }
        .contentShape(Rectangle())
    }
}

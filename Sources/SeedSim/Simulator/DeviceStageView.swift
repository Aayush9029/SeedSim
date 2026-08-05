import AppKit
import SwiftUI

struct DeviceStageView: View {
    @Bindable var engine: LVGLEngine
    var style: FrameStyle?
    var zoom: CGFloat

    @State private var scrollAccumulator: CGFloat = 0
    @FocusState private var focused: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.clear
                if let style {
                    framed(style: style, in: geo.size)
                } else {
                    bare(in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .background(ScrollCatcher { accumulate($0) })
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onAppear { focused = true }
            .onKeyPress(.leftArrow)  { engine.rotate(-1);  return .handled }
            .onKeyPress(.rightArrow) { engine.rotate(1);   return .handled }
            .onKeyPress(.upArrow)    { engine.rotate(-1);  return .handled }
            .onKeyPress(.downArrow)  { engine.rotate(1);   return .handled }
            .onKeyPress(.return)     { engine.press();     return .handled }
            .onKeyPress(.space)      { engine.longPress(); return .handled }
            .animation(.easeInOut(duration: 0.2), value: style?.id)
            .animation(.easeInOut(duration: 0.15), value: zoom)
        }
    }

    private func framed(style: FrameStyle, in size: CGSize) -> some View {
        let box = fittedRect(aspect: style.aspect, in: size)
        let diameter = 2 * style.radiusFrac * box.width
        let center = CGPoint(
            x: box.minX + style.centerXFrac * box.width,
            y: box.minY + style.centerYFrac * box.height
        )
        // Black backing, live panel, then the frame with its disc punched out -
        // so the bezel occludes the panel edge instead of sitting behind it.
        return ZStack(alignment: .topLeading) {
            Circle()
                .fill(.black)
                .frame(width: diameter, height: diameter)
                .offset(x: center.x - diameter / 2, y: center.y - diameter / 2)

            panel(diameter: diameter)
                .offset(x: center.x - diameter / 2, y: center.y - diameter / 2)

            if let art = FrameStyle.image(named: style.cutoutImage) {
                Image(nsImage: art)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: box.width, height: box.height)
                    .offset(x: box.minX, y: box.minY)
                    .allowsHitTesting(false)
            }
        }
    }

    /// Without a frame the panel keeps the exact size *and position* it has
    /// inside one, the artwork's panel centre is off-centre in its canvas, so
    /// centring in the view instead would make the panel jump on toggle.
    private func bare(in size: CGSize) -> some View {
        let reference = FrameStyle.default
        let box = fittedRect(aspect: reference.aspect, in: size)
        let diameter = 2 * reference.radiusFrac * box.width
        let center = CGPoint(
            x: box.minX + reference.centerXFrac * box.width,
            y: box.minY + reference.centerYFrac * box.height
        )
        return panel(diameter: diameter)
            .offset(x: center.x - diameter / 2, y: center.y - diameter / 2)
    }

    private func panel(diameter: CGFloat) -> some View {
        Group {
            if let frame = engine.frame {
                Image(decorative: frame, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                Color.black
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { send($0.location, diameter: diameter, down: true) }
                .onEnded { send($0.location, diameter: diameter, down: false) }
        )
    }

    /// Gesture coordinates are panel-local; rescale into the 412px LVGL space.
    private func send(_ point: CGPoint, diameter: CGFloat, down: Bool) {
        let scale = CGFloat(style?.panelPx ?? 412) / diameter
        engine.touch(x: Int(point.x * scale), y: Int(point.y * scale), down: down)
    }

    private func accumulate(_ delta: CGFloat) {
        scrollAccumulator += delta
        while abs(scrollAccumulator) >= 6 {
            engine.rotate(scrollAccumulator > 0 ? -1 : 1)
            scrollAccumulator -= scrollAccumulator > 0 ? 6 : -6
        }
    }


    private func fittedRect(aspect: Double, in size: CGSize) -> CGRect {
        let available = CGSize(
            width: max(1, size.width - 48),
            height: max(1, size.height - 48)
        )
        var width = (available.width / available.height) > aspect
            ? available.height * aspect
            : available.width
        width *= zoom
        let height = width / aspect
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width, height: height
        )
    }
}

private struct ScrollCatcher: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = CatcherView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CatcherView)?.onScroll = onScroll
    }

    final class CatcherView: NSView {
        var onScroll: ((CGFloat) -> Void)?
        override func scrollWheel(with event: NSEvent) {
            onScroll?(event.scrollingDeltaY)
        }
    }
}

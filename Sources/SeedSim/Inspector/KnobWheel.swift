import AppKit
import SwiftUI

/// Rotary dial standing in for the Watcher's physical knob. The encoder is
/// continuous, so there is no progress to show, only position and detents.
struct KnobWheel: View {
    var onDetent: (Int) -> Void

    @State private var angle: Double = -90
    @State private var residual: Double = 0
    @State private var grabOffset: Double?
    @State private var dragging = false

    private let detentDegrees: Double = 15
    private let diameter: CGFloat = 176
    private let ringWidth: CGFloat = 30
    private let handleSize: CGFloat = 26

    /// Centreline of the stroked track. Shapes are inset by half the ring width
    /// so the stroke sits inside the frame and this radius is exact.
    private var trackRadius: CGFloat { (diameter - ringWidth) / 2 }

    private var detentCount: Int { Int(360 / detentDegrees) }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: ringWidth)

            ticks

            Circle()
                .fill(.white)
                .frame(width: handleSize, height: handleSize)
                .overlay(Circle().strokeBorder(Color.black.opacity(0.12)))
                .shadow(color: .black.opacity(0.30), radius: 3, y: 1)
                .scaleEffect(dragging ? 1.14 : 1, anchor: .center)
                .offset(
                    x: trackRadius * cos(angle * .pi / 180),
                    y: trackRadius * sin(angle * .pi / 180)
                )
        }
        // Gesture must attach to the sized frame: anything wider (a centring
        // frame, say) becomes the gesture's coordinate space and skews every
        // angle we derive from value.location.
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .gesture(rotation)
        .animation(.interactiveSpring(duration: 0.16), value: angle)
        .animation(.easeOut(duration: 0.12), value: dragging)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// One mark per encoder detent, cut into the track itself.
    private var ticks: some View {
        ForEach(0..<detentCount, id: \.self) { index in
            Capsule()
                .fill(Color.primary.opacity(0.16))
                .frame(width: 2, height: ringWidth * 0.55)
                .offset(y: -trackRadius)
                .rotationEffect(.degrees(Double(index) * detentDegrees))
        }
    }

    private var rotation: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: diameter / 2, y: diameter / 2)
                let touch = atan2(value.location.y - center.y, value.location.x - center.x)
                    * 180 / .pi

                // Grab where the cursor landed rather than snapping the handle to
                // it, so the dial tracks the hand instead of jumping and dumping
                // a burst of detents on first contact.
                if grabOffset == nil {
                    grabOffset = angle - touch
                    dragging = true
                }
                let target = touch + (grabOffset ?? 0)

                var delta = target - angle
                if delta > 180 { delta -= 360 }
                if delta < -180 { delta += 360 }
                angle += delta
                residual += delta

                while abs(residual) >= detentDegrees {
                    let step: Double = residual > 0 ? 1 : -1
                    haptic()
                    onDetent(Int(step))
                    residual -= step * detentDegrees
                }
            }
            .onEnded { _ in
                dragging = false
                grabOffset = nil
                residual = 0
            }
    }

    /// Trackpad detent click. Silent on hardware without a haptic actuator.
    private func haptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}

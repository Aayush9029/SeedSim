import AppKit
import CLVGL
import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class LVGLEngine {
    private(set) var frame: CGImage?
    private(set) var fps: Int = 0

    let panel = Int(wsim_panel_size())

    private var timer: Timer?
    private var lastTick = Date()
    private var frameCount = 0
    private var fpsWindowStart = Date()
    private var releaseWork: DispatchWorkItem?

    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue
        | CGImageAlphaInfo.premultipliedFirst.rawValue)

    init() {
        wsim_init()
        start()
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func step() {
        let now = Date()
        let elapsed = UInt32(max(1, now.timeIntervalSince(lastTick) * 1000))
        lastTick = now
        wsim_tick(elapsed)
        frame = makeImage()

        frameCount += 1
        let window = now.timeIntervalSince(fpsWindowStart)
        if window >= 1 {
            fps = Int(Double(frameCount) / window)
            frameCount = 0
            fpsWindowStart = now
        }
    }

    private func makeImage() -> CGImage? {
        guard let base = wsim_framebuffer() else { return nil }
        let byteCount = panel * panel * 4
        let data = Data(bytes: base, count: byteCount)
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(
            width: panel, height: panel,
            bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: panel * 4,
            space: colorSpace, bitmapInfo: bitmapInfo,
            provider: provider, decode: nil,
            shouldInterpolate: false, intent: .defaultIntent
        )
    }

    // MARK: Input

    func rotate(_ detents: Int) {
        wsim_knob_rotate(Int32(detents))
    }

    func press() {
        wsim_knob_set_pressed(true)
        scheduleRelease(after: 0.09)
    }

    /// Exceeds LVGL's 400 ms LV_INDEV_DEF_LONG_PRESS_TIME.
    func longPress() {
        wsim_knob_set_pressed(true)
        scheduleRelease(after: 0.75)
    }

    func setPressed(_ down: Bool) {
        releaseWork?.cancel()
        wsim_knob_set_pressed(down)
    }

    private func scheduleRelease(after seconds: TimeInterval) {
        releaseWork?.cancel()
        let work = DispatchWorkItem { MainActor.assumeIsolated { wsim_knob_set_pressed(false) } }
        releaseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    func touch(x: Int, y: Int, down: Bool) {
        wsim_touch(Int32(x), Int32(y), down)
    }

    // MARK: Capture

    func saveScreenshot() {
        guard let png = pngData() else { return }
        let name = "watcher-panel-\(Int(Date().timeIntervalSince1970)).png"
        let url = FileManager.default
            .urls(for: .desktopDirectory, in: .userDomainMask)[0]
            .appending(path: name)
        try? png.write(to: url)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func copyPanelToPasteboard() {
        guard let frame else { return }
        let image = NSImage(cgImage: frame, size: NSSize(width: panel, height: panel))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    private func pngData() -> Data? {
        guard let frame else { return nil }
        let rep = NSBitmapImageRep(cgImage: frame)
        return rep.representation(using: .png, properties: [:])
    }
}

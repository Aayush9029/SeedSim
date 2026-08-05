import AppKit
import Foundation

struct FrameStyle: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let image: String
    let cutoutImage: String
    let imageWidth: Double
    let imageHeight: Double
    let centerXFrac: Double
    let centerYFrac: Double
    let radiusFrac: Double
    let panelPx: Double

    enum CodingKeys: String, CodingKey {
        case id, name, image
        case cutoutImage = "cutout_image"
        case imageWidth = "image_width"
        case imageHeight = "image_height"
        case centerXFrac = "center_x_frac"
        case centerYFrac = "center_y_frac"
        case radiusFrac = "radius_frac"
        case panelPx = "panel_px"
    }

    var aspect: Double { imageWidth / imageHeight }

    private struct Manifest: Decodable { let frames: [FrameStyle] }

    static let all: [FrameStyle] = {
        guard let url = Bundle.module.url(forResource: "frames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data)
        else {
            fatalError("frames.json missing or malformed")
        }
        return manifest.frames.sorted { $0.name < $1.name }
    }()

    static var `default`: FrameStyle {
        all.first { $0.id == "steel-white" } ?? all[0]
    }

    @MainActor private static var imageCache: [String: NSImage] = [:]

    @MainActor
    static func image(named name: String) -> NSImage? {
        if let cached = imageCache[name] { return cached }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else { return nil }
        imageCache[name] = image
        return image
    }
}

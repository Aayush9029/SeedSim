import Foundation
import Observation

struct SimDevice: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var model: String
    var version: String
    var booted: Bool = false
}

@MainActor
@Observable
final class DeviceStore {
    private(set) var devices: [SimDevice]
    var selection: SimDevice.ID?

    private static let storageKey = "watchersim.devices"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([SimDevice].self, from: data),
           !saved.isEmpty {
            devices = saved
        } else {
            devices = Self.seed
        }
        selection = devices.first?.id
    }

    private static let seed = [
        SimDevice(name: "SenseCAP Watcher", model: "ESP32-S3 + HX6538",
                  version: "1.1.7", booted: true),
        SimDevice(name: "Watcher (custom fw)", model: "sami build", version: "0.1.0"),
    ]

    var selected: SimDevice? {
        devices.first { $0.id == selection }
    }

    func add() {
        let device = SimDevice(
            name: "New Firmware",
            model: "sami build",
            version: "0.1.0"
        )
        devices.append(device)
        selection = device.id
        persist()
    }

    func duplicate(_ id: SimDevice.ID) {
        guard let source = devices.first(where: { $0.id == id }) else { return }
        var copy = source
        copy.id = UUID()
        copy.name = "\(source.name) copy"
        copy.booted = false
        devices.append(copy)
        selection = copy.id
        persist()
    }

    func rename(_ id: SimDevice.ID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = devices.firstIndex(where: { $0.id == id })
        else { return }
        devices[index].name = trimmed
        persist()
    }

    func delete(_ id: SimDevice.ID) {
        devices.removeAll { $0.id == id }
        if selection == id { selection = devices.first?.id }
        persist()
    }

    func resetToDefaults() {
        devices = Self.seed
        selection = devices.first?.id
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

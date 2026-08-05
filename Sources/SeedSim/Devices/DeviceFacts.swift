import Foundation

/// Values read off the connected unit and out of the firmware sources, so the
/// inspector shows the real board rather than placeholders.
enum DeviceFacts {
    struct Fact: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    static let silicon = [
        Fact(label: "MCU", value: "ESP32-S3 rev v0.2"),
        Fact(label: "Cores", value: "2 + LP @ 240 MHz"),
        Fact(label: "PSRAM", value: "8 MB octal @ 80 MHz"),
        Fact(label: "Flash", value: "32 MB W25Q256"),
        Fact(label: "Vision", value: "Himax HX6538 + Ethos-U55"),
    ]

    static let peripherals = [
        Fact(label: "Panel", value: "SPD2010 412×412 round"),
        Fact(label: "Touch", value: "SPD2010 TDDI @ 0x53"),
        Fact(label: "Speaker", value: "ES8311 @ 0x18"),
        Fact(label: "Microphone", value: "ES7243E @ 0x14"),
        Fact(label: "Camera", value: "OV5647 → Himax, SPI2 12 MHz"),
        Fact(label: "Expander", value: "PCA9535"),
    ]

    static let firmware = [
        Fact(label: "Stock app", value: "factory_firmware 1.1.7"),
        Fact(label: "ESP-IDF", value: "v5.2.1"),
        Fact(label: "LVGL", value: "8.4.0"),
        Fact(label: "App slot", value: "ota_0 @ 0x110000 · 12 MB"),
        Fact(label: "Identity", value: "nvsfactory @ 0x9000 · 200 KB"),
    ]

    static let unit = [
        Fact(label: "MAC", value: "44:1B:F6:85:9C:98"),
        Fact(label: "EUI", value: "2CF7F1C9811000A1"),
        Fact(label: "Serial", value: "113991315261100162"),
        Fact(label: "Batch", value: "1001114"),
    ]
}

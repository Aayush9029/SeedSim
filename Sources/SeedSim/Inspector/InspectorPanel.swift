import SwiftUI

struct InspectorPanel: View {
    @Bindable var engine: LVGLEngine

    var body: some View {
        Form {
            Section {
                KnobWheel(onDetent: { engine.rotate($0) })
                    .padding(.vertical, 12)
            }

            Section("Display") {
                LabeledContent("Panel", value: "\(engine.panel) × \(engine.panel)")
                LabeledContent("Colour", value: "RGB565")
                LabeledContent("FPS", value: "\(engine.fps)")
            }

            factSection("Silicon", DeviceFacts.silicon)
            factSection("Peripherals", DeviceFacts.peripherals)
            factSection("Firmware", DeviceFacts.firmware)
            factSection("This Unit", DeviceFacts.unit, monospaced: true)

            Section("Shortcuts") {
                shortcut("Rotate knob", "← →")
                shortcut("Press", "Return")
                shortcut("Long press", "Space")
                shortcut("Rotate knob", "Scroll")
                shortcut("Touch panel", "Click")
            }
        }
        .formStyle(.grouped)
    }

    private func factSection(
        _ title: String,
        _ facts: [DeviceFacts.Fact],
        monospaced: Bool = false
    ) -> some View {
        Section(title) {
            ForEach(facts) { fact in
                LabeledContent(fact.label) {
                    Text(fact.value)
                        .font(monospaced ? .caption.monospaced() : .callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private func shortcut(_ label: String, _ keys: String) -> some View {
        LabeledContent(label) {
            Text(keys)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

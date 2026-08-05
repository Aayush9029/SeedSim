import AppKit
import SwiftUI

struct ContentView: View {
    @State private var engine = LVGLEngine()
    @State private var store = DeviceStore()
    @State private var style: FrameStyle? = .default
    @State private var zoom: CGFloat = 1
    @State private var showInspector = true
    @State private var showFramePicker = false
    @State private var search = ""
    @State private var renaming: SimDevice?
    @State private var renameText = ""

    private let zoomRange: ClosedRange<CGFloat> = 0.4...2.5

    var body: some View {
        NavigationSplitView {
            SidebarView(
                store: store,
                search: $search,
                onRename: beginRename,
                onReveal: revealFirmware
            )
            .navigationSplitViewColumnWidth(min: 230, ideal: 265, max: 330)
        } detail: {
            DeviceStageView(engine: engine, style: style, zoom: zoom)
                .navigationTitle(store.selected?.name ?? "Simulator")
                .navigationSubtitle(store.selected.map { "\($0.model) · \($0.version)" } ?? "")
                .contextMenu { stageMenu }
        }
        .inspector(isPresented: $showInspector) {
            InspectorPanel(engine: engine)
                .inspectorColumnWidth(min: 260, ideal: 300, max: 380)
        }
        .toolbar { toolbarContent }
        .alert("Rename Firmware", isPresented: renameBinding) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renaming = nil }
            Button("Rename") {
                if let renaming { store.rename(renaming.id, to: renameText) }
                renaming = nil
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button { showFramePicker.toggle() } label: {
                FrameSwatchButtonLabel(style: style)
            }
            .buttonStyle(.plain)
            .help("Device frame")
            .popover(isPresented: $showFramePicker, arrowEdge: .bottom) {
                FrameSwatchPicker(selection: $style)
            }
        }

        ToolbarItemGroup(placement: .principal) {
            Button { setZoom(zoom - 0.2) } label: {
                Label("Zoom Out", systemImage: "minus.magnifyingglass")
            }
            .disabled(zoom <= zoomRange.lowerBound + 0.001)
            .help("Zoom out")

            Button { setZoom(1) } label: {
                Label("Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
            }
            .disabled(abs(zoom - 1) < 0.001)
            .help("Fit to window")

            Button { setZoom(zoom + 0.2) } label: {
                Label("Zoom In", systemImage: "plus.magnifyingglass")
            }
            .disabled(zoom >= zoomRange.upperBound - 0.001)
            .help("Zoom in")
        }

        ToolbarItem(placement: .primaryAction) {
            Menu {
                firmwareMenu
            } label: {
                Label("More", systemImage: "ellipsis")
            }
            .menuIndicator(.hidden)
            .help("Firmware actions")
        }

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(placement: .primaryAction) {
            Button { engine.saveScreenshot() } label: {
                Label("Screenshot", systemImage: "camera")
            }
            .help("Save panel screenshot to Desktop")
        }

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(placement: .primaryAction) {
            Button { showInspector.toggle() } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help("Toggle inspector")
        }
    }

    @ViewBuilder
    private var firmwareMenu: some View {
        if let device = store.selected {
            Button("Rename…") { beginRename(device) }
            Button("Duplicate") { store.duplicate(device.id) }
            Button("Delete", role: .destructive) { store.delete(device.id) }
                .disabled(store.devices.count <= 1)
            Divider()
        }
        Button("Reveal Firmware Source…") { revealFirmware() }
        Divider()
        Button("Save Screenshot…") { engine.saveScreenshot() }
        Button("Copy Panel Image") { engine.copyPanelToPasteboard() }
        Divider()
        Button("Reset Firmware List", role: .destructive) { store.resetToDefaults() }
    }


    @ViewBuilder
    private var stageMenu: some View {
        Button("Press Knob") { engine.press() }
        Button("Long Press Knob") { engine.longPress() }
        Divider()
        Menu("Frame") {
            ForEach(FrameStyle.all) { option in
                Button(option.name) { style = option }
            }
            Divider()
            Button("No Frame") { style = nil }
        }
        Menu("Zoom") {
            Button("Zoom In") { setZoom(zoom + 0.2) }
            Button("Zoom Out") { setZoom(zoom - 0.2) }
            Button("Actual Size") { setZoom(1) }
        }
        Divider()
        Button("Save Screenshot…") { engine.saveScreenshot() }
        Button("Copy Panel Image") { engine.copyPanelToPasteboard() }
    }

    private var renameBinding: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private func beginRename(_ device: SimDevice) {
        renameText = device.name
        renaming = device
    }

    private func setZoom(_ value: CGFloat) {
        zoom = min(max(value, zoomRange.lowerBound), zoomRange.upperBound)
    }

    private func revealFirmware() {
        let path = URL(fileURLWithPath: NSHomeDirectory())
            .appending(path: "Developer/personal/sami/packages/SenseCAP-Watcher-Firmware")
        NSWorkspace.shared.selectFile(
            path.path,
            inFileViewerRootedAtPath: path.deletingLastPathComponent().path
        )
    }

}

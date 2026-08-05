import AppKit
import SwiftUI

struct SidebarView: View {
    @Bindable var store: DeviceStore
    @Binding var search: String
    var onRename: (SimDevice) -> Void
    var onCopyIdentity: () -> Void
    var onReveal: () -> Void

    var body: some View {
        List(selection: $store.selection) {
            Section("Available") {
                ForEach(filtered) { device in
                    row(device)
                        .tag(device.id)
                        .contextMenu { menu(for: device) }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $search, placement: .sidebar, prompt: "Search firmware")
        .overlay {
            if filtered.isEmpty, !search.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 2) {
                Button { store.add() } label: {
                    Image(systemName: "plus")
                }
                .help("Add firmware")

                Button {
                    if let id = store.selection { store.delete(id) }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(store.selection == nil || store.devices.count <= 1)
                .help("Delete firmware")

                Spacer()

                Menu {
                    Button("Reveal Firmware Source…") { onReveal() }
                    Button("Copy Device Identity") { onCopyIdentity() }
                    Divider()
                    Button("Reset List", role: .destructive) { store.resetToDefaults() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.bar)
        }
    }

    private var filtered: [SimDevice] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return store.devices }
        return store.devices.filter {
            $0.name.localizedStandardContains(query)
                || $0.model.localizedStandardContains(query)
                || $0.version.localizedStandardContains(query)
        }
    }

    @ViewBuilder
    private func menu(for device: SimDevice) -> some View {
        Button("Rename…") { onRename(device) }
        Button("Duplicate") { store.duplicate(device.id) }
        Divider()
        Button("Copy Device Identity") { onCopyIdentity() }
        Button("Reveal Firmware Source…") { onReveal() }
        Divider()
        Button("Delete", role: .destructive) { store.delete(device.id) }
            .disabled(store.devices.count <= 1)
    }

    private func row(_ device: SimDevice) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "smallcircle.filled.circle")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(device.booted ? Color.accentColor : Color.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(device.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(device.model)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(device.version)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 3)
    }
}

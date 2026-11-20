import SwiftUI

struct AccentColorPickerView: View {
    @ObservedObject private var store = AccentColorStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    previewCard
                } header: {
                    Text("Preview")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(AccentColorStore.presets) { preset in
                            presetButton(preset)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Presets")
                }

                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        sliderRow(label: "Hue", value: $store.hue, color: Color(hue: store.hue, saturation: 1, brightness: 1))
                        sliderRow(label: "Saturation", value: $store.saturation, color: store.accentColor)
                        sliderRow(label: "Brightness", value: $store.brightness, color: store.accentColor)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Fine Tune")
                }
            }
            .tint(store.accentColor)
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(store.accentColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "paintpalette.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Byte External")
                    .font(.headline)
                Text("Current accent color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(store.accentColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.vertical, 4)
    }

    private func presetButton(_ preset: AccentColorStore.AccentPreset) -> some View {
        let isSelected = abs(store.hue - preset.hue) < 0.02
            && abs(store.saturation - preset.saturation) < 0.05
            && abs(store.brightness - preset.brightness) < 0.05

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.applyPreset(preset)
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(preset.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(isSelected ? 0.8 : 0), lineWidth: 2.5)
                    )
                    .shadow(color: isSelected ? preset.color.opacity(0.5) : .clear, radius: 6)
                Text(preset.name)
                    .font(.caption2.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func sliderRow(label: String, value: Binding<CGFloat>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", value.wrappedValue * 100))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...1)
                .tint(color)
        }
    }
}

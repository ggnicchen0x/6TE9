import SwiftUI

struct AccentColorPickerView: View {
    @ObservedObject private var store = AccentColorStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var hexInput = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    previewCard
                } header: {
                    Text("Preview")
                }

                Section {
                    HStack(spacing: 12) {
                        Text("#")
                            .font(.title3.weight(.bold).monospaced())
                            .foregroundStyle(.secondary)

                        TextField("7B4AEB", text: $hexInput)
                            .font(.title3.monospaced())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: hexInput) { val in
                                let cleaned = val.replacingOccurrences(of: "#", with: "")
                                    .filter { $0.isHexDigit }
                                if cleaned != val {
                                    hexInput = String(cleaned.prefix(6))
                                }
                                if cleaned.count == 6 {
                                    store.applyHex(cleaned)
                                }
                            }

                        Button {
                            store.applyHex(hexInput)
                        } label: {
                            Text("Apply")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(store.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(store.hexString)
                            .font(.caption.monospaced().weight(.medium))
                            .foregroundStyle(.primary)

                        Button {
                            UIPasteboard.general.string = store.hexString
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Hex Code")
                }

                Section {
                    sliderRow(label: "Red", value: $store.red, color: .red,
                              displayValue: Int(round(store.red * 255)))
                    sliderRow(label: "Green", value: $store.green, color: .green,
                              displayValue: Int(round(store.green * 255)))
                    sliderRow(label: "Blue", value: $store.blue, color: .blue,
                              displayValue: Int(round(store.blue * 255)))
                } header: {
                    Text("RGB")
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
            .onAppear {
                hexInput = store.hexString.replacingOccurrences(of: "#", with: "")
            }
            .onChange(of: [store.red, store.green, store.blue]) { _ in
                hexInput = store.hexString.replacingOccurrences(of: "#", with: "")
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
                Text(store.hexString)
                    .font(.caption.monospaced())
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

    private func sliderRow(label: String, value: Binding<CGFloat>, color: Color, displayValue: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(displayValue)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...1)
                .tint(color)
        }
        .padding(.vertical, 2)
    }
}

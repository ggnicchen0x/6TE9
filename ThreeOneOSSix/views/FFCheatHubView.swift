import SwiftUI

struct FFCheatHubView: View {
    @Environment(\.appLanguage) private var language
    @State private var selectedVariant: FFGameVariant = .ffmax
    @State private var isBusy = false
    @State private var actionAlert: FFActionAlert?
    @State private var entranceShown = false
    @State private var activePatches: [UUID: PatchTransactionReceipt] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void

    private var entries: [FFCheatEntry] {
        FFPatchCatalog.entries(for: selectedVariant)
    }

    private var sections: [(section: FFCheatSection, entries: [FFCheatEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.category.section }
        return FFCheatSection.allCases.compactMap { section in
            guard let items = grouped[section], !items.isEmpty else { return nil }
            return (section, items)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    variantPicker
                    statusBanner
                    ForEach(sections, id: \.section.id) { group in
                        sectionCard(group.section, entries: group.entries)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Byte External")
            .navigationBarTitleDisplayMode(.inline)
            .opacity(entranceShown ? 1 : 0)
            .offset(y: entranceShown ? 0 : 10)
            .onAppear {
                guard !entranceShown, !reduceMotion else {
                    entranceShown = true
                    return
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    entranceShown = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onOpenSettings()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .alert(item: $actionAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var variantPicker: some View {
        HStack(spacing: 0) {
            ForEach(FFGameVariant.allCases) { variant in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedVariant = variant
                    }
                } label: {
                    Text(variant.shortName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedVariant == variant ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedVariant == variant {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppTheme.accent)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.badge.checkmark.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedVariant.displayName)
                    .font(.headline)
                Text(selectedVariant.rawValue)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(entries.count) patches")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    AppTheme.accent.opacity(0.12),
                    in: Capsule()
                )
        }
        .padding(14)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func sectionCard(_ section: FFCheatSection, entries: [FFCheatEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text(section.displayName)
                    .font(.subheadline.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            let categories = Dictionary(grouping: entries) { $0.category }
            let orderedCategories = FFCheatCategory.allCases.filter { categories[$0] != nil }

            ForEach(orderedCategories) { category in
                if let categoryEntries = categories[category] {
                    cheatCard(category: category, entries: categoryEntries)
                }
            }
        }
    }

    private func cheatCard(category: FFCheatCategory, entries: [FFCheatEntry]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.body.weight(.semibold))
                    Text(entrySubtitle(entries))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)

            Divider()
                .padding(.horizontal, 14)

            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    patchRow(entry)
                    if entry.id != entries.last?.id {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
        }
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func entrySubtitle(_ entries: [FFCheatEntry]) -> String {
        let variants = entries.map { $0.hasAntenna ? "Antenna" : "No Antenna" }
        return variants.joined(separator: " · ")
    }

    private func isActive(_ entry: FFCheatEntry) -> Bool {
        activePatches[entry.id] != nil
    }

    private func patchRow(_ entry: FFCheatEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.hasAntenna ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                .font(.caption)
                .foregroundStyle(entry.hasAntenna ? AppTheme.accent : .secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.hasAntenna ? "With Antenna" : "Without Antenna")
                    .font(.subheadline)
                Text(entry.filename)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { isActive(entry) },
                set: { newValue in
                    if newValue {
                        applyPatch(entry)
                    } else {
                        revertPatch(entry)
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
            .labelsHidden()
            .disabled(isBusy)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func applyPatch(_ entry: FFCheatEntry) {
        guard !isBusy else { return }
        isBusy = true
        Task.detached(priority: .userInitiated) {
            do {
                guard let data = FFPatchCatalog.patchData(for: entry) else {
                    throw PatchPackageError.unsupportedFormat
                }
                let decoded = try PatchPackageCodec.decode(data, password: nil)
                let receipt = try DevicePatchService.apply(project: decoded.project)
                await MainActor.run {
                    activePatches[entry.id] = receipt
                    isBusy = false
                    actionAlert = FFActionAlert(
                        title: "Enabled",
                        message: "\(entry.category.displayName) patch applied to device."
                    )
                }
            } catch {
                await MainActor.run {
                    isBusy = false
                    actionAlert = FFActionAlert(
                        title: "Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func revertPatch(_ entry: FFCheatEntry) {
        guard !isBusy, let receipt = activePatches[entry.id] else { return }
        isBusy = true
        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    activePatches.removeValue(forKey: entry.id)
                    isBusy = false
                    actionAlert = FFActionAlert(
                        title: "Reverted",
                        message: "\(entry.category.displayName) patch removed from device."
                    )
                }
            } catch {
                await MainActor.run {
                    isBusy = false
                    actionAlert = FFActionAlert(
                        title: "Revert Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
}

private struct FFActionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

import SwiftUI

private let cardFill = Color(white: 0.11)

struct FFCheatHubView: View {
    @Environment(\.appLanguage) private var language
    @AppStorage("selectedGame") private var selectedGameID = FFGameVariant.ffth.rawValue
    @State private var isBusy = false
    @State private var actionAlert: FFActionAlert?
    @State private var entranceShown = false
    @State private var activePatches: [String: PatchTransactionReceipt] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void

    private var selectedVariant: FFGameVariant {
        FFGameVariant(rawValue: selectedGameID) ?? .ffth
    }

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
                VStack(spacing: 16) {
                    gameHeader
                    ForEach(sections, id: \.section.id) { group in
                        sectionBlock(group.section, entries: group.entries)
                    }
                    if entries.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("Cheats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(white: 0.06), for: .navigationBar)
            .opacity(entranceShown ? 1 : 0)
            .offset(y: entranceShown ? 0 : 10)
            .onAppear {
                refreshActiveState()
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

    // MARK: - Game Header

    private var gameHeader: some View {
        HStack(spacing: 14) {
            Image(selectedVariant == .ffth ? "FFIcon" : "FFMaxIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedVariant.displayName)
                    .font(.headline)
                Text(selectedVariant.rawValue)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entries.count)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundColor(AppTheme.accent)
                Text("patches")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.015), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                HStack(spacing: 0) {
                    AppTheme.accent.frame(width: 3.5)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        )
    }

    // MARK: - Section

    private func sectionBlock(_ section: FFCheatSection, entries: [FFCheatEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 22, height: 22)
                    .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(section.displayName)
                    .font(.subheadline.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entries.count)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)

            let categories = Dictionary(grouping: entries) { $0.category }
            let orderedCategories = FFCheatCategory.allCases.filter { categories[$0] != nil }

            ForEach(orderedCategories) { category in
                if let categoryEntries = categories[category] {
                    categoryCard(category: category, entries: categoryEntries)
                }
            }
        }
    }

    // MARK: - Category Card

    private func categoryCard(category: FFCheatCategory, entries: [FFCheatEntry]) -> some View {
        VStack(spacing: 0) {
            // Category header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: category.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("\(entries.count) variant\(entries.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                let activeCount = entries.filter { isActive($0) }.count
                if activeCount > 0 {
                    Text("\(activeCount) ON")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accent.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            ForEach(entries) { entry in
                Divider()
                    .padding(.leading, 14)
                patchRow(entry)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }

    // MARK: - Patch Row

    private func patchRow(_ entry: FFCheatEntry) -> some View {
        HStack(spacing: 14) {
            Image(systemName: entry.hasAntenna
                  ? "antenna.radiowaves.left.and.right"
                  : "antenna.radiowaves.left.and.right.slash")
                .font(.caption.weight(.medium))
                .foregroundStyle(entry.hasAntenna ? AppTheme.accent : Color(white: 0.4))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.hasAntenna ? "With Antenna" : "Without Antenna")
                    .font(.subheadline.weight(.medium))
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No patches available")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Select a game in your Profile to load patches.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Patch Logic

    private func isActive(_ entry: FFCheatEntry) -> Bool {
        activePatches[entry.id] != nil
    }

    private func recoverReceipt(for entry: FFCheatEntry) -> PatchTransactionReceipt? {
        guard let data = FFPatchCatalog.patchData(for: entry),
              let decoded = try? PatchPackageCodec.decode(data, password: nil) else { return nil }
        return DevicePatchService.latestReceipt(projectID: decoded.project.id)
    }

    private func refreshActiveState() {
        for entry in FFPatchCatalog.allEntries() {
            if let receipt = recoverReceipt(for: entry) {
                activePatches[entry.id] = receipt
            } else {
                activePatches.removeValue(forKey: entry.id)
            }
        }
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
                let receipt: PatchTransactionReceipt
                do {
                    receipt = try DevicePatchService.apply(project: decoded.project)
                } catch PatchPackageError.projectAlreadyApplied {
                    if let existing = DevicePatchService.latestReceipt(projectID: decoded.project.id) {
                        try DevicePatchService.restore(receipt: existing)
                    }
                    receipt = try DevicePatchService.apply(project: decoded.project)
                } catch {
                    ContainerStore.refreshLaunchServicesSnapshot()
                    receipt = try DevicePatchService.apply(project: decoded.project)
                }
                await MainActor.run {
                    activePatches[entry.id] = receipt
                    isBusy = false
                    actionAlert = FFActionAlert(
                        title: "Enabled",
                        message: "\(entry.category.displayName) patch applied."
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
        guard !isBusy else { return }
        let receipt = activePatches[entry.id] ?? recoverReceipt(for: entry)
        guard let receipt else { return }
        isBusy = true
        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    activePatches.removeValue(forKey: entry.id)
                    isBusy = false
                    actionAlert = FFActionAlert(
                        title: "Reverted",
                        message: "\(entry.category.displayName) patch removed."
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

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
                VStack(spacing: 14) {
                    gameCard
                    ForEach(sections, id: \.section.id) { group in
                        sectionBlock(group.section, entries: group.entries)
                    }
                    if entries.isEmpty {
                        emptyCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(
                ZStack {
                    Color.black
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.35)
                    )
                    .ignoresSafeArea()
                }
            )
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
                    Button { onOpenSettings() } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(AppTheme.accent)
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

    // MARK: - Game Card

    private var gameCard: some View {
        HStack(spacing: 12) {
            Image(selectedVariant == .ffth ? "FFIcon" : "FFMaxIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedVariant.displayName)
                    .font(.callout.weight(.semibold))
                Text(selectedVariant.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
                Text("Active")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.12), in: Capsule())
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.035), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }
        )
    }

    // MARK: - Section

    private func sectionBlock(_ section: FFCheatSection, entries: [FFCheatEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.displayName)
                .font(.footnote.weight(.bold))

            let categories = Dictionary(grouping: entries) { $0.category }
            let orderedCategories = FFCheatCategory.allCases.filter { categories[$0] != nil }

            VStack(spacing: 0) {
                ForEach(Array(orderedCategories.enumerated()), id: \.element.id) { index, category in
                    if let categoryEntries = categories[category] {
                        if index > 0 {
                            Divider().padding(.leading, 14)
                        }
                        categoryBlock(category: category, entries: categoryEntries)
                    }
                }
            }
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
                }
            )
        }
    }

    // MARK: - Category Block

    private func categoryBlock(category: FFCheatCategory, entries: [FFCheatEntry]) -> some View {
        VStack(spacing: 0) {
            if entries.count == 1, let entry = entries.first {
                singleEntryRow(category: category, entry: entry)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.footnote)
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 26)
                    Text(category.displayName)
                        .font(.footnote.weight(.semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)

                ForEach(entries) { entry in
                    Divider().padding(.leading, 50)
                    patchRow(entry)
                }
            }
        }
    }

    // MARK: - Single Entry Row

    private func singleEntryRow(category: FFCheatCategory, entry: FFCheatEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.footnote)
                .foregroundColor(AppTheme.accent)
                .frame(width: 26)
            Text(category.displayName)
                .font(.footnote.weight(.semibold))
            Spacer(minLength: 4)
            patchToggle(entry)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Patch Row

    private func patchRow(_ entry: FFCheatEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.hasAntenna
                  ? "antenna.radiowaves.left.and.right"
                  : "antenna.radiowaves.left.and.right.slash")
                .font(.caption2)
                .foregroundColor(entry.hasAntenna ? AppTheme.accent.opacity(0.7) : Color(white: 0.35))
                .frame(width: 26)

            Text(entry.hasAntenna ? "With Antenna" : "Without Antenna")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer(minLength: 4)
            patchToggle(entry)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Toggle

    private func patchToggle(_ entry: FFCheatEntry) -> some View {
        Toggle("", isOn: Binding(
            get: { isActive(entry) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if newValue {
                        applyPatch(entry)
                    } else {
                        revertPatch(entry)
                    }
                }
            }
        ))
        .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
        .labelsHidden()
        .disabled(isBusy)
        .scaleEffect(0.85)
        .fixedSize()
    }

    // MARK: - Empty

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("No patches available")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }
        )
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
                try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
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

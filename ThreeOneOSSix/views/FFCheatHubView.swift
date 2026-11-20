import SwiftUI

private let cardFill = Color(white: 0.11)

struct FFCheatHubView: View {
    @Environment(\.appLanguage) private var language
    @AppStorage("selectedGame") private var selectedGameID = FFGameVariant.ffth.rawValue
    @State private var isBusy = false
    @State private var busyEntryID: String?
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    gameCard
                    ForEach(entries) { entry in
                        patchCard(entry)
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

    // MARK: - Patch Card

    private func patchCard(_ entry: FFCheatEntry) -> some View {
        let loaded = isActive(entry)
        let loading = busyEntryID == entry.id

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(loaded ? AppTheme.accent.opacity(0.15) : Color(white: 0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.category.icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(loaded ? AppTheme.accent : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entryDisplayName(entry))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if loading {
                        Text(loaded ? "Removing..." : "Loading...")
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                    } else {
                        Text(loaded ? "Loaded" : "Not loaded")
                            .font(.caption)
                            .foregroundColor(loaded ? .green : .secondary)
                    }

                    Text("Safe")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12), in: Capsule())
                }
            }

            Spacer(minLength: 4)

            if loading {
                ProgressView()
                    .tint(AppTheme.accent)
                    .scaleEffect(0.8)
                    .frame(width: 64)
            } else {
                Button {
                    if loaded {
                        revertPatch(entry)
                    } else {
                        applyPatch(entry)
                    }
                } label: {
                    Text(loaded ? "Unload" : "Load")
                        .font(.caption.weight(.bold))
                        .foregroundColor(loaded ? .primary : AppTheme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(loaded ? Color(white: 0.2) : AppTheme.accent.opacity(0.15))
                        )
                }
                .disabled(isBusy)
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
                    .strokeBorder(
                        loaded ? AppTheme.accent.opacity(0.2) : Color.white.opacity(0.06),
                        lineWidth: 0.5
                    )
            }
        )
        .animation(.easeInOut(duration: 0.25), value: loaded)
        .animation(.easeInOut(duration: 0.2), value: loading)
    }

    // MARK: - Display Name

    private func entryDisplayName(_ entry: FFCheatEntry) -> String {
        let base = entry.category.displayName
        if entry.hasAntenna {
            return base + " + Antenna"
        }
        return base
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
        busyEntryID = entry.id
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activePatches[entry.id] = receipt
                        isBusy = false
                        busyEntryID = nil
                    }
                }
            } catch {
                await MainActor.run {
                    isBusy = false
                    busyEntryID = nil
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
        busyEntryID = entry.id
        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt, allowChangedTargets: true)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activePatches.removeValue(forKey: entry.id)
                        isBusy = false
                        busyEntryID = nil
                    }
                }
            } catch {
                await MainActor.run {
                    isBusy = false
                    busyEntryID = nil
                    actionAlert = FFActionAlert(
                        title: "Unload Failed",
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

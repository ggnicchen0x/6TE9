import SwiftUI

private let cardFill = Color(white: 0.11)

private enum CategoryTab: String, CaseIterable, Identifiable {
    case aimbot
    case hologram

    var id: String { rawValue }

    var label: String {
        switch self {
        case .aimbot: return "Aimbot"
        case .hologram: return "Hologram"
        }
    }

    var icon: String {
        switch self {
        case .aimbot: return "scope"
        case .hologram: return "sparkles"
        }
    }
}

private enum AimbotSubTab: String, CaseIterable, Identifiable {
    case head
    case neck
    case chest
    case drag

    var id: String { rawValue }

    var label: String {
        switch self {
        case .head: return "Head"
        case .neck: return "Neck"
        case .chest: return "Chest"
        case .drag: return "Drag"
        }
    }

    var categories: [FFCheatCategory] {
        switch self {
        case .head: return [.aimbotHead]
        case .neck: return [.aimbotNeck]
        case .chest: return [.aimbotChest]
        case .drag: return [.aimbotDrag]
        }
    }
}

struct FFCheatHubView: View {
    @Environment(\.appLanguage) private var language
    @AppStorage("selectedGame") private var selectedGameID = FFGameVariant.ffth.rawValue
    @State private var isBusy = false
    @State private var busyEntryID: String?
    @State private var actionAlert: FFActionAlert?
    @State private var entranceShown = false
    @State private var activePatches: [String: PatchTransactionReceipt] = [:]
    @State private var selectedCategory: CategoryTab = .aimbot
    @State private var selectedAimbotSub: AimbotSubTab = .head
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onOpenSettings: () -> Void

    private var selectedVariant: FFGameVariant {
        FFGameVariant(rawValue: selectedGameID) ?? .ffth
    }

    private var allEntries: [FFCheatEntry] {
        FFPatchCatalog.entries(for: selectedVariant)
    }

    private var filteredEntries: [FFCheatEntry] {
        switch selectedCategory {
        case .aimbot:
            let cats = selectedAimbotSub.categories
            return allEntries.filter { cats.contains($0.category) }
        case .hologram:
            return allEntries.filter { $0.category == .holoWeapons || $0.category == .holoCharacter }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    gameCard
                    categoryTabBar
                    if selectedCategory == .aimbot {
                        aimbotSubTabBar
                    }
                    ForEach(filteredEntries) { entry in
                        patchCard(entry)
                    }
                    if filteredEntries.isEmpty {
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
        .background(accentBarCard(cornerRadius: 14, barColor: AppTheme.accent))
    }

    // MARK: - Category Tabs

    private var categoryTabBar: some View {
        HStack(spacing: 10) {
            ForEach(CategoryTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.caption.weight(.semibold))
                        Text(tab.label)
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(selectedCategory == tab ? .black : .white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selectedCategory == tab ? AppTheme.accent : Color(white: 0.16))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(
                                selectedCategory == tab ? Color.clear : Color.white.opacity(0.08),
                                lineWidth: 0.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var aimbotSubTabBar: some View {
        HStack(spacing: 8) {
            ForEach(AimbotSubTab.allCases) { sub in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedAimbotSub = sub
                    }
                } label: {
                    Text(sub.label)
                        .font(.caption.weight(.bold))
                        .foregroundColor(selectedAimbotSub == sub ? .black : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedAimbotSub == sub ? AppTheme.accent : Color(white: 0.14))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    selectedAimbotSub == sub ? Color.clear : Color.white.opacity(0.06),
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Accent Bar Card

    private func accentBarCard(cornerRadius: CGFloat, barColor: Color = AppTheme.accent) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(cardFill)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.035), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            HStack(spacing: 0) {
                barColor
                    .frame(width: 3.5)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    // MARK: - Patch Card

    private func patchCard(_ entry: FFCheatEntry) -> some View {
        let loaded = isActive(entry)
        let loading = busyEntryID == entry.id

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(loaded ? Color.green.opacity(0.15) : Color(white: 0.16))
                    .frame(width: 48, height: 48)
                Image(systemName: entry.category.icon)
                    .font(.body.weight(.semibold))
                    .foregroundColor(loaded ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entryDisplayName(entry))
                    .font(.callout.weight(.bold))

                HStack(spacing: 8) {
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
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12), in: Capsule())
                }
            }

            Spacer(minLength: 8)

            if loading {
                ProgressView()
                    .tint(AppTheme.accent)
                    .scaleEffect(0.85)
                    .frame(width: 72)
            } else {
                Button {
                    if loaded {
                        revertPatch(entry)
                    } else {
                        applyPatch(entry)
                    }
                } label: {
                    Text(loaded ? "Unload" : "Load")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(loaded ? .white : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(loaded ? AppTheme.accent : Color(white: 0.22))
                        )
                }
                .disabled(isBusy)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            loaded
                ? AnyView(accentBarCard(cornerRadius: 16, barColor: .green))
                : AnyView(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(cardFill)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.02), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                    }
                )
        )
        .animation(.easeInOut(duration: 0.25), value: loaded)
        .animation(.easeInOut(duration: 0.2), value: loading)
    }

    // MARK: - Display Name

    private func entryDisplayName(_ entry: FFCheatEntry) -> String {
        let base: String
        switch entry.category {
        case .aimbotHead:    base = "Aim Head"
        case .aimbotNeck:    base = "Aim Neck"
        case .aimbotChest:   base = "Aim Chest"
        case .aimbotDrag:    base = "Aim Drag"
        case .holoWeapons:   base = "Holo Weapons"
        case .holoCharacter: base = "Holo Character"
        }
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

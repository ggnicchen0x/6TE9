import SwiftUI

private let cardFill = AppTheme.cardFill

private enum CategoryTab: String, CaseIterable, Identifiable {
    case aimbot
    case hologram

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .aimbot: return "cheats.tab.aimbot"
        case .hologram: return "cheats.tab.hologram"
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

    var labelKey: String {
        switch self {
        case .head: return "cheats.sub.head"
        case .neck: return "cheats.sub.neck"
        case .chest: return "cheats.sub.chest"
        case .drag: return "cheats.sub.drag"
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
    @State private var catalogLoaded = false
    @State private var catalogLoading = false
    @State private var isSafe = true
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
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
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
            .navigationTitle(language.text("cheats.title"))
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
            .task {
                guard !catalogLoaded else { return }
                catalogLoading = true
                await FFPatchCatalog.loadCatalogIfNeeded()
                catalogLoading = false
                catalogLoaded = true
                isSafe = CloudPatchService.shared.isSafe
                refreshActiveState()
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
                    dismissButton: .default(Text(language.text("common.ok")))
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
                    .font(.callout.weight(.medium))
                Text(selectedVariant.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
                Text(language.text("cheats.active"))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(AppTheme.statusGreen)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.statusGreen.opacity(0.12), in: Capsule())
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
                            .font(.caption.weight(.medium))
                        Text(language.text(tab.labelKey))
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(selectedCategory == tab ? .black : .white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selectedCategory == tab ? AppTheme.accent : Color(white: 0.10))
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
                    Text(language.text(sub.labelKey))
                        .font(.caption.weight(.medium))
                        .foregroundColor(selectedAimbotSub == sub ? .black : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedAimbotSub == sub ? AppTheme.accent : Color(white: 0.09))
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
                        colors: [Color.white.opacity(AppTheme.cardGradientOpacity), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(AppTheme.cardBorderOpacity), lineWidth: 0.5)
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
                    .fill(loaded ? AppTheme.statusGreen.opacity(0.15) : Color(white: 0.10))
                    .frame(width: 48, height: 48)
                Image(systemName: entry.category.icon)
                    .font(.body.weight(.medium))
                    .foregroundColor(loaded ? AppTheme.statusGreen : .secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entryDisplayName(entry))
                    .font(.callout.weight(.medium))

                HStack(spacing: 8) {
                    if loading {
                        Text(loaded ? language.text("cheats.removing") : language.text("cheats.loading"))
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                    } else {
                        Text(loaded ? language.text("cheats.loaded") : language.text("cheats.not_loaded"))
                            .font(.caption)
                            .foregroundColor(loaded ? AppTheme.statusGreen : .secondary)
                    }

                    Text(isSafe ? language.text("cheats.safe") : language.text("cheats.unsafe"))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(isSafe ? AppTheme.statusGreen : .red)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background((isSafe ? AppTheme.statusGreen : Color.red).opacity(0.12), in: Capsule())
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
                    Text(loaded ? language.text("cheats.unload") : language.text("cheats.load"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(loaded ? AppTheme.accent : Color(white: 0.14))
                        )
                }
                .disabled(isBusy)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            loaded
                ? AnyView(accentBarCard(cornerRadius: 16, barColor: AppTheme.statusGreen))
                : AnyView(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(cardFill)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(AppTheme.cardGradientOpacity), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(AppTheme.cardBorderOpacity), lineWidth: 0.5)
                    }
                )
        )
        .animation(.easeInOut(duration: 0.25), value: loaded)
        .animation(.easeInOut(duration: 0.2), value: loading)
    }

    // MARK: - Display Name

    private func entryDisplayName(_ entry: FFCheatEntry) -> String {
        if !entry.displayLabel.isEmpty {
            return entry.displayLabel
        }
        let base: String
        switch entry.category {
        case .aimbotHead:    base = language.text("cheats.aim_head")
        case .aimbotNeck:    base = language.text("cheats.aim_neck")
        case .aimbotChest:   base = language.text("cheats.aim_chest")
        case .aimbotDrag:    base = language.text("cheats.aim_drag")
        case .holoWeapons:   base = language.text("cheats.holo_weapons")
        case .holoCharacter: base = language.text("cheats.holo_character")
        }
        if entry.hasAntenna {
            return base + language.text("cheats.antenna_suffix")
        }
        return base
    }

    // MARK: - Empty

    private var emptyCard: some View {
        VStack(spacing: 10) {
            if catalogLoading {
                ProgressView()
                    .tint(AppTheme.accent)
                Text(language.text("cheats.loading_catalog"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text(language.text("cheats.empty"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if FFPatchCatalog.lastFetchError != nil {
                    Button {
                        Task {
                            catalogLoading = true
                            await FFPatchCatalog.refreshCatalog()
                            catalogLoading = false
                            isSafe = CloudPatchService.shared.isSafe
                            refreshActiveState()
                        }
                    } label: {
                        Text(language.text("cheats.retry"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.top, 4)
                }
            }
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
        guard let data = CloudPatchService.shared.cachedPatchData(featureID: entry.featureID) else { return nil }
        guard let decoded = try? PatchPackageCodec.decode(data, password: nil) else { return nil }
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
                let data = try await FFPatchCatalog.patchData(for: entry)
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
                        title: language.text("cheats.failed"),
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
                        title: language.text("cheats.unload_failed"),
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

import SwiftUI

/// The landing page: a local feature hub instead of a remote repository feed.
/// Everything that used to occupy its own tab bar slot (market, sources,
/// installed patches) is reachable from here, keeping the bottom bar at five
/// fixed destinations.
struct FeatureHubView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var taskCenter: MigrationTaskCenter
    // Page-level single entrance: the whole card list fades/slides in once.
    // Per-row @State animations would replay when List recycles rows.
    @State private var entranceShown = false
    let onSelectTab: (AppSection) -> Void
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(language.text("home.version"), value: appVersion)
                    LabeledContent(
                        language.text("home.backend"),
                        value: SandboxAccess.backend.displayName
                    )
                    if SandboxAccess.needsWorseQuery {
                        LabeledContent(
                            language.text("home.app_group"),
                            value: appGroupText
                        )
                        if SandboxAccess.appGroup == nil {
                            Text(language.text("home.app_group_warning"))
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text(language.text("home.status"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.text("tab.features"))
            .navigationBarTitleDisplayMode(.inline)
            .opacity(entranceShown ? 1 : 0)
            .offset(y: entranceShown ? 0 : 10)
            .onAppear {
                guard !entranceShown, !reduceMotion else {
                    entranceShown = true
                    taskCenter.refreshPendingResumes()
                    return
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    entranceShown = true
                }
                taskCenter.refreshPendingResumes()
            }
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
        }
    }

    private func card(
        _ titleKey: String,
        detail: String,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(language.text(titleKey))
                    .foregroundStyle(.primary)
                Text(language.text(detail))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var appVersion: String { AppInfo.appVersion }

    private var appGroupText: String {
        SandboxAccess.appGroup ?? language.text("home.app_group_missing")
    }
}
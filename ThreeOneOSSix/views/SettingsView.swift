import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage("sound.effects.enabled") private var soundEffectsEnabled = true


    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Compass").font(.headline)
                            Text("v\(appVersion)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(language.text("settings.language")) {
                    // Inline, not segmented: with four languages the segmented
                    // control truncates "Tiếng Việt" to "Tiếng…" on a narrow
                    // device. Inline renders one row per language under the
                    // section header, which is also the platform idiom for a
                    // list this long.
                    Picker(language.text("settings.language"), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Toggle(isOn: $soundEffectsEnabled) {
                        Label(
                            language.text("settings.sound_effects"),
                            systemImage: "speaker.wave.2"
                        )
                    }
                    // W5d: store-artwork fallback for icon-less migration
                    // rows; off keeps the app fully offline.
                    Toggle(isOn: Binding(
                        get: { StoreIconFallbackService.isEnabled },
                        set: { StoreIconFallbackService.setEnabled($0) }
                    )) {
                        Label(
                            language.text("settings.storeicon_fallback"),
                            systemImage: "network"
                        )
                    }
                } header: {
                    Text(language.text("settings.sound_effects"))
                } footer: {
                    Text(language.text("settings.sound_effects_footer"))
                }


                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                    LabeledContent(language.text("settings.access_backend"), value: SandboxAccess.backend.displayName)
                    LabeledContent(language.text("settings.app_group"), value: appGroupStatus)
                    NavigationLink {
                        SandboxDiagnosticsView()
                    } label: {
                        Label(language.text("sandbox.diag.title"), systemImage: "stethoscope")
                    }
                }

            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private var appGroupStatus: String {
        guard SandboxAccess.needsWorseQuery else { return "—" }
        return SandboxAccess.appGroup ?? language.text("settings.app_group_missing")
    }

    }
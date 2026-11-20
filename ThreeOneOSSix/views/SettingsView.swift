import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage("sound.effects.enabled") private var soundEffectsEnabled = true
    @AppStorage(FeatureVisibility.developerModeStorageKey) private var experimentalFeaturesEnabled = false
    var onLogout: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Byte External").font(.headline)
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
                    NavigationLink {
                        BackupCenterView()
                    } label: {
                        Label(
                            language.text("backup.title"),
                            systemImage: "externaldrive.badge.timemachine"
                        )
                    }

                    RespringButton()
                } header: {
                    Text(language.text("settings.backup"))
                }

                Section {
                    NavigationLink {
                        AccentColorPickerView()
                    } label: {
                        HStack {
                            Label("Accent Color", systemImage: "paintpalette.fill")
                            Spacer()
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 22, height: 22)
                        }
                    }
                } header: {
                    Text("Appearance")
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


                Section {
                    Toggle(isOn: $experimentalFeaturesEnabled) {
                        Label(
                            language.text("settings.experimental"),
                            systemImage: "flask"
                        )
                    }
                } header: {
                    Text(language.text("settings.experimental_header"))
                } footer: {
                    Text(language.text("settings.experimental_footer"))
                }

                if WallpaperFeatureSupportPolicy.isSupported(
                    major: AppInfo.versionTuple.major
                ) {
                    Section {
                        NavigationLink {
                            WallpaperResetSettingsView()
                        } label: {
                            Label(
                                language.text("wallpaper.reset"),
                                systemImage: "arrow.counterclockwise"
                            )
                        }
                    } header: {
                        Text(language.text("tab.wallpapers"))
                    } footer: {
                        Text(language.text("wallpaper.reset_settings_footer"))
                    }
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

                Section {
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent(
                        "iOS 26",
                        value: "\(ExploitSupportPolicy.verifiedIOS26BadQueryRange) · \(ExploitSupportPolicy.verifiedIOS26WorseQueryRange)"
                    )
                    LabeledContent("iOS 27", value: ExploitSupportPolicy.verifiedIOS27Range)
                    // 27.3 is a separate row on purpose: its boundary is a
                    // build number, not a version number, and folding it into
                    // the row above would read as "all of 27.3 is supported".
                    LabeledContent(
                        "iOS 27.3",
                        value: "\(ExploitSupportPolicy.verifiedIOS27BuildGatedRange) · \(ExploitSupportPolicy.verifiedIOS27Builds.joined(separator: ", "))"
                    )
                    if let reason = appState.unsupportedMessage {
                        // The reason was computed at launch but never rendered
                        // anywhere, so an unsupported device only ever saw a
                        // red badge with no explanation. Show it here for every
                        // unsupported case, not just iOS 18.
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }

                if let onLogout {
                    Section {
                        Button(role: .destructive) {
                            onLogout()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.body.weight(.semibold))
                                Spacer()
                            }
                        }
                    } footer: {
                        if let key = ByteAuthService.shared.savedLicenseKey {
                            Text("Logged in with key: \(key)")
                                .font(.caption2)
                        }
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
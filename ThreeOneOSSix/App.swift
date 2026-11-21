import SwiftUI
import UIKit

@main
struct ThreeOneOSSixApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @StateObject private var patchStore = PatchProjectStore()
    @StateObject private var repositoryStore = PackageRepositoryStore()
    @StateObject private var migrationTaskCenter = MigrationTaskCenter()
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var showOnboarding = OnboardingStore.shouldShow()

    @State private var configImportError: String?
    @State private var showSplash = true
    @State private var compassLocked = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        // Seed the UI language before the first view body runs. `@AppStorage`
        // reads UserDefaults on every access, so a write here is visible to
        // the first render. A stored value always wins — see seedIfNeeded.
        LanguageResolver.seedIfNeeded()
        setupLogCapture()
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let cpu = DeviceCPU.cpuFamily.map { String(format: "0x%X", $0) } ?? "unknown"
        log("app: Compass \(appVersion) (\(appBuild)) launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild)) \(AppInfo.machineName) cpu=\(cpu)")
        SandboxAccess.prepare()
        TempSpaceRegistry.purgeExpired()
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    private func importConfigPackage(at url: URL) {
        do {
            _ = try MigrationConfigBackupService.importPackage(at: url)
            migrationTaskCenter.refreshStoredSets()
            configImportError = nil
            log("migration: config package imported — \(url.lastPathComponent)")
        } catch {
            log("migration: config package import failed — \(error)")
            configImportError = language.errorText(error)
        }
    }

    /// GestaltX #133: a share extension may drop packages into the App Group
    /// inbox without delivering an onOpenURL callback. Read whichever App
    /// Group the side-loaded build was actually signed with.
    private func importSharedConfigPackages() {
        guard let group = SandboxAccess.appGroup,
              let inbox = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: group)?
                .appendingPathComponent("SharedConfigInbox", isDirectory: true) else { return }
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: inbox,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        for url in urls where url.pathExtension.lowercased()
            == MigrationConfigBackupService.packageExtension {
            importConfigPackage(at: url)
            try? FileManager.default.removeItem(at: url)
        }
    }


    var body: some Scene {
        WindowGroup {
            ZStack {
                if compassLocked {
                    CompassLockView {
                        waitForSandboxAccess {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                compassLocked = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showSplash = false
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                } else if showSplash {
                    ByteSplashView()
                        .transition(.opacity)
                        .zIndex(1.5)
                } else if showOnboarding {
                    OnboardingView {
                        OnboardingStore.markCompleted()
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) {
                            showOnboarding = false
                        }
                        appState.detectSupport()
                    }
                    .environment(\.appLanguage, language)
                    .environment(\.locale, language.locale)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.98))
                    )
                    .zIndex(1)
                } else {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(patchDraftCoordinator)
                        .environmentObject(fileOperationCoordinator)
                        .environmentObject(patchStore)
                        .environmentObject(repositoryStore)
                        .environmentObject(migrationTaskCenter)
                        .environment(\.appLanguage, language)
                        .environment(\.locale, language.locale)
                }
            }
            .alert(
                language.text("config.import_error.title"),
                isPresented: .init(
                    get: { configImportError != nil },
                    set: { if !$0 { configImportError = nil } }
                )
            ) {
                Button(language.text("common.ok"), role: .cancel) {
                    configImportError = nil
                }
            } message: {
                Text(configImportError ?? "")
            }
            .onAppear {
                appState.detectSupport()
                migrationTaskCenter.refreshPendingResumes()
                importSharedConfigPackages()
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                appState.detectSupport()
            }
            .onOpenURL { url in
                if url.scheme == "compass" || url.scheme == "threeoneossix" {
                    if url.host == "activate" || url.path.contains("activate") {
                        ByteAuthService.shared.handleActivationURL(url)
                        return
                    }
                }
                // Config backup packages (.3106cfg) route to the migration
                // importer; everything else stays on the patch-package path.
                if url.isFileURL,
                   url.pathExtension.lowercased() == MigrationConfigBackupService.packageExtension {
                    importConfigPackage(at: url)
                    return
                }
                patchDraftCoordinator.presentImport(url)
            }
        }
    }

    private func waitForSandboxAccess(then completion: @escaping () -> Void) {
        if appState.exploitStatus.isSuccess || appState.exploitStatus.isFailed || appState.unsupportedMessage != nil {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            waitForSandboxAccess(then: completion)
        }
    }
}

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?

    /// Same storage key as the `@AppStorage` in `ThreeOneOSSixApp`. AppState
    /// is a plain class, so it cannot read the struct's property directly —
    /// it resolves the language from the shared defaults instead.
    private var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? "")
            ?? .english
    }
    @Published var kernelExploitRunning = false

    var kernelExploitApplicable: Bool {
        KernelExploit.isApplicable(
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            build: AppInfo.osBuild,
            isA10: DeviceCPU.isA10
        )
    }

    var isSupported: Bool { unsupportedMessage == nil }

    func detectSupport() {
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild,
            isA10: DeviceCPU.isA10
        )
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--simulate-access") {
            exploitStatus = .success(method: "Simulator preview")
        }
#endif

        if !supported {
            // The explanation lives in RejectionReason so onboarding can show
            // the identical copy without a second hand-maintained copy drifting
            // the moment a version boundary moves.
            if let reason = RejectionReason.make(
                major: v.major,
                minor: v.minor,
                patch: v.patch,
                build: AppInfo.osBuild,
                osVersion: "iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))",
                isA10: DeviceCPU.isA10
            ) {
                unsupportedMessage = language.text(reason.key, reason.arguments)
            }
        }
        if let unsupportedMessage {
            exploitStatus = .unsupported(unsupportedMessage)
            return
        }

        let applicable = KernelExploit.isApplicable(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild,
            isA10: DeviceCPU.isA10
        )
        guard applicable else { return }

        refreshKernelExploitStatus()
        if !exploitStatus.isSuccess {
            runKernelExploitIfNeeded()
        }
    }

    /// True when the app should offer the Unlock screen: a kernel backend that
    /// has not succeeded yet. Deliberately excludes a settled failure — retrying
    /// automatically after a failure would recreate the silent loop this change
    /// removed. The user re-opens Unlock explicitly to try again.
    var needsUnlock: Bool {
        ExploitSupportPolicy.requiresExplicitUnlock(
            isKernelBackend: SandboxAccess.backend == .kernel,
            hasAccess: exploitStatus.isSuccess
        )
    }

    private func refreshKernelExploitStatus() {
        guard !kernelExploitRunning else { return }

        // iOS < 26: kernel R/W success persists (no sandbox probe)
        // iOS >= 26: verify full sandbox escape is still active
        if KernelExploit.requiresSandboxEscape {
            if KernelExploit.hasSandboxAccess() {
                if !exploitStatus.isSuccess {
                    exploitStatus = .success(method: SandboxAccess.backend.displayName)
                    log("app: existing \(SandboxAccess.backend.displayName) access is still active")
                }
            } else if exploitStatus.isSuccess {
                exploitStatus = .notStarted
                log("app: sandbox access is no longer active")
            }
        }
    }

    func runKernelExploitIfNeeded() {
        refreshKernelExploitStatus()
        guard !kernelExploitRunning,
              !exploitStatus.isSuccess,
              !exploitStatus.isFailed else { return }
        kernelExploitRunning = true
        exploitStatus = .notStarted
        let backend = SandboxAccess.backend
        log("app: running \(backend.displayName) access setup on background...")
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                if ok {
                    self.exploitStatus = .success(method: backend.displayName)
                    if backend == .kernel {
                        log("app: kernel access active")
                    } else {
                        log("app: \(backend.displayName) access active")
                    }
                } else {
                    self.exploitStatus = .failed(method: backend.displayName, code: -1)
                    if backend == .worseQuery && !SandboxAccess.hasAppGroup {
                        log("app: worse_query needs an App Group; re-sign with a tool that provides one")
                    } else {
                        log("app: \(backend.displayName) setup failed — relaunch the app before retrying")
                    }
                }
            }
        }
    }
}

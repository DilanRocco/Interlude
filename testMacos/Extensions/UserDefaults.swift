//
//  UserDefaults.swift
//  Interlude
//
//  Created by Dilan Piscatello on 7/24/22.
//

import Foundation
import SwiftData

enum SettingsSyncMode: String {
    case local
    case iCloud
}

struct AppSettingsSnapshot {
    var notificationsOn: Bool
    var screenIntervalMinutes: Int
    var overlayIntervalSeconds: Int
    var backgroundColor: BackgroundColorOverlay
    var scheduleEnabled: Bool
    var scheduleStartHour: Int
    var scheduleStartMinute: Int
    var scheduleEndHour: Int
    var scheduleEndMinute: Int
    var scheduleWeekdaysOnly: Bool
    var calendarBlockingEnabled: Bool

    static let `default` = AppSettingsSnapshot(
        notificationsOn: false,
        screenIntervalMinutes: 20,
        overlayIntervalSeconds: 20,
        backgroundColor: Constants.DefaultBackgroundColor,
        scheduleEnabled: false,
        scheduleStartHour: 9,
        scheduleStartMinute: 0,
        scheduleEndHour: 18,
        scheduleEndMinute: 0,
        scheduleWeekdaysOnly: false,
        calendarBlockingEnabled: false
    )
}

@Model
final class AppSettingsRecord {
    var notificationsOn: Bool
    var screenIntervalMinutes: Int
    var overlayIntervalSeconds: Int
    var backgroundColorHex: String
    var backgroundColorHelpText: String
    var backgroundColorDark: Bool
    var scheduleEnabled: Bool
    var scheduleStartHour: Int
    var scheduleStartMinute: Int
    var scheduleEndHour: Int
    var scheduleEndMinute: Int
    var scheduleWeekdaysOnly: Bool
    var calendarBlockingEnabled: Bool
    var createdAt: Date

    init(from snapshot: AppSettingsSnapshot) {
        notificationsOn = snapshot.notificationsOn
        screenIntervalMinutes = snapshot.screenIntervalMinutes
        overlayIntervalSeconds = snapshot.overlayIntervalSeconds
        backgroundColorHex = snapshot.backgroundColor.backColor
        backgroundColorHelpText = snapshot.backgroundColor.helpText
        backgroundColorDark = snapshot.backgroundColor.dark
        scheduleEnabled = snapshot.scheduleEnabled
        scheduleStartHour = snapshot.scheduleStartHour
        scheduleStartMinute = snapshot.scheduleStartMinute
        scheduleEndHour = snapshot.scheduleEndHour
        scheduleEndMinute = snapshot.scheduleEndMinute
        scheduleWeekdaysOnly = snapshot.scheduleWeekdaysOnly
        calendarBlockingEnabled = snapshot.calendarBlockingEnabled
        createdAt = Date()
    }

    func update(from snapshot: AppSettingsSnapshot) {
        notificationsOn = snapshot.notificationsOn
        screenIntervalMinutes = snapshot.screenIntervalMinutes
        overlayIntervalSeconds = snapshot.overlayIntervalSeconds
        backgroundColorHex = snapshot.backgroundColor.backColor
        backgroundColorHelpText = snapshot.backgroundColor.helpText
        backgroundColorDark = snapshot.backgroundColor.dark
        scheduleEnabled = snapshot.scheduleEnabled
        scheduleStartHour = snapshot.scheduleStartHour
        scheduleStartMinute = snapshot.scheduleStartMinute
        scheduleEndHour = snapshot.scheduleEndHour
        scheduleEndMinute = snapshot.scheduleEndMinute
        scheduleWeekdaysOnly = snapshot.scheduleWeekdaysOnly
        calendarBlockingEnabled = snapshot.calendarBlockingEnabled
    }

    func snapshot() -> AppSettingsSnapshot {
        AppSettingsSnapshot(
            notificationsOn: notificationsOn,
            screenIntervalMinutes: screenIntervalMinutes,
            overlayIntervalSeconds: overlayIntervalSeconds,
            backgroundColor: BackgroundColorOverlay(
                backColor: backgroundColorHex,
                helpText: backgroundColorHelpText,
                dark: backgroundColorDark
            ),
            scheduleEnabled: scheduleEnabled,
            scheduleStartHour: scheduleStartHour,
            scheduleStartMinute: scheduleStartMinute,
            scheduleEndHour: scheduleEndHour,
            scheduleEndMinute: scheduleEndMinute,
            scheduleWeekdaysOnly: scheduleWeekdaysOnly,
            calendarBlockingEnabled: calendarBlockingEnabled
        )
    }
}

final class AppSettingsStore: ObservableObject {
    static let shared = AppSettingsStore()

    @Published private(set) var settings: AppSettingsSnapshot = .default
    @Published private(set) var syncMode: SettingsSyncMode = .local

    private var container: ModelContainer
    private var context: ModelContext
    private var record: AppSettingsRecord

    private enum Keys {
        static let syncMode = "interlude.settings.syncMode.v1"
        static let didMigrate = "interlude.settings.didMigrateToSwiftData.v1"
        static let launchedBefore = "isAppAlreadyLaunchedOnce"
        static let backgroundColor = "BackgroundColor"
        static let useNotifications = "useNotifications"
        static let screenInterval = "screenInterval"
        static let overlayInterval = "overlayInterval"
        static let scheduleEnabled = "scheduleEnabled"
        static let scheduleStartHour = "scheduleStartHour"
        static let scheduleStartMinute = "scheduleStartMinute"
        static let scheduleEndHour = "scheduleEndHour"
        static let scheduleEndMinute = "scheduleEndMinute"
        static let scheduleWeekdaysOnly = "scheduleWeekdaysOnly"
        static let calendarBlockingEnabled = "calendarBlockingEnabled"
    }

    private init() {
        let savedMode = AppSettingsStore.readSyncMode()
        syncMode = savedMode
        let configuredContainer = AppSettingsStore.makeContainer(for: savedMode) ?? AppSettingsStore.makeContainer(for: .local)!
        container = configuredContainer
        context = ModelContext(container)
        let bootstrappedRecord = AppSettingsStore.loadOrCreateRecord(
            in: context,
            shouldMigrateFromDefaults: !UserDefaults.standard.bool(forKey: Keys.didMigrate)
        )
        record = bootstrappedRecord
        settings = bootstrappedRecord.snapshot()
    }

    var isICloudSyncEnabled: Bool {
        syncMode == .iCloud
    }

    @discardableResult
    func setICloudSyncEnabled(_ enabled: Bool) -> Bool {
        let nextMode: SettingsSyncMode = enabled ? .iCloud : .local
        guard nextMode != syncMode else { return false }
        UserDefaults.standard.set(nextMode.rawValue, forKey: Keys.syncMode)
        syncMode = nextMode
        return true
    }

    func currentSettings() -> AppSettingsSnapshot {
        settings
    }

    func updateNotificationsOn(_ value: Bool) {
        mutate {
            $0.notificationsOn = value
        }
    }

    func updateScreenIntervalMinutes(_ value: Int) {
        mutate {
            $0.screenIntervalMinutes = max(1, value)
        }
    }

    func updateOverlayIntervalSeconds(_ value: Int) {
        mutate {
            $0.overlayIntervalSeconds = max(1, value)
        }
    }

    func updateBackgroundColor(_ value: BackgroundColorOverlay) {
        mutate {
            $0.backgroundColor = value
        }
    }

    func updateScheduleEnabled(_ value: Bool) {
        mutate {
            $0.scheduleEnabled = value
        }
    }

    func updateScheduleStart(hour: Int, minute: Int) {
        mutate {
            $0.scheduleStartHour = hour
            $0.scheduleStartMinute = minute
        }
    }

    func updateScheduleEnd(hour: Int, minute: Int) {
        mutate {
            $0.scheduleEndHour = hour
            $0.scheduleEndMinute = minute
        }
    }

    func updateScheduleWeekdaysOnly(_ value: Bool) {
        mutate {
            $0.scheduleWeekdaysOnly = value
        }
    }

    func updateCalendarBlockingEnabled(_ value: Bool) {
        mutate {
            $0.calendarBlockingEnabled = value
        }
    }

    private func mutate(_ mutation: (inout AppSettingsSnapshot) -> Void) {
        var next = settings
        mutation(&next)
        settings = next
        record.update(from: next)
        do {
            try context.save()
        } catch {
            print("Failed to save app settings: \(error)")
        }
    }

    private static func readSyncMode() -> SettingsSyncMode {
        guard let raw = UserDefaults.standard.string(forKey: Keys.syncMode) else { return .local }
        return SettingsSyncMode(rawValue: raw) ?? .local
    }

    private static func makeContainer(for mode: SettingsSyncMode) -> ModelContainer? {
        let configuration: ModelConfiguration
        switch mode {
        case .local:
            configuration = ModelConfiguration("AppSettingsLocal")
        case .iCloud:
            configuration = ModelConfiguration("AppSettingsCloud", cloudKitDatabase: .automatic)
        }
        do {
            return try ModelContainer(for: AppSettingsRecord.self, configurations: configuration)
        } catch {
            print("Failed creating \(mode.rawValue) settings container: \(error)")
            return nil
        }
    }

    private static func loadOrCreateRecord(in context: ModelContext, shouldMigrateFromDefaults: Bool) -> AppSettingsRecord {
        let descriptor = FetchDescriptor<AppSettingsRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        if let existing = try? context.fetch(descriptor).first {
            if shouldMigrateFromDefaults {
                UserDefaults.standard.set(true, forKey: Keys.didMigrate)
            }
            return existing
        }

        let initialSettings = shouldMigrateFromDefaults ? migratedSettingsFromUserDefaults() : .default
        let record = AppSettingsRecord(from: initialSettings)
        context.insert(record)
        do {
            try context.save()
        } catch {
            print("Failed to save initial app settings: \(error)")
        }
        if shouldMigrateFromDefaults {
            UserDefaults.standard.set(true, forKey: Keys.didMigrate)
        }
        return record
    }

    private static func migratedSettingsFromUserDefaults() -> AppSettingsSnapshot {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Keys.launchedBefore) else { return .default }

        func intValue(_ key: String, fallback: Int) -> Int {
            guard defaults.object(forKey: key) != nil else { return fallback }
            return defaults.integer(forKey: key)
        }

        return AppSettingsSnapshot(
            notificationsOn: defaults.object(forKey: Keys.useNotifications) != nil ? defaults.bool(forKey: Keys.useNotifications) : false,
            screenIntervalMinutes: max(1, intValue(Keys.screenInterval, fallback: 20)),
            overlayIntervalSeconds: max(1, intValue(Keys.overlayInterval, fallback: 20)),
            backgroundColor: readLegacyBackgroundColor(from: defaults),
            scheduleEnabled: defaults.object(forKey: Keys.scheduleEnabled) != nil ? defaults.bool(forKey: Keys.scheduleEnabled) : false,
            scheduleStartHour: intValue(Keys.scheduleStartHour, fallback: 9),
            scheduleStartMinute: intValue(Keys.scheduleStartMinute, fallback: 0),
            scheduleEndHour: intValue(Keys.scheduleEndHour, fallback: 18),
            scheduleEndMinute: intValue(Keys.scheduleEndMinute, fallback: 0),
            scheduleWeekdaysOnly: defaults.object(forKey: Keys.scheduleWeekdaysOnly) != nil ? defaults.bool(forKey: Keys.scheduleWeekdaysOnly) : false,
            calendarBlockingEnabled: defaults.object(forKey: Keys.calendarBlockingEnabled) != nil ? defaults.bool(forKey: Keys.calendarBlockingEnabled) : false
        )
    }

    private static func readLegacyBackgroundColor(from defaults: UserDefaults) -> BackgroundColorOverlay {
        guard let data = defaults.data(forKey: Keys.backgroundColor),
              let decoded = try? JSONDecoder().decode(BackgroundColorOverlay.self, from: data) else {
            return Constants.DefaultBackgroundColor
        }
        return decoded
    }
}

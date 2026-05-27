import Foundation

/// Thin typed wrapper around `UserDefaults.standard` for persisting
/// `AvailabilityOptions`. Keys are namespaced so future preference groups
/// can coexist without collisions, and a single `reset()` entry point
/// keeps the "Reset all settings" affordance honest.
///
/// `@unchecked Sendable`: the only stored property is `UserDefaults`,
/// which Apple documents as thread-safe.
final class PreferencesStore: @unchecked Sendable {
    static let shared = PreferencesStore()

    static let currentSchemaVersion = 1

    enum Keys {
        static let namespace = "availabilityOptions"

        static let schemaVersion       = "\(namespace).schemaVersion"
        static let dayStartHour        = "\(namespace).dayStartHour"
        static let dayEndHour          = "\(namespace).dayEndHour"
        static let lunchEnabled        = "\(namespace).lunchEnabled"
        static let lunchStartHour      = "\(namespace).lunchStartHour"
        static let lunchEndHour        = "\(namespace).lunchEndHour"
        static let hideEventTimes      = "\(namespace).hideEventTimes"
        static let includeWeekends     = "\(namespace).includeWeekends"
        static let selectedCalendarIDs = "\(namespace).selectedCalendarIDs"
        static let visibleAvailabilities = "\(namespace).visibleAvailabilities"
        static let timezoneIdentifier  = "\(namespace).timezoneIdentifier"

        static let all: [String] = [
            schemaVersion,
            dayStartHour, dayEndHour,
            lunchEnabled, lunchStartHour, lunchEndHour,
            hideEventTimes, includeWeekends,
            selectedCalendarIDs, visibleAvailabilities,
            timezoneIdentifier,
        ]
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.schemaVersion) == nil {
            defaults.set(Self.currentSchemaVersion, forKey: Keys.schemaVersion)
        }
    }

    // MARK: - Typed accessors

    func int(_ key: String, default fallback: Int) -> Int {
        defaults.object(forKey: key) == nil ? fallback : defaults.integer(forKey: key)
    }

    func set(_ value: Int, for key: String) {
        defaults.set(value, forKey: key)
    }

    func bool(_ key: String, default fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }

    func set(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }

    func string(_ key: String) -> String? {
        defaults.string(forKey: key)
    }

    func set(_ value: String?, for key: String) {
        defaults.set(value, forKey: key)
    }

    func stringArray(_ key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    func set(_ value: [String], for key: String) {
        defaults.set(value, forKey: key)
    }

    // MARK: - Reset

    func reset() {
        for key in Keys.all {
            defaults.removeObject(forKey: key)
        }
        defaults.set(Self.currentSchemaVersion, forKey: Keys.schemaVersion)
    }
}

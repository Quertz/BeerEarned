import Foundation
import WidgetKit
import UserNotifications

enum DrinkKind: String {
    case beer
    case prosecco

    var symbol: String { self == .beer ? "🍺" : "🍸" }
    var defaultCalories: Double { self == .beer ? 220 : 135 }
}

enum BeerStorage {
    static let groupID = "group.cz.beerearned.shared"
    static let widgetKind = "BeerEarnedWidget"

    enum Key {
        static let configured = "settings.configured"
        static let drink = "settings.drink"
        static let workoutsOnly = "settings.workoutsOnly"
        static let notifications = "settings.notifications"
        static let healthRequested = "health.requested"
        static let lastWorkoutEnd = "health.lastWorkoutEnd"
        static let dayStart = "cache.dayStart"
        static let totalCalories = "cache.totalCalories"
        static let activityCalories = "cache.activityCalories"
        static let updatedAt = "cache.updatedAt"
    }

    // A fallback lets the main app show a useful diagnostic if App Groups
    // have not been provisioned. The widget will not display fake data.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    static var isSharedContainerAvailable: Bool {
        UserDefaults(suiteName: groupID) != nil
    }

    static var selectedDrink: DrinkKind {
        DrinkKind(rawValue: defaults.string(forKey: Key.drink) ?? "beer") ?? .beer
    }

    // Fixed energy per serving (beer 0.5 L / prosecco 0.2 L).
    // Ignore previous editable values stored by older app versions.
    static var caloriesPerDrink: Double {
        selectedDrink.defaultCalories
    }

    static func notifyWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    // The request is triggered only by an explicit choice in onboarding
    // or when enabling notifications in Settings.
    static func requestNotificationPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func scheduleTestNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "test_notification_title")
        content.body = String(localized: "test_notification_body")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "beerearned-test-" + UUID().uuidString,
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    static func saveCalories(total: Double, activity: Double, dayStart: Date) {
        guard let shared = UserDefaults(suiteName: groupID) else { return }
        shared.set(dayStart.timeIntervalSince1970, forKey: Key.dayStart)
        shared.set(max(0, total), forKey: Key.totalCalories)
        shared.set(max(0, activity), forKey: Key.activityCalories)
        shared.set(Date().timeIntervalSince1970, forKey: Key.updatedAt)
        notifyWidget()
    }
}

import Foundation
import HealthKit
import Combine
import UserNotifications

@MainActor
final class BeerHealthStore: ObservableObject {
    static let shared = BeerHealthStore()

    @Published private(set) var todayCalories: Double = 0
    @Published private(set) var workoutCalories: Double = 0
    @Published private(set) var errorMessage: String?

    private let store = HKHealthStore()
    private let energyType = HKQuantityType(.activeEnergyBurned)
    private var observers: [HKObserverQuery] = []
    private var refreshSequence = 0

    private init() {}

    var hasRequestedAccess: Bool {
        BeerStorage.defaults.bool(forKey: BeerStorage.Key.healthRequested)
    }

    func connect() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = String(localized: "health_unavailable")
            return
        }

        let readTypes: Set<HKObjectType> = [energyType, .workoutType()]
        store.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard success else {
                    self.errorMessage = String(localized: "health_not_confirmed")
                    return
                }

                // HealthKit does not disclose whether each read type was denied.
                BeerStorage.defaults.set(true, forKey: BeerStorage.Key.healthRequested)
                self.errorMessage = nil
                self.enableBackgroundDelivery()
                self.refresh()
            }
        }
    }

    func startObserving() {
        guard HKHealthStore.isHealthDataAvailable(), observers.isEmpty else { return }

        for sampleType: HKSampleType in [energyType, .workoutType()] {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) {
                [weak self] _, completion, error in

                guard error == nil else {
                    completion()
                    return
                }
                Task { @MainActor [weak self] in
                    guard let self else {
                        completion()
                        return
                    }
                    self.refresh(completion: completion)
                }
            }
            observers.append(query)
            store.execute(query)
        }

        if hasRequestedAccess {
            enableBackgroundDelivery()
        }
    }

    private func enableBackgroundDelivery() {
        // Most watchOS HealthKit types are delivered at most hourly.
        for type: HKObjectType in [energyType, .workoutType()] {
            store.enableBackgroundDelivery(for: type, frequency: .hourly) { success, error in
                if let error {
                    NSLog("BeerEarned background delivery: %@", error.localizedDescription)
                } else if !success {
                    NSLog("BeerEarned background delivery was not enabled")
                }
            }
        }
    }

    func refresh(completion: (() -> Void)? = nil) {
        guard hasRequestedAccess, HKHealthStore.isHealthDataAvailable() else {
            completion?()
            return
        }

        refreshSequence += 1
        let currentRefresh = refreshSequence
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: Date(), options: .strictStartDate
        )

        let currentStore = store
        let dayQuery = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, statistics, dailyError in

            let total = statistics?.sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0

            let workoutQuery = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] _, samples, workoutError in

                let workouts = samples as? [HKWorkout] ?? []
                let energy = HKQuantityType(.activeEnergyBurned)
                let workoutTotal = workouts.reduce(0.0) { sum, workout in
                    let kcal = workout.statistics(for: energy)?
                        .sumQuantity()?
                        .doubleValue(for: .kilocalorie()) ?? 0
                    return sum + kcal
                }

                Task { @MainActor [weak self] in
                    guard let self else {
                        completion?()
                        return
                    }
                    defer { completion?() }

                    guard currentRefresh == self.refreshSequence else { return }

                    self.todayCalories = max(total, 0)
                    self.workoutCalories = max(workoutTotal, 0)
                    self.errorMessage = self.message(for: dailyError)
                        ?? self.message(for: workoutError)

                    BeerStorage.saveCalories(
                        total: total,
                        activity: workoutTotal,
                        dayStart: start
                    )
                    self.notifyOfNewWorkouts(workouts)
                }
            }
            currentStore.execute(workoutQuery)
        }
        currentStore.execute(dayQuery)
    }

    private func message(for error: Error?) -> String? {
        guard let error else { return nil }
        let nsError = error as NSError
        if nsError.domain == HKErrorDomain &&
           nsError.code == HKError.Code.errorNoData.rawValue {
            return nil
        }
        return error.localizedDescription
    }

    private func notifyOfNewWorkouts(_ workouts: [HKWorkout]) {
        let completed = workouts
            .filter { $0.endDate <= Date() }
            .sorted { $0.endDate < $1.endDate }
        guard let newest = completed.last else { return }

        let defaults = BeerStorage.defaults
        let key = BeerStorage.Key.lastWorkoutEnd
        let newestEnd = newest.endDate.timeIntervalSince1970

        // Initial installation must not replay earlier workouts.
        guard defaults.object(forKey: key) != nil else {
            defaults.set(newestEnd, forKey: key)
            return
        }

        let previous = defaults.double(forKey: key)
        let fresh = completed.filter {
            $0.endDate.timeIntervalSince1970 > previous
        }
        guard !fresh.isEmpty else { return }
        defaults.set(newestEnd, forKey: key)
        guard defaults.bool(forKey: BeerStorage.Key.notifications) else { return }

        let keys = [
            "notification_message_1",
            "notification_message_2",
            "notification_message_3",
            "notification_message_4",
            "notification_message_5"
        ]

        for workout in fresh {
            let kcal = workout.statistics(for: energyType)?.sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0
            let count = Int(max(0, kcal) / BeerStorage.caloriesPerDrink)
            guard count > 0 else { continue }

            let drink = BeerStorage.selectedDrink
            let selectedKey = keys.randomElement() ?? keys[0]
            let template = NSLocalizedString(
                selectedKey, comment: "Random workout celebration"
            )

            let notification = UNMutableNotificationContent()
            notification.title = String(localized: "notification_title")
            let workoutReward = DrinkCountText.formatted(
                count, drink: drink.rawValue
            )
            let totalReward = DrinkCountText.formatted(
                Int(self.todayCalories / BeerStorage.caloriesPerDrink),
                drink: drink.rawValue
            )
            notification.body = String(
                format: template, locale: .current,
                workoutReward, totalReward
            )
            notification.sound = .default

            let request = UNNotificationRequest(
                identifier: "workout-" + workout.uuid.uuidString,
                content: notification,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    NSLog("BeerEarned notification: %@", error.localizedDescription)
                }
            }
        }
    }
}

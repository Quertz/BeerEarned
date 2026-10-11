
import Foundation
import Combine
import HealthKit


private func healthErrorMessage(_ error: Error?) -> String? {
    guard let error else { return nil }

    let nsError = error as NSError

    if nsError.domain == HKErrorDomain &&
       nsError.code == HKError.Code.errorNoData.rawValue {
        return nil
    }

    return error.localizedDescription
}


@MainActor
final class BeerHealthStore: ObservableObject {

    @Published private(set) var todayCalories = 0.0
    @Published private(set) var workoutCalories = 0.0
    @Published private(set) var errorMessage: String?

    private let healthStore = HKHealthStore()
    private let energyType = HKQuantityType(.activeEnergyBurned)

    func connect() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available."
            return
        }

        let readTypes: Set<HKObjectType> = [
            energyType,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(
            toShare: [],
            read: readTypes
        ) { [weak self] _, error in

            let message = healthErrorMessage(error)

            Task { @MainActor [weak self] in
                guard let self else { return }

                if let message {
                    self.errorMessage = message
                } else {
                    self.refresh()
                }
            }
        }
    }

    func refresh() {
        let start = Calendar.current.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        let dailyQuery = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, statistics, error in

            let calories = statistics?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0

            let message = healthErrorMessage(error)

            Task { @MainActor [weak self] in
                self?.todayCalories = calories

                if let message {
                    self?.errorMessage = message
                }
            }
        }

        healthStore.execute(dailyQuery)

        let workoutQuery = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in

            let energy = HKQuantityType(.activeEnergyBurned)
            let workouts = samples as? [HKWorkout] ?? []

            let calories = workouts.reduce(0.0) { sum, workout in
                let value = workout
                    .statistics(for: energy)?
                    .sumQuantity()?
                    .doubleValue(for: .kilocalorie()) ?? 0

                return sum + value
            }

            let message = healthErrorMessage(error)

            Task { @MainActor [weak self] in
                self?.workoutCalories = calories

                if let message {
                    self?.errorMessage = message
                }
            }
        }

        healthStore.execute(workoutQuery)
    }
}

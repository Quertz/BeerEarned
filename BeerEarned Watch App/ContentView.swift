import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var health: BeerHealthStore
    @AppStorage(BeerStorage.Key.configured, store: BeerStorage.defaults)
    private var configured = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if configured {
                DashboardView()
            } else {
                SetupView {
                    BeerStorage.defaults.set(
                        Date().timeIntervalSince1970,
                        forKey: BeerStorage.Key.lastWorkoutEnd
                    )
                    configured = true
                    BeerStorage.notifyWidget()
                    health.connect()
                    if BeerStorage.defaults.bool(forKey: BeerStorage.Key.notifications) {
                        BeerStorage.requestNotificationPermission()
                    }
                }
            }
        }
        .task {
            if configured && health.hasRequestedAccess {
                health.refresh()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && configured && health.hasRequestedAccess {
                health.refresh()
            }
        }
    }
}

private struct SetupView: View {
    let onComplete: () -> Void

    @AppStorage(BeerStorage.Key.drink, store: BeerStorage.defaults)
    private var drink = "beer"
    @AppStorage(BeerStorage.Key.calories, store: BeerStorage.defaults)
    private var calories: Double = 220
    @AppStorage(BeerStorage.Key.notifications, store: BeerStorage.defaults)
    private var notificationsEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("welcome_title")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                HStack {
                    drinkButton(.beer)
                    drinkButton(.prosecco)
                }

                Text("calories_per_drink")
                    .font(.caption)

                Stepper(value: $calories, in: 50...500, step: 10) {
                    Text("\(Int(calories)) kcal").bold()
                }

                Toggle("workout_notifications", isOn: $notificationsEnabled)

                Button("get_started", action: onComplete)
                    .tint(.orange)
            }
            .padding(.horizontal, 5)
        }
    }

    private func drinkButton(_ kind: DrinkKind) -> some View {
        Button {
            drink = kind.rawValue
            calories = kind.defaultCalories
        } label: {
            VStack {
                Text(kind.symbol).font(.title2)
                if kind == .beer {
                    Text("beer")
                } else {
                    Text("prosecco")
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(drink == kind.rawValue ? 1 : 0.6)
        }
        .tint(drink == kind.rawValue ? .orange : .gray)
    }
}

private struct DashboardView: View {
    @EnvironmentObject private var health: BeerHealthStore
    @AppStorage(BeerStorage.Key.drink, store: BeerStorage.defaults)
    private var drink = "beer"
    @AppStorage(BeerStorage.Key.calories, store: BeerStorage.defaults)
    private var calories: Double = 220

    private var kind: DrinkKind { DrinkKind(rawValue: drink) ?? .beer }
    private var divisor: Double { calories > 0 ? calories : kind.defaultCalories }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if kind == .beer {
                        Text("earned_beer_title")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                    } else {
                        Text("earned_prosecco_title")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                    }

                    HStack {
                        Text("activity_label")
                        Spacer()
                        Text(DrinkCountText.formatted(Int(health.workoutCalories / divisor), drink: kind.rawValue) + " " + kind.symbol)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .bold()
                    }

                    Text("\(Int(health.workoutCalories)) kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack {
                        Text("total_today_label")
                        Spacer()
                        Text(DrinkCountText.formatted(Int(health.todayCalories / divisor), drink: kind.rawValue) + " " + kind.symbol)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .bold()
                            .foregroundStyle(.yellow)
                    }

                    Text("\(Int(health.todayCalories)) kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if !health.hasRequestedAccess {
                        Button("connect_health") {
                            health.connect()
                        }
                        .tint(.green)
                    }

                    Button("refresh") {
                        health.refresh()
                    }

                    NavigationLink("settings") {
                        SettingsView()
                    }

                    if !BeerStorage.isSharedContainerAvailable {
                        Text("app_group_missing")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    if let error = health.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
        }
    }
}

private struct SettingsView: View {
    @AppStorage(BeerStorage.Key.drink, store: BeerStorage.defaults)
    private var drink = "beer"
    @AppStorage(BeerStorage.Key.calories, store: BeerStorage.defaults)
    private var calories: Double = 220
    @AppStorage(BeerStorage.Key.notifications, store: BeerStorage.defaults)
    private var notificationsEnabled = true

    var body: some View {
        Form {
            Picker("drink_selection", selection: $drink) {
                Text("beer").tag("beer")
                Text("prosecco").tag("prosecco")
            }

            Stepper(value: $calories, in: 50...500, step: 10) {
                Text("\(Int(calories)) kcal")
            }

            Toggle("workout_notifications", isOn: $notificationsEnabled)
        }
        .navigationTitle("settings")
        .onChange(of: drink) { _, newValue in
            calories = (DrinkKind(rawValue: newValue) ?? .beer).defaultCalories
            BeerStorage.notifyWidget()
        }
        .onChange(of: calories) { _, _ in
            BeerStorage.notifyWidget()
        }
        .onChange(of: notificationsEnabled) { _, enabled in
            if enabled { BeerStorage.requestNotificationPermission() }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BeerHealthStore.shared)
}

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
        // Opening from a complication launches the watch app by default.
        // Refresh on cold launch and whenever the app returns to foreground.
        .task(id: configured) {
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
        } label: {
            VStack {
                Text(kind.symbol).font(.title2)
                if kind == .beer {
                    Text("beer")
                    Text("beer_serving")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                } else {
                    Text("prosecco")
                    Text("prosecco_serving")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
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

    private var kind: DrinkKind { DrinkKind(rawValue: drink) ?? .beer }
    private var divisor: Double { kind.defaultCalories }

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

                    if health.isRefreshing {
                        HStack(spacing: 4) {
                            ProgressView()
                            Text("refreshing_health")
                                .font(.caption2)
                        }
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
    @AppStorage(BeerStorage.Key.notifications, store: BeerStorage.defaults)
    private var notificationsEnabled = true

    var body: some View {
        Form {
            Picker("drink_selection", selection: $drink) {
                Text("beer").tag("beer")
                Text("prosecco").tag("prosecco")
            }

            if drink == "prosecco" {
                Text("prosecco_serving")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("beer_serving")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Toggle("workout_notifications", isOn: $notificationsEnabled)
        }
        .navigationTitle("settings")
        .onChange(of: drink) { _, newValue in
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

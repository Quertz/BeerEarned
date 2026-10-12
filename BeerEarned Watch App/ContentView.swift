import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var health: BeerHealthStore
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(BeerStorage.Key.configured, store: BeerStorage.defaults)
    private var configured = false

    var body: some View {
        Group {
            if configured {
                DashboardView()
            } else {
                SetupView {
                    // Do not replay already completed workouts as new rewards.
                    BeerStorage.defaults.set(
                        Date().timeIntervalSince1970,
                        forKey: BeerStorage.Key.lastWorkoutEnd
                    )
                    configured = true
                    BeerStorage.notifyWidget()
                }
            }
        }
        // The circular complication opens the app by default. A fresh
        // HealthKit query is started on launch and whenever it becomes active.
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

private enum SetupStep {
    case drink
    case health
    case notifications
}

private struct SetupView: View {
    @EnvironmentObject private var health: BeerHealthStore

    let onComplete: () -> Void

    @AppStorage(BeerStorage.Key.drink, store: BeerStorage.defaults)
    private var drink = "beer"

    @AppStorage(BeerStorage.Key.notifications, store: BeerStorage.defaults)
    private var notificationsEnabled = false

    @State private var step: SetupStep = .drink
    @State private var isConnectingHealth = false
    @State private var isRequestingNotifications = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                switch step {
                case .drink:
                    Text("welcome_title")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        drinkButton(.beer)
                        drinkButton(.prosecco)
                    }

                    Button("setup_continue") {
                        step = .health
                    }
                    .tint(.orange)

                case .health:
                    Image(systemName: "heart.text.square")
                        .font(.title2)
                        .foregroundStyle(.green)

                    Text("setup_health_title")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("setup_health_explanation")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button("connect_health") {
                        isConnectingHealth = true
                        health.connect { success in
                            isConnectingHealth = false
                            if success {
                                step = .notifications
                            }
                        }
                    }
                    .disabled(isConnectingHealth)

                    if isConnectingHealth {
                        ProgressView()
                    }

                    if let error = health.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }

                    Button("setup_skip_health") {
                        step = .notifications
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                case .notifications:
                    Image(systemName: "bell.badge")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text("setup_notification_title")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("setup_notification_explanation")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button("setup_allow_notifications") {
                        isRequestingNotifications = true
                        Task { @MainActor in
                            let granted = await BeerStorage.requestNotificationPermission()
                            notificationsEnabled = granted
                            isRequestingNotifications = false
                            onComplete()
                        }
                    }
                    .disabled(isRequestingNotifications)

                    if isRequestingNotifications {
                        ProgressView()
                    }

                    Button("setup_widget_only") {
                        notificationsEnabled = false
                        onComplete()
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
    }

    private func drinkButton(_ kind: DrinkKind) -> some View {
        Button {
            drink = kind.rawValue
        } label: {
            VStack(spacing: 3) {
                Text(kind.symbol)
                    .font(.title2)

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

    private var kind: DrinkKind {
        DrinkKind(rawValue: drink) ?? .beer
    }

    private var divisor: Double {
        kind.defaultCalories
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 9) {
                        if kind == .beer {
                            Text("earned_beer_title")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                        } else {
                            Text("earned_prosecco_title")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                        }

                        Divider()

                        HStack {
                            Text("activity_label")
                            Spacer(minLength: 4)
                            Text(
                                DrinkCountText.formatted(
                                    Int(health.workoutCalories / divisor),
                                    drink: kind.rawValue
                                ) + " " + kind.symbol
                            )
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
                            Spacer(minLength: 4)
                            Text(
                                DrinkCountText.formatted(
                                    Int(health.todayCalories / divisor),
                                    drink: kind.rawValue
                                ) + " " + kind.symbol
                            )
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
                            ProgressView()
                                .accessibilityLabel(Text("refreshing_health"))
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
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                }

                // Compact bottom toolbar stays visible even if the dashboard
                // needs to scroll on a smaller Apple Watch.
                HStack {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .frame(width: 36, height: 32)
                    }
                    .accessibilityLabel(Text("settings"))

                    Spacer(minLength: 0)

                    Button {
                        health.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 36, height: 32)
                    }
                    .disabled(health.isRefreshing)
                    .accessibilityLabel(Text("refresh"))

                    Spacer(minLength: 0)

                    NavigationLink {
                        InformationView()
                    } label: {
                        Image(systemName: "info.circle")
                            .frame(width: 36, height: 32)
                    }
                    .accessibilityLabel(Text("information"))
                }
                .font(.body)
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 2)
            }
        }
    }
}

private struct SettingsView: View {
    @AppStorage(BeerStorage.Key.drink, store: BeerStorage.defaults)
    private var drink = "beer"

    @AppStorage(BeerStorage.Key.notifications, store: BeerStorage.defaults)
    private var notificationsEnabled = false

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
        .onChange(of: drink) { _, _ in
            BeerStorage.notifyWidget()
        }
        .onChange(of: notificationsEnabled) { _, enabled in
            if enabled {
                Task { @MainActor in
                    let granted = await BeerStorage.requestNotificationPermission()
                    if !granted {
                        notificationsEnabled = false
                    }
                }
            }
        }
    }
}

private struct InformationView: View {
    var body: some View {
        ScrollView {
            Text("alcohol_disclaimer")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BeerHealthStore.shared)
}

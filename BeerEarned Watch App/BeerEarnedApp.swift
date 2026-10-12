import SwiftUI

@main
@MainActor
struct BeerEarned_Watch_AppApp: App {
    @StateObject private var health = BeerHealthStore.shared

    init() {
        // Register as early as possible, including background launches.
        BeerHealthStore.shared.startObserving()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(health)
        }
    }
}

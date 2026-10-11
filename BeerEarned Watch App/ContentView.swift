
import SwiftUI

struct ContentView: View {

    @StateObject private var health = BeerHealthStore()

    private let caloriesPerDrink = 220.0

    private var activityBeers: Int {
        Int(health.workoutCalories / caloriesPerDrink)
    }

    private var totalBeers: Int {
        Int(health.todayCalories / caloriesPerDrink)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                Text("🍺 BEER EARNED")
                    .font(.headline)
                    .foregroundStyle(.yellow)

                Divider()

                HStack {
                    Text("Activity")
                    Spacer()
                    Text("\(activityBeers) 🍺")
                        .bold()
                }

                Text("\(Int(health.workoutCalories)) workout kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider()

                HStack {
                    Text("Total today")
                    Spacer()
                    Text("\(totalBeers) 🍺")
                        .bold()
                        .foregroundStyle(.yellow)
                }

                Text("\(Int(health.todayCalories)) active kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button("❤️ Connect Apple Health") {
                    health.connect()
                }
                .tint(.green)

                Button("Refresh") {
                    health.refresh()
                }

                if let error = health.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .onAppear {
            health.refresh()
        }
    }
}

#Preview {
    ContentView()
}

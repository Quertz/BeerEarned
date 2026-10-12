import Foundation
import SwiftUI
import WidgetKit

private enum Shared {
    static let groupID = "group.cz.beerearned.shared"
    static let drink = "settings.drink"
    static let dayStart = "cache.dayStart"
    static let total = "cache.totalCalories"
    static let activity = "cache.activityCalories"
    static let updated = "cache.updatedAt"
}

struct BeerEntry: TimelineEntry {
    let date: Date
    let activity: Int
    let total: Int
    let symbol: String
    let prosecco: Bool
    let hasData: Bool
}

struct BeerProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeerEntry {
        BeerEntry(date: .now, activity: 5, total: 7,
                  symbol: "🍺", prosecco: false, hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (BeerEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeerEntry>) -> Void) {
        let now = Date()
        let midnight = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: now)
        ) ?? now.addingTimeInterval(86400)

        let next = min(now.addingTimeInterval(1800), midnight)
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }

    private func entry() -> BeerEntry {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let data = UserDefaults(suiteName: Shared.groupID)

        let isToday = data?.object(forKey: Shared.updated) != nil &&
            abs((data?.double(forKey: Shared.dayStart) ?? 0) -
                today.timeIntervalSince1970) < 1

        let prosecco = data?.string(forKey: Shared.drink) == "prosecco"
        // Same fixed serving calories as the watch app; ignore legacy values.
        let divider: Double = prosecco ? 135 : 220

        return BeerEntry(
            date: now,
            activity: isToday
                ? Int(max(0, data?.double(forKey: Shared.activity) ?? 0) / divider) : 0,
            total: isToday
                ? Int(max(0, data?.double(forKey: Shared.total) ?? 0) / divider) : 0,
            symbol: prosecco ? "🍸" : "🍺",
            prosecco: prosecco,
            hasData: isToday
        )
    }
}

struct BeerWidgetView: View {
    let entry: BeerEntry

    @Environment(\.widgetFamily) private var family

    private var drink: String { entry.prosecco ? "prosecco" : "beer" }

    private func count(_ value: Int) -> String {
        entry.hasData
            ? DrinkCountText.formatted(value, drink: drink)
            : "—"
    }

    private var circularCount: String {
        entry.hasData
            ? DrinkCountText.circular(entry.total, drink: drink)
            : "—"
    }

    var body: some View {
        Group {
            if family == .accessoryCircular {
                ZStack {
                    Circle()
                        .stroke(.orange, lineWidth: 3)
                        .padding(2)
                        .widgetAccentable()

                    HStack(spacing: 1) {
                        Text(circularCount)
                            .font(.system(
                                size: !entry.prosecco && entry.total == 20 ? 10 : 20,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        // Champagne emoji only in the circular prosecco complication.
                        Text(entry.prosecco ? "🥂" : "🍺")
                            .font(.system(size: 15))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 5)
                    .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    if entry.prosecco {
                        Text("widget_prosecco_title")
                            .font(.caption2).bold().foregroundStyle(.yellow)
                    } else {
                        Text("widget_beer_title")
                            .font(.caption2).bold().foregroundStyle(.yellow)
                    }

                    HStack {
                        Text("activity_label")
                        Spacer()
                        Text(count(entry.activity) + " " + entry.symbol)
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    HStack {
                        Text("total_today_label")
                        Spacer()
                        Text(count(entry.total) + " " + entry.symbol)
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(.yellow)
                    }
                }
                .font(.caption2)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BeerEarnedWidget: Widget {
    let kind = "BeerEarnedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeerProvider()) { entry in
            BeerWidgetView(entry: entry)
        }
        .configurationDisplayName("Beer Earned")
        .description("Your activity converted into drink equivalents.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

#Preview(as: .accessoryRectangular) {
    BeerEarnedWidget()
} timeline: {
    BeerEntry(date: .now, activity: 5, total: 7,
              symbol: "🍺", prosecco: false, hasData: true)
}

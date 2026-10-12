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

// Compact visual notation used by both the Smart Stack and complication.
// Thresholds are expressed in drink equivalents, not kilocalories.
private enum DrinkBadge {
    static func label(_ count: Int, prosecco: Bool) -> String {
        let number = max(0, count)

        if number >= 13 {
            return "\(number)☠️"
        }

        if prosecco {
            switch number {
            case 4: return "1🍾"
            case 8: return "2🍾"
            case 9...12: return "\(number)🍸⚠️"
            default: return "\(number)🍸"
            }
        } else {
            if number >= 7 {
                return "\(number)🍺⚠️"
            }
            return "\(number)🍺"
        }
    }
}

struct BeerWidgetView: View {
    let entry: BeerEntry

    @Environment(\.widgetFamily) private var family

    private func badge(_ value: Int) -> String {
        guard entry.hasData else { return "—" }
        return DrinkBadge.label(value, prosecco: entry.prosecco)
    }

    var body: some View {
        Group {
            if family == .accessoryCircular {
                ZStack {
                    Circle()
                        .stroke(.orange, lineWidth: 3)
                        .padding(2)
                        .widgetAccentable()

                    Text(badge(entry.total))
                        .font(.system(
                            size: entry.total >= 10 ? 14 : 19,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                        .padding(.horizontal, 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("total_today_label"))
                .accessibilityValue(Text(badge(entry.total)))
            } else {
                // Two values remain, but no long titles or inflected units:
                // running figure = today's workouts, calendar = whole day.
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 2)
                        Text(badge(entry.activity))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("activity_label"))
                    .accessibilityValue(Text(badge(entry.activity)))

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 2)
                        Text(badge(entry.total))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("total_today_label"))
                    .accessibilityValue(Text(badge(entry.total)))
                }
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

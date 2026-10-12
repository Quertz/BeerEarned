import Foundation
import SwiftUI
import WidgetKit

private enum Shared {
    static let groupID = "group.cz.beerearned.shared"
    static let drink = "settings.drink"
    static let workoutsOnly = "settings.workoutsOnly"
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
    let cola: Bool
    let workoutsOnly: Bool
    let hasData: Bool
}

struct BeerProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeerEntry {
        BeerEntry(date: .now, activity: 5, total: 7,
                  symbol: "🍺", prosecco: false, cola: false, workoutsOnly: false, hasData: true)
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

        let selectedDrink = data?.string(forKey: Shared.drink) ?? "beer"
        let prosecco = selectedDrink == "prosecco"
        let cola = selectedDrink == "cola"
        // Same fixed serving calories as the watch app; ignore legacy values.
        let divider: Double = cola ? 90 : (prosecco ? 135 : 220)

        return BeerEntry(
            date: now,
            activity: isToday
                ? Int(max(0, data?.double(forKey: Shared.activity) ?? 0) / divider) : 0,
            total: isToday
                ? Int(max(0, data?.double(forKey: Shared.total) ?? 0) / divider) : 0,
            symbol: cola ? "🥤" : (prosecco ? "🍸" : "🍺"),
            prosecco: prosecco,
            cola: cola,
            workoutsOnly: data?.bool(forKey: Shared.workoutsOnly) ?? false,
            hasData: isToday
        )
    }
}

// Compact visual notation used by both the Smart Stack and complication.
// Thresholds are expressed in drink equivalents, not kilocalories.
private enum DrinkBadge {
    static func label(_ count: Int, prosecco: Bool, cola: Bool) -> String {
        let number = max(0, count)

        // Soft drink never receives alcohol-specific warning/bottle symbols.
        if cola { return "\(number)🥤" }

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
        return DrinkBadge.label(value, prosecco: entry.prosecco, cola: entry.cola)
    }

    // Circular complication always shows count + selected drink, with the
    // count derived from workouts only when the user enables that mode.
    // Warning and bottle thresholds apply only to the rectangular widget.
    private var circularBadge: String {
        guard entry.hasData else { return "—" }
        let count = entry.workoutsOnly ? entry.activity : entry.total
        return String(max(0, count)) + (entry.cola ? "🥤" : (entry.prosecco ? "🍸" : "🍺"))
    }

    private var circularDisplayCount: Int {
        entry.workoutsOnly ? entry.activity : entry.total
    }

    var body: some View {
        Group {
            if family == .accessoryCircular {
                ZStack {
                    Circle()
                        .stroke(.orange, lineWidth: 1.25)
                        .padding(2)
                        .widgetAccentable()

                    Text(circularBadge)
                        .font(.system(
                            size: circularDisplayCount >= 100 ? 12 : (circularDisplayCount >= 10 ? 15 : 19),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                        .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(entry.workoutsOnly ? Text("activity_label") : Text("total_today_label"))
                .accessibilityValue(Text(circularBadge))
            } else if entry.workoutsOnly {
                HStack(spacing: 3) {
                    Text("activity_label")
                        .font(.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 1)

                    Text(badge(entry.activity))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("activity_label"))
                .accessibilityValue(Text(badge(entry.activity)))
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 3) {
                        Text("activity_label")
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Spacer(minLength: 1)

                        Text(badge(entry.activity))
                            .font(.body.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("activity_label"))
                    .accessibilityValue(Text(badge(entry.activity)))

                    HStack(spacing: 3) {
                        Text("total_today_label")
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Spacer(minLength: 1)

                        Text(badge(entry.total))
                            .font(.body.weight(.semibold))
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
        .configurationDisplayName("BeerCounter")
        .description("Your activity converted into drink equivalents.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

#Preview(as: .accessoryRectangular) {
    BeerEarnedWidget()
} timeline: {
    BeerEntry(date: .now, activity: 5, total: 7,
              symbol: "🍺", prosecco: false, cola: false, workoutsOnly: false, hasData: true)
}


import SwiftUI
import WidgetKit

struct BeerEntry: TimelineEntry {
    let date: Date
    let activity: Int
    let total: Int
}

struct BeerProvider: TimelineProvider {

    func placeholder(in context: Context) -> BeerEntry {
        BeerEntry(date: .now, activity: 5, total: 7)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (BeerEntry) -> Void
    ) {
        completion(
            BeerEntry(date: .now, activity: 5, total: 7)
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<BeerEntry>) -> Void
    ) {
        let entry = BeerEntry(
            date: .now,
            activity: 5,
            total: 7
        )

        completion(
            Timeline(entries: [entry], policy: .never)
        )
    }
}


struct BeerWidgetView: View {
    let entry: BeerEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .accessoryCircular {
                VStack(spacing: 0) {
                    Text("🍺")
                        .font(.system(size: 19))

                    Text("\(entry.total)")
                        .font(.system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        ))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("🍺 BEER EARNED")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.yellow)

                    HStack {
                        Text("Activity")
                        Spacer()
                        Text("\(entry.activity) beers")
                            .bold()
                    }

                    HStack {
                        Text("Total today")
                        Spacer()
                        Text("\(entry.total) beers")
                            .bold()
                            .foregroundStyle(.yellow)
                    }
                }
                .font(.caption2)
            }
        }
        .containerBackground(
            .fill.tertiary,
            for: .widget
        )
    }
}


struct BeerEarnedWidget: Widget {
    let kind = "BeerEarnedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: BeerProvider()
        ) { entry in
            BeerWidgetView(entry: entry)
        }
        .configurationDisplayName("Beer Earned")
        .description("Your daily earned beers.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

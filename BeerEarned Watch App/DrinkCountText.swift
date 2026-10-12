import Foundation

// This file is intentionally included in both targets: the main watch app
// and Widget Extension have separate localizations and separate modules.
enum DrinkCountText {
    static func formatted(_ count: Int, drink: String) -> String {
        let amount = max(0, count)
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let isCzech = language.hasPrefix("cs")

        let key: String
        if drink == "cola" {
            if amount == 1 {
                key = "count_cola_one"
            } else if isCzech && (2...4).contains(amount) {
                key = "count_cola_few"
            } else {
                key = "count_cola_many"
            }
        } else if drink == "prosecco" {
            if amount == 1 {
                key = "count_prosecco_one"
            } else if isCzech && (2...4).contains(amount) {
                key = "count_prosecco_few"
            } else {
                key = "count_prosecco_many"
            }
        } else {
            if amount == 20 {
                return NSLocalizedString("count_beer_crate", comment: "20 beers")
            }
            if amount == 1 {
                key = "count_beer_one"
            } else if isCzech && (2...4).contains(amount) {
                key = "count_beer_few"
            } else {
                key = "count_beer_many"
            }
        }
        let template = NSLocalizedString(key, comment: "Drink count")
        return String(format: template, locale: .current, amount)
    }

    static func circular(_ count: Int, drink: String) -> String {
        if drink == "beer" && count == 20 {
            return NSLocalizedString("count_beer_crate_short", comment: "Crate")
        }
        return String(max(0, count))
    }
}

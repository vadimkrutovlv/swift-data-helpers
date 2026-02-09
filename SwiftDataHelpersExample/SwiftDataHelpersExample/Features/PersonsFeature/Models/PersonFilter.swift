import Foundation
import SwiftData

enum PersonFilter: String, CaseIterable, Identifiable {
    case all
    case adults
    case minors

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            "All"
        case .adults:
            "Adults"
        case .minors:
            "Minors"
        }
    }

    var predicate: Predicate<Person>? {
        switch self {
        case .all:
            return nil
        case .adults:
            return #Predicate<Person> { $0.age >= 18 }
        case .minors:
            return #Predicate<Person> { $0.age < 18 }
        }
    }
}

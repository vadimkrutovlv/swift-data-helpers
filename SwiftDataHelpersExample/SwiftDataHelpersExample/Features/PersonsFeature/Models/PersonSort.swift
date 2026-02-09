import Foundation
import SwiftData

enum PersonSort: String, CaseIterable, Identifiable {
    case name
    case age

    var id: Self { self }

    var title: String {
        switch self {
        case .name:
            "Name"
        case .age:
            "Age"
        }
    }

    var descriptors: [SortDescriptor<Person>] {
        switch self {
        case .name:
            [.init(\.name)]
        case .age:
            [.init(\.age)]
        }
    }
}

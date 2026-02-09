import SwiftData

enum Database {
    case main
    case privatePersons

    var container: ModelContainer {
        switch self {
        case .main:
            .main
        case .privatePersons:
            .privatePersons
        }
    }
}

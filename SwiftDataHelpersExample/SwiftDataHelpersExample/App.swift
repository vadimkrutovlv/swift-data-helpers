import Dependencies
import SwiftDataHelpers
import SwiftData
import SwiftUI

@main
struct SwiftDataHelpersExampleApp: App {
    let container: ModelContainer = .main

    init() {
        let container = self.container
        prepareDependencies {
            $0.liveQueryContext.modelContext = { container.mainContext }
        }
    }

    var body: some Scene {
        WindowGroup {
            PersonsView()
                .modelContainer(container)
        }
    }
}

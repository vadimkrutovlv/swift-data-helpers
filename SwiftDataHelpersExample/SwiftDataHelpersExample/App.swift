import Dependencies
import SwiftDataHelpers
import SwiftData
import SwiftUI

@main
struct SwiftDataHelpersExampleApp: App {
    let container: ModelContainer = .main
    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        let container = self.container
        prepareDependencies {
            $0.liveQueryContext.modelContext = { container.mainContext }
        }
    }

    var body: some Scene {
        WindowGroup {
            if !Self.isRunningTests {
                PersonsView()
                    .modelContainer(container)
            }
        }
    }
}

import Foundation
import OSLog

@MainActor
final class LiveQueryObservationRegistry {
    typealias ObservationTaskFactory = @MainActor () -> Task<Void, Never>

    private var observationTaskFactories: [ObjectIdentifier: ObservationTaskFactory] = [:]
    private var observationTasks: [ObjectIdentifier: Task<Void, Never>] = [:]
    private var isObserving = false

    func register(
        key: ObjectIdentifier,
        taskFactory: @escaping ObservationTaskFactory
    ) {
        guard observationTaskFactories[key] == nil else {
            Logger.liveQuery.error("Duplicate LiveQuery observation registration for key: \(String(describing: key), privacy: .public)")
            return
        }

        observationTaskFactories[key] = taskFactory

        guard isObserving else { return }
        observationTasks[key] = taskFactory()
    }

    func startIfNeeded() {
        isObserving = true

        for (key, taskFactory) in observationTaskFactories where observationTasks[key] == nil {
            observationTasks[key] = taskFactory()
        }
    }

    func stop() {
        isObserving = false

        for task in observationTasks.values {
            task.cancel()
        }

        observationTasks.removeAll()
    }
}

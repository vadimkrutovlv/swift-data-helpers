import Testing
@testable import SwiftDataHelpers

@Suite("LiveQueryObservationRegistry")
@MainActor
struct LiveQueryObservationRegistryTests {
    @Test("Starts registered observers when started")
    func startsRegisteredObserversWhenStarted() async {
        let recorder = ObservationTaskRecorder()
        let registry = LiveQueryObservationRegistry()
        let key = ObjectIdentifier(ObservationKeys.First.self)

        registry.register(key: key) {
            recorder.makeTask(for: key)
        }

        #expect(recorder.startedKeys.isEmpty)
        registry.startIfNeeded()

        await yieldUntil({ recorder.startedKeys == [key] })

        registry.stop()
        await yieldUntil({ recorder.cancelledKeys == [key] })
    }

    @Test("startIfNeeded does not duplicate running tasks")
    func startIfNeededDoesNotDuplicateRunningTasks() async {
        let recorder = ObservationTaskRecorder()
        let registry = LiveQueryObservationRegistry()
        let key = ObjectIdentifier(ObservationKeys.First.self)

        registry.register(key: key) {
            recorder.makeTask(for: key)
        }

        registry.startIfNeeded()
        await yieldUntil({ recorder.startedKeys.count == 1 })

        registry.startIfNeeded()
        await yield(times: 50)

        #expect(recorder.startedKeys.count == 1)

        registry.stop()
        await yieldUntil({ recorder.cancelledKeys.count == 1 })
    }

    @Test("stop cancels all running tasks")
    func stopCancelsAllRunningTasks() async {
        let recorder = ObservationTaskRecorder()
        let registry = LiveQueryObservationRegistry()
        let firstKey = ObjectIdentifier(ObservationKeys.First.self)
        let secondKey = ObjectIdentifier(ObservationKeys.Second.self)

        registry.register(key: firstKey) {
            recorder.makeTask(for: firstKey)
        }
        registry.register(key: secondKey) {
            recorder.makeTask(for: secondKey)
        }

        registry.startIfNeeded()
        await yieldUntil({ recorder.startedKeys.count == 2 })

        registry.stop()
        await yieldUntil({ recorder.cancelledKeys.count == 2 })
    }

    @Test("Registry restarts tasks after stop")
    func registryRestartsTasksAfterStop() async {
        let recorder = ObservationTaskRecorder()
        let registry = LiveQueryObservationRegistry()
        let key = ObjectIdentifier(ObservationKeys.First.self)

        registry.register(key: key) {
            recorder.makeTask(for: key)
        }

        registry.startIfNeeded()
        await yieldUntil({ recorder.startedKeys.count == 1 })

        registry.stop()
        await yieldUntil({ recorder.cancelledKeys.count == 1 })

        registry.startIfNeeded()
        await yieldUntil({ recorder.startedKeys.count == 2 })

        registry.stop()
        await yieldUntil({ recorder.cancelledKeys.count == 2 })
    }

    @Test("Supports multiple distinct observation keys")
    func supportsMultipleDistinctObservationKeys() async {
        let recorder = ObservationTaskRecorder()
        let registry = LiveQueryObservationRegistry()
        let firstKey = ObjectIdentifier(ObservationKeys.First.self)
        let secondKey = ObjectIdentifier(ObservationKeys.Second.self)
        let thirdKey = ObjectIdentifier(ObservationKeys.Third.self)

        registry.register(key: firstKey) {
            recorder.makeTask(for: firstKey)
        }
        registry.register(key: secondKey) {
            recorder.makeTask(for: secondKey)
        }
        registry.register(key: thirdKey) {
            recorder.makeTask(for: thirdKey)
        }

        registry.startIfNeeded()
        await yieldUntil({ Set(recorder.startedKeys) == Set([firstKey, secondKey, thirdKey]) })

        registry.stop()
        await yieldUntil({ Set(recorder.cancelledKeys) == Set([firstKey, secondKey, thirdKey]) })
    }

    @Test("Duplicate registration is ignored")
    func duplicateRegistrationIsIgnored() async {
        let firstRecorder = ObservationTaskRecorder()
        let secondRecorder = ObservationTaskRecorder()
        let registry = LiveQueryObservationRegistry()
        let key = ObjectIdentifier(ObservationKeys.First.self)

        registry.register(key: key) {
            firstRecorder.makeTask(for: key)
        }
        registry.register(key: key) {
            secondRecorder.makeTask(for: key)
        }

        registry.startIfNeeded()
        await yieldUntil({ firstRecorder.startedKeys.count == 1 })
        await yield(times: 50)

        #expect(secondRecorder.startedKeys.isEmpty)

        registry.stop()
        await yieldUntil({ firstRecorder.cancelledKeys.count == 1 })
    }
}

@MainActor
private enum ObservationKeys {
    final class First {}
    final class Second {}
    final class Third {}
}

@MainActor
private final class ObservationTaskRecorder {
    var startedKeys: [ObjectIdentifier] = []
    var cancelledKeys: [ObjectIdentifier] = []

    func makeTask(for key: ObjectIdentifier) -> Task<Void, Never> {
        return Task { @MainActor [weak self] in
            guard let self else { return }
            startedKeys.append(key)

            defer {
                cancelledKeys.append(key)
            }

            while !Task.isCancelled {
                await Task.yield()
            }
        }
    }
}

@MainActor
private func yieldUntil(
    _ condition: @escaping () -> Bool,
    maxIterations: Int = 1_000
) async {
    for _ in 0..<maxIterations {
        if condition() { return }
        await Task.yield()
    }
}

@MainActor
private func yield(times: Int) async {
    for _ in 0..<max(0, times) {
        await Task.yield()
    }
}

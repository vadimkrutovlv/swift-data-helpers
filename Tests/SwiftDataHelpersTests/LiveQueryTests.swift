import Foundation
import SwiftData
import Testing
@testable import SwiftDataHelpers

@Suite("LiveQuery")
struct LiveQueryTests {
    @Model
    final class TestItem {
        var name: String
        var isEnabled: Bool

        init(name: String, isEnabled: Bool) {
            self.name = name
            self.isEnabled = isEnabled
        }
    }

    @Model
    final class OtherItem {
        var value: Int

        init(value: Int) {
            self.value = value
        }
    }

    @MainActor
    @Test("Fetches initial models (predicate + sort)")
    func initialFetchRespectsPredicateAndSort() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)
        readerContext.autosaveEnabled = true

        writerContext.insert(TestItem(name: "B", isEnabled: true))
        writerContext.insert(TestItem(name: "A", isEnabled: true))
        writerContext.insert(TestItem(name: "C", isEnabled: false))
        try writerContext.save()

        let predicate = #Predicate<TestItem> { $0.isEnabled == true }
        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let expectedNames = ["A", "B"]

        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: predicate,
            sort: sort
        )
        storage.update(context: readerContext, predicate: predicate, sort: sort)

        await yieldUntil({ storage.fetched.count == 2 })
        #expect(storage.fetched.map(\TestItem.name) == expectedNames)
    }

    @MainActor
    @Test("Refreshes after save in same container")
    func refreshesAfterSaveInSameContainer() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        try writerContext.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: nil,
            sort: sort
        )
        storage.update(context: readerContext, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A"] })
        #expect(storage.fetched.map(\TestItem.name) == ["A"])

        writerContext.insert(TestItem(name: "B", isEnabled: true))
        try writerContext.save()

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A", "B"] })
        #expect(storage.fetched.map(\TestItem.name) == ["A", "B"])
    }

    @MainActor
    @Test("Ignores saves from other containers")
    func ignoresSavesFromOtherContainers() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        try writerContext.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: nil,
            sort: sort
        )
        storage.update(context: readerContext, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A"] })
        #expect(storage.fetched.map(\TestItem.name) == ["A"])

        let otherContainer = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let otherContext = ModelContext(otherContainer)
        otherContext.insert(TestItem(name: "B", isEnabled: true))
        try otherContext.save()

        await yield(times: 100)
        #expect(storage.fetched.map(\TestItem.name) == ["A"])

        writerContext.insert(TestItem(name: "C", isEnabled: true))
        try writerContext.save()

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A", "C"] })
        #expect(storage.fetched.map(\TestItem.name) == ["A", "C"])
    }

    @MainActor
    @Test("Returns empty when model is missing from container schema")
    func returnsEmptyWhenModelIsMissingFromContainerSchema() async throws {
        let container = try ModelContainer(
            for: OtherItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let storage = LiveQuery<TestItem>.Storage(
            context: context,
            predicate: nil,
            sort: []
        )
        storage.update(context: context, predicate: nil, sort: [])

        await yieldUntil({ storage.fetched.isEmpty })
        #expect(storage.fetched.isEmpty)
    }

    @MainActor
    @Test("Updates predicate and sort on update")
    func updatesPredicateAndSort() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        writerContext.insert(TestItem(name: "B", isEnabled: false))
        writerContext.insert(TestItem(name: "C", isEnabled: true))
        try writerContext.save()

        let enabledPredicate = #Predicate<TestItem> { $0.isEnabled == true }
        let nameAscending = [SortDescriptor<TestItem>(\.name, order: .forward)]

        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: enabledPredicate,
            sort: nameAscending
        )
        storage.update(context: readerContext, predicate: enabledPredicate, sort: nameAscending)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A", "C"] })
        #expect(storage.fetched.map(\TestItem.name) == ["A", "C"])

        let disabledPredicate = #Predicate<TestItem> { $0.isEnabled == false }
        let nameDescending = [SortDescriptor<TestItem>(\.name, order: .reverse)]

        storage.update(context: readerContext, predicate: disabledPredicate, sort: nameDescending)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["B"] })
        #expect(storage.fetched.map(\TestItem.name) == ["B"])
    }

    @MainActor
    @Test("Switches containers on update")
    func switchesContainerOnUpdate() async throws {
        let containerA = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let containerB = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let contextA = ModelContext(containerA)
        let contextB = ModelContext(containerB)

        contextA.insert(TestItem(name: "A", isEnabled: true))
        try contextA.save()

        contextB.insert(TestItem(name: "B", isEnabled: true))
        try contextB.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: contextA,
            predicate: nil,
            sort: sort
        )
        storage.update(context: contextA, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A"] })
        #expect(storage.fetched.map(\TestItem.name) == ["A"])

        storage.update(context: contextB, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["B"] })
        #expect(storage.fetched.map(\TestItem.name) == ["B"])
    }

    @MainActor
    @Test("Stream replays current snapshot on subscribe")
    func streamReplaysCurrentSnapshotOnSubscribe() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        writerContext.insert(TestItem(name: "B", isEnabled: true))
        try writerContext.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: nil,
            sort: sort
        )
        storage.update(context: readerContext, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A", "B"] })

        let snapshots = SnapshotRecorder()
        let streamTask = Task { @MainActor in
            for await snapshot in storage.valuesStream() {
                snapshots.values.append(snapshot.map(\TestItem.name))
                break
            }
        }

        await yieldUntil({ snapshots.values.count == 1 })
        #expect(snapshots.values.first == ["A", "B"])

        streamTask.cancel()
        _ = await streamTask.result
    }

    @MainActor
    @Test("Stream emits after save in same container")
    func streamEmitsAfterSaveInSameContainer() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        try writerContext.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: nil,
            sort: sort
        )
        storage.update(context: readerContext, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A"] })

        let snapshots = SnapshotRecorder()
        let streamTask = Task { @MainActor in
            for await snapshot in storage.valuesStream() {
                snapshots.values.append(snapshot.map(\TestItem.name))

                if snapshots.values.count == 2 {
                    break
                }
            }
        }

        await yieldUntil({ snapshots.values.count >= 1 })
        #expect(snapshots.values.first == ["A"])

        writerContext.insert(TestItem(name: "B", isEnabled: true))
        try writerContext.save()

        await yieldUntil({ snapshots.values.count >= 2 })
        #expect(snapshots.values.dropFirst().first == ["A", "B"])

        streamTask.cancel()
        _ = await streamTask.result
    }

    @MainActor
    @Test("Stream broadcasts updates to multiple subscribers")
    func streamBroadcastsUpdatesToMultipleSubscribers() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        try writerContext.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: nil,
            sort: sort
        )
        storage.update(context: readerContext, predicate: nil, sort: sort)

        await yieldUntil({ storage.fetched.map(\TestItem.name) == ["A"] })

        let firstSubscriber = SnapshotRecorder()
        let secondSubscriber = SnapshotRecorder()

        let firstTask = Task { @MainActor in
            for await snapshot in storage.valuesStream() {
                firstSubscriber.values.append(snapshot.map(\TestItem.name))

                if firstSubscriber.values.count == 2 {
                    break
                }
            }
        }

        let secondTask = Task { @MainActor in
            for await snapshot in storage.valuesStream() {
                secondSubscriber.values.append(snapshot.map(\TestItem.name))

                if secondSubscriber.values.count == 2 {
                    break
                }
            }
        }

        await yieldUntil({
            firstSubscriber.values.count >= 1
                && secondSubscriber.values.count >= 1
        })
        #expect(firstSubscriber.values.first == ["A"])
        #expect(secondSubscriber.values.first == ["A"])

        writerContext.insert(TestItem(name: "B", isEnabled: true))
        try writerContext.save()

        await yieldUntil({
            firstSubscriber.values.count >= 2
                && secondSubscriber.values.count >= 2
        })
        #expect(firstSubscriber.values.dropFirst().first == ["A", "B"])
        #expect(secondSubscriber.values.dropFirst().first == ["A", "B"])

        firstTask.cancel()
        secondTask.cancel()
        _ = await firstTask.result
        _ = await secondTask.result
    }

    @MainActor
    @Test("Stream starts observing without update call")
    func streamStartsObservingWithoutUpdateCall() async throws {
        let container = try ModelContainer(
            for: TestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let writerContext = ModelContext(container)
        let readerContext = ModelContext(container)

        writerContext.insert(TestItem(name: "A", isEnabled: true))
        try writerContext.save()

        let sort = [SortDescriptor<TestItem>(\.name, order: .forward)]
        let storage = LiveQuery<TestItem>.Storage(
            context: readerContext,
            predicate: nil,
            sort: sort
        )

        let snapshots = SnapshotRecorder()
        let streamTask = Task { @MainActor in
            for await snapshot in storage.valuesStream(replayCurrentValue: false) {
                snapshots.values.append(snapshot.map(\TestItem.name))

                if snapshots.values.count == 2 {
                    break
                }
            }
        }

        await yieldUntil({ snapshots.values.count >= 1 })
        #expect(snapshots.values.first == ["A"])

        writerContext.insert(TestItem(name: "B", isEnabled: true))
        try writerContext.save()

        await yieldUntil({ snapshots.values.count >= 2 })
        #expect(snapshots.values.dropFirst().first == ["A", "B"])

        streamTask.cancel()
        _ = await streamTask.result
    }
}

@MainActor
private final class SnapshotRecorder {
    var values: [[String]] = []
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

import Dependencies
import Foundation
import OSLog
import Observation
import SwiftData
import SwiftUI

/// A SwiftUI dynamic property that keeps a collection of models in sync with a `ModelContext`.
///
/// `LiveQuery` fetches identifiers using the current container, resolves models
/// from the active `ModelContext`, and refreshes when `ModelContext.didSave`
/// notifications are posted from the same container.
///
/// ## Example
///
/// ```swift
/// struct PeopleView: View {
///     @LiveQuery(
///         predicate: #Predicate<Person> { $0.isActive },
///         sort: [SortDescriptor(\Person.name)]
///     )
///     private var people
///
///     var body: some View {
///         List(people) { person in
///             Text(person.name)
///         }
///     }
/// }
/// ```
///
/// - Important: Configure ``Dependencies/DependencyValues/liveQueryContext`` before creating
///   a `@LiveQuery`. You can wrap views in ``LiveQueryBindable`` or set
///   `liveQueryContext.modelContext` in `prepareDependencies`.
@MainActor
@propertyWrapper
public struct LiveQuery<Model: PersistentModel>: @MainActor DynamicProperty {
    @Dependency(\.liveQueryContext) private var liveQueryContext
    @State private var storage: Storage

    private let predicate: Predicate<Model>?
    private let sort: [SortDescriptor<Model>]

    /// Creates a live query with an optional predicate and sort descriptors.
    ///
    /// - Parameters:
    ///   - predicate: A `Predicate` used to filter results. Pass `nil` to
    ///     fetch all models.
    ///   - sort: Sort descriptors applied to the fetched models. An empty
    ///     array preserves store order.
    ///
    /// - Important: If `liveQueryContext.modelContext` is not configured, this
    ///   initializer logs a fault and returns empty results until configured.
    public init(
        predicate: Predicate<Model>? = nil,
        sort: [SortDescriptor<Model>] = []
    ) {
        self.predicate = predicate
        self.sort = sort
        @Dependency(\.liveQueryContext) var liveQueryContext

        do {
            let context = try liveQueryContext.modelContext()
            _storage = State(initialValue: Storage(
                context: context,
                predicate: predicate,
                sort: sort
            ))
        } catch {
            Logger.liveQuery.error(
                "Model context dependency threw an error: \(error, privacy: .public)"
            )
            _storage = State(initialValue: Storage(
                context: nil,
                predicate: predicate,
                sort: sort
            ))
        }
    }

    /// The current models fetched by the live query.
    ///
    /// This array updates when the underlying model container saves changes.
    public var wrappedValue: [Model] {
        return storage.fetched
    }

    /// Access to projected helpers for `@LiveQuery`.
    ///
    /// Use `$items.valuesStream` to iterate over snapshots as the query refreshes.
    public var projectedValue: Projection {
        return .init(storage: storage)
    }

    /// Updates the query when dependencies or parameters change.
    ///
    /// SwiftUI calls this as part of `DynamicProperty`; you generally should
    /// not call it directly.
    public mutating func update() {
        do {
            let context = try liveQueryContext.modelContext()
            storage.update(
                context: context,
                predicate: predicate,
                sort: sort
            )
        } catch {
            Logger.liveQuery.error(
                "Model context dependency threw an error: \(error, privacy: .public)"
            )
        }
    }
}

extension LiveQuery {
    @MainActor
    @Observable
    final class Storage {
        @ObservationIgnored private var context: ModelContext?
        @ObservationIgnored private var predicate: Predicate<Model>?
        @ObservationIgnored private var sort: [SortDescriptor<Model>]
        @ObservationIgnored private var fetcher: LiveQueryFetcher?
        @ObservationIgnored private var containerID: ObjectIdentifier?
        @ObservationIgnored private var isObserving = false
        @ObservationIgnored private var observationTask: Task<Void, Never>?
        @ObservationIgnored private var valuesStreamContinuations: [UUID: AsyncStream<[Model]>.Continuation] = [:]

        var fetched: [Model] = [] {
            didSet {
                publishFetched()
            }
        }

        init(
            context: ModelContext?,
            predicate: Predicate<Model>? = nil,
            sort: [SortDescriptor<Model>] = []
        ) {
            self.predicate = predicate
            self.sort = sort

            if let context {
                configure(context: context)
            } else {
                self.context = nil
                self.fetcher = nil
                self.containerID = nil
            }
        }

        func update(
            context: ModelContext,
            predicate: Predicate<Model>?,
            sort: [SortDescriptor<Model>]
        ) {
            self.predicate = predicate
            self.sort = sort

            guard let containerID else {
                configure(context: context)
                startObserving()
                return
            }

            let newContainerID = ObjectIdentifier(context.container)
            let containerChanged = newContainerID != containerID

            if containerChanged {
                configure(context: context)
            }

            guard isObserving else  {
                startObserving()
                return
            }

            if containerChanged {
                restartObserving()
            } else {
                Task { [weak self] in
                    guard let self else { return }
                    fetched = await refresh()
                }
            }
        }

        func valuesStream(replayCurrentValue: Bool = true) -> AsyncStream<[Model]> {
            return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
                let id = UUID()
                valuesStreamContinuations[id] = continuation
                startObservingIfNeededForStream()

                if replayCurrentValue {
                    // SAFETY: `LiveQuery` is `@MainActor`; stream snapshots are sourced
                    // from this main-actor-isolated state.
                    let snapshot = UncheckedSendable(wrappedValue: fetched)
                    continuation.yield(snapshot.wrappedValue)
                }

                continuation.onTermination = { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.valuesStreamContinuations.removeValue(forKey: id)
                    }
                }
            }
        }

        private func startObservingIfNeededForStream() {
            guard !isObserving else { return }
            startObserving()
        }

        private func configure(context: ModelContext) {
            self.context = context
            self.fetcher = .init(modelContainer: context.container)
            self.containerID = ObjectIdentifier(context.container)
        }

        private func observeChanges() async {
            fetched = await refresh()

            let notifications = NotificationCenter
                .default
                .notifications(named: ModelContext.didSave)

            for await notification in notifications {
                if Task.isCancelled { break }

                guard let savingContext = notification.object as? ModelContext else { continue }
                guard let containerID else { continue }
                guard ObjectIdentifier(savingContext.container) == containerID else { continue }

                fetched = await refresh()
            }
        }

        private func startObserving() {
            guard containerID != nil else { return }
            isObserving = true
            observationTask = Task { [weak self] in
                guard let self else { return }
                await self.observeChanges()
            }
        }

        private func restartObserving() {
            observationTask?.cancel()
            observationTask = nil
            startObserving()
        }

        private func publishFetched() {
            // SAFETY: `LiveQuery` is `@MainActor`; stream snapshots are sourced
            // from this main-actor-isolated state.
            let snapshot = UncheckedSendable(wrappedValue: fetched)

            for continuation in valuesStreamContinuations.values {
                continuation.yield(snapshot.wrappedValue)
            }
        }

        private func refresh() async -> [Model] {
            guard let fetcher, let context else { return [] }

            do {
                let ids = try await fetcher.fetchIDs(predicate: predicate)
                let models = ids.compactMap { context.model(for: $0) as? Model }

                if !sort.isEmpty {
                    return models.sorted(using: sort)
                } else {
                    return models
                }
            } catch {
                Logger.liveQuery.error("Error occurred while fetching \(Model.self): \(error)")
            }

            return []
        }

        deinit {
            observationTask?.cancel()
            observationTask = nil

            for continuation in valuesStreamContinuations.values {
                continuation.finish()
            }

            valuesStreamContinuations.removeAll()
        }
    }

    @MainActor
    public struct Projection {
        private let storage: Storage

        fileprivate init(storage: Storage) {
            self.storage = storage
        }

        /// An async stream of query snapshots.
        ///
        /// New subscribers immediately receive the current `wrappedValue`, then
        /// subsequent values after each refresh.
        public var valuesStream: AsyncStream<[Model]> {
            return storage.valuesStream()
        }
    }
}

extension LiveQuery.Projection {
    var observationKey: ObjectIdentifier {
        return ObjectIdentifier(storage)
    }
}

@ModelActor
private actor LiveQueryFetcher {
    func fetchIDs<M: PersistentModel>(
        predicate: Predicate<M>?
    ) throws -> [PersistentIdentifier] {
        let descriptor = FetchDescriptor<M>(predicate: predicate)
        return try modelContext.fetchIdentifiers(descriptor)
    }
}

#if canImport(UIKit)
import SwiftData
import UIKit

/// A UIKit base controller that manages `@LiveQuery` stream observation lifecycle.
///
/// Register projected `@LiveQuery` values with ``observe(_:onSnapshot:)`` (typically in
/// `viewDidLoad`). Observation starts in `viewDidAppear`, stops in
/// `viewDidDisappear`, and is cancelled on deallocation.
@MainActor
open class LiveQueryViewController: UIViewController {
    private let liveQueryObservationRegistry = LiveQueryObservationRegistry()

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        liveQueryObservationRegistry.startIfNeeded()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        liveQueryObservationRegistry.stop()
    }

    /// Registers a `@LiveQuery` projection for lifecycle-managed snapshot observation.
    ///
    /// Call this once per projection, usually from `viewDidLoad`.
    ///
    /// - Parameters:
    ///   - projection: The projected `@LiveQuery` value (for example, `$people`).
    ///   - onSnapshot: Closure called for every emitted snapshot while observation is active.
    public final func observe<Model: PersistentModel>(
        _ projection: LiveQuery<Model>.Projection,
        onSnapshot: @escaping @MainActor ([Model]) -> Void
    ) {
        liveQueryObservationRegistry.register(
            key: projection.observationKey,
            taskFactory: {
                Task { @MainActor in
                    for await snapshot in projection.valuesStream {
                        if Task.isCancelled { break }
                        onSnapshot(snapshot)
                    }
                }
            }
        )
    }

    isolated deinit { liveQueryObservationRegistry.stop() }
}
#endif

import OSLog

@_documentation(visibility: internal)
public enum SwiftDataHelpersRelationshipQueriesLogger {
    private static let logger = Logger(
        subsystem: "lv.krutov.SwiftDataHelpers",
        category: "RelationshipQueries"
    )

    public static func fetchFailed(
        method: String,
        relatedType: String,
        error: any Error
    ) {
        logger.error(
            "Failed relationship query fetch for \(relatedType, privacy: .public) via \(method, privacy: .public): \(String(describing: error), privacy: .public)"
        )
    }
}

import SwiftDataHelpers
import SwiftUI

struct FilteredPersonsList: View {
    private let filter: PersonFilter
    private let sort: PersonSort
    private let onEdit: (Person) -> Void
    private let onDelete: (Person) -> Void

    @LiveQuery private var persons: [Person]

    init(
        filter: PersonFilter,
        sort: PersonSort,
        onEdit: @escaping (Person) -> Void,
        onDelete: @escaping (Person) -> Void
    ) {
        self.filter = filter
        self.sort = sort
        self.onEdit = onEdit
        self.onDelete = onDelete
        _persons = LiveQuery(predicate: filter.predicate, sort: sort.descriptors)
    }

    var body: some View {
        if persons.isEmpty {
            ContentUnavailableView(
                "No people",
                systemImage: "person",
                description: Text("Tap + to add one.")
            )
        } else {
            ForEach(persons) { person in
                PersonRow(
                    person: person,
                    onEdit: { onEdit(person) },
                    onDelete: { onDelete(person) }
                )
            }
        }
    }
}

import Dependencies
import SwiftData
import SwiftDataHelpers
import SwiftUI

struct PersonsView: View {
    @State private var model = PersonsFeatureModel()

    var body: some View {
        NavigationStack {
            List {
                mainSection
                mainUIKitSection
                petsSection
                privateSection
                migrationNoteSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("People")
            .sheet(item: $model.editor) { editor in
                NavigationStack {
                    PersonFormView(
                        editor: editor,
                        onSave: { name, age in
                            model.savePerson(editor: editor, name: name, age: age)
                            model.editor = nil
                        },
                        onCancel: { model.editor = nil }
                    )
                    .modelContainer(editor.database == .main ? .main : .privatePersons)
                }
            }
            .toolbar { toolbarContent }
        }
    }
}

private extension PersonsView {
    var mainSection: some View {
        PersonsSection(
            title: "Main DB",
            systemImage: "internaldrive"
        ) {
            FilterSortControls(model: model)
            FilteredPersonsList(
                filter: model.filter,
                sort: model.sort,
                onEdit: { person in model.editPerson(person, database: .main) },
                onDelete: { person in model.deletePerson(person, database: .main) }
            )
        }
    }

    var privateSection: some View {
        LiveQueryBindable(modelContainer: .privatePersons) {
            PrivatePersonsSection(model: model)
        }
    }

    var mainUIKitSection: some View {
        PersonsSection(
            title: "Main DB (UIKit)",
            systemImage: "tablecells"
        ) {
            LiveQueryBindable(modelContainer: .main) {
                MainDatabaseUIKitPersonsList()
                    .frame(height: 250)
                    .listRowInsets(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        }
    }

    var petsSection: some View {
        PetsSection(model: model)
    }

    var migrationNoteSection: some View {
        Section("Migration Note") {
            Text("This demo does not ship a migration plan. If the app fails to load after a schema change, delete it to recreate the stores.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Add to Main DB") {
                    model.addPerson(database: .main)
                }
                Button("Add to Private DB") {
                    model.addPerson(database: .privatePersons)
                }

                Divider()

                Button("Import 5 in Background (Main)") {
                    model.importRandomPeople(count: 5, database: .main)
                }
                Button("Import 5 in Background (Private)") {
                    model.importRandomPeople(count: 5, database: .privatePersons)
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
}

private struct PrivatePersonsSection: View {
    @LiveQuery(sort: [.init(\.name)]) private var persons: [Person]
    let model: PersonsFeatureModel

    var body: some View {
        PersonsSection(title: "Private DB", systemImage: "lock") {
            if persons.isEmpty {
                ContentUnavailableView(
                    "No people",
                    systemImage: "lock",
                    description: Text("Tap + to add one to the Private DB.")
                )
            } else {
                ForEach(persons) { person in
                    PersonRow(
                        person: person,
                        onEdit: { model.editPerson(person, database: .privatePersons) },
                        onDelete: { model.deletePerson(person, database: .privatePersons) }
                    )
                }
            }
        }
    }
}

#Preview() {
    prepareDependencies {
        $0.liveQueryContext.modelContext = { ModelContainer.main.mainContext }
    }

    return PersonsView()
        .modelContainer(.main)
}

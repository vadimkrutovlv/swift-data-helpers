import SwiftUI

struct FilterSortControls: View {
    @Bindable var model: PersonsFeatureModel

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            filterControl
            sortControl
        }
    }
}

private extension FilterSortControls {
    var filterControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Filter")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Filter", selection: $model.filter) {
                ForEach(PersonFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
    }

    var sortControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sort")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Sort", selection: $model.sort) {
                ForEach(PersonSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.segmented)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
    }
}

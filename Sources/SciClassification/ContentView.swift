import SwiftUI

struct ContentView: View {
    @StateObject private var model = TaxonomyViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.96, blue: 0.94)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    searchPanel

                    if model.isLoading {
                        ProgressView("Looking up taxonomy…")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }

                    if let errorMessage = model.errorMessage {
                        errorPanel(errorMessage)
                    }

                    if !model.matches.isEmpty {
                        matchPanel
                    }

                    if let taxon = model.selectedTaxon {
                        resultPanel(for: taxon)
                    }

                    sourceNote
                }
                .frame(maxWidth: 760)
                .padding(32)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 640, minHeight: 640)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color(red: 0.19, green: 0.39, blue: 0.31))
                .frame(width: 56, height: 56)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                Text("Animal Taxonomy")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.13, green: 0.22, blue: 0.18))
                Text("Find an animal and explore its classification.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What animal are you looking for?")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("e.g. tiger, Bengal tiger, or Panthera tigris", text: $model.query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await model.search() } }
                    .accessibilityLabel("Animal name")

                Button {
                    Task { await model.search() }
                } label: {
                    Label("Identify", systemImage: "magnifyingglass")
                        .frame(minWidth: 112)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.19, green: 0.39, blue: 0.31))
                .disabled(model.isLoading || model.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("You can enter a broad name first, then choose a specific type such as Bengal tiger.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }

    private var matchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose the closest match")
                .font(.headline)

            ForEach(model.matches) { taxon in
                Button {
                    Task { await model.select(taxon) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf")
                            .foregroundStyle(Color(red: 0.19, green: 0.39, blue: 0.31))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(taxon.displayName)
                                .font(.body.weight(.semibold))
                            Text("\(taxon.name) · \(taxon.rank.capitalized)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 7)
                .disabled(model.isLoading)
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }

    private func resultPanel(for taxon: Taxon) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "pawprint")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.19, green: 0.39, blue: 0.31))
                    .padding(12)
                    .background(Color(red: 0.92, green: 0.96, blue: 0.92), in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 4) {
                    Text(taxon.displayName)
                        .font(.title2.weight(.bold))
                    Text(taxon.name)
                        .font(.callout.italic())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(taxon.rank.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.92, green: 0.96, blue: 0.92), in: Capsule())
            }

            Divider()

            VStack(spacing: 0) {
                taxonomyRow("Kingdom", value: ancestorValue("kingdom", for: taxon))
                taxonomyRow("Phylum", value: ancestorValue("phylum", for: taxon))
                taxonomyRow("Class", value: ancestorValue("class", for: taxon))
                taxonomyRow("Order", value: ancestorValue("order", for: taxon))
                taxonomyRow("Superfamily", value: ancestorValue("superfamily", for: taxon))
                taxonomyRow("Family", value: ancestorValue("family", for: taxon))
                taxonomyRow("Type", value: typeValue(for: taxon), isLast: true)
            }

            if taxon.rank.lowercased() == "species" {
                subspeciesPanel(for: taxon)
            }
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func subspeciesPanel(for taxon: Taxon) -> some View {
        if model.isLoadingSubspecies {
            ProgressView("Checking for recognized subspecies…")
                .font(.callout)
        } else if !model.subspecies.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Which type of \(taxon.displayName)?")
                    .font(.headline)
                Text("Choose a more specific subspecies, or keep the species-level result above.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                ForEach(model.subspecies) { option in
                    Button {
                        Task { await model.select(option) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.displayName)
                                    .font(.body.weight(.semibold))
                                Text(option.name)
                                    .font(.callout.italic())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color(red: 0.19, green: 0.39, blue: 0.31))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .background(Color(red: 0.96, green: 0.97, blue: 0.95), in: RoundedRectangle(cornerRadius: 12))
                    .disabled(model.isLoading)
                }
            }
            .padding(.top, 4)
        }
    }

    private var sourceNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
            Text("Taxonomy data from iNaturalist · Internet connection required")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }

    private func errorPanel(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.callout)
            .foregroundStyle(Color(red: 0.58, green: 0.22, blue: 0.17))
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 1.0, green: 0.94, blue: 0.91), in: RoundedRectangle(cornerRadius: 12))
    }

    private func taxonomyRow(_ title: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(title)
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .leading)
                Text(value)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 11)

            if !isLast {
                Divider()
            }
        }
    }

    private func ancestorValue(_ rank: String, for taxon: Taxon) -> String {
        taxon.ancestors?.first(where: { $0.rank.lowercased() == rank })?.name
            ?? "Not listed by source"
    }

    private func typeValue(for taxon: Taxon) -> String {
        let rank = taxon.rank.capitalized
        guard let commonName = taxon.preferredCommonName, commonName != taxon.name else {
            return rank
        }
        return "\(rank) — \(commonName)"
    }
}

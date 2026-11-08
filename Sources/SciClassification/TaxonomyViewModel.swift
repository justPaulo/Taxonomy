import Foundation

@MainActor
final class TaxonomyViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var matches: [Taxon] = []
    @Published private(set) var selectedTaxon: Taxon?
    @Published private(set) var subspecies: [Taxon] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingSubspecies = false
    @Published private(set) var errorMessage: String?

    private let client = INaturalistClient()

    func search() async {
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerm.isEmpty, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        matches = []
        selectedTaxon = nil
        subspecies = []

        defer { isLoading = false }

        do {
            let results = try await client.searchAnimals(named: searchTerm)
            guard !results.isEmpty else {
                errorMessage = "No animal matches found. Try another common or scientific name."
                return
            }

            let exactMatch = results.first {
                normalize($0.displayName) == normalize(searchTerm)
                    || normalize($0.name) == normalize(searchTerm)
            }

            if let exactMatch {
                try await load(exactMatch)
            } else if results.count == 1, let onlyResult = results.first {
                try await load(onlyResult)
            } else {
                matches = Array(results.prefix(8))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ taxon: Taxon) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        matches = []
        subspecies = []

        defer { isLoading = false }

        do {
            try await load(taxon)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load(_ taxon: Taxon) async throws {
        let details = try await client.taxon(id: taxon.id)
        selectedTaxon = details

        guard details.rank.lowercased() == "species" else { return }

        isLoadingSubspecies = true
        defer { isLoadingSubspecies = false }

        do {
            subspecies = try await client.subspecies(of: details.id)
        } catch {
            errorMessage = "The classification loaded, but its subspecies could not be retrieved: \(error.localizedDescription)"
        }
    }

    private func normalize(_ value: String) -> String {
        value.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

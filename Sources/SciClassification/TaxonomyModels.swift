import Foundation

struct Taxon: Decodable, Hashable, Identifiable {
    let id: Int
    let name: String
    let rank: String
    let preferredCommonName: String?
    let ancestorIDs: [Int]?
    let ancestors: [TaxonAncestor]?

    var displayName: String {
        preferredCommonName ?? name
    }

    var isAnimal: Bool {
        id == 1 || ancestorIDs?.contains(1) == true
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case rank
        case preferredCommonName = "preferred_common_name"
        case ancestorIDs = "ancestor_ids"
        case ancestors
    }
}

struct TaxonAncestor: Decodable, Hashable {
    let id: Int
    let name: String
    let rank: String
    let preferredCommonName: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case rank
        case preferredCommonName = "preferred_common_name"
    }
}

struct TaxaResponse<TaxonType: Decodable>: Decodable {
    let results: [TaxonType]
}

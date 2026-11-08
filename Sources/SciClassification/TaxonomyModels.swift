import Foundation

struct Taxon: Decodable, Hashable, Identifiable {
    let id: Int
    let name: String
    let rank: String
    let preferredCommonName: String?
    let ancestorIDs: [Int]?
    let ancestors: [TaxonAncestor]?
    let defaultPhoto: TaxonPhoto?

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
        case defaultPhoto = "default_photo"
    }
}

struct TaxonPhoto: Decodable, Hashable {
    let mediumURL: URL?
    let attribution: String?

    private enum CodingKeys: String, CodingKey {
        case mediumURL = "medium_url"
        case attribution
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageURL = try container.decodeIfPresent(URL.self, forKey: .mediumURL)
        mediumURL = imageURL?.scheme == "https" ? imageURL : nil
        attribution = try container.decodeIfPresent(String.self, forKey: .attribution)
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

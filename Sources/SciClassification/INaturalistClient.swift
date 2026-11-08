import Foundation

struct INaturalistClient {
    func searchAnimals(named query: String) async throws -> [Taxon] {
        let response: TaxaResponse<Taxon> = try await request(
            path: "taxa/autocomplete",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "per_page", value: "30"),
                URLQueryItem(name: "locale", value: "en")
            ]
        )
        return response.results.filter(\.isAnimal)
    }

    func taxon(id: Int) async throws -> Taxon {
        let response: TaxaResponse<Taxon> = try await request(
            path: "taxa/\(id)",
            queryItems: [URLQueryItem(name: "locale", value: "en")]
        )
        guard let taxon = response.results.first else {
            throw INaturalistError.noTaxonDetails
        }
        return taxon
    }

    func subspecies(of taxonID: Int) async throws -> [Taxon] {
        let response: TaxaResponse<Taxon> = try await request(
            path: "taxa",
            queryItems: [
                URLQueryItem(name: "parent_id", value: String(taxonID)),
                URLQueryItem(name: "rank", value: "subspecies"),
                URLQueryItem(name: "is_active", value: "true"),
                URLQueryItem(name: "per_page", value: "30"),
                URLQueryItem(name: "locale", value: "en"),
                URLQueryItem(name: "order_by", value: "observations_count")
            ]
        )
        return response.results
    }

    private func request<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> Response {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.inaturalist.org"
        components.path = "/v1/\(path)"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw INaturalistError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SciClassification/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw INaturalistError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw INaturalistError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

enum INaturalistError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case noTaxonDetails
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "Could not create the taxonomy request."
        case .invalidResponse:
            "The taxonomy service returned an invalid response."
        case .noTaxonDetails:
            "The selected animal no longer has a taxonomy record."
        case .httpStatus(let status):
            "The taxonomy service returned HTTP \(status). Please try again."
        }
    }
}

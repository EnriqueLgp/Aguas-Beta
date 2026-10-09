//
//  EvidenceService.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 09/10/26.
//

import Foundation

nonisolated struct EvidenceResponse: Codable, Sendable {
    let idEvidencia: Int
    let tipoEvidencia: String
    let archivoUrl: String
    let formato: String
}

final class EvidenceService {

    static let shared = EvidenceService()

    private init() {}

    private let baseURL = APIConfig.baseURL

    func fetchEvidence(
        for reportID: Int,
        completion: @escaping (Result<EvidenceResponse, Error>) -> Void
    ) {

        guard let accessToken = UserDefaults.standard.string(
            forKey: "accessToken"
        ) else {
            completion(.failure(EvidenceServiceError.missingAccessToken))
            return
        }

        guard let url = URL(
            string: "\(baseURL)/evidencia/reporte/\(reportID)"
        ) else {
            completion(.failure(EvidenceServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        URLSession.shared.dataTask(with: request) {
            data,
            response,
            error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse else {
                completion(.failure(EvidenceServiceError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(EvidenceServiceError.noData))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(
                    .failure(
                        EvidenceServiceError.serverError(
                            httpResponse.statusCode
                        )
                    )
                )
                return
            }

            do {

                let evidences = try JSONDecoder().decode(
                    [EvidenceResponse].self,
                    from: data
                )

                guard let evidence = evidences.first else {
                    completion(
                        .failure(EvidenceServiceError.noEvidence)
                    )
                    return
                }

                completion(.success(evidence))

            } catch {
                completion(.failure(error))
            }

        }.resume()
    }
}

enum EvidenceServiceError: LocalizedError {

    case invalidURL
    case invalidResponse
    case noData
    case noEvidence
    case missingAccessToken
    case serverError(Int)

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "La URL de la evidencia no es válida."

        case .invalidResponse:
            return "La respuesta del servidor no es válida."

        case .noData:
            return "No se recibió información de la evidencia."

        case .noEvidence:
            return "El reporte no tiene evidencia registrada."

        case .missingAccessToken:
            return "No se encontró una sesión activa."

        case .serverError(let statusCode):
            return "El servidor respondió con el código \(statusCode)."
        }
    }
}

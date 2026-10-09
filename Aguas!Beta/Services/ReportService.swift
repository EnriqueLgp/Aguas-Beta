//
//  ReportService.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 08/10/26.
//

import Foundation
import UIKit

nonisolated struct ReportResponse: Codable, Sendable {
    let idReporte: Int
    let descripcion: String?
    let telefonoEstafador: String?
    let enlaceSospechoso: String?
    let fechaReporte: String
    let empresaSuplantada: String
    let estado: String
    let evidenciaPrincipal: String
}

final class ReportService {

    static let shared = ReportService()

    private init() {}

    private let baseURL = APIConfig.baseURL

    func fetchMyReports(
        completion: @escaping (Result<[ReportResponse], Error>) -> Void
    ) {
        fetchReports(
            from: "/reportes/mios",
            completion: completion
        )
    }

    func fetchVerifiedReports(
        completion: @escaping (Result<[ReportResponse], Error>) -> Void
    ) {
        fetchReports(
            from: "/reportes",
            completion: completion
        )
    }

    private func fetchReports(
        from endpoint: String,
        completion: @escaping (Result<[ReportResponse], Error>) -> Void
    ) {

        guard let accessToken = UserDefaults.standard.string(
            forKey: "accessToken"
        ) else {
            completion(.failure(ReportServiceError.missingAccessToken))
            return
        }

        guard let url = URL(
            string: "\(baseURL)\(endpoint)"
        ) else {
            completion(.failure(ReportServiceError.invalidURL))
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
                completion(.failure(ReportServiceError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(ReportServiceError.noData))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(
                    .failure(
                        ReportServiceError.serverError(
                            httpResponse.statusCode
                        )
                    )
                )
                return
            }

            do {

                let reports = try JSONDecoder().decode(
                    [ReportResponse].self,
                    from: data
                )

                completion(.success(reports))

            } catch {
                completion(.failure(error))
            }

        }.resume()
    }

    func createReport(
        draft: ReportDraft,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

        guard let accessToken = UserDefaults.standard.string(
            forKey: "accessToken"
        ) else {
            completion(.failure(ReportServiceError.missingAccessToken))
            return
        }

        guard let url = URL(
            string: "\(baseURL)/reportes"
        ) else {
            completion(.failure(ReportServiceError.invalidURL))
            return
        }

        // multipart/form-data necesita un boundary para separar cada campo enviado
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        appendTextField(
            name: "telefonoEstafador",
            value: draft.phone,
            boundary: boundary,
            to: &body
        )

        appendTextField(
            name: "enlaceSospechoso",
            value: draft.url,
            boundary: boundary,
            to: &body
        )

        appendTextField(
            name: "empresaSuplantada",
            value: draft.impersonatedCompany,
            boundary: boundary,
            to: &body
        )

        appendTextField(
            name: "descripcion",
            value: draft.descriptionText,
            boundary: boundary,
            to: &body
        )

        do {

            if let image = draft.evidenceImages.first {

                guard let imageData = image.jpegData(
                    compressionQuality: 0.85
                ) else {
                    completion(.failure(ReportServiceError.invalidEvidence))
                    return
                }

                appendFile(
                    fieldName: "archivos",
                    fileName: "evidencia.jpg",
                    mimeType: "image/jpeg",
                    fileData: imageData,
                    boundary: boundary,
                    to: &body
                )

            } else if let fileURL = draft.evidenceFileURLs.first {

                let fileData = try Data(
                    contentsOf: fileURL
                )

                appendFile(
                    fieldName: "archivos",
                    fileName: fileURL.lastPathComponent,
                    mimeType: mimeType(for: fileURL),
                    fileData: fileData,
                    boundary: boundary,
                    to: &body
                )

            } else {

                completion(
                    .failure(ReportServiceError.missingEvidence)
                )

                return
            }

        } catch {

            completion(
                .failure(ReportServiceError.invalidEvidence)
            )

            return
        }

        body.append(
            "--\(boundary)--\r\n".data(
                using: .utf8
            )!
        )

        request.httpBody = body

        URLSession.shared.dataTask(with: request) {
            _,
            response,
            error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse =
                    response as? HTTPURLResponse else {
                completion(.failure(ReportServiceError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {

                completion(
                    .failure(
                        ReportServiceError.serverError(
                            httpResponse.statusCode
                        )
                    )
                )

                return
            }

            completion(.success(()))

        }.resume()
    }

    private func appendTextField(
        name: String,
        value: String,
        boundary: String,
        to body: inout Data
    ) {

        let field =
        """
        --\(boundary)\r
        Content-Disposition: form-data; name="\(name)"\r
        \r
        \(value)\r

        """

        if let data = field.data(using: .utf8) {
            body.append(data)
        }
    }

    private func appendFile(
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        boundary: String,
        to body: inout Data
    ) {

        let header =
        """
        --\(boundary)\r
        Content-Disposition: form-data; name="\(fieldName)"; filename="\(fileName)"\r
        Content-Type: \(mimeType)\r
        \r

        """

        if let headerData = header.data(using: .utf8) {
            body.append(headerData)
        }

        body.append(fileData)

        if let lineBreak = "\r\n".data(
            using: .utf8
        ) {
            body.append(lineBreak)
        }
    }

    private func mimeType(
        for url: URL
    ) -> String {

        switch url.pathExtension.lowercased() {

        case "jpg", "jpeg":
            return "image/jpeg"

        case "png":
            return "image/png"

        case "pdf":
            return "application/pdf"

        case "txt":
            return "text/plain"

        default:
            return "application/octet-stream"
        }
    }
}

enum ReportServiceError: LocalizedError {

    case invalidURL
    case invalidResponse
    case noData
    case missingAccessToken
    case missingEvidence
    case invalidEvidence
    case serverError(Int)

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "La URL del servidor no es válida."

        case .invalidResponse:
            return "La respuesta del servidor no es válida."

        case .noData:
            return "El servidor no devolvió información."

        case .missingAccessToken:
            return "No se encontró una sesión activa."

        case .missingEvidence:
            return "El reporte necesita una evidencia."

        case .invalidEvidence:
            return "No fue posible preparar la evidencia seleccionada."

        case .serverError(let statusCode):
            return "El servidor respondió con el código \(statusCode)."
        }
    }
}

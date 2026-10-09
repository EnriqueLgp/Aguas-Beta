//
//  AuthService.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 06/10/26.
//

import Foundation

nonisolated struct RegisterResponse: Codable, Sendable {
    let idUsuario: Int
    let correo: String
}

nonisolated struct LoginResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let nombre: String
}

enum AuthServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL del servidor no es válida."

        case .invalidResponse:
            return "La respuesta del servidor no es válida."

        case .noData:
            return "El servidor no devolvió información."

        case .serverError(let message):
            return message
        }
    }
}

final class AuthService {

    static let shared = AuthService()

    private init() {}

    private let baseURL = APIConfig.baseURL

    // MARK: - Register

    func register(
        nombre: String,
        apellido: String,
        correo: String,
        password: String,
        telefono: String?,
        completion: @escaping (Result<RegisterResponse, Error>) -> Void
    ) {

        guard let url = URL(string: "\(baseURL)/auth/register") else {
            completion(.failure(AuthServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        var body: [String: Any] = [
            "nombre": nombre,
            "apellido": apellido,
            "correo": correo,
            "password": password
        ]

        if let telefono = telefono,
           !telefono.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            body["telefono"] = telefono
        }

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: body
            )
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) {
            data,
            response,
            error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthServiceError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(AuthServiceError.noData))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {

                let message = self.extractErrorMessage(from: data)

                completion(
                    .failure(
                        AuthServiceError.serverError(message)
                    )
                )

                return
            }

            do {

                let result = try JSONDecoder().decode(
                    RegisterResponse.self,
                    from: data
                )

                completion(.success(result))

            } catch {

                completion(.failure(error))
            }

        }.resume()
    }

    // MARK: - Login

    func login(
        correo: String,
        password: String,
        completion: @escaping (Result<LoginResponse, Error>) -> Void
    ) {

        guard let url = URL(string: "\(baseURL)/auth/login") else {
            completion(.failure(AuthServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body: [String: Any] = [
            "correo": correo,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: body
            )
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) {
            data,
            response,
            error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthServiceError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(AuthServiceError.noData))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {

                let message = self.extractErrorMessage(from: data)

                completion(
                    .failure(
                        AuthServiceError.serverError(message)
                    )
                )

                return
            }

            do {

                let result = try JSONDecoder().decode(
                    LoginResponse.self,
                    from: data
                )

                completion(.success(result))

            } catch {

                completion(.failure(error))
            }

        }.resume()
    }

    // MARK: - Error message

    private func extractErrorMessage(from data: Data) -> String {

        if let object = try? JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any] {

            if let message = object["message"] as? String {
                return message
            }

            if let messages = object["message"] as? [String] {
                return messages.joined(separator: "\n")
            }
        }

        return "Ocurrió un error en el servidor."
    }
}

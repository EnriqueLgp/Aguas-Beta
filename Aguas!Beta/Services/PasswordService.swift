//
//  PasswordService.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 18/10/26.
//

import Foundation

nonisolated struct PasswordMessageResponse: Decodable, Sendable {
    let message: String
}

nonisolated struct VerifyResetCodeResponse: Decodable, Sendable {
    let resetToken: String
}

final class PasswordService {

    static let shared = PasswordService()

    private init() {}

    private let baseURL = APIConfig.baseURL

    func forgotPassword(
        correo: String,
        completion: @escaping (Result<PasswordMessageResponse, Error>) -> Void
    ) {

        send(
            path: "/auth/forgot-password",
            method: "POST",
            body: ["correo": correo],
            requiresAuthentication: false,
            completion: completion
        )
    }

    func resendResetCode(
        correo: String,
        completion: @escaping (Result<PasswordMessageResponse, Error>) -> Void
    ) {

        send(
            path: "/auth/resend-reset-code",
            method: "POST",
            body: ["correo": correo],
            requiresAuthentication: false,
            completion: completion
        )
    }

    func verifyResetCode(
        correo: String,
        codigo: String,
        completion: @escaping (Result<VerifyResetCodeResponse, Error>) -> Void
    ) {

        send(
            path: "/auth/verify-reset-code",
            method: "POST",
            body: [
                "correo": correo,
                "codigo": codigo
            ],
            requiresAuthentication: false,
            completion: completion
        )
    }

    func resetPassword(
        resetToken: String,
        password: String,
        completion: @escaping (Result<PasswordMessageResponse, Error>) -> Void
    ) {

        send(
            path: "/auth/reset-password",
            method: "POST",
            body: [
                "resetToken": resetToken,
                "password": password
            ],
            requiresAuthentication: false,
            completion: completion
        )
    }

    func changePassword(
        currentPassword: String,
        newPassword: String,
        completion: @escaping (Result<PasswordMessageResponse, Error>) -> Void
    ) {

        send(
            path: "/auth/change-password",
            method: "PATCH",
            body: [
                "currentPassword": currentPassword,
                "newPassword": newPassword
            ],
            requiresAuthentication: true,
            completion: completion
        )
    }

    private func send<Response: Decodable & Sendable>(
        path: String,
        method: String,
        body: [String: String],
        requiresAuthentication: Bool,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {

        guard let url = URL(string: "\(baseURL)\(path)") else {
            completion(.failure(AuthServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)

        request.httpMethod = method

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: body
            )
        } catch {
            completion(.failure(error))
            return
        }

        let handleResponse: (Result<(Data, HTTPURLResponse), Error>) -> Void = { result in

            switch result {

            case .success(let (data, httpResponse)):

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

                    let response = try JSONDecoder().decode(
                        Response.self,
                        from: data
                    )

                    completion(.success(response))

                } catch {

                    completion(.failure(error))
                }

            case .failure(let error):

                completion(.failure(error))
            }
        }

        if requiresAuthentication {

            AuthenticatedRequest.shared.perform(
                request: request,
                completion: handleResponse
            )

        } else {

            URLSession.shared.dataTask(with: request) {
                data,
                response,
                error in

                if let error = error {
                    handleResponse(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    handleResponse(.failure(AuthServiceError.invalidResponse))
                    return
                }

                guard let data = data else {
                    handleResponse(.failure(AuthServiceError.noData))
                    return
                }

                handleResponse(.success((data, httpResponse)))

            }.resume()
        }
    }

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

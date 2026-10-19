//
//  AuthenticatedRequest.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 18/10/26.
//

import Foundation

final class AuthenticatedRequest {

    static let shared = AuthenticatedRequest()

    private init() {}

    func perform(
        request: URLRequest,
        completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void
    ) {

        send(
            request: request,
            canRetry: true,
            completion: completion
        )
    }

    private func send(
        request: URLRequest,
        canRetry: Bool,
        completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void
    ) {

        var authorizedRequest = request

        if let token = UserDefaults.standard.string(
            forKey: "accessToken"
        ) {
            authorizedRequest.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        URLSession.shared.dataTask(
            with: authorizedRequest
        ) {
            data,
            response,
            error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(
                    .failure(
                        AuthServiceError.invalidResponse
                    )
                )
                return
            }

            guard let data = data else {
                completion(
                    .failure(
                        AuthServiceError.noData
                    )
                )
                return
            }

            if httpResponse.statusCode == 401,
               canRetry {
                
                AuthService.shared.refreshAccessToken { result in

                    switch result {

                    case .success:

                        self.send(
                            request: request,
                            canRetry: false,
                            completion: completion
                        )

                    case .failure(let error):

                        self.clearSession()

                        completion(
                            .failure(error)
                        )
                    }
                }

                return
            }

            completion(
                .success(
                    (
                        data,
                        httpResponse
                    )
                )
            )

        }.resume()
    }

    private func clearSession() {

        UserDefaults.standard.removeObject(
            forKey: "accessToken"
        )

        UserDefaults.standard.removeObject(
            forKey: "refreshToken"
        )

        UserDefaults.standard.removeObject(
            forKey: "userName"
        )

        UserDefaults.standard.removeObject(
            forKey: "userEmail"
        )

        UserDefaults.standard.removeObject(
            forKey: "userRole"
        )

        DispatchQueue.main.async {

            NotificationCenter.default.post(
                name: Notification.Name(
                    "SessionExpired"
                ),
                object: nil
            )
        }
    }
}

//
//  NotificationService.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 18/10/26.
//

import Foundation

enum NotificationServiceError: LocalizedError {
    case invalidURL
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL del servidor no es válida."

        case .serverError(let message):
            return message
        }
    }
}

final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    private let baseURL = APIConfig.baseURL

    func getMyNotifications(
        completion: @escaping (Result<[AppNotification], Error>) -> Void
    ) {

        guard let url = URL(
            string: "\(baseURL)/notificaciones/mias"
        ) else {
            completion(.failure(NotificationServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)

        request.httpMethod = "GET"

        AuthenticatedRequest.shared.perform(
            request: request
        ) { result in

            switch result {

            case .success(let response):

                let data = response.0
                let httpResponse = response.1

                guard (200...299).contains(httpResponse.statusCode) else {

                    let message = self.extractErrorMessage(from: data)

                    completion(
                        .failure(
                            NotificationServiceError.serverError(message)
                        )
                    )

                    return
                }

                do {

                    let notifications = try JSONDecoder().decode(
                        [AppNotification].self,
                        from: data
                    )

                    completion(.success(notifications))

                } catch {

                    completion(.failure(error))
                }

            case .failure(let error):

                completion(.failure(error))
            }
        }
    }

    func markAsRead(
        idNotification: Int,
        completion: @escaping (Result<AppNotification, Error>) -> Void
    ) {

        guard let url = URL(
            string: "\(baseURL)/notificaciones/\(idNotification)/leer"
        ) else {
            completion(.failure(NotificationServiceError.invalidURL))
            return
        }

        var request = URLRequest(url: url)

        request.httpMethod = "PATCH"

        AuthenticatedRequest.shared.perform(
            request: request
        ) { result in

            switch result {

            case .success(let response):

                let data = response.0
                let httpResponse = response.1

                guard (200...299).contains(httpResponse.statusCode) else {

                    let message = self.extractErrorMessage(from: data)

                    completion(
                        .failure(
                            NotificationServiceError.serverError(message)
                        )
                    )

                    return
                }

                do {

                    let notification = try JSONDecoder().decode(
                        AppNotification.self,
                        from: data
                    )

                    completion(.success(notification))

                } catch {

                    completion(.failure(error))
                }

            case .failure(let error):

                completion(.failure(error))
            }
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

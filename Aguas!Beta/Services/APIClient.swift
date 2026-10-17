//
//  APIClient.swift
//  Aguas!Beta
//
//  Manda peticiones al backend con el access token de la sesión.
//
//  El access token dura 15 minutos. Si el backend responde 401 (token
//  vencido), este cliente pide uno nuevo a POST /auth/refresh con el
//  refresh token (dura 7 días) y repite la petición una sola vez. Así el
//  usuario no tiene que volver a iniciar sesión cada 15 minutos.
//
//  Si el refresh también falla (refresh vencido, cuenta borrada o
//  suspendida), se borra la sesión y se avisa con la notificación
//  .aguasSesionTerminada; el SceneDelegate regresa al login.
//

import Foundation

extension Notification.Name {
    /// userInfo["mensaje"]: texto para mostrarle al usuario
    nonisolated static let aguasSesionTerminada = Notification.Name("aguasSesionTerminada")
}

nonisolated enum SessionError: LocalizedError {
    case sinSesion
    case terminada(String)

    var errorDescription: String? {
        switch self {
        case .sinSesion:
            return "No se encontró una sesión activa."
        case .terminada(let mensaje):
            return mensaje
        }
    }
}

nonisolated final class APIClient: @unchecked Sendable {

    static let shared = APIClient()

    private init() {}

    typealias Respuesta = (Data?, URLResponse?, Error?) -> Void

    // Si varias peticiones reciben 401 al mismo tiempo, solo se hace un
    // refresh y las demás esperan su resultado.
    private let lock = NSLock()
    private var refrescando = false
    private var enEspera: [(Result<String, Error>) -> Void] = []

    // MARK: - Enviar

    /// Igual que URLSession.shared.dataTask, pero le pone el token a la
    /// petición y lo renueva solo si venció. No hace falta poner el header
    /// Authorization antes de llamarlo.
    func send(_ request: URLRequest, completion: @escaping Respuesta) {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            completion(nil, nil, SessionError.sinSesion)
            return
        }
        enviar(request, token: token, reintentar: true, completion: completion)
    }

    private func enviar(
        _ request: URLRequest,
        token: String,
        reintentar: Bool,
        completion: @escaping Respuesta
    ) {
        var conToken = request
        conToken.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: conToken) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode

            guard status == 401, reintentar else {
                completion(data, response, error)
                return
            }

            self.renovarToken { resultado in
                switch resultado {
                case .success(let nuevo):
                    self.enviar(request, token: nuevo, reintentar: false, completion: completion)
                case .failure(let fallo):
                    completion(nil, nil, fallo)
                }
            }
        }.resume()
    }

    // MARK: - Refresh

    private func renovarToken(completion: @escaping (Result<String, Error>) -> Void) {
        lock.lock()
        enEspera.append(completion)
        if refrescando {
            lock.unlock()
            return
        }
        refrescando = true
        lock.unlock()

        guard
            let refreshToken = UserDefaults.standard.string(forKey: "refreshToken"),
            let url = URL(string: "\(APIConfig.baseURL)/auth/refresh"),
            let body = try? JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])
        else {
            terminar(.failure(cerrarSesion(mensaje: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            if (200...299).contains(status),
               let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let nuevo = json["accessToken"] as? String {
                UserDefaults.standard.set(nuevo, forKey: "accessToken")
                self.terminar(.success(nuevo))
                return
            }

            // Sin red o el servidor falló: no cerramos la sesión, solo
            // falla esta petición. Al reintentar puede funcionar.
            if error != nil || status == 0 || status >= 500 {
                self.terminar(.failure(error ?? URLError(.cannotConnectToHost)))
                return
            }

            // 401 = refresh vencido o cuenta borrada; 403 = cuenta suspendida
            let mensaje = status == 403 ? APIClient.mensajeDelServidor(data) : nil
            self.terminar(.failure(self.cerrarSesion(mensaje: mensaje)))
        }.resume()
    }

    private func terminar(_ resultado: Result<String, Error>) {
        lock.lock()
        let esperando = enEspera
        enEspera = []
        refrescando = false
        lock.unlock()

        esperando.forEach { $0(resultado) }
    }

    /// Borra la sesión guardada y avisa para regresar al login.
    private func cerrarSesion(mensaje: String?) -> Error {
        let texto = mensaje ?? "Tu sesión terminó. Inicia sesión de nuevo."
        APIClient.borrarSesion()
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .aguasSesionTerminada,
                object: nil,
                userInfo: ["mensaje": texto]
            )
        }
        return SessionError.terminada(texto)
    }

    // MARK: - Utilidades

    static func borrarSesion() {
        ["accessToken", "refreshToken", "userName", "userEmail"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    /// Nest manda los errores como { "message": "texto" } o { "message": ["a", "b"] }
    static func mensajeDelServidor(_ data: Data?) -> String? {
        guard
            let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        if let mensaje = json["message"] as? String {
            return mensaje
        }
        if let mensajes = json["message"] as? [String] {
            return mensajes.joined(separator: "\n")
        }
        return nil
    }
}

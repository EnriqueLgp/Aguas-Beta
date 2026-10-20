//
//  SimuladorRespuestaAPI.swift
//  Aguas!BetaTests
//
//  Created by Enrique Lopez Gallo Perez on 19/10/26.
//

import Foundation

nonisolated final class SimuladorRespuestaAPI: URLProtocol, @unchecked Sendable {

    private static let estado = EstadoSimuladorAPI()

    static func configurar(
        ruta: String,
        codigoEstado: Int,
        json: String
    ) {
        estado.configurar(
            ruta: ruta,
            codigoEstado: codigoEstado,
            datos: Data(json.utf8)
        )
    }

    static var ultimaSolicitud: URLRequest? {
        estado.ultimaSolicitud
    }

    static func limpiar() {
        estado.limpiar()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        let esquema = request.url?.scheme
        return esquema == "http" || esquema == "https"
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        return request
    }

    override func startLoading() {

        guard let url = request.url,
              let respuesta = Self.estado.respuesta(para: request),
              let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: respuesta.codigoEstado,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
              ) else {

            client?.urlProtocol(
                self,
                didFailWithError: URLError(.resourceUnavailable)
            )

            return
        }

        client?.urlProtocol(
            self,
            didReceive: httpResponse,
            cacheStoragePolicy: .notAllowed
        )

        client?.urlProtocol(self, didLoad: respuesta.datos)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

nonisolated private struct RespuestaSimuladaAPI: Sendable {
    let ruta: String
    let codigoEstado: Int
    let datos: Data
}

nonisolated private final class EstadoSimuladorAPI: @unchecked Sendable {

    // Protege los datos compartidos entre la prueba y la petición.
    private let bloqueo = NSLock()
    private var respuestaActual: RespuestaSimuladaAPI?
    private var solicitudActual: URLRequest?

    var ultimaSolicitud: URLRequest? {
        bloqueo.lock()
        defer { bloqueo.unlock() }

        return solicitudActual
    }

    func configurar(
        ruta: String,
        codigoEstado: Int,
        datos: Data
    ) {
        bloqueo.lock()
        defer { bloqueo.unlock() }

        respuestaActual = RespuestaSimuladaAPI(
            ruta: ruta,
            codigoEstado: codigoEstado,
            datos: datos
        )

        solicitudActual = nil
    }

    func respuesta(para solicitud: URLRequest) -> RespuestaSimuladaAPI? {
        bloqueo.lock()
        defer { bloqueo.unlock() }

        guard let respuestaActual = respuestaActual,
              solicitud.url?.path == respuestaActual.ruta else {
            return nil
        }

        solicitudActual = solicitud
        return respuestaActual
    }

    func limpiar() {
        bloqueo.lock()
        defer { bloqueo.unlock() }

        respuestaActual = nil
        solicitudActual = nil
    }
}

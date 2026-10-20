//
//  Aguas_BetaTests.swift
//  Aguas!BetaTests
//
//  Created by Enrique Lopez Gallo Perez on 19/10/26.
//

import XCTest
import UIKit
@testable import Aguas_Beta

@MainActor
final class Aguas_BetaTests: XCTestCase {

    private let correo = "prueba@example.com"
    private let password = "Prueba1234"

    private var reporteJSON: String {
        """
        {
            "idReporte": 7,
            "descripcion": "Mensaje falso de paquetería",
            "telefonoEstafador": "5512345678",
            "enlaceSospechoso": "https://ejemplo.invalid",
            "fechaReporte": "2026-10-19T12:00:00.000Z",
            "empresaSuplantada": "DHL",
            "estado": "verificado",
            "evidenciaPrincipal": "/uploads/evidencia.jpg"
        }
        """
    }

    private func notificacionJSON(leida: Bool) -> String {
        """
        {
            "idNotificacion": 3,
            "idReporte": 7,
            "tipo": "reporte_verificado",
            "titulo": "Reporte revisado",
            "mensaje": "Tu reporte fue verificado.",
            "motivo": null,
            "fechaNotificacion": "2026-10-19T12:00:00.000Z",
            "leida": \(leida)
        }
        """
    }

    func testLoginExitoso() throws {

        let resultado = ejecutar(
            ruta: "/auth/login",
            codigoEstado: 200,
            json: """
            {
                "accessToken": "access-prueba",
                "refreshToken": "refresh-prueba",
                "nombre": "Enrique",
                "correo": "prueba@example.com",
                "rol": "usuario"
            }
            """,
            metodo: "POST",
            cuerpoEsperado: [
                "correo": correo,
                "password": password
            ]
        ) {
            AuthService.shared.login(
                correo: correo,
                password: password,
                completion: $0
            )
        }

        let respuesta = try resultado.get()

        XCTAssertEqual(respuesta.accessToken, "access-prueba")
        XCTAssertEqual(respuesta.refreshToken, "refresh-prueba")
        XCTAssertEqual(respuesta.nombre, "Enrique")
        XCTAssertEqual(respuesta.correo, correo)
        XCTAssertEqual(respuesta.rol, "usuario")
    }

    func testLoginConCredencialesIncorrectas() {

        let mensaje = "Correo o contraseña incorrectos"

        let resultado = ejecutar(
            ruta: "/auth/login",
            codigoEstado: 401,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST"
        ) {
            AuthService.shared.login(
                correo: correo,
                password: "Incorrecta123",
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testRegistroExitoso() throws {

        let resultado = ejecutar(
            ruta: "/auth/register",
            codigoEstado: 201,
            json: """
            {"idUsuario": 15, "correo": "prueba@example.com"}
            """,
            metodo: "POST",
            cuerpoEsperado: [
                "nombre": "Enrique",
                "apellido": "López",
                "correo": correo,
                "password": password
            ]
        ) {
            AuthService.shared.register(
                nombre: "Enrique",
                apellido: "López",
                correo: correo,
                password: password,
                telefono: nil,
                completion: $0
            )
        }

        let respuesta = try resultado.get()

        XCTAssertEqual(respuesta.idUsuario, 15)
        XCTAssertEqual(respuesta.correo, correo)
    }

    func testRegistroConCorreoDuplicado() {

        let mensaje = "El correo ya está registrado"

        let resultado = ejecutar(
            ruta: "/auth/register",
            codigoEstado: 409,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST"
        ) {
            AuthService.shared.register(
                nombre: "Enrique",
                apellido: "López",
                correo: correo,
                password: password,
                telefono: nil,
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testConsultaMisReportesExitosa() throws {

        let resultado = ejecutar(
            ruta: "/reportes/mios",
            codigoEstado: 200,
            json: "[\(reporteJSON)]",
            metodo: "GET",
            autenticada: true
        ) {
            ReportService.shared.fetchMyReports(completion: $0)
        }

        let reportes = try resultado.get()

        XCTAssertEqual(reportes.count, 1)
        XCTAssertEqual(reportes.first?.idReporte, 7)
        XCTAssertEqual(reportes.first?.empresaSuplantada, "DHL")
        XCTAssertEqual(reportes.first?.estado, "verificado")
    }

    func testConsultaMisReportesConError() {

        let resultado = ejecutar(
            ruta: "/reportes/mios",
            codigoEstado: 500,
            json: """
            {"message": "Error al consultar reportes"}
            """,
            metodo: "GET",
            autenticada: true
        ) {
            ReportService.shared.fetchMyReports(completion: $0)
        }

        comprobarError(
            resultado,
            esperado: ReportServiceError.serverError(500)
        )
    }

    func testConsultaReportesVerificadosExitosa() throws {

        let resultado = ejecutar(
            ruta: "/reportes",
            codigoEstado: 200,
            json: "[\(reporteJSON)]",
            metodo: "GET",
            autenticada: true
        ) {
            ReportService.shared.fetchVerifiedReports(completion: $0)
        }

        let reportes = try resultado.get()

        XCTAssertEqual(reportes.count, 1)
        XCTAssertEqual(reportes.first?.telefonoEstafador, "5512345678")
        XCTAssertEqual(reportes.first?.enlaceSospechoso, "https://ejemplo.invalid")
        XCTAssertEqual(reportes.first?.estado, "verificado")
    }

    func testConsultaReportesVerificadosConError() {

        let resultado = ejecutar(
            ruta: "/reportes",
            codigoEstado: 500,
            json: """
            {"message": "Error al consultar reportes"}
            """,
            metodo: "GET",
            autenticada: true
        ) {
            ReportService.shared.fetchVerifiedReports(completion: $0)
        }

        comprobarError(
            resultado,
            esperado: ReportServiceError.serverError(500)
        )
    }

    func testCreacionReporteExitosa() throws {

        let draft = crearBorradorConEvidencia()

        let resultado = ejecutar(
            ruta: "/reportes",
            codigoEstado: 201,
            json: """
            {"idReporte": 7}
            """,
            metodo: "POST",
            autenticada: true,
            multipart: true
        ) {
            ReportService.shared.createReport(
                draft: draft,
                completion: $0
            )
        }

        _ = try resultado.get()
    }

    func testCreacionReporteRechazada() {

        let draft = crearBorradorConEvidencia()

        let resultado = ejecutar(
            ruta: "/reportes",
            codigoEstado: 400,
            json: """
            {"message": "Datos del reporte inválidos"}
            """,
            metodo: "POST",
            autenticada: true,
            multipart: true
        ) {
            ReportService.shared.createReport(
                draft: draft,
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: ReportServiceError.serverError(400)
        )
    }

    func testConsultaEvidenciaExitosa() throws {

        let resultado = ejecutar(
            ruta: "/evidencia/reporte/7",
            codigoEstado: 200,
            json: """
            [
                {
                    "idEvidencia": 4,
                    "tipoEvidencia": "imagen",
                    "archivoUrl": "/uploads/evidencia.jpg",
                    "formato": "jpg"
                }
            ]
            """,
            metodo: "GET",
            autenticada: true
        ) {
            EvidenceService.shared.fetchEvidence(
                for: 7,
                completion: $0
            )
        }

        let evidencia = try resultado.get()

        XCTAssertEqual(evidencia.idEvidencia, 4)
        XCTAssertEqual(evidencia.archivoUrl, "/uploads/evidencia.jpg")
        XCTAssertEqual(evidencia.formato, "jpg")
    }

    func testConsultaEvidenciaDeReporteNoDisponible() {

        let resultado = ejecutar(
            ruta: "/evidencia/reporte/999",
            codigoEstado: 404,
            json: """
            {"message": "Reporte no encontrado"}
            """,
            metodo: "GET",
            autenticada: true
        ) {
            EvidenceService.shared.fetchEvidence(
                for: 999,
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: EvidenceServiceError.serverError(404)
        )
    }

    func testConsultaNotificacionesExitosa() throws {

        let resultado = ejecutar(
            ruta: "/notificaciones/mias",
            codigoEstado: 200,
            json: "[\(notificacionJSON(leida: false))]",
            metodo: "GET",
            autenticada: true
        ) {
            NotificationService.shared.getMyNotifications(completion: $0)
        }

        let notificaciones = try resultado.get()

        XCTAssertEqual(notificaciones.count, 1)
        XCTAssertEqual(notificaciones.first?.idNotificacion, 3)
        XCTAssertEqual(notificaciones.first?.idReporte, 7)
        XCTAssertEqual(notificaciones.first?.leida, false)
    }

    func testConsultaNotificacionesConError() {

        let mensaje = "No fue posible consultar las notificaciones"

        let resultado = ejecutar(
            ruta: "/notificaciones/mias",
            codigoEstado: 500,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "GET",
            autenticada: true
        ) {
            NotificationService.shared.getMyNotifications(completion: $0)
        }

        comprobarError(
            resultado,
            esperado: NotificationServiceError.serverError(mensaje)
        )
    }

    func testMarcarNotificacionComoLeidaExitoso() throws {

        let resultado = ejecutar(
            ruta: "/notificaciones/3/leer",
            codigoEstado: 200,
            json: notificacionJSON(leida: true),
            metodo: "PATCH",
            autenticada: true
        ) {
            NotificationService.shared.markAsRead(
                idNotification: 3,
                completion: $0
            )
        }

        let notificacion = try resultado.get()

        XCTAssertEqual(notificacion.idNotificacion, 3)
        XCTAssertTrue(notificacion.leida)
    }

    func testMarcarNotificacionNoDisponible() {

        let mensaje = "Notificación no encontrada"

        let resultado = ejecutar(
            ruta: "/notificaciones/999/leer",
            codigoEstado: 404,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "PATCH",
            autenticada: true
        ) {
            NotificationService.shared.markAsRead(
                idNotification: 999,
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: NotificationServiceError.serverError(mensaje)
        )
    }

    func testSolicitudRecuperacionExitosa() throws {

        let mensaje = "Si el correo corresponde a una cuenta activa, recibirás un código."

        let resultado = ejecutar(
            ruta: "/auth/forgot-password",
            codigoEstado: 200,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST",
            cuerpoEsperado: ["correo": correo]
        ) {
            PasswordService.shared.forgotPassword(
                correo: correo,
                completion: $0
            )
        }

        XCTAssertEqual(try resultado.get().message, mensaje)
    }

    func testSolicitudRecuperacionConCorreoInvalido() {

        let mensaje = "El correo no es válido"

        let resultado = ejecutar(
            ruta: "/auth/forgot-password",
            codigoEstado: 400,
            json: """
            {"message": ["\(mensaje)"]}
            """,
            metodo: "POST"
        ) {
            PasswordService.shared.forgotPassword(
                correo: "correo-invalido",
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testReenvioCodigoExitoso() throws {

        let mensaje = "Solicitud de reenvío procesada."

        let resultado = ejecutar(
            ruta: "/auth/resend-reset-code",
            codigoEstado: 200,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST",
            cuerpoEsperado: ["correo": correo]
        ) {
            PasswordService.shared.resendResetCode(
                correo: correo,
                completion: $0
            )
        }

        XCTAssertEqual(try resultado.get().message, mensaje)
    }

    func testReenvioCodigoConError() {

        let mensaje = "No fue posible procesar la solicitud"

        let resultado = ejecutar(
            ruta: "/auth/resend-reset-code",
            codigoEstado: 500,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST"
        ) {
            PasswordService.shared.resendResetCode(
                correo: correo,
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testVerificacionCodigoExitosa() throws {

        let resultado = ejecutar(
            ruta: "/auth/verify-reset-code",
            codigoEstado: 200,
            json: """
            {"resetToken": "reset-token-prueba"}
            """,
            metodo: "POST",
            cuerpoEsperado: [
                "correo": correo,
                "codigo": "123456"
            ]
        ) {
            PasswordService.shared.verifyResetCode(
                correo: correo,
                codigo: "123456",
                completion: $0
            )
        }

        XCTAssertEqual(try resultado.get().resetToken, "reset-token-prueba")
    }

    func testVerificacionCodigoIncorrecto() {

        let mensaje = "Código inválido o expirado"

        let resultado = ejecutar(
            ruta: "/auth/verify-reset-code",
            codigoEstado: 401,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST"
        ) {
            PasswordService.shared.verifyResetCode(
                correo: correo,
                codigo: "000000",
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testRestablecimientoPasswordExitoso() throws {

        let mensaje = "Contraseña actualizada correctamente"

        let resultado = ejecutar(
            ruta: "/auth/reset-password",
            codigoEstado: 200,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST",
            cuerpoEsperado: [
                "resetToken": "reset-token-prueba",
                "password": "Nueva1234"
            ]
        ) {
            PasswordService.shared.resetPassword(
                resetToken: "reset-token-prueba",
                password: "Nueva1234",
                completion: $0
            )
        }

        XCTAssertEqual(try resultado.get().message, mensaje)
    }

    func testRestablecimientoConTokenInvalido() {

        let mensaje = "Token de recuperación inválido o expirado"

        let resultado = ejecutar(
            ruta: "/auth/reset-password",
            codigoEstado: 401,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "POST"
        ) {
            PasswordService.shared.resetPassword(
                resetToken: "token-invalido",
                password: "Nueva1234",
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testCambioPasswordDesdePerfilExitoso() throws {

        let mensaje = "Contraseña actualizada correctamente"

        let resultado = ejecutar(
            ruta: "/auth/change-password",
            codigoEstado: 200,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "PATCH",
            autenticada: true,
            cuerpoEsperado: [
                "currentPassword": password,
                "newPassword": "Nueva1234"
            ]
        ) {
            PasswordService.shared.changePassword(
                currentPassword: password,
                newPassword: "Nueva1234",
                completion: $0
            )
        }

        XCTAssertEqual(try resultado.get().message, mensaje)
    }

    func testCambioPasswordConActualIncorrecta() {

        let mensaje = "La contraseña actual es incorrecta"

        let resultado = ejecutar(
            ruta: "/auth/change-password",
            codigoEstado: 400,
            json: """
            {"message": "\(mensaje)"}
            """,
            metodo: "PATCH",
            autenticada: true
        ) {
            PasswordService.shared.changePassword(
                currentPassword: "Incorrecta123",
                newPassword: "Nueva1234",
                completion: $0
            )
        }

        comprobarError(
            resultado,
            esperado: AuthServiceError.serverError(mensaje)
        )
    }

    func testDatosDelDetalleCorrectos() throws {

        let respuesta = try JSONDecoder().decode(
            ReportResponse.self,
            from: Data(reporteJSON.utf8)
        )

        let reporte = Report(response: respuesta)

        XCTAssertEqual(reporte.idReporte, 7)
        XCTAssertEqual(reporte.title, "Mensaje falso de paquetería")
        XCTAssertEqual(reporte.description, "Mensaje falso de paquetería")
        XCTAssertEqual(reporte.status, "Verificado")
        XCTAssertEqual(reporte.phone, "5512345678")
        XCTAssertEqual(reporte.company, "DHL")
        XCTAssertEqual(reporte.evidenceURL, "/uploads/evidencia.jpg")
    }

    func testDetalleConDatosOpcionalesAusentes() throws {

        let json = """
        {
            "idReporte": 8,
            "descripcion": null,
            "telefonoEstafador": null,
            "enlaceSospechoso": null,
            "fechaReporte": "fecha-invalida",
            "empresaSuplantada": "DHL",
            "estado": "pendiente",
            "evidenciaPrincipal": "/uploads/evidencia.jpg"
        }
        """

        let respuesta = try JSONDecoder().decode(
            ReportResponse.self,
            from: Data(json.utf8)
        )

        let reporte = Report(response: respuesta)

        XCTAssertEqual(reporte.title, "Reporte sin descripción")
        XCTAssertEqual(reporte.description, "")
        XCTAssertEqual(reporte.phone, "")
        XCTAssertEqual(reporte.url, "")
        XCTAssertEqual(reporte.date, "fecha-invalida")
        XCTAssertEqual(reporte.status, "Pendiente")
    }

    private func crearBorradorConEvidencia() -> ReportDraft {

        let draft = ReportDraft()

        draft.phone = "5512345678"
        draft.url = "https://ejemplo.invalid"
        draft.impersonatedCompany = "DHL"
        draft.descriptionText = "Mensaje falso de paquetería"

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 2, height: 2)
        )

        let imagen = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }

        draft.evidenceImages = [imagen]

        return draft
    }

    private func ejecutar<T: Sendable>(
        ruta: String,
        codigoEstado: Int,
        json: String,
        metodo: String,
        autenticada: Bool = false,
        multipart: Bool = false,
        cuerpoEsperado: [String: String] = [:],
        operacion: (@escaping (Result<T, Error>) -> Void) -> Void
    ) -> Result<T, Error> {

        let defaults = UserDefaults.standard
        let claves = [
            "accessToken",
            "refreshToken",
            "userName",
            "userEmail",
            "userRole"
        ]

        var sesionAnterior: [String: Any] = [:]

        for clave in claves {
            if let valor = defaults.object(forKey: clave) {
                sesionAnterior[clave] = valor
            }
        }

        // Se restaura la sesión original al terminar cada prueba.
        defer {

            URLProtocol.unregisterClass(SimuladorRespuestaAPI.self)
            SimuladorRespuestaAPI.limpiar()

            for clave in claves {
                if let valor = sesionAnterior[clave] {
                    defaults.set(valor, forKey: clave)
                } else {
                    defaults.removeObject(forKey: clave)
                }
            }
        }

        defaults.removeObject(forKey: "accessToken")
        defaults.removeObject(forKey: "refreshToken")

        if autenticada {
            defaults.set("access-prueba", forKey: "accessToken")
        }

        SimuladorRespuestaAPI.configurar(
            ruta: ruta,
            codigoEstado: codigoEstado,
            json: json
        )

        guard URLProtocol.registerClass(SimuladorRespuestaAPI.self) else {
            XCTFail("No se pudo registrar el simulador de respuestas.")
            return .failure(URLError(.unsupportedURL))
        }

        let terminada = expectation(description: ruta)
        let caja = ResultadoPruebaAPI<T>()

        operacion { resultado in
            caja.guardar(resultado)
            terminada.fulfill()
        }

        wait(for: [terminada], timeout: 5)

        guard let resultado = caja.obtener() else {
            XCTFail("La operación no entregó un resultado.")
            return .failure(URLError(.timedOut))
        }

        guard let solicitud = SimuladorRespuestaAPI.ultimaSolicitud else {
            XCTFail("El servicio no llamó a la ruta esperada: \(ruta)")
            return resultado
        }

        XCTAssertEqual(solicitud.url?.path, ruta)
        XCTAssertEqual(solicitud.httpMethod, metodo)

        if autenticada {
            XCTAssertEqual(
                solicitud.value(forHTTPHeaderField: "Authorization"),
                "Bearer access-prueba"
            )
        } else {
            XCTAssertNil(
                solicitud.value(forHTTPHeaderField: "Authorization")
            )
        }

        if !cuerpoEsperado.isEmpty {

            XCTAssertEqual(
                solicitud.value(forHTTPHeaderField: "Content-Type"),
                "application/json"
            )

            do {

                let datos = try leerCuerpo(de: solicitud)

                let objeto = try JSONSerialization.jsonObject(
                    with: datos
                )

                guard let cuerpo = objeto as? [String: Any] else {
                    XCTFail("El cuerpo no es un objeto JSON.")
                    return resultado
                }

                for (campo, valor) in cuerpoEsperado {
                    XCTAssertEqual(
                        cuerpo[campo] as? String,
                        valor,
                        "Valor incorrecto en el campo \(campo)"
                    )
                }

            } catch {
                XCTFail("No se pudo revisar el cuerpo: \(error)")
            }
        }

        if multipart {

            let contentType = solicitud.value(
                forHTTPHeaderField: "Content-Type"
            ) ?? ""

            XCTAssertTrue(
                contentType.hasPrefix("multipart/form-data; boundary=")
            )

            do {

                let datos = try leerCuerpo(de: solicitud)
                let contenido = String(decoding: datos, as: UTF8.self)

                XCTAssertTrue(contenido.contains("name=\"telefonoEstafador\""))
                XCTAssertTrue(contenido.contains("5512345678"))
                XCTAssertTrue(contenido.contains("name=\"empresaSuplantada\""))
                XCTAssertTrue(contenido.contains("DHL"))
                XCTAssertTrue(contenido.contains("name=\"descripcion\""))
                XCTAssertTrue(contenido.contains("Mensaje falso de paquetería"))
                XCTAssertTrue(contenido.contains("filename=\"evidencia.jpg\""))
                XCTAssertTrue(contenido.contains("Content-Type: image/jpeg"))

            } catch {
                XCTFail("No se pudo revisar la evidencia enviada: \(error)")
            }
        }

        return resultado
    }

    private func comprobarError<T>(
        _ resultado: Result<T, Error>,
        esperado: Error
    ) {

        switch resultado {

        case .success:
            XCTFail("Se esperaba un error, pero la operación tuvo éxito.")

        case .failure(let error):

            XCTAssertEqual(
                String(reflecting: type(of: error)),
                String(reflecting: type(of: esperado))
            )

            XCTAssertEqual(
                error.localizedDescription,
                esperado.localizedDescription
            )
        }
    }

    private func leerCuerpo(de solicitud: URLRequest) throws -> Data {

        if let datos = solicitud.httpBody {
            return datos
        }

        guard let stream = solicitud.httpBodyStream else {
            throw URLError(.cannotDecodeContentData)
        }

        stream.open()
        defer { stream.close() }

        var datos = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)

        while true {

            let cantidad = stream.read(
                &buffer,
                maxLength: buffer.count
            )

            if cantidad < 0 {
                throw stream.streamError ?? URLError(.cannotDecodeContentData)
            }

            if cantidad == 0 {
                break
            }

            datos.append(contentsOf: buffer.prefix(cantidad))
        }

        return datos
    }
}

nonisolated private final class ResultadoPruebaAPI<T: Sendable>: @unchecked Sendable {

    private let bloqueo = NSLock()
    private var resultado: Result<T, Error>?

    func guardar(_ resultado: Result<T, Error>) {
        bloqueo.lock()
        defer { bloqueo.unlock() }

        self.resultado = resultado
    }

    func obtener() -> Result<T, Error>? {
        bloqueo.lock()
        defer { bloqueo.unlock() }

        return resultado
    }
}

//
//  Report.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 03/10/26.
//

import UIKit

struct Report {

    let idReporte: Int

    let title: String
    let date: String
    let status: String

    let phone: String
    let url: String
    let company: String
    let description: String

    let evidenceImages: [UIImage]
    let evidenceFileNames: [String]
    let evidenceURL: String?

    init(response: ReportResponse) {

        let description = response.descripcion ?? ""

        idReporte = response.idReporte

        title = Report.generateTitle(
            from: description
        )

        date = Report.formatDate(
            response.fechaReporte
        )

        status = response.estado.capitalized

        phone = response.telefonoEstafador ?? ""
        url = response.enlaceSospechoso ?? ""
        company = response.empresaSuplantada
        self.description = description

        //Las evidencias se cargarán después desde el backend
        evidenceImages = []
        evidenceFileNames = []

        evidenceURL = response.evidenciaPrincipal
    }

    private static func generateTitle(
        from description: String
    ) -> String {

        let words = description.split(
            separator: " "
        )

        guard !words.isEmpty else {
            return "Reporte sin descripción"
        }

        let titleWords = words.prefix(7)

        var title = titleWords.joined(
            separator: " "
        )

        if words.count > 7 {
            title += "..."
        }

        return title
    }

    private static func formatDate(
        _ dateString: String
    ) -> String {

        let isoFormatter = ISO8601DateFormatter()

        // El backend puede enviar la fecha con milisegundos
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        var date = isoFormatter.date(
            from: dateString
        )

        //también acepta fechas ISO 8601 sin milisegundos
        if date == nil {

            isoFormatter.formatOptions = [
                .withInternetDateTime
            ]

            date = isoFormatter.date(
                from: dateString
            )
        }

        guard let date else {
            return dateString
        }

        let displayFormatter = DateFormatter()

        displayFormatter.locale =
            Locale(identifier: "es_MX")

        displayFormatter.dateFormat =
            "dd MMM yyyy"

        return displayFormatter.string(
            from: date
        )
    }
}

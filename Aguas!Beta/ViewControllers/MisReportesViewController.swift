//
//  MisReportesViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 03/10/26.
//
// Controlador encargado de mostrar los reportes creados
//por el usuario que tiene una sesión activa

import UIKit

class MisReportesViewController: UIViewController,
                                 UITableViewDataSource,
                                 UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    // Almacena los reportes obtenidos desde el backend correspondientes al usuario autenticado
    private var reports: [Report] = []

    // Guarda temporalmente el reporte seleccionado para enviarlo a la pantalla de detalle
    private var selectedReport: Report?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Se asigna este controlador como fuente de datos y delegado de la tabla
        tableView.dataSource = self
        tableView.delegate = self

        // Mantiene una altura uniforme para las celdas
        tableView.rowHeight = 72

        // Solicita al backend los reportes del usuario
        loadReports()
    }

    // Obtiene los reportes del usuario mediante ReportService
    // El servicio utiliza el access token guardado durante el inicio de sesión para identificar al usuario
    private func loadReports() {

        ReportService.shared.fetchMyReports { result in

            // Los cambios sobre elementos de interfaz deben realizarse en el hilo principal
            DispatchQueue.main.async {

                switch result {

                case .success(let responses):

                    // Convierte las respuestas de la API al modelo utilizado por la interfaz de la aplicación
                    self.reports = responses.map {
                        Report(response: $0)
                    }

                    // Actualiza la tabla con los datos obtenidos
                    self.tableView.reloadData()

                case .failure(let error):

                    // Si la consulta falla, se informa al usuario sin cerrar la pantalla
                    self.showAlert(
                        title: "No se pudieron cargar los reportes",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    // Indica a la tabla cuántos reportes debe mostrar
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        return reports.count
    }

    // Configura el contenido visual de cada celda utilizando la información del reporte correspondiente
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReportCell",
            for: indexPath
        )

        let report = reports[indexPath.row]

        // Muestra el título generado a partir de la descripción
        cell.textLabel?.text = report.title

        // Muestra la fecha y el estado actual del reporte
        cell.detailTextLabel?.text =
            "\(report.date) • \(report.status)"

        // Indica visualmente que la celda puede abrir una pantalla con más información
        cell.accessoryType = .disclosureIndicator

        return cell
    }


    // Detecta qué reporte seleccionó el usuario
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        selectedReport = reports[indexPath.row]

        // Retira visualmente la selección después del toque
        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        // Navega hacia la pantalla de detalle
        performSegue(
            withIdentifier: "goToReportDetail",
            sender: self
        )
    }


    // Envía el reporte seleccionado a la pantalla de detalle antes de realizar la transición
    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {

        guard segue.identifier == "goToReportDetail",
              let destination =
                segue.destination as? DetalleReporteViewController,
              let selectedReport = selectedReport else {
            return
        }

        destination.report = selectedReport

        // Permite que la pantalla de detalle muestre también el estado del reporte
        destination.source = .myReports
    }

    // Presenta mensajes de error de forma uniforme dentro de esta pantalla
    private func showAlert(
        title: String,
        message: String
    ) {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Aceptar",
                style: .default
            )
        )

        present(
            alert,
            animated: true
        )
    }
}

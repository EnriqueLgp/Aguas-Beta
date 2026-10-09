//
//  BuscarReportesViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 04/10/26.
//
// Controlador encargado de consultar los reportes verificados
//disponibles en el backend y permitir su búsqueda.

import UIKit

class BuscarReportesViewController: UIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate,
                                    UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    //Contiene todos los reportes verificados obtenidos desde el backend
    private var reports: [Report] = []

    // Contiene únicamente los reportes que coinciden con el texto ingresado en la barra de búsqueda
    private var filteredReports: [Report] = []

    // Guarda el reporte seleccionado para enviarlo posteriormente a la pantalla de detalle
    private var selectedReport: Report?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configura los delegados necesarios para la tabla y la barra de búsqueda
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.rowHeight = 72
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadReports()
    }

    // Obtiene desde la API los reportes cuyo estado ha sido marcado como verificado
    private func loadReports() {

        ReportService.shared.fetchVerifiedReports { result in

            DispatchQueue.main.async {

                switch result {

                case .success(let responses):

                    // Convierte cada respuesta del backend al modelo utilizado por la interfaz
                    self.reports = responses.map {
                        Report(response: $0)
                    }

                    // Actualiza la lista mostrada con los reportes obtenidos del backend
                    self.filteredReports = self.reports

                    self.tableView.reloadData()

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudieron cargar los reportes",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }


    // Cierra el flujo modal utilizado para la pantalla de búsqueda de reportes
    @IBAction func closeTapped(_ sender: UIBarButtonItem) {

        dismiss(
            animated: true
        )
    }


    // Indica cuántos resultados debe mostrar la tabla
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        return filteredReports.count
    }

    // Configura cada celda utilizando los datos del reporte correspondiente
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SearchReportCell",
            for: indexPath
        )

        let report = filteredReports[indexPath.row]

        // La primera línea muestra el título generado a partir de la descripción del reporte
        cell.textLabel?.text = report.title

        // La segunda línea muestra el enlace sospechoso
        // Si el reporte no contiene enlace, se muestra un texto alternativo para evitar una celda vacía
        cell.detailTextLabel?.text =
            report.url.isEmpty
            ? "Sin enlace registrado"
            : report.url

        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // Filtra los reportes conforme el usuario escribe dentro de la barra de búsqueda
    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {

        let text = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Si no existe texto de búsqueda, se vuelven a mostrar todos los reportes
        if text.isEmpty {

            filteredReports = reports

        } else {

            // Permite buscar utilizando tanto el título generado como el enlace sospechoso del reporte
            filteredReports = reports.filter { report in

                report.title.localizedCaseInsensitiveContains(text) ||
                report.url.localizedCaseInsensitiveContains(text)
            }
        }

        // Actualiza inmediatamente los resultados mostrados
        tableView.reloadData()
    }


    // Guarda el reporte seleccionado y abre su pantalla de detalle
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        selectedReport = filteredReports[indexPath.row]

        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        performSegue(
            withIdentifier: "goToSearchReportDetail",
            sender: self
        )
    }


    // Envía el reporte seleccionado a la pantalla de detalle
    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {

        guard segue.identifier == "goToSearchReportDetail",
              let destination =
                segue.destination as? DetalleReporteViewController,
              let selectedReport = selectedReport else {
            return
        }

        destination.report = selectedReport

        // Los resultados de búsqueda ya fueron verificados,
        //por lo que la pantalla de detalle no muestra el estado del reporte
        destination.source = .search
    }

    // Presenta un mensaje cuando ocurre un problema al consultar información del backend
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

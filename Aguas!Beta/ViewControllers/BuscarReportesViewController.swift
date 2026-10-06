//
//  BuscarReportesViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 04/10/26.
//

import UIKit

class BuscarReportesViewController: UIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate,
                                    UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private let reports: [Report] = [
        Report(
            title: "Me llegó un mensaje diciendo que...",
            date: "03 oct 2026",
            status: "Verificado",
            phone: "55 1234 5678",
            url: "https://paqueteria-falsa.com",
            company: "DHL",
            description: "Me llegó un mensaje diciendo que mi paquete estaba retenido y que tenía que pagar para liberarlo.",
            evidenceImages: [
                UIImage(named: "LogoAguas")!
            ],
            evidenceFileNames: ["captura_mensaje.pdf"]
        ),
        Report(
            title: "Una página se hizo pasar por...",
            date: "01 oct 2026",
            status: "Verificado",
            phone: "55 9876 5432",
            url: "https://banco-seguro-falso.com",
            company: "BBVA",
            description: "Una página se hizo pasar por el banco y pedía ingresar datos de acceso para evitar un supuesto bloqueo.",
            evidenceImages: [],
            evidenceFileNames: []
        ),
        Report(
            title: "Me ofrecieron un premio falso...",
            date: "28 sep 2026",
            status: "Verificado",
            phone: "",
            url: "https://premio-falso.com",
            company: "Amazon",
            description: "Me ofrecieron un premio falso y me pidieron ingresar datos personales para reclamarlo.",
            evidenceImages: [],
            evidenceFileNames: ["evidencia.txt"]
        )
    ]

    private var filteredReports: [Report] = []
    private var selectedReport: Report?

    override func viewDidLoad() {
        super.viewDidLoad()

        filteredReports = reports

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.rowHeight = 72
    }

    @IBAction func closeTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        return filteredReports.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SearchReportCell",
            for: indexPath
        )

        let report = filteredReports[indexPath.row]

        cell.textLabel?.text = report.title
        cell.detailTextLabel?.text = report.url

        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {

        let text = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if text.isEmpty {

            filteredReports = reports

        } else {

            filteredReports = reports.filter { report in

                report.title.localizedCaseInsensitiveContains(text) ||
                report.url.localizedCaseInsensitiveContains(text)
            }
        }

        tableView.reloadData()
    }

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
        destination.source = .search
    }
}

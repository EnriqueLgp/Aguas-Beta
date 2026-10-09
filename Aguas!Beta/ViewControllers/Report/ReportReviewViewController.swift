//
//  ReportReviewViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 20/09/26.
//

import UIKit

class ReportReviewViewController: UIViewController {

    var reportDraft: ReportDraft!

    @IBOutlet weak var contactCardView: UIView!
    @IBOutlet weak var phoneValueLabel: UILabel!
    @IBOutlet weak var urlValueLabel: UILabel!
    @IBOutlet weak var companyValueLabel: UILabel!

    @IBOutlet weak var descriptionCardView: UIView!
    @IBOutlet weak var descriptionValueLabel: UILabel!
    @IBOutlet weak var evidenceCountLabel: UILabel!

    @IBAction func editContactTapped(_ sender: UIButton) {

        guard let viewControllers = navigationController?.viewControllers else {
            return
        }

        for viewController in viewControllers {

            if let step1ViewController = viewController as? ReportStep1ViewController {

                navigationController?.popToViewController(
                    step1ViewController,
                    animated: true
                )

                return
            }
        }
    }

    @IBAction func editDescriptionTapped(_ sender: UIButton) {

        guard let viewControllers = navigationController?.viewControllers else {
            return
        }

        for viewController in viewControllers {

            if let step2ViewController = viewController as? ReportStep2ViewController {

                navigationController?.popToViewController(
                    step2ViewController,
                    animated: true
                )

                return
            }
        }
    }

    @IBAction func sendReportTapped(_ sender: UIButton) {

        //evita que el usuario envíe el mismo reporte varias veces mientras la petición está en proceso
        sender.isEnabled = false

        ReportService.shared.createReport(
            draft: reportDraft
        ) { result in

            DispatchQueue.main.async {

                switch result {

                case .success:

                    // La pantalla de confirmación solo se muestra si el backend aceptó correctamente el reporte
                    self.performSegue(
                        withIdentifier: "goToReportSent",
                        sender: self
                    )

                case .failure(let error):

                    sender.isEnabled = true

                    let alert = UIAlertController(
                        title: "No se pudo enviar el reporte",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )

                    alert.addAction(
                        UIAlertAction(
                            title: "Aceptar",
                            style: .default
                        )
                    )

                    self.present(
                        alert,
                        animated: true
                    )
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contactCardView.layer.cornerRadius = 12
        contactCardView.clipsToBounds = true

        descriptionCardView.layer.cornerRadius = 12
        descriptionCardView.clipsToBounds = true

        phoneValueLabel.text = reportDraft.phone.isEmpty
            ? "No proporcionado"
            : reportDraft.phone

        urlValueLabel.text = reportDraft.url.isEmpty
            ? "No proporcionado"
            : reportDraft.url

        companyValueLabel.text = reportDraft.impersonatedCompany.isEmpty
            ? "No especificado"
            : reportDraft.impersonatedCompany

        descriptionValueLabel.text = reportDraft.descriptionText

        let evidenceCount =
            reportDraft.evidenceImages.count +
            reportDraft.evidenceFileURLs.count

        evidenceCountLabel.text = evidenceCount == 1
            ? "1 evidencia seleccionada"
            : "Sin evidencia adjunta"
    }
}

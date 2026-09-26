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
        performSegue(
              withIdentifier: "goToReportSent",
              sender: self
          )
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Redondea las esquinas de las tarjetas.
        contactCardView.layer.cornerRadius = 12
        contactCardView.clipsToBounds = true

        descriptionCardView.layer.cornerRadius = 12
        descriptionCardView.clipsToBounds = true

        // Muestra los datos capturados en Step 1.
        phoneValueLabel.text = reportDraft.phone.isEmpty
            ? "No proporcionado"
            : reportDraft.phone

        urlValueLabel.text = reportDraft.url.isEmpty
            ? "No proporcionado"
            : reportDraft.url

        companyValueLabel.text = reportDraft.impersonatedCompany.isEmpty
            ? "No especificado"
            : reportDraft.impersonatedCompany

        // Muestra la descripción capturada en Step 2.
        descriptionValueLabel.text = reportDraft.descriptionText

        // Muestra cuántas evidencias fueron seleccionadas.
        let evidenceCount =
            reportDraft.evidenceImages.count +
            reportDraft.evidenceFileURLs.count

        if evidenceCount == 0 {

            evidenceCountLabel.text = "Sin evidencia adjunta"

        } else if evidenceCount == 1 {

            evidenceCountLabel.text = "1 elemento seleccionado"

        } else {

            evidenceCountLabel.text = "\(evidenceCount) elementos seleccionados"
        }
    }
}

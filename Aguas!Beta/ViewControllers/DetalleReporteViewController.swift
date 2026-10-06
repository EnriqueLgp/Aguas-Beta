//
//  DetalleReporteViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 03/10/26.
//

import UIKit

enum ReportDetailSource {
    case myReports
    case search
}

class DetalleReporteViewController: UIViewController {

    var report: Report?
    var source: ReportDetailSource = .myReports

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!

    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var imagesStack: UIStackView!
    @IBOutlet weak var filesStack: UIStackView!
    @IBOutlet weak var evidenceCountLabel: UILabel!

    @IBOutlet weak var fraudsterCardView: UIView!
    @IBOutlet weak var descriptionCardView: UIView!
    @IBOutlet weak var evidenceCardView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCards()
        configureReport()
        configureEvidence()
    }

    private func configureCards() {

        let cards = [
            fraudsterCardView,
            descriptionCardView,
            evidenceCardView
        ]

        for card in cards {
            card?.backgroundColor = .secondarySystemBackground
            card?.layer.cornerRadius = 12
        }
    }

    private func configureReport() {

        guard let report = report else {
            return
        }

        titleLabel.text = report.title
        dateLabel.text = report.date

        statusLabel.text = "Estado: \(report.status)"

        // Solo mostramos el estado cuando viene de "Mis reportes".
        statusLabel.isHidden = source == .search

        if report.phone.isEmpty {
            phoneLabel.text = "Número: No proporcionado"
        } else {
            phoneLabel.text = "Número: \(report.phone)"
        }

        if report.url.isEmpty {
            urlLabel.text = "Enlace: No proporcionado"
        } else {
            urlLabel.text = "Enlace: \(report.url)"
        }

        if report.company.isEmpty {
            companyLabel.text = "Empresa: No especificada"
        } else {
            companyLabel.text = "Empresa: \(report.company)"
        }

        descriptionLabel.text = report.description
    }

    private func configureEvidence() {

        guard let report = report else {
            return
        }

        imagesStack.arrangedSubviews.forEach {
            imagesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        filesStack.arrangedSubviews.forEach {
            filesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, image) in report.evidenceImages.enumerated() {

            let imageView = UIImageView(image: image)

            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8

            imageView.isUserInteractionEnabled = true
            imageView.tag = index

            let tapGesture = UITapGestureRecognizer(
                target: self,
                action: #selector(imageTapped(_:))
            )

            imageView.addGestureRecognizer(tapGesture)

            imagesStack.addArrangedSubview(imageView)
        }

        for fileName in report.evidenceFileNames {

            let label = UILabel()

            label.text = "📄 \(fileName)"
            label.font = .systemFont(ofSize: 15)
            label.numberOfLines = 0

            filesStack.addArrangedSubview(label)
        }

        let totalEvidence =
            report.evidenceImages.count +
            report.evidenceFileNames.count

        if totalEvidence == 0 {

            evidenceCountLabel.text = "Sin evidencia adjunta"

            imagesStack.isHidden = true
            filesStack.isHidden = true

        } else {

            imagesStack.isHidden =
                report.evidenceImages.isEmpty

            filesStack.isHidden =
                report.evidenceFileNames.isEmpty

            if totalEvidence == 1 {
                evidenceCountLabel.text =
                    "1 elemento adjunto"
            } else {
                evidenceCountLabel.text =
                    "\(totalEvidence) elementos adjuntos"
            }
        }
    }

    @objc private func imageTapped(
        _ gesture: UITapGestureRecognizer
    ) {

        guard let imageView =
                gesture.view as? UIImageView,
              let report = report else {
            return
        }

        let index = imageView.tag

        guard index < report.evidenceImages.count else {
            return
        }

        let previewViewController =
            ImagePreviewViewController()

        previewViewController.image =
            report.evidenceImages[index]

        navigationController?.pushViewController(
            previewViewController,
            animated: true
        )
    }
}

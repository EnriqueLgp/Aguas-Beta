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

    private var loadedEvidenceImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCards()
        configureReport()
        loadEvidence()
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
        statusLabel.isHidden = source == .search

        phoneLabel.text = report.phone.isEmpty
            ? "Número: No proporcionado"
            : "Número: \(report.phone)"

        urlLabel.text = report.url.isEmpty
            ? "Enlace: No proporcionado"
            : "Enlace: \(report.url)"

        companyLabel.text = report.company.isEmpty
            ? "Empresa: No especificada"
            : "Empresa: \(report.company)"

        descriptionLabel.text = report.description
    }

    private func loadEvidence() {

        guard let report = report else {
            return
        }

        clearEvidenceViews()

        evidenceCountLabel.text = "Cargando evidencia..."
        imagesStack.isHidden = true
        filesStack.isHidden = true

        EvidenceService.shared.fetchEvidence(
            for: report.idReporte
        ) { result in

            DispatchQueue.main.async {

                switch result {

                case .success(let evidence):
                    self.configureEvidence(
                        evidence
                    )

                case .failure:
                    self.evidenceCountLabel.text =
                        "No se pudo cargar la evidencia"
                }
            }
        }
    }

    private func configureEvidence(
        _ evidence: EvidenceResponse
    ) {

        clearEvidenceViews()

        let format = evidence.formato.lowercased()
        let fileExtension = URL(
            fileURLWithPath: evidence.archivoUrl
        ).pathExtension.lowercased()

        let imageFormats = [
            "jpg",
            "jpeg",
            "png",
            "heic",
            "webp",
            "image/jpeg",
            "image/png",
            "image/heic",
            "image/webp"
        ]

        let isImage =
            imageFormats.contains(format) ||
            imageFormats.contains(fileExtension)

        if isImage {

            loadEvidenceImage(
                from: evidence.archivoUrl
            )

        } else {

            let fileName = URL(
                fileURLWithPath: evidence.archivoUrl
            ).lastPathComponent

            let label = UILabel()

            label.text = "📄 \(fileName)"
            label.font = .systemFont(ofSize: 15)
            label.numberOfLines = 0

            filesStack.addArrangedSubview(label)

            filesStack.isHidden = false
            imagesStack.isHidden = true

            evidenceCountLabel.text =
                "1 evidencia adjunta"
        }
    }

    private func loadEvidenceImage(
        from archivoURL: String
    ) {

        guard let url = evidenceURL(
            from: archivoURL
        ) else {

            evidenceCountLabel.text =
                "No se pudo cargar la evidencia"

            return
        }

        URLSession.shared.dataTask(
            with: url
        ) { data, _, error in

            guard error == nil,
                  let data = data,
                  let image = UIImage(data: data) else {

                DispatchQueue.main.async {
                    self.evidenceCountLabel.text =
                        "No se pudo cargar la evidencia"
                }

                return
            }

            DispatchQueue.main.async {

                self.loadedEvidenceImage = image

                let imageView = UIImageView(
                    image: image
                )

                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8

                imageView.heightAnchor.constraint(
                    equalToConstant: 180
                ).isActive = true

                imageView.isUserInteractionEnabled = true

                let tapGesture = UITapGestureRecognizer(
                    target: self,
                    action: #selector(self.imageTapped)
                )

                imageView.addGestureRecognizer(
                    tapGesture
                )

                self.imagesStack.addArrangedSubview(
                    imageView
                )

                self.imagesStack.isHidden = false
                self.filesStack.isHidden = true

                self.evidenceCountLabel.text =
                    "1 evidencia adjunta"
            }

        }.resume()
    }

    // archivoUrl puede venir como URL completa o como una ruta relativa del servidor,
    //por ejemplo /uploads/archivo.jpg.
    private func evidenceURL(
        from archivoURL: String
    ) -> URL? {

        if let url = URL(string: archivoURL),
           url.scheme != nil {

            return url
        }

        let separator =
            archivoURL.hasPrefix("/") ? "" : "/"

        return URL(
            string:
                "\(APIConfig.baseURL)\(separator)\(archivoURL)"
        )
    }

    private func clearEvidenceViews() {

        imagesStack.arrangedSubviews.forEach {
            imagesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        filesStack.arrangedSubviews.forEach {
            filesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    @objc private func imageTapped() {

        guard let image = loadedEvidenceImage else {
            return
        }

        let previewViewController =
            ImagePreviewViewController()

        previewViewController.image = image

        navigationController?.pushViewController(
            previewViewController,
            animated: true
        )
    }
}

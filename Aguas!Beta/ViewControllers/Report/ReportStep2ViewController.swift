//
//  ReportStep2ViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 20/09/26.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers

class ReportStep2ViewController: UIViewController,
                                 UITextViewDelegate,
                                 PHPickerViewControllerDelegate,
                                 UIDocumentPickerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var attachEvidenceButton: UIButton!

    private let descriptionPlaceholder = "Escribe lo que ocurrió"

    var reportDraft: ReportDraft!

    // El backend permite una sola evidencia por reporte
    private var selectedEvidenceImages: [UIImage] = []
    private var selectedEvidenceFileURLs: [URL] = []

    private var hasEvidence: Bool {
        !selectedEvidenceImages.isEmpty ||
        !selectedEvidenceFileURLs.isEmpty
    }

    @IBAction func attachEvidenceTapped(_ sender: UIButton) {

        let actionSheet = UIAlertController(
            title: hasEvidence ? "Cambiar evidencia" : "Adjuntar evidencia",
            message: "Selecciona el tipo de evidencia que quieres adjuntar.",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Elegir foto",
                style: .default,
                handler: { [weak self] _ in
                    self?.openPhotoPicker()
                }
            )
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Elegir archivo",
                style: .default,
                handler: { [weak self] _ in
                    self?.openDocumentPicker()
                }
            )
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Cancelar",
                style: .cancel
            )
        )

        present(actionSheet, animated: true)
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {

        let description = descriptionTextView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if description.isEmpty ||
            description == descriptionPlaceholder {

            let alert = UIAlertController(
                title: "Falta información",
                message: "Describe brevemente lo que ocurrió para continuar.",
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "Aceptar",
                    style: .default
                )
            )

            present(alert, animated: true)

            return
        }

        // El backend requiere que cada reporte tenga una evidencia
        guard hasEvidence else {

            let alert = UIAlertController(
                title: "Falta evidencia",
                message: "Adjunta una foto o archivo como evidencia para continuar.",
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "Aceptar",
                    style: .default
                )
            )

            present(alert, animated: true)

            return
        }

        reportDraft.descriptionText = description
        reportDraft.evidenceImages = selectedEvidenceImages
        reportDraft.evidenceFileURLs = selectedEvidenceFileURLs

        performSegue(
            withIdentifier: "goToReportReview",
            sender: self
        )
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {

        if segue.identifier == "goToReportReview",
           let destination =
            segue.destination as? ReportReviewViewController {

            destination.reportDraft = reportDraft
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionTextView.delegate = self
        descriptionTextView.backgroundColor = .secondarySystemBackground
        descriptionTextView.layer.cornerRadius = 10
        descriptionTextView.clipsToBounds = true

        descriptionTextView.textContainerInset = UIEdgeInsets(
            top: 12,
            left: 10,
            bottom: 12,
            right: 10
        )

        // Recupera la información si el usuario vuelve desde Review
        selectedEvidenceImages = Array(
            reportDraft.evidenceImages.prefix(1)
        )

        selectedEvidenceFileURLs = Array(
            reportDraft.evidenceFileURLs.prefix(1)
        )

        // Evita conservar simultáneamente una imagen y un archivo
        if !selectedEvidenceImages.isEmpty {
            selectedEvidenceFileURLs.removeAll()
        }

        if reportDraft.descriptionText.isEmpty {

            descriptionTextView.text = descriptionPlaceholder
            descriptionTextView.textColor = .placeholderText

        } else {

            descriptionTextView.text = reportDraft.descriptionText
            descriptionTextView.textColor = .label
        }

        updateEvidenceButton()

        scrollView.keyboardDismissMode = .interactive

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func openPhotoPicker() {

        var configuration = PHPickerConfiguration()

        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(
            configuration: configuration
        )

        picker.delegate = self

        present(picker, animated: true)
    }

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {

        picker.dismiss(animated: true)

        guard let result = results.first else {
            return
        }

        let itemProvider = result.itemProvider

        guard itemProvider.canLoadObject(
            ofClass: UIImage.self
        ) else {
            return
        }

        itemProvider.loadObject(
            ofClass: UIImage.self
        ) { [weak self] object, error in

            guard let self = self,
                  let image = object as? UIImage,
                  error == nil else {
                return
            }

            DispatchQueue.main.async {

                // Una nueva selección reemplaza cualquier evidencia anterior
                self.selectedEvidenceImages = [image]
                self.selectedEvidenceFileURLs.removeAll()

                self.updateEvidenceButton()
            }
        }
    }

    private func openDocumentPicker() {

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .pdf,
                .text,
                .image,
                .data
            ],
            asCopy: true
        )

        picker.delegate = self
        picker.allowsMultipleSelection = false

        present(picker, animated: true)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {

        guard let selectedURL = urls.first else {
            return
        }

        // Una nueva selección reemplaza cualquier evidencia anterior
        selectedEvidenceFileURLs = [selectedURL]
        selectedEvidenceImages.removeAll()

        updateEvidenceButton()
    }

    private func updateEvidenceButton() {

        if hasEvidence {

            attachEvidenceButton.setTitle(
                "1 evidencia seleccionada",
                for: .normal
            )

            attachEvidenceButton.setImage(
                UIImage(systemName: "checkmark.circle.fill"),
                for: .normal
            )

        } else {

            attachEvidenceButton.setTitle(
                "Adjunta una foto o archivo",
                for: .normal
            )

            attachEvidenceButton.setImage(
                UIImage(systemName: "paperclip"),
                for: .normal
            )
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {

        if textView.text == descriptionPlaceholder {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {

        let text = textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            textView.text = descriptionPlaceholder
            textView.textColor = .placeholderText
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification: Notification) {

        guard let keyboardFrame = notification.userInfo?[
            UIResponder.keyboardFrameEndUserInfoKey
        ] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(
            keyboardFrame,
            from: nil
        )

        let keyboardOverlap = max(
            0,
            view.bounds.maxY - keyboardFrameInView.minY
        )

        scrollView.contentInset.bottom = keyboardOverlap
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardOverlap
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

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
    private let maximumEvidenceCount = 5

    var reportDraft: ReportDraft!

    // Fotos seleccionadas.
    private var selectedEvidenceImages: [UIImage] = []

    // Archivos seleccionados.
    private var selectedEvidenceFileURLs: [URL] = []

    private var totalEvidenceCount: Int {
        selectedEvidenceImages.count + selectedEvidenceFileURLs.count
    }

    @IBAction func attachEvidenceTapped(_ sender: UIButton) {

        if totalEvidenceCount >= maximumEvidenceCount {
            showEvidenceLimitAlert()
            return
        }

        let actionSheet = UIAlertController(
            title: "Adjuntar evidencia",
            message: "Selecciona el tipo de evidencia que quieres adjuntar.",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Elegir fotos",
                style: .default,
                handler: { [weak self] _ in
                    self?.openPhotoPicker()
                }
            )
        )

        actionSheet.addAction(
            UIAlertAction(
                title: "Elegir archivos",
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

        // Guarda los datos de Step 2 en el borrador.
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
           let destination = segue.destination as? ReportReviewViewController {

            destination.reportDraft = reportDraft
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configura el Text View.
        descriptionTextView.delegate = self
        descriptionTextView.backgroundColor = .secondarySystemBackground
        descriptionTextView.layer.cornerRadius = 10
        descriptionTextView.clipsToBounds = true

        // Espacio interno del Text View.
        descriptionTextView.textContainerInset = UIEdgeInsets(
            top: 12,
            left: 10,
            bottom: 12,
            right: 10
        )

        // Carga los datos ya guardados en el borrador.
        selectedEvidenceImages = reportDraft.evidenceImages
        selectedEvidenceFileURLs = reportDraft.evidenceFileURLs

        if reportDraft.descriptionText.isEmpty {

            descriptionTextView.text = descriptionPlaceholder
            descriptionTextView.textColor = .placeholderText

        } else {

            descriptionTextView.text = reportDraft.descriptionText
            descriptionTextView.textColor = .label
        }

        // Actualiza el botón según las evidencias ya guardadas.
        updateEvidenceButton()

        // Permite ocultar el teclado arrastrando.
        scrollView.keyboardDismissMode = .interactive

        // Oculta el teclado al tocar fuera.
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Detecta cuando aparece el teclado.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        // Detecta cuando desaparece el teclado.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Photo Picker

    private func openPhotoPicker() {

        let remainingSlots = maximumEvidenceCount - totalEvidenceCount

        guard remainingSlots > 0 else {
            showEvidenceLimitAlert()
            return
        }

        var configuration = PHPickerConfiguration()

        configuration.filter = .images
        configuration.selectionLimit = remainingSlots

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

        guard !results.isEmpty else {
            return
        }

        for result in results {

            let itemProvider = result.itemProvider

            guard itemProvider.canLoadObject(
                ofClass: UIImage.self
            ) else {
                continue
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

                    guard self.totalEvidenceCount < self.maximumEvidenceCount else {
                        return
                    }

                    self.selectedEvidenceImages.append(image)

                    self.updateEvidenceButton()
                }
            }
        }
    }

    // MARK: - Document Picker

    private func openDocumentPicker() {

        let remainingSlots = maximumEvidenceCount - totalEvidenceCount

        guard remainingSlots > 0 else {
            showEvidenceLimitAlert()
            return
        }

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
        picker.allowsMultipleSelection = true

        present(picker, animated: true)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {

        let remainingSlots = maximumEvidenceCount - totalEvidenceCount

        guard remainingSlots > 0 else {
            showEvidenceLimitAlert()
            return
        }

        let filesToAdd = Array(
            urls.prefix(remainingSlots)
        )

        selectedEvidenceFileURLs.append(
            contentsOf: filesToAdd
        )

        updateEvidenceButton()

        if urls.count > remainingSlots {

            let alert = UIAlertController(
                title: "Límite de evidencias",
                message: "Solo se agregaron los archivos disponibles hasta completar un máximo de 5 evidencias.",
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "Aceptar",
                    style: .default
                )
            )

            present(alert, animated: true)
        }
    }

    // MARK: - Evidence UI

    private func updateEvidenceButton() {

        let count = totalEvidenceCount

        if count == 0 {

            attachEvidenceButton.setTitle(
                "Adjunta fotos o archivos",
                for: .normal
            )

            attachEvidenceButton.setImage(
                UIImage(systemName: "paperclip"),
                for: .normal
            )

        } else if count == 1 {

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
                "\(count) evidencias seleccionadas",
                for: .normal
            )

            attachEvidenceButton.setImage(
                UIImage(systemName: "checkmark.circle.fill"),
                for: .normal
            )
        }
    }

    private func showEvidenceLimitAlert() {

        let alert = UIAlertController(
            title: "Límite alcanzado",
            message: "Puedes adjuntar un máximo de 5 evidencias.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Aceptar",
                style: .default
            )
        )

        present(alert, animated: true)
    }

    // MARK: - UITextViewDelegate

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

    // MARK: - Keyboard

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

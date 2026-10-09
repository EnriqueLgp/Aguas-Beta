//
//  ReportStep1ViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 20/09/26.
//

import UIKit

class ReportStep1ViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var companyTextField: UITextField!

    private var reportDraft = ReportDraft()

    @IBAction func closeReportFlow(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func continueButtonTapped(_ sender: Any) {

        let phone = phoneTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let url = urlTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if phone.isEmpty && url.isEmpty {

            let alert = UIAlertController(
                title: "Falta información",
                message: "Ingresa un número telefónico o un enlace para continuar.",
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

        // Guarda los datos de Step 1 en el borrador
        reportDraft.phone = phone
        reportDraft.url = url
        reportDraft.impersonatedCompany = companyTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        performSegue(
            withIdentifier: "goToReportStep2",
            sender: self
        )
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {

        if segue.identifier == "goToReportStep2",
           let destination = segue.destination as? ReportStep2ViewController {

            destination.reportDraft = reportDraft
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Carga los datos que ya estaban guardados en el borrador
        phoneTextField.text = reportDraft.phone
        urlTextField.text = reportDraft.url
        companyTextField.text = reportDraft.impersonatedCompany

        // Permite ocultar el teclado arrastrando el Scroll View
        scrollView.keyboardDismissMode = .interactive

        //Oculta el teclado al tocar fuera de los TextFields
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Detecta cuando aparece el teclado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        // Detecta cuando desaparece el teclado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
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

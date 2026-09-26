//
//  RegisterViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 16/09/26.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Oculta el teclado mientras arrastras el Scroll View.
        scrollView.keyboardDismissMode = .interactive

        // Oculta el teclado al tocar fuera de los TextFields.
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

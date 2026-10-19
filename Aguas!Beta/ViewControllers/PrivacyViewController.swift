//
//  PrivacyViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 18/10/26.
//

import UIKit

class PrivacyViewController: UIViewController {


    @IBOutlet weak var privacyTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        privacyTextView.text = PrivacyContent.text
        privacyTextView.isEditable = false
        privacyTextView.isSelectable = true
        privacyTextView.isScrollEnabled = true
        privacyTextView.font = UIFont.systemFont(ofSize: 14)
        privacyTextView.textColor = .label
        privacyTextView.backgroundColor = .secondarySystemBackground
        privacyTextView.layer.cornerRadius = 8
        privacyTextView.layer.borderWidth = 1
        privacyTextView.layer.borderColor = UIColor.separator.cgColor
        privacyTextView.textContainerInset = UIEdgeInsets(
            top: 12,
            left: 12,
            bottom: 12,
            right: 12
        )
    }

    @IBAction func closeButtonTapped(_ sender: UIButton) {

        if let navigationController = navigationController,
           navigationController.viewControllers.first !== self {

            navigationController.popViewController(
                animated: true
            )

        } else {

            dismiss(animated: true)
        }
    }

}

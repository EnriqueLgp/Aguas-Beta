//
//  ReportSentViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 20/09/26.
//

import UIKit

class ReportSentViewController: UIViewController {

    @IBAction func viewReportsTapped(_ sender: UIButton) {

        closeReportFlowAndGoToTab(index: 1)
    }

    @IBAction func goHomeTapped(_ sender: UIButton) {

        closeReportFlowAndGoToTab(index: 0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Evita regresar al Review después de enviar el reporte.
        navigationItem.hidesBackButton = true
    }

    private func closeReportFlowAndGoToTab(index: Int) {

        guard let reportNavigationController = navigationController else {
            return
        }

        guard let rootViewController =
                view.window?.rootViewController else {
            return
        }

        guard let tabBarController =
                findTabBarController(from: rootViewController) else {
            return
        }

        // Seleccionamos la pestaña deseada.
        tabBarController.selectedIndex = index

        // Cerramos todo el flujo del reporte.
        reportNavigationController.dismiss(animated: true)
    }

    private func findTabBarController(
        from viewController: UIViewController
    ) -> UITabBarController? {

        // Si este controlador ya es el Tab Bar, lo regresamos.
        if let tabBarController =
            viewController as? UITabBarController {

            return tabBarController
        }

        // Si es un Navigation Controller,
        // buscamos dentro de sus controladores.
        if let navigationController =
            viewController as? UINavigationController {

            for controller in navigationController.viewControllers {

                if let tabBarController =
                    findTabBarController(from: controller) {

                    return tabBarController
                }
            }
        }

        // También revisamos los controladores hijos.
        for child in viewController.children {

            if let tabBarController =
                findTabBarController(from: child) {

                return tabBarController
            }
        }

        return nil
    }
}

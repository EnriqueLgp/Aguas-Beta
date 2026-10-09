//
//  ReportSentViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 20/09/26.
//

import UIKit

class ReportSentViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Evita regresar al Review después de enviar el reporte
        navigationItem.hidesBackButton = true
    }

    @IBAction func viewReportsTapped(_ sender: UIButton) {
        closeReportFlowAndGoToTab(index: 1)
    }

    @IBAction func goHomeTapped(_ sender: UIButton) {
        closeReportFlowAndGoToTab(index: 0)
    }

    private func closeReportFlowAndGoToTab(index: Int) {

        guard let reportNavigationController = navigationController else {
            return
        }

        guard let rootViewController = view.window?.rootViewController else {
            return
        }

        guard let tabBarController = findTabBarController(
            from: rootViewController
        ) else {
            return
        }

        // Cambia a la pestaña deseada
        tabBarController.selectedIndex = index

        // Cierra todo el flujo de creación del reporte
        reportNavigationController.dismiss(animated: true)
    }

    private func findTabBarController(
        from viewController: UIViewController
    ) -> UITabBarController? {

        //Si ya encontramos el Tab Bar, lo regresamos
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }

        // Revisa controladores presentados de forma modal
        if let presentedViewController =
            viewController.presentedViewController {

            if let tabBarController = findTabBarController(
                from: presentedViewController
            ) {
                return tabBarController
            }
        }

        //revisa controladores dentro de Navigation Controllers
        if let navigationController =
            viewController as? UINavigationController {

            for controller in navigationController.viewControllers {

                if let tabBarController = findTabBarController(
                    from: controller
                ) {
                    return tabBarController
                }
            }
        }

        //Revisa controladores hijos
        for child in viewController.children {

            if let tabBarController = findTabBarController(
                from: child
            ) {
                return tabBarController
            }
        }

        return nil
    }
}

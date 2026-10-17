//
//  SceneDelegate.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 15/09/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        // Si la sesión ya no se puede renovar (refresh vencido o cuenta
        // suspendida), APIClient avisa y aquí regresamos al login.
        NotificationCenter.default.addObserver(
            forName: .aguasSesionTerminada,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let mensaje = notification.userInfo?["mensaje"] as? String
                ?? "Tu sesión terminó. Inicia sesión de nuevo."
            MainActor.assumeIsolated {
                self?.regresarAlLogin(mensaje: mensaje)
            }
        }
    }

    // La app es: Navigation (Bienvenida → Login) y, encima, el Tab Bar
    // presentado a pantalla completa. Quitar lo presentado deja el Login.
    private func regresarAlLogin(mensaje: String) {
        guard let raiz = window?.rootViewController else { return }

        let mostrarAviso = {
            let alerta = UIAlertController(
                title: "Sesión terminada",
                message: mensaje,
                preferredStyle: .alert
            )
            alerta.addAction(UIAlertAction(title: "OK", style: .default))
            raiz.present(alerta, animated: true)
        }

        if raiz.presentedViewController != nil {
            raiz.dismiss(animated: true, completion: mostrarAviso)
        } else {
            mostrarAviso()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}


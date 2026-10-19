//
//  Notification.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 18/10/26.
//

import Foundation

nonisolated struct AppNotification: Codable, Sendable {
    let idNotificacion: Int
    let idReporte: Int
    let tipo: String
    let titulo: String
    let mensaje: String
    let motivo: String?
    let fechaNotificacion: String
    let leida: Bool
}

//
//  APIConfig.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 08/10/26.
//

import Foundation

nonisolated enum APIConfig {

    // IP de la compu que corre el backend en la red del laboratorio.
    // Cámbiala por la IP real (el backend la imprime al arrancar:
    // "API en http://localhost:3000 y en http://<esta-ip>:3000").
    static let ipServidorLab = "192.168.20.10"

#if targetEnvironment(simulator)
    // En el simulador, "localhost" es la Mac donde corre el backend.
    static let baseURL = "http://localhost:3000"
#else
    // En un iPhone real, "localhost" sería el propio cel; hay que usar la IP.
    static let baseURL = "http://\(ipServidorLab):3000"
#endif
}

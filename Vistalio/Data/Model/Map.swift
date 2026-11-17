//
//  Place.swift
//  Vistalio
//
//  Created by Julia Konkova on 11.11.2026.
//

import UIKit
import CoreLocation

struct Place {
    let latitude: Double
    let longitude: Double
    let address: String?
}

enum MapApp: CaseIterable {
    case appleMaps
    case yandexMaps
    case yandexNavigator
    case twoGis
    case googleMaps

    var title: String {
        switch self {
        case .appleMaps: return "Apple Карты"
        case .yandexMaps: return "Яндекс Карты"
        case .yandexNavigator: return "Яндекс Навигатор"
        case .twoGis: return "2ГИС"
        case .googleMaps: return "Google Maps"
        }
    }

    // Базовая схема для проверки, установлено ли приложение
    private var checkURL: URL? {
        switch self {
        case .appleMaps: return URL(string: "http://apple.com")
        case .yandexMaps: return URL(string: "yandexmaps://")
        case .yandexNavigator: return URL(string: "yandexnavi://")
        case .twoGis: return URL(string: "dgis://")
        case .googleMaps: return URL(string: "comgooglemaps://")
        }
    }

    // Проверка установки на устройстве
    var isInstalled: Bool {
        if self == .appleMaps { return true } // Apple Карты доступны всегда (или откроются в браузере)
        guard let url = checkURL else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // Формирование ссылки для открытия конкретной точки
    func url(lat: Double, lon: Double) -> URL? {
        
        switch self {
        case .appleMaps:
            // ll — координаты, q — подпись пина
            return URL(string: "maps://?q=\(lat),\(lon)")

        case .yandexMaps:
            // pt — координаты точки (ВНИМАНИЕ: у Яндекса сначала долгота, потом широта!), z — зум
            return URL(string: "yandexmaps://maps.yandex.ru/?pt=\(lon),\(lat)&z=16&l=map")

        case .yandexNavigator:
            // Открывает сразу построение маршрута до точки
            return URL(string: "yandexnavi://build_route_on_map?lat_to=\(lat)&lon_to=\(lon)")

        case .twoGis:
            // В 2ГИС тоже сначала идёт долгота (lon), потом широта (lat)
            return URL(string: "dgis://2gis.ru/geo/\(lon),\(lat)")

        case .googleMaps:
            // q — центр и пин, zoom — масштаб
            return URL(string: "comgooglemaps://?q=\(lat),\(lon)&center=\(lat),\(lon)&zoom=16")
        }
    }

    // Получить список только тех карт, которые есть у пользователя
    static var availableApps: [MapApp] {
        return Self.allCases.filter { $0.isInstalled }
    }
}

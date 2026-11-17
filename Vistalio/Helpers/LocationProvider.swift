//
//  LocationProvider.swift
//  Vistalio
//
//  Created by Julia Konkova on 05.11.2026.
//

import UIKit
import CoreLocation

class LocationProvider : NSObject {
    
    static let shared = LocationProvider()
    
    private let manager = CLLocationManager()
    
    var onFirstLocationReceived: ((CLLocationCoordinate2D) -> ())?
    
    private(set) var lastKnownLocation: CLLocationCoordinate2D?
    
    private var authCompletion: ((Bool) -> Void)?
        
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = true
    }
    
    func startTrackingIfAuthorized() {
        let status = getAuthorizationStatus()
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = getAuthorizationStatus()
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            completion(true)
            return
        }
        
        if status == .notDetermined {
            authCompletion = completion
            manager.requestWhenInUseAuthorization()
        } else {
            completion(false)
        }
    }
    
    // Вспомогательный метод получения статуса для поддержки разных версий iOS
    private func getAuthorizationStatus() -> CLAuthorizationStatus {
        return manager.authorizationStatus
    }
}

extension LocationProvider : CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = getAuthorizationStatus()
        
        // Ждем, пока статус изменится с "notDetermined" на конкретный выбор пользователя
        guard status != .notDetermined else { return }
        
        let isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        if isAuthorized {
            manager.startUpdatingLocation()
        }
        
        // Вызываем коллбек, передавая результат (true или false), и обнуляем его
        authCompletion?(isAuthorized)
        authCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("Location updated")
        if lastKnownLocation == nil {
            print("First location received")
            onFirstLocationReceived?(location.coordinate)
        }
        
        lastKnownLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка постоянного GPS-трекинга: \(error.localizedDescription)")
    }
}



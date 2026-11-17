//
//  PlaceViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 12.11.2026.
//

import UIKit
import MapLibre

class PlaceViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var openButton: UIButton!
    
    private var mapView: MLNMapView!
    
    var location: GeoTag?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupBottomConstraint(openButton, bottom: 10)
        setupMapView()
        addLocation()
    }
    
    private func setupMapView() {
        guard let styleURL = URL(string: "https://tiles.openfreemap.org/styles/positron") else { return }
                
        mapView = MLNMapView(frame: view.bounds, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.automaticallyAdjustsContentInset = false
        
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let point = CGPoint(x: 16, y: (bottom > 0 ? bottom : 10) + 62)
        mapView.logoViewMargins = point
        mapView.attributionButtonMargins = point
        
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
    }
    
    private func addLocation() {
        if let location = location {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            mapView.addAnnotation(annotation)
            mapView.setCenter(annotation.coordinate, zoomLevel: 16, animated: false)
        }
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func openTapped() {
        
        guard let location = location else {
            return
        }
        
        let availableMaps = MapApp.availableApps

        // Если доступны только Apple Карты, можно открыть их сразу без лишнего меню
        if availableMaps.count == 1, let firstMap = availableMaps.first, let url = firstMap.url(lat: location.latitude, lon: location.longitude) {
            UIApplication.shared.open(url)
            return
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for mapApp in availableMaps {
            let action = UIAlertAction(title: mapApp.title, style: .default) { _ in
                if let url = mapApp.url(lat: location.latitude, lon: location.longitude) {
                    UIApplication.shared.open(url)
                }
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))

        present(alert, animated: true)
    }
}

extension PlaceViewController: MLNMapViewDelegate {
    func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        
        let reuseIdentifier = "customAnnotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MyCustomUserLocationView(reuseIdentifier: reuseIdentifier)
            annotationView?.bounds = CGRect(x: 0, y: 0, width: 36, height: 45)
            annotationView?.centerOffset = CGVector(dx: 0, dy: -22)
            
            let imageView = UIImageView(frame: annotationView!.bounds)
            imageView.image = UIImage.mapCenter
            
            imageView.contentMode = .scaleAspectFit
            annotationView?.addSubview(imageView)
        }
        
        return annotationView
    }
}

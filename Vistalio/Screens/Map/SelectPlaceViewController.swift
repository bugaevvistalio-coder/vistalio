//
//  PlaceViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 04.11.2026.
//

import UIKit
import MapLibre

class SelectPlaceViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    
    @IBOutlet weak var bottomSheetView: UIView!
    @IBOutlet weak var bottomSheetShadow: UIView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    @IBOutlet weak var addButton: UIButton!
    
    private var mapView: MLNMapView!
    private var myLocationAnnotation: MLNPointAnnotation?
    private var isFirstLocationLoaded = false
    
    var onPlaceSelected: ((Place) -> ())?
    private var address: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        centerButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 28, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: 30, height: 30))
        
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetView.layer.cornerRadius = 36
        bottomSheetShadow.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 36, shadowOpacity: 0.09, bounds: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 72))
        
        centerButton.isHidden = true
        setupBottomConstraint(addButton, bottom: 10)
        setupMapView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        let point = CGPoint(x: 16, y: bottomSheetView.frame.height + 10 - bottom)
        mapView.logoViewMargins = point
        mapView.attributionButtonMargins = point
    }
    
    private func setupMapView() {
        guard let styleURL = URL(string: "https://tiles.openfreemap.org/styles/positron") else { return }
                
        mapView = MLNMapView(frame: view.bounds, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.automaticallyAdjustsContentInset = false
        mapView.showsUserLocation = true
        
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func centerTapped() {
        if let coordinate = mapView.userLocation?.coordinate {
            mapView.setCenter(coordinate, zoomLevel: mapView.zoomLevel, animated: true)
        }
    }
    
    @IBAction func addressTapped() {
        let sb = UIStoryboard(name: "Missions", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "AddressVC") as! AddressViewController
        vc.coordinate = mapView.centerCoordinate
        vc.onPlaceSelected = { [unowned self] place in
            print("Address: \(place.address), \(place.countryCity)")
            mapView.setCenter(place.coordinate, zoomLevel: 16, animated: false)
        }
        presentFullScreen(vc, autoAdjustToKeyboard: false)
    }
    
    @IBAction func addTapped() {
        if !progressView.isHidden {
            return
        }
        let center = mapView.centerCoordinate
        onPlaceSelected?(Place(latitude: center.latitude, longitude: center.longitude, address: address))
        dismiss(animated: true)
    }
}

class MyCustomUserLocationView: MLNUserLocationAnnotationView {
}


extension SelectPlaceViewController: MLNMapViewDelegate {
    
    func mapView(_ mapView: MLNMapView, imageFor annotation: MLNAnnotation) -> MLNAnnotationImage? {
            
        if annotation is MLNUserLocation { return nil }
        
        let reuseIdentifier = "myLocationMarker"
        
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier)
        
        if annotationImage == nil {
            annotationImage = MLNAnnotationImage(image: UIImage.mePin, reuseIdentifier: reuseIdentifier)
        }
        
        return annotationImage
    }
    
    func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        
        guard annotation is MLNUserLocation else { return nil }
        
        let reuseIdentifier = "customUserLocationView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MyCustomUserLocationView(reuseIdentifier: reuseIdentifier)
            annotationView?.bounds = CGRect(x: 0, y: 0, width: 58, height: 59)
            
            let imageView = UIImageView(frame: annotationView!.bounds)
            imageView.image = UIImage.mePin
            
            imageView.contentMode = .scaleAspectFit
            annotationView?.addSubview(imageView)
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
        guard let coordinate = userLocation?.coordinate, !isFirstLocationLoaded else { return }
        guard coordinate.latitude != 0 && coordinate.longitude != 0 else { return }
        
        isFirstLocationLoaded = true
        
        mapView.setCenter(coordinate, zoomLevel: 16, animated: false)
        
        centerButton.isHidden = false
    }
    
    func mapView(_ mapView: MLNMapView, didChangeLocationManagerAuthorization manager: any MLNLocationManager) {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            CoreDataStack.shared.performAndWait { context in
                if let geoTag = GeoTag.fetchLatestRecord(context: context) {
                    mapView.setCenter(CLLocationCoordinate2D(latitude: geoTag.latitude, longitude: geoTag.longitude), zoomLevel: 16, animated: false)
                } else {
                    mapView.setCenter(CLLocationCoordinate2D(latitude: 66.416667, longitude: 94.250000), zoomLevel: 6, animated: false)
                }
            }
        }
    }
    
    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        if center.latitude == 0 && center.longitude == 0 {
            addressLabel.text = "Поиск по адресу"
            addressLabel.textColor = .textGrey30
            return
        }
        
        progressView.isHidden = false
        progressView.startAnimating()
        addButton.setTitleColor(.clear, for: .normal)
        
        GeocodingService.shared.fetchGeoapifyAddress(from: center) { [weak self] resolvedAddress, coordinate in
            
            DispatchQueue.main.async {
                let center = mapView.centerCoordinate
                print("Center is \(center), coordinate is \(coordinate)")
                if coordinate.latitude == center.latitude && coordinate.longitude == center.longitude {
                    self?.progressView.stopAnimating()
                    self?.progressView.isHidden = true
                    self?.addButton.setTitleColor(.white, for: .normal)
                    
                    if let address = resolvedAddress {
                        self?.addressLabel.text = address
                        self?.addressLabel.textColor = .black
                    } else {
                        self?.addressLabel.text = "Поиск по адресу"
                        self?.addressLabel.textColor = .textGrey30
                    }
                    self?.address = resolvedAddress
                }
            }
        }
    }
}

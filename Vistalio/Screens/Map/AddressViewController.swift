//
//  AddressViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.11.2026.
//

import UIKit
import CoreLocation

class AddressViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var textField: StyledTextField!
    @IBOutlet weak var tableView: UITableView!
    
    var address: String?
    var coordinate: CLLocationCoordinate2D!
    var onPlaceSelected: ((AddressPrediction) -> ())?
    
    private var predictions = [AddressPrediction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.highlightBlue.cgColor
        textField.text = address
        
        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        
        textField.becomeFirstResponder()
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBAction func clearTapped() {
        textField.text = nil
        predictions.removeAll()
        tableView.reloadData()
        textField.becomeFirstResponder()
    }
    
    @IBAction func textChanged() {
        let searchText = textField.text ?? ""
        if searchText.isEmpty {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if let `self` = self, searchText == self.textField.text {
                GeocodingService.shared.appleLocalSearch(text: searchText, biasCoordinate: self.coordinate) { predictions, text in
                    DispatchQueue.main.async {
                        if searchText != text {
                            return
                        }
                        self.predictions = predictions
                        self.tableView.reloadData()
                        print("Addresses updated")
                    }
                }
            }
        }
    }
}

extension AddressViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath) as! AddressCell
        if indexPath.row == predictions.count {
            cell.prediction = nil
        } else {
            cell.prediction = predictions[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < predictions.count {
            print("Address at \(indexPath.row)")
            onPlaceSelected?(predictions[indexPath.row])
        }
        dismiss(animated: true)
    }
}

//
//  AddressCell.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.11.2026.
//

import UIKit

class AddressCell: UITableViewCell {
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var countryCityLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        arrowImageView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 12, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 24, height: 24))
    }
    
    var prediction: AddressPrediction? {
        didSet {
            if let prediction = prediction {
                addressLabel.text = prediction.address
                countryCityLabel.text = prediction.countryCity
                addressLabel.textColor = .black
//                arrowImageView.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 12, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 24, height: 24))
            } else {
                addressLabel.text = "Нет нужного адреса"
                countryCityLabel.text = "Выберите на карте"
                addressLabel.textColor = .highlightBlue
            }
        }
    }
}

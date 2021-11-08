//
//  DevicesTableViewCell.swift
//  MBD Tracker
//
//  Created by Soeng Saravit on 4/7/21.
//

import UIKit

class DevicesTableViewCell: UITableViewCell {

    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceStatusLabel: UILabel!
    @IBOutlet weak var deviceIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindView(icon:UIImage, deviceName:String, status:String) {
        if status == "Paired Device" {
            self.deviceStatusLabel.textColor = .red
        }else {
            self.deviceStatusLabel.textColor = .black
        }
        self.deviceNameLabel.text = deviceName
        self.deviceStatusLabel.text = status
        self.deviceIconImageView.image = icon
    }

}



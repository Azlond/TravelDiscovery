//
//  TravelsTableViewCell.swift
//  TravelDiscovery
//
//  Created by Hyerim Park on 13/01/2018.
//  Copyright © 2018 Jan. All rights reserved.
//

import UIKit

class TravelsTableViewCell: UITableViewCell {

    @IBOutlet weak var travelNameLabel: UILabel!
    @IBOutlet weak var travelDateLabel: UILabel!
    @IBOutlet weak var travelImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
      
        layer.masksToBounds = true
        layer.cornerRadius = min(self.frame.width/2 , self.frame.height/2)
        clipsToBounds = true

    }
}

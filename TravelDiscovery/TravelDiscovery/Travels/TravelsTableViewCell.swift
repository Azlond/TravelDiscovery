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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
      
        layer.masksToBounds = true
        layer.cornerRadius = min(self.frame.width/2 , self.frame.height/2)
        clipsToBounds = true
        // layer.borderWidth = 1
        // layer.borderColor = UIColor.lightGray.cgColor
       // backgroundColor = UIColor.black
      
        
    }
    /*
    override func prepareForReuse() {
        imgView.image = nil
        imgView.setRandomBackgroundColor()
        super.prepareForReuse()
    }
 */
    
}

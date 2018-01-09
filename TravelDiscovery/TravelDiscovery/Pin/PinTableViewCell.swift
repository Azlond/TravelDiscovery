//
//  PinTableViewCell.swift
//  TravelDiscovery
//
//  Created by admin on 21.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import UIKit

class PinTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var pinNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
   
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    override func prepareForReuse() {
        imgView.image = nil
        imgView.setRandomBackgroundColor()
        super.prepareForReuse()
    }
    
}

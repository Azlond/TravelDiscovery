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
    
    @IBOutlet weak var imageStackView: UIStackView!
    @IBOutlet weak var pinNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    
    }
    
}

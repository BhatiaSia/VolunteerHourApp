//
//  LogCell.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 9/7/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import Foundation
import UIKit

class LogCollectionViewCell: UICollectionViewCell {
    @IBOutlet var cellLabel: UILabel!
    @IBOutlet var cellDate: UILabel!
    @IBOutlet var cellHours: UILabel!
    
    override func layoutSubviews() {
        // cell rounded section
        self.layer.cornerRadius = 15.0
        self.layer.borderWidth = 5.0
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.masksToBounds = true
    }
}

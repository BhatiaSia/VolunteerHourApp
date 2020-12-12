//
//  ImageViewController.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 10/3/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
}

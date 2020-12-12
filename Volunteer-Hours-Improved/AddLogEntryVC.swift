//
//  AddLogEntryVC.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 9/7/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase

class AddLogEntryViewController: UIViewController {
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var activtyNameField: UITextField!
    @IBOutlet var activityTimePicker: UIDatePicker!
    var user: User!
    var ref: DatabaseReference!
    var curSnapShot: NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissVC))
    }
    
    @objc func dismissKeyboard(selector: AnyObject) {
        self.activtyNameField.resignFirstResponder()
    }
    
    @objc func dismissVC() {
        // Get activity name here
        if let activityName = activtyNameField.text {
            // Get time put in
            let timeSpent = Double(activityTimePicker.countDownDuration)
            
            if activityName != "" {
                self.ref.child(user!.uid).child("places").observeSingleEvent(of: .value) { (snapshot) in
                    guard let snapshot = snapshot.value as? NSDictionary else {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                        let now = df.string(from: Date())
                        guard let key = self.ref.child(self.user.uid).childByAutoId().key else { return }
                        let activityItem = [
                            "name": activityName,
                            "date": now,
                            "seconds": String(timeSpent),
                            "note": ""
                        ]
                        let childUpdates = ["/" + self.user.uid + "/logs/\(key)": activityItem,
                                            "/" + self.user.uid + "/places/\(activityName)": String(timeSpent)] as [String : Any]
                        self.ref.updateChildValues(childUpdates)
                        return
                    }
                    
                    let originalTimeSpent = snapshot[activityName] as? String
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                    let now = df.string(from: Date())
                    guard let key = self.ref.child(self.user.uid).childByAutoId().key else { return }
                    let activityItem = [
                        "name": activityName,
                        "date": now,
                        "seconds": String(timeSpent),
                        "note": ""
                    ]
                    let childUpdates = ["/" + self.user.uid + "/logs/\(key)": activityItem,
                                        "/" + self.user.uid + "/places/\(activityName)": String(Double((originalTimeSpent ?? "0.0"))! + timeSpent)] as [String : Any]
                    self.ref.updateChildValues(childUpdates)
                }
                
            }
            _ = navigationController?.popViewController(animated: true)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
}

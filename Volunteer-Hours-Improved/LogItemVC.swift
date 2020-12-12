//
//  LogItemVC.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 9/7/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import UIKit


class LogItemVC: UIViewController {
    @IBOutlet var activityName: UILabel!
    @IBOutlet var activityHours: UILabel!
    @IBOutlet var noteField: UITextView!

    var activityHoursVar = 0.0
    var activityNameVar = ""
    var activityDate = ""
    var initialNoteText = ""
    var totalHoursVar = 0.0
    var ref: DatabaseReference!
    var user: User?
    let formatter = DateComponentsFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        
        self.activityName.text = activityDate
        self.activityHours.text = formatter.string(from: TimeInterval(activityHoursVar))
        
        self.title = activityNameVar

        self.ref.child(user!.uid).child("places").observeSingleEvent(of: .value) { (snapshot) in
            guard let snapshot = snapshot.value as? NSDictionary else {
                return
            }
            let originalTimeSpent = Double(snapshot[self.activityNameVar] as! String)!
            self.totalHoursVar = originalTimeSpent
        }
        self.noteField.layer.borderColor = UIColor.lightGray.cgColor
        self.noteField.layer.borderWidth = 1
        self.noteField.layer.cornerRadius = 5
        self.noteField.layer.masksToBounds = true
        self.noteField.text = initialNoteText
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.ref.child(user!.uid).child("logs")
            .queryOrdered(byChild: "date")
            .queryEqual(toValue: activityDate)
            .observeSingleEvent(of: .value) { snapshot in
                guard let user = self.user else { return }
                let key = (snapshot.children.allObjects[0] as! DataSnapshot).key
                let activityItem = [
                    "name": self.activityNameVar,
                    "date": self.activityDate,
                    "seconds": String(self.activityHoursVar),
                    "note": self.noteField.text ?? "poop"
                ] as [String : Any]
                let childUpdates = ["/" + user.uid + "/logs/\(key)": activityItem]
                self.ref.updateChildValues(childUpdates)
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let destVC = segue.destination as? DetailEventViewController {
                destVC.eventName = activityNameVar
                destVC.totalTime = formatter.string(from: TimeInterval(totalHoursVar))
            }
        }
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}

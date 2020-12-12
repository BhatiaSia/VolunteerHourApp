//
//  LogTableViewController.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 9/7/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import ColorHash

struct LogDBItem {
    let name: String
    let email: String
    let date: String
}

class LogTableViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var ref: DatabaseReference!
    
    var user: User?
    
    var data: NSMutableArray = []
    
    var curSnapshot: NSDictionary?
    
    var curActivityName: String = ""
    
    @IBOutlet var collectionView: UICollectionView!
    
    var curActivityHours: String = ""
    
    var curActivityDate: String = ""
    
    var oldNote: String = ""
    
    let formatter = DateComponentsFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Event Log"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tappedPlus(sender:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.setTitlePositionAdjustment(.init(horizontal: 10, vertical: 20), for: UIBarMetrics.default)
        
        self.data = []

        if user == nil {
            Auth.auth().signIn(withEmail: "test123@gmail.com", password: "123456") { [weak self] (res, error) in
                guard self != nil else { return }
            }
        }
        
        let _ = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                self.user = user
                
                self.ref.child(user.uid).observeSingleEvent(of: .value) { (snapshot) in
                    guard let snapshot = snapshot.value as? NSDictionary else { return }
                    self.curSnapshot = snapshot
                    
                    for (_, (_, value)) in (snapshot["logs"] as! NSDictionary).enumerated() {
                        self.data.add(value)
                    }
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                    self.data = NSMutableArray(array: self.data.sorted { (val1, val2) -> Bool in
                        let d2 = (val2 as? NSMutableDictionary)?["date"] as! String
                        let d1 = (val1 as? NSMutableDictionary)?["date"] as! String
                        
                        let date1 = df.date(from: d1)!
                        let date2 = df.date(from: d2)!
                        return date1 > date2
                        })
                    self.collectionView.reloadData()
                }
            }
        })

    }
    
    
    @IBAction func valueChanged(_ sender: UIRefreshControl) {
        print("called")
        self.ref.child(user!.uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let snapshot = snapshot.value as? NSDictionary else {
                self.data = []

                self.collectionView.reloadData()
                sender.endRefreshing()
                return
            }
            self.curSnapshot = snapshot

            self.data = []

            for (_, (_, value)) in (snapshot["logs"] as! NSDictionary).enumerated() {
                self.data.add(value)
            }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm:ss"
            self.data = NSMutableArray(array: self.data.sorted { (val1, val2) -> Bool in
                let d2 = (val2 as? NSMutableDictionary)?["date"] as! String
                let d1 = (val1 as? NSMutableDictionary)?["date"] as! String
                
                let date1 = df.date(from: d1)!
                let date2 = df.date(from: d2)!
                return date1 > date2
                })
    
            
            self.collectionView.reloadData()
            sender.endRefreshing()
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellData", for: indexPath) as? LogCollectionViewCell, self.data.count > 0 else {
            fatalError("bad cell")
        }
        
                
        let elem = self.data[indexPath.row] as? NSMutableDictionary
        let time = Double(elem?["seconds"] as! String)!
        
        let formattedTime = self.formatter.string(from: TimeInterval(time))
        cell.cellLabel.text = elem?["name"] as? String
        cell.backgroundColor = ColorHash(cell.cellLabel.text!).color
        cell.cellLabel.textColor = cell.backgroundColor?.isDarkColor == true ? .white : .black
        cell.cellDate.text = String((elem?["date"] as? String)?.split(separator: " ")[0] ?? "")
        cell.cellDate.textColor = cell.backgroundColor?.isDarkColor == true ? .white : .black

        cell.cellHours.text = formattedTime
        cell.cellHours.textColor = cell.backgroundColor?.isDarkColor == true ? .white : .black
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let elem = self.data[indexPath.row] as? NSMutableDictionary
        curActivityName = elem?["name"] as! String
        curActivityHours = elem?["seconds"] as! String
        curActivityDate = elem?["date"] as! String
        oldNote = elem?["note"] as! String
        performSegue(withIdentifier: "cellSegue", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width - 20, height: 120)
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addLog" {
            if let destVC = segue.destination as? AddLogEntryViewController {
                guard let user = self.user else { return }
                destVC.user = user
                destVC.ref = ref
                destVC.curSnapShot = curSnapshot
            }
        } else if segue.identifier == "cellSegue" {
            if let destVC = segue.destination as? LogItemVC {
                destVC.activityHoursVar = Double(curActivityHours)!
                destVC.activityNameVar = curActivityName
                destVC.activityDate = curActivityDate
                destVC.initialNoteText = oldNote
                destVC.ref = ref
                destVC.user = user
            }
        }
    }
    
    @objc func tappedPlus(sender: AnyObject) {
        performSegue(withIdentifier: "addLog", sender: sender)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("test")
    }
}

extension UIColor
{
    var isDarkColor: Bool {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return  lum < 0.50
    }
}

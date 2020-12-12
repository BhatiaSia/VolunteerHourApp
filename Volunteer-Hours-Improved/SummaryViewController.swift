//
//  SummaryViewController.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 10/4/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import UIKit
import Charts
import FirebaseDatabase
import FirebaseAuth
import ColorHash
import PDFKit

struct DataBundle {
    let name: String
    let time: String
}

class SummaryViewController: UIViewController, ChartViewDelegate {
    var ref: DatabaseReference!
    var user: User?
    var data: NSMutableDictionary = [:]
    var curSnapshot: NSDictionary = [:]
    var selectedEvent: String = ""
    var selectedEventHours: String = ""
    var totalHours: Double = 0.0
    
    @IBOutlet var exportButton: UIButton!
    @IBOutlet var pieChart: PieChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Overview"
        self.navigationController?.topViewController?.title = "Overview"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.exportButton.addTarget(self, action: #selector(exportData), for: .touchUpInside)
        self.pieChart.delegate = self
        ref = Database.database().reference()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                    
                    for (_, (key, value)) in (snapshot["places"] as! NSDictionary).enumerated() {
                        self.data[key] = Double(value as! String)
                    }
                    self.setupChart(dataPt: self.data.allKeys as! [String], values: self.data.allValues as! [Double])
                    self.pieChart.setNeedsDisplay()
                }
            }
        })
    }
    
    @objc func exportData() {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        
        let pdf = createPDF(hours: pieChart.centerText!)
        
        let activityVC = UIActivityViewController(activityItems: [pdf], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let data = entry.data as? DataBundle else { return }
        selectedEvent = data.name
        selectedEventHours = data.time
        pieChart.highlightValue(nil)
        performSegue(withIdentifier: "showDetail", sender: self)
        
    }
    
    func setupChart(dataPt: [String], values: [Double]) {
        pieChart.noDataText = "Add volunteering hours to see a breakdown here!"
//        pieChart.rotationEnabled = false
        
        var dataEntries: [PieChartDataEntry] = []
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        
        for i in 0..<dataPt.count {
            let extraData: DataBundle = DataBundle(name: dataPt[i], time: formatter.string(from: TimeInterval(values[i]))!)
            let dE = PieChartDataEntry(value: values[i], label: dataPt[i], data: extraData as DataBundle)
            dataEntries.append(dE)
            totalHours += values[i]
        }
    
        pieChart.centerText = formatter.string(from: TimeInterval(totalHours))
        totalHours = 0
        let dataSet = PieChartDataSet(entries: dataEntries, label: nil)
        dataSet.colors = colorsOfCharts(labels: dataPt)
        dataSet.drawValuesEnabled = false
        
        let data = PieChartData(dataSet: dataSet)
        
        pieChart.data = data
        pieChart.legend.horizontalAlignment = .center
        pieChart.legend.verticalAlignment = .bottom
        pieChart.legend.xOffset = 10
    }
    
    func createPDF(hours: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Sia Bhatia",
            kCGPDFContextAuthor: "Sia Bhatia"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            addTitle(pageRect: pageRect, title: "Sia's Volunteer Hours" )
            addHours(pageRect: pageRect, val: hours)
            
            
        }
        
        return data

    }
    
    func addTitle(pageRect: CGRect, title: String) -> CGFloat {
      // 1
      let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
      // 2
      let titleAttributes: [NSAttributedString.Key: Any] =
        [NSAttributedString.Key.font: titleFont]
      // 3
      let attributedTitle = NSAttributedString(
        string: title,
        attributes: titleAttributes
      )
      // 4
      let titleStringSize = attributedTitle.size()
      // 5
      let titleStringRect = CGRect(
        x: (pageRect.width - titleStringSize.width) / 2.0,
        y: 36,
        width: titleStringSize.width,
        height: titleStringSize.height
      )
      // 6
      attributedTitle.draw(in: titleStringRect)
      // 7
      return titleStringRect.origin.y + titleStringRect.size.height
    }
    
    func addHours(pageRect: CGRect, val: String) -> CGFloat {
      // 1
      let titleFont = UIFont.systemFont(ofSize: 16.0, weight: .regular)
      // 2
      let titleAttributes: [NSAttributedString.Key: Any] =
        [NSAttributedString.Key.font: titleFont]
      // 3
      let attributedTitle = NSAttributedString(
        string: val,
        attributes: titleAttributes
      )
      // 4
      let titleStringSize = attributedTitle.size()
      // 5
      let titleStringRect = CGRect(
        x: 20,
        y: 50,
        width: titleStringSize.width,
        height: titleStringSize.height
      )
      // 6
      attributedTitle.draw(in: titleStringRect)
      // 7
      return titleStringRect.origin.y + titleStringRect.size.height
    }
    
    private func colorsOfCharts(labels: [String]) -> [UIColor] {
        var ret: [UIColor] = []
        
        for label in labels {
            ret.append(ColorHash(label).color)
        }
        
        return ret
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let destVC = segue.destination as? DetailEventViewController {
                destVC.eventName = selectedEvent
                destVC.totalTime = selectedEventHours
            }
        }
    }
}

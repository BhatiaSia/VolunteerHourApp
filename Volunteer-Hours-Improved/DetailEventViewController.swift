//
//  DetailEventViewController.swift
//  Volunteer-Hours-Improved
//
//  Created by Sia Bhatia on 10/3/20.
//  Copyright © 2020 Sia Bhatia. All rights reserved.
//

import UIKit

class DetailEventViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var timeLabel: UILabel!
    
    var eventName: String!
    var totalTime: String!
    
    var imagePicker: UIImagePickerController!
    
    var images: [(String, UIImage)] = []
    
    let fileManager = FileManager.default
    
    var curSelectedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = eventName
        timeLabel.text = totalTime
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 1
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        if let fileNames = loadImages(prefix: eventName) {
            for f in fileNames {
                images.append((f, getSavedImage(named: f)!))
            }
        }
        
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(tappedCamera(sender:)))
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detailCell", for: indexPath) as? ProofCell else { fatalError("bad cell") }
        cell.img.image = images[indexPath.row].1
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 5, height: 128)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedImage = images[indexPath.row].1
        curSelectedImage = selectedImage
        performSegue(withIdentifier: "showImage", sender: self)
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage" {
            if let destVC = segue.destination as? ImageViewController {
                destVC.imageView = UIImageView(image: curSelectedImage)
                destVC.image = curSelectedImage
            }
        }
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer!) {
        if gesture.state != .began {
            return
        }
        let p = gesture.location(in: self.collectionView)
        
        if let indexPath = self.collectionView.indexPathForItem(at: p) {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? ProofCell, let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            let imageTuple = images.filter { $0.1 == cell.img.image }.first!
            let fileName = imageTuple.0
            let fileURL = documentsDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                    images.removeAll { (item) -> Bool in
                        item.1 == cell.img.image
                    }
                    self.collectionView.reloadData()
                } catch let e {
                    print(e)
                }
            }
        }
    }
    
    @objc func tappedCamera(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { (action) in
            self.imagePicker =  UIImagePickerController()
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        let photoLibraryAction = UIAlertAction(title: "Choose Existing", style: .default) { (action) in
            self.imagePicker =  UIImagePickerController()
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }

        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibraryAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else {
            return
        }
        
        // save image
        let path = eventName + "-" + UUID().uuidString
        saveImage(imageName: path, image: selectedImage)
        
        images.append((path, selectedImage))
        collectionView.reloadData()
    }
    
    func saveImage(imageName: String, image: UIImage) {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDir.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let e {
                print(e)
            }
        }
        
        do {
            try data.write(to: fileURL)
        } catch let e {
            print(e)
        }
    }
    
    func loadImages(prefix: String) -> [String]? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let imgFiles = contents.filter { $0.absoluteString.contains(eventName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) }
            let fileNames = imgFiles.map{ $0.deletingPathExtension().lastPathComponent }
            return fileNames
        } catch let e {
            print(e)
        }
        return nil
    }
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }

}

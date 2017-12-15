//
//  PinViewController.swift
//  TravelDiscovery
//
//  Created by Laura on 13.12.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import Foundation
import UIKit
import Photos
import NohanaImagePicker

class PinViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK: UI controls
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var commentsTextView: UITextView!
    @IBOutlet weak var publicSwitch: UISwitch!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //variables for image display
    var picker = NohanaImagePickerController()
    var selectedPhotos = [UIImage]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSettings()
        
        addBorderToTextView()
        
        //init image picker
        picker.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        
    }
    
    func initSettings() {
        //Location
        // TODO: get current location
        
        //Date
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let today = formatter.string(from: date)
        dateTextField.text = today
        
        //Share visibility from user settings -> TODO
    }
    
    
    func addBorderToTextView() {
        let color = UIColor.init(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        commentsTextView.layer.borderWidth = 0.5
        commentsTextView.layer.borderColor = color.cgColor
        commentsTextView.layer.cornerRadius = 5.0
    }
    
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        option.version = .original
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
//
//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
    
    //MARK: Image display in CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath)
        let imageView = UIImageView(image: selectedPhotos[indexPath.row])
        cell.contentView.addSubview(imageView)
        return cell
    }
    
    //MARK: User Interaction
    
    @IBAction func clickedCancel(_ sender: UIBarButtonItem) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func clickedSave(_ sender: UIBarButtonItem) {
        //required parameters
        let name = locationTextField.text
        let date = dateTextField.text
        let longitude = 0.123
        let latitude = 0.456
        
        //TODO: error handling: required fields not filled out
        
        let visibility = publicSwitch.isOn
        let text = commentsTextView.text
        
        let pin : Pin = Pin.init(name: name!, longitude: longitude, latitude: latitude,
                           visibilityPublic: visibility, date: date!,
                           photos: [], text: text!)!
        savePin(pin: pin)
        
    }
    
    @IBAction func addImages(_ sender: UIButton) {
        //open multi image picker
        present(picker, animated: true, completion: nil)
    }
    
    func savePin(pin: Pin) {
        //do
    }
    
    

}

// MARK: Extension ImagePickerController

extension PinViewController: NohanaImagePickerControllerDelegate {
    
    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        print("🐷Canceled🙅")
        picker.dismiss(animated: true, completion: nil)
    }
    
    func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset]) {
        print("🐷Completed🙆\n\tpickedAssets = \(pickedAssts)")
        picker.dismiss(animated: true, completion: nil)
        
        
        for asset in pickedAssts {
            self.selectedPhotos.append(self.getAssetThumbnail(asset: asset))
        }
        
        self.collectionView.reloadData()
        
    }
}

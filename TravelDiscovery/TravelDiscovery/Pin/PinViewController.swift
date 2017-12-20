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
import SwiftLocation

class PinViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK: UI controls
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var locationText: UILabel!
    @IBOutlet weak var commentsTextView: UITextView!
    @IBOutlet weak var publicSwitch: UISwitch!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //variables
    var latitude: Double = 0.0, longitude: Double = 0.0
    
    //variables for image display
    var picker = NohanaImagePickerController()
    var selectedPhotos = [UIImage]()
    var thumbnails = [UIImage]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //check for current location
        Locator.currentPosition(accuracy: .block, onSuccess: { location -> (Void) in
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.initSettings()
            
        }) { (error, loc) -> (Void) in
            Locator.currentPosition(accuracy: .neighborhood, onSuccess: { location -> (Void) in
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
                self.initSettings()
                
            }) { (error, loc) -> (Void) in
                print(error)
                let alert = UIAlertController(title: "Error",
                                              message: "Unable to track location. Please try again another time.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.returnToParentViewController()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBorderToTextView()
        
        //init image picker
        picker.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        
        self.hideKeyboardWhenTappedAround()

    }
    
    func initSettings() {
        //Location: only display first 8 chars
        let latString = String(latitude).prefix(8)
        let lonString = String(longitude).prefix(8)
        locationText.text = "lat: " + latString + ", lon: " + lonString
        
        //Date
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let today = formatter.string(from: date)
        dateText.text = today
        
        //get Share-visibility from user settings
        publicSwitch.setOn(UserDefaults.standard.bool(forKey: "visibility"), animated: false)
    }
    
    
    func addBorderToTextView() {
        let color = UIColor.init(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        commentsTextView.layer.borderWidth = 0.5
        commentsTextView.layer.borderColor = color.cgColor
        commentsTextView.layer.cornerRadius = 5.0
    }
    
    //creates a thumbnail for chosen image assets to display them
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let retinaSquare = CGSize(width: 80.0, height: 80.0)
        let cropSizeLength = min(asset.pixelWidth, asset.pixelHeight)
        let square = CGRect(x:0, y: 0,width: CGFloat(cropSizeLength),height: CGFloat(cropSizeLength))
        let cropRect = square.applying(CGAffineTransform(scaleX: 1.0/CGFloat(asset.pixelWidth), y: 1.0/CGFloat(asset.pixelHeight)))

        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        option.version = .original
        option.deliveryMode = .highQualityFormat
        option.resizeMode = .exact
        option.normalizedCropRect = cropRect
            
        manager.requestImage(for: asset, targetSize: retinaSquare, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    
    // creates UIImage in original size from chosen photo assets
    func getUIImageFromAsset(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var image = UIImage()
        
        option.version = .original
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in image = result! })
        return image
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
        return thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath)
        let imageView = UIImageView(image: thumbnails[indexPath.row])
        imageView.sizeToFit()
        cell.contentView.addSubview(imageView)
        return cell
    }
    
    //MARK: User Interaction
    
    @IBAction func clickedCancel(_ sender: UIBarButtonItem) {
        returnToParentViewController()
    }
    
    @IBAction func clickedSave(_ sender: UIBarButtonItem) {
        //required parameters
        guard let name = locationTextField.text else {
            //warning for user in field
            return
        }
        let date = dateText.text!
        let longitude = self.longitude
        let latitude = self.latitude
        
        //TODO: error handling: required fields not filled out
        
        let visibility = publicSwitch.isOn
        let text = commentsTextView.text
        
        let id = "Pin_" + UUID().uuidString
        
        let pin : Pin = Pin.init(id: id, name: name, longitude: longitude, latitude: latitude,
                           visibilityPublic: visibility, date: date,
                           photos: selectedPhotos, text: text!)!
        savePin(pin: pin)
        
        //save location to background data for route visualization
        let location = CLLocation.init(latitude: latitude, longitude: longitude)
        FirebaseController.handleBackgroundLocationData(location: location)
        
        returnToParentViewController()
        
    }
    
    @IBAction func addImages(_ sender: UIButton) {
        //open multi image picker
        present(picker, animated: true, completion: nil)
    }
    
    func savePin(pin: Pin) {
        FirebaseData.pins[pin.id] = pin
        FirebaseController.savePinsToFirebase()
    }
    
    func returnToParentViewController() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    

}

// MARK: Extension ImagePickerController

extension PinViewController: NohanaImagePickerControllerDelegate {
    
    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset]) {
        //print("🐷Completed🙆\n\tpickedAssets = \(pickedAssts)")
        picker.dismiss(animated: true, completion: nil)
        
        thumbnails = [UIImage]()
        selectedPhotos = [UIImage]()
        
        for asset in pickedAssts {
            thumbnails.append(getAssetThumbnail(asset: asset))
            //TODO: compress images
            selectedPhotos.append(getUIImageFromAsset(asset: asset))
        }
        collectionView.reloadData()
        
    }
}






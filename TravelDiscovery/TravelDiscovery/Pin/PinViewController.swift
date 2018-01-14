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

class PinViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: UI controls
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var locationText: UILabel!
    @IBOutlet weak var commentsTextView: UITextView!
    @IBOutlet weak var publicSwitch: UISwitch!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var videoPreview: UIImageView!
    
    var latitude: Double = 0.0, longitude: Double = 0.0
    
    //variables for image display
    var picker = NohanaImagePickerController()
    var selectedPhotos = [UIImage]()
    var thumbnails = [UIImage]()
    
    var videoPicker = UIImagePickerController()
    var selectedVideoURL: URL?
    var videoThumbnail: UIImage?

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.latitude = UserDefaults.standard.double(forKey: "latitude")
        self.longitude = UserDefaults.standard.double(forKey: "longitude")
        initSettings()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBorderToTextView()
        
        //init image picker
        videoPicker.delegate = self
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
    
    //MARK: Image display in CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath)
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 79, height: 79))
        imageView.image = thumbnails[indexPath.row]
        cell.contentView.addSubview(imageView)
        return cell
    }
    
    //MARK: User Interaction
    
    @IBAction func clickedCancel(_ sender: UIBarButtonItem) {
        returnToParentViewController()
    }
    
    @IBAction func clickedSave(_ sender: UIBarButtonItem) {

        let id = "Pin_" + UUID().uuidString
        
        let name = locationTextField.text
        if name == "" {
            //display warning
            let alert = UIAlertController(title: "Missing Input", message: "Please enter a Pin Name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                return
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        //calculate number of pin in active travel
        var pinNumber = 0
        if let travel = FirebaseData.getActiveTravel() {
            pinNumber = travel.pins.count + 1
        }
        
        let pin : Pin = Pin.init(id: id,
                                 number: pinNumber,
                                 name: name!,
                                 longitude: longitude,
                                 latitude: latitude,
                                 visibilityPublic: publicSwitch.isOn,
                                 date: dateText.text!,
                                 photos: selectedPhotos,
                                 videoURL: selectedVideoURL,
                                 videoThumbnail: videoThumbnail,
                                 text: commentsTextView.text!)!
        
        // save pin to travel
        if let currentTravel = FirebaseData.getActiveTravel() {
            currentTravel.pins[pin.id] = pin
            FirebaseController.saveTravelsToFirebase()
        }
                
        //save location to background data for route visualization
        let location = CLLocation.init(latitude: latitude, longitude: longitude)
        FirebaseController.handleBackgroundLocationData(location: location)
        
        returnToParentViewController()
        
    }
    
    @IBAction func addImages(_ sender: UIButton) {
        //open multi image picker
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func addVideo(_ sender: Any) {
        videoPicker.sourceType = .savedPhotosAlbum
        videoPicker.mediaTypes = ["public.movie"]
        videoPicker.allowsEditing = true
        videoPicker.videoQuality = .typeIFrame960x540
        present(videoPicker, animated: true, completion: nil)
    }
    
    
    // MARK: Helper Functions
    
    //creates a thumbnail for chosen image assets to display them
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let retinaScale = UIScreen.main.scale
        let retinaSquare = CGSize(width: 80.0 * retinaScale, height: 80.0 * retinaScale)
        let cropSizeLength = min(asset.pixelWidth, asset.pixelHeight)
        let square = CGRect(x:0, y: 0,width: CGFloat(cropSizeLength),height: CGFloat(cropSizeLength))
        let cropRect = square.applying(CGAffineTransform(scaleX: 1.0/CGFloat(asset.pixelWidth), y: 1.0/CGFloat(asset.pixelHeight)))
        
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
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
    
    func compressImage(image:UIImage) -> Data? {
        var actualHeight : CGFloat = image.size.height
        var actualWidth : CGFloat = image.size.width
        let maxHeight : CGFloat = 1136.0
        let maxWidth : CGFloat = 640.0
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        var compressionQuality : CGFloat = 0.5
        
        if (actualHeight > maxHeight || actualWidth > maxWidth){
            if(imgRatio < maxRatio){
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if(imgRatio > maxRatio){
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else{
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        guard let imageData = UIImageJPEGRepresentation(img, compressionQuality) else{
            return nil
        }
        return imageData
    }
    
    //video selected
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
            self.selectedVideoURL = videoURL
        }
        if let asset = info["UIImagePickerControllerPHAsset"] as? PHAsset {
            self.videoThumbnail = getUIImageFromAsset(asset: asset)
            videoPreview.image = videoThumbnail
        }
        videoPicker.dismiss(animated: true, completion: nil)
    }
  
    
    
    func returnToParentViewController() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

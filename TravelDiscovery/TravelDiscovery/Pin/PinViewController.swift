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
import ImagePicker
import SwiftLocation

class PinViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImagePickerDelegate {
    
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
    var selectedPhotos = [UIImage]()
    var thumbnails = [UIImage]()
    
    var videoPicker = UIImagePickerController()
    var selectedVideoURL: URL?
    var videoThumbnail: UIImage?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if(self.latitude == 0 && self.longitude == 0) {
            self.latitude = UserDefaults.standard.double(forKey: "latitude")
            self.longitude = UserDefaults.standard.double(forKey: "longitude")
            initSettings()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBorderToTextView()
        
        videoPicker.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(activateDeleteOption)))
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
        return self.selectedPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath)
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 79, height: 79))
        imageView.image = selectedPhotos[indexPath.row]
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

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
        
        //calculate number of pins in active travel
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
            FirebaseController.savePinToFirebaseOfTravel(pin: pin, travel: currentTravel)
        }
                
        //save location to background data for route visualization
        let location = CLLocation.init(latitude: latitude, longitude: longitude)
        FirebaseController.handleBackgroundLocationData(location: location, isPin: true)
        
        returnToParentViewController()
        
    }
    
    @IBAction func addImages(_ sender: UIButton) {
        //open multi image picker
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 10
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func addVideo(_ sender: Any) {
        videoPicker.sourceType = .savedPhotosAlbum
        videoPicker.mediaTypes = ["public.movie"]
        videoPicker.allowsEditing = true
        videoPicker.videoQuality = .typeIFrame960x540
        present(videoPicker, animated: true, completion: nil)
    }
    
    @objc func activateDeleteOption(longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            if let indexPath = collectionView.indexPathForItem(at: longPress.location(in: collectionView)){
                let alert = UIAlertController(title: "Delete Photo", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.selectedPhotos.remove(at: indexPath.row)
                    self.collectionView.reloadData()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: ImagePicker
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else { return }
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]){
        imagePicker.dismiss(animated: true, completion: nil)
        for image in images {
            guard let jpgImage = compressImage(image: image) else {
                selectedPhotos.append(image)
                continue
            }
            selectedPhotos.append(UIImage(data: jpgImage)!)
        }
        collectionView.reloadData()
    }
    
    // MARK: Helper Functions
    
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

    
    
    func returnToParentViewController() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

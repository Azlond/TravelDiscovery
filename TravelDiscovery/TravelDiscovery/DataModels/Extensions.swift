//
//  Extensions.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 04.01.18.
//  Copyright © 2018 Jan. All rights reserved.
//

import Foundation
import UIKit
import NohanaImagePicker
import Photos


/*Adds a preference for adding a done button to the keyboard when using UITextView*/
extension UITextView {
    /*Expose preference to storyboard*/
    @IBInspectable var doneAccessory: Bool {
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    /*Add toolbar with done button*/
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    /*Done action*/
    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}

/*Adds a preference for adding a done button to the keyboard when using UITextView*/
extension UITextField {
    /*Expose preference to storyboard*/
    @IBInspectable var doneAccessory: Bool{
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    /*Add toolbar with done button*/
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    /*Done action*/
    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}

/**
 * Hide keyboard when tapping in the view besides the textfields
 */
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
            
            let image = getUIImageFromAsset(asset: asset)
            guard let jpgImage = compressImage(image: image) else {
                //if image compression fails use original image
                print("image compression failed")
                selectedPhotos.append(image)
                continue
            }
            selectedPhotos.append(UIImage(data: jpgImage)!)
        }
        collectionView.reloadData()
        
    }
}

extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont(name: "AvenirNext-Medium", size: 20)!]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let normal = NSAttributedString(string: text)
        append(normal)
        
        return self
    }
}
/*extension for downloading, caching and resizing images*/
extension UIImageView {
    func loadImageUsingCache(withUrl urlString : String) {
        let url = URL(string: urlString)
        
        // check cached image
        if let cachedImage = FirebaseData.imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = self.resizeImage(image: cachedImage)
            return
        }
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    FirebaseData.imageCache.setObject(image, forKey: urlString as NSString)
                    self.image = self.resizeImage(image: image)
                    //                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageLoaded"), object: nil)
                }
            }
            
        }).resume()
    }
    
    /**
     * resize downloaded image to fit into the UIImageView
     */
    func resizeImage(image: UIImage) -> UIImage? {
        let size = image.size
        
        //scale image to screenWidth
        let screenWidth = UIScreen.main.bounds.width
        let scaleFactor = screenWidth / size.width
        
        let targetSize = CGSize(width: screenWidth, height: size.height * scaleFactor)
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

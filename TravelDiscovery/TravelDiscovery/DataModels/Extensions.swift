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

/*Adds a preference for adding a done button to the keyboard when using UITextField*/
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


/* MARK: Extension ImagePickerController*/

extension PinViewController: NohanaImagePickerControllerDelegate {
    
    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset]) {
        picker.dismiss(animated: true, completion: nil)
        
        thumbnails = [UIImage]()
        selectedPhotos = [UIImage]()
        
        for asset in pickedAssts {
            thumbnails.append(getAssetThumbnail(asset: asset))
            
            let image = getUIImageFromAsset(asset: asset)
            guard let jpgImage = compressImage(image: image) else {
                /*if image compression fails use original image*/
                print("image compression failed")
                selectedPhotos.append(image)
                continue
            }
            selectedPhotos.append(UIImage(data: jpgImage)!)
        }
        collectionView.reloadData()
        
    }
}
/**
 * Extensions to easily bold a string
 */
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
    func loadImageUsingCache(withUrl urlString : String, tableview: UITableView?, indexPath: IndexPath?) {
        let url = URL(string: urlString)
        
        /*reset image*/
        self.image = nil
        self.setRandomBackgroundColor()
        
        /*check cached image*/
        if let cachedImage = FirebaseData.imageCache.object(forKey: url!.lastPathComponent as NSString) as? UIImage {
            if let visibleCellIndices = tableview?.indexPathsForVisibleRows {
                if (!visibleCellIndices.contains(indexPath!)) {
                    return
                }
            }
            self.image = cachedImage
            return
        }
        
        /* if it is not in cache, download image from url*/
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    FirebaseData.imageCache.setObject(image, forKey: url!.lastPathComponent as NSString)
                    if let visibleCellIndices = tableview?.indexPathsForVisibleRows {
                        if (!visibleCellIndices.contains(indexPath!)) {
                            return
                        }
                    }
                    self.image = image
                }
            }
            
        }).resume()
    }

    /**
     * resize downloaded image to fit into the UIImageView
     */
    func resizeImage(image: UIImage) -> UIImage? {
        let size = image.size
        
        /*scale image to screenWidth*/
        let screenWidth = UIScreen.main.bounds.width
        let scaleFactor = screenWidth / size.width
        
        let targetSize = CGSize(width: screenWidth, height: size.height * scaleFactor)
        
        /* This is the rect that we've calculated out and this is what is actually used below*/
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        
        /* Actually do the resizing to the rect using the ImageContext stuff*/
        UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.main.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
     * returns image with reduced saturation
     */
    func reduceSaturation(){
        if self.image != nil {
            let context = CIContext(options: nil)
            
            let filter = CIFilter(name: "CIPhotoEffectFade")
            filter!.setValue(CIImage(image: self.image!), forKey: kCIInputImageKey)
            let output = filter!.outputImage
            let cgimg = context.createCGImage(output!,from: output!.extent)
            self.image = UIImage(cgImage: cgimg!)
        }
        
    }
    /**
     * Set background to random color
     */
    func setRandomBackgroundColor(){
        var red: CGFloat = CGFloat(arc4random() % 256 ) / 256
        var green: CGFloat = CGFloat(arc4random() % 256 ) / 256
        var blue: CGFloat = CGFloat(arc4random() % 256 ) / 256
        
        let mixRed: CGFloat = 1+0xad/256, mixGreen: CGFloat = 1+0xd8/256, mixBlue: CGFloat = 1+0xe6/256;
        red = (red + mixRed) / 3;
        green = (green + mixGreen) / 3;
        blue = (blue + mixBlue) / 3;
        
        
        self.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        
    }
}
/**
 * Extension used to find out which device the user is using
 */
extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                    return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                              return "Apple TV"
        case "AppleTV6,2":                              return "Apple TV 4K"
        case "AudioAccessory1,1":                       return "HomePod"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}

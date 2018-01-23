//
//  PinDetailViewController.swift
//  TravelDiscovery
//
//  Created by admin on 03.01.18.
//  Copyright © 2018 Jan. All rights reserved.
//
import UIKit
import AVKit
import AVFoundation
import CoreLocation
import SwiftLocation
import SwiftPhotoGallery

class PinDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, SwiftPhotoGalleryDelegate, SwiftPhotoGalleryDataSource {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var primaryImageView: UIImageView!
    @IBOutlet weak var pinNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imagesCV: UICollectionView!
    @IBOutlet weak var videoDisplay: UIImageView!
    
    @IBOutlet weak var imagesCVHeight: NSLayoutConstraint!
    @IBOutlet weak var primaryImageHeight: NSLayoutConstraint!
    @IBOutlet weak var videoDisplayHeight: NSLayoutConstraint!
    
    override var prefersStatusBarHidden: Bool {
        if showStatusBar {
            return false
        }
        return true
    }
    
    var showStatusBar = true
    var isFeedPin = false
    var pin: Pin!
    var images = [UIImage]()
    
    let playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named:"play-button"), for: .normal)
        button.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        return button
    }()
    
    let spinner: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //set location as title
        setTitleFromLocationOfPin(pin: pin)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //remove back button title
        if let nav = self.navigationController, let item = nav.navigationBar.topItem {
            item.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action:nil)
        }
        
        usernameLabel.text = "by " + pin.username
        dateLabel.text = "- " + pin.date
        pinNameLabel.text = pin.name
        
        textView.text = ""
        if let text = pin.text {
            textView.text = text
        }
        
        // set images
        primaryImageView.image = primaryImageView.resizeImage(image: UIImage(named: "default2")!)
        if ((pin.imageURLs?.count ?? 0) > 0) {
            primaryImageView.loadImageUsingCache(withUrl: pin.imageURLs![0], tableview: nil, indexPath: nil)
            primaryImageView.reduceSaturation()
            
            loadImages(urlStrings: pin.imageURLs!)
        } else {
            imagesCVHeight.constant = 0
        }
        // if no images were uploaded, but a video was -> use video thumbnail for preview
        if pin.imageURLs?.count == 0 && pin.videoThumbnailURL != nil {
            primaryImageView.loadImageUsingCache(withUrl: pin.videoThumbnailURL!, tableview: nil, indexPath: nil)
            primaryImageView.reduceSaturation()
        }
        
        // set video
        if pin.videoDownloadURL != nil {
            setupVideoDisplay()
        } else {
            videoDisplayHeight.constant = 0
        }
                
        imagesCV.dataSource = self
        imagesCV.delegate = self
        imagesCV.reloadData()
        
        //navigationBar design
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setTitleFromLocationOfPin(pin: Pin) {
        let geoCoder = CLGeocoder()
        let location: CLLocation = CLLocation.init(latitude: pin.latitude, longitude: pin.longitude)
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if let placemark = placemarks?[0]  {
                // get city name from placemark and set title
                if let city = placemark.locality {
                    //let region = placemark.administrativeArea //Staat
                    if self.isFeedPin && placemark.subLocality != nil {
                        self.title = placemark.subLocality // Stadtviertel
                    } else {
                        self.title = city
                    }
                }
            }
        })
    }
    
    // MARK: Image Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (pin.imageURLs?.count ?? 0) > 0 {
            return pin.imageURLs!.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (pin.imageURLs?.count ?? 0) > 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detailCell", for: indexPath as IndexPath)
            let cellSize = getCellSize(itemCount: pin.imageURLs!.count)
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cellSize.width, height: cellSize.height))
            imageView.loadImageUsingCache(withUrl: pin.imageURLs![indexPath.row], tableview: nil, indexPath: nil)
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            
            cell.contentView.addSubview(imageView)
            return cell
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: "detailCell", for: indexPath as IndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openGallery(index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (pin.imageURLs?.count ?? 0) > 0 {
            return getCellSize(itemCount: pin.imageURLs!.count)
        }
        return CGSize(width:0, height:0)
    }
    
    
    private func getCellSize(itemCount: Int) -> CGSize {
        var cellRowNumber: CGFloat = 0
        if itemCount == 1 {
            cellRowNumber = 1
        }
        else if itemCount % 2 == 0 {
            cellRowNumber = 2
        }
        else if itemCount % 3 == 0 {
            cellRowNumber = 3
        }
        else {
            cellRowNumber = CGFloat((itemCount % 3) + 1)
        }
        //subtract the 5 pixels that are between the items
        let cellSize = (UIScreen.main.bounds.size.width - (5*(cellRowNumber-1))) / cellRowNumber
        
        //adjust height of collectionview
        let cellColumnNumber = CGFloat(itemCount)/cellRowNumber
        self.imagesCVHeight.constant = cellSize * ceil(cellColumnNumber) + (5*(cellColumnNumber-1))
        
        return CGSize(width: cellSize, height: cellSize)
        
    }
    
    // MARK: SwiftPhotoGallery
    
    func openGallery(index: Int) {
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackground = UIView(frame: keyWindow.frame)
            blackBackground!.backgroundColor = UIColor.black
            blackBackground!.alpha = 0
            keyWindow.addSubview(blackBackground!)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.blackBackground!.alpha = 1
            }, completion: {(completed) in
                //open gallery
                let gallery = SwiftPhotoGallery(delegate: self, dataSource: self)
                self.present(gallery, animated: false, completion: {
                    gallery.currentPage = index
                    self.blackBackground?.alpha = 0
                    
                })
            })
        }
    }
    
    
    func numberOfImagesInGallery(gallery: SwiftPhotoGallery) -> Int {
        return images.count
    }
    
    func imageInGallery(gallery: SwiftPhotoGallery, forIndex: Int) -> UIImage? {
        return images[forIndex]
    }
    
    func galleryDidTapToClose(gallery: SwiftPhotoGallery) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Image Click Animation
    
    var startFrame: CGRect?
    var blackBackground: UIView?
    
    @objc func zoomIn(tapGesture: UITapGestureRecognizer){
        if let imageView = tapGesture.view as? UIImageView {
            startFrame = imageView.superview?.convert(imageView.frame, to: nil)
            
            let zoomInView = UIImageView(frame: startFrame!)
            zoomInView.image = imageView.image
            zoomInView.contentMode = .scaleAspectFill
            
            if let keyWindow = UIApplication.shared.keyWindow {
                guard let img = imageView.image else {
                    return
                }
                
                blackBackground = UIView(frame: keyWindow.frame)
                blackBackground!.backgroundColor = UIColor.black
                blackBackground!.alpha = 0
                
                keyWindow.addSubview(blackBackground!)
                keyWindow.addSubview(zoomInView)
                
                //animate image to fill the screen with black background
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                    self.blackBackground!.alpha = 1
                    let height = img.size.height / img.size.width * keyWindow.frame.width
                    zoomInView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                    zoomInView.center = keyWindow.center
                }, completion: {(completed) in
                    zoomInView.removeFromSuperview()
                    
                })
            }
            
        }
    }
    
    
    private func setupVideoDisplay() {
        //set first video frame as image
        if pin.videoThumbnailURL != nil {
            self.videoDisplay.loadImageUsingCache(withUrl: pin.videoThumbnailURL!, tableview: nil, indexPath: nil)
        }
        
        //add play button
        self.videoDisplay.addSubview(playButton)
        
        //center play button in parent view
        playButton.centerXAnchor.constraint(lessThanOrEqualTo: self.videoDisplay.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(lessThanOrEqualTo: self.videoDisplay.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //add spinner
        self.videoDisplay.addSubview(spinner)
        
        //center in parent view
        spinner.centerXAnchor.constraint(lessThanOrEqualTo: self.videoDisplay.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(lessThanOrEqualTo: self.videoDisplay.centerYAnchor).isActive = true
        spinner.widthAnchor.constraint(equalToConstant: 50).isActive = true
        spinner.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        self.videoDisplay.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(playVideo)))
       
    }
    
    @objc func playVideo() {
        spinner.startAnimating()
        playButton.isHidden = true
        
        let player = AVPlayer(url: URL(string: pin.videoDownloadURL!)!)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        self.present(playerVC, animated: true) {
            playerVC.player!.play()
            
            self.playButton.isHidden = false
            self.spinner.stopAnimating()
        }
    }
    
    func loadImages(urlStrings: [String]) {
        for urlString in urlStrings {
            let url = URL(string: urlString)
            
            /*check cached image*/
            if let cachedImage = FirebaseData.imageCache.object(forKey: url!.lastPathComponent as NSString) as? UIImage {
                self.images.append(cachedImage)
                continue
            }
            
            /* if it is not in cache, download image from url*/
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                DispatchQueue.main.async {
                    if let image = UIImage(data: data!) {
                        FirebaseController.saveImageToDocuments(withUrl: url!, pinImage: image)
                        FirebaseData.imageCache.setObject(image, forKey: url!.lastPathComponent as NSString)
                        self.images.append(image)
                    }
                }
            }).resume()
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

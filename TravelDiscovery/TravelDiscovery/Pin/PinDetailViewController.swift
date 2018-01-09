//
//  PinDetailViewController.swift
//  TravelDiscovery
//
//  Created by admin on 03.01.18.
//  Copyright © 2018 Jan. All rights reserved.
//

import UIKit
import AVKit

class PinDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var primaryImageView: UIImageView!
    @IBOutlet weak var pinNameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imagesCV: UICollectionView!
    @IBOutlet weak var videoDisplay: UIImageView!
    
    @IBOutlet weak var imagesCVHeight: NSLayoutConstraint!
    @IBOutlet weak var primaryImageHeight: NSLayoutConstraint!
    @IBOutlet weak var videoDisplayHeight: NSLayoutConstraint!
    
    var pin: Pin!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = pin.date
        usernameLabel.text = "by " + pin.username
        pinNameLabel.text = pin.name
        
        textView.text = ""
        if let text = pin.text {
            textView.text = text
        }
        
        // set images
        primaryImageView.image = primaryImageView.resizeImage(image: UIImage(named: "default2")!)
        if ((pin.imageURLs?.count ?? 0) > 0) {
            primaryImageView.loadImageUsingCache(withUrl: pin.imageURLs![0])
            primaryImageView.reduceSaturation()
        } else {
            imagesCVHeight.constant = 0
        }
        
        // set video
        if pin.videoDownloadURL != nil {
            setupVideoDisplay()
        } else {
            videoDisplayHeight.constant = 0
        }
        
        //TODO? add map including pin location marker
        
        imagesCV.dataSource = self
        imagesCV.delegate = self
        imagesCV.reloadData()
        
        scrollView.delegate = self
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yPos: CGFloat = -scrollView.contentOffset.y
        
//        if (yPos > 0) {
//            var imgRect: CGRect = self.imageView.frame
//            imgRect.origin.y = scrollView.contentOffset.y
//            imgRect.size.height = kHeaderHeight+yPos
//            self.imageView.frame = imgRect
//        }
        
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
            imageView.loadImageUsingCache(withUrl: pin.imageURLs![indexPath.row])
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(zoomIn)))
            
            cell.contentView.addSubview(imageView)
            return cell
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: "detailCell", for: indexPath as IndexPath)
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
    
    // MARK: Image Click Animation
    
    var startFrame: CGRect?
    var blackBackground: UIView?
    
    @objc func zoomIn(tapGesture: UITapGestureRecognizer){
        if let imageView = tapGesture.view as? UIImageView {
            startFrame = imageView.superview?.convert(imageView.frame, to: nil)
            
            let zoomInView = UIImageView(frame: startFrame!)
            zoomInView.image = imageView.image
            zoomInView.contentMode = .scaleAspectFill
            zoomInView.isUserInteractionEnabled = true
            zoomInView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomOut)))
            
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
                })
            }
            
        }
    }
    
    //zoom image back to previous location
    @objc func zoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutView = tapGesture.view as? UIImageView {
            zoomOutView.clipsToBounds = true
            zoomOutView.contentMode = .scaleAspectFill
            
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.blackBackground?.alpha = 0
                zoomOutView.frame = self.startFrame!
            }, completion: {(completed) in
                zoomOutView.removeFromSuperview()
            })
        }
    }
    
    
    private func setupVideoDisplay() {
        //set first video frame as image
        if pin.videoThumbnailURL != nil {
            self.videoDisplay.loadImageUsingCache(withUrl: pin.videoThumbnailURL!)
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
        
    }
    
    @objc func playVideo() {
        let player = AVPlayer(url: URL(string: pin.videoDownloadURL!)!)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoDisplay.bounds //CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)//
        playerLayer.videoGravity = .resizeAspectFill
        self.videoDisplay.layer.addSublayer(playerLayer)
        self.videoDisplayHeight.constant = playerLayer.frame.height
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        
        player.play()
        spinner.startAnimating()
        playButton.isHidden = true
    }
    
    @objc func playerDidFinishPlaying(sender: Notification){
        for var subview in videoDisplay.subviews {
            subview.removeFromSuperview()
        }
        playButton.isHidden = false
        spinner.stopAnimating()
        setupVideoDisplay()
        
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

//
//  CreditsViewController.swift
//  TravelDiscovery
//
//  Created by Jan Kaiser on 05.01.18.
//  Copyright © 2018 Jan. All rights reserved.
//

import UIKit
//TODO: update credit links
//TODO: scale content to full screen size
class CreditsViewController: UIViewController {

    @IBOutlet weak var creditsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Credits";
        
        let titleAttribute = [NSAttributedStringKey.font:  UIFont(name: "Helvetica-Bold", size: 30.0)!]
        let creditsString = NSMutableAttributedString()

        /*Developers*/
        let devTitleString = NSMutableAttributedString(string: "Developers:\n", attributes: titleAttribute)
        let dev1 = "Jan Kaiser (http://www.sintho.com)"
        let dev2 = "Laura Mühlbach"
        let dev3 = "Hyerim Park"
        
        let devBullets = createBullets(bullets: [dev1, dev2, dev3])
        creditsString.append(devTitleString)
        creditsString.append(devBullets)

        /*Libraries*/
        let librariesTitleString = NSMutableAttributedString(string: "\nLibraries:\n", attributes: titleAttribute)
        let lib1 = "Firebase (https://firebase.google.com)"
        let lib2 = "Mapbox (https://www.mapbox.com)"
        let lib3 = "ScratchCard (https://github.com/joehour/ScratchCard)"
        let lib4 = "Eureka (https://github.com/xmartlabs/Eureka)"
        let lib5 = "SwiftLocation (https://github.com/malcommac/SwiftLocation)"
        let lib6 = "NohanaImagePicker (https://github.com/nohana/NohanaImagePicker)"
        let lib7 = "GSMessagesn (https://github.com/wxxsw/GSMessages)"
        
        let libraryBullets = createBullets(bullets: [lib1, lib2, lib3, lib4, lib5, lib6, lib7])
        creditsString.append(librariesTitleString)
        creditsString.append(libraryBullets)

        /*Images*/
        let imagesTitleString = NSMutableAttributedString(string: "\nImages:\n", attributes: titleAttribute)
        let img1 = "Map icon (https://icons8.com/icon/345)"
        let img2 = "Travel icon (https://icons8.com/icon/2487)"
        let img3 = "Feed icon (https://icons8.com/icon/12555)"
        let img4 = "Settings icon (https://icons8.com/icon/364)"
        let img5 = "Login image (https://pixabay.com/de/berge-wandern-ruhm-abenteuer-1264538/)"
        let img6 = "Pin default image (https://www.pexels.com/photo/ball-shaped-blur-close-up-focus-346885)"
        let img7 = "Country shapes (https://www.amcharts.com/svg-maps)"
        
        let imageBullets = createBullets(bullets: [img1, img2, img3, img4, img5, img6, img7])
        creditsString.append(imagesTitleString)
        creditsString.append(imageBullets)

        /*Misc*/
        let miscTitleString = NSMutableAttributedString(string: "\nMiscellaneous:\n", attributes: titleAttribute)
        let misc1 = "World geoJSON (https://github.com/johan/world.geo.json)"
        
        let miscBullets = createBullets(bullets: [misc1])
        creditsString.append(miscTitleString)
        creditsString.append(miscBullets)
        
        
        creditsTextView.attributedText = creditsString
        // Do any additional setup after loading the view.
    }

    private func createBullets(bullets: [String]) -> NSMutableAttributedString {
        let bulletPoint: String = "\u{2022}"
        let paragraphStyle = createParagraphAttribute()
        let string = NSMutableAttributedString(string: "")
        for bullet: String in bullets {
            let formattedString: String = "\(bulletPoint) \(bullet)\n"
            let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: formattedString)
            
            attributedString.addAttributes([NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.font:  UIFont(name: "Helvetica", size: 16.0)!], range: NSMakeRange(0, bullet.count + 2))
            
            string.append(attributedString)
        }
        return string
    }
    
    private func createParagraphAttribute() ->NSParagraphStyle {
        var paragraphStyle: NSMutableParagraphStyle
        paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 15, options: NSDictionary() as! [NSTextTab.OptionKey : Any])]
        paragraphStyle.defaultTabInterval = 15
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 15
        
        return paragraphStyle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

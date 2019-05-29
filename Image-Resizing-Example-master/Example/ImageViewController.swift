//
//  ImageViewController.swift
//  Image Resizing
//
//  Created by kuroky on 2019/5/29.
//  Copyright © 2019 NSHipster. All rights reserved.
//

import UIKit

enum ResizeType: Int {
    case ResizeWithCoreGraphics              =           1
    case ResizeWithCoreImage                 =           2
    case ResizeWithImageIO                   =           3
    case ResizeWithImageIO1                  =           6
    case ResizeWithUIKit                     =           4
    case ResizeWithvImage                    =           5
}


class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var resizeButton: UIButton!
    @IBOutlet weak var testButton: UIButton!
    
    var imgUrl: URL!
    var resizeType: Int?
    var size: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Image"
        
        self.resizeButton.setTitle("Resize", for: .normal)
        self.resizeButton.setTitle("Resizing", for: .selected)
        
        self.activityView.isHidden = true
        self.imgUrl = Bundle.main.url(forResource: "VIIRS_3Feb2012_lrg", withExtension: "jpg")
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scale = UIScreen.main.scale;
        let transform = CGAffineTransform.init(scaleX: scale, y: scale)
        self.size = self.imageView.bounds.size.applying(transform)
    }
    
    
    @IBAction func clickResize(_ sender: UIButton) {
        sender.isSelected = true
        sender.isUserInteractionEnabled = false
        self.imageView.image = nil
        self.activityView.isHidden = false
        self.activityView.startAnimating()
        
        DispatchQueue.global().async {
            let start = CACurrentMediaTime()
            let image = self.resizeImage()
            
            DispatchQueue.main.async {
                let duration = 1.0;
                UIView.transition(with: self.imageView,
                                  duration: duration,
                                  options: .curveEaseOut,
                                  animations: {
                                    self.imageView.image = image
                }, completion: { _ in
                    self.activityView.stopAnimating()
                    self.activityView.isHidden = true
                    sender.isSelected = false
                    sender.isUserInteractionEnabled = true
                    let end = CACurrentMediaTime()
                    print("%@ time: %.2fs", self.resizeMethod() as String, end - start - duration);
                })
            }
        }
    }
    
    @IBAction func clickTest(_ sender: UIButton) {
    
    }
        
    func resizeImage() -> UIImage? {
        if (self.resizeType == ResizeType.ResizeWithCoreGraphics.rawValue) {
            return CoreGraphics.resizedImage(at: self.imgUrl, for: self.size)
        }
        else if (self.resizeType == ResizeType.ResizeWithCoreImage.rawValue) {
            return CoreImage.resizedImage(at: self.imgUrl, for: self.size)
        }
        else if (self.resizeType == ResizeType.ResizeWithUIKit.rawValue) {
            return UIKit.resizedImage(at: self.imgUrl, for: self.size)
        }
        else if (self.resizeType == ResizeType.ResizeWithImageIO.rawValue) {
            return ImageIO.resizedImage(at: self.imgUrl, for: self.size)
        }
        else if (self.resizeType == ResizeType.ResizeWithImageIO1.rawValue) {
            return ImageIO.resizedImageWithHintingAndSubsampling(at: self.imgUrl, for: self.size)
        }
        else if (self.resizeType == ResizeType.ResizeWithvImage.rawValue) {
            return vImage.resizedImage(at: self.imgUrl, for: self.size)
        }
        return nil;
    }

    func resizeMethod() -> String! {
        if (self.resizeType == ResizeType.ResizeWithCoreGraphics.rawValue) {
            return "Core Graphics";
        }
        else if (self.resizeType == ResizeType.ResizeWithCoreImage.rawValue) {
            return "CoreImage";
        }
        else if (self.resizeType == ResizeType.ResizeWithImageIO.rawValue) {
            return "ImageIO";
        }
        else if (self.resizeType == ResizeType.ResizeWithImageIO1.rawValue) {
            return "ImageIO1";
        }
        else if (self.resizeType == ResizeType.ResizeWithUIKit.rawValue) {
            return "UIKit";
        }
        else if (self.resizeType == ResizeType.ResizeWithvImage.rawValue) {
            return "vImage";
        }
        return nil;
    }
}

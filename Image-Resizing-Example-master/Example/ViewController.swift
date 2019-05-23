import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let url = Bundle.main.url(forResource: "VIIRS_3Feb2012_lrg",
                                        withExtension: "jpg")
        else {
            fatalError("Missing image resource")
        }
        
        let scaleFactor = UIScreen.main.scale
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let size = self.imageView.bounds.size.applying(scale)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let start = CACurrentMediaTime()
            
            // Test on iPhone7
            // UIImage 不缩放
//            let image = UIImage(contentsOfFile: url.path) // 220 0.22 内存暴涨
            
            // 1. CoreGraphics
//            let image = CoreGraphics.resizedImage(at: url, for: size) // 14M 0.18
            
            // 2. CoreImage
//            let image = CoreImage.resizedImage(at: url, for: size) // 400 -> 16.8M 2.9

            // 3. ImageIO
//            let image = ImageIO.resizedImage(at: url, for: size) // 14M 0.16
//            let image = ImageIO.resizedImageWithHintingAndSubsampling(at: url, for: size) // 14M 0.17
            
            // 4. UIKit
//            let image = UIKit.resizedImage(at: url, for: size) // 31 -> 14M 0.35
            
            // 5.
            let image = vImage.resizedImage(at: url, for: size) //  917 -> 18.7M 2.9
            DispatchQueue.main.sync {
                let duration = 1.0
                UIView.transition(with: self.imageView, duration: duration, options: [.curveEaseOut, .transitionCrossDissolve], animations: {
                    self.imageView.image = image
                }, completion: { _ in
                    let end = CACurrentMediaTime()
                    print(end - start - duration)
                })
            }
        }
    }
}


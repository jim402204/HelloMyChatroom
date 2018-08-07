

import UIKit

extension UIImage {
    
    func resize(maxWidthHeight: CGFloat) -> UIImage? {
        // Check if current image is already smaller than maxWidthHeight?
        if self.size.width <= maxWidthHeight && self.size.height <= maxWidthHeight{
           return self
        }
        
        // Decide final size
        let finalSize : CGSize      //保留長的邊 縮小端的邊
        if self.size.width >= self.size.height { //Width >= Height
            let ratio = self.size.width / maxWidthHeight
            finalSize = CGSize(width: maxWidthHeight, height: self.size.height / ratio)
        }else{  //Height >= Width
            let ratio = self.size.height / maxWidthHeight
            finalSize = CGSize(width: self.size.width / ratio, height: maxWidthHeight)
        }
        
        // Generate a new image.
        UIGraphicsBeginImageContext(finalSize)  //c語言的api 記憶管理要很小心 ARC管理不會起作用
        //創造畫布
        let drawRect = CGRect(x: 0, y: 0, width: finalSize.width, height: finalSize.height)
        self.draw(in: drawRect) //把自己畫在較小的框框
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext() // very Important       釋放記憶體
        
    
        return result
    }
    
    
    
    
}

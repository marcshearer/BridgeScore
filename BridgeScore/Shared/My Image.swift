//
//  My Image.swift
// Bridge Score
//
//  Created by Marc Shearer on 26/02/2021.
//

import SwiftUI

#if canImport(UIKit)

class MyImage : UIImage {
    
    convenience init?(image: Any?) {
        if let image = image as? UIImage, let cgImage = image.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init(cgImage: UIImage().cgImage!)
        }
    }
    
}

#else

class MyImage : NSImage {
    
    convenience init?(image: Any?) {
        if let image = image as? NSImage, let cgImage = image.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init(cgImage: UIImage().cgImage!)
        }
    }
        
    func pngData() -> Data? {
        return { self.tiffRepresentation?.bitmap?.png }()
    }
}

#endif

#if canImport(UIKit)
#else
extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
#endif

extension Image {
    #if canImport(UIKit)
    init(myImage: MyImage) {
        self.init(uiImage: myImage)
    }
    #else
    init(myImage: MyImage) {
        self.init(nsImage: myImage)
    }
    #endif
}

//
//  Image Capture.swift
// Bridge Score
//
//  Created by Marc Shearer on 11/02/2021.
//

import SwiftUI
import UIKit

struct ImageCapture: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var isPresented

    @Binding var image: Data?
    var source: UIImagePickerController.SourceType

    static var isCameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    static var isPhotoLibraryAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = self.source
        imagePickerController.delegate = context.coordinator
        return imagePickerController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }

    func makeCoordinator() -> ImageCaptureCoordinator {
        return ImageCaptureCoordinator(source: self)
    }
    
    fileprivate func dismiss() {
        self.isPresented.wrappedValue.dismiss()
    }
}

class ImageCaptureCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var source: ImageCapture
    
    init(source: ImageCapture) {
        self.source = source
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = MyImage(image: info[.originalImage]) {
            let rotatedImage = self.rotateImage(image: image)
            self.source.image = rotatedImage.pngData()
            self.source.dismiss()
        }
    }

    func rotateImage(image: MyImage) -> MyImage {
        if (image.imageOrientation == MyImage.Orientation.up ) {
            return image
        }
        
        UIGraphicsBeginImageContext(image.size)
        
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return copy as! MyImage
    }
}

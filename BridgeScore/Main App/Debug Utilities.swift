//
//  File.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 09/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

extension View {
    
    func debugAction(_ action: () -> Void) -> Self {
         action()
    
        return self
    }
    
    func debugPrint(_ value: Any) -> Self {
        debugAction { print(value) }
    }
    
    func reportGlobalFocus(windowScene: UIWindowScene?) {
        Utility.executeAfter(delay: 1) {
            if let windowScene = windowScene, let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                
                if let responder = window.findFirstResponder {
                        // This will print the internal UIKit class name (e.g., _UITextFieldCanvasView)
                    print("Focus is at First Responder: \(type(of: responder))")
                    
                    if let responderView = responder as? UIView {
                        let label = (responder as NSObject).accessibilityLabel ?? "No Label"
                        let identifier = responderView.accessibilityIdentifier ?? "No ID"
                        
                        print("Focus is at: \(type(of: responder))")
                        print("Accessibility Label: \(label)")
                        print("Accessibility ID: \(identifier)")
                    }
                } else {
                    print("No First Responder - Focus is truly lost/dismissed.")
                }
            }
        }
    }
}

struct WindowSceneReader: UIViewRepresentable {
    // A closure to send the scene back to your SwiftUI view
    var onSceneFound: (UIWindowScene) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // We use dispatch async to ensure the view is fully attached to the window
        DispatchQueue.main.async {
            if let scene = uiView.window?.windowScene {
                context.coordinator.onSceneFound(scene)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSceneFound: onSceneFound)
    }
    
    class Coordinator {
        let onSceneFound: (UIWindowScene) -> Void
        init(onSceneFound: @escaping (UIWindowScene) -> Void) {
            self.onSceneFound = onSceneFound
        }
    }
}

extension UIView {
    var findFirstResponder: UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let responder = subview.findFirstResponder {
                return responder
            }
        }
        return nil
    }
}

//
//  Drop Zone.swift
//  BridgeScore
//
//  Created by Marc Shearer on 31/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDropZone: UIViewRepresentable {
    @Binding var isHovering: Bool
    var processResults: ([(filename: String, contents: String)])->()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        view.isUserInteractionEnabled = true
        
        let dropInteraction = UIDropInteraction(delegate: context.coordinator)
        view.addInteraction(dropInteraction)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIDropInteractionDelegate {
        var parent: FileDropZone
        
        init(parent: FileDropZone) {
            self.parent = parent
        }
        
        // Force the pipeline to say "yes" instantly on hover
        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            return true
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isHovering = true
            }
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            return UIDropProposal(operation: .copy)
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isHovering = false
            }
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isHovering = false
            }
            
            let group = DispatchGroup()
            var results: [(filename: String, contents: String)] = []
            
            for item in session.items {
                let provider = item.itemProvider
                
                if provider.hasItemConformingToTypeIdentifier("public.item") {
                    group.enter()
                    
                    provider.loadInPlaceFileRepresentation(forTypeIdentifier: "public.item") { url, isInPlace, error in
                        defer { group.leave() }
                        
                        if let url = url {
                            let coordinator = NSFileCoordinator()
                            var coordinatorError: NSError?
                            
                            coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinatorError) { coordinatedURL in
                                if let contents = try? String(contentsOf: coordinatedURL, encoding: .utf8) {
                                    results.append((filename: url.lastPathComponent, contents: contents))
                                }
                            }
                        }
                    }
                }
            }
            
            // 4. Return the entire collection batch safely to your main thread
            group.notify(queue: .main) {
                if !results.isEmpty {
                    self.parent.processResults(results)
                }
            }
        }
    }
}

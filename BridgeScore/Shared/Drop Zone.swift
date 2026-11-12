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
    var allowedTypes: [UTType]
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
        Coordinator(parent: self, allowedTypes: allowedTypes)
    }
    
    class Coordinator: NSObject, UIDropInteractionDelegate {
        var parent: FileDropZone
        let allowedTypes: [UTType]
        
        init(parent: FileDropZone, allowedTypes: [UTType]) {
            self.parent = parent
            self.allowedTypes = allowedTypes
        }
        
        private func isAllowed(_ provider: NSItemProvider) -> Bool {
            provider.registeredTypeIdentifiers.contains { id in
                if let type = UTType(id) {
                    return allowedTypes.contains { type.conforms(to: $0) }
                } else {
                    return false
                }
            }
        }
        
        // Force the pipeline to say "yes" instantly on hover
        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            !session.items.isEmpty && session.items.allSatisfy { isAllowed($0.itemProvider) }
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isHovering = true
            }
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            return UIDropProposal(operation: .copy)
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
            DispatchQueue.main.async {
                self.parent.isHovering = false
            }
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
                
                print("types: ",provider.registeredTypeIdentifiers, "name: ", provider.suggestedName ?? "-")
                if let type = provider.registeredTypeIdentifiers.first {
                    group.enter()
                    let start = Date()
                    print("load start:", provider.registeredTypeIdentifiers)
                    provider.loadInPlaceFileRepresentation(forTypeIdentifier: type) { item, _, error in
                        defer { group.leave() }
                        if let url = item, let contents = try? String(contentsOf: url, encoding: .utf8) {
                            print("load done after", Date().timeIntervalSince(start), "url:", url as Any, "error:", error as Any)
                            let filename = url.lastPathComponent
                            results.append((filename: filename, contents: contents))
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                if !results.isEmpty {
                    self.parent.processResults(results)
                }
            }
        }
    }
}

extension UTType {
    static let pbn = UTType(importedAs: "com.sheareronline.pbn")
}

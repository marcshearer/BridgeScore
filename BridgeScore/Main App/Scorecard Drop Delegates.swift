//
//  Scorecard Drop Delegate.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/11/2023.
//

import SwiftUI
import AudioToolbox
import UniformTypeIdentifiers

struct ScorecardDropFiles : DropDelegate {
    @Binding var dropZoneEntered: Bool
    @Binding var droppedFiles: [(filename: String, contents: String)]
    @State var type: UTType = UTType.data
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        dropZoneEntered = true
    }
    
    func dropExited(info: DropInfo) {
        dropZoneEntered = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        var newFiles: [(filename: String, contents: String)] = []
        let items = info.itemProviders(for: [type])
        for (index, item) in items.enumerated() {
            if let filename = item.suggestedName {
                item.loadItem(forTypeIdentifier: type.identifier) { (url, error) in
                    if let url = url as? URL {
                        if let data = try? Data(contentsOf: url), let contents = String(data: data, encoding: .utf8) {
                            newFiles.append((filename, contents))
                        }
                    }
                    if index >= items.count - 1 {
                        droppedFiles.append(contentsOf: newFiles)
                        newFiles = []
                    }
                }
            }
        }
        dropZoneEntered = false
        AudioServicesPlaySystemSound(SystemSoundID(1304))
        return true
    }
}

struct ScorecardDropText : DropDelegate {
    @Binding var dropZoneEntered: Bool
    @Binding var droppedText: [String]
    @State var type: UTType = UTType.text
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        dropZoneEntered = true
    }
    
    func dropExited(info: DropInfo) {
        dropZoneEntered = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        var newText: [String] = []
        let items = info.itemProviders(for: [type])
        for (index, item) in items.enumerated() {
            item.loadItem(forTypeIdentifier: type.identifier) { (data, error) in
                if let data = data as? Data, let text = String(data: data, encoding: .utf8) {
                    newText.append(text)
                }
                if index >= items.count - 1 {
                    droppedText.append(contentsOf: newText)
                    newText = []
                }
            }
        }
        dropZoneEntered = false
        AudioServicesPlaySystemSound(SystemSoundID(1304))
        return true
    }
}

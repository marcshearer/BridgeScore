//
//  Insights Storage View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 10/05/2026.
//

import SwiftUI

struct InsightsReportViewStorage : View {
    @ObservedObject var report: Report
    @State var showLoadDialog: Bool = false
    @State var showSaveDialog: Bool = false
    
    var body: some View {
        HStack {
            Spacer().frame(width: 100)
            VStack {
                Spacer().frame(height: 100)
                InsightsSetupButton(text: "Save View") {
                    showSaveDialog = true
                }
                Spacer().frame(height: 40)
                InsightsSetupButton(text: "Load View") {
                    showLoadDialog = true
                }
                Spacer()
            }
            Spacer()
        }
        .sheet(isPresented: $showLoadDialog) {
            InsightsReportViewStorageLoadDialog(report: report)
        }
        .sheet(isPresented: $showSaveDialog) {
            InsightsReportViewStorageSaveDialog(report: report)
        }
    }
    
    static public var storageUrl: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("InsightReport", isDirectory: true)
        
        // Create the folder if it doesn't exist
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    
    static public func url(for filename: String) -> URL {
        storageUrl.appendingPathComponent(filename).appendingPathExtension("json")
    }
    
    static func save(report: Report, to fileUrl: URL) {
        do {
            let data = try JSONEncoder().encode(report.values)
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    static func load(report: Report, from fileUrl: URL) {
        do {
            let values = try JSONDecoder().decode(ReportValues.self, from: Data(contentsOf: fileUrl))
            report.update(from: values)
        } catch {
            print("Load failed: \(error)")
        }
    }
    
    static func loadFileList() -> [URL] {
        if let contents = try? FileManager.default.contentsOfDirectory(at: InsightsReportViewStorage.storageUrl, includingPropertiesForKeys: nil) {
            return contents.filter { $0.pathExtension == "json" }
        } else {
            return []
        }
    }
}

struct InsightsReportViewStorageLoadDialog: View {
    @ObservedObject var report: Report
    
    @Environment(\.dismiss) var dismiss
    @State private var files: [URL] = []
    @State var loadUrl: URL?
    
    var body: some View {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
       
        Banner(title: Binding.constant("Load View"), alternateStyle: true, back: false, leftTitle: false)
        VStack {
            Spacer().frame(height: 20)
            Top {
                Leading(padding: 30) {
                    Text("Select view to load:")
                }
                Spacer().frame(height: 10)
                Centered(padding: 20) {
                    Middle(padding: 10) {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(files, id: \.self) { url in
                                    Centered(padding: 20) {
                                        HStack {
                                            Spacer().frame(width: 10)
                                            Text(url.deletingPathExtension().lastPathComponent)
                                            Spacer()
                                            LeadingText(url == defaultUrl ? " (default)" : "")
                                                .frame(width: 80)
                                                .foregroundColor(Palette.background.faintText)
                                        }
                                        .contentShape(Rectangle())
                                        .frame(height: 30)
                                        .palette(loadUrl == url ? .alternate : .clear)
                                        .cornerRadius(8)
                                    }
                                    .onTapGesture {
                                        loadUrl = url
                                    }
                                }
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Palette.gridLine, lineWidth: 2))
                }
            }
            MiddleCentered {
                HStack {
                    InsightsSetupButton(text: "Cancel") {
                        forceDismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer().frame(width: 50)
                    InsightsSetupButton(text: "Load") {
                        InsightsReportViewStorage.load(report: report, from: loadUrl!)
                        forceDismiss()
                    }
                    .disabled(loadUrl == nil)
                }
            }
            .frame(height: 80)
        }
        .onAppear {
            files = InsightsReportViewStorage.loadFileList()
        }
    }
}

struct InsightsReportViewStorageSaveDialog: View {
    @ObservedObject var report: Report
    
    @Environment(\.dismiss) var dismiss
    @State private var files: [URL] = []
    @State var saveUrl: URL?
    @State var filename: String = ""
    @State var saveAsDefault: Bool = false
    
    var body: some View {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        
        Banner(title: Binding.constant("Save View"), alternateStyle: true, back: false, leftTitle: false)
        VStack {
            Spacer().frame(height: 20)
            Top {
                Leading(padding: 30) {
                    Spacer().frame(width: 10)
                    Input(title: "Save As:", field: $filename, color: Palette.alternate, cornerRadius: 8, inlineTitle: true, inlineTitleWidth: 100) { _ in
                        if filename.isEmpty {
                            saveUrl = nil
                        } else {
                            saveUrl = InsightsReportViewStorage.url(for: filename)
                        }
                    }
                    Spacer().frame(width: 50)
                }
                Spacer().frame(height: 10)
                Centered(padding: 20) {
                    Middle(padding: 10) {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(files, id: \.self) { url in
                                    Centered(padding: 20) {
                                        HStack {
                                            Spacer().frame(width: 10)
                                            Text(url.deletingPathExtension().lastPathComponent)
                                            Spacer()
                                            LeadingText(url == defaultUrl ? " (default)" : "")
                                                .frame(width: 80)
                                                .foregroundColor(Palette.background.faintText)
                                        }
                                        .contentShape(Rectangle())
                                        .frame(height: 30)
                                        .palette(saveUrl == url ? .alternate : .clear)
                                        .cornerRadius(8)
                                    }
                                    .onTapGesture {
                                        saveUrl = url
                                        filename = url.deletingPathExtension().lastPathComponent
                                    }
                                }
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Palette.gridLine, lineWidth: 2))
                }
            }
            Leading(padding: 30) {
                Text("Save as default:")
                Spacer().frame(width: 20)
                Toggle("", isOn: $saveAsDefault)
                    .toggleStyle(.automatic)
                    .frame(width: 40)
                Spacer()
            }
            
            MiddleCentered {
                HStack {
                    InsightsSetupButton(text: "Cancel") {
                        forceDismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer().frame(width: 50)
                    InsightsSetupButton(text: "Save") {
                        InsightsReportViewStorage.save(report: report, to: saveUrl!)
                        if saveAsDefault {
                            UserDefault.defaultViewName.set(filename)
                        }
                        forceDismiss()
                    }
                    .disabled(saveUrl == nil)
                }
            }
            .frame(height: 80)
        }
        .onAppear {
            files = InsightsReportViewStorage.loadFileList()
            filename = report.values.viewName
        }
    }
}


struct InsightsSetupButton : View {
    @Environment(\.isEnabled) private var isEnabled
    var text: String
    var action: ()->()
    
    var body : some View {
        Button {
            action()
        } label: {
            MiddleCentered {
                Text(text)
            }
            .frame(width: 130, height: 40)
            .font(inputTitleFont)
            .palette(isEnabled ? .enabledButton : .disabledButton)
            .opacity(isEnabled ? 1 : 0.7)
            .cornerRadius(6)
        }
        .focusable(false)
    }
}

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
    @State var showRemoveDialog: Bool = false
    
    var body: some View {
        HStack {
            VStack {
                Spacer().frame(height: 80)
                InsightsSetupButton(text: "Load View") {
                    showLoadDialog = true
                }
                Spacer().frame(height: 40)
                InsightsSetupButton(text: "Save View") {
                    showSaveDialog = true
                }
                Spacer().frame(height: 40)
                InsightsSetupButton(text: "Create View") {
                    do {
                        try InsightsReportViewStorage.createEmptyView(report: report)
                        report.objectWillChange.send()
                    } catch {
                        fatalError()
                    }
                }
                Spacer().frame(height: 40)
                InsightsSetupButton(text: "Delete View") {
                    showRemoveDialog = true
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showLoadDialog) {
            InsightsReportViewStorageLoadDialog(report: report)
        }
        .sheet(isPresented: $showSaveDialog) {
            InsightsReportViewStorageSaveDialog(report: report)
        }
        .sheet(isPresented: $showRemoveDialog) {
            InsightsReportViewStorageRemoveDialog(report: report)
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
    
    static func save(report: Report, to fileUrl: URL) -> Bool {
        var result = true
        do {
            try report.refresh()
            let data = try JSONEncoder().encode(report.values)
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            result = false
        }
        return result
    }
    
    static func load(report: Report, from fileUrl: URL) -> Bool {
        var result = true
        do {
            let values = try JSONDecoder().decode(ReportValues.self, from: Data(contentsOf: fileUrl))
            try report.update(from: values)
            report.objectWillChange.send()
        } catch {
            result = false
        }
        return result // TODO Need to handle returned FALSE
    }
    
    static func remove(at fileUrl: URL) {
        do {
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            fatalError()
        }
    }
    
    static func loadFileList() -> [URL] {
        if let contents = try? FileManager.default.contentsOfDirectory(at: InsightsReportViewStorage.storageUrl, includingPropertiesForKeys: nil) {
            return contents.filter { $0.pathExtension == "json" }
        } else {
            return []
        }
    }
    
    static func createEmptyView(report: Report) throws {
        let level = CalculatedSortLevel(isBoard: true)
        level.selectionLogic = [.variable(.age),.comparisonOperator(.lessThan),.literal(CalculatedLiteral(characters: "30", type: .numeric))]
        try report.update(from: ReportValues(viewName: "", pinnedColumns: InsightColumn.defaultPinnedColumns, unpinnedColumns: InsightColumn.defaultColumns, levels: [level]))
    }
}

struct InsightsReportViewStorageLoadDialog: View {
    @ObservedObject var report: Report
    var forceDismiss: Bool = false
    var completion: (()->())? = nil
    
    @Environment(\.dismiss) var dismiss
    @State private var files: [URL] = []
    @State var loadUrl: URL?
    
    var body: some View {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        
        PopupStandardView("Load Insight View") {
            Banner(title: Binding.constant("Load View"), alternateColor: true, height: 80, back: false, leftTitle: false)
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
                                            .frame(minWidth: 200)
                                            .contentShape(Rectangle())
                                            .frame(height: 30)
                                            .palette(loadUrl == url ? .alternate : .clear)
                                            .cornerRadius(8)
                                        }
                                        .onTapGesture {
                                            loadUrl = url
                                        }
                                        .onTapGesture(count: 2) {
                                            loadUrl = url
                                            loadUrl(url: loadUrl!)
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
                            loadUrl(url: loadUrl!)
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
    
    func loadUrl(url: URL) {
        if InsightsReportViewStorage.load(report: report, from: url) {
            if forceDismiss {
                forceDismiss()
            } else {
                dismiss()
            }
            completion?()
        } else {
            MessageBox.shared.show("Failed to load view")
        }
    }
}

struct InsightsReportViewStorageSaveDialog: View {
    @ObservedObject var report: Report
    var forceDismiss: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @State private var files: [URL] = []
    @State var saveUrl: URL?
    @State var filename: String = ""
    @State var saveAsDefault: Bool = false
    
    var body: some View {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        
        PopupStandardView("Save Insight View") {
            Banner(title: Binding.constant("Save View"), alternateColor: true, height: 80, back: false, leftTitle: false)
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
                                            .frame(minWidth: 200)
                                            .contentShape(Rectangle())
                                            .frame(height: 30)
                                            .palette(saveUrl == url ? .alternate : .clear)
                                            .cornerRadius(8)
                                        }
                                        .onTapGesture {
                                            saveUrl = url
                                            filename = url.deletingPathExtension().lastPathComponent
                                        }
                                        .onTapGesture(count: 2) {
                                            saveUrl = url
                                            filename = url.deletingPathExtension().lastPathComponent
                                            saveUrl(url: saveUrl!)
                                            
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
                            if forceDismiss {
                                forceDismiss()
                            } else {
                                dismiss()
                            }
                        }
                        .keyboardShortcut(.cancelAction)
                        Spacer().frame(width: 50)
                        InsightsSetupButton(text: "Save") {
                            MessageBox.shared.show("View already exists!", if: filename != report.values.viewName && files.contains(saveUrl!), cancelText: "Cancel", okText: "Overwrite", okDestructive: true, okAction: {
                                saveUrl(url: saveUrl!)
                            })
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
    
    func saveUrl(url: URL) {
        report.values.viewName = filename
        if InsightsReportViewStorage.save(report: report, to: saveUrl!) {
            if saveAsDefault {
                UserDefault.defaultViewName.set(filename)
            }
            if forceDismiss {
                forceDismiss()
            } else {
                dismiss()
            }
        } else {
            MessageBox.shared.show("Failed to save view")
        }
    }
}

struct InsightsReportViewStorageRemoveDialog: View {
    @ObservedObject var report: Report
    
    @Environment(\.dismiss) var dismiss
    @State private var files: [URL] = []
    @State var removeUrl: URL?
    
    var body: some View {
        let defaultUrl = InsightsReportViewStorage.url(for: UserDefault.defaultViewName.string)
        let currentUrl = InsightsReportViewStorage.url(for: report.values.viewName)
        let removableFiles = files.filter({$0 != defaultUrl && $0 != currentUrl})
       
        StandardView("Remove View") {
            Banner(title: Binding.constant("Delete View"), alternateStyle: true, back: false, leftTitle: false)
            VStack {
                Spacer().frame(height: 20)
                Top {
                    Leading(padding: 30) {
                        VStack(spacing: 0) {
                            LeadingText("Select view to delete:")
                            LeadingText("Current view and default view cannot be deleted")
                                .foregroundColor(Palette.background.faintText)
                        }
                    }
                    Spacer().frame(height: 10)
                    Centered(padding: 20) {
                        Middle(padding: 10) {
                            ScrollView(.vertical) {
                                LazyVStack(spacing: 0) {
                                    ForEach(removableFiles, id: \.self) { url in
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
                                            .palette(removeUrl == url ? .alternate : .clear)
                                            .cornerRadius(8)
                                        }
                                        .onTapGesture {
                                            removeUrl = url
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
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                        Spacer().frame(width: 50)
                        InsightsSetupButton(text: "Delete") {
                            MessageBox.shared.show("Are you sure you want to delete this view?", cancelText: "Cancel", okText: "Delete", okDestructive: true, okAction: {
                                InsightsReportViewStorage.remove(at: removeUrl!)
                                dismiss()
                            })
                        }
                        .disabled(removeUrl == nil)
                    }
                }
                .frame(height: 80)
            }
        }
        .onAppear {
            files = InsightsReportViewStorage.loadFileList()
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

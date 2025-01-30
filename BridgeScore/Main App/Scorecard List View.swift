//
//  Scorecard List View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 21/01/2022.
//

import SwiftUI
import UniformTypeIdentifiers
import AudioToolbox
import Combine

struct ScorecardDetails {
    var layout: LayoutViewModel?
    var scorecard: ScorecardViewModel?
    var newScorecard: Bool = false
    
    init(scorecard: ScorecardViewModel? = nil, layout: LayoutViewModel? = nil, newScorecard: Bool = false) {
        self.layout = layout
        self.scorecard = scorecard
        self.newScorecard = newScorecard
    }
}

enum Destination: Int {
    case root
    case layoutSetup
    case playerSetup
    case locationSetup
    case stats
    case scorecardInput
    case scorecardParameters
    case layoutSelect
    
    var navigate: Bool { [.layoutSetup, .playerSetup, .locationSetup, .stats, .scorecardInput].contains(self)}
}

let ScorecardListViewChange = PassthroughSubject<ScorecardDetails, Never>()

struct ScorecardListView: View, DropDelegate {
    @Environment(\.verticalSizeClass) var sizeClass
    private let id = scorecardListViewId
    public static var view: ScorecardListView?
    private let inputId = UUID()
    private let uttypes = [UTType.fileURL]
    @StateObject private var selected = ScorecardViewModel(scorecardId: nullUUID)
    @StateObject private var filterValues = ScorecardFilterValues(.list)
    @ObservedObject private var data = MasterData.shared
    @State private var title = "Scorecards"
    @State public var layout = LayoutViewModel()
    @State public var layoutSelected = false
    @State private var linkToDownload = false
    @State private var destination: Destination = .root { didSet { if destination.navigate { path.append(destination) } } }
    @State private var highlighted = false
    @State private var startAt: UUID?
    @State private var closeFilter = false
    @State private var importScorecard: ImportSource = .none
    @State private var importTapped: ImportSource = .none
    @State private var dropEntered: Bool = false
    @State private var tileColor = Palette.contrastTile
    @State private var deleted = false
    @State private var cancelled = false
    @State private var dismissDetailView = false
    @State private var path: [Destination] = []
    var dropColor: Binding<PaletteColor> { Binding { tileColor } set: { (newValue) in tileColor = newValue } }
    var linkToLayoutSelect: Binding<Bool> { Binding { destination == .layoutSelect } set: { (_) in } }
    var linkToScorecardParameters: Binding<Bool> { Binding { destination == .scorecardParameters } set: { (_) in } }

    var body: some View {
        let scorecards = MasterData.shared.scorecards.filter({filterValues.filter($0)})
        
        var menuOptions = [BannerOption(text: "Statistics", action: { destination = .stats }),
                           BannerOption(text: "Templates", action: { destination = .layoutSetup }),
                           BannerOption(text: "Players",  action: { destination = .playerSetup }),
                           BannerOption(text: "Locations", action: { destination = .locationSetup }),
                           BannerOption(text: "Import BBO Names", action: { ImportBBO.importNames() }),
                           BannerOption(text: "Backup", action: { MessageBox.shared.show("Backing up", cancelText: "Cancel", okText: "Continue", okAction: {Backup.shared.backup() ; MessageBox.shared.hide()})})]
        if Utility.isSimulator {
            menuOptions.append(
                           BannerOption(text: "Restore", action: {
                              Backup.shared.restore(dateString: "Latest") }))
        }
        menuOptions.append(contentsOf:
                          [BannerOption(text: "About \(appName)", action: { MessageBox.shared.show("A Bridge scoring app from\nShearer Online Ltd", showIcon: true, showVersion: true) })])
        
        return StandardView("Scorecard List", slideInId: id, navigation: true, path: $path) {
            GeometryReader { geometry in
                VStack {
                    Banner(title: $title, back: false, optionMode: .menu, menuImage: AnyView(Image(systemName: "gearshape")), menuTitle: "Setup", menuId: id, options: menuOptions)
                    Spacer().frame(height: 8)
                    
                    ListTileView(color: dropColor) {
                        HStack {
                            Image(systemName: "plus.square")
                            Text("New Scorecard")
                        }
                    }
                    /*.onDrop(of: uttypes, delegate: self)
                     In case you ever need to drop import files on this list
                     */
                    .onTapGesture {
                        self.destination = .layoutSelect
                    }
                    
                    ScrollView {
                        Spacer().frame(height: 4)
                        ScorecardFilterView(id: id, filterValues: filterValues, closeFilter: $closeFilter)
                        ScrollViewReader { scrollViewProxy in
                            LazyVStack {
                                ForEach(scorecards) { (scorecard) in
                                    ScorecardSummaryView(slideInId: id, scorecard: scorecard, highlighted: highlighted, selected: selected, importTapped: $importTapped)
                                        .id(scorecard.scorecardId)
                                        .onTapGesture {
                                                // Copy this entry to current scorecard
                                            self.selected.copy(from: scorecard)
                                            linkAction()
                                        }
                                }
                            }
                            .onChange(of: importTapped, initial: false) { (_, newValue) in
                                if newValue != .none {
                                    linkAction(importTapped: newValue)
                                }
                                importTapped = .none
                            }
                            .onChange(of: self.startAt, initial: false) { (_, newValue) in
                                if let newValue = newValue {
                                    scrollViewProxy.scrollTo(newValue, anchor: .top)
                                    startAt = nil
                                }
                            }
                            .onChange(of: self.closeFilter, initial: false) { (_, newValue) in
                                if newValue {
                                    if let scorecard = data.scorecards.first {
                                        self.startAt = scorecard.scorecardId
                                    }
                                    closeFilter = false
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .onAppear {
                    ScorecardListView.view = self
                    if selected.scorecardId == nullUUID {
                        Utility.mainThread {
                            if let scorecard = scorecards.first {
                                if  filterValues.isClear {
                                    self.startAt = scorecard.scorecardId
                                }
                            }
                        }
                        if UserDefault.currentUnsaved.bool {
                            // Unsaved version - restore it and link to it
                            let scorecard = ScorecardViewModel()
                            scorecard.restoreCurrent()
                            self.selected.copy(from: scorecard)
                            Scorecard.current.load(scorecard: scorecard)
                            destination = .scorecardInput
                        }
                    }
                }
                .onReceive(ScorecardListViewChange) { (details) in
                    Utility.mainThread {
                        // Clear any pre-existing view
                        path = []
                        cancelled = true
                        self.destination = .root
                        layoutSelected = false
                        // Link to new view
                        if details.newScorecard {
                            if let layout = details.layout {
                                createScorecard(from: layout)
                                if layout.displayDetail {
                                    self.destination = .scorecardParameters
                                } else {
                                    destination = .scorecardInput
                                }
                            } else {
                                layoutSelected = false
                                destination = .layoutSelect
                            }
                        } else if let scorecard = details.scorecard {
                            self.selected.copy(from: scorecard)
                            linkAction()
                        }
                    }
                }
                .navigationDestination(for: Destination.self) { (destination) in
                    switch destination {
                    case .layoutSetup:
                        LayoutSetupView()
                    case .playerSetup:
                        PlayerSetupView()
                    case .locationSetup:
                        LocationSetupView()
                    case .stats:
                        StatsView()
                    case .scorecardInput:
                        ScorecardInputView(scorecard: selected, importScorecard: importScorecard)
                    default:
                        fatalError()
                    }
                }
                .sheet(isPresented: linkToLayoutSelect, onDismiss: {
                    if layoutSelected {
                        createScorecard(from: layout)
                        var transaction = Transaction(animation: .linear(duration: 0.01))
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            if layout.displayDetail {
                                destination = .scorecardParameters
                            } else {
                                destination = .scorecardInput
                            }
                        }
                    }
                }) {
                    LayoutListView(selected: $layoutSelected, layout: $layout, completion: {
                        destination = .root
                    })
                }
                .fullScreenCover(isPresented: linkToScorecardParameters, onDismiss: {
                    if !deleted && !cancelled {
                        destination = .scorecardInput
                    }
                }) {
                    ZStack {
                        Color.black.opacity(0.4)
                        let width = min(704, geometry.size.width) // Allow for safe area
                        let height = min(610, (geometry.size.height))
                        let frame = CGRect(x: (geometry.size.width - width) / 2,
                                           y: ((geometry.size.height - height) / 2) + 20,
                                           width: width,
                                           height: height)
                        ScorecardDetailView(scorecard: selected, deleted: $deleted, title: "Scorecard Details", frame: frame, dismissView: $dismissDetailView, showResults: false, cancelButton: true, completion: {
                                destination = .root
                            })
                    }
                    .background(BackgroundBlurView(opacity: 0.0))
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
    
    private func linkAction(importTapped: ImportSource = .none) {
        Utility.mainThread {
            Scorecard.current.load(scorecard: self.selected)
            if true || !Scorecard.current.isSensitive { // TODO Reinstate password control?
                importScorecard = importTapped
                destination = .scorecardInput
            } else {
                LocalAuthentication.authenticate(reason: "You must authenticate to access the scorecard detail") {
                    importScorecard = importTapped
                    destination = .scorecardInput
                } failure: {
                    Scorecard.current.clear()
                }
            }
        }
    }
    
    private func createScorecard(from layout: LayoutViewModel) {
        self.selected.reset(from: layout)
        Scorecard.current.load(scorecard: selected)
        selected.saveScorecard()
        importScorecard = .none
    }
    
    // MARK: - Drop delegates
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        dropColor.wrappedValue = Palette.enabledButton
    }
    
    func dropExited(info: DropInfo) {
        dropColor.wrappedValue = Palette.contrastTile
    }
    
    func performDrop(info: DropInfo) -> Bool {
        var dropped: [(filename: String, conteents: String)] = []
        for item in info.itemProviders(for: [UTType.data]) {
            if let filename = item.suggestedName {
                item.loadItem(forTypeIdentifier: UTType.data.identifier) { (url, error) in
                    if let url = url as? URL {
                        if let data = try? Data(contentsOf: url), let contents = String(data: data, encoding: .utf8) {
                            dropped.append((filename, contents))
                        }
                    }
                }
            }
        }
        
        dropColor.wrappedValue = Palette.contrastTile
        AudioServicesPlaySystemSound(SystemSoundID(1304))
        return true
    }
}

struct ScorecardSummaryView: View {
    @Environment(\.verticalSizeClass) var sizeClass

    var slideInId: UUID
    @ObservedObject var scorecard: ScorecardViewModel
    @State var highlighted: Bool
    @ObservedObject var selected: ScorecardViewModel
    @Binding var importTapped: ImportSource
    @State var selectImport = false
    @State var importSelected: Int?
    
    var body: some View {
        if MyApp.format == .phone && !isLandscape {
            portraitPhoneView
        } else {
            normalView
        }
    }
    
    var normalView: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return ListTileView(color: Binding.constant(color)) {
            GeometryReader { geometry in
                HStack {
                    VStack {
                        Spacer().frame(height: 4)
                        HStack {
                            description
                            Spacer()
                            position.frame(width: 100)
                            score.frame(width: 150)
                            Spacer().frame(width: 30)
                        }
                        .minimumScaleFactor(0.7)
                        .foregroundColor(color.contrastText)
                        .font(.title)
                        HStack {
                            datePlayed
                            Spacer()
                            HStack {
                                playedWith
                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.3)
                            playedAt
                            .frame(width: geometry.size.width * 0.37)
                        }
                        .foregroundColor(color.text)
                        .font(.callout)
                        .minimumScaleFactor(0.5)
                        Spacer().frame(height: 12)
                    }
                    importButton
                    deleteButton
                }
            }
        }
    }
    
    var portraitPhoneView: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return ListTileView(color: Binding.constant(color), height: 120) {
            VStack {
                Spacer().frame(height: 4)
                HStack {
                    description
                    Spacer()
                    score
                }
                .minimumScaleFactor(0.7)
                .foregroundColor(color.contrastText)
                .font(.title)
                HStack {
                    VStack {
                        HStack {
                            datePlayed
                            Spacer()
                        }
                        Spacer().frame(height: 2)
                        HStack {
                            playedWith
                            Spacer()
                        }
                        Spacer().frame(height: 2)
                        HStack {
                            playedAt
                            Spacer()
                        }
                    }
                    .foregroundColor(color.text)
                    .font(.callout)
                    .minimumScaleFactor(0.5)
                    deleteButton
                    
                }
                Spacer().frame(height: 8)
            }
        }
    }
    
    var description: some View {
        HStack {
            let text = scorecard.desc + (scorecard.comment == "" || portraitPhone ? "" : " (\(scorecard.comment))") + (scorecard.scorer?.isSelf ?? true || portraitPhone ? "" : " as \(scorecard.scorer!.name)")
            Text(text).lineLimit(portraitPhone ? 1 : 2)
                .if(MyApp.format == .phone) { (view) in
                    view.minimumScaleFactor(1)
                }
        }
    }
    
    var portraitPhone: Bool {
        MyApp.format == .phone && !isLandscape
    }
    
    var position: some View {
        HStack {
            if scorecard.position != 0 && scorecard.entry != 0 {
                Text("\(scorecard.position) / \(scorecard.entry)")
                    
            }
        }
    }
    
    var score: some View {
        HStack {
            if scorecard.score != nil {
                if !portraitPhone {
                    Text(scorecard.scoreString)
                } else {
                    Text(scorecard.score!.toString(places: scorecard.type.matchPlaces))
                }
            }
        }
    }
    
    var datePlayed: some View {
        Text(Utility.dateString(Date.startOfDay(from: scorecard.date)!, format: "dd MMM yyyy", style: .short, doesRelativeDateFormatting: true)).font(.callout).bold()
    }
    
    var playedWith: some View {
        HStack {
            if scorecard.type.players > 1 {
                HStack {
                    Text("With: ")
                    Text(scorecard.partner?.name ?? "").font(.callout).bold()
                    Spacer()
                }
            }
        }
    }
    
    var playedAt: some View {
        HStack {
            HStack {
                Text("At: ")
                Text(scorecard.location?.name ?? "").font(.callout).bold()
                Spacer()
            }
        }
    }
    
    var importButton: some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return HStack {
            if scorecard.importSource == .none && !scorecard.manualTotals {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        PopupMenu(id: slideInId, field: $importSelected, values: ImportSource.validCases.map{$0.string}, animation: .none, top: geometry.frame(in: .global).minY - 30, left: geometry.frame(in: .global).minX - 290, width: 300) { (selectedIndex) in
                            if let selectedIndex = selectedIndex {
                                importTapped = ImportSource.validCases[selectedIndex]
                                selected.copy(from: scorecard)
                            }
                            importSelected = nil
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(color.contrastText)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 50)
    }
    
    var deleteButton: some View {
        button("trash.circle.fill") {
            highlighted = true
            MessageBox.shared.show("This will delete the scorecard permanently.\nAre you sure you want to do this?", cancelText: "Cancel", okText: "Confirm", cancelAction: {
                highlighted = false
            }, okAction: {
                highlighted = false
                scorecard.remove()
            })
        }
    }
    
    func button(_ imageName: String, action: @escaping ()->()) -> some View {
        let color = (highlighted ? Palette.highlightTile : Palette.tile)
        return VStack {
            Spacer()
            Button {
                action()
            } label: {
                Image(systemName: imageName)
                    .font(.largeTitle)
                    .foregroundColor(color.contrastText)
            }
            Spacer()
        }
    }
}


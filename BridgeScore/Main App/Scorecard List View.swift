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
import WidgetKit

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

struct ScorecardListView: View, DropDelegate {
    @Environment(\.verticalSizeClass) var sizeClass
    private let id = scorecardListViewId
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
    @State private var forceDisplayDetail = false
    @State private var filterLayouts: [LayoutViewModel]? = nil
    @State private var path: [Destination] = []
    var dropColor: Binding<PaletteColor> { Binding { tileColor } set: { (newValue) in tileColor = newValue } }
    var linkToLayoutSelect: Binding<Bool> { Binding { destination == .layoutSelect } set: { (_) in } }
    var linkToScorecardParameters: Binding<Bool> { Binding { destination == .scorecardParameters } set: { (_) in } }

    var body: some View {
        let scorecards = MasterData.shared.scorecards.filter({filterValues.filter($0)})
        
        return StandardView("Scorecard List", slideInId: id, navigation: true, path: $path) {
            GeometryReader { geometry in
                VStack {
                    Banner(title: $title, back: false, optionMode: .menu, menuImage: AnyView(Image(systemName: "gearshape")), menuTitle: "Setup", menuId: id, options: bannerMenuOptions())
                    Spacer().frame(height: 8)
                    newScorecardTileView()
                    ScrollView {
                        Spacer().frame(height: 4)
                        ScorecardFilterView(id: id, filterValues: filterValues, closeFilter: $closeFilter)
                        ScrollViewReader { scrollViewProxy in
                            LazyVStack {
                                ForEach(scorecards) { (scorecard) in
                                    existingScorecardTileView(scorecard: scorecard)
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
                    initialiseView(scorecards: scorecards)
                }
                .onReceive(ScorecardListViewChange) { (details) in
                    // Probably from Widget / AppIntent
                    receiveViewChange(details: details)
                }
                .navigationDestination(for: Destination.self) { (destination) in
                    AnyView(navigateToDestinationView())
                }
                .sheet(isPresented: linkToLayoutSelect, onDismiss: {
                    // Completed
                    linkToParametersOrInput()
                }) {
                    LayoutListView(selected: $layoutSelected, layout: $layout, filterLayouts: filterLayouts, completion: {
                        destination = .root
                    })
                }
                .fullScreenCover(isPresented: linkToScorecardParameters, onDismiss: {
                    if !deleted && !cancelled {
                        destination = .scorecardInput
                    }
                }) {
                    scorecardDetailView(geometry: geometry)
                        .onAppear {
                            cancelled = false
                        }
                }
            }
        }
    }
    
    func initialiseView(scorecards: [ScorecardViewModel]) {
        if selected.scorecardId == nullUUID {
            Utility.mainThread {
                if let scorecard = scorecards.first {
                    if filterValues.isClear {
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
    
    func newScorecardTileView() -> some View {
        return ListTileView(color: dropColor) {
            HStack {
                Image(systemName: "plus.square")
                Text("New Scorecard")
            }
        }
        .onTapGesture {
            self.forceDisplayDetail = false
            self.filterLayouts = nil
            self.destination = .layoutSelect
        }
    }
    
    func navigateToDestinationView() -> any View {
        var result: any View
        switch destination {
        case .layoutSetup:
            result = LayoutSetupView()
        case .playerSetup:
            result = PlayerSetupView()
        case .locationSetup:
            result = LocationSetupView()
        case .stats:
            result = StatsView()
        case .scorecardInput:
            result = ScorecardInputView(scorecard: selected, importScorecard: importScorecard)
        default:
            result = EmptyView()
        }
        return result
    }
    
    func existingScorecardTileView(scorecard: ScorecardViewModel) -> some View {
        ScorecardSummaryView(slideInId: id, scorecard: scorecard, highlighted: highlighted, selected: selected, importTapped: $importTapped)
            .id(scorecard.scorecardId)
            .onTapGesture {
                    // Copy this entry to current scorecard
                self.selected.copy(from: scorecard)
                linkAction()
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
    
    private func linkToParametersOrInput() {
        if layoutSelected {
            createScorecard(from: layout)
            var transaction = Transaction(animation: .linear(duration: 0.01))
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if layout.displayDetail || forceDisplayDetail {
                    destination = .scorecardParameters
                } else {
                    destination = .scorecardInput
                }
            }
        }
    }
    
    private func scorecardDetailView(geometry: GeometryProxy) -> some View {
        return ZStack {
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
    
    private func createScorecard(from layout: LayoutViewModel) {
        self.selected.reset(from: layout)
        Scorecard.current.load(scorecard: selected)
        selected.saveScorecard()
        importScorecard = .none
    }
    
    func receiveViewChange(details: ScorecardDetails) {
        Utility.mainThread {
            // Clear any pre-existing view
            path = []
            cancelled = true
            self.destination = .root
            layoutSelected = false
            // Link to new view
            Utility.executeAfter(delay: 0.1) {
                switch details.action {
                case .createScorecard:
                    forceDisplayDetail = details.forceDisplayDetail
                    if let layouts = details.layouts, !layouts.isEmpty {
                        if layouts.count == 1 {
                            let layout = layouts.first!
                            createScorecard(from: layout)
                            if layout.displayDetail || forceDisplayDetail {
                                self.destination = .scorecardParameters
                            } else {
                                destination = .scorecardInput
                            }
                        } else {
                            layoutSelected = false
                            filterLayouts = layouts
                            destination = .layoutSelect
                        }
                    } else {
                        layoutSelected = false
                        filterLayouts = nil
                        destination = .layoutSelect
                    }
                case .scorecardDetails:
                    if let scorecard = details.scorecard {
                        self.selected.copy(from: scorecard)
                        linkAction()
                    }
                case .stats:
                    self.destination = .stats
                }
            }
        }
    }
    
    func bannerMenuOptions() -> [BannerOption] {
        var menuOptions: [BannerOption] = []
        menuOptions = [BannerOption(text: "Statistics", action: { destination = .stats }),
                           BannerOption(text: "Templates", action: { destination = .layoutSetup }),
                           BannerOption(text: "Players",  action: { destination = .playerSetup }),
                           BannerOption(text: "Locations", action: { destination = .locationSetup }),
                           BannerOption(text: "Import BBO Names", action: { ImportBBO.importNames() }),
                           BannerOption(text: "Backup", action: { MessageBox.shared.show("Backing up", cancelText: "Cancel", okText: "Continue", okAction: {Backup.shared.backup() ; MessageBox.shared.hide()})})]
        if Utility.isSimulator || MyApp.target == .iOS {
            menuOptions.append(
                BannerOption(text: "Restore", action: {
                    Backup.shared.restore(dateString: "Latest") }))
        }
        menuOptions.append(contentsOf:
                            [BannerOption(text: "About \(appName)", action: { MessageBox.shared.show("A Bridge scoring app from\nShearer Online Ltd", showIcon: true, showVersion: true) })])
        return menuOptions
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
            Text(scorecard.positionString)
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
            HStack {
                if scorecard.type.players > 1 {
                    Text("With: ")
                    Text(scorecard.partner?.name ?? "").font(.callout).bold()
                } else {
                    Text("Individual")
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
                WidgetCenter.shared.reloadTimelines(ofKind: lastScorecardWidgetKind)
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


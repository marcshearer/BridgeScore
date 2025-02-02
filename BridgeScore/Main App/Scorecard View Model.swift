//
//  Scorecard View Model.swift
//  BridgeScore
//
//  Created by Marc Shearer on 12/02/2021.
//

import Combine
import SwiftUI
import CoreData
import PencilKit

public class ScorecardViewModel : ObservableObject, Identifiable, Equatable, CustomDebugStringConvertible {

    // Properties in core data model
    @Published private(set) var scorecardId = UUID()
    public var id: UUID { self.scorecardId }
    @Published public var date = Date()
    @Published public var location: LocationViewModel?
    @Published public var desc: String = ""
    @Published public var comment: String = ""
    @Published public var scorer: PlayerViewModel?
    @Published public var partner: PlayerViewModel?
    @Published public var boards: Int = 0
    @Published public var boardsTable: Int = 0
    @Published public var sessions: Int = 1
    @Published public var type: ScorecardType = ScorecardType()
    @Published public var manualTotals: Bool = false
    @Published public var resetNumbers: Bool = false
    @Published public var score: Float?
    @Published public var maxScore: Float?
    @Published public var position: Int = 0
    @Published public var entry: Int = 0
    @Published public var importSource: ImportSource = .none
    @Published public var importNext: Int = 0
    
    public var tables: Int { get { boards / max(1, boardsTable) } }
    public var tablesSession: Int { get { tables / max(1, sessions) } }
    public var boardsSession: Int { get { boards / max(1, sessions) } }
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var scorecardMO: ScorecardMO?
    
    @Published public var descMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    @Published internal var editTitle: String = "New Scorecard"
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.scorecardMO {
            if self.scorecardId != mo.scorecardId ||
                self.date != mo.date ||
                self.location?.locationId != mo.locationId ||
                self.desc != mo.desc ||
                self.comment != mo.comment ||
                self.scorer?.playerId != mo.scorerId ||
                self.partner?.playerId != mo.partnerId ||
                self.boards != mo.boards ||
                self.boardsTable != mo.boardsTable ||
                self.sessions != mo.sessions ||
                self.type != mo.type ||
                self.manualTotals != mo.manualTotals ||
                self.resetNumbers != mo.resetNumbers ||
                self.score != mo.score ||
                self.maxScore != mo.maxScore ||
                self.position != mo.position ||
                self.entry != mo.entry ||
                self.importSource != mo.importSource ||
                self.importNext != mo.importNext
            {
                    result = true
            }
        } else {
            result = true
        }
        return result
    }
    
    public init() {
        self.reset()
        self.setupMappings()
    }
    
    public convenience init(scorecardId: UUID) {
        self.init()
        self.reset()
        self.setupMappings()
        self.scorecardId = scorecardId
    }
    
    public convenience init(scorecardMO: ScorecardMO) {
        self.init()
        self.scorecardMO = scorecardMO
        self.revert()
    }
    
    private func setupMappings() {
        $desc
            .receive(on: RunLoop.main)
            .map { (desc) in
                return (desc == "" ? "Description must be non-blank.\nPlease re-edit and enter a valid description or delete this scorecard." : "")
            }
        .assign(to: \.saveMessage, on: self)
        .store(in: &cancellableSet)
        
        $desc
            .receive(on: RunLoop.main)
            .map { (desc) in
                return (desc == "" ? "Must be non-blank" : "")
            }
        .assign(to: \.descMessage, on: self)
        .store(in: &cancellableSet)
        
        Publishers.CombineLatest($desc, $scorecardMO)
            .receive(on: RunLoop.main)
            .map { (desc, scorecardMO) in
                return scorecardMO == nil ? "New Scorecard" : desc
            }
        .assign(to: \.editTitle, on: self)
        .store(in: &cancellableSet)
              
        $saveMessage
            .receive(on: RunLoop.main)
            .map { (saveMessage) in
                return (saveMessage == "")
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
    }
    
    public func reset(from: LayoutViewModel? = nil) {
        self.scorecardId = UUID()
        let layout = from ?? MasterData.shared.layouts.first ?? LayoutViewModel()
        self.desc = layout.scorecardDesc
        self.location = layout.location
        self.scorer = MasterData.shared.scorer
        self.partner = layout.partner
        self.boards = layout.boards
        self.boardsTable = layout.boardsTable
        self.sessions = layout.sessions
        self.type = layout.type
        self.manualTotals = layout.manualTotals
        self.resetNumbers = layout.resetNumbers
        self.date = layout.regularDay.lastDate
        self.comment = ""
        self.score = nil
        self.maxScore = nil
        self.position = 0
        self.entry = 0
        self.importSource = .none
        self.importNext = 1
        self.scorecardMO = nil
    }
    
    public func copy(from: ScorecardViewModel) {
        self.scorecardId = from.scorecardId
        self.date = from.date
        self.location = from.location
        self.desc = from.desc
        self.comment = from.comment
        self.scorer = from.scorer
        self.partner = from.partner
        self.boards = from.boards
        self.boardsTable = from.boardsTable
        self.sessions = from.sessions
        self.type = from.type
        self.manualTotals = from.manualTotals
        self.resetNumbers = from.resetNumbers
        self.score = from.score
        self.maxScore = from.maxScore
        self.position = from.position
        self.entry = from.entry
        self.importSource = from.importSource
        self.importNext = from.importNext
        self.scorecardMO = from.scorecardMO
    }
    
    public func revert() {
        if let mo = self.scorecardMO {
            self.scorecardId = mo.scorecardId
            self.date = mo.date
            if let location = MasterData.shared.location(id: mo.locationId) {
                self.location = location
            }
            self.desc = mo.desc
            self.comment = mo.comment
            if let scorer = MasterData.shared.player(id: mo.scorerId) {
                self.scorer = scorer
            } else {
                self.scorer = MasterData.shared.scorer
            }
            if let partner = MasterData.shared.player(id: mo.partnerId) {
                self.partner = partner
            }
            self.boards = mo.boards
            self.boardsTable = mo.boardsTable
            self.sessions = mo.sessions
            self.type = mo.type
            self.manualTotals = mo.manualTotals
            self.resetNumbers = mo.resetNumbers
            self.score = mo.score
            self.maxScore = mo.maxScore
            self.position = mo.position
            self.entry = mo.entry
            self.importSource = mo.importSource
            self.importNext = mo.importNext
        }
    }
    
    public func updateMO() {
        if let mo = self.scorecardMO {
            mo.scorecardId = self.scorecardId
            mo.date = self.date
            mo.locationId = self.location?.locationId
            mo.desc = self.desc
            mo.comment = self.comment
            mo.scorerId = self.scorer?.playerId
            mo.partnerId = self.partner?.playerId
            mo.boards = self.boards
            mo.boardsTable = self.boardsTable
            mo.sessions = self.sessions
            mo.type = self.type
            mo.manualTotals = self.manualTotals
            mo.resetNumbers = self.resetNumbers
            mo.score = self.score
            mo.maxScore = self.maxScore
            mo.position = self.position
            mo.entry = self.entry
            mo.importSource = self.importSource
            mo.importNext = self.importNext
        } else {
            fatalError("No managed object")
        }
    }
    
    public static func == (lhs: ScorecardViewModel, rhs: ScorecardViewModel) -> Bool {
        return lhs.scorecardId == rhs.scorecardId
    }
    
    public func saveScorecard() {
        // Note that scorecard should always be saved in this way as we're re-using
        // the object that the scorecard is defined in
        assert(Scorecard.current.match(scorecard: self), "This is not the currently loaded scorecard")
        Scorecard.current.addNew()
        Scorecard.current.saveAll(scorecard: self)
        if let master = MasterData.shared.scorecard(id: self.scorecardId) {
            master.copy(from: self)
            master.save()
            self.copy(from: master)
        } else {
            let master = ScorecardViewModel()
            master.copy(from: self)
            master.insert()
            self.copy(from: master)
        }
    }
    
    private func save() {
        if self.scorecardMO == nil {
            MasterData.shared.insert(scorecard: self)
        } else {
            MasterData.shared.save(scorecard: self)
        }
        if Scorecard.current.match(scorecard: self) {
            Scorecard.current.saveAll(scorecard: self)
            UserDefault.currentUnsaved.set(false)
        }
    }
    
    private func insert() {
        MasterData.shared.insert(scorecard: self)
        if Scorecard.current.match(scorecard: self) {
            Scorecard.current.saveAll(scorecard: self)
            UserDefault.currentUnsaved.set(false)
        }
    }
    
    public func remove() {
        if !self.isNew {
            MasterData.shared.remove(scorecard: self)
        }
        if Scorecard.current.match(scorecard: self) {
            Scorecard.current.removeAll(scorecard: self)
        }
        UserDefault.currentUnsaved.set(false)
    }
    
    public var isNew: Bool {
        self.scorecardMO == nil
    }
    
    public var isMultiSession: Bool {
        self.sessions > 1
    }
    
    private func descExists(_ name: String) -> Bool {
        return !MasterData.shared.scorecards.contains(where: {$0.desc == desc && $0 != self})
    }
    
    public var scoreString: String {
        "\(type.matchPrefix(score: score))\((score ?? 0).toString(places: min(1, type.matchPlaces)))\(type.matchSuffix(maxScore: maxScore))"
    }
    
    public var description: String {
        "Scorecard: \(self.desc)"
    }
    
    public func sessionTables(session: Int?) -> ClosedRange<Int> {
        var result: ClosedRange<Int>
        if let session = session {
            let lowerBound = max(1, ((session - 1) * tablesSession) + 1)
            let upperBound = min(tables, lowerBound + tablesSession - 1)
            result = lowerBound...upperBound
        } else {
            result = 1...tables
        }
        return result
    }
    
    public var debugDescription: String { self.description }
    
    public func backupCurrent() {
        UserDefault.currentId.set(self.scorecardId)
        UserDefault.currentDate.set(self.date)
        if let locationId = self.location?.locationId {
            UserDefault.currentLocation.set(locationId)
        }
        UserDefault.currentDescription.set(self.desc)
        UserDefault.currentComment.set(self.comment)
        if let partnerId = self.partner?.playerId {
            UserDefault.currentScorer.set(partnerId)
        }
        if let partnerId = self.partner?.playerId {
            UserDefault.currentPartner.set(partnerId)
        }
        UserDefault.currentBoards.set(self.boards)
        UserDefault.currentBoardsTable.set(self.boardsTable)
        UserDefault.currentSessions.set(self.sessions)
        UserDefault.currentType.set(self.type)
        UserDefault.currentManualTotals.set(self.manualTotals)
        UserDefault.currentResetNumbers.set(self.resetNumbers)
        UserDefault.currentScore.set(self.score == nil ? "" : "\(self.score!)")
        UserDefault.currentMaxScore.set(self.maxScore == nil ? "" : "\(self.maxScore!)")
        UserDefault.currentPosition.set(self.position)
        UserDefault.currentEntry.set(self.entry)
        UserDefault.currentImportSource.set(self.importSource)
        UserDefault.currentImportNext.set(self.importNext)
    }
    
    public func restoreCurrent() {
        // First try to read existing
        if let id = UserDefault.currentId.uuid {
            let savedScorecard = MasterData.shared.scorecard(id: id)
            self.scorecardMO = savedScorecard?.scorecardMO
        }
        
        // Now overwrite with backed up data
        self.scorecardId = UserDefault.currentId.uuid ?? UUID()
        self.date = UserDefault.currentDate.date ?? Date()
        self.location = MasterData.shared.location(id: UserDefault.currentLocation.uuid)
        self.desc = UserDefault.currentDescription.string
        self.comment = UserDefault.currentComment.string
        self.partner = MasterData.shared.player(id: UserDefault.currentPartner.uuid)
        self.boards = UserDefault.currentBoards.int
        self.boardsTable = UserDefault.currentBoardsTable.int
        self.sessions = UserDefault.currentSessions.int
        self.type = UserDefault.currentType.type ?? ScorecardType()
        self.manualTotals = UserDefault.currentManualTotals.bool
        self.resetNumbers = UserDefault.currentResetNumbers.bool
        let score = UserDefault.currentScore.string
        self.score = score == "" ? nil : Float(score)
        let maxScore = UserDefault.currentMaxScore.string
        self.maxScore = maxScore == "" ? nil : Float(maxScore)
        self.position = UserDefault.currentPosition.int
        self.importSource = UserDefault.currentImportSource.importSource ?? .none
        self.importNext = UserDefault.currentImportNext.int
    }
}

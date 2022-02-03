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
    @Published private(set) var scorecardId: UUID
    public var id: UUID { self.scorecardId }
    @Published public var date: Date
    @Published public var location: LocationViewModel?
    @Published public var desc: String
    @Published public var comment: String = ""
    @Published public var partner: PlayerViewModel?
    @Published public var boards: Int = 0
    @Published public var boardsTable: Int = 0
    @Published public var type: Type = .percent
    @Published public var tableTotal: Bool = false
    @Published public var totalScore: Float = 0
    @Published public var drawingWidth: CGFloat = 0.0
    @Published public var drawing = PKDrawing()
    
    public var tables: Int { get { boards / max(1, boardsTable) } }
    
    // Linked managed objects - should only be referenced in this and the Data classes
    @Published internal var scorecardMO: ScorecardMO?
    
    @Published public var descMessage: String = ""
    @Published private(set) var saveMessage: String = ""
    @Published private(set) var canSave: Bool = false
    @Published internal var canExit: Bool = false
    @Published internal var editTitle: String = "New Scorecard"
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Check if view model matches managed object
    public var changed: Bool {
        var result = false
        if let mo = self.scorecardMO {
            if self.scorecardId != mo.scorecardId ||
                self.location?.locationId != mo.locationId ||
                self.desc != mo.desc ||
                self.comment != mo.comment ||
                self.partner?.playerId != mo.partnerId ||
                self.boards != mo.boards ||
                self.boardsTable != mo.boardsTable ||
                self.type != mo.type ||
                self.tableTotal != mo.tableTotal ||
                self.totalScore != mo.totalScore ||
                self.drawing != mo.drawing ||
                self.drawingWidth != mo.drawingWidth
            {
                    result = true
            }
        }
        return result
    }
    
    public init() {
        self.scorecardId = UUID()
        self.date = Date()
        self.desc = ""
        self.setupMappings()
    }
    
    public convenience init(layout: LayoutViewModel) {
        self.init()
        self.desc = layout.desc
        self.boards = layout.boards
        self.boardsTable = layout.boardsTable
        self.type = layout.type
        self.tableTotal = layout.tableTotal
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
                return (desc == "" ? "Scorecard description must not be left blank. Either enter a valid description or delete this scorecard" : (self.descExists(desc) ? "This description already exists on another scorecard. The description must be unique" : ""))
            }
        .assign(to: \.saveMessage, on: self)
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
        
        Publishers.CombineLatest3($desc, $scorecardMO, $canSave)
            .receive(on: RunLoop.main)
            .map { (desc, scorecardMO, canSave) in
                return (canSave || (scorecardMO == nil && desc == ""))
            }
        .assign(to: \.canExit, on: self)
        .store(in: &cancellableSet)
 
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
            if let partner = MasterData.shared.player(id: mo.partnerId) {
                self.partner = partner
            }
            self.boards = mo.boards
            self.boardsTable = mo.boardsTable
            self.type = mo.type
            self.tableTotal = mo.tableTotal
            self.totalScore = mo.totalScore
            self.drawing = mo.drawing
            self.drawingWidth = mo.drawingWidth
        }
    }
    
    public static func == (lhs: ScorecardViewModel, rhs: ScorecardViewModel) -> Bool {
        return lhs.scorecardId == rhs.scorecardId
    }
    
    public func save() {
        if self.scorecardMO == nil {
            MasterData.shared.insert(scorecard: self)
        } else {
            MasterData.shared.save(scorecard: self)
        }
        UserDefault.currentUnsaved.set(false)
    }
    
    public func insert() {
        MasterData.shared.insert(scorecard: self)
        UserDefault.currentUnsaved.set(false)
    }
    
    public func remove() {
        MasterData.shared.remove(scorecard: self)
        UserDefault.currentUnsaved.set(false)
    }
    
    public var isNew: Bool {
        return self.scorecardMO == nil
    }
    
    private func descExists(_ name: String) -> Bool {
        return !MasterData.shared.scorecards.compactMap{$1}.filter({$0.desc == desc && $0.scorecardId != self.scorecardId}).isEmpty
    }
    
    public var description: String {
        "Scorecard: \(self.desc)"
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
            UserDefault.currentPartner.set(partnerId)
        }
        UserDefault.currentBoards.set(self.boards)
        UserDefault.currentBoardsTable.set(self.boardsTable)
        UserDefault.currentType.set(self.type)
        UserDefault.currentTableTotal.set(self.tableTotal)
        UserDefault.currentTotalScore.set(self.totalScore)
        backupCurrentDrawing()
    }
    
    public func backupCurrentDrawing(drawing: PKDrawing? = nil, width: CGFloat? = nil) {
        UserDefault.currentDrawing.set((drawing ?? self.drawing).dataRepresentation())
        UserDefault.currentWidth.set(Float(width ?? self.drawingWidth))
        UserDefault.currentUnsaved.set(true)
    }
    
    public func reset() {
        UserDefault.currentUnsaved.set(true)
        self.scorecardId = UUID()
        self.date = Date()
        self.location = MasterData.shared.locations.compactMap{ $0.value }.sorted(by: {$0.sequence < $1.sequence}).first!
        self.desc = ""
        self.comment = ""
        self.partner = MasterData.shared.players.compactMap{ $0.value }.sorted(by: {$0.sequence < $1.sequence}).first!
        self.boards = 24
        self.boardsTable = 3
        self.type = .percent
        self.tableTotal = true
        self.totalScore = 0
        self.drawing = PKDrawing()
        self.drawingWidth = 0
        self.scorecardMO = nil
    }
    
    public func restoreCurrent() {
        UserDefault.currentUnsaved.set(true)
        
        // First try to read existing
        if let id = UserDefault.currentId.uuid {
            let savedScorecard = MasterData.shared.scorecard(id: id)
            self.scorecardMO = savedScorecard?.scorecardMO
        }
        
        // Now overwrite with backed up data
        self.scorecardId = UserDefault.currentId.uuid ?? UUID()
        self.date = UserDefault.currentDate.date
        self.location = MasterData.shared.location(id: UserDefault.currentLocation.uuid)
        self.desc = UserDefault.currentDescription.string
        self.comment = UserDefault.currentComment.string
        self.partner = MasterData.shared.player(id: UserDefault.currentPartner.uuid)
        self.boards = UserDefault.currentBoards.int
        self.boardsTable = UserDefault.currentBoardsTable.int
        self.type = UserDefault.currentType.type
        self.tableTotal = UserDefault.currentTableTotal.bool
        self.totalScore = UserDefault.currentTotalScore.float
        self.drawing = (try? PKDrawing(data: UserDefault.currentDrawing.data)) ?? PKDrawing()
        self.drawingWidth = CGFloat(UserDefault.currentWidth.float)
    }
}

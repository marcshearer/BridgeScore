//
//  Scorecard Intents.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/01/2025.
//

import AppIntents

enum ScorecardDetailsAction {
    case scorecardDetails
    case createScorecard
    case stats
}

struct ScorecardDetails {
    var action: ScorecardDetailsAction
    var layouts: [LayoutViewModel]?
    var scorecard: ScorecardViewModel?
    var forceDisplayDetail: Bool
    
    init(action: ScorecardDetailsAction, scorecard: ScorecardViewModel? = nil, layouts: [LayoutViewModel]? = nil, forceDisplayDetail: Bool = false) {
        self.action = action
        self.layouts = layouts
        self.scorecard = scorecard
        self.forceDisplayDetail = forceDisplayDetail
    }
}

extension CreateScorecardAppIntent {
    func perform() async throws -> some IntentResult {
        var layoutViewModels: [LayoutViewModel]? = []
        for layoutEntity in layouts {
            if layoutEntity.id == nullUUID {
                layoutViewModels = nil
                break
            } else if let layout = MasterData.shared.layout(id: layoutEntity.id) {
                layoutViewModels!.append(layout)
            }
        }
        if layoutViewModels?.isEmpty ?? true {
            layoutViewModels = nil
        }
        let details = ScorecardDetails(action: .createScorecard, layouts: layoutViewModels, forceDisplayDetail: forceDisplayDetail)
        Utility.mainThread {
            ScorecardListViewChange.send(details)
        }
        return .result()
    }
}

extension LastScorecardAppIntent {
    func perform() async throws -> some IntentResult {
        let scorecardId = target.id
        if let scorecardMO = ScorecardEntity.scorecard(id: scorecardId) {
            let scorecard = ScorecardViewModel(scorecardMO: scorecardMO)
            let details = ScorecardDetails(action: .scorecardDetails, scorecard: scorecard)
            Utility.mainThread {
                ScorecardListViewChange.send(details)
            }
        }
        return .result()
    }
}

extension StatsAppIntent {
    func perform() async throws -> some IntentResult {
        let filterValues = ScorecardFilterValues(.stats)
        filterValues.clear()
        if !locations.isEmpty && !locations.contains(where: {$0.id == nullUUID}) {
            filterValues.locations.setArray(locations.map{$0.id.uuidString})
        }
        if !players.isEmpty && !players.contains(where: {$0.id == nullUUID}) {
            filterValues.partners.setArray(players.map{$0.id.uuidString})
        }
        if !eventTypes.isEmpty {
            filterValues.types.setArray(eventTypes.map{$0.eventType.rawValue})
        }
        if dateRange != .all {
            filterValues.dateFrom = dateRange.startDate
        }
        filterValues.save()
        
        let details = ScorecardDetails(action: .stats)
        Utility.mainThread {
            ScorecardListViewChange.send(details)
        }
        
        return .result()
    }
}


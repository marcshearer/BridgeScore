//
//  Scorecard Intents.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/01/2025.
//

import AppIntents

enum ScorecardDetailsAction {
    case openScorecard
    case createScorecard
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

struct CreateScorecardAppIntent: AppIntent, OpenIntent {

    static let title: LocalizedStringResource = "Create Scorecard"
    
    @Parameter(title: "Template", description: "The template to use for the Scorecard") var target: LayoutEntity
    
    func perform() async throws -> some IntentResult {
        let layoutId = target.id
        if let layoutMO = LayoutEntity.layouts(id: layoutId).first {
            let layout = LayoutViewModel(layoutMO: layoutMO)
            let details = ScorecardDetails(action: .createScorecard, layouts: [layout])
            Utility.mainThread {
                ScorecardListViewChange.send(details)
            }
        }
        return .result()
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$target)")
    }
    
}

struct OpenScorecard : AppIntent, OpenIntent {
    
    static let title: LocalizedStringResource = "Open Scorecard"
    
    @Parameter(title: "Scorecard", description: "Scorecard to Open") var target: ScorecardEntity

    init() {
        
    }
    
    init(id: UUID? = nil) {
        if let id = id {
            self.target = ScorecardEntity(id: id)
        }
    }
    
    func perform() async throws -> some IntentResult {
        let scorecardId = target.id
        if let scorecardMO = ScorecardEntity.scorecards(id: scorecardId).first {
            let scorecard = ScorecardViewModel(scorecardMO: scorecardMO)
            let details = ScorecardDetails(action: .openScorecard, scorecard: scorecard)
            Utility.mainThread {
                ScorecardListViewChange.send(details)
            }
        }
        return .result()
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create scorecard for \(\.$target)")
    }
    
    static let openAppWhenRun: Bool = true
    
}

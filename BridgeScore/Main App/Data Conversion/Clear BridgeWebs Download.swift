//
//  Clear BridgeWebs Download.swift
//  BridgeScore
//
//  Created by Marc Shearer on 01/05/2026.
//

import SwiftUI

class ClearBridgeWebsDownload {
    static let cutoff = Utility.dateFromString("13/03/2026")!
    
    static func clear() {
        for scorecard in MasterData.shared.scorecards {
            if scorecard.date >= cutoff && scorecard.importSource != .none {
                Scorecard.current.clear()
                Scorecard.current.load(scorecard: scorecard)
                if let context = CoreData.context {
                    context.performAndWait {
                        Scorecard.current.clearImport()
                        
                    }
                }
                Scorecard.current.saveAll(scorecard: scorecard)
            }
        }
    }
    
}

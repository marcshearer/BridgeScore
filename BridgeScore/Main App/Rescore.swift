//
//  Rescore.swift
//  BridgeScore
//
//  Created by Marc Shearer on 17/03/2026.
//

import Swift

extension Scorecard {
    
    public func rescore(as playerName: String, checkUpdate: (()->Bool)?) -> Bool {
        var success = true
        var playerTravellers: [Int:TravellerViewModel] = [:]  // [BoardIndex:Ranking]
        var playerRankings: [Int:RankingViewModel] = [:]       // [Session:Ranking]
        var playerSeats: [Int:[Seat]] = [:]                   // [Session:[Seat]]
        var scorer: PlayerViewModel!
        var partner: PlayerViewModel?
        
        if isImported, let scorecard = scorecard {
            
            // Setup player
            let otherPlayer = MasterData.shared.player(name: otherPlayer)!
            scorer = MasterData.shared.player(name: playerName) ?? otherPlayer
            
            for session in 1...scorecard.sessions {
                // Check ranking for session
                let rankings = Scorecard.current.rankings(session: (scorecard.isMultiSession ? session : nil), player: (bboName: scorer.bboName, name: scorer.name))
                if let playerRanking = rankings.first {
                    playerRankings[session] = playerRanking
                    playerSeats[session] = playerRanking.players.filter({$1 == playerName}).map{$0.key}
                    if scorecard.type.players > 1 {
                        if let seat = playerSeats[session]?.first {
                            let partnerName = playerRanking.players[seat.partner]!
                            partner = MasterData.shared.player(name: partnerName) ?? otherPlayer
                        } else {
                            success = false
                        }
                    }
                } else {
                    success = false
                }
            }
            if success {
                    // Look at boards / travellers
                iterateBoards { (_, board) in
                    let travellers = Scorecard.current.travellers(board: board.boardIndex)
                    for seat in playerSeats[board.session] ?? [] {
                        if let playerTraveller = travellers.first(where: {$0.rankingNumber[seat] == playerRankings[board.session]?.number && $0.section[seat] == playerRankings[board.session]?.section}) {
                            
                            playerTravellers[board.boardIndex] = playerTraveller
                            break
                        }
                    }
                }
            }
            if success {
                scorecard.scorer = scorer
                scorecard.partner = partner
                // TODO: Need to update total score / position on scorecard
                iterateBoards { (table, board) in
                    if let traveller = playerTravellers[board.boardIndex], let sitting = seat(traveller: traveller, ranking: playerRankings[board.session]!, name: scorer.name) {
                        // Update table
                        table.sitting = sitting
                        table.score = nil
                        table.versus = ""
                        table.partner = ""
                        // Update table
                        board.contract = traveller.contract
                        board.declarer = traveller.declarer
                        board.made = traveller.made
                        board.score = scorecard.type.invertScore(score: traveller.nsScore, pair: sitting.pair)
                        // board.responsible = .unknown
                    } else {
                        // Sitout
                        table.sitting = .unknown
                        table.score = nil
                        table.versus = ""
                        table.partner = ""
                        board.contract = Contract()
                        board.declarer = .unknown
                        board.made = nil
                        board.score = nil
                        board.responsible = .unknown
                    }
                }
                scorecard.saveScorecard()
            }
        } else {
            success = false
        }
        return success
    }
    
    func seat(traveller: TravellerViewModel, ranking: RankingViewModel, name: String) -> Seat? {
        var result: Seat?
        
        for seat in Seat.validCases {
            if traveller.rankingNumber[seat] == ranking.number {
                if ranking.players[seat]?.lowercased() == name.lowercased() {
                    result = seat
                    break
                }
            }
        }
        
        return result
    }
}

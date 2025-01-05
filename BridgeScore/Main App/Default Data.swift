//
//  Default Data.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022.
//

import Foundation

class DefaultData {
    
    public class func layouts(players: [PlayerViewModel], locations: [LocationViewModel]) -> [LayoutViewModel] {
        
        let layout1 = LayoutViewModel()
        layout1.desc = "St Andrews Pairs"
        layout1.scorecardDesc = "St Andrews Pairs"
        layout1.location = locations.first(where: {$0.name == "St Andrews"})
        layout1.partner = players.first(where: {$0.name == "George Watson"})
        layout1.sequence = 1
        layout1.boards = 24
        layout1.boardsTable = 3
        layout1.sessions = 1
        layout1.type = .percent
        layout1.resetNumbers = false
        layout1.sequence = 0
        
        let layout2 = LayoutViewModel()
        layout2.desc = "Dundee Online"
        layout2.scorecardDesc = "Dundee Online Pairs"
        layout2.location = locations.first(where: {$0.name == "Dundee"})
        layout2.partner = players.first(where: {$0.name == "Jack Shearer"})
        layout2.sequence = 0
        layout2.boards = 24
        layout2.boardsTable = 3
        layout2.sessions = 1
        layout2.type = .percent
        layout2.resetNumbers = false
        layout2.sequence = 1
        
        let layout3 = LayoutViewModel()
        layout3.desc = "Dundee Pairs"
        layout3.scorecardDesc = "Dundee Pairs"
        layout3.location = locations.first(where: {$0.name == "Dundee"})
        layout3.partner = players.first(where: {$0.name == "Michele Grainger"})
        layout3.sequence = 0
        layout3.boards = 24
        layout3.boardsTable = 3
        layout3.sessions = 1
        layout3.type = .percent
        layout3.resetNumbers = false
        layout3.sequence = 2
        
        let layout4 = LayoutViewModel()
        layout4.desc = "SOL"
        layout4.scorecardDesc = "SOL v "
        layout4.location = locations.first(where: {$0.name == "SBU"})
        layout4.partner = players.first(where: {$0.name == "George Watson"})
        layout4.sequence = 0
        layout4.boards = 24
        layout4.boardsTable = 12
        layout3.sessions = 2
        layout4.type = .vpMatchTeam
        layout4.resetNumbers = true
        layout4.sequence = 3
        
        let layout5 = LayoutViewModel()
        layout5.desc = "Saturday Swiss Pairs"
        layout5.scorecardDesc = "Saturday Swiss Pairs"
        layout5.location = locations.first(where: {$0.name == "SBU"})
        layout5.partner = players.first(where: {$0.name == "Michele Grainger"})
        layout5.sequence = 0
        layout5.boards = 25
        layout5.boardsTable = 5
        layout5.sessions = 1
        layout5.type = .percent
        layout5.resetNumbers = false
        layout5.sequence = 4
        
        let layout6 = LayoutViewModel()
        layout6.desc = "EBU Pairs"
        layout6.scorecardDesc = "EBU Pairs"
        layout6.location = locations.first(where: {$0.name == "EBU"})
        layout6.partner = players.first(where: {$0.name == "Jack Shearer"})
        layout6.sequence = 0
        layout6.boards = 12
        layout6.boardsTable = 2
        layout6.sessions = 1
        layout6.type = .percent
        layout6.resetNumbers = false
        layout6.sequence = 5
        
        let layout7 = LayoutViewModel()
        layout7.desc = "New Melville Pairs"
        layout7.scorecardDesc = "New Melville Pairs"
        layout7.location = locations.first(where: {$0.name == "New Melville"})
        layout7.partner = players.first(where: {$0.name == "Michele Grainger"})
        layout7.sequence = 0
        layout7.boards = 24
        layout7.boardsTable = 3
        layout3.sessions = 1
        layout7.type = .xImp
        layout7.resetNumbers = false
        layout7.sequence = 6

        return [layout1, layout2, layout3, layout4, layout5, layout6, layout7]
    }
    
    public class var players: [PlayerViewModel] {
        get {
            let player1 = PlayerViewModel()
            player1.name = "Michele Grainger"
            player1.bboName = "mjg2507"
            player1.sequence = 0
            
            let player2 = PlayerViewModel()
            player2.name = "George Watson"
            player2.bboName = "StaGeorge"
            player2.sequence = 2
            
            let player3 = PlayerViewModel()
            player3.name = "Jack Shearer"
            player3.bboName = "ShearerJP"
            player3.sequence = 1
            
            let player4 = PlayerViewModel()
            player4.name = "Peter Thommeny"
            player4.bboName = "Genesisss"
            player4.sequence = 3
            
            let player5 = PlayerViewModel()
            player5.name = "Marc Shearer"
            player5.bboName = "MShearer"
            player5.isSelf = true
            player5.sequence = 5
            
            return [player1, player2, player3, player4, player5]
        }
    }
    
    public class var locations: [LocationViewModel] {
        get {
            let location1 = LocationViewModel()
            location1.name = "St Andrews"
            location1.bridgeWebsId = "standrews"
            location1.sequence = 0

            let location2 = LocationViewModel()
            location2.name = "SBU"
            location2.bridgeWebsId = "sbu"
            location2.sequence = 2

            let location3 = LocationViewModel()
            location3.name = "EBU"
            location3.bridgeWebsId = "eburesults"
            location3.sequence = 3

            let location5 = LocationViewModel()
            location5.name = "Dundee"
            location5.bridgeWebsId = "dundee"
            location5.sequence = 1

            let location6 = LocationViewModel()
            location6.name = "Andrew Robson"
            location6.sequence = 5
            
            let location7 = LocationViewModel()
            location7.name = "SOL"
            location7.sequence = 6
            
            let location8 = LocationViewModel()
            location8.name = "Carlton"
            location8.bridgeWebsId = "carlton"
            location8.sequence = 7
            
            let location9 = LocationViewModel()
            location9.name = "New Melville"
            location9.bridgeWebsId = "newmelville"
            location9.sequence = 8
            
            return [location1, location2, location3, location5, location6, location7, location8, location9]
        }
    }

}

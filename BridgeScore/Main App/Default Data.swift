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
        layout1.type = .percent
        layout1.tableTotal = true
        layout1.sequence = 0
        
        let layout2 = LayoutViewModel()
        layout2.desc = "Tuesday Pairs"
        layout2.scorecardDesc = "Tuesday Pairs"
        layout2.location = locations.first(where: {$0.name == "SBU"})
        layout2.partner = players.first(where: {$0.name == "Michele Grainger"})
        layout2.sequence = 0
        layout2.boards = 24
        layout2.boardsTable = 3
        layout2.type = .percent
        layout2.tableTotal = true
        layout2.sequence = 1
        
        let layout3 = LayoutViewModel()
        layout3.desc = "Leven Pairs"
        layout3.scorecardDesc = "Leven Pairs"
        layout3.location = locations.first(where: {$0.name == "Leven"})
        layout3.partner = players.first(where: {$0.name == "Jack Shearer"})
        layout3.sequence = 0
        layout3.boards = 24
        layout3.boardsTable = 3
        layout3.type = .percent
        layout3.tableTotal = true
        layout3.sequence = 2
        
        let layout4 = LayoutViewModel()
        layout4.desc = "Thursday Teams"
        layout4.scorecardDesc = "Scottish Swiss Teams 11 - Week "
        layout4.location = locations.first(where: {$0.name == "Online Swiss Teams"})
        layout4.partner = players.first(where: {$0.name == "George Watson"})
        layout4.sequence = 0
        layout4.boards = 24
        layout4.boardsTable = 12
        layout4.type = .imp
        layout4.tableTotal = true
        layout4.sequence = 3
        
        let layout5 = LayoutViewModel()
        layout5.desc = "Saturday Swiss Pairs"
        layout5.scorecardDesc = "Saturday Swiss Pairs"
        layout5.location = locations.first(where: {$0.name == "SBU"})
        layout5.partner = players.first(where: {$0.name == "Michele Grainger"})
        layout5.sequence = 0
        layout5.boards = 25
        layout5.boardsTable = 5
        layout5.type = .percent
        layout5.tableTotal = true
        layout5.sequence = 4
        
        let layout6 = LayoutViewModel()
        layout6.desc = "EBU Pairs"
        layout6.scorecardDesc = "EBU Pairs"
        layout6.location = locations.first(where: {$0.name == "EBU"})
        layout6.partner = players.first(where: {$0.name == "Jack Shearer"})
        layout6.sequence = 0
        layout6.boards = 12
        layout6.boardsTable = 2
        layout6.type = .percent
        layout6.tableTotal = true
        layout6.sequence = 5
        
        let layout7 = LayoutViewModel()
        layout7.desc = "ARBC Pairs"
        layout7.scorecardDesc = "ARBC Pairs"
        layout7.location = locations.first(where: {$0.name == "Andrew Robson"})
        layout7.partner = players.first(where: {$0.name == "Michele Grainger"})
        layout7.sequence = 0
        layout7.boards = 18
        layout7.boardsTable = 3
        layout7.type = .percent
        layout7.tableTotal = true
        layout7.sequence = 6

        return [layout1, layout2, layout3, layout4, layout5, layout6, layout7]
    }
    
    public class var players: [PlayerViewModel] {
        get {
            let player1 = PlayerViewModel()
            player1.name = "Michele Grainger"
            player1.sequence = 0
            
            let player2 = PlayerViewModel()
            player2.name = "George Watson"
            player2.sequence = 1
            
            let player3 = PlayerViewModel()
            player3.name = "Jack Shearer"
            player3.sequence = 2
            
            let player4 = PlayerViewModel()
            player4.name = "Peter Thommeny"
            player4.sequence = 3
            
            return [player1, player2, player3, player4]
        }
    }
    
    public class var locations: [LocationViewModel] {
        get {
            let location1 = LocationViewModel()
            location1.name = "St Andrews"
            location1.sequence = 0

            let location2 = LocationViewModel()
            location2.name = "SBU"
            location2.sequence = 1

            let location3 = LocationViewModel()
            location3.name = "EBU"
            location3.sequence = 2

            let location4 = LocationViewModel()
            location4.name = "Leven"
            location4.sequence = 3

            let location5 = LocationViewModel()
            location5.name = "Dundee"
            location5.sequence = 4

            let location6 = LocationViewModel()
            location6.name = "Andrew Robson"
            location6.sequence = 5
            
            let location7 = LocationViewModel()
            location7.name = "Online Swiss Teams"
            location7.sequence = 6

            return [location1, location2, location3, location4, location5, location6, location7]
        }
    }

}

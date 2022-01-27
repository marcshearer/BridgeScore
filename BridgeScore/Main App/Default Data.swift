//
//  Default Data.swift
//  BridgeScore
//
//  Created by Marc Shearer on 23/01/2022.
//

import Foundation

class DefaultData {
    
    public class var layouts: [LayoutViewModel] {
        get {
            let layout = LayoutViewModel()
            layout.desc = "Default layout"
            layout.sequence = 0
            layout.boards = 24
            layout.boardsTable = 3
            layout.type = .percent
            layout.tableTotal = false
            
            return [layout]
        }
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

            return [location1, location2, location3, location4, location5, location6]
        }
    }

}

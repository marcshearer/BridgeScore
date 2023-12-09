//
//  Export.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/11/2023.
//

import CoreData

class Export {
    
    static public func export(scorecard: ScorecardViewModel, playerName: String, includeComment: Bool, includeResponsible: Bool, rotateTo: SeatPlayer?) -> String? {
        var exportData: String? = ""
        exportData! += "{\"parameters\":{"
        exportData! += "\"scorerName\":\"\(playerName)\""
        let bboName = MasterData.shared.bboNames.first(where: {$0.name.lowercased() == playerName.lowercased()})?.bboName
        if let ranking = Scorecard.current.rankings(player: (bboName: bboName ?? "", name: playerName)).first {
            var partnerName: String?
            for seat in Seat.validCases {
                if ranking.players[seat] == playerName || ranking.players[seat] == bboName {
                    partnerName = ranking.players[seat.partner]
                    break
                }
            }
            if let partnerName = partnerName {
                exportData! += ",\"partnerName\":\"\(MasterData.shared.realName(bboName: partnerName) ?? partnerName)\""
            }
        }
        exportData! += "}},"
        exportData! += "\n{\"data\":["
        for entity in MyApp.databaseTables {
            if entity.attributesByName.contains(where: {$0.key == "scorecardId"}) {
                if let data = Export.exportTable(scorecard: scorecard, entity: entity, includeComment: includeComment, includeResponsible: includeResponsible, rotateTo: rotateTo) {
                    exportData! += data
                } else {
                    exportData = nil
                    break
                }
            }
        }
        if exportData != nil {
            exportData! += "]}}"
        }
        return exportData
    }
    
    static private func exportTable(scorecard: ScorecardViewModel, entity: NSEntityDescription, includeComment: Bool, includeResponsible: Bool, rotateTo: SeatPlayer?) -> String? {
        var tableData: String? = ""
        let recordType = entity.name!
        let predicate = NSPredicate(format: "scorecardId = %@", scorecard.scorecardId as NSUUID)
        let recordList = CoreData.fetch(from: recordType, filter: predicate)
        if !recordList.isEmpty {
            tableData! += "\n{\"\(recordType)s\":["
            for record in recordList {
                tableData! += "\n{\"\(recordType)\":"
                if let data = Export.exportRecord(scorecard: scorecard, record: record, includeComment: includeComment, includeResponsible: includeResponsible, rotateTo: rotateTo) {
                    tableData! += data
                } else {
                    tableData = nil
                    break
                }
                tableData! += "}"
            }
            if tableData != nil {
                tableData! += "]}"
            }
        }
        return tableData
    }
    
    static private func exportRecord(scorecard: ScorecardViewModel, record: NSManagedObject, includeComment: Bool, includeResponsible: Bool, rotateTo: SeatPlayer?) -> String? {
        var recordData: String? = ""
        var dictionary: [String : Any] = [:]
        for (key, _) in record.entity.attributesByName {
            if key == "scorecardId" {
                dictionary[key] = ""
            } else {
                let value = record.value(forKey: key)
                if value == nil {
                        // No need to back up
                } else if let date = value! as? Date {
                    dictionary[key] = ["date" : Utility.dateString(date, format: backupDateFormat, localized: false)]
                } else if let uuid = value! as? UUID {
                    switch key.lowercased() {
                    case "locationid":
                        if let location = MasterData.shared.location(id: uuid) {
                            dictionary["location"] = location.name
                        } else {
                            recordData = nil
                            break
                        }
                    case "partnerid":
                        if let player = MasterData.shared.player(id: uuid) {
                            dictionary["partner"] = player.name
                        } else {
                            recordData = nil
                            break
                        }
                    default:
                        recordData = nil
                        break
                    }
                } else if let data = value! as? Data {
                    dictionary[key] = ["data" : data.base64EncodedString()]
                } else if let value = value! as? String {
                    if record.entity.name?.lowercased() == "ranking" {
                        switch key.lowercased() {
                        case "north", "south", "east", "west":
                            dictionary[key] = value
                            if let name = MasterData.shared.realName(bboName: value) {
                                dictionary[key + ".bbo"] = name
                            }
                        default:
                            dictionary[key] = value
                        }
                    } else if record.entity.name?.lowercased() == "board" {
                        switch key.lowercased() {
                        case "comment":
                            if includeComment {
                                dictionary[key] = value
                            }
                        default:
                            dictionary[key] = value
                        }
                    } else {
                        dictionary[key] = value
                    }
                } else {
                    if record.entity.name?.lowercased() == "board" {
                        switch key.lowercased() {
                        case "responsible16":
                            if includeResponsible {
                                dictionary[key] = rotated(responsible: value as! Int16)
                            }
                        default:
                            dictionary[key] = value!
                        }
                    } else {
                        dictionary[key] = value!
                    }
                }
            }
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            recordData = String(data: data, encoding: .utf8)
        } catch {
            recordData = nil
            
        }
        return recordData
        
        func rotated(responsible: Int16) -> Int16? {
            var result = Responsible(rawValue: Int(responsible))!
            if rotateTo == .partner {
                result = result.partnerInverse
            } else if (rotateTo?.isOpponent ?? false) {
                result = result.teamInverse
            }
            return Int16(result.rawValue)
        }
    }
}

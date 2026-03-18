//
//  Export.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/11/2023.
//

import CoreData

class Export {
    
    static public func export(scorecard: ScorecardViewModel, playerName: String, includeComment: Bool, includeResponsible: Bool, rotateTo: SeatPlayer?) -> Data? {
        var dictionary: [String:Any?] = [:]
        var parameterDictionary:[String:String] = [:]
        parameterDictionary["scorerName"] = playerName
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
                parameterDictionary["partnerName"] = partnerName
            }
        }
        parameterDictionary["sharedBy"] = MasterData.shared.scorer!.email
        parameterDictionary["schemaVersion"] = "\(schemaVersion)"
        dictionary["parameters"] = parameterDictionary
        var tableList: [[String:Any?]] = []
        for entity in MyApp.databaseTables {
            if entity.attributesByName.contains(where: {$0.key == "scorecardId"}) {
                if let tableDictionary = Export.exportTable(scorecard: scorecard, entity: entity, includeComment: includeComment, includeResponsible: includeResponsible, rotateTo: rotateTo) {
                    tableList.append(tableDictionary)
                }
            }
        }
        dictionary["data"] = tableList
        return try? JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    static private func exportTable(scorecard: ScorecardViewModel, entity: NSEntityDescription, includeComment: Bool, includeResponsible: Bool, rotateTo: SeatPlayer?) -> [String:Any?]? {
        let recordType = entity.name!
        let predicate = NSPredicate(format: "scorecardId = %@", scorecard.scorecardId as NSUUID)
        let records = CoreData.fetch(from: recordType, filter: predicate)
        var tableDictionary: [String:Any?]? = nil
        if !records.isEmpty {
            var recordList: [[String:Any?]] = []
            for record in records {
                recordList.append(Export.exportRecord(scorecard: scorecard, record: record, includeComment: includeComment, includeResponsible: includeResponsible, rotateTo: rotateTo))
            }
            tableDictionary = [entity.name!:recordList]
        }
        return tableDictionary
    }
    
    static private func exportRecord(scorecard: ScorecardViewModel, record: NSManagedObject, includeComment: Bool, includeResponsible: Bool, rotateTo: SeatPlayer?) -> [String:Any?] {
        var dictionary: [String : Any] = [:]
        for (key, _) in record.entity.attributesByName {
            if key == "scorecardId" || key == "sharedWith" {
                dictionary[key] = ""
            } else if key == "sharedBy" {
                dictionary[key] = MasterData.shared.scorer!.email
            } else {
                let value = record.value(forKey: key)
                if value == nil {
                        // No need to export
                } else if let date = value! as? Date {
                    dictionary[key] = ["date" : Utility.dateString(date, format: backupDateFormat, localized: false)]
                } else if let uuid = value! as? UUID {
                    switch key.lowercased() {
                    case "locationid":
                        dictionary["location"] = MasterData.shared.location(id: uuid)?.name ?? ""
                    case "partnerid":
                        dictionary["partner"] = MasterData.shared.player(id: uuid)?.name ?? ""
                    default:
                        break
                    }
                } else if let value = value! as? String {
                    if record.entity.name?.lowercased() == "ranking" {
                        switch key.lowercased() {
                        case "north", "south", "east", "west":
                            dictionary[key] = value
                            if let name = MasterData.shared.realName(bboName: value) {
                                dictionary[key + ".bbo"] = value
                                dictionary[key] = name
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
        return dictionary
        
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
        
    static public func restore(data: Data) -> (UUID?, String?, String?) {
        let scorecardId = UUID()
        let importDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:Any?]
        let parameters = importDictionary["parameters"] as! [String:String]
        let importSchemaVersion = Int(parameters["schemaVersion"] ?? "999") ?? 999
        if importSchemaVersion > schemaVersion {
            return (nil, "Import version is higher than current version. Please upgrade to latest version.", nil)
        } else {
            let contents = importDictionary["data"] as! [[String:[[String:Any?]]]]
            for table in contents {
                for (type, records) in table {
                    if let entity = MyApp.databaseTables.first(where: { $0.name == type }) {
                        restoreTable(entity: entity, records: records, scorecardId: scorecardId)
                    }
                }
            }
            return (scorecardId, nil, parameters["scorerName"])
        }
    }
    
    static private func restoreTable(entity: NSEntityDescription, records: [[String: Any?]], scorecardId: UUID) {
        let recordType = entity.name!
        let tableKeys = entity.propertiesByName.keys
        for record in records {
            let managedObject = NSManagedObject(entity: entity, insertInto: CoreData.context)
            for (keyName, value) in record {
                if tableKeys.contains(keyName) {
                    if keyName == "scorecardId" {
                        managedObject.setValue(scorecardId, forKey: keyName)
                    } else if let actualValue = self.value(forKey: keyName, keys: record) {
                        managedObject.setValue(actualValue, forKey: keyName)
                    } else {
                        fatalError("Error in \(recordType) - Invalid key value for \(keyName)")
                    }
                } else {
                    switch keyName {
                    case "partner":
                        if let name = value as? String {
                            var partnerId = MasterData.shared.player(name: name)?.playerId
                            if partnerId == nil {
                                partnerId = MasterData.shared.player(name: otherPlayer)?.playerId
                            }
                            if let partnerId = partnerId {
                                managedObject.setValue(partnerId, forKey: "partnerId")
                            }
                        }
                    case "location":
                        if let name = value as? String {
                            var locationId = MasterData.shared.location(name: name)?.locationId
                            if locationId == nil {
                                locationId = MasterData.shared.location(name: otherLocation)?.locationId
                            }
                            if let locationId = locationId {
                                managedObject.setValue(locationId, forKey: "locationId")
                            }
                        }
                    case "north.bbo", "south.bbo", "east.bbo","west.bbo":
                        // Check if this is a translation that isn't in our local file
                        if let value = value as? String {
                            if MasterData.shared.bboNames.first(where: {$0.bboName == value}) == nil {
                                let parts = keyName.components(separatedBy: ".")
                                if let name = record[parts.first!] as? String {
                                    let bboName = BBONameViewModel()
                                    bboName.bboName = value
                                    bboName.name = name
                                    MasterData.shared.insert(bboName: bboName)
                                }
                            }
                        }
                    default:
                        break
                    }
                }
            }
            if recordType == "Scorecard" {
                // Add to list
                MasterData.shared.insert(scorecard: ScorecardViewModel(scorecardMO: managedObject as! ScorecardMO), useExistingMO: true)
            }
        }
        try! CoreData.context.save()
    }
    
    static private func value(forKey name: String, keys: [String:Any?]) -> Any? {
        var result: Any?
        if let specialValue = keys[name] as? [String:String] {
            // Special value
            if specialValue.keys.first == "date" {
                result = Utility.dateFromString(specialValue["date"]!, format: backupDateFormat, localized: false)
            } else if specialValue.keys.first == "uuid" {
                result = UUID(uuidString: specialValue["uuid"]!)
            } else if specialValue.keys.first == "data" {
                result = Data(base64Encoded: specialValue["data"] ?? "")
            }
        } else {
            result = keys[name]!
        }
        return result
    }
}

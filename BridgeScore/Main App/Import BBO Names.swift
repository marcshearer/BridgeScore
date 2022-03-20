//
//  Import BBO Names.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/03/2022.
//

import CoreData

class ImportBBONames {
    
    public class func importFile() {
        
        let documentsUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
        let importsURL = documentsUrl.appendingPathComponent("imports")
        
        let entity = BBONameMO.entity()
        let recordType = entity.name!
        let elementName = recordType
        let groupName = "data"
        let fileURL = importsURL.appendingPathComponent("BboName.json")
        if let fileContents = try? Data(contentsOf: fileURL, options: []) {
            if let fileDictionary = try? JSONSerialization.jsonObject(with: fileContents, options: []) as? [String:Any?] {
                if let contents = fileDictionary[groupName] as? [[String:Any?]] {
                    var fileOK = true
                    CoreData.update {
                        for record in contents {
                            if let keys = record[elementName] as? [String:String],
                               let bboName = keys["bboName"],
                               let name = keys["name"]  {
                                if let bboNameMO = MasterData.shared.bboName(id: bboName) {
                                    bboNameMO.name = name
                                } else {
                                    let bboNameMO = NSManagedObject(entity: entity, insertInto: CoreData.context) as! BBONameMO
                                    bboNameMO.bboName = bboName
                                    bboNameMO.name = name
                                }
                            } else {
                                fileOK = false
                            }
                        }
                    }
                    try! CoreData.context.save()
                    MasterData.shared.load()
                    MessageBox.shared.show(fileOK ? "File imported successfully" : "File imported with errors")
                } else {
                    MessageBox.shared.show("File contains invalid JSON")
                }
            } else {
                MessageBox.shared.show("File contains invalid JSON")
            }
        } else {
            MessageBox.shared.show("Unable to open import file 'imports/BBOName.json")
        }
    }
}

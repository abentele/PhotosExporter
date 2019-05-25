//
//  PreferencesReader.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 25.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class PreferencesReader {
    
    private let logger = Logger(loggerName: "PreferencesReader", logLevel: .info)

    func preferencesFromYaml(yamlStr: String) -> Preferences {
        let preferences = Preferences()

        do {
            let obj = try UniYAML.decode(yamlStr)
            
            if let plansRaw = obj["plans"], let plansArray = plansRaw.array {
                for planRaw in plansArray {
                    let planDict = planRaw.dictionary!
                    if let type = planDict["type"]?.string, let name = planDict["name"]?.string {
                        var plan: Plan?
                        switch (type) {
                        case "FileSystemExport":
                            if let targetFolder = planDict["targetFolder"]?.string {
                                let fileSystemExportPlan = FileSystemExportPlan(name: name, targetFolder: targetFolder)
                                plan = fileSystemExportPlan
                                if let exportCalculated = planDict["exportCalculated"]?.bool {
                                    fileSystemExportPlan.exportCalculated = exportCalculated
                                }
                                if let exportOriginals = planDict["exportOriginals"]?.bool {
                                    fileSystemExportPlan.exportOriginals = exportOriginals
                                }
                            } else {
                                logger.warn("Plan '\(name)' defined without attribute 'targetFolder'")
                            }
                            break
                        case "GooglePhotosExport":
                            plan = GooglePhotosExportPlan(name: name)
                            break
                        default:
                            break
                        }
                        if let plan = plan {
                            preferences.plans.append(plan)
                        }
                    } else {
                        logger.warn("Plan defined without type or name attribute: \(String(describing: planRaw.dictionary))")
                    }
                }
            }
        } catch UniYAMLError.error(let detail) {
            print(detail)
        } catch {
            print("error")
        }
        
        return preferences
    }
    
}

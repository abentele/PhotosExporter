//
//  PreferencesReader.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 25.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

enum PreferencesReaderError: Error {
    case invalidYaml
    case invalidOrNoPlanType
}

class PreferencesReader {
    
    private let logger = Logger(loggerName: "PreferencesReader", logLevel: .info)

    func preferencesFromYaml(yamlStr: String) throws -> Preferences {
        let preferences = Preferences()

        var preferencesRaw: YAML
        do {
            preferencesRaw = try UniYAML.decode(yamlStr)
        } catch UniYAMLError.error(let detail) {
            print(detail)
            throw PreferencesReaderError.invalidYaml
        } catch {
            print("error: \(error)")
            throw PreferencesReaderError.invalidYaml
        }
        
        if let plansRaw = preferencesRaw["plans"], let plansArray = plansRaw.array {
            for planRaw in plansArray {
                let planDict = planRaw.dictionary!
                if let type = planDict["type"]?.string {
                    var plan: Plan?
                    switch (type) {
                    case "IncrementalFileSystemExport":
                        plan = IncrementalFileSystemExportPlan()
                        break
                    case "SnapshotFileSystemExport":
                        plan = SnapshotFileSystemExportPlan()
                        break
                    case "GooglePhotosExport":
                        plan = GooglePhotosExportPlan()
                        break
                    default:
                        throw PreferencesReaderError.invalidOrNoPlanType
                    }

                    if let plan = plan, let name = planDict["name"]?.string {
                        plan.name = name
                    }

                    if let plan = plan as? FileSystemExportPlan {
                        if let targetFolder = planDict["targetFolder"]?.string {
                            plan.targetFolder = targetFolder
                        }
                        if let exportCalculated = planDict["exportCalculated"]?.bool {
                            plan.exportCalculated = exportCalculated
                        }
                        plan.exportOriginals = planDict["exportOriginals"]?.bool
                    }
                    
                    if let plan = plan as? IncrementalFileSystemExportPlan {
                        plan.baseExportPath = planDict["baseExportPath"]?.string
                    }

                    if let plan = plan as? SnapshotFileSystemExportPlan {
                        if let deleteFlatPath = planDict["deleteFlatPath"]?.bool {
                            plan.deleteFlatPath = deleteFlatPath
                        }
                    }

                    if let plan = plan {
                        preferences.plans.append(plan)
                    }
                } else {
                    logger.warn("Plan defined without type attribute: \(String(describing: planRaw.dictionary))")
                    throw PreferencesReaderError.invalidOrNoPlanType
                }
            }
        }

        
        return preferences
    }
    
}

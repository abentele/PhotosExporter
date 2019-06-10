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

        var preferencesYaml: YAML
        do {
            preferencesYaml = try UniYAML.decode(yamlStr)
        } catch UniYAMLError.error(let detail) {
            print(detail)
            throw PreferencesReaderError.invalidYaml
        } catch {
            print("error: \(error)")
            throw PreferencesReaderError.invalidYaml
        }
        
        if let plansYaml = preferencesYaml["plans"], let plansArray = plansYaml.array {
            for planYaml in plansArray {
                let planDict = planYaml.dictionary!
                if let type = planDict["type"]?.string {
                    var plan: Plan
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

                    plan.name = planDict["name"]?.string
                    if let enabledYaml = planDict["enabled"]?.bool {
                        plan.enabled = enabledYaml
                    }
                    plan.exportCalculated = planDict["exportCalculated"]?.bool
                    plan.exportOriginals = planDict["exportOriginals"]?.bool

                    if let plan = plan as? FileSystemExportPlan {
                        plan.targetFolder = planDict["targetFolder"]?.string
                    }
                    
                    if let plan = plan as? IncrementalFileSystemExportPlan {
                        plan.baseExportPath = planDict["baseExportPath"]?.string
                    }

                    if let plan = plan as? SnapshotFileSystemExportPlan {
                        plan.deleteFlatPath = planDict["deleteFlatPath"]?.bool
                    }
                    
                    if let mediaObjectFilterYaml = planDict["mediaObjectFilter"] {
                        let mediaObjectFilterDict = mediaObjectFilterYaml.dictionary!
                        
                        if let mediaGroupTypeWhiteListYaml = mediaObjectFilterDict["mediaGroupTypeWhiteList"]?.array {
                            plan.mediaObjectFilter.mediaGroupTypeWhiteList = []
                            for elem in mediaGroupTypeWhiteListYaml {
                                if let str = elem.string {
                                    plan.mediaObjectFilter.mediaGroupTypeWhiteList.append(str)
                                }
                            }
                        }
                        if let keywordWhiteListYaml = mediaObjectFilterDict["keywordWhiteList"]?.array {
                            plan.mediaObjectFilter.keywordWhiteList = []
                            for elem in keywordWhiteListYaml {
                                if let str = elem.string {
                                    plan.mediaObjectFilter.keywordWhiteList.append(str)
                                }
                            }
                        }
                        if let keywordBlackListYaml = mediaObjectFilterDict["keywordBlackList"]?.array {
                            plan.mediaObjectFilter.keywordBlackList = []
                            for elem in keywordBlackListYaml {
                                if let str = elem.string {
                                    plan.mediaObjectFilter.keywordBlackList.append(str)
                                }
                            }
                        }
                    }

                    preferences.plans.append(plan)
                } else {
                    logger.warn("Plan defined without type attribute: \(String(describing: planYaml.dictionary))")
                    throw PreferencesReaderError.invalidOrNoPlanType
                }
            }
        }

        
        return preferences
    }
    
}

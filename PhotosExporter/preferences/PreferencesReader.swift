//
//  PreferencesReader.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 25.05.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

enum PreferencesReaderError: Error {
    case invalidYaml
    case invalidOrNoPlanType
    case missingRequiredAttribute
}

class PreferencesReader {
    
    private static let logger = Logger(loggerName: "PreferencesReader", logLevel: .info)
    
    static func readPreferencesFile() throws -> Preferences {
        let preferencesFolderUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("PhotosExporter")
        do {
            let preferencesFileUrl = preferencesFolderUrl.appendingPathComponent("PhotosExporter.yaml")
            let path = preferencesFileUrl.path
            if FileManager.default.fileExists(atPath: path) {
                let fileContent = try String(contentsOfFile: path)
                logger.debug("Read preferences file; content:\n\(fileContent)")
                return try preferencesFromYaml(yamlStr: fileContent)
            } else {
                logger.info("Preferences file not found")
            }
        } catch {
            logger.error("Error reading preferences file: \(error)")
            throw error
        }
        return Preferences()
    }
    
    static func writePreferencesFile(preferences: Preferences) {
        let preferencesFolderUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("PhotosExporter")
        do {
            try FileManager.default.createDirectory(at: preferencesFolderUrl, withIntermediateDirectories: true, attributes: nil)
            let preferencesFileUrl = preferencesFolderUrl.appendingPathComponent("PhotosExporter.yaml")
            let fileContent = preferences.toYaml()
            try fileContent.write(to: preferencesFileUrl, atomically: true, encoding: String.Encoding.utf8)
            logger.debug("Wrote preferences file to : \(preferencesFileUrl.path)")
        } catch {
            logger.error("Error writing preferences file: \(error)")
        }
    }

    
    static func preferencesFromYaml(yamlStr: String) throws -> Preferences {
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
                    plan.exportCurrent = planDict["exportCurrent"]?.bool
                    plan.exportOriginals = planDict["exportOriginals"]?.bool
                    plan.exportDerived = planDict["exportDerived"]?.bool

                    if let plan = plan as? FileSystemExportPlan {
                        plan.targetFolder = planDict["targetFolder"]?.string
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

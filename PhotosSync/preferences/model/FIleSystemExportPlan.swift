//
//  ExportPlan.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class FileSystemExportPlan : Plan {
    public var targetFolder: String
    public var exportCalculated: Bool?
    public var exportOriginals: Bool?
    
    init(name: String, targetFolder: String) {
        self.targetFolder = targetFolder
        super.init(name: name)
    }
    
    override func getType() -> String {
        return "FileSystemExport"
    }
    
    override func toYaml(indent: Int) -> String {
        var result: String = ""
        result += super.toYaml(indent: indent)
        result += "targetFolder: \(targetFolder)\n".indent(indent)
        if let exportCalculated = exportCalculated {
            result += "exportCalculated: \(exportCalculated)\n".indent(indent)
        }
        if let exportOriginals = exportOriginals {
            result += "exportOriginals: \(exportOriginals)\n".indent(indent)
        }
        return result
    }
}

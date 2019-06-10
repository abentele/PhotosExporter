//
//  ExportPlan.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class FileSystemExportPlan : Plan {

    public var targetFolder: String?
    
    override func toYaml(indent: Int) -> String {
        var result: String = ""
        result += super.toYaml(indent: indent)
        if let targetFolder = targetFolder {
            result += "targetFolder: \(targetFolder)\n".indent(indent)
        }
        return result
    }
    
}

class IncrementalFileSystemExportPlan : FileSystemExportPlan {

    public var baseExportPath:String?

    override func getType() -> String {
        return "IncrementalFileSystemExport"
    }
    
    override func toYaml(indent: Int) -> String {
        var result: String = ""
        result += super.toYaml(indent: indent)
        if let baseExportPath = baseExportPath {
            result += "baseExportPath: \(baseExportPath)\n".indent(indent)
        }
        return result
    }

}

class SnapshotFileSystemExportPlan : FileSystemExportPlan {

    public var deleteFlatPath: Bool?
    
    override func getType() -> String {
        return "SnapshotFileSystemExport"
    }
    
    override func toYaml(indent: Int) -> String {
        var result: String = ""
        result += super.toYaml(indent: indent)
        if let deleteFlatPath = deleteFlatPath {
            result += "deleteFlatPath: \(deleteFlatPath)\n".indent(indent)
        }
        return result
    }

}

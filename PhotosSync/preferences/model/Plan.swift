//
//  Plan.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class Plan {
    public var enabled: Bool = true
    public var name: String?

    // exports derived resources for all assets (i.e. jpeg images instead of RAW)
    public var exportDerived: Bool?

    // exports the current assets (original if unmodified, otherwise the changed resource)
    public var exportCurrent: Bool?
    
    // exports the original assets
    public var exportOriginals: Bool?
    
    
    public var mediaObjectFilter = MediaObjectFilter()

    func getType() -> String {
        return String(describing: self)
    }
    
    func toYaml(indent: Int) -> String {
        var result: String = ""
        result += "type: \(getType())\n".indent(indent)
        
        // enabled == true is the default => only write false to Yaml
        if (!enabled) {
            result += "enabled: \(enabled)\n".indent(indent)
        }
        
        if let name = name {
            result += "name: \(name)\n".indent(indent)
        }
        if let exportDerived = exportDerived {
            result += "exportDerived: \(exportDerived)\n".indent(indent)
        }
        if let exportCurrent = exportCurrent {
            result += "exportCurrent: \(exportCurrent)\n".indent(indent)
        }
        if let exportOriginals = exportOriginals {
            result += "exportOriginals: \(exportOriginals)\n".indent(indent)
        }
        result += mediaObjectFilter.toYaml(indent: indent)
        
        return result
    }
    
}

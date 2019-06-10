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
    public var exportCalculated: Bool?
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
        if let exportCalculated = exportCalculated {
            result += "exportCalculated: \(exportCalculated)\n".indent(indent)
        }
        if let exportOriginals = exportOriginals {
            result += "exportOriginals: \(exportOriginals)\n".indent(indent)
        }
        result += mediaObjectFilter.toYaml(indent: indent)
        
        return result
    }
    
}

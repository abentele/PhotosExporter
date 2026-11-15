//
//  Preferences.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

class Preferences {
    public var plans: [Plan] = []
    public var photosLibraryPath: String?
    
    func toYaml() -> String {
        var result = "---\n"
        if let photosLibraryPath = photosLibraryPath {
            result += "config:\n"
            result += "  photosLibraryPath: \(UniYAML.quote(photosLibraryPath))\n"
        }
        result += "plans:\n"
        for plan in plans {
            result += "-\n".indent(2)
            result += "\(plan.toYaml(indent: 4))"
        }
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        return result
    }
}

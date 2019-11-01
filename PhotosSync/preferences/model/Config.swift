//
//  Config.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 21.12.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class Config {
    public var photosLibraryPath: String?

    func getType() -> String {
        return String(describing: self)
    }
    
    func toYaml(indent: Int) -> String {
        var result: String = ""
        
        if let photosLibraryPath = photosLibraryPath {
            result += "photosLibraryPath: \(photosLibraryPath)\n".indent(indent)
        }
        
        return result
    }
}

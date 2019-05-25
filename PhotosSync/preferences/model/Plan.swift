//
//  Plan.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class Plan {
    public var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func getType() -> String {
        return String(describing: self)
    }
    
    func toYaml(indent: Int) -> String {
        var result: String = ""
        result += "type: \(getType())\n".indent(indent)
        result += "name: \(name)\n".indent(indent)
        return result
    }
    
}

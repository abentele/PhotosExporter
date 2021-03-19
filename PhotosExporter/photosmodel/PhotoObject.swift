//
//  PhotoObject.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 30.10.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

class PhotoObject {
    
    var localIdentifier: String?
    
    init() {
    }
    
    func printYaml(indent: Int) {
        print("-".indent(indent))
        if let localIdentifier = localIdentifier {
            print("localIdentifier: \(localIdentifier)".indent(indent + 2))
        }
    }
    
    /** identifier used in the photos SQLite database */
    func zuuid() -> String {
        let zuuid = PhotoObject.zuuid(localIdentifier: localIdentifier!)
        return zuuid
    }
    
    /** identifier used in the photos SQLite database */
    static func zuuid(localIdentifier: String) -> String {
        let zuuid = String(localIdentifier[..<localIdentifier.firstIndex(of: "/")!])
        return zuuid
    }


}

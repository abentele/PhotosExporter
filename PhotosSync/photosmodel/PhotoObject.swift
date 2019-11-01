//
//  PhotoObject.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 30.10.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
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
        let zuuid = String(localIdentifier![..<localIdentifier!.firstIndex(of: "/")!])
        return zuuid
    }

}

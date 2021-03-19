//
//  PhotoCollection.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 30.10.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

class PhotoCollection : PhotoObject {
    var name: String = ""
    var childCollections: [PhotoCollection] = [];
    var mediaObjects: [MediaObject] = []
    
    override init() {
    }

    override func printYaml(indent: Int) {
        super.printYaml(indent: indent)
        print("name: \(name)".indent(indent + 2))
        print("children:".indent(indent + 2))
        for collection in childCollections {
            collection.printYaml(indent: indent + 4)
        }
        for mediaObject in mediaObjects {
            mediaObject.printYaml(indent: indent + 4)
        }
    }
}

extension PhotoCollection: CustomStringConvertible {
    var description: String {
        return "[localIdentifier: \(String(describing: localIdentifier)), name: \(String(describing: name))]"
    }
}

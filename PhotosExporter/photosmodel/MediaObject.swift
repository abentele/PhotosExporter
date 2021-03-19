//
//  MediaObject.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 30.10.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class MediaObject : PhotoObject {
    var originalName: String?
    var originalFilename: String?
    var originalUrl: URL?
    var currentUrl: URL?
    var derivedUrl: URL?
    var creationDate: Date?
    var title: String?
    var keywords: [String] = []

    override init() {
    }
    
    override func printYaml(indent: Int) {
        super.printYaml(indent: indent);
        if let originalName = originalName {
            print("originalName: \(originalName)".indent(indent + 2))
        }
        if let originalFilename = originalFilename {
            print("originalFilename: \(originalFilename)".indent(indent + 2))
        }
        if let originalUrl = originalUrl {
            print("originalUrl: \(originalUrl)".indent(indent + 2))
        }
        if let currentUrl = currentUrl {
            print("currentUrl: \(currentUrl)".indent(indent + 2))
        }
        if let derivedUrl = derivedUrl {
            print("derivedUrl: \(derivedUrl)".indent(indent + 2))
        }
        if let creationDate = creationDate {
            print("creationDate: \(creationDate)".indent(indent + 2))
        }
        if let title = title {
            print("title: \(title)".indent(indent + 2))
        }
        print("keywords: \(keywords)".indent(indent + 2))
    }
}

extension MediaObject: CustomStringConvertible {
    var description: String {
        return "[localIdentifier: \(String(describing: localIdentifier)), originalName: \(String(describing: originalName))]"
    }
}

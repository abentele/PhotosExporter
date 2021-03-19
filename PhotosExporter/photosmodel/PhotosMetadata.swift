//
//  PhotosMetadata.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.12.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

class PhotosMetadata {
    public let rootCollection: PhotoCollection;
    public let allMediaObjects: [MediaObject]
    
    init(rootCollection: PhotoCollection, allMediaObjects: [MediaObject]) {
        self.rootCollection = rootCollection
        self.allMediaObjects = allMediaObjects
    }
}

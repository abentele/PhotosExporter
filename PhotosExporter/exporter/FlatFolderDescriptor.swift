//
//  FlatFolderDescriptor.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.03.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class FlatFolderDescriptor {
    public var folderName: String
    public var countSubFolders: Int
    
    init(folderName: String, countSubFolders: Int) {
        self.folderName = folderName
        self.countSubFolders = countSubFolders
    }
}

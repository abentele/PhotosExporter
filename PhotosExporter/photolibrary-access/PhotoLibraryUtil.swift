//
//  PhotoLibraryUtil.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 17.04.21.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

enum PhotoLibraryError: Error {
    case systemLibraryPathNotDefined
}


// implements some helper functions to access the photo library
class PhotoLibraryUtil {
    
    static private var systemPhotosLibraryPath: String?;
    
    static func getSystemPhotosLibraryPath() throws -> String {
        if let systemPhotosLibraryPath = systemPhotosLibraryPath {
            return systemPhotosLibraryPath;
        }
        
        systemPhotosLibraryPath = getSystemPhotosLibraryPathInternal()
        
        if systemPhotosLibraryPath == nil {
            throw PhotoLibraryError.systemLibraryPathNotDefined
        }

        return systemPhotosLibraryPath!
    }
    
    static func getSystemPhotosLibraryPathInternal() -> String? {
        let libraryDirectoryUrls = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        
        if libraryDirectoryUrls.count > 0 {
            let libraryDirectoryUrl = libraryDirectoryUrls[0]
            print("containerUrl: \(libraryDirectoryUrl)")
            let fileUrl = URL(fileURLWithPath: "Containers/com.apple.photolibraryd/Data/Library/Preferences/group.com.apple.photolibraryd.private.plist", relativeTo: libraryDirectoryUrl)
            print("fileUrl: \(fileUrl)")
            if let dictionary = NSDictionary(contentsOfFile: fileUrl.path) {
                return dictionary["SystemLibraryPath"] as? String
            }
        }
        
        return nil
    }
}

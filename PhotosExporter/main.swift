//
//  main.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.02.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

// define the target path (this is the root path for your backups)
let photosExporter = PhotosExporter.init(targetPath: "/Volumes/WD-4TB-EXT/Backup/fotos-export")

// define which media groups should be exported
photosExporter.exportMediaGroupFilter = { (mediaGroup: MLMediaGroup) -> Bool in
    // export all media groups
    return true
}

// define for which media groups the photos should be exported
photosExporter.exportPhotosOfMediaGroupFilter = { (mediaGroup: MLMediaGroup) -> Bool in
    return ["com.apple.Photos.Album", "com.apple.Photos.SmartAlbum", "com.apple.Photos.CollectionGroup", "com.apple.Photos.MomentGroup", "com.apple.Photos.YearGroup", "com.apple.Photos.PlacesCountryAlbum", "com.apple.Photos.PlacesProvinceAlbum", "com.apple.Photos.PlacesCityAlbum", "com.apple.Photos.PlacesPointOfInterestAlbum", "com.apple.Photos.FacesAlbum", "com.apple.Photos.VideosGroup", "com.apple.Photos.FrontCameraGroup", "com.apple.Photos.PanoramasGroup", "com.apple.Photos.BurstGroup", "com.apple.Photos.ScreenshotGroup"].contains(mediaGroup.typeIdentifier) &&
        !("com.apple.Photos.FacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.AlbumsGroup") &&
        !("com.apple.Photos.PlacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.RootGroup")
}

photosExporter.exportPhotos()

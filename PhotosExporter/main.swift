//
//  main.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.02.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

// define which media groups should be exported
let exportMediaGroupFilter = { (mediaGroup: MLMediaGroup) -> Bool in
    // export all media groups
    return true
}

// define for which media groups the photos should be exported
let exportPhotosOfMediaGroupFilter = { (mediaGroup: MLMediaGroup) -> Bool in
    return ["com.apple.Photos.Album", "com.apple.Photos.SmartAlbum", "com.apple.Photos.CollectionGroup", "com.apple.Photos.MomentGroup", "com.apple.Photos.YearGroup", "com.apple.Photos.PlacesCountryAlbum", "com.apple.Photos.PlacesProvinceAlbum", "com.apple.Photos.PlacesCityAlbum", "com.apple.Photos.PlacesPointOfInterestAlbum", "com.apple.Photos.FacesAlbum", "com.apple.Photos.VideosGroup", "com.apple.Photos.FrontCameraGroup", "com.apple.Photos.PanoramasGroup", "com.apple.Photos.BurstGroup", "com.apple.Photos.ScreenshotGroup"].contains(mediaGroup.typeIdentifier) &&
        !("com.apple.Photos.FacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.AlbumsGroup") &&
        !("com.apple.Photos.PlacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.RootGroup")
}


//////////////////////////////////////////////////////////////////////////////////////
// Export to local disk in simple export mode (snapshot folder, with hard links
// to the original files to save disk space)
//////////////////////////////////////////////////////////////////////////////////////

// define the target path (this is the root path for your backups)
let localPhotosExporter = SnapshotPhotosExporter.init(targetPath: "/Users/andreas/Pictures/Fotos Library export")
localPhotosExporter.exportMediaGroupFilter = exportMediaGroupFilter
localPhotosExporter.exportPhotosOfMediaGroupFilter = exportPhotosOfMediaGroupFilter
localPhotosExporter.exportPhotos()


//////////////////////////////////////////////////////////////////////////////////////
// Export to external disk in "time machine" mode (one folder for each export date)
//////////////////////////////////////////////////////////////////////////////////////

// define the target path (this is the root path for your backups)
let externalDiskPhotosExporter = IncrementalPhotosExporter.init(targetPath: "/Volumes/WD-4TB-EXT/Backup/Bilder/Fotos Library export")
externalDiskPhotosExporter.exportMediaGroupFilter = exportMediaGroupFilter
externalDiskPhotosExporter.exportPhotosOfMediaGroupFilter = exportPhotosOfMediaGroupFilter
externalDiskPhotosExporter.exportPhotos()

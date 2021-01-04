//
//  MediaGroupFilter.swift
//  PhotosExporter
//
//  Created by Kai Unger on 01.01.21.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

struct MediaGroupFilter
{
    func matches(_ group: MLMediaGroup) -> Bool {
        switch group.typeIdentifier {
        case MLPhotosMomentGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Moments)
        case MLPhotosCollectionGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Collections)
        case MLPhotosYearGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Years)
        case "com.apple.Photos.PlacesCountryAlbum":
            return self.photoGroups.contains(PhotoGroups.Places)
        case "com.apple.Photos.PlacesProvinceAlbum":
            return self.photoGroups.contains(PhotoGroups.Places)
        case "com.apple.Photos.PlacesCityAlbum":
            return self.photoGroups.contains(PhotoGroups.Places)
        case "com.apple.Photos.PlacesPointOfInterestAlbum":
            return self.photoGroups.contains(PhotoGroups.Places)
        case MLPhotosFacesAlbumTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Faces)
                // Photos' "Faces" album has typeIdentifier MLPhotosFacesAlbumTypeIdentifier
                // and all the faces albums of individual persons have the same identifier, too.
                // The individual faces albums are children of the "Faces" album.
                // We are only interested in the individual faces albums, thus we
                // match only the faces albums which are children of the top level "Faces" album:
                && (group.parent?.typeIdentifier == MLPhotosFacesAlbumTypeIdentifier)
        case MLPhotosVideosGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Videos)
        case MLPhotosFrontCameraGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Selfies)
        case MLPhotosPanoramasGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Panoramas)
        case MLPhotosScreenshotGroupTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Screenshots)
        case MLPhotosAlbumTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.Albums)
        case MLPhotosSmartAlbumTypeIdentifier:
            return self.photoGroups.contains(PhotoGroups.SmartAlbums)
        default:
            return false
        }
    }
    var photoGroups: [PhotoGroups]
}

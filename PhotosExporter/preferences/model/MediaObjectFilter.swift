//
//  MediaObjectFilter.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 03.06.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

let allMediaGroupTypes = [
    "com.apple.Photos.RootGroup",
    "com.apple.Photos.AllMomentsGroup",
    "com.apple.Photos.MomentGroup",
    "com.apple.Photos.AllCollectionsGroup",
    "com.apple.Photos.CollectionGroup",
    "com.apple.Photos.AllYearsGroup",
    "com.apple.Photos.YearGroup",
    "com.apple.Photos.PlacesAlbum",
    "com.apple.Photos.PlacesCountryAlbum",
    "com.apple.Photos.PlacesProvinceAlbum",
    "com.apple.Photos.PlacesCityAlbum",
    "com.apple.Photos.PlacesPointOfInterestAlbum",
    "com.apple.Photos.AlbumsGroup",
    "com.apple.Photos.FacesAlbum",
    "com.apple.Photos.VideosGroup",
    "com.apple.Photos.FrontCameraGroup",
    "com.apple.Photos.PanoramasGroup",
    "com.apple.Photos.DepthEffectGroup",
    "com.apple.Photos.BurstGroup",
    "com.apple.Photos.ScreenshotGroup",
    "com.apple.Photos.Folder",
    "com.apple.Photos.SmartAlbum",
    "com.apple.Photos.Album"
]

let defaultMediaGroupTypeWhiteList = [
    "com.apple.Photos.Album",
    "com.apple.Photos.SmartAlbum",
    "com.apple.Photos.CollectionGroup",
    "com.apple.Photos.MomentGroup",
    "com.apple.Photos.YearGroup",
    "com.apple.Photos.PlacesCountryAlbum",
    "com.apple.Photos.PlacesProvinceAlbum",
    "com.apple.Photos.PlacesCityAlbum",
    "com.apple.Photos.PlacesPointOfInterestAlbum",
    "com.apple.Photos.FacesAlbum",
    "com.apple.Photos.VideosGroup",
    "com.apple.Photos.FrontCameraGroup",
    "com.apple.Photos.PanoramasGroup",
    "com.apple.Photos.BurstGroup",
    "com.apple.Photos.ScreenshotGroup"
]

// TODO always apply this blacklist condition:
//  !("com.apple.Photos.FacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.AlbumsGroup") &&
//  !("com.apple.Photos.PlacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.RootGroup")


// empty whitelist or blacklists are ignored when filtering for photos
class MediaObjectFilter {

    var mediaGroupTypeWhiteList: [String] = defaultMediaGroupTypeWhiteList
    
    var keywordWhiteList: [String] = []
    var keywordBlackList: [String] = []
    
    func toYaml(indent: Int) -> String {
        var result: String = "mediaObjectFilter:\n".indent(indent)
        
        result += "mediaGroupTypeWhiteList:\n".indent(indent + 2)
        for elem in mediaGroupTypeWhiteList {
            result += "- \(elem)\n".indent(indent + 4)
        }
        result += "keywordWhiteList:\n".indent(indent + 2)
        for elem in keywordWhiteList {
            result += "- \(elem)\n".indent(indent + 4)
        }
        result += "keywordBlackList:\n".indent(indent + 2)
        for elem in keywordBlackList {
            result += "- \(elem)\n".indent(indent + 4)
        }

        return result
    }
    
}

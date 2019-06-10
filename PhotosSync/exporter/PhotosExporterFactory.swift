//
//  PhotosExporterFactory.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 10.06.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

enum PhotosExporterFactoryError: Error {
    case unknownType
}


class PhotosExporterFactory {
    static func createPhotosExporter(plan: Plan) throws -> PhotosExporter {
        // define which media groups should be exported
        let exportMediaGroupFilter = { (mediaGroup: MLMediaGroup) -> Bool in
            // export all media groups
            return true
        }

        let exportPhotosOfMediaGroupFilter = { (mediaGroup: MLMediaGroup) -> Bool in
            return plan.mediaObjectFilter.mediaGroupTypeWhiteList.contains(mediaGroup.typeIdentifier) &&
                !("com.apple.Photos.FacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.AlbumsGroup") &&
                !("com.apple.Photos.PlacesAlbum" == mediaGroup.typeIdentifier && mediaGroup.parent?.typeIdentifier == "com.apple.Photos.RootGroup")
        }
        
        let exportMediaObjectFilter: ((MLMediaObject) -> Bool) = { (mediaObject) -> Bool in
            var result = true
            if plan.mediaObjectFilter.keywordWhiteList.count > 0 {
                result = false
                for keyword in plan.mediaObjectFilter.keywordWhiteList {
                    if (hasKeyword(mediaObject: mediaObject, keyword: keyword)) {
                        result = true
                        break
                    }
                }
            }
            if plan.mediaObjectFilter.keywordBlackList.count > 0 {
                for keyword in plan.mediaObjectFilter.keywordWhiteList {
                    if (hasKeyword(mediaObject: mediaObject, keyword: keyword)) {
                        result = false
                        break
                    }
                }
            }
            return result
        }

        var photosExporter: PhotosExporter

        if let plan = plan as? IncrementalFileSystemExportPlan {
            // TODO existence of targetFolder must be validated
            let incrementalPhotosExporter = IncrementalPhotosExporter(targetPath: plan.targetFolder!)
            if let baseExportPath = plan.baseExportPath {
                incrementalPhotosExporter.baseExportPath = baseExportPath
            }
            photosExporter = incrementalPhotosExporter
        } else if let plan = plan as? SnapshotFileSystemExportPlan {
            // TODO existence of targetFolder must be validated
            let snapshotPhotosExporter = SnapshotPhotosExporter(targetPath: plan.targetFolder!)
            if let deleteFlatPath = plan.deleteFlatPath {
                snapshotPhotosExporter.deleteFlatPath = deleteFlatPath
            }
            photosExporter = snapshotPhotosExporter
        } else {
            throw PhotosExporterFactoryError.unknownType
        }

        photosExporter.exportMediaGroupFilter = exportMediaGroupFilter
        photosExporter.exportPhotosOfMediaGroupFilter = exportPhotosOfMediaGroupFilter
        photosExporter.exportMediaObjectFilter = exportMediaObjectFilter
        if let exportCalculated = plan.exportCalculated {
            photosExporter.exportCalculated = exportCalculated
        }
        if let exportOriginals = plan.exportOriginals {
            photosExporter.exportOriginals = exportOriginals
        }
        
        return photosExporter
    }
}

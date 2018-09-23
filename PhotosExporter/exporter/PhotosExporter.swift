//
//  image.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 04.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary


enum PhotosExporterError: Error {
    case noMediaObjects
}

class Statistics {
    private let logger = Logger(loggerName: "PhotosExporter", logLevel: .info)

    var countCopiedFiles = 0
    var countLinkedFiles = 0
    
    func print() {
        logger.info("Statistics: copied files: \(countCopiedFiles); linked files: \(countLinkedFiles)")
    }
}

class PhotosExporter {
    
    let logger = Logger(loggerName: "PhotosExporter", logLevel: .info)

    private static var rootMediaGroup: MLMediaGroup?
    var exportMediaGroupFilter: ((MLMediaGroup) -> Bool) = { (MLMediaGroup) -> Bool in
        return true
    }
    var exportPhotosOfMediaGroupFilter: ((MLMediaGroup) -> Bool) = { (MLMediaGroup) -> Bool in
        return true
    }
    var exportMediaObjectFilter: ((MLMediaObject) -> Bool) = { (MLMediaObject) -> Bool in
        return true
    }
    
    // set to true if calculated photos should be exported
    var exportCalculated = true
    // set to true if original photos should be exported
    var exportOriginals = true

    let fileManager = FileManager.default

    // paths
    var targetPath: String
    var inProgressPath: String {
        return "\(targetPath)/InProgress"
    }
    var originalsRelativePath = "Originals"
    var calculatedRelativePath = "Calculated"
    var flatRelativePath = "_flat"
    
    private static var metadataReader: MetadataLoader?
    
    var statistics = Statistics()

    init(targetPath: String) {
        self.targetPath = targetPath
    }
    
    func exportPhotos() {
        if !fileManager.fileExists(atPath: targetPath) {
            logger.error("The folder at targetPath=\(targetPath) doesn't exist. Create it before running the PhotosExporter.")
            return
        }
        
        do {
            // initialize metadata only once to static member, to be able to use multiple instances of PhotosExporter without loading the metadata multiple times
            if PhotosExporter.rootMediaGroup == nil {
                PhotosExporter.rootMediaGroup = MetadataLoader().loadMetadata()
            }
            
            let mediaObjects = PhotosExporter.rootMediaGroup!.mediaObjects
            if (mediaObjects == nil || mediaObjects!.count == 0) {
                throw PhotosExporterError.noMediaObjects
            }
            
            logger.info("Start export to \(targetPath)")

            try doExport()

            logger.info("Finished export to \(targetPath)")
        } catch {
            logger.error("Error occured: \(error) => abort export")
        }
    }
    
    private func doExport() throws {
        try initExport()

        try exportFoldersFlat()
        
        if exportOriginals {
            logger.info("export originals albums folders")
            try exportFoldersRecursive(
                mediaGroup: PhotosExporter.rootMediaGroup!,
                flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
                targetPath: "\(inProgressPath)/\(originalsRelativePath)/\(PhotosExporter.rootMediaGroup!.name!)",
                exportOriginals: true)
            
        }
        if exportCalculated {
            logger.info("export calculated albums folders")
            try exportFoldersRecursive(
                mediaGroup: PhotosExporter.rootMediaGroup!,
                flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
                targetPath: "\(inProgressPath)/\(calculatedRelativePath)/\(PhotosExporter.rootMediaGroup!.name!)",
                exportOriginals: false)
        }
        
        try finishExport()
        
        statistics.print()
    }
    
    func initExport() throws {
        try recreateInProgressFolder()
    }
    
    func exportFoldersFlat() throws {
        // override function
    }
    
    private func recreateInProgressFolder() throws {
        do {
            if fileManager.fileExists(atPath: inProgressPath) {
                logger.info("Delete folder: \(inProgressPath)")
                for (retryCounter, _) in [0...2].enumerated() {
                    do {
                        try fileManager.removeItem(atPath: inProgressPath)
                    } catch {
                        if retryCounter == 2 {
                            throw error
                        }
                    }
                }
            }
            try fileManager.createDirectory(atPath: inProgressPath, withIntermediateDirectories: true)
        } catch {
            logger.error("Error recreating folder \(inProgressPath)")
            throw error
        }
    }
    
    /**
     * Finish the filesystem structures; invariant:
     * if no folder "InProgress" but folders with date exist, and there is a symbolic link "Latest", there was no error.
     */
    func finishExport() throws {
        logger.info("Finish export")
    }
    
    private func sourceUrlOfMediaObject(mediaObject: MLMediaObject, exportOriginals: Bool) -> URL? {
        var sourceUrl: URL?
        if (exportOriginals) {
            if let originalUrl = mediaObject.originalURL {
                sourceUrl = originalUrl
            } else if let url = mediaObject.url {
                sourceUrl = url
            }
        } else {
            if let url = mediaObject.url {
                sourceUrl = url
            }
        }
        return sourceUrl
    }
    
    private func getLinkToUrl(candidatesToLinkTo: [String], mediaObject: MLMediaObject, sourceUrl: URL) throws -> URL? {
        for candidateToLinkTo in candidatesToLinkTo {
            let candidateToLinkToUrl = URL.init(fileURLWithPath: "\(candidateToLinkTo)/\(mediaObject.identifier).\(sourceUrl.pathExtension)")
            if fileManager.fileExists(atPath: candidateToLinkToUrl.path) {
                // only minimal file comparison by file size for performance reasons! (this is sufficient for originals, and for important changes of calculated images; may not be sufficient for changes of image and video headers, which can have static sizes)
                let stopWatch = StopWatch("check file size")
                let candidateToLinkToAttributes = try fileManager.attributesOfItem(atPath: candidateToLinkToUrl.path)
                let sourceAttributes = try fileManager.attributesOfItem(atPath: sourceUrl.path)
                let candidateToLinkToFileSize = candidateToLinkToAttributes[FileAttributeKey.size] as! UInt64
                let sourceFileSize = sourceAttributes[FileAttributeKey.size] as! UInt64
                stopWatch.stop()
                if (candidateToLinkToFileSize == sourceFileSize) {
                    return candidateToLinkToUrl
                } else {
                    logger.debug("file size comparing to latest different => copy")
                }
            }
        }
        return nil
    }
    
    func exportFolderFlat(flatPath: String, candidatesToLinkTo: [String], exportOriginals: Bool) throws {
        var containsFotosToExport = false;
        let mediaObjects = PhotosExporter.rootMediaGroup!.mediaObjects!
        for mediaObject in mediaObjects {
            if exportMediaObjectFilter(mediaObject) {
                containsFotosToExport = true
                break
            }
        }
        
        if containsFotosToExport {
            do {
                try fileManager.createDirectory(atPath: flatPath, withIntermediateDirectories: true)
            }
            catch let error as NSError {
                logger.error("Unable to create directory \(flatPath): \(error)")
                throw error
            }
            
            var index = 1
            for mediaObject in mediaObjects {
                if exportMediaObjectFilter(mediaObject) {
                    // autorelease periodically
                    try autoreleasepool {
                        let sourceUrl = sourceUrlOfMediaObject(mediaObject: mediaObject, exportOriginals: exportOriginals)
                        
                        if let sourceUrl = sourceUrl {
                            let targetUrl = URL.init(fileURLWithPath: "\(flatPath)/\(mediaObject.identifier).\(sourceUrl.pathExtension)")
                            if !fileManager.fileExists(atPath: targetUrl.path) {
                                let linkToUrl = try getLinkToUrl(candidatesToLinkTo: candidatesToLinkTo, mediaObject: mediaObject, sourceUrl: sourceUrl)
                                
                                if let linkToUrl = linkToUrl {
                                    logger.debug("\(index): link unchanged image: \(sourceUrl); link to: \(linkToUrl)")
                                    do {
                                        let stopWatch = StopWatch("fileManager.linkItem")
                                        try fileManager.linkItem(at: linkToUrl, to: targetUrl)
                                        statistics.countLinkedFiles += 1
                                        stopWatch.stop()
                                    }
                                    catch let error as NSError {
                                        logger.error("\(index): Unable to link file: \(error)")
                                        throw error
                                    }
                                } else {
                                    try copyOrLinkFileInPhotosLibrary(sourceUrl: sourceUrl, targetUrl: targetUrl)
                                    
                                    let fotoDateAsTimerInterval = mediaObject.attributes["DateAsTimerInterval"] as! TimeInterval
                                    let fotoDate = Date(timeIntervalSinceReferenceDate: fotoDateAsTimerInterval)
                                    let attributes = [FileAttributeKey.modificationDate : fotoDate]
                                    let stopWatch = StopWatch("fileManager.setAttributes")
                                    do {
                                        try fileManager.setAttributes(attributes, ofItemAtPath: targetUrl.path)
                                    }
                                    catch let error as NSError {
                                        logger.error("\(index): Unable to set attributes on file: \(error)")
                                        throw error
                                    }
                                    stopWatch.stop()
                                }
                            }
                        }
                        else {
                            logger.warn("mediaObject has no url")
                        }
                    }
                }

                index += 1
            }
        }
    }
    
    func copyOrLinkFileInPhotosLibrary(sourceUrl: URL, targetUrl: URL) throws {
        // default operation: copy
        logger.info("copy image: \(sourceUrl) to \(targetUrl.lastPathComponent)")
        do {
            let stopWatch = StopWatch("fileManager.copyItem")
            try fileManager.copyItem(at: sourceUrl, to: targetUrl)
            statistics.countCopiedFiles += 1
            stopWatch.stop()
        }
        catch let error as NSError {
            logger.error("\(index): Unable to copy file: \(error)")
            throw error
        }
    }
    
    private func exportFoldersRecursive(mediaGroup: MLMediaGroup, flatPath: String, targetPath: String, exportOriginals: Bool) throws {
        // autorelease periodically
        try autoreleasepool {
            if exportMediaGroupFilter(mediaGroup) {
                var containsFotosToExport = false;
                if exportPhotosOfMediaGroupFilter(mediaGroup) {
                    for mediaObject in mediaGroup.mediaObjects! {
                        if exportMediaObjectFilter(mediaObject) {
                            containsFotosToExport = true
                            break
                        }
                    }
                }

                if containsFotosToExport {
                    // create folder at targetPath
                    do {
                        logger.debug("Create folder: \(targetPath)")
                        try fileManager.createDirectory(atPath: targetPath, withIntermediateDirectories: true)
                    } catch {
                        logger.error("Error recreating folder \(targetPath)")
                        throw error
                    }
                    
                    if exportPhotosOfMediaGroupFilter(mediaGroup) {
                        for mediaObject in mediaGroup.mediaObjects! {
                            if exportMediaObjectFilter(mediaObject) {
                                try exportFoto(mediaObject: mediaObject, flatPath: flatPath, targetPath: targetPath, exportOriginals: exportOriginals)
                            }
                        }
                    }
                }
                
                for childMediaGroup in mediaGroup.childGroups! {
                    var childTargetPath: String = "\(targetPath)/\(childMediaGroup.name!)"
                    if childMediaGroup.typeIdentifier == "com.apple.Photos.SmartAlbum" {
                        childTargetPath = "\(childTargetPath) (Smart album)"
                    }
                    try exportFoldersRecursive(mediaGroup: childMediaGroup, flatPath: flatPath, targetPath: childTargetPath, exportOriginals: exportOriginals)
                }
                
                
            }
        }
    }
    
    private func exportFoto(mediaObject: MLMediaObject, flatPath: String, targetPath: String, exportOriginals: Bool) throws {
        let sourceUrl = sourceUrlOfMediaObject(mediaObject: mediaObject, exportOriginals: exportOriginals)
        if let sourceUrl = sourceUrl {
            let linkTargetUrl = URL.init(fileURLWithPath: "\(flatPath)/\(mediaObject.identifier).\(sourceUrl.pathExtension)")
            
            // get unique target name
            let fotoName = getFotoName(mediaObject: mediaObject, sourceUrl: sourceUrl)
            var targetUrl = URL.init(fileURLWithPath: "\(targetPath)/\(fotoName).\(sourceUrl.pathExtension)")
            logger.debug("Export foto: \(fotoName) to \(targetUrl)")
            var i = 1
            while fileManager.fileExists(atPath: targetUrl.path) {
                targetUrl = URL.init(fileURLWithPath: "\(targetPath)/\(fotoName) (\(i)).\(sourceUrl.pathExtension)")
                i += 1
            }
            
            logger.debug("link image: \(targetUrl.lastPathComponent)")
            let stopWatch = StopWatch("fileManager.linkItem")
            try fileManager.linkItem(at: linkTargetUrl, to: targetUrl)
            statistics.countLinkedFiles += 1
            stopWatch.stop()
        } else {
            logger.warn("Source URL of mediaObject unknown: \(mediaObject.name!)")
        }
    }
    
    private func getFotoName(mediaObject: MLMediaObject, sourceUrl: URL) -> String {
        var fotoName = ""
        if let name = mediaObject.name {
            fotoName = name
        } else {
            fotoName = sourceUrl.lastPathComponent
        }
        
        // remove extension if exists
        if fotoName.hasSuffix("." + sourceUrl.pathExtension) {
            fotoName = String(fotoName.prefix(upTo: fotoName.index(fotoName.endIndex, offsetBy: -sourceUrl.pathExtension.count-1)))
        }
        
        // ignore filenames generated by Photos
        if fotoName.hasPrefix("fullsizeoutput_") {
            fotoName = ""
        }

        if !hasKeyword(mediaObject: mediaObject, keyword: "export-no-date") {
            
            // get date of foto
            let fotoDateAsTimerInterval = mediaObject.attributes["DateAsTimerInterval"] as! TimeInterval
            let fotoDate = Date(timeIntervalSinceReferenceDate: fotoDateAsTimerInterval)
            
            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let dateTime1 = dateFormatter1.string(from: fotoDate)
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let dateTime2 = dateFormatter2.string(from: fotoDate)
            
            if fotoName.starts(with: dateTime1) || fotoName.starts(with: dateTime2) {
                fotoName = String(fotoName.suffix(from: fotoName.index(fotoName.startIndex, offsetBy: dateTime1.count)))
            }

            if fotoName.count > 0 {
                fotoName = "\(dateTime2) \(fotoName)"
            } else {
                fotoName = dateTime2
            }
        }
        
        return fotoName
    }
    
}





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
    
    private let logger = Logger(loggerName: "PhotosExporter", logLevel: .info)

    var rootMediaGroup: MLMediaGroup!
    var exportMediaGroupFilter: ((MLMediaGroup) -> Bool) = { (MLMediaGroup) -> Bool in
        return true
    }
    var exportPhotosOfMediaGroupFilter: ((MLMediaGroup) -> Bool) = { (MLMediaGroup) -> Bool in
        return true
    }
    
    private let fileManager = FileManager.default

    // paths
    private var targetPath: String
    private var inProgressPath: String {
        return "\(targetPath)/InProgress"
    }
    private var latestPath: String {
        return "\(targetPath)/Latest"
    }
    private var originalsRelativePath = "Originals"
    private var calculatedRelativePath = "Calculated"
    private var flatRelativePath = "_flat"
    
    private var statistics = Statistics()

    init(targetPath: String) {
        self.targetPath = targetPath
    }
    
    func exportPhotos() {
        if !fileManager.fileExists(atPath: targetPath) {
            logger.error("The folder at targetPath=\(targetPath) doesn't exist. Create it before running the PhotosExporter.")
            return
        }
        
        do {
            let metadataReader = MetadataLoader()
            self.rootMediaGroup = metadataReader.loadMetadata()
            
            let mediaObjects = self.rootMediaGroup.mediaObjects
            if (mediaObjects == nil || mediaObjects!.count == 0) {
                throw PhotosExporterError.noMediaObjects
            }
            
            logger.info("Start export")

            try doExport()

            logger.info("Finished export")
        } catch {
            logger.error("Error occured: \(error) => abort export")
        }
    }
    
    private func doExport() throws {
        try recreateInProgressFolder()

        logger.info("export originals photos to _flat folder")
        try exportFolderFlat(
            flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
            candidatesToLinkTo: ["\(latestPath)/\(originalsRelativePath)/\(flatRelativePath)"],
            exportOriginals: true)
        
        logger.info("export calculated photos to _flat folder")
        try exportFolderFlat(
            flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
            candidatesToLinkTo: ["\(latestPath)/\(calculatedRelativePath)/\(flatRelativePath)", "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)"],
            exportOriginals: false)

        logger.info("export originals albums folders")
        try exportFoldersRecursive(
            mediaGroup: self.rootMediaGroup,
            flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
            targetPath: "\(inProgressPath)/\(originalsRelativePath)/\(self.rootMediaGroup.name!)",
            exportOriginals: true)
        
        logger.info("export calculated albums folders")
        try exportFoldersRecursive(
            mediaGroup: self.rootMediaGroup,
            flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
            targetPath: "\(inProgressPath)/\(calculatedRelativePath)/\(self.rootMediaGroup.name!)",
            exportOriginals: false)

        try finishExport()
        
        statistics.print()
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
    private func finishExport() throws {
        logger.info("Finish export")
        
        // remove the "Latest" symbolic link
        do {
            if fileManager.fileExists(atPath: latestPath) {
                try fileManager.removeItem(atPath: latestPath)
            }
        } catch {
            logger.error("Error removing link 'Latest': \(error) => abort export")
            throw error
        }

        // rename "InProgress" folder to export date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let formattedDate = dateFormatter.string(from: Date())
        let newBackupPath = "\(targetPath)/\(formattedDate)"
        do {
            try fileManager.moveItem(atPath: inProgressPath, toPath: newBackupPath)
        } catch {
            logger.error("Error renaming InProgress folder: \(error) => abort export")
            throw error
        }
        
        // create new "Latest" symbolic link
        do {
            try fileManager.createSymbolicLink(atPath: latestPath, withDestinationPath: newBackupPath)
        } catch {
            logger.error("Error recreating link 'Latest': \(error) => abort export")
            throw error
        }
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
    
    private func exportFolderFlat(flatPath: String, candidatesToLinkTo: [String], exportOriginals: Bool) throws {
        do {
            try fileManager.createDirectory(atPath: flatPath, withIntermediateDirectories: true)
        }
        catch let error as NSError {
            logger.error("Unable to create directory \(flatPath): \(error)")
            throw error
        }
        
        var index = 1
        let mediaObjects = self.rootMediaGroup.mediaObjects!
        for mediaObject in mediaObjects {
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
                            if try filesAreOnSameDevice(path1: sourceUrl.path, path2: flatPath) {
                                logger.debug("\(index): link image: \(sourceUrl) to \(targetUrl.lastPathComponent)")
                                do {
                                    let stopWatch = StopWatch("fileManager.linkItem")
                                    try fileManager.linkItem(at: sourceUrl, to: targetUrl)
                                    statistics.countLinkedFiles += 1
                                    stopWatch.stop()
                                }
                                catch let error as NSError {
                                    logger.error("\(index): Unable to link file: \(error)")
                                    throw error
                                }
                            } else {
                                logger.info("\(index): copy image: \(sourceUrl) to \(targetUrl.lastPathComponent)")
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

            index += 1
        }
    }
    
    private func filesAreOnSameDevice(path1: String, path2: String) throws -> Bool {
        let attributes1 = try fileManager.attributesOfItem(atPath: path1)
        let attributes2 = try fileManager.attributesOfItem(atPath: path2)
        let deviceIdentifier1 = attributes1[FileAttributeKey.systemNumber]
        let deviceIdentifier2 = attributes2[FileAttributeKey.systemNumber]
        if deviceIdentifier1 != nil && deviceIdentifier2 != nil {
            if (deviceIdentifier1 as! NSNumber) == (deviceIdentifier2 as! NSNumber) {
                return true
            }
        }
        return false
    }
    
    private func exportFoldersRecursive(mediaGroup: MLMediaGroup, flatPath: String, targetPath: String, exportOriginals: Bool) throws {
        // autorelease periodically
        try autoreleasepool {
            if exportMediaGroupFilter(mediaGroup) {
                // create folder at targetPath
                do {
                    logger.debug("Create folder: \(targetPath)")
                    try fileManager.createDirectory(atPath: targetPath, withIntermediateDirectories: true)
                } catch {
                    logger.error("Error recreating folder \(targetPath)")
                    throw error
                }
                
                for childMediaGroup in mediaGroup.childGroups! {
                    var childTargetPath: String = "\(targetPath)/\(childMediaGroup.name!)"
                    if childMediaGroup.typeIdentifier == "com.apple.Photos.SmartAlbum" {
                        childTargetPath = "\(childTargetPath) (Smart album)"
                    }
                    try exportFoldersRecursive(mediaGroup: childMediaGroup, flatPath: flatPath, targetPath: childTargetPath, exportOriginals: exportOriginals)
                }
                
                if exportPhotosOfMediaGroupFilter(mediaGroup) {
                    for mediaObject in mediaGroup.mediaObjects! {
                        try exportFoto(mediaObject: mediaObject, flatPath: flatPath, targetPath: targetPath, exportOriginals: exportOriginals)
                    }
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

        // get keywords
        var keywords: [String.SubSequence] = []
        if let keywordAttribute = mediaObject.attributes["keywordNamesAsString"] {
            let keywordsStr = keywordAttribute as! String
            keywords = keywordsStr.split(separator: ",")
        }
        if !keywords.contains("export-no-date") {
            
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


//
//  image.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 04.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

func debugMediaGroups(group: MLMediaGroup, logger: Logger, depth: Int = 0)
{
    let message : String = String(repeating: "\t", count: depth) +
        "\(group.typeIdentifier) " +
        "\"\(group.name ?? "<no name>")\" " +
        "\(group.mediaObjects?.count ?? 0) object(s)"
    logger.debug(message)
    
    for childGroup in group.childGroups! {
        debugMediaGroups(group: childGroup, logger: logger, depth: depth + 1)
    }
}

enum PhotosExporterError: Error {
    case noMediaObjects
}

class Statistics {
    private let logger = Logger(loggerName: "PhotosExporter", logLevel: .info)
    
    private var _countCopiedFiles: UInt64 = 0
    private var _countLinkedFiles: UInt64 = 0

    var countCopiedFiles: UInt64 {
        get {
            return _countCopiedFiles
        }
        set(newValue) {
            _countCopiedFiles = newValue
            if _countCopiedFiles % 100 == 0 {
                print()
            }
        }
    }
    var countLinkedFiles: UInt64 {
        get {
            return _countLinkedFiles
        }
        set(newValue) {
            _countLinkedFiles = newValue
            if _countLinkedFiles % 1000 == 0 {
                print()
            }
        }
    }
    
    func print() {
        logger.info("Statistics: copied files: \(countCopiedFiles); linked files: \(countLinkedFiles)")
    }
}

class PhotosExporter {
    
    public let logger = Logger(loggerName: "PhotosExporter", logLevel: .info)

    private var mediaGroupFilter: MediaGroupFilter
    private static var rootMediaGroup: MLMediaGroup?
    var exportMediaGroupFilter: ((MLMediaGroup) -> Bool) = { (MLMediaGroup) -> Bool in
        return true
    }
    func exportPhotosOfMediaGroupFilter(_ group: MLMediaGroup) -> Bool {
        return self.mediaGroupFilter.matches(group)
    }
    var exportMediaObjectFilter: ((MLMediaObject) -> Bool) = { (MLMediaObject) -> Bool in
        return true
    }
    
    /**
     * Count of subfolders in the .flat folder; if > 0, subfolders .flat/0, .flat/1, .flat/2, ..., .flat/{countSubFolders-1} are created, and files are equally distributed to those folders, instead of saving them directly to the .flat folder.
     * This feature is to reduce the amount of files in a single folder which could decrease the performance.
     * If set to 0, no subfolders are used.
     * The value can be simply changed for subsequent incremental backups.
     */
    var countSubFolders: Int = 0
    
    // set to true if calculated photos should be exported
    var exportCalculated = true
    // set to true if original photos should be exported
    var exportOriginals = true
    // set to true if folders for collections, moments and albums should be created
    var exportMediaGroupsAsFolders: Bool = true

    let fileManager = FileManager.default

    // paths
    var targetPath: String
    var inProgressPath: String {
        return "\(targetPath)/InProgress"
    }
    var originalsRelativePath = "Originals"
    var calculatedRelativePath = "Calculated"
    var flatRelativePath = ".flat"
    
    private static var metadataReader: MetadataLoader?
    
    var statistics = Statistics()

    init(exporterConfig: ExporterConfig) {
        self.mediaGroupFilter = MediaGroupFilter(photoGroups: exporterConfig.groupsToExport)
        self.targetPath = exporterConfig.targetPath
        self.exportCalculated = exporterConfig.exportCalculated
        self.exportOriginals = exporterConfig.exportOriginals
        self.logger.logLevel = exporterConfig.logLevel
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
            
            debugMediaGroups(group: PhotosExporter.rootMediaGroup!, logger: logger)
            
            let mediaObjects = PhotosExporter.rootMediaGroup!.mediaObjects
            if (mediaObjects == nil || mediaObjects!.count == 0) {
                throw PhotosExporterError.noMediaObjects
            }
            
            // use a subfolder for max. ~6000 files
            self.countSubFolders = Int(mediaObjects!.count / 6000)
            logger.debug("countSubFolders: \(countSubFolders)")
            
            // separator for multiple export jobs
            logger.info("")
            logger.info("==================================================")
            logger.info("")
            
            let stopWatch = StopWatch("Export to \(targetPath)", LogLevel.debug, addFileSizes: false)
            logger.info("Start export to \(targetPath)")
            if !mediaGroupFilter.photoGroups.isEmpty {
                logger.info("    Including groups/albums \(mediaGroupFilter.photoGroups)")
            }
            stopWatch.start()

            try doExport()

            stopWatch.stop()
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
                targetPath: "\(inProgressPath)/\(originalsRelativePath)/\(escapeFileName(PhotosExporter.rootMediaGroup!.name!))",
                exportOriginals: true)
            
        }
        if exportCalculated {
            logger.info("export calculated albums folders")
            try exportFoldersRecursive(
                mediaGroup: PhotosExporter.rootMediaGroup!,
                flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
                targetPath: "\(inProgressPath)/\(calculatedRelativePath)/\(escapeFileName(PhotosExporter.rootMediaGroup!.name!))",
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
    
    let stopWatchCheckFileSize = StopWatch("check file size", LogLevel.info, addFileSizes: false)

    private func getLinkToUrl(candidatesToLinkTo: [FlatFolderDescriptor], mediaObject: MLMediaObject, sourceUrl: URL) throws -> URL? {
        for candidateToLinkTo in candidatesToLinkTo {
            let candidateToLinkToUrl = URL.init(fileURLWithPath: getFlatPath(candidateToLinkTo, mediaObject, pathExtension: sourceUrl.pathExtension))
            if fileManager.fileExists(atPath: candidateToLinkToUrl.path) {
                // only minimal file comparison by file size for performance reasons! (this is sufficient for originals, and for important changes of calculated images; may not be sufficient for changes of image and video headers, which can have static sizes)
                stopWatchCheckFileSize.start()
                let candidateToLinkToAttributes = try fileManager.attributesOfItem(atPath: candidateToLinkToUrl.path)
                let sourceAttributes = try fileManager.attributesOfItem(atPath: sourceUrl.path)
                let candidateToLinkToFileSize = candidateToLinkToAttributes[FileAttributeKey.size] as! UInt64
                let sourceFileSize = sourceAttributes[FileAttributeKey.size] as! UInt64
                stopWatchCheckFileSize.stop()
                if (candidateToLinkToFileSize == sourceFileSize) {
                    return candidateToLinkToUrl
                } else {
                    logger.debug("file size comparing to latest different => copy")
                }
            }
        }
        return nil
    }
    
    let stopWatchCopyMediaObject = StopWatch("copy mediaObject", LogLevel.info, addFileSizes: false)
    let stopWatchExportFolderFlatScanMediaObjects = StopWatch("scan mediaObjects", LogLevel.info, addFileSizes: false)
    let stopWatchFileManagerLinkItem = StopWatch("fileManager.linkItem", LogLevel.info, addFileSizes: false)
    let stopWatchFileManagerSetAttributes = StopWatch("fileManager.setAttributes", LogLevel.info, addFileSizes: false)
    let stopWatchMediaObjectIteration = StopWatch("for mediaObject in mediaObjects", LogLevel.info, addFileSizes: false)

    func exportFolderFlat(flatPath: String, candidatesToLinkTo: [FlatFolderDescriptor], exportOriginals: Bool) throws {
        var containsFotosToExport = false;
        let mediaObjects = PhotosExporter.rootMediaGroup!.mediaObjects!
        stopWatchExportFolderFlatScanMediaObjects.start()
        for mediaObject in mediaObjects {
            if exportMediaObjectFilter(mediaObject) {
                containsFotosToExport = true
                break
            }
        }
        stopWatchExportFolderFlatScanMediaObjects.stop()
        
        if containsFotosToExport {
            do {
                try fileManager.createDirectory(atPath: flatPath, withIntermediateDirectories: true)
                if countSubFolders > 0 {
                    for i in 0...countSubFolders-1 {
                        try fileManager.createDirectory(atPath: "\(flatPath)/\(i)", withIntermediateDirectories: true)
                    }
                }
            }
            catch let error as NSError {
                logger.error("Unable to create directory \(flatPath): \(error)")
                throw error
            }
            
            var index = 1
            stopWatchMediaObjectIteration.start()
            for mediaObject in mediaObjects {
                stopWatchMediaObjectIteration.stop()

                if exportMediaObjectFilter(mediaObject) {
                    stopWatchCopyMediaObject.start()

                    // autorelease periodically
                    try autoreleasepool {
                        let sourceUrl = sourceUrlOfMediaObject(mediaObject: mediaObject, exportOriginals: exportOriginals)
                        
                        if let sourceUrl = sourceUrl {
                            let targetUrl = URL.init(fileURLWithPath: getFlatPath(FlatFolderDescriptor(folderName: flatPath, countSubFolders: countSubFolders), mediaObject, pathExtension: sourceUrl.pathExtension))
                            if !fileManager.fileExists(atPath: targetUrl.path) {
                                let linkToUrl = try getLinkToUrl(candidatesToLinkTo: candidatesToLinkTo, mediaObject: mediaObject, sourceUrl: sourceUrl)
                                
                                if let linkToUrl = linkToUrl {
                                    logger.debug("\(index): link unchanged image: \(sourceUrl); link to: \(linkToUrl)")
                                    do {
                                        stopWatchFileManagerLinkItem.start()
                                        try fileManager.linkItem(at: linkToUrl, to: targetUrl)
                                        statistics.countLinkedFiles += 1
                                        stopWatchFileManagerLinkItem.stop()
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
                                    stopWatchFileManagerSetAttributes.start()
                                    do {
                                        try fileManager.setAttributes(attributes, ofItemAtPath: targetUrl.path)
                                    }
                                    catch let error as NSError {
                                        logger.error("\(index): Unable to set attributes on file: \(error)")
                                        throw error
                                    }
                                    stopWatchFileManagerSetAttributes.stop()
                                }
                            }
                        }
                        else {
                            logger.warn("mediaObject has no url")
                        }
                    }
                    
                    stopWatchCopyMediaObject.stop()
                }

                index += 1
            }
            
            stopWatchCopyMediaObject.stop()
        }
    }
    
    let stopWatchCopyOrLinkFileInPhotosLibrary = StopWatch("fileManager.copyItem", LogLevel.info, addFileSizes: true)

    func copyOrLinkFileInPhotosLibrary(sourceUrl: URL, targetUrl: URL) throws {
        // default operation: copy
        logger.debug("copy image: \(sourceUrl) to \(targetUrl.lastPathComponent)")
        do {
            stopWatchCopyOrLinkFileInPhotosLibrary.start(fileSizeFn: {() throws -> UInt64 in
                let attributes = try fileManager.attributesOfItem(atPath: sourceUrl.path)
                let fileSize = attributes[FileAttributeKey.size] as! UInt64
                return fileSize
            })
            try fileManager.copyItem(at: sourceUrl, to: targetUrl)
            statistics.countCopiedFiles += 1
            stopWatchCopyOrLinkFileInPhotosLibrary.stop()
        }
        catch let error as NSError {
            logger.error("\(String(describing: index)): Unable to copy file: \(error)")
            throw error
        }
    }
    
    private func exportFoldersRecursive(mediaGroup: MLMediaGroup, flatPath: String, targetPath: String, exportOriginals: Bool) throws {
        let flatFolder = FlatFolderDescriptor(folderName: flatPath, countSubFolders: countSubFolders)
        
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
                    logger.debug("Exporting folder: \(targetPath)")
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
                                try exportFoto(mediaObject: mediaObject, flatFolder: flatFolder, targetPath: targetPath, exportOriginals: exportOriginals)
                            }
                        }
                    }
                }
                
                for childMediaGroup in mediaGroup.childGroups! {
                    var childTargetPath: String = "\(targetPath)/\(escapeFileName(childMediaGroup.name!))"
                    if childMediaGroup.typeIdentifier == MLPhotosSmartAlbumTypeIdentifier {
                        childTargetPath = "\(childTargetPath) (Smart album)"
                    }
                    try exportFoldersRecursive(mediaGroup: childMediaGroup, flatPath: flatPath, targetPath: childTargetPath, exportOriginals: exportOriginals)
                }
                
                
            }
        }
    }
    
    private func exportFoto(mediaObject: MLMediaObject, flatFolder: FlatFolderDescriptor, targetPath: String, exportOriginals: Bool) throws {
        let sourceUrl = sourceUrlOfMediaObject(mediaObject: mediaObject, exportOriginals: exportOriginals)
        if let sourceUrl = sourceUrl {
            let linkTargetUrl = URL.init(fileURLWithPath: getFlatPath(flatFolder, mediaObject, pathExtension: sourceUrl.pathExtension))
            
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
            stopWatchFileManagerLinkItem.start()
            try fileManager.linkItem(at: linkTargetUrl, to: targetUrl)
            statistics.countLinkedFiles += 1
            stopWatchFileManagerLinkItem.stop()
        } else {
            logger.warn("Source URL of mediaObject unknown: \(mediaObject.name!)")
        }
    }
    
    private func getFlatPath(_ flatPath: FlatFolderDescriptor, _ mediaObject: MLMediaObject, pathExtension: String) -> String {
        if flatPath.countSubFolders > 0 {
            return "\(flatPath.folderName)/\(abs(mediaObject.identifier.djb2hash) % flatPath.countSubFolders)/\(mediaObject.identifier).\(pathExtension)"
        } else {
            return "\(flatPath.folderName)/\(mediaObject.identifier).\(pathExtension)"
        }
    }
    
    private func getFotoName(mediaObject: MLMediaObject, sourceUrl: URL) -> String {
        let exportNoDate = hasKeyword(mediaObject: mediaObject, keyword: "export-no-date")
        
        var fotoName = ""
        if let name = mediaObject.name {
            fotoName = name
        } else if (exportNoDate) {
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
        
        fotoName = escapeFileName(fotoName)

        if !exportNoDate {
            
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
    
    private func escapeFileName(_ fileName: String) -> String {
        return fileName.replacingOccurrences(of: "/", with: ", ")
    }

    
}





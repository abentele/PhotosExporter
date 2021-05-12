//
//  image.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 04.03.18.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary


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

enum PhotoVersion {
    case derived
    case current
    case originals
}

class PhotosExporter {
    
    public let logger = Logger(loggerName: "PhotosExporter", logLevel: .info)
    
    var exportMediaGroupFilter: ((PhotoCollection) -> Bool) = { (PhotoCollection) -> Bool in
        return true
    }
    var exportPhotosOfMediaGroupFilter: ((PhotoCollection) -> Bool) = { (PhotoCollection) -> Bool in
        return true
    }
    var exportMediaObjectFilter: ((MediaObject) -> Bool) = { (MediaObject) -> Bool in
        return true
    }
    
    /**
     * Count of subfolders in the .flat folder; if > 0, subfolders .flat/0, .flat/1, .flat/2, ..., .flat/{countSubFolders-1} are created, and files are equally distributed to those folders, instead of saving them directly to the .flat folder.
     * This feature is to reduce the amount of files in a single folder which could decrease the performance.
     * If set to 0, no subfolders are used.
     * The value can be simply changed for subsequent incremental backups.
     */
    var countSubFolders: Int = 0
    
    // set to true if derived resources (i.e. JPEG's instead of RAW) should be exported
    var exportDerived = true
    // set to true if current photos should be exported
    var exportCurrent = true
    // set to true if original photos should be exported
    var exportOriginals = true
    
    let fileManager = FileManager.default

    // paths
    var targetPath: String
    var inProgressPath: String {
        return "\(targetPath)/InProgress"
    }
    var originalsRelativePath = "Originals"
    var currentRelativePath = "Current"
    var derivedRelativePath = "Derived"
    var flatRelativePath = ".flat"
    
    public var baseExportPath:String?
    
    var statistics = Statistics()

    init(targetPath: String) {
        self.targetPath = targetPath
    }
    
    func exportPhotos(photosMetadata: PhotosMetadata) {
        if !fileManager.fileExists(atPath: targetPath) {
            logger.error("The folder at targetPath=\(targetPath) doesn't exist. Create it before running the PhotosExporter.")
            return
        }
        
        do {
            if (photosMetadata.allMediaObjects.count == 0) {
                throw PhotosExporterError.noMediaObjects
            }
            
            // use a subfolder for max. ~6000 files
            self.countSubFolders = Int(photosMetadata.allMediaObjects.count / 6000)
            logger.debug("countSubFolders: \(countSubFolders)")
            
            let stopWatch = StopWatch("Export to \(targetPath)", LogLevel.debug, addFileSizes: false)
            logger.info("Start export to \(targetPath)")
            stopWatch.start()

            try doExport(photosMetadata: photosMetadata)

            stopWatch.stop()
            logger.info("Finished export to \(targetPath)")
        } catch {
            logger.error("Error occured: \(error) => abort export")
        }
    }
    
    private func doExport(photosMetadata: PhotosMetadata) throws {
        try initExport()

        try exportFoldersFlat(photosMetadata: photosMetadata)
        
        if exportOriginals {
            logger.info("export albums folders - original assets")
            try exportFoldersRecursive(
                photoCollection: photosMetadata.rootCollection,
                flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
                targetPath: "\(inProgressPath)/\(originalsRelativePath)/\(escapeFileName(photosMetadata.rootCollection.name))",
                version: PhotoVersion.originals)
        }
        if exportCurrent {
            logger.info("export albums folders - current assets")
            try exportFoldersRecursive(
                photoCollection: photosMetadata.rootCollection,
                flatPath: "\(inProgressPath)/\(currentRelativePath)/\(flatRelativePath)",
                targetPath: "\(inProgressPath)/\(currentRelativePath)/\(escapeFileName(photosMetadata.rootCollection.name))",
                version: PhotoVersion.current)
        }
        if exportDerived {
            logger.info("export albums folders - derived assets")
            try exportFoldersRecursive(
                photoCollection: photosMetadata.rootCollection,
                flatPath: "\(inProgressPath)/\(derivedRelativePath)/\(flatRelativePath)",
                targetPath: "\(inProgressPath)/\(derivedRelativePath)/\(escapeFileName(photosMetadata.rootCollection.name))",
                version: PhotoVersion.derived)
        }

        try finishExport()
        
        statistics.print()
    }
    
    func initExport() throws {
        try recreateInProgressFolder()
    }
    
    func exportFoldersFlat(photosMetadata: PhotosMetadata) throws {
        // override function
    }
    
    private func recreateInProgressFolder() throws {
        do {
            if fileManager.fileExists(atPath: inProgressPath) {
                logger.info("Delete folder: \(inProgressPath)")
                for (retryCounter, _) in [0...2].enumerated() {
                    do {
                        try fileManager.removeItem(atPath: inProgressPath)
                    } catch let error as NSError {
                        if retryCounter == 2 {
                            logger.error("Unable to remove directory \(inProgressPath): \(error) => abort")
                            throw error
                        } else {
                            logger.error("Unable to remove directory \(inProgressPath): \(error) => retry")
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
    
    private func sourceUrlOfMediaObject(mediaObject: MediaObject, version: PhotoVersion) -> URL? {
        switch (version) {
        case PhotoVersion.originals:
            return mediaObject.originalUrl
        case PhotoVersion.current:
            return mediaObject.currentUrl
        case PhotoVersion.derived:
            return mediaObject.derivedUrl
        }
    }
    
    let stopWatchCheckFileSize = StopWatch("check file size", LogLevel.info, addFileSizes: false)

    private func getLinkToUrl(candidatesToLinkTo: [FlatFolderDescriptor], mediaObject: MediaObject, sourceUrl: URL) throws -> URL? {
        for candidateToLinkTo in candidatesToLinkTo {
            let candidateToLinkToUrl = URL(fileURLWithPath: getFlatPath(candidateToLinkTo, mediaObject, pathExtension: sourceUrl.pathExtension))
            if fileManager.fileExists(atPath: candidateToLinkToUrl.path) {
                // only minimal file comparison by file size for performance reasons! (this is sufficient for originals, and for important changes of current images; may not be sufficient for changes of image and video headers, which can have static sizes)
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

    func exportFolderFlat(photosMetadata: PhotosMetadata, flatPath: String, candidatesToLinkTo: [FlatFolderDescriptor], version: PhotoVersion) throws {
        var containsFotosToExport = false;
        stopWatchExportFolderFlatScanMediaObjects.start()
        for mediaObject in photosMetadata.allMediaObjects {
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
            for mediaObject in photosMetadata.allMediaObjects {
                stopWatchMediaObjectIteration.stop()

                if exportMediaObjectFilter(mediaObject) {
                    stopWatchCopyMediaObject.start()

                    // autorelease periodically
                    try autoreleasepool {
                        let sourceUrl = sourceUrlOfMediaObject(mediaObject: mediaObject, version: version)
                        
                        if sourceUrl?.absoluteString != "(null)", let sourceUrl = sourceUrl {
                            let targetUrl = URL(fileURLWithPath: getFlatPath(FlatFolderDescriptor(folderName: flatPath, countSubFolders: countSubFolders), mediaObject, pathExtension: sourceUrl.pathExtension))
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
                                    
                                    let fotoDate = mediaObject.creationDate!
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
                                
                                try setTagsOnFile(mediaObject: mediaObject, targetUrl: targetUrl)
                            }
                        }
                        else {
                            logger.warn("mediaObject has no url: \(mediaObject)")
                        }
                    }
                    
                    stopWatchCopyMediaObject.stop()
                }

                index += 1
            }
            
            stopWatchCopyMediaObject.stop()
        }
    }
    
    func setTagsOnFile(mediaObject: MediaObject, targetUrl: URL) throws {
        // remark: always set tags, not configurable => because the files are heavily linked with hard links, it would lead to an inconsistent state if one plan would export tags and the others not
        // workaround: API of URL doesn't allow to set tags => use NSURL
        let url = NSURL(fileURLWithPath: targetUrl.path)
        try url.setResourceValues([URLResourceKey.tagNamesKey : mediaObject.keywords])
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
    
    private func exportFoldersRecursive(photoCollection: PhotoCollection, flatPath: String, targetPath: String, version: PhotoVersion) throws {
        let flatFolder = FlatFolderDescriptor(folderName: flatPath, countSubFolders: countSubFolders)
        
        // autorelease periodically
        try autoreleasepool {
            if exportMediaGroupFilter(photoCollection) {
                var containsFotosToExport = false;
                if exportPhotosOfMediaGroupFilter(photoCollection) {
                    for mediaObject in photoCollection.mediaObjects {
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
                    
                    if exportPhotosOfMediaGroupFilter(photoCollection) {
                        for mediaObject in photoCollection.mediaObjects {
                            if exportMediaObjectFilter(mediaObject) {
                                try exportFoto(mediaObject: mediaObject, flatFolder: flatFolder, targetPath: targetPath, version: version)
                            }
                        }
                    }
                }
                
                for childCollection in photoCollection.childCollections {
                    let childTargetPath: String = "\(targetPath)/\(escapeFileName(childCollection.name))"
                    // TODO
//                    if childCollection.typeIdentifier == "com.apple.Photos.SmartAlbum" {
//                        childTargetPath = "\(childTargetPath) (Smart album)"
//                    }
                    try exportFoldersRecursive(photoCollection: childCollection, flatPath: flatPath, targetPath: childTargetPath, version: version)
                }
                
                
            }
        }
    }
    
    private func exportFoto(mediaObject: MediaObject, flatFolder: FlatFolderDescriptor, targetPath: String, version: PhotoVersion) throws {
        let sourceUrl = sourceUrlOfMediaObject(mediaObject: mediaObject, version: version)
        if sourceUrl?.absoluteString != "(null)", let sourceUrl = sourceUrl {
            let linkTargetUrl = URL(fileURLWithPath: getFlatPath(flatFolder, mediaObject, pathExtension: sourceUrl.pathExtension))
            
            // get unique target name
            let fotoName = getFotoName(mediaObject: mediaObject, sourceUrl: sourceUrl)
            var targetUrl = URL(fileURLWithPath: "\(targetPath)/\(fotoName).\(sourceUrl.pathExtension)")
            logger.debug("Export foto: \(fotoName) to \(targetUrl)")
            var i = 1
            while fileManager.fileExists(atPath: targetUrl.path) {
                targetUrl = URL(fileURLWithPath: "\(targetPath)/\(fotoName) (\(i)).\(sourceUrl.pathExtension)")
                i += 1
            }
            
            logger.debug("link image: \(targetUrl.lastPathComponent)")
            stopWatchFileManagerLinkItem.start()
            do {
                try fileManager.linkItem(at: linkTargetUrl, to: targetUrl)
            } catch let error as NSError {
                logger.error("\(String(describing: index)): Unable to link file: \(error)")
                throw error
            }
            statistics.countLinkedFiles += 1
            stopWatchFileManagerLinkItem.stop()
        } else {
            logger.warn("Source URL of mediaObject unknown: \(mediaObject)")
        }
    }
    
    private func getFlatPath(_ flatPath: FlatFolderDescriptor, _ mediaObject: MediaObject, pathExtension: String) -> String {
        if flatPath.countSubFolders > 0 {
            return "\(flatPath.folderName)/\(abs(mediaObject.zuuid().djb2hash) % flatPath.countSubFolders)/\(mediaObject.zuuid()).\(pathExtension)"
        } else {
            return "\(flatPath.folderName)/\(mediaObject.zuuid()).\(pathExtension)"
        }
    }
    
    private func getFotoName(mediaObject: MediaObject, sourceUrl: URL) -> String {
        let exportNoDate = hasKeyword(mediaObject: mediaObject, keyword: "export-no-date")
        
        var fotoName = ""
        if let name = mediaObject.title {
            fotoName = name
        } else if (exportNoDate) {
            fotoName = mediaObject.originalFilename!
            //fotoName = sourceUrl.lastPathComponent
        }
        
        // remove file extension
        let extensions: Set = [sourceUrl.pathExtension, mediaObject.originalUrl!.pathExtension, "jpg", "jpeg", "cr2", "png", "tif", "tiff", "heic", "mov"]
        for ext in extensions {
            if fotoName.lowercased().hasSuffix("." + ext.lowercased()) {
                fotoName = String(fotoName.prefix(upTo: fotoName.index(fotoName.endIndex, offsetBy: -ext.count-1)))
            }
        }
        
        // ignore filenames generated by Photos
        if fotoName.hasPrefix("fullsizeoutput_") {
            fotoName = ""
        }
        
        fotoName = escapeFileName(fotoName)

        if !exportNoDate {
            
            // get date of foto
            let fotoDate = mediaObject.creationDate!
            
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
    
    func flatFolderIfExists(_ flatFolderPath: String) throws -> [FlatFolderDescriptor] {
        if fileManager.fileExists(atPath: flatFolderPath) {
            return [try initFlatFolderDescriptor(flatFolderPath: flatFolderPath)]
        }
        
        return []
    }
    
    func initFlatFolderDescriptor(flatFolderPath: String) throws -> FlatFolderDescriptor {
        var lastCountSubFolders = 0
        
        if fileManager.fileExists(atPath: flatFolderPath) {
            let urls = try fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: flatFolderPath),
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            for url in urls {
                if let folderNumber = Int(url.lastPathComponent) {
                    if (folderNumber >= lastCountSubFolders) {
                        lastCountSubFolders = folderNumber+1
                    }
                }
            }
            logger.debug("lastCountSubFolders: \(lastCountSubFolders)")
            
            return FlatFolderDescriptor(folderName: flatFolderPath, countSubFolders: lastCountSubFolders)
        }
        
        throw FileNotFoundException.fileNotFound
    }
    
}

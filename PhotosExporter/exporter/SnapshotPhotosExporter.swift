//
//  SnapshotPhotosExporter.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation

/**
 * simple export mode which creates one snapshot folder, with hard links to the original files to save disk space (only if the target directory is in the same file system as the Photos Library)
 */
class SnapshotPhotosExporter : PhotosExporter {
    
    private var subTargetPath: String {
        return "\(targetPath)/Current"
    }
    
    override func exportFoldersFlat() throws {
        logger.info("export originals photos to \(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath) folder")
        try exportFolderFlat(
            flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
            candidatesToLinkTo: [],
            exportOriginals: true)
        
        logger.info("export calculated photos to \(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath) folder")
        try exportFolderFlat(
            flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
            candidatesToLinkTo: ["\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)"],
            exportOriginals: false)
    }
    
    override func copyOrLinkFileInPhotosLibrary(sourceUrl: URL, targetUrl: URL) throws {
        if try filesAreOnSameDevice(path1: sourceUrl.path, path2: targetUrl.deletingLastPathComponent().path) {
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
            // copy
            try super.copyOrLinkFileInPhotosLibrary(sourceUrl: sourceUrl, targetUrl: targetUrl)
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
    
    override func initExport() throws {
        try super.initExport()
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
    override func finishExport() throws {
        try super.finishExport()
        
        // remove the "Current" folder
        do {
            if fileManager.fileExists(atPath: subTargetPath) {
                logger.info("Delete folder: \(subTargetPath)")
                for (retryCounter, _) in [0...2].enumerated() {
                    do {
                        try fileManager.removeItem(atPath: subTargetPath)
                    } catch {
                        if retryCounter == 2 {
                            throw error
                        }
                    }
                }
            }
        } catch {
            logger.error("Error deleting folder \(subTargetPath)")
            throw error
        }
        
        // rename "InProgress" folder to "Current"
        do {
            try fileManager.moveItem(atPath: inProgressPath, toPath: subTargetPath)
        } catch {
            logger.error("Error renaming InProgress folder: \(error) => abort export")
            throw error
        }
    }
}

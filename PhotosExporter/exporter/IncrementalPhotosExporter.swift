//
//  IncrementalPhotosExporter.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.03.18.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

/**
 * backup mode, like "Time Machine", which creates one folder per date and which is a real copy of the Photos Library data.
 */
class IncrementalPhotosExporter : PhotosExporter {
    
    private var latestPath: String {
        return "\(targetPath)/Latest"
    }
    
    override func initExport() throws {
        try super.initExport()
    }
    
    override func exportFoldersFlat(photosMetadata: PhotosMetadata) throws {
        if exportOriginals {
            logger.info("export originals photos to \(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath) folder")
            
            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }

            candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(latestPath)/\(originalsRelativePath)/\(flatRelativePath)")

            try exportFolderFlat(
                photosMetadata: photosMetadata,
                flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                version: PhotoVersion.originals)
        }
        
        if exportCurrent {
            logger.info("export current photos to \(inProgressPath)/\(currentRelativePath)/\(flatRelativePath) folder")

            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(currentRelativePath)/\(flatRelativePath)")
            }
            
            candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(latestPath)/\(currentRelativePath)/\(flatRelativePath)")

            if exportOriginals {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }
            
            try exportFolderFlat(
                photosMetadata: photosMetadata,
                flatPath: "\(inProgressPath)/\(currentRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                version: PhotoVersion.current)
        }
        if exportDerived {
            logger.info("export derived photos to \(inProgressPath)/\(derivedRelativePath)/\(flatRelativePath) folder")

            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(derivedRelativePath)/\(flatRelativePath)")
            }
            
            candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(latestPath)/\(derivedRelativePath)/\(flatRelativePath)")

            if exportOriginals {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }
            
            try exportFolderFlat(
                photosMetadata: photosMetadata,
                flatPath: "\(inProgressPath)/\(derivedRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                version: PhotoVersion.derived)
        }

    }
    
    /**
     * Finish the filesystem structures; invariant:
     * if no folder "InProgress" but folders with date exist, and there is a symbolic link "Latest", there was no error.
     */
    override func finishExport() throws {
        try super.finishExport()
        
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
    
}

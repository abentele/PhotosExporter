//
//  IncrementalPhotosExporter.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation

/**
 * backup mode, like "Time Machine", which creates one folder per date and which is a real copy of the Photos Library data.
 */
class IncrementalPhotosExporter : PhotosExporter {
    
    private var latestPath: String {
        return "\(targetPath)/Latest"
    }
    
    override func exportFoldersFlat() throws {
        logger.info("export originals photos to \(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath) folder")
        try exportFolderFlat(
            flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
            candidatesToLinkTo: ["\(latestPath)/\(originalsRelativePath)/\(flatRelativePath)"],
            exportOriginals: true)
        
        logger.info("export calculated photos to \(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath) folder")
        try exportFolderFlat(
            flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
            candidatesToLinkTo: ["\(latestPath)/\(calculatedRelativePath)/\(flatRelativePath)", "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)"],
            exportOriginals: false)
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

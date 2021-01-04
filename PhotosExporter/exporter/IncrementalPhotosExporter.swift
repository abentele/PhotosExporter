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
    override init(exporterConfig: ExporterConfig) {
        super.init(exporterConfig: exporterConfig)
        self.baseExportPath = exporterConfig.baseExportPath
    }
    
    private var latestPath: String {
        return "\(targetPath)/Latest"
    }
    
    override func initExport() throws {
        try super.initExport()
    }
    
    public var baseExportPath:String?
    
    public func initFlatFolderDescriptor(flatFolderPath: String) throws -> FlatFolderDescriptor {
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
    
    override func exportFoldersFlat() throws {
        if exportOriginals {
            logger.info("export originals photos to \(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath) folder")
            
            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }

            candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(latestPath)/\(originalsRelativePath)/\(flatRelativePath)")

            try exportFolderFlat(
                flatPath: "\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                exportOriginals: true)
        }
        
        if exportCalculated {
            logger.info("export calculated photos to \(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath) folder")

            var candidatesToLinkTo: [FlatFolderDescriptor] = []

            if let baseExportPath = baseExportPath {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(baseExportPath)/\(calculatedRelativePath)/\(flatRelativePath)")
            }
            
            candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(latestPath)/\(calculatedRelativePath)/\(flatRelativePath)")

            if exportOriginals {
                candidatesToLinkTo = try candidatesToLinkTo + flatFolderIfExists("\(inProgressPath)/\(originalsRelativePath)/\(flatRelativePath)")
            }
            
            try exportFolderFlat(
                flatPath: "\(inProgressPath)/\(calculatedRelativePath)/\(flatRelativePath)",
                candidatesToLinkTo: candidatesToLinkTo,
                exportOriginals: false)
        }
    }
    
    func flatFolderIfExists(_ flatFolderPath: String) throws -> [FlatFolderDescriptor] {
        if fileManager.fileExists(atPath: flatFolderPath) {
            return [try initFlatFolderDescriptor(flatFolderPath: flatFolderPath)]
        }

        return []
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

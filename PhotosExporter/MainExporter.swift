//
//  Main.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.02.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation

func export() {
    let appName = nameOfApp()
    let logger = Logger(loggerName: appName, logLevel: .info)
    let configStorage = ConfigStorage(logger: logger)
    let configOptional = configStorage.tryToReadConfig()
    
    if configOptional == nil {
        logger.warn("Seems like you're using \(appName) for the first time, "
            + "since there is no config available in \(configStorage.configFileURL()).\n"
            + "Creating default settings in \(configStorage.defaultConfigFileURL()).\n"
            + "Please adapt its contents to your needs and save as \(configStorage.configFileURL())."
        )
        do {
            try configStorage.createDefaultConfig()
        } catch {
            logger.error("Failed to create default config: \(error)\nCannot continue.")
        }
        return
    }

    for exporterConfig in configOptional!.exporterConfigs {
        switch exporterConfig.exporterType
        {
        case ExporterConfig.ExporterType.snapshot:
            //////////////////////////////////////////////////////////////////////////////////////
            // Export to local disk in simple export mode (snapshot folder, with hard links
            // to the original files to save disk space)
            //////////////////////////////////////////////////////////////////////////////////////
            logger.info("Exporting snapshot to \(exporterConfig.targetPath)")
            let photosExporter = SnapshotPhotosExporter.init(exporterConfig: exporterConfig)
            photosExporter.exportPhotos()
            
        case ExporterConfig.ExporterType.incremental:
            //////////////////////////////////////////////////////////////////////////////////////
            // Export to external disk in "time machine" mode (one folder for each export date)
            //////////////////////////////////////////////////////////////////////////////////////
            logger.info("Exporting increment to \(exporterConfig.targetPath)")
            let photosExporter = IncrementalPhotosExporter.init(exporterConfig: exporterConfig)
            photosExporter.exportPhotos()
        }
    }
}


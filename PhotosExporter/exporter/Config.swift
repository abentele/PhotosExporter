//
//  Config.swift
//  PhotosExporter
//
//  Created by Kai Unger on 30.12.20.
//  Copyright © 2020 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

// Hierarchical organization of Apple's Photo's as seen in Photos 3.0 (3291.13.210) on macOS 10.13.6 (17G66)
//    type=com.apple.Photos.RootGroup, name=Optional("Fotos")
//        type=com.apple.Photos.AllMomentsGroup, name=Optional("Momente")
//            type=com.apple.Photos.MomentGroup, name=Optional("...")
//            ... more moments ...
//        type=com.apple.Photos.AllCollectionsGroup, name=Optional("Sammlungen")
//            type=com.apple.Photos.CollectionGroup, name=Optional("...")
//            ... more collections ...
//        type=com.apple.Photos.AllYearsGroup, name=Optional("Jahre")
//            type=com.apple.Photos.YearGroup, name=Optional("...")
//            ... more years ...
//        type=com.apple.Photos.PlacesAlbum, name=Optional("Orte")
//            type=com.apple.Photos.PlacesCountryAlbum, name=Optional("Dänemark")
//                type=com.apple.Photos.PlacesProvinceAlbum, name=Optional("Nordjylland")
//                    type=com.apple.Photos.PlacesCityAlbum, name=Optional("Hirtshals")
//                        type=com.apple.Photos.PlacesPointOfInterestAlbum, name=Optional("Vendsyssel-Thy")
//        type=com.apple.Photos.SharedGroup, name=Optional("Freigegeben")
//            type=com.apple.Photos.SharedPhotoStream, name=Optional("...")
//            ... more shared albums ...
//        type=com.apple.Photos.AlbumsGroup, name=Optional("Alben")
//            type=com.apple.Photos.FacesAlbum, name=Optional("Personen")
//                type=com.apple.Photos.FacesAlbum, name=Optional("...")
//                ... more individual persons ...
//            type=com.apple.Photos.VideosGroup, name=Optional("Videos")
//            type=com.apple.Photos.FrontCameraGroup, name=Optional("Selfies")
//            type=com.apple.Photos.PanoramasGroup, name=Optional("Panoramen")
//            type=com.apple.Photos.ScreenshotGroup, name=Optional("Bildschirmfotos")
//            type=com.apple.Photos.MyPhotoStream, name=Optional("Mein Fotostream")
//            type=com.apple.Photos.Album, name=Optional("... album name ...")
//            type=com.apple.Photos.Folder, name=Optional("... some folder name ...")
//                type=com.apple.Photos.SmartAlbum, name=Optional("... some album name ...")
//                type=com.apple.Photos.Album, name=Optional("... another album name ...")

// Folders and albums and smart albums can be nested individually.

// Media objects appear on any level aggregating from the most specific towards the root media group.
// E.g. a photo contained in com.apple.Photos.PlacesPointOfInterestAlbum appears
// a second time in com.apple.Photos.PlacesCityAlbum,
// a third time in com.apple.Photos.PlacesProvinceAlbum
// a fourth time in com.apple.Photos.PlacesCountryAlbum
// a fifth time in com.apple.Photos.PlacesAlbum
// a sixth time in com.apple.Photos.RootGroup

func debugPhotosGroupTypeIdConstants() {
    let logger = Logger(loggerName: "PhotosExporter", logLevel: .debug)
    
    logger.debug("MLPhotosAlbumTypeIdentifier: \(MLPhotosAlbumTypeIdentifier)")
    logger.debug("MLPhotosAlbumsGroupTypeIdentifier \(MLPhotosAlbumsGroupTypeIdentifier)")
    logger.debug("MLPhotosAllCollectionsGroupTypeIdentifier \(MLPhotosAllCollectionsGroupTypeIdentifier)")
    logger.debug("MLPhotosAllMomentsGroupTypeIdentifier \(MLPhotosAllMomentsGroupTypeIdentifier)")
    logger.debug("MLPhotosAllPhotosAlbumTypeIdentifier \(MLPhotosAllPhotosAlbumTypeIdentifier)")
    logger.debug("MLPhotosAllYearsGroupTypeIdentifier \(MLPhotosAllYearsGroupTypeIdentifier)")
    logger.debug("MLPhotosBurstGroupTypeIdentifier \(MLPhotosBurstGroupTypeIdentifier)")
    logger.debug("MLPhotosCollectionGroupTypeIdentifier \(MLPhotosCollectionGroupTypeIdentifier)")
    logger.debug("MLPhotosDepthEffectGroupTypeIdentifier \(MLPhotosDepthEffectGroupTypeIdentifier)")
    logger.debug("MLPhotosFacesAlbumTypeIdentifier \(MLPhotosFacesAlbumTypeIdentifier)")
    logger.debug("MLPhotosFavoritesGroupTypeIdentifier \(MLPhotosFavoritesGroupTypeIdentifier)")
    logger.debug("MLPhotosFolderTypeIdentifier \(MLPhotosFolderTypeIdentifier)")
    logger.debug("MLPhotosFrontCameraGroupTypeIdentifier \(MLPhotosFrontCameraGroupTypeIdentifier)")
    logger.debug("MLPhotosLastImportGroupTypeIdentifier \(MLPhotosLastImportGroupTypeIdentifier)")
    logger.debug("MLPhotosMomentGroupTypeIdentifier \(MLPhotosMomentGroupTypeIdentifier)")
    logger.debug("MLPhotosMyPhotoStreamTypeIdentifier \(MLPhotosMyPhotoStreamTypeIdentifier)")
    logger.debug("MLPhotosPanoramasGroupTypeIdentifier \(MLPhotosPanoramasGroupTypeIdentifier)")
    logger.debug("MLPhotosPublishedAlbumTypeIdentifier \(MLPhotosPublishedAlbumTypeIdentifier)")
    logger.debug("MLPhotosRootGroupTypeIdentifier \(MLPhotosRootGroupTypeIdentifier)")
    logger.debug("MLPhotosScreenshotGroupTypeIdentifier \(MLPhotosScreenshotGroupTypeIdentifier)")
    logger.debug("MLPhotosSharedGroupTypeIdentifier \(MLPhotosSharedGroupTypeIdentifier)")
    logger.debug("MLPhotosSharedPhotoStreamTypeIdentifier \(MLPhotosSharedPhotoStreamTypeIdentifier)")
    logger.debug("MLPhotosSloMoGroupTypeIdentifier \(MLPhotosSloMoGroupTypeIdentifier)")
    logger.debug("MLPhotosSmartAlbumTypeIdentifier \(MLPhotosSmartAlbumTypeIdentifier)")
    logger.debug("MLPhotosTimelapseGroupTypeIdentifier \(MLPhotosTimelapseGroupTypeIdentifier)")
    logger.debug("MLPhotosVideosGroupTypeIdentifier \(MLPhotosVideosGroupTypeIdentifier)")
    logger.debug("MLPhotosYearGroupTypeIdentifier \(MLPhotosYearGroupTypeIdentifier)")
}

enum PhotoGroups : String, Codable {
    case Moments
    case Collections
    case Years
    case Places

    case Faces
    case Videos
    case Selfies
    case Panoramas
    case Screenshots
    
    case Albums
    case SmartAlbums
}

struct ExporterConfig : Codable {
    enum ExporterType : String, Codable {
        case incremental
        case snapshot
    }
    
    // define which media groups should be exported
    public var groupsToExport: [PhotoGroups]
    // Level of logging. Only messages with this level or higher will be logged
    public var logLevel: LogLevel
    public var exporterType: ExporterType
    // Location (file system folder) where to put the exported files
    public var targetPath: String
    // (only IncrementalPhotosExporter, optional parameter): the path to an already existing export folder on the same device; example: export all photos using SnapshotPhotosExporter to your local disk or SSD; create a backup using Time Machine; additionally export the photos using IncrementalPhotosExporter to the same device as your Time Machine backup. Then you would set the baseExportPath to the export folder within your Time Machine backup, to link the exported photos with the photos of your Time Machine backup to save disk space.
    public var baseExportPath: String?
    // Switches whether the original photos (masters) shall be exported
    public var exportOriginals: Bool
    // Switches whether the edited photos (rendered as jpegs) shall be exported
    public var exportCalculated: Bool
    // Switches whether the "flat" folder wich contains all photos
    // shall be deleted after the export is finished
    //
    // This parameter is ignored by the incremental exporter
    //
    // Note: If this is true and groupsToExport is empty,
    // effectively nothing will be exported, because the flat folder
    // is the only folder created during export
    public var deleteFlatPathAfterExport: Bool
    
    enum CodingKeys: String, CodingKey {
        case exporterType
        case targetPath
        case baseExportPath
        case groupsToExport
        case logLevel
        case exportOriginals
        case exportCalculated
        case deleteFlatPathAfterExport
    }
}

func createDefaultExporterConfig(exporterType: ExporterConfig.ExporterType,
                                 targetPath: String) -> ExporterConfig
{
    return ExporterConfig(
        groupsToExport:
        [PhotoGroups.Moments,
         PhotoGroups.Collections,
         PhotoGroups.Years,
         PhotoGroups.Places,
         
         PhotoGroups.Faces,
         PhotoGroups.Videos,
         PhotoGroups.Selfies,
         PhotoGroups.Panoramas,
         PhotoGroups.Screenshots,
         
         PhotoGroups.Albums,
         PhotoGroups.SmartAlbums],
        logLevel: LogLevel.info,
        exporterType: exporterType,
        targetPath: targetPath,
        baseExportPath: nil,
        exportOriginals: true,
        exportCalculated: true,
        deleteFlatPathAfterExport: true)
}

class MainConfig : Codable {
    public var exporterConfigs : [ExporterConfig]
        = [createDefaultExporterConfig(exporterType: ExporterConfig.ExporterType.snapshot,
                                       targetPath: "/Users/andreas/Pictures/Fotos Library export"),
           createDefaultExporterConfig(exporterType: ExporterConfig.ExporterType.incremental,
                                       targetPath: "/Volumes/WD-4TB/Fotos Library export")]
}

func nameOfApp() -> String {
    let bundle = Bundle.main
    if let appNameAny = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName")
        ?? bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String)
        , let appNameString = appNameAny as? String
    {
        return appNameString
    }
    
    return "PhotosExporter"
}

struct ConfigStorage {
    public var logger : Logger
    
    func configFolderURL() -> URL {
        let applicationSupportFolderURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appName = nameOfApp()
        let myFolderInApplicationSupportFolderURL = applicationSupportFolderURL.appendingPathComponent("\(appName)",
            isDirectory: true)
        
        return myFolderInApplicationSupportFolderURL
    }
    
    func configFileURL() -> URL {
        let configFolder = configFolderURL()
        return configFolder.appendingPathComponent("config.json", isDirectory: false)
    }
    
    func defaultConfigFileURL() -> URL {
        let configFolder = configFolderURL()
        return configFolder.appendingPathComponent("default_config.json", isDirectory: false)
    }
    
    func ensureApplicationSupportFolderExists() throws {
        let myFolderInApplicationSupportFolderURL = configFolderURL()
        
        do {
            try FileManager.default.createDirectory(atPath: myFolderInApplicationSupportFolderURL.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            logger.error("Unable to create directory \(myFolderInApplicationSupportFolderURL): \(error)")
            throw error
        }
    }
    
    func writeConfig(url: URL, data: Data) {
        do {
            try ensureApplicationSupportFolderExists()
            try data.write(to: url)
        } catch let error as NSError {
            // Handle error
            logger.error("Failed to write config data to \(url): \(error)")
        }
    }
    
    func createDefaultConfig() throws {
        let config = MainConfig()
        let fileToWrite = defaultConfigFileURL()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(config)
        try data.write(to: fileToWrite)
    }
    
    func tryToReadConfig() -> MainConfig? {
        var config: MainConfig? = nil
        do {
            let configFile = configFileURL()
            let jsonData = try Data(contentsOf: configFile)
            let jsonDecoder = JSONDecoder()
            do {
                config = try jsonDecoder.decode(MainConfig.self, from: jsonData)
            } catch {
                logger.error("Failed to parse config from \(configFileURL): \(error)")
            }
        } catch {
            logger.error("Failed to read config file \(configFileURL): \(error)")
        }
        
        return config
    }
}

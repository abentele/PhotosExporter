//
//  metadata-reader.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 09.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

class MetadataLoader : NSObject {
    
    let logger = Logger(loggerName: "MetadataLoader", logLevel: .debug)

    // MLMediaLibrary instances for loading the photos.
    private var mediaLibrary: MLMediaLibrary!
    private var mediaSource: MLMediaSource!
    private var rootMediaGroup: MLMediaGroup!
    
    var loadMediaObjectsCounter = 0
    
    // MLMediaLibrary property values for KVO.
    private struct MLMediaLibraryPropertyKeys {
        static let mediaSourcesKey = "mediaSources"
        static let rootMediaGroupKey = "rootMediaGroup"
        static let mediaObjectsKey = "mediaObjects"
    }
    
    /**
     The KVO contexts for `MLMediaLibrary`.
     This provides a stable address to use as the `context` parameter for KVO observation methods.
     */
    private var mediaSourcesContext = 1
    private var rootMediaGroupContext = 2
    private var mediaObjectsContext = 3
    
    private var shouldExit = false
    
    func loadMetadata() -> MLMediaGroup {
        logger.info("Start reading metadata (this may take a while)...")
        
        // Setup the media library to load only photos, don't include other source types.
        let options: [String : AnyObject] =
            [MLMediaLoadSourceTypesKey: MLMediaSourceType.image.rawValue as AnyObject,
             MLMediaLoadIncludeSourcesKey: [MLMediaSourcePhotosIdentifier] as AnyObject]
        
        // Create our media library instance to get our photo.
        self.mediaLibrary = MLMediaLibrary(options: options)
        
        // We want to be called when media sources come in that's available (via observeValueForKeyPath).
        self.mediaLibrary.addObserver(self,
                                      forKeyPath: MLMediaLibraryPropertyKeys.mediaSourcesKey,
                                      options: NSKeyValueObservingOptions.new,
                                      context: &mediaSourcesContext)
        
        if (self.mediaLibrary.mediaSources != nil) {} // Reference returns nil but starts the asynchronous loading.


        // wait until all metadata is loaded
        let runLoop = RunLoop.current
        while (!shouldExit
            && runLoop.run(mode:   RunLoop.Mode.default,
                           before: .distantFuture ) ) {}
        
        return self.rootMediaGroup
    }
    

    
    // MARK: - Photo Loading
    
    /// Observer for all key paths returned from the MLMediaLibrary.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == MLMediaLibraryPropertyKeys.mediaSourcesKey && context == &mediaSourcesContext && object! is MLMediaLibrary) {
            
            // The media sources have loaded, we can access the its root media.
            
            if let mediaSource = self.mediaLibrary.mediaSources?[MLMediaSourcePhotosIdentifier] {
                self.mediaSource = mediaSource
            }
            else {
                return  // No photos found.
            }
            
            // Media Library is loaded now, we can access mediaSource for photos
            self.mediaSource.addObserver(self,
                                         forKeyPath: MLMediaLibraryPropertyKeys.rootMediaGroupKey,
                                         options: NSKeyValueObservingOptions.new,
                                         context: &rootMediaGroupContext)
            
            // Obtain the media grouping (reference returns nil but starts asynchronous loading).
            if (self.mediaSource.rootMediaGroup != nil) {}
        }
        else if (keyPath == MLMediaLibraryPropertyKeys.rootMediaGroupKey && context == &rootMediaGroupContext && object! is MLMediaSource) {
            
            // The root media group is loaded, we can access the media objects.
            
            // Done observing for media groups.
            self.mediaSource.removeObserver(self, forKeyPath: MLMediaLibraryPropertyKeys.rootMediaGroupKey, context:&rootMediaGroupContext)
            
            self.rootMediaGroup = self.mediaSource.rootMediaGroup

            loadMediaObjectsCounter = 0
            triggerLoadMediaGroupRecursive(mediaGroup: self.rootMediaGroup)
        }
        else if (keyPath == MLMediaLibraryPropertyKeys.mediaObjectsKey && context == &mediaObjectsContext && object! is MLMediaGroup) {
            // The media objects are loaded

            let mediaGroup = object as! MLMediaGroup
            
            // Done observing for media objects that group.
            mediaGroup.removeObserver(self, forKeyPath: MLMediaLibraryPropertyKeys.mediaObjectsKey, context:&mediaObjectsContext)
            

            // if all entries are loaded...
            loadMediaObjectsCounter = loadMediaObjectsCounter - 1
            if loadMediaObjectsCounter == 0 {
                logger.info("Finished reading metadata.")
                shouldExit = true
            }
                
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func triggerLoadMediaGroupRecursive(mediaGroup: MLMediaGroup) {
        loadMediaObjectsCounter = loadMediaObjectsCounter + 1
        mediaGroup.addObserver(self,
                                        forKeyPath: MLMediaLibraryPropertyKeys.mediaObjectsKey,
                                        options: NSKeyValueObservingOptions.new,
                                        context: &mediaObjectsContext)
        
        // Obtain the all the photos, (reference returns nil but starts asynchronous loading).
        if (mediaGroup.mediaObjects != nil) {}
        
        if let childGroups = mediaGroup.childGroups {
            for childMediaGroup in childGroups {
                triggerLoadMediaGroupRecursive(mediaGroup: childMediaGroup)
            }
        } else {
            logger.warn("optional mediaGroup.childGroups is nil: \(mediaGroup.name!)")
        }
    }
    
}

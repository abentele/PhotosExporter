//
//  MediaLibUtil.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 23.09.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import MediaLibrary

/**
 * Checks if a specific keyword is assigned to the mediaObject
 */
func hasKeyword(mediaObject: MediaObject, keyword: String) -> Bool {
    return mediaObject.keywords.contains(keyword)
}


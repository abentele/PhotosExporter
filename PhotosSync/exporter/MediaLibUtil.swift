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
func hasKeyword(mediaObject: MLMediaObject, keyword: String) -> Bool {
    if let keywordAttribute = mediaObject.attributes["keywordNamesAsString"] {
        let keywordsStr = keywordAttribute as! String
        let keywords = keywordsStr.components(separatedBy: ",").map { word in word.trimmingCharacters(in: .whitespacesAndNewlines) }
        return keywords.contains(keyword)
    }
    return false
}


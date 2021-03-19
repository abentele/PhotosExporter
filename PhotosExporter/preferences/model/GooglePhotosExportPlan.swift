//
//  GooglePhotosPlan.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

class GooglePhotosExportPlan : Plan {
    
    override func getType() -> String {
        return "GooglePhotosExport"
    }

    override func toYaml(indent: Int) -> String {
        var result: String = ""
        result += super.toYaml(indent: indent)
        return result
    }
}

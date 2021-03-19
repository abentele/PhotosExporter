//
//  PreferencesReaderTest.swift
//  PreferencesReaderTest
//
//  Created by Andreas Bentele on 25.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import XCTest
@testable import PhotosExporter

class PreferencesReaderTest: XCTestCase {
    
    let yaml0 = """
---
plans:
"""

    let yaml1 = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
      keywordWhiteList:
      keywordBlackList:
    targetFolder: /Volumes/test
"""
    
    let yaml2 = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
    targetFolder: /Volumes/test
  -
    type: GooglePhotosExport
    name: Google photos example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
"""
    
    let yamlEnabledFalse = """
---
plans:
  -
    type: IncrementalFileSystemExport
    enabled: false
    name: Incremental export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
"""

    let yamlEnabledTrue = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
"""

    let yamlExportCurrent = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    exportCurrent: true
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
    targetFolder: /Volumes/test
"""

    let yamlExportOriginals = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    exportOriginals: false
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
    targetFolder: /Volumes/test
"""
    
    let yamlBaseExportPath = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
    baseExportPath: /Volumes/base
"""
    
    let yamlDeleteFlatPath = """
---
plans:
  -
    type: SnapshotFileSystemExport
    name: Snapshot export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
        - com.apple.Photos.CollectionGroup
        - com.apple.Photos.MomentGroup
        - com.apple.Photos.YearGroup
        - com.apple.Photos.PlacesCountryAlbum
        - com.apple.Photos.PlacesProvinceAlbum
        - com.apple.Photos.PlacesCityAlbum
        - com.apple.Photos.PlacesPointOfInterestAlbum
        - com.apple.Photos.FacesAlbum
        - com.apple.Photos.VideosGroup
        - com.apple.Photos.FrontCameraGroup
        - com.apple.Photos.PanoramasGroup
        - com.apple.Photos.BurstGroup
        - com.apple.Photos.ScreenshotGroup
      keywordWhiteList:
      keywordBlackList:
    deleteFlatPath: true
"""
    
let yamlMediaObjectFilter = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    mediaObjectFilter:
      mediaGroupTypeWhiteList:
        - com.apple.Photos.Album
        - com.apple.Photos.SmartAlbum
      keywordWhiteList:
        - photos-for-my-dad
        - photos-for-linda
      keywordBlackList:
        - dont-export
        - private
    targetFolder: /Volumes/test
"""
    
let mediaGroupTypeWhiteList = [
    "com.apple.Photos.Album",
    "com.apple.Photos.SmartAlbum"
]

let keywordWhiteList = [
    "photos-for-my-dad",
    "photos-for-linda"
]

let keywordBlackList = [
    "dont-export",
    "private"
]
    
    let invalidYaml = """
invalid
"""

    let yamlPlanWithoutType = """
---
plans:
  -
    name: Incremental export example
"""

    let yamlInvalidPlanType = """
---
plans:
  -
    type: invalid-type
    name: Incremental export example
"""
    

    /**
     * Test serialization of an empty preferences object
     */
    func testSerialize0() {
        let preferences = Preferences()
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml0, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of an empty preferences object
     */
    func testDeserialize0() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yaml0)
        
        XCTAssertEqual(0, preferences.plans.count)
    }

    /**
     * Test serialization of a preferences object with exactly one plan
     */
    func testSerialize1() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.targetFolder = "/Volumes/test"
        plan.mediaObjectFilter.mediaGroupTypeWhiteList = []
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml1, yamlStr, "Yaml string not as expected")
    }

    /**
     * Test deserialization of a preferences object with exactly one plan
     */
    func testDeserialize1() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yaml1)
        
        XCTAssertEqual(1, preferences.plans.count)
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, preferences.plans[0].exportCurrent)
        XCTAssertEqual(nil, preferences.plans[0].exportOriginals)
        XCTAssertEqual([], preferences.plans[0].mediaObjectFilter.mediaGroupTypeWhiteList)
        XCTAssertEqual([], preferences.plans[0].mediaObjectFilter.keywordWhiteList)
        XCTAssertEqual([], preferences.plans[0].mediaObjectFilter.keywordBlackList)
    }
    
    /**
     * Test serialization of a preferences object with two plans of different type
     */
    func testSerialize2() {
        let preferences = Preferences()
        
        let plan1 = IncrementalFileSystemExportPlan()
        plan1.name = "Incremental export example"
        plan1.targetFolder = "/Volumes/test"
        preferences.plans.append(plan1)
        
        let plan2 = GooglePhotosExportPlan()
        plan2.name = "Google photos example"
        preferences.plans.append(plan2)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml2, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of a preferences object with two plans of different type
     */
    func testDeserialize2() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yaml2)
        
        XCTAssertEqual(2, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, preferences.plans[0].exportCurrent)
        XCTAssertEqual(nil, preferences.plans[0].exportOriginals)
        
        XCTAssertEqual("GooglePhotosExport", preferences.plans[1].getType())
        XCTAssertEqual("Google photos example", preferences.plans[1].name)
    }
    
    /**
     * Test serialization of the "enabled" attribute
     */
    func testSerializeEnabledFalse() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.enabled = false
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlEnabledFalse, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportCurrent" attribute
     */
    func testDeserializeEnabledFalse() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlEnabledFalse)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual(false, preferences.plans[0].enabled)
    }
    
    /**
     * Test serialization of the "enabled" attribute
     */
    func testSerializeEnabledTrue() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.enabled = true
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlEnabledTrue, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportCurrent" attribute
     */
    func testDeserializeEnabledTrue() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlEnabledTrue)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual(true, preferences.plans[0].enabled)
    }


    
    /**
     * Test serialization of the "exportCurrent" attribute
     */
    func testSerializeExportCurrent() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.targetFolder = "/Volumes/test"
        plan.exportCurrent = true
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlExportCurrent, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportCurrent" attribute
     */
    func testDeserializeExportCurrent() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlExportCurrent)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(true, preferences.plans[0].exportCurrent)
        XCTAssertEqual(nil, preferences.plans[0].exportOriginals)
    }
    
    /**
     * Test serialization of the "exportOriginals" attribute
     */
    func testSerializeExportOriginals() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.targetFolder = "/Volumes/test"
        plan.exportOriginals = false
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlExportOriginals, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportOriginals" attribute
     */
    func testDeserializeExportOriginals() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlExportOriginals)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, preferences.plans[0].exportCurrent)
        XCTAssertEqual(false, preferences.plans[0].exportOriginals)
    }
    
    /**
     * Test serialization of the "baseExportPath" attribute
     */
    func testSerializeBaseExportPath() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.baseExportPath = "/Volumes/base"
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlBaseExportPath, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "baseExportPath" attribute
     */
    func testDeserializeBaseExportPath() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlBaseExportPath)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/base", (preferences.plans[0] as! IncrementalFileSystemExportPlan).baseExportPath)
    }
    
    /**
     * Test serialization of the "deleteFlatPath" attribute
     */
    func testSerializeDeleteFlatPath() {
        let preferences = Preferences()
        let plan = SnapshotFileSystemExportPlan()
        plan.name = "Snapshot export example"
        plan.deleteFlatPath = true
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlDeleteFlatPath, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "deleteFlatPath" attribute
     */
    func testDeserializeDeleteFlatPath() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlDeleteFlatPath)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("SnapshotFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Snapshot export example", preferences.plans[0].name)
        XCTAssertEqual(true, (preferences.plans[0] as! SnapshotFileSystemExportPlan).deleteFlatPath)
    }
    
    /**
     * Test serialization of the "deleteFlatPath" attribute
     */
    func testSerializeMediaObjectFilter() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.targetFolder = "/Volumes/test"
        plan.mediaObjectFilter.mediaGroupTypeWhiteList = mediaGroupTypeWhiteList
        plan.mediaObjectFilter.keywordWhiteList = keywordWhiteList
        plan.mediaObjectFilter.keywordBlackList = keywordBlackList
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlMediaObjectFilter, yamlStr, "Yaml string not as expected")
    }

    
    /**
     * Test deserialization of the "mediaObjectFilter" attribute
     */
    func testDeserializeMediaObjectFilter() throws {
        let preferences = try PreferencesReader.preferencesFromYaml(yamlStr: yamlMediaObjectFilter)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! IncrementalFileSystemExportPlan).targetFolder)
        XCTAssertEqual(mediaGroupTypeWhiteList, preferences.plans[0].mediaObjectFilter.mediaGroupTypeWhiteList)
        XCTAssertEqual(keywordWhiteList, preferences.plans[0].mediaObjectFilter.keywordWhiteList)
        XCTAssertEqual(keywordBlackList, preferences.plans[0].mediaObjectFilter.keywordBlackList)
    }

    
    /**
     * Test behavior of deserializing an invalid Yaml string.
     */
    func testDeserializeInvalidYaml() {
        XCTAssertThrowsError(try PreferencesReader.preferencesFromYaml(yamlStr: invalidYaml)) { error in
            XCTAssertEqual(error as! PreferencesReaderError, PreferencesReaderError.invalidYaml)
        }
    }
    
    /**
     * Test behavior of deserializing a plan without type.
     */
    func testDeserializePlanWithoutType() {
        XCTAssertThrowsError(try PreferencesReader.preferencesFromYaml(yamlStr: yamlPlanWithoutType)) { error in
            XCTAssertEqual(error as! PreferencesReaderError, PreferencesReaderError.invalidOrNoPlanType)
        }
    }
    
    /**
     * Test behavior of deserializing a plan with an invalid type.
     */
    func testDeserializeInvalidPlanType() {
        XCTAssertThrowsError(try PreferencesReader.preferencesFromYaml(yamlStr: yamlInvalidPlanType)) { error in
            XCTAssertEqual(error as! PreferencesReaderError, PreferencesReaderError.invalidOrNoPlanType)
        }
    }
}

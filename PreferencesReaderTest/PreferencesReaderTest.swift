//
//  PreferencesReaderTest.swift
//  PreferencesReaderTest
//
//  Created by Andreas Bentele on 25.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import XCTest
@testable import PhotosSync

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
    targetFolder: /Volumes/test
"""

    let yaml2 = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    targetFolder: /Volumes/test
  -
    type: GooglePhotosExport
    name: Google photos example
"""
    
    let yamlExportCalculated = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    targetFolder: /Volumes/test
    exportCalculated: true
"""

    let yamlExportOriginals = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    targetFolder: /Volumes/test
    exportOriginals: false
"""
    
    let yamlBaseExportPath = """
---
plans:
  -
    type: IncrementalFileSystemExport
    name: Incremental export example
    baseExportPath: /Volumes/base
"""
    
    let yamlDeleteFlatPath = """
---
plans:
  -
    type: SnapshotFileSystemExport
    name: Snapshot export example
    deleteFlatPath: true
"""
    
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
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yaml0)
        
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
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml1, yamlStr, "Yaml string not as expected")
    }

    /**
     * Test deserialization of a preferences object with exactly one plan
     */
    func testDeserialize1() throws {
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yaml1)
        
        XCTAssertEqual(1, preferences.plans.count)
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportCalculated)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportOriginals)
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
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yaml2)
        
        XCTAssertEqual(2, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportCalculated)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportOriginals)
        
        XCTAssertEqual("GooglePhotosExport", preferences.plans[1].getType())
        XCTAssertEqual("Google photos example", preferences.plans[1].name)
    }
    
    /**
     * Test serialization of the "exportCalculated" attribute
     */
    func testSerializeExportCalculated() {
        let preferences = Preferences()
        let plan = IncrementalFileSystemExportPlan()
        plan.name = "Incremental export example"
        plan.targetFolder = "/Volumes/test"
        plan.exportCalculated = true
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlExportCalculated, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportCalculated" attribute
     */
    func testDeserializeExportCalculated() throws {
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yamlExportCalculated)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(true, (preferences.plans[0] as! FileSystemExportPlan).exportCalculated)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportOriginals)
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
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yamlExportOriginals)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("IncrementalFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportCalculated)
        XCTAssertEqual(false, (preferences.plans[0] as! FileSystemExportPlan).exportOriginals)
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
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yamlBaseExportPath)
        
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
        let preferencesReader = PreferencesReader()
        
        let preferences = try preferencesReader.preferencesFromYaml(yamlStr: yamlDeleteFlatPath)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("SnapshotFileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Snapshot export example", preferences.plans[0].name)
        XCTAssertEqual(true, (preferences.plans[0] as! SnapshotFileSystemExportPlan).deleteFlatPath)
    }
    
    /**
     * Test behavior of deserializing an invalid Yaml string.
     */
    func testDeserializeInvalidYaml() {
        let preferencesReader = PreferencesReader()
        
        XCTAssertThrowsError(try preferencesReader.preferencesFromYaml(yamlStr: invalidYaml)) { error in
            XCTAssertEqual(error as! PreferencesReaderError, PreferencesReaderError.invalidYaml)
        }
    }
    
    /**
     * Test behavior of deserializing a plan without type.
     */
    func testDeserializePlanWithoutType() {
        let preferencesReader = PreferencesReader()
        
        XCTAssertThrowsError(try preferencesReader.preferencesFromYaml(yamlStr: yamlPlanWithoutType)) { error in
            XCTAssertEqual(error as! PreferencesReaderError, PreferencesReaderError.invalidOrNoPlanType)
        }
    }
    
    /**
     * Test behavior of deserializing a plan with an invalid type.
     */
    func testDeserializeInvalidPlanType() {
        let preferencesReader = PreferencesReader()
        
        XCTAssertThrowsError(try preferencesReader.preferencesFromYaml(yamlStr: yamlInvalidPlanType)) { error in
            XCTAssertEqual(error as! PreferencesReaderError, PreferencesReaderError.invalidOrNoPlanType)
        }
    }
}

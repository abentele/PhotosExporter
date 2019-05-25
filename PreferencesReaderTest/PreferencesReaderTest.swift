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
    type: FileSystemExport
    name: Incremental export example
    targetFolder: /Volumes/test
"""

    let yaml2 = """
---
plans:
  -
    type: FileSystemExport
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
    type: FileSystemExport
    name: Incremental export example
    targetFolder: /Volumes/test
    exportCalculated: true
"""

    let yamlExportOriginals = """
---
plans:
  -
    type: FileSystemExport
    name: Incremental export example
    targetFolder: /Volumes/test
    exportOriginals: false
"""

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
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
    func testDeserialize0() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yaml0)
        
        XCTAssertEqual(0, preferences.plans.count)
    }

    /**
     * Test serialization of a preferences object with exactly one plan
     */
    func testSerialize1() {
        let preferences = Preferences()
        preferences.plans.append(FileSystemExportPlan(name: "Incremental export example", targetFolder: "/Volumes/test"))
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml1, yamlStr, "Yaml string not as expected")
    }

    /**
     * Test deserialization of a preferences object with exactly one plan
     */
    func testDeserialize1() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yaml1)
        
        XCTAssertEqual(1, preferences.plans.count)
        XCTAssertEqual("FileSystemExport", preferences.plans[0].getType())
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
        preferences.plans.append(FileSystemExportPlan(name: "Incremental export example", targetFolder: "/Volumes/test"))
        preferences.plans.append(GooglePhotosExportPlan(name: "Google photos example"))
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml2, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of a preferences object with two plans of different type
     */
    func testDeserialize2() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yaml2)
        
        XCTAssertEqual(2, preferences.plans.count)
        
        XCTAssertEqual("FileSystemExport", preferences.plans[0].getType())
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
        let plan: FileSystemExportPlan = FileSystemExportPlan(name: "Incremental export example", targetFolder: "/Volumes/test")
        plan.exportCalculated = true
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlExportCalculated, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportCalculated" attribute
     */
    func testDeserializeExportCalculated() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yamlExportCalculated)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("FileSystemExport", preferences.plans[0].getType())
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
        let plan: FileSystemExportPlan = FileSystemExportPlan(name: "Incremental export example", targetFolder: "/Volumes/test")
        plan.exportOriginals = false
        preferences.plans.append(plan)
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yamlExportOriginals, yamlStr, "Yaml string not as expected")
    }
    
    /**
     * Test deserialization of the "exportOriginals" attribute
     */
    func testDeserializeExportOriginals() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yamlExportOriginals)
        
        XCTAssertEqual(1, preferences.plans.count)
        
        XCTAssertEqual("FileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
        XCTAssertEqual(nil, (preferences.plans[0] as! FileSystemExportPlan).exportCalculated)
        XCTAssertEqual(false, (preferences.plans[0] as! FileSystemExportPlan).exportOriginals)
    }


    
}

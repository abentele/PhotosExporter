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

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSerialize0() {
        let preferences = Preferences()
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml0, yamlStr, "Yaml string not as expected")
    }

    func testSerialize1() {
        let preferences = Preferences()
        preferences.plans.append(FileSystemExportPlan(name: "Incremental export example", targetFolder: "/Volumes/test"))
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml1, yamlStr, "Yaml string not as expected")
    }

    func testSerialize2() {
        let preferences = Preferences()
        preferences.plans.append(FileSystemExportPlan(name: "Incremental export example", targetFolder: "/Volumes/test"))
        preferences.plans.append(GooglePhotosExportPlan(name: "Google photos example"))
        
        let yamlStr = preferences.toYaml()
        
        XCTAssertEqual(yaml2, yamlStr, "Yaml string not as expected")
    }
    
    func testDeserialize0() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yaml0)
        
        XCTAssertEqual(0, preferences.plans.count)
    }

    func testDeserialize1() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yaml1)
        
        XCTAssertEqual(1, preferences.plans.count)
        XCTAssertEqual("FileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)
    }
    
    func testDeserialize2() {
        let preferencesReader = PreferencesReader()
        
        let preferences = preferencesReader.preferencesFromYaml(yamlStr: yaml2)
        
        XCTAssertEqual(2, preferences.plans.count)

        XCTAssertEqual("FileSystemExport", preferences.plans[0].getType())
        XCTAssertEqual("Incremental export example", preferences.plans[0].name)
        XCTAssertEqual("/Volumes/test", (preferences.plans[0] as! FileSystemExportPlan).targetFolder)

        XCTAssertEqual("GooglePhotosExport", preferences.plans[1].getType())
        XCTAssertEqual("Google photos example", preferences.plans[1].name)
    }

}

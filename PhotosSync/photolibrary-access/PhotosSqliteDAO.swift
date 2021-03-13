//
//  PhotosSqliteDAO.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 15.12.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
  case OpenDatabase(message: String)
  case Prepare(message: String)
  case Step(message: String)
  case Bind(message: String)
}

class PhotosSqliteDAO {
    
    fileprivate var dbPointer: OpaquePointer?
    
    init(config: Config) throws {
        try openDatabase(path: config.photosLibraryPath! + "/database/Photos.sqlite")
    }
    
    func openDatabase(path: String) throws {
      var db: OpaquePointer? = nil
      if sqlite3_open(path, &db) == SQLITE_OK {
        
        dbPointer = db

        print("Successfully opened connection to database.")
      } else {
        defer {
          if db != nil {
            sqlite3_close(db)
          }
        }

        if let errorPointer = sqlite3_errmsg(db) {
          let message = String(cString: errorPointer)
          throw SQLiteError.OpenDatabase(message: message)
        } else {
          throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
        }
      }
    }
    
    deinit {
      sqlite3_close(dbPointer)
    }
    
    func readOriginalFilePath() throws -> [String:String] {

        let stmt = try prepareStatement(sql:
            """
            select ZASSET.ZUUID, ZASSET.ZDIRECTORY || '/' || ZASSET.ZFILENAME
            from ZASSET
            """
        )
            
        defer {
          sqlite3_finalize(stmt)
        }
        
        var result: [String:String] = [:]

        while sqlite3_step(stmt) == SQLITE_ROW {
            let zuuid_cString = sqlite3_column_text(stmt, 0)
            let path_cString = sqlite3_column_text(stmt, 1)
            
            if let zuuid_cString = zuuid_cString, let path_cString = path_cString {
                let zuuid = String(cString: zuuid_cString)
                let path = String(cString: path_cString)
                
                result[zuuid] = path
            }
        }
        return result
    }
    
    func readKeywords() throws -> [String:[String]] {

        let stmt = try prepareStatement(sql:
            """
            SELECT ZASSET.zuuid, zkeyword.ZTITLE
            FROM Z_1KEYWORDS
            join zkeyword on zkeyword.Z_PK = z_1keywords.z_36keywords
            join ZADDITIONALASSETATTRIBUTES on ZADDITIONALASSETATTRIBUTES.z_pk = Z_1ASSETATTRIBUTES
            join ZASSET on ZASSET.ZADDITIONALATTRIBUTES = ZADDITIONALASSETATTRIBUTES.Z_PK
            """
        )
            
        defer {
          sqlite3_finalize(stmt)
        }
        
        var result: [String:[String]] = [:]

        while sqlite3_step(stmt) == SQLITE_ROW {
            let zuuid_cString = sqlite3_column_text(stmt, 0)
            let keyword_cString = sqlite3_column_text(stmt, 1)
            
            if let zuuid_cString = zuuid_cString, let keyword_cString = keyword_cString {
                let zuuid = String(cString: zuuid_cString)
                let keyword = String(cString: keyword_cString)
                
//                if zuuid == "DEFDFF1A-11DD-4EC4-A72D-F13FB2B4B2ED" {
//                    print("keyword: \(keyword)")
//                }
                
                if var keywords = result[zuuid] {
                    keywords += [keyword]
                    result[zuuid] = keywords
                } else {
                    result[zuuid] = [keyword]
                }
                
            }
        }
        return result
    }
    
    func readTitles() throws -> [String:String] {

            let stmt = try prepareStatement(sql:
                """
                select
                  ZASSET.ZUUID,
                  ZADDITIONALASSETATTRIBUTES.ZTITLE
                from ZASSET
                join ZADDITIONALASSETATTRIBUTES on ZASSET.ZADDITIONALATTRIBUTES = ZADDITIONALASSETATTRIBUTES.Z_PK
                where not ZADDITIONALASSETATTRIBUTES.ZTITLE is null and ZADDITIONALASSETATTRIBUTES.ZTITLE <> ''
                """
            )
                
            defer {
              sqlite3_finalize(stmt)
            }
            
            var result: [String:String] = [:]

            while sqlite3_step(stmt) == SQLITE_ROW {
                let zuuid_cString = sqlite3_column_text(stmt, 0)
                let title_cString = sqlite3_column_text(stmt, 1)
                
                if let zuuid_cString = zuuid_cString, let title_cString = title_cString {
                    let zuuid = String(cString: zuuid_cString)
                    let title = String(cString: title_cString)
                    
                    result[zuuid] = title
                    
                }
            }
            return result
        }
    
    func prepareStatement(sql: String) throws -> OpaquePointer? {
      var statement: OpaquePointer? = nil
      guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
        throw SQLiteError.Prepare(message: "Could not prepare statement")
      }

      return statement
    }

}

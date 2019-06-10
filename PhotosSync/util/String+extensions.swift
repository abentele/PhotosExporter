//
//  String+extensions.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 02.03.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

extension String {
    
    // hash(0) = 5381
    // hash(i) = hash(i - 1) * 33 ^ str[i];
    var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
    
    func indent(_ count: Int) -> String {
        var result: String = "\(self)"
        if (count > 0) {
            for _ in 1...count {
                result = " \(result)"
            }
        }
        return result
    }

}

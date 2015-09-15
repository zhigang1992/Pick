//
//  Utils.swift
//  pick
//
//  Created by kylefang on 9/15/15.
//  Copyright © 2015 hackplan. All rights reserved.
//

import Foundation

extension Array {
    func sample() -> Element {
        let randomIndex = Int(arc4random_uniform(UInt32(self.count)))
        return self[randomIndex]
    }
}
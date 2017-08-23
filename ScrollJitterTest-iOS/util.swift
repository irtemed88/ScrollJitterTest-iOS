//
//  util.swift
//  ScrollJitterTest-iOS
//
//  Created by Demetri Miller on 8/17/17.
//  Copyright © 2017 Demetri Miller. All rights reserved.
//

import Foundation

func pin<T: Comparable>(aMin: T, value: T, aMax: T) -> T {
    var result = max(aMin, value)
    result = min(aMax, result)
    return result
}

//
//  Comparable Extensions.swift
//  Timely
//
//  Created by Pierce Oxley on 12/1/26.
//

import Foundation

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
        
    }
}

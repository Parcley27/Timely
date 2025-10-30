//
//  Date Extensions.swift
//  Timely
//
//  Created by Pierce Oxley on 29/10/25.
//

import Foundation

extension Date {
    func formattedDate(_ style: DateFormatterStyle = .medium) -> String {
        let oneWeekInSeconds: Double = 60 * 60 * 24 * 7
        let dateFormatter = DateFormatter()
        
        if abs(self.timeIntervalSinceNow) < oneWeekInSeconds {
            if Calendar.current.isDate(self, inSameDayAs: Date()) {
                return NSLocalizedString("Today", comment: "")
                
            } else if Calendar.current.isDateInYesterday(self) {
                return NSLocalizedString("Yesterday", comment: "")
                
            } else if Calendar.current.isDateInTomorrow(self) {
                return NSLocalizedString("Tomorrow", comment: "")
                
            } else {
                dateFormatter.dateFormat = "EEEE"
                let dayString = dateFormatter.string(from: self)
                
                if self.timeIntervalSinceNow > 0.0 {
                    return dayString
                    
                } else {
                    let stringFormat = NSLocalizedString("Last %@", comment: "")
                    return String(format: stringFormat, dayString)
                    
                }
            }
            
        }
        
        if Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year) {
            dateFormatter.dateFormat = "MMMM d"
            
        }
        
        switch style {
        case .short:
            dateFormatter.dateStyle = .short
            
        case .medium:
            dateFormatter.dateStyle = .medium
            
        case .long:
            dateFormatter.dateStyle = .long
            
        case .full:
            dateFormatter.dateStyle = .full
            
        }
        
        return dateFormatter.string(from: self)
        
    }
    
    func isSameDay(as other: Date) -> Bool {
        if Calendar.current.isDate(self, equalTo: other, toGranularity: .day) {
            return true
            
        }
        
        return false
        
    }
}

enum DateFormatterStyle {
    case short
    case medium
    case long
    case full
    
}

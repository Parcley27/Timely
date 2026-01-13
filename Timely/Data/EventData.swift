//
//  EventData.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI

class EventData : ObservableObject {
    @Published var events = [
        Event(name: "Riding Lesson", emoji: "🐎"),
        Event(name: "Lazer Tag", emoji: "🔫"),
        Event(name: "Nature Walk", emoji: "🌲")
    ]
}

// Seasonally every 3 months
// recurringTimeOptions: [String] = ["never", "daily", "weekly", "monthly", "annualy"]

struct Event: Identifiable, Codable, Hashable {
    var name: String? = "Event Name"
    var emoji: String? = "📅"
    
    func averageColour(saturation: Double = 1.0, brightness: Double = 1.0, opacity: Double = 1.0) -> Color? {
        // Render Emoji as an Image
        let size = CGSize(width: 7, height: 7)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        
        let rect = CGRect(origin: .zero, size: size)
        
        UIRectFill(rect)
        
        // Draw emoji
        let font = UIFont.systemFont(ofSize: 7)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        self.emoji!.draw(in: rect, withAttributes: attributes)
        
        // Get image from emoji drawing
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        
        // Extract Pixel Data
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = calloc(height * width * 4, MemoryLayout<CUnsignedChar>.size)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let context = CGContext(data: rawData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Calculate Average Colour
        let data = UnsafePointer<CUnsignedChar>(context!.data!.assumingMemoryBound(to: CUnsignedChar.self))
        
        var redTotal = 0
        var greenTotal = 0
        var blueTotal = 0
        
        for x in 0..<width {
            for y in 0..<height {
                let pixelIndex = (width * y + x) * bytesPerPixel
                
                let red = data[pixelIndex]
                let green = data[pixelIndex + 1]
                let blue = data[pixelIndex + 2]
                
                redTotal += Int(red)
                greenTotal += Int(green)
                blueTotal += Int(blue)
                
            }
        }
        
        let pixelCount = width * height
        
        let averageRed = Double(redTotal) / Double(pixelCount) / 255.0
        let averageGreen = Double(greenTotal) / Double(pixelCount) / 255.0
        let averageBlue = Double(blueTotal) / Double(pixelCount) / 255.0
        
        let baseColour = Color(red: averageRed, green: averageGreen, blue: averageBlue)
        
        if baseColour.isGreyscale {
            return baseColour.asGreyscale(brightness: brightness, opacity: opacity)
            
        } else {
            return baseColour.adjusted(saturation: saturation, brightness: brightness, opacity: opacity)
            
        }
        
    }
    
    var description: String?
    
    var dateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        return currentDate.addingTimeInterval(oneDayInSeconds)
        
    }()
    var endDateAndTime: Date?
    var isAllDay: Bool? = false
    var isOnDates: [Date] {
        var dates: [Date] = []
        var currentDate = dateAndTime
        
        let oneDayInSeconds: Double = 24 * 60 * 60
        
        while currentDate <= endDateAndTime ?? dateAndTime {
            dates.append(currentDate)
            
            currentDate = currentDate.addingTimeInterval(oneDayInSeconds)
            
        }
        
        return dates
        
    }
    
    var dateString: String? {
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "dd MMM, yyyy 'at' h:mm a"
        // Auto adapts to user system settings
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var formattedDate = "Event Date and Time String"
        
        func isBeforeOrAfter12(date: Date) -> String {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            
            if hour < 12 {
                return "AM"
                
            } else {
                return "PM"
                
            }
        }
        
        if endDateAndTime != nil {
            if dateAndTime == endDateAndTime! {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, d MMMM yyyy", comment: "")
                
                formattedDate = dateFormatter.string(from: dateAndTime)
                
            } else if Calendar.current.isDate(dateAndTime, equalTo: endDateAndTime!, toGranularity: .day) {
                if isBeforeOrAfter12(date: dateAndTime) == isBeforeOrAfter12(date: endDateAndTime!) {
                    dateFormatter.dateFormat = "h:mm"
                    let firstTime = dateFormatter.string(from: dateAndTime)
                    
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEE, d MMMM yyyy", comment: "")
                    let secondTime = dateFormatter.string(from: endDateAndTime!)
                    
                    // "\(firstTime) to \(secondTime)"
                    let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                    formattedDate = String(format: stringFormat, firstTime, secondTime)
                    
                } else {
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a", comment: "")
                    let firstTime = dateFormatter.string(from: dateAndTime)
                    
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEE, d MMMM yyyy", comment: "")
                    let secondTime = dateFormatter.string(from: endDateAndTime!)
                    
                    // "\(firstTime) to \(secondTime)"
                    let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                    formattedDate = String(format: stringFormat, firstTime, secondTime)
                    
                }
                
            } else if Calendar.current.isDate(dateAndTime, equalTo: endDateAndTime!, toGranularity: .year) {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, d MMMM", comment: "")
                let firstTime = dateFormatter.string(from: dateAndTime)
                
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, d MMMM yyyy", comment: "")
                let secondTime = dateFormatter.string(from: endDateAndTime!)
                
                // "\(firstTime) to\n\(secondTime)"
                let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                formattedDate = String(format: stringFormat, firstTime, secondTime)
                
            } else {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, d MMM yyyy", comment: "")
                
                let firstTime = dateFormatter.string(from: dateAndTime)
                let secondTime = dateFormatter.string(from: endDateAndTime!)
                
                // "\(firstTime) to\n\(secondTime)"
                let stringFormat = NSLocalizedString("%1$@ to\n%2$@", comment: "")
                formattedDate = String(format: stringFormat, firstTime, secondTime)
                
            }
            
        } else {
            dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, d MMMM yyyy", comment: "")
            
            formattedDate = dateFormatter.string(from: dateAndTime)
            
        }
        
        if isAllDay ?? false {
            dateFormatter.dateFormat = NSLocalizedString("'All day on' EEEE, d MMMM yyyy", comment: "")
            
            formattedDate = dateFormatter.string(from: dateAndTime)
            
        }
        
        return formattedDate
        
    }
    var timeUntil: String {
        let timeIntervalToStart = dateAndTime.timeIntervalSinceNow
        let timeIntervalToEnd = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        
        let oneDayInSeconds = 86000.0
        let oneHourInSeconds = 3600.0
        let oneMinuteInSeconds = 60.0
        
        var isWithin60Sec = false
        
        if timeIntervalToStart > oneDayInSeconds || timeIntervalToEnd < -oneDayInSeconds {
            formatter.allowedUnits = [.year, .month, .day, .hour]
            
        } else if timeIntervalToStart > oneHourInSeconds || timeIntervalToEnd < -oneHourInSeconds {
            formatter.allowedUnits = [.day, .hour, .minute]
            
        } else if timeIntervalToStart > oneMinuteInSeconds || timeIntervalToEnd < -oneMinuteInSeconds {
            formatter.allowedUnits = [.minute]
            
        } else {
            isWithin60Sec = true
            
        }
           
        /*
        if let formattedString = formatter.string(from: timeInterval) {
            return formattedString
            
        } else {
            return "Time Until Date"
            
        }
         */
        
        //if hasStarted == false {
            //return formatter.string(from: timeIntervalToStart)!
        
        if hasPassed {
            if isWithin60Sec {
                return NSLocalizedString("Less than a minute ago", comment: "")
                
            } else if var timePastString = formatter.string(from: timeIntervalToEnd) {
                timePastString.remove(at: timePastString.startIndex)
                
                let timeAgoFormat = NSLocalizedString("%@ ago", comment: "")
                return String(format: timeAgoFormat, timePastString)
                
            } else {
                return NSLocalizedString("Time Unknown", comment: "")
                
            }
            
        } else if hasStarted && !hasPassed {
            //let rightNowString = NSLocalizedString("Right Now", comment: "")
            
            if timeIntervalToEnd < oneMinuteInSeconds {
                return NSLocalizedString("Ends in less than a minute", comment: "")
            
            } else if timeIntervalToEnd < oneHourInSeconds {
                formatter.allowedUnits = [.minute]
                
            } else if timeIntervalToEnd < oneDayInSeconds {
                formatter.allowedUnits = [.hour, .minute]
                
            } else {
                formatter.allowedUnits = [.year, .month, .day, .hour]
            }
            
            let timeUntilEnd = formatter.string(from: timeIntervalToEnd)!
            let endingInFormat = NSLocalizedString("Ending in %@", comment: "")
            let timeUntilEndString = String(format: endingInFormat, timeUntilEnd)
            
            //return (rightNowString + "\n") + timeUntilEndString
            return timeUntilEndString
            
        } else {
            if isWithin60Sec {
                return NSLocalizedString("Less than a minute", comment: "")
                
            } else if let timeUntilString = formatter.string(from: timeIntervalToStart) {
                return timeUntilString
                
            } else {
                return NSLocalizedString("Time Unknown", comment: "")
                
            }
        }
    }
    
    var hasStarted: Bool {
        let timeInterval = dateAndTime.timeIntervalSinceNow
        
        if timeInterval <= 0.0 {
            return true
            
        } else {
            return false
            
        }
    }
    var hasPassed: Bool {
        let timeInterval = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        if timeInterval <= 0.0 {
            return true
            
        } else {
            return false
            
        }
    }
    
    func hasExpired(maxTime: Int = 3600) -> Bool {
        let timeInterval = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        if timeInterval < -Double(maxTime) {
            return true
            
        } else {
            return false
            
        }
    }
    
    var isRecurring: Bool? = false
    var recurranceRate: String? = "never"
    var recurringTimes: Int? = 0
    
    var isCopy: Bool? = false
    var copyOfEventWithID: UUID?
    var copyNumber: Int?
    
    var isFavourite: Bool = false
    var isStandard: Bool {
        if !isFavourite && !isMuted {
            return true
            
        } else {
            return false
            
        }
    }
    var isMuted: Bool = false
    
    var id: UUID = UUID()
    
}

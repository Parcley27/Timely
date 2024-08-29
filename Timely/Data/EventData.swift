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

struct Event : Identifiable, Codable {
    var name: String? = "Event Name"
    var emoji: String? = "📅"
    
    func averageColor(saturation: Double = 1.0, brightness: Double = 1.0, opacity: Double = 1.0) -> Color? {
        // Render Emoji as an Image
        let size = CGSize(width: 7, height: 7) // Size of the image to render
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        
        // Draw emoji
        let font = UIFont.systemFont(ofSize: 7) // Adjust font size as needed
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
        
        // Calculate Average Color
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
        let avgRed = Double(redTotal) / Double(pixelCount) / 255.0
        let avgGreen = Double(greenTotal) / Double(pixelCount) / 255.0
        let avgBlue = Double(blueTotal) / Double(pixelCount) / 255.0
        
        // Adjust Saturation and Brightness
        let avgColor = UIColor(red: CGFloat(avgRed), green: CGFloat(avgGreen), blue: CGFloat(avgBlue), alpha: 1.0)
        
        var hue: CGFloat = 0
        var saturationValue: CGFloat = 0
        var brightnessValue: CGFloat = 0
        var alpha: CGFloat = 0
        
        avgColor.getHue(&hue, saturation: &saturationValue, brightness: &brightnessValue, alpha: &alpha)
        
        saturationValue = max(0, min(CGFloat(saturation), 1))
        brightnessValue = max(0, min(CGFloat(brightness), 1))
        
        let adjustedColor = UIColor(hue: hue, saturation: saturationValue, brightness: brightnessValue, alpha: CGFloat(opacity))
        
        // Convert to SwiftUI Color
        return Color(adjustedColor)
        
    }
    
    var description: String?
    
    var dateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        return currentDate.addingTimeInterval(oneDayInSeconds)
        
    }()
    var endDateAndTime: Date?
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
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d, yyyy", comment: "")
                
                formattedDate = dateFormatter.string(from: dateAndTime)
                
            } else if Calendar.current.isDate(dateAndTime, equalTo: endDateAndTime!, toGranularity: .day) {
                if isBeforeOrAfter12(date: dateAndTime) == isBeforeOrAfter12(date: endDateAndTime!) {
                    dateFormatter.dateFormat = "h:mm"
                    let firstTime = dateFormatter.string(from: dateAndTime)
                    
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEE, MMMM d, yyyy", comment: "")
                    let secondTime = dateFormatter.string(from: endDateAndTime!)
                    
                    // "\(firstTime) to \(secondTime)"
                    let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                    formattedDate = String(format: stringFormat, firstTime, secondTime)
                    
                } else {
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a", comment: "")
                    let firstTime = dateFormatter.string(from: dateAndTime)
                    
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEE, MMMM d, yyyy", comment: "")
                    let secondTime = dateFormatter.string(from: endDateAndTime!)
                    
                    // "\(firstTime) to \(secondTime)"
                    let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                    formattedDate = String(format: stringFormat, firstTime, secondTime)
                    
                }
                
            } else if Calendar.current.isDate(dateAndTime, equalTo: endDateAndTime!, toGranularity: .year) {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d", comment: "")
                let firstTime = dateFormatter.string(from: dateAndTime)
                
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d, yyyy", comment: "")
                let secondTime = dateFormatter.string(from: endDateAndTime!)
                
                // "\(firstTime) to\n\(secondTime)"
                let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                formattedDate = String(format: stringFormat, firstTime, secondTime)
                
            } else {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMM d, yyyy", comment: "")
                
                let firstTime = dateFormatter.string(from: dateAndTime)
                let secondTime = dateFormatter.string(from: endDateAndTime!)
                
                // "\(firstTime) to\n\(secondTime)"
                let stringFormat = NSLocalizedString("%1$@ to\n%2$@", comment: "")
                formattedDate = String(format: stringFormat, firstTime, secondTime)
                
            }
            
        } else {
            dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d, yyyy", comment: "")
            
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
        
        if timeIntervalToStart > oneDayInSeconds || timeIntervalToEnd < -oneDayInSeconds {
            formatter.allowedUnits = [.year, .month, .day, .hour]
            
        } else if timeIntervalToStart > oneHourInSeconds || timeIntervalToEnd < -oneHourInSeconds {
            formatter.allowedUnits = [.day, .hour, .minute]
            
        } else if timeIntervalToStart > oneMinuteInSeconds || timeIntervalToEnd < -oneMinuteInSeconds {
            formatter.allowedUnits = [.minute, .second]
            
        } else {
            formatter.allowedUnits = [.second]
            
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
            if var timePastString = formatter.string(from: timeIntervalToEnd) {
                timePastString.remove(at: timePastString.startIndex)
                
                let timeAgoFormat = NSLocalizedString("%@ ago", comment: "")
                return String(format: timeAgoFormat, timePastString)
                
            } else {
                return NSLocalizedString("Time Unknown", comment: "")
                
            }
            
        } else if hasStarted && !hasPassed {
            //let rightNowString = NSLocalizedString("Right Now", comment: "")
            
            if timeIntervalToEnd < oneHourInSeconds {
                formatter.allowedUnits = [.minute, .second]
                
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
            if let timeUntilString = formatter.string(from: timeIntervalToStart) {
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
    
    // One hour in seconds
    func hasExpired(maxTime: Int = 3600) -> Bool {
        let timeInterval = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        if timeInterval < -Double(maxTime) {
            return true
            
        } else {
            return false
            
        }
    }
    
    var isFavourite: Bool = false
    
    var isStandard: Bool {
        if !isFavourite && !isMuted {
            return true
            
        } else {
            return false
            
        }
    }
    
    var isMuted: Bool = false
    
    var id = UUID()
}

extension EventData {
    func removeEvent(event: Event) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            events.remove(at: index)
            
        }
    }
    
    func updateEventName(event: Event, newName: String) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            events[index].name = newName
            
        }
    }
    
    func toggleFavouriteEvent(event: Event) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            if events[index].isFavourite == true {
                events[index].isFavourite = false
                
            } else {
                events[index].isFavourite = true
                
            }
        }
    }
    
    func toggleMutedEvent(event: Event) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            if events[index].isMuted == true {
                events[index].isMuted = false
                
            } else {
                events[index].isMuted = true
                
            }
        }
    }
    
    func timeUntil(inputDate: Date, format: String? = "Full Date") -> String {
        let timeInterval = inputDate.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        
        if format == "Full Date" {
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.year, .day, .hour, .minute, .second]
            
        }
        
        if format == "Seconds" {
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.second]
            
        }
        
        if var formattedString = formatter.string(from: timeInterval) {
            formattedString = formattedString.replacingOccurrences(of: ",", with: "")
            
            let timeAgoFormat = NSLocalizedString("%@ ago", comment: "")
            
            return String(format: timeAgoFormat, formattedString)
            
        } else {
            return NSLocalizedString("Time Unknown", comment: "")
            
        }
    }
    
    func dateDisplayString(event: Event) -> String {
        let dateToDisplay = event.dateAndTime
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateString = dateFormatter.string(from: dateToDisplay)
        
        if dateString != "" {
            return dateString
            
        } else {
            return "Date unknown"
            
        }
    }
    
    func passedEvents() -> Int {
        var count = 0
        
        for event in events {
            if event.hasPassed {
                count += 1
                
            }
        }
        
        return count
        
    }
    
    func indexFor(_ event: Event) ->  Double {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            return Double(index)
            
        }
        
        return 0.0
        
    }
}

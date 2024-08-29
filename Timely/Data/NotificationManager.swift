//
//  NotificationManager.swift
//  Timely
//
//  Created by Pierce Oxley on 15/8/24.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    var events = EventStore().getAllEvents()
    
    var allNotificationTimes: [Int] = [0, 15, 60]
    
    func formatTimeForNotification(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
        
    }
    
    func scheduleNotificationsForAllEvents() {
        removeAllNotifications()
        
        for event in events {
            scheduleNotifications(for: event)
            
        }
    }
    
    func scheduleNotifications(for event: Event) {
        let standardTimes: [Int] = [0, 15]
        let favouriteTimes: [Int] = [0, 15, 60]
        
        if !event.isMuted && !event.hasExpired() {
            if event.isFavourite {
                for time in favouriteTimes {
                    addNotification(for: event, time: time)
                    
                }
                
            } else {
                for time in standardTimes {
                    addNotification(for: event, time: time)
                    
                }
            }
        }
    }
    
    func addNotification(for event: Event, time: Int) {
        let notificationIdentifier = "\(event.id.uuidString) \(time) minutes"
        
        let content = UNMutableNotificationContent()
        content.title = "\(event.name!) • \(event.emoji!)"
        content.sound = .default
        
        let eventTime = formatTimeForNotification(from: event.dateAndTime)
        
        if time == 0 {
            // Starting Now!
            content.body = NSLocalizedString("Starting Now!", comment: "")
            
        } else if time < 60 {
            // Starting in \(time) minutes, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in %1$@ minutes, at %2$@.", comment: ""), String(time), eventTime)
            
        } else if time == 60 {
            // Starting in 1 hour, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in 1 hour, at %@.", comment: ""), eventTime)
            
        } else if time > 60 {
            // Starting in \(time/60) hours, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in %1$@ hours, at %2$@.", comment: ""), String(format: "%.1f", Double(time) / 60.0), eventTime)
            
        }
        
        if event.isFavourite && time <= 15 {
            content.interruptionLevel = .timeSensitive
            
        }
        
        content.threadIdentifier = event.id.uuidString
        
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -time, to: event.dateAndTime)
        guard let triggerDate = triggerDate else { return }
        
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
                
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        print("Removing notifications")
        
    }
}

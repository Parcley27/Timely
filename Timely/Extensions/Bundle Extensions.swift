//
//  Bundle Extensions.swift
//  Timely
//
//  Created by Pierce Oxley on 12/10/25.
//

import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
    }
    
    var fullVersion: String {
        return "v\(appVersion) (\(NSLocalizedString("Build", comment: "")) \(buildNumber))"
        
    }
}

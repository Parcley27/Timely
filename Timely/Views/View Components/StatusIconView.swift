//
//  StatusIconView.swift
//  Timely
//
//  Created by Pierce Oxley on 4/4/26.
//

import SwiftUI

struct StatusIconView: View {
    enum IconType: String {
        case pinned
        case favourite
        case muted
        case repeating
        
    }
    
    let icons: [IconType: String] = [
        .pinned: "pin.fill",
        .favourite: "star.fill",
        .muted: "bell.slash.fill",
        .repeating: "repeat.circle.fill"
    
    ]
    
    let colours: [IconType: Color] = [
        .pinned: .red,
        .favourite: .yellow,
        .muted: .purple,
        .repeating: .cyan
        
    ]
    
    let iconType: IconType
    let colour: Color?
    
    init (_ iconStyle: IconType = .pinned, _ colour: Color? = nil) {
        self.iconType = iconStyle
        self.colour = colour
        
    }
    
    var body: some View {
        Image(systemName: icons[iconType]!)
            .foregroundStyle(colour ?? colours[iconType]!)
        
    }
}

#Preview {
    StatusIconView(.pinned)
    StatusIconView(.favourite)
    //StatusIconView(.muted, .green)
    StatusIconView(.muted)
    StatusIconView(.repeating)
    
}

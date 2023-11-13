//
//  Settings.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI
        
struct Settings: View {
    
    @EnvironmentObject var data: EventData
    
    var body: some View {
        VStack {
            Image(systemName: "gearshape.fill")
            Text("Hello, Settings!")
            
            // Fix reference
            //Text(outsideTest)
            
            List{
                ForEach(data.events) { event in
                    HStack {
                        Text(event.name ?? "EventName")
                        Spacer()
                        Text(event.emoji ?? "📅")
                    }
                }
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}

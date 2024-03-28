//
//  Settings.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI
        
struct Settings: View {
    @Environment(\.dismiss) var dismiss
    
    //@EnvironmentObject var data: EventData
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "gearshape.fill")
                Text("Hello, Settings!")
                
                // Fix reference
                //Text(outsideTest)
                /*
                List($data) { $event in
                    Text(event.name ?? "eventName")
                    /*
                    ForEach($scrums.event) { $event in
                        HStack {
                            Text(event.name ?? "EventName")
                            Spacer()
                            Text(event.emoji ?? "📅")
                        }
                     */

                }
                 */
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button ("Done") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}

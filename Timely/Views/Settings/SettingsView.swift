//
//  Settings.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI
        
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    //@EnvironmentObject var data: EventData
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "gearshape.fill")
                Text("Hello, Settings!")
                
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

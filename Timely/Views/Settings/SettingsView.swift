//
//  Settings.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI
        
struct SettingsView: View {
    @StateObject private var preferences = SettingsStore()
    @State var editedAutoDelete: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                
                //Image(systemName: "gearshape.fill")
                //Text("Hello, Settings!")
                
                Form {
                    Section("App Behaviour") {
                        Toggle(isOn: $preferences.showBadge) {
                            Text("In-app Notifications")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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

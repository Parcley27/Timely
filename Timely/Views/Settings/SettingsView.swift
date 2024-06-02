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
    @Environment(\.openURL) var openURL
    
    private var gitHubLink: some View {
        HStack {
            Text("Contribute to Timely")
            Spacer()
            Image(systemName: "arrow.up.forward.app")
        }
        .foregroundStyle(.blue)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                //Image(systemName: "gearshape.fill")
                //Text("Hello, Settings!")
                
                List {
                    Section("App Behaviour") {
                        Toggle(isOn: $preferences.showBadge) {
                            Text("In-app Notifications")
                            
                        }
                        
                        Toggle(isOn: $preferences.deletePassedEvents) {
                            Text("Delete Passed Events")
                        }
                        
                    }
                    
                    Section("Credits") {
                        Text("Created by Pierce Oxley")
                        Text("Special thanks to my family, Dale Dai, and everyone else along the way.")
                        Button {
                            openURL(URL(string: "https://github.com/Parcley27/Timely")!)

                        } label: {
                            gitHubLink
                            
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

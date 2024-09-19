//
//  Settings.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI
import MessageUI

struct NoMailView: View {
    var body: some View {
        Text("Cannot Send Mail")
            .bold()
        
        Text("Check that email is set up on your device")
        
    }
}

struct SettingsView: View {
    @StateObject private var preferences = SettingsStore()
    @State var editedAutoDelete: Bool = false
    
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    
    @State private var showGetSupport = false
    @State private var showIssueReport = false
    @State private var showFeatureRequest = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @State private var showConfirmationDialog: Bool = false
    @State private var temporaryToggleState: Bool = false
    
    private var gitHubLink: some View {
        HStack {
            Text("Contribute to Timely")
            Spacer()
            Image(systemName: "arrow.up.forward.app")
            
        }
        .foregroundStyle(.blue)
    }
    
    func customButton(text: String, icon: String) -> some View {
        HStack {
            Text(text)
            Spacer()
            ZStack {
                Image(systemName: icon)
                
                Text("📅")
                    .opacity(0)
                
            }
        }
        .foregroundStyle(.blue)
        
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("App Behaviour") {
                        Toggle(isOn: $preferences.quickAdd) {
                            Text("Quick-Add Events")
                            
                        }
                        
                        Toggle(isOn: $preferences.showBadge) {
                            Text("In-App Notifications")
                            
                        }
                        
                        Toggle(isOn: $preferences.listTinting) {
                            Text("List Tinting")
                            
                        }
                    }
                    
                    Section("Event History") {
                        Toggle(isOn: $preferences.removePassedEvents) {
                            if preferences.keepEventHistory {
                                Text("Archive Passed Events")
                                
                            } else {
                                Text("Delete Passed Events")
                                
                            }
                        }
                        
                        Toggle(isOn: Binding(
                            get: { preferences.keepEventHistory },
                            set: { newValue in
                                if !newValue {
                                    temporaryToggleState = newValue
                                    showConfirmationDialog = true
                                    
                                } else {
                                    preferences.keepEventHistory = newValue
                                    
                                }
                            }
                        )) {
                            Text("Keep Event History")
                            
                        }
                        .confirmationDialog(Text("Turn Off Event History?"),
                            isPresented: $showConfirmationDialog,
                            titleVisibility: .visible,
                            actions: {
                                Button("Turn Off and Delete", role: .destructive) {
                                    preferences.keepEventHistory = temporaryToggleState
                                    
                                }
                            },
                            message: {
                                Text("All archived events will be permanently deleted")
                            
                            }
                        )
                    }
                    
                    Section("Contact") {
                        Button() {
                            self.showGetSupport.toggle()
                            
                        } label: {
                            customButton(text: NSLocalizedString("Get Support", comment: ""), icon: "questionmark.circle")
                            
                        }
                        
                        Button() {
                            self.showIssueReport.toggle()
                            
                        } label: {
                            customButton(text: NSLocalizedString("Report an Issue", comment: ""), icon: "exclamationmark.bubble")
                            
                        }
                        
                        Button() {
                            self.showFeatureRequest.toggle()
                            
                        } label: {
                            customButton(text: NSLocalizedString("Request a Feature", comment: ""), icon: "sparkles")
                            
                        }
                    }
                    
                    Section("Credits") {
                        Button() {
                            openURL(URL(string: "https://github.com/Parcley27")!)
                            
                        } label: {
                            customButton(text: NSLocalizedString("Created by Pierce Oxley", comment: ""), icon: "person.circle")
                            
                        }
                        
                        Text("Special thanks to my family, Dale Dai, and everyone else along the way.")
                        
                    }
                    
                    Section("App Information") {
                        Text("Version")
                            .badge("v\(TimelyApp().versionNumber) - Build \(TimelyApp().buildNumber)")
                        
                        Button() {
                            openURL(URL(string: "https://github.com/Parcley27/Timely")!)
                            
                        } label: {
                            customButton(text: NSLocalizedString("Timely GitHub", comment: ""), icon: "arrow.up.forward.app")
                            
                        }
                    }
                }
            }
            .sheet(isPresented: $showGetSupport) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(result: self.$result, subject: NSLocalizedString("App Support", comment: ""))
                    
                } else {
                    NoMailView()
                    
                }
            }
            .sheet(isPresented: $showIssueReport) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(result: self.$result, subject: NSLocalizedString("Issue Report", comment: ""))
                    
                } else {
                    NoMailView()
                    
                }
            }
            .sheet(isPresented: $showFeatureRequest) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(result: self.$result, subject: NSLocalizedString("Feature Request", comment: ""))
                    
                } else {
                    NoMailView()
                    
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

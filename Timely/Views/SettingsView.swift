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
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var preferences: SettingsStore
    
    @State var editedAutoDelete: Bool = false
    
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    
    @State private var showGetSupport = false
    @State private var showIssueReport = false
    @State private var showFeatureRequest = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var showLayoutChangeConfirmation: Bool = false
    @State private var temporaryLegacyLayout: Bool = false
    
    @State private var showArchiveDisableConfirmation: Bool = false
    @State private var showSettingsResetConfirmation: Bool = false
    @State private var showDeleteEventsConfirmation: Bool = false
    
    @State private var temporaryToggleState: Bool = false
    
    // Plain accent blue and system grey wash out against the accent-tinted tiles,
    // so when tinting is on, use a deeper accent in light mode, a lighter one in dark mode,
    // and a primary-based grey for headings and secondary text
    private var linkColour: Color {
        guard preferences.listTinting else { return .accentColor }
        
        return colorScheme == .light
            ? Color.accentColor.adjusted(saturation: 1.0, brightness: 0.68)
            : Color.accentColor.adjusted(saturation: 0.6, brightness: 1.0)
    }
    
    // Softer red than the system one, which looks harsh on the tinted tiles
    private var dangerColour: Color {
        colorScheme == .light
            ? Color.red.adjusted(saturation: 0.8, brightness: 0.92)
            : Color.red.adjusted(saturation: 0.55, brightness: 1.0)
    }
    
    private var secondaryTextColour: Color {
        preferences.listTinting ? Color.primary.opacity(0.7) : Color.secondary
    }
    
    private var gitHubLink: some View {
        HStack {
            Text("Contribute to Timely")
            Spacer()
            Image(systemName: "arrow.up.forward.app")
            
        }
        .foregroundStyle(linkColour)
        
    }
    
    var listSpacing: CGFloat = 12
    var headingSpacing: CGFloat = 0
    
    func customButton(text: String, icon: String) -> some View {
        HStack {
            Text(text)
                .fontWeight(.medium)
            Spacer()
            ZStack {
                Image(systemName: icon)
                
                Text("📅")
                    .opacity(0)
                
            }
        }
        .foregroundStyle(linkColour)
        
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("App Behaviour")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        Toggle(isOn: $preferences.quickAdd) {
                            Text("Enable Quick Add")
                            
                        }
                        
                        Divider()
                            
                        Toggle(isOn: $preferences.allowContextMenu) {
                            Text("Allow \"Press and Hold\" Actions")
                            
                        }
                        
                        Divider()
                        
                            
                        Toggle(isOn: $preferences.useEmojiKeyboard) {
                            Text("Use Emoji Keyboard")
                        }
                            
                        Divider()
                        
                        Toggle(isOn: $preferences.showBadge) {
                            Text("In-App Notifications")
                            
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                    
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("Appearance")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        Toggle(isOn: Binding(
                            get: { preferences.useLegacyLayout },
                            set: { newValue in
                                temporaryLegacyLayout = newValue
                                showLayoutChangeConfirmation = true
                                
                            }
                        )) {
                            Text("Use Legacy Layout")
                            
                        }
                        .alert(
                            Text("Change Layout Style?"),
                            isPresented: $showLayoutChangeConfirmation,
                            actions: {
                                Button("Cancel", role: .cancel) {}
                                
                                Button("Ok", role: .confirm) {
                                    preferences.useLegacyLayout = temporaryLegacyLayout
                                    
                                }
                            },
                            message: {
                                Text("Timely will restart to apply your changes")
                                
                            }
                        )
                        
                        Divider()
                        
                        Toggle(isOn: $preferences.listTinting) {
                            Text("List Tinting")
                            
                        }
                        
                        Divider()
                        
                        Toggle(isOn: $preferences.showFilmGrain) {
                            Text("Display \"Film Grain\" Effects")
                            
                        }
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                    
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("Event Storage")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        /*
                        Toggle(isOn: $preferences.doiCloudSync) {
                            Text("Sync to iCloud")
                            
                        }
                         */
                        
                        Toggle(isOn: $preferences.removePassedEvents) {
                            if preferences.keepEventHistory {
                                Text("Archive Passed Events")
                                
                            } else {
                                Text("Delete Passed Events")
                                
                            }
                        }
                        
                        Divider()
                        
                        Toggle(isOn: Binding(
                            get: { preferences.keepEventHistory },
                            set: { newValue in
                                if !newValue {
                                    temporaryToggleState = newValue
                                    showArchiveDisableConfirmation = true
                                    
                                } else {
                                    preferences.keepEventHistory = newValue
                                    
                                }
                            }
                        )) {
                            Text("Keep Event History")
                            
                        }
                        .confirmationDialog(Text("Turn Off Event History?"),
                            isPresented: $showArchiveDisableConfirmation,
                            titleVisibility: .visible,
                            actions: {
                                Button("Turn Off and Delete", role: .destructive) {
                                    preferences.keepEventHistory = temporaryToggleState
                                    
                                }
                                
                                Button("Cancel", role: .cancel) {}
                            
                            },
                            message: {
                                Text("All archived events will be permanently deleted")
                            
                            }
                        )
                    
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                    
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("Contact")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        Button() {
                            self.showGetSupport.toggle()
                            
                        } label: {
                            customButton(text: NSLocalizedString("Get Support", comment: ""), icon: "questionmark.circle")
                            
                        }
                        
                        Divider()
                        
                        Button() {
                            self.showIssueReport.toggle()
                            
                        } label: {
                            customButton(text: NSLocalizedString("Report an Issue", comment: ""), icon: "exclamationmark.bubble")
                            
                        }
                        
                        Divider()
                        
                        Button() {
                            self.showFeatureRequest.toggle()
                            
                        } label: {
                            customButton(text: NSLocalizedString("Request a Feature", comment: ""), icon: "lightbulb")
                            
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                    
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("App Information")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        Button() {
                            openURL(URL(string: "https://apps.apple.com/ca/app/timely-event-tracker/id6503667182")!)
                            
                        } label: {
                            customButton(text: NSLocalizedString("App Store Page", comment: ""), icon: "arrow.up.forward.app")
                        }
                        
                        Divider()
                        
                        Button() {
                            openURL(URL(string: "https://github.com/Parcley27/Timely")!)
                            
                        } label: {
                            customButton(text: NSLocalizedString("Timely GitHub", comment: ""), icon: "arrow.up.forward.app")
                            
                        }
                        
                        Divider()
                        
//                        Text("Timely Version \(Bundle.main.fullVersion)")
//                        
//                        Divider()
                        
                        HStack {
                            Text("Version")
                            
                            Spacer()
                            
                            Text("Timely \(Bundle.main.fullVersion)")
                                .foregroundStyle(secondaryTextColour)
                            
                        }
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                    
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("Credits")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        Button() {
                            openURL(URL(string: "https://pierceoxley.ca")!)
                            
                        } label: {
                            customButton(text: NSLocalizedString("Created by Pierce Nestibo-Oxley", comment: ""), icon: "person.circle")
                            
                        }
                        
                        Divider()
                        
                        Text("Special thanks to my family, Dale Dai, and everyone else along the way.")
                            .foregroundStyle(secondaryTextColour)
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                    
                    VStack(alignment: .leading, spacing: listSpacing) {
                        Text("Danger Zone")
                            .font(.headline)
                            .foregroundStyle(secondaryTextColour)
                            .padding(.bottom, headingSpacing)
                        
                        Button () {
                            showSettingsResetConfirmation = true
                            
                        } label: {
                            HStack {
                                Text("Restore Defaults")
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                                
                            }
                            .foregroundStyle(dangerColour)
                            
                        }
                        .confirmationDialog(
                            Text("Reset to Default Settings?"),
                            isPresented: $showSettingsResetConfirmation,
                            titleVisibility: .visible,
                            actions: {
                            Button("Reset", role: .destructive) {
                                    preferences.resetToDefaults()
                                    
                                }
                            },
                            message: {
                                Text("This action cannot be undone")
                            
                            }
                        )
                        
                        Divider()
                        
                        Button () {
                            showDeleteEventsConfirmation = true
                            
                        } label: {
                            HStack {
                                Text("Delete All Events")
                                Spacer()
                                Image(systemName: "trash")
                                
                            }
                            .foregroundStyle(dangerColour)
                            
                        }
                        .confirmationDialog(
                            Text("Delete All Events?"),
                            isPresented: $showDeleteEventsConfirmation,
                            titleVisibility: .visible,
                            actions: {
                                Button("Reset", role: .destructive) {
                                    eventStore.deleteAllEvents()
                                    
                                }
                            },
                            message: {
                                Text("This action cannot be undone")
                            
                            }
                        )
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        TileView(inputColours: preferences.listTinting ? .accentColor : .black, forceBackground: true, saturationModifier: 0.75, customBorder: false)
                        
                    )
                }
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                
                VStack(spacing: 6) {
                    HStack {
                        Rectangle()
                            //.frame(width: 27 * 1.62, height: 2)
                            .frame(width: 27 * 1, height: 2)
                        
                        Image("Centered Logo")
                            .renderingMode(.template)
                            .resizable().scaledToFit()
                            .frame(width: 27)
                        
                        Rectangle()
                            //.frame(width: 27 * 1.62, height: 2)
                            .frame(width: 27 * 1, height: 2)
                        
                    }
                    .padding(.bottom, 6)
                    
                    HStack(spacing: 0) {
                        Text("Made in ")
                            .bold()
                        
                        //Image("Canada Flag BW Transparent")
                        Image("Leaf")
                            .renderingMode(.template)
                            .resizable().scaledToFit()
                            .frame(height: 14)
                        
                        Text(" with ♥︎")
                            .bold()
                        
                    }
                    
                }
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 32)
                
            }
            .scrollContentBackground(preferences.showFilmGrain ? .hidden : .visible)
            .background {
                if preferences.showFilmGrain {
                    NoiseView()
                    
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
                if preferences.useLegacyLayout {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                            
                        }
                    }
                }
            }
            .navigationBarTitle("Settings")
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsStore())
        
    }
}

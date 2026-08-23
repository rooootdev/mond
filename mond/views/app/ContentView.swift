//
//  ContentView.swift
//  mond
//
//  Created by ruter on 17.07.26.
//

import SwiftUI
import PartyUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("method") private var method: String = "bad_query"
    @AppStorage("ignore_failure") private var ignore_failure = false
    
    @State private var is_valid: Bool = false
    @State private var show_settings: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    Label(NSLocalizedString("logs", tableName: "ContentView", comment: "Logs section header"), systemImage: "apple.terminal")
                }
                
                Section {
                    NavigationLink {
                        GestaltView()
                    } label: {
                        HStack {
                            Text("MobileGestalt")
                            if state.granting_mg {
                                Spacer()
                                ProgressView()
                                    .tint(Color.primary)
                            }
                        }
                    }
                    .disabled((state.mg_granted != true) && !ignore_failure)
                    
                    NavigationLink {
                        PosterView()
                    } label: {
                        HStack {
                            Text("PosterBoard")
                            if state.granting_pb {
                                Spacer()
                                ProgressView()
                                    .tint(Color.primary)
                            }
                        }
                    }
                    .disabled((method == "cmg" || state.pb_granted != true) && !ignore_failure)
                    
                    NavigationLink {
                        SantanderView()
                    } label: {
                        HStack {
                            Text("HouseArrest")
                            if state.granting_apps {
                                Spacer()
                                ProgressView()
                                    .tint(Color.primary)
                            }
                        }
                    }
                    .disabled((method == "cmg" || state.apps_granted != true) && !ignore_failure)
                } header: {
                    Label(NSLocalizedString("tweaks", tableName: "ContentView", comment: "Tweaks section header"), systemImage: "paintbrush")
                } footer: {
                    if method == "cmg" {
                         Text(NSLocalizedString("only_mobilegestalt_available", tableName: "ContentView", comment: ""))
                    }
                }
                
                Section {
                    NavigationLink {
                        CEView()
                    } label: {
                        Text("CacheExtra Fields")
                    }
                } header: {
                    Label(NSLocalizedString("advanced", tableName: "ContentView", comment: ""), systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(NSLocalizedString("advanced_warning", tableName: "ContentView", comment: ""))
                }
            }
            .navigationTitle("mond")
            .tint(Color("AccentColor"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            show_settings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $show_settings) {
                SettingsView()
            }
        }
    }
}
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
    @EnvironmentObject private var l10n: L10n
    @AppStorage("method") private var method: String = "bad_query"
    @AppStorage("ignore_failure") private var ignore_failure = false
    
    @State private var is_valid: Bool = false
    @State private var show_settings: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: l10n.language_binding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.display_name).tag(language)
                        }
                    } label: {
                        Label(l10n.t("Language"), systemImage: "globe")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label(l10n.t("Language"), systemImage: "globe")
                } footer: {
                    Text(l10n.t("Choose the language used by the app."))
                }

                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    Label(l10n.t("Logs"), systemImage: "apple.terminal")
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
                    Label(l10n.t("Tweaks"), systemImage: "paintbrush")
                } footer: {
                    if method == "cmg" {
                         Text(l10n.t("Only MobileGestalt is available when method is set to cmg."))
                    }
                }
                
                Section {
                    NavigationLink {
                        CEView()
                    } label: {
                        Text(l10n.t("CacheExtra Fields"))
                    }
                } header: {
                    Label(l10n.t("Advanced"), systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(l10n.t("Only use these Tweaks if you know what you're doing.\nYou could break something irreversibly."))
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

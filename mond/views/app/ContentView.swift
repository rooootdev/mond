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

    @State private var is_valid: Bool = false
    @State private var show_settings: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    Label(String(localized: "Logs"), systemImage: "apple.terminal")
                }

                Section {
                    NavigationLink {
                        GestaltView()
                    } label: {
                        HStack {
                            Text(String(localized: "MobileGestalt"))
                            if state.granting_mg {
                                Spacer()
                                ProgressView()
                                    .tint(Color.primary)
                            }
                        }
                    }
                    .disabled(state.mg_granted != true)

                    NavigationLink {
                        PosterView()
                    } label: {
                        HStack {
                            Text(String(localized: "PosterBoard"))
                            if state.granting_pb {
                                Spacer()
                                ProgressView()
                                    .tint(Color.primary)
                            }
                        }
                    }
                    .disabled(method == "cmg" || state.pb_granted != true)

                    NavigationLink {
                        SantanderView()
                    } label: {
                        HStack {
                            Text(String(localized: "HouseArrest"))
                            if state.granting_apps {
                                Spacer()
                                ProgressView()
                                    .tint(Color.primary)
                            }
                        }
                    }
                    .disabled(method == "cmg" || state.apps_granted != true)
                } header: {
                    Label(String(localized: "Tweaks"), systemImage: "paintbrush")
                } footer: {
                    if method == "cmg" {
                         Text(String(localized: "Only MobileGestalt is available when method is set to cmg."))
                    }
                }
            }
            .navigationTitle(String(localized: "mond"))
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
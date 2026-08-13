//
//  PosterView.swift
//  mond
//
//  Created by ruter on 11.08.26.
//

import SwiftUI
import UniformTypeIdentifiers
import SafariServices
import PartyUI

struct PosterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: AppState
    
    @State private var show_settings: Bool = false
    @State private var show_importer: Bool = false
    @State private var busy = false
    
    @State private var show_browser: Bool = false
    @State private var browser_url = URL(string: "https://cowabunga.serstars.nl/wallpapers")!

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        apply()
                    } label: {
                        HStack {
                            if busy {
                                ProgressView()
                            }
                            
                            Text("Apply")
                        }
                    }
                    .disabled(state.poster_files.isEmpty || busy)

                    Button {
                        reset()
                    } label: {
                        Text("Reset")
                    }
                    .disabled(busy)
                }
                
                Section {
                    Button {
                        show_importer = true
                    } label: {
                        Text("Import Tendies")
                    }
                    .disabled(busy)
                } footer: {
                    Text("Pick one or more .tendies (or .zip) wallpaper packs.\nGet .tendies [here](https://cowabunga.serstars.nl/wallpapers).")
                        .environment(\.openURL, OpenURLAction { url in
                            browser_url = url
                            show_browser = true
                            return .handled
                        })
                        .sheet(isPresented: $show_browser) {
                            SafariView(url: browser_url)
                        }
                }

                if !state.poster_files.isEmpty {
                    Section {
                        ForEach(state.poster_files, id: \.self) { url in
                            Text(url.lastPathComponent)
                        }
                        .onDelete { offsets in
                            state.remove_poster_files(at: offsets)
                        }
                    } header: {
                        Label("Imported", systemImage: "document.on.document")
                    }
                }
            }
            .navigationTitle("PosterBoard")
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
            .fileImporter(isPresented: $show_importer, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    urls.forEach { state.append_poster_file($0) }
                    show_browser = false
                case .failure(let error):
                    print("(pb) import failed: \(error)")
                }
            }
        }
    }

    private func apply() {
        busy = true
        do {
            let count = try pb.apply(at: state.poster_files)
            print("(pb) applied \(count) descriptor(s).")
            busy = false
            Alertinator.shared.alert(
                title: "Successfully applied PosterBoard!",
                body: "Respring your device for changes to take effect.",
                actionLabel: "Respring",
                action: {
                    state.respring()
                }
            )
        } catch {
            print("(pb) failed: \(error.localizedDescription)\n")
            busy = false
            Alertinator.shared.alert(
                title: "Failed to apply PosterBoard!",
                body: "Restart the app and try again. Check logs for more detailed information."
            )
        }
    }

    private func reset() {
        busy = true
        do {
            try pb.reset()
            print("(pb) reset done.")
            busy = false
            Alertinator.shared.alert(
                title: "Successfully reverted PosterBoard!",
                body: "Respring your device for changes to take effect.",
                actionLabel: "Respring",
                action: {
                    state.respring()
                }
            )
        } catch {
            print("(pb) failed: \(error.localizedDescription)")
            busy = false
            Alertinator.shared.alert(
                title: "Failed to revert PosterBoard!",
                body: "Restart the app and try again. Check logs for more detailed information."
            )
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

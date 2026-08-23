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
    @EnvironmentObject private var l10n: L10n
    
    @State private var show_settings: Bool = false
    @State private var show_importer: Bool = false
    @State private var show_explorer: Bool = false
    @State private var busy = false

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
                            
                            Text(l10n.t("Apply"))
                        }
                    }
                    .disabled(state.poster_files.isEmpty || busy)

                    if false {
                        Button {
                            reset()
                        } label: {
                            Text(l10n.t("Reset"))
                        }
                        .disabled(busy)
                    }
                }
                
                Section {
                    Button {
                        show_importer = true
                    } label: {
                        Text(l10n.t("Import Tendies"))
                    }
                    .disabled(busy)
                    
                    Button {
                        show_explorer = true
                    } label: {
                        Text(l10n.t("Explore Tendies"))
                    }
                    .disabled(busy)
                } footer: {
                    Text(LocalizedStringKey(l10n.t("Import up to 5 wallpaper packs.\n**NOTE:** Importing more than 5 tendies at once is not a good idea and importing more than 15 is a TERRIBLE idea. Dont say I didnt warn you.")))
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
                        Label(l10n.t("Imported"), systemImage: "document.on.document")
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
            .sheet(isPresented: $show_explorer) {
                TendiesView()
            }
            .fileImporter(isPresented: $show_importer, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    urls.forEach { state.append_poster_file($0) }
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
                title: L10n.shared.t("Successfully applied PosterBoard!"),
                body: L10n.shared.t("For changes to take effect:\n1. Click 'Open' to launch Posterboard\n2. Close it from the App Switcher"),
                actionLabel: L10n.shared.t("Open"),
                action: {
                    // state.respring()
                    
                    let cls = objc_getClass("LSApplicationWorkspace") as? NSObject
                    let ws = cls?.perform(Selector(("defaultWorkspace"))).takeUnretainedValue()
                    _ = ws?.perform(Selector(("openApplicationWithBundleID:")), with: "com.apple.PosterBoard")
                }
            )
        } catch {
            print("(pb) failed: \(error.localizedDescription)\n")
            busy = false
            Alertinator.shared.alert(
                title: L10n.shared.t("Failed to apply PosterBoard!"),
                body: L10n.shared.t("Restart the app and try again. Check logs for more detailed information.")
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
                title: L10n.shared.t("Successfully reverted PosterBoard!"),
                body: L10n.shared.t("Respring your device for changes to take effect."),
                actionLabel: L10n.shared.t("Respring"),
                action: {
                    state.respring()
                }
            )
        } catch {
            print("(pb) failed: \(error.localizedDescription)")
            busy = false
            Alertinator.shared.alert(
                title: L10n.shared.t("Failed to revert PosterBoard!"),
                body: L10n.shared.t("Restart the app and try again. Check logs for more detailed information.")
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

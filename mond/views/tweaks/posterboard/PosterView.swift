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
                            
                            Text(NSLocalizedString("apply", tableName: "PosterView", comment: ""))
                        }
                    }
                    .disabled(state.poster_files.isEmpty || busy)

                    if false {
                        Button {
                            reset()
                        } label: {
                            Text(NSLocalizedString("reset", tableName: "PosterView", comment: ""))
                        }
                        .disabled(busy)
                    }
                }
                
                Section {
                    Button {
                        show_importer = true
                    } label: {
                        Text(NSLocalizedString("import_tendies", tableName: "PosterView", comment: ""))
                    }
                    .disabled(busy)
                    
                    Button {
                        show_explorer = true
                    } label: {
                        Text(NSLocalizedString("explore_tendies", tableName: "PosterView", comment: ""))
                    }
                    .disabled(busy)
                } footer: {
                    Text(try! AttributedString(markdown:NSLocalizedString("tendies_warning", tableName: "PosterView", comment: "")))
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
                        Label(NSLocalizedString("imported", tableName: "PosterView", comment: ""), systemImage: "document.on.document")
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
            AlertinatorLocalized.shared.alert(
                title: NSLocalizedString("poster_apply_success_title", tableName: "PosterView", comment: ""),
                body: NSLocalizedString("poster_take_effect", tableName: "PosterView", comment: ""),
                actionLabel: NSLocalizedString("open", tableName: "PosterView", comment: ""),
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
            AlertinatorLocalized.shared.alert(
                title: NSLocalizedString("poster_apply_failed_title", tableName: "PosterView", comment: ""),
                body: NSLocalizedString("poster_apply_failed_body", tableName: "PosterView", comment: "")
            )
        }
    }

    private func reset() {
        busy = true
        do {
            try pb.reset()
            print("(pb) reset done.")
            busy = false
            AlertinatorLocalized.shared.alert(
                title: NSLocalizedString("poster_reset_success_title", tableName: "PosterView", comment: ""),
                body: NSLocalizedString("poster_reset_success_body", tableName: "PosterView", comment: ""),
                actionLabel: NSLocalizedString("respring", comment: ""),
                action: {
                    state.respring()
                }
            )
        } catch {
            print("(pb) failed: \(error.localizedDescription)")
            busy = false
            AlertinatorLocalized.shared.alert(
                title: NSLocalizedString("poster_reset_failed_title", tableName: "PosterView", comment: ""),
                body: NSLocalizedString("poster_reset_failed_body", tableName: "PosterView", comment: "")
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
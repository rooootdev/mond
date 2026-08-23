//
//  mond.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI
import PartyUI
import UniformTypeIdentifiers

var pipe = Pipe()
var sema = DispatchSemaphore(value: 0)
var fm = FileManager.default

var path: String {
    let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("test.txt")

    if !FileManager.default.fileExists(atPath: url.path) {
        FileManager.default.createFile(atPath: url.path, contents: Data())
    }

    return url.path
}

@main
struct mond: App {
    @StateObject private var state = AppState.shared
    @StateObject private var language_manager = LanguageManager.shared
    
    @AppStorage("ka_on") private var ka_on = true
    
    init() {
        if !is_debugged() {
            setvbuf(stdout, nil, _IONBF, 0)
            dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        }
        
        UserDefaults.standard.register(defaults: [
            "method": "bad_query",
            "atomic_write": true
        ])
        if UserDefaults.standard.bool(forKey: "ka_on") {
            keep_alive()
        }
        
        // thanks lunginspector
        let fix = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let og = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(og, fix)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .onOpenURL { url in
                    guard is_pb_archive(url) else {
                        print("(mond) ignoring unsupported URL: \(url.lastPathComponent)")
                        return
                    }

                    state.append_poster_file(url)
                }
                .onAppear() {
                    if !is_supported() {
                        AlertinatorLocalized.shared.alert(title: NSLocalizedString("not_supported", comment:""), body: NSLocalizedString("check_your_ios", comment:""))
                    }
                    
                    grant_all(state: state)
                }
                .overlay {
                    if state.show_respring {
                        RespringView()
                            .brightness(-1.0)
                            .ignoresSafeArea()
                            .onAppear {
                                print("(respring) respringing now...")
                            }
                    }
                }
        }
    }
}

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}
//
//  utils.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import SwiftUI
import Darwin
import UIKit
import WebKit
import Combine

func is_debugged() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride

    let rc = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
    if rc != 0 { return false }

    let P_TRACED: Int32 = 0x00000800
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

func is_supported() -> Bool {
    let v = ProcessInfo.processInfo.operatingSystemVersion

    return v.majorVersion == 27 &&
           v.minorVersion == 0 &&
           v.patchVersion == 0
}

func has_home_button() -> Bool {
    let windows = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }

    return (windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0) == 0
}

enum AppPaths {
    static var backups: String {
        let url = backups_url
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.path
    }

    private static var backups_url: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent("backups", isDirectory: true)
    }

    static var tendies: String {
        let url = tendies_url
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.path
    }

    private static var tendies_url: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent("tendies", isDirectory: true)
    }
}

enum TweakPaths {
    static var gestalt = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    static var gestalt_dir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/"
    static var apps = "/private/var/mobile/Containers/Data/Application/"
}

// respring.swift: easy respring on all iOS versions (probably).
// Web approach developed by @neonmodder123, implemented in Swift here by @skadz108.
// 4/9/26, https://jailbreak.party

let respringDocument = """
<!DOCTYPE html>
<html>
    <body>
        <!--  big credit to @neonmodder123  -->
        <iframe id="frame" srcdoc="" sandbox="allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups allow-presentation allow-scripts"></iframe>
        <script>
            const frame = document.getElementById('frame');
            const respringScript = `
                <html>
                <body>
                    <script>
                        const container = document.createElement('div');
                        container.style.cssText = 'perspective: 1px; perspective-origin: 9999999% 9999999%;';
                        document.body.appendChild(container);
    
                        for (let i = 0; i < 500; i++) {
                            let d = document.createElement('div');
                            d.style.cssText = 'position: absolute; width: 100vw; height: 100vh; backdrop-filter: blur(100px); -webkit-backdrop-filter: blur(100px); transform: translate3d(100000px, 100000px, ' + i + 'px) rotateY(90deg);';
                            container.appendChild(d);
                        }
    
                        setInterval(() => {
                            navigator.share({ title: 'R', text: 'R'.repeat(100000) }).catch(() => {});
                            let x = new Uint8Array(1024 * 1024 * 10);
                            crypto.getRandomValues(x);
                        }, 0);
                    <\\/script>
                </body>
                </html>
            `;
    
            frame.srcdoc = respringScript;
        </script>
    </body>
</html>
"""

struct RespringView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        WKWebpagePreferences().allowsContentJavaScript = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(respringDocument, baseURL: nil)
    }
}

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var show_respring = false
    @Published var exploit_succeeded = false
    @Published var granting_pb = false
    @Published var pb_granted: Bool? = nil
    @Published var granting_apps = false
    @Published var apps_granted: Bool? = nil
    @Published var granting_mg = false
    @Published var mg_granted: Bool? = nil
    @Published var poster_files: [URL] = []

    func respring() {
        show_respring = true
    }

    func append_poster_file(_ url: URL) {
        guard is_pb_archive(url) else {
            print("(pb) ignoring unsupported file: \(url.lastPathComponent)")
            return
        }

        if poster_files.contains(url) {
            return
        }

        _ = url.startAccessingSecurityScopedResource()
        poster_files.append(url)
    }

    func remove_poster_files(at offsets: IndexSet) {
        for index in offsets {
            poster_files[index].stopAccessingSecurityScopedResource()
        }

        poster_files.remove(atOffsets: offsets)
    }

    func clear_pb_files() {
        for url in poster_files {
            url.stopAccessingSecurityScopedResource()
        }

        poster_files.removeAll()
    }
}

func is_pb_archive(_ url: URL) -> Bool {
    switch url.pathExtension.lowercased() {
    case "tendies", "zip":
        return true
    default:
        return false
    }
}
//
//  utils.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import Darwin
import Foundation
import UIKit

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

// Unused for now
// Was causing KERN_INVALID_ADDRESS at 0x0000000000000001 on my iPhone SE 2 crashing the app when opening -- aokumo21
/*func hasHomeButton() -> Bool {
    let sel = NSSelectorFromString("_hasHomeButton")
    return UIDevice.responds(to: sel) &&
        (UIDevice.perform(sel)?.takeUnretainedValue() as? Bool ?? false)
*/}

enum AppPaths {
    static var backups: String {
        let url = backupsURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.path
    }

    private static var backupsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent("backups", isDirectory: true)
    }
}

enum TweakPaths {
    static var gestalt = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    static var gestalt_dir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/"
}

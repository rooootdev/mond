//
//  sbx.swift
//  symlin4k
//
//  Created by ruter on 10.07.26.
//

import Foundation

func sandbox_extension_consume(_ token: String) -> Int64? {
    typealias sbx_consume_func = @convention(c) (UnsafePointer<CChar>?) -> Int64
    
    guard let libsys_sbx = dlopen("/usr/lib/system/libsystem_sandbox.dylib", RTLD_NOW) else { return nil }
    defer { dlclose(libsys_sbx) }
    
    guard let sbx_consume_sym = dlsym(libsys_sbx, "sandbox_extension_consume") else { return nil }
    let consume = unsafeBitCast(sbx_consume_sym, to: sbx_consume_func.self)
    let result = consume(token)
    
    return result
}

func sandbox_extension_issue_file(path: String) -> String? {
    typealias sbx_issue_func = @convention(c) (UnsafePointer<CChar>?, UnsafePointer<CChar>?, Int32, Int32) -> UnsafeMutablePointer<CChar>?

    guard let libsys_sbx = dlopen("/usr/lib/system/libsystem_sandbox.dylib", RTLD_NOW) else { return nil }
    defer { dlclose(libsys_sbx) }
    
    guard let sbx_issue_sym = dlsym(libsys_sbx, "sandbox_extension_issue_file") else { return nil }
    let issue = unsafeBitCast(sbx_issue_sym, to: sbx_issue_func.self)

    guard let ptr = issue("com.apple.app-sandbox.read-write", path, 0, 0) else { return nil }
    defer { free(ptr) }

    return String(cString: ptr)
}

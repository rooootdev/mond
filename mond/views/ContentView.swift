//
//  ContentView.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI
import PartyUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("mg_devicename") private var mg_devicename: String = ""
    @AppStorage("token") private var token: String = ""
    
    @State private var mg_dict_now: NSMutableDictionary = NSMutableDictionary()
    @State private var is_valid: Bool = false
    
    @State private var subtype: Int = 0
    @State private var og_subtype: Int = 0
    @State private var og_devicename: String = ""
    @State private var enable_devicename: Bool = false
    @State private var product_type: String = ""
    
    @State private var show_settings: Bool = false
    
    private var mg_valid: Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)) else { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }
    
    private var mg_empty: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: TweakPaths.gestalt),
              let size = attributes[.size] as? UInt64 else { return false }

        return size == 0
    }
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !mg_valid || mg_empty {
                    Section {
                        if mg_empty {
                            PlainAlert(title: "Do not reboot!", icon: "exclamationmark.triangle.fill", text: "Your MobileGestalt.plist seems to be empty.", color: Color.yellow)
                        }
                        
                        if !mg_valid {
                            PlainAlert(title: "Do not reboot!", icon: "exclamationmark.triangle.fill", text: "Your MobileGestalt.plist seems to be invalid.", color: Color.yellow)
                        }
                    } header: {
                        Label("Warning", systemImage: "exclamationmark.triangle")
                    } footer: {
                        Text("Rebooting now might cause a bootloop. Try pressing 'Revert Tweaks'. If the warnings dont go away after that, you're fucked.")
                    }
                }
                
                Section {
                    Button {
                        mg_apply()
                    } label: {
                        Text("Apply Tweaks")
                    }
                    
                    Button {
                        mg_revert()
                    } label: {
                        Text("Revert Tweaks")
                    }
                } footer: {
                    Text("**WARNING:** These tweaks have the capability to break features on your device or softbrick it if misused!")
                }
                
                Section {
                    Picker(selection: $subtype) {
                        Text("Original (\(og_subtype))").tag(og_subtype)
                        if is_device_good() {
                            Text("Disable Dynamic Island").tag(2436)
                        }
                        Text("iPhone 14 Pro").tag(2436)
                        Text("iPhone 14 Pro Max").tag(2796)
                        Text("iPhone 15 Pro Max").tag(2976)
                        if doubleSystemVersion() >= 18.0 {
                            Text("iPhone 16 Pro").tag(2622)
                            Text("iPhone 16 Pro Max").tag(2868)
                        }
                        if doubleSystemVersion() >= 26.0 {
                            Text("iPhone Air").tag(2736)
                        }
                        Text("iPhone X Gestures (iPhone SE Only)").tag(2436) // I don't know how to check for the home button so this is the best I can do - aokumo21
                    } label: {
                        HStack {
                            Text("Subtype")
                            Spacer()
                        }
                    }
                    
                    Toggle("Custom Device Name", isOn: $enable_devicename)
                    
                    if enable_devicename {
                        TextField("Device Name", text: $mg_devicename)
                    }
                } header: {
                    Label("Device Artwork", systemImage: "paintbrush.pointed")
                }
                
                // basic tweak toggles
                Section {
                    PlainToggle(text: "Dynamic Island", minSupportedVersion: 19.0, isOn: mg_key_binding(["YlEtTtHlNesRBMal1CqRaA"]))
                    PlainToggle(text: "Always On Display", minSupportedVersion: 18.0, isOn: mg_key_binding(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    PlainToggle(text: "AOD Vibrancy", minSupportedVersion: 18.0, isOn: mg_key_binding(["ykpu7qyhqFweVMKtxNylWA"]))
                    PlainToggle(text: "Charge Limit", minSupportedVersion: 17.0, isOn: mg_key_binding(["37NVydb//GP/GrhuTN+exg"]))
                    PlainToggle(text: "Boot Chime", isOn: mg_key_binding(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    PlainToggle(text: "Liquid Glass LPM", minSupportedVersion: 19.0, isOn: mg_key_binding(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                } header: {
                    Label("Software-Oriented Features", systemImage: "gearshape")
                }
                
                Section {
                    PlainToggle(text: "Camera Control", minSupportedVersion: 18.0, isOn: mg_key_binding(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    PlainToggle(text: "Action Button", minSupportedVersion: 17.0, isOn: mg_key_binding(["cT44WE1EohiwRzhsZ8xEsw"]))
                    PlainToggle(text: "Crash Detection", isOn: mg_key_binding(["HCzWusHQwZDea6nNhaKndw"]))
                    
                    PlainToggle(text: "Enable Tap to Wake (iPhone SE Only)", isOn: mg_key_binding(["yZf3GTRMGTuwSV/lD7Cagw"])) // I don't know how to check for the home button so this is the best I can do - aokumo21
                    
                    PlainToggle(text: "Pulse Width Modulation", minSupportedVersion: 19.0, isOn: mg_key_binding(["6IejgN+1Fmu5/QrZFOIeNw"]))
                } header: {
                    Label("Hardware-Oriented Features", systemImage: "iphone")
                }
                
                Section {
                    PlainToggle(text: "Security Research Device UI", minSupportedVersion: 26.0, isOn: mg_key_binding(["XYlJKKkj2hztRP1NWWnhlw"]))
                    PlainToggle(text: "Disable Region Restrictions", isOn: mg_region_restrict_binding())
                    PlainToggle(text: "Apple Intelligence", minSupportedVersion: 18.1, isOn: mg_key_binding(["A62OafQ85EJAiiqKn4agtg"]))
                    HStack(spacing: 10) {
                        Picker("Spoofing", selection: $product_type) {
                            Text("Default").tag(machine_name())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                if doubleSystemVersion() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSystemVersion() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSystemVersion() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                            }
                        }
                        
                        Button {
                            Alertinator.shared.alert(
                                title: "Device Spoofing Info",
                                body: "Only spoof your device model if you want to download Apple Intelligence. This may break Face ID. If you decide to unspoof and want to keep Apple Intelligence, do NOT re-enter the Apple Intelligence & Siri menu in Settings."
                            )
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("Eligibility", systemImage: "checklist")
                }
                
                Section {
                    let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary
                    
                    PlainToggle(text: "Allow Installing iPadOS Apps", isOn: mg_key_binding(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, default_val: [1], on_val: [1, 2]))
                    PlainToggle(text: "Apple Pencil Settings", isOn: mg_key_binding(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        PlainToggle(text: "Stage Manager", isOn: mg_key_binding(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    }
                    PlainToggle(
                        text: "iPadOS UI",
                        infoType: .warning,
                        infoMessage: "This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! With these two things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. But I guess some funny multitasking features that still make the device relatively unusable are cool? Whatever dude, I'm not here to tell you how to use your own device.",
                        isOn: mg_trollpad_binding()
                    )
                    .disabled(cache_extra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } header: {
                    Label("iPadOS Features", systemImage: "ipad")
                }
                
                Section {
                    PlainToggle(text: "Internal Storage", isOn: mg_key_binding(["LBJfwOEzExRxzlAnSuI7eg"]))
                    PlainToggle(text: "Internal Features", isOn: mg_internal_binding())
                    PlainToggle(text: "Metal HUD in All Apps", isOn: mg_key_binding(["EqrsVvjcYDdxHBiQmGhAWw"]))
                } header: {
                    Label("Internal", systemImage: "ant")
                }
            }
            .navigationTitle("mond")
            .tint(Color("AccentColor"))
            .onAppear {
                if !valid {
                    state.exploit_succeeded = grant_mg_write() >= 0
                } else {
                    print("(mond) valid token saved, skipping exploit")
                    state.exploit_succeeded = true
                }
                
                mg_load()
            }
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
    
    private enum MGViewError: Error, LocalizedError {
        case missingArtworkSubtype
        case missingArtworkDeviceName
        
        var errorDescription: String? {
            switch self {
            case .missingArtworkSubtype:
                return "Failed to get ArtworkDeviceSubType!"
            case .missingArtworkDeviceName:
                return "Failed to get ArtworkDeviceProductDescription!"
            }
        }
    }
    
    private func mg_load() {
        do {
            let mg_url_now = URL(fileURLWithPath: TweakPaths.gestalt)
            mg_dict_now = try NSMutableDictionary(contentsOf: mg_url_now, error: ())
            
            // this'll cache gestalt and put it in a safe place
            let mg_url_saved = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            
            if !FileManager.default.fileExists(atPath: mg_url_saved.path) {
                try FileManager.default.copyItem(at: mg_url_now, to: mg_url_saved)
            }
            
            // get original gestalt values
            let mg_saved_dict = try NSMutableDictionary(contentsOf: mg_url_saved, error: ())
            let og_cache_extra = mg_saved_dict["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            let og_artwork = og_cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            guard let ogSubtype = og_artwork["ArtworkDeviceSubType"] as? Int else { throw MGViewError.missingArtworkSubtype }
            og_subtype = ogSubtype
            
            guard let ogDeviceName = og_artwork["ArtworkDeviceProductDescription"] as? String else { throw MGViewError.missingArtworkDeviceName }
            
            // now get current gestalt values
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            let artwork = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            subtype = artwork["ArtworkDeviceSubType"] as? Int ?? ogSubtype // fallback
            mg_devicename = artwork["ArtworkDeviceProductDescription"] as? String ?? ogDeviceName
            
            // assume it's been changed
            if mg_devicename != ogDeviceName {
                enable_devicename = true
            }
            
            if let productType = cache_extra["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String, !productType.isEmpty {
                product_type = productType
            } else {
                product_type = machine_name()
            }
        } catch {
            print("(mg) failed to load data: \(error)")
            Alertinator.shared.alert(title: "Failed to load current MobileGestalt!", body: "Restart the app and try again. Check logs for more detailed information.")
        }
    }
    
    private func mg_apply() {
        do {
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            if !product_type.isEmpty {
                cache_extra["h9jDsbgj7xIVeIQ8S3/X3Q"] = product_type
            }
            
            let artwork_dict = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            artwork_dict["ArtworkDeviceSubType"] = subtype
            if enable_devicename {
                artwork_dict["ArtworkDeviceProductDescription"] = mg_devicename
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)

            try mg_write(data)
            mg_dict_now = NSMutableDictionary()
            enable_devicename = false

            print("(mg) successfully overwrote mobilegestalt!")
            Alertinator.shared.alert(title: "Successfully applied Gestalt tweaks!", body: "Respring your device for changes to take effect. Note that some tweaks may require a reboot for them to apply properly.", actionLabel: "Respring", action: {
                state.respring()
            })
        } catch {
            print("(mg) failed to apply mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "Failed to apply MobileGestalt!", body: "Restart the app and try again. Check logs for more detailed information.")
        }
    }
    
    private func mg_revert() {
        do {
            let backup_url = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            let backup_data = try Data(contentsOf: backup_url)
            try mg_write(backup_data)

            print("(mg) successfully reverted mobilegestalt!)")
            Alertinator.shared.alert(title: "Successfully reverted Gestalt tweaks!", body: "Reboot your device for changes to take effect.")
        } catch {
            // The direct file write path now surfaces the underlying error through the catch.
            print("(mg) failed to revert mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "Failed to revert MobileGestalt!", body: "Check logs for error information.")
        }
    }

    private func mg_write(_ data: Data) throws {
        let target_url = URL(fileURLWithPath: TweakPaths.gestalt)
        let temp_url = target_url.deletingLastPathComponent()
            .appendingPathComponent(".\(target_url.lastPathComponent).\(UUID().uuidString).tmp")

        try data.write(to: temp_url, options: [.withoutOverwriting])
        defer { try? fm.removeItem(at: temp_url) }

        if fm.fileExists(atPath: target_url.path) {
            _ = try fm.replaceItemAt(target_url, withItemAt: temp_url)
        } else {
            try fm.moveItem(at: temp_url, to: target_url)
        }
    }
    
    private func mg_key_binding<T: Equatable>(_ keys: [String], type: T.Type = Int.self, default_val: T? = 0, on_val: T? = 1) -> Binding<Bool>  {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? T?, let on_val {
                return value == on_val
            }
            
            return false
        }, set: { enabled in
            for key in keys {
                // if it exists inside of the plist, then update it. if not then pull the value completely.
                if enabled {
                    cache_extra[key] = on_val
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_trollpad_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData,
                let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        let value_off = cache_data_offset("mtrAoWJ3gsq+I90ZnQ0vQw")
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? Int? {
                return value == 1
            }
            
            return false
        }, set: { enabled in
            if enabled {
                Alertinator.shared.alert(title: "Warning!", body: "This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! With these two things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. I'm honestly not too certain why you'd want to use this tweak anyways, it's not like your device is gonna be all that usable (due to apps scaling weirdly) when it's enabled.")
            }
            
            cache_data.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: value_off, as: Int.self)
            
            for key in keys {
                if enabled {
                    cache_extra[key] = 1
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_region_restrict_binding() -> Binding<Bool> {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding<Bool>(
            get: {
                return cache_extra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                    cache_extra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    Alertinator.shared.alert(title: "Warning!", body: "Please do not use this feature to bypass region restrictions that would equate to breaking regional laws (e.g. disabling the camera shutter sound). We will NOT be held responsible for enabling any illegal activites!")
                    cache_extra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cache_extra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cache_extra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cache_extra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
            }
        )
    }
    
    private func mg_internal_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData else {
            return .constant(false)
        }
        
        let off_apple_internal_install = cache_data_offset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_has_internal_settings_bundle = cache_data_offset("Oji6HRoPi7rH7HPdWVakuw")
        let off_internal_build = cache_data_offset("LBJfwOEzExRxzlAnSuI7eg")
        
        return Binding(
            get: {
                return cache_data.bytes.load(fromByteOffset: off_apple_internal_install, as: Int.self) == 1
            },
            set: { enabled in
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_apple_internal_install, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_has_internal_settings_bundle, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_internal_build, as: Int.self)
            }
        )
    }
    
    private func is_device_good() -> Bool {
        let supported: [String] = ["iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2", "iPhone17,3", "iPhone17,4", "iPhone17,1", "iPhone17,2", "iPhone18,3", "iPhone18,1", "iPhone18,2", "iPhone17,5"]
        
        if supported.contains(machine_name()) && doubleSystemVersion() < 19.0 {
            return true
        }
        
        return false
    }
    
    private func machine_name() -> String {
        var sys_info = utsname()
        uname(&sys_info)
        let machine_mirror = Mirror(reflecting: sys_info.machine)
        
        return machine_mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}

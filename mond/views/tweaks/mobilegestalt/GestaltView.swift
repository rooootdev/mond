//
//  GestaltView.swift
//  mond
//
//  Created by ruter on 11.08.26.
//

import SwiftUI
import PartyUI

private extension mg_tweak.InfoType {
    var party_info_type: ToggleInfoType {
        switch self {
            case .info: return .info
            case .warning, .error: return .warning
        }
    }
}

struct TweakToggle: View {
    let title: String

    var body: some View {
        if let tweak = tweak(title) {
            PlainToggle(
                text: tweak.title,
                infoType: tweak.info_t?.party_info_type ?? .none,
                infoMessage: tweak.info_msg ?? "",
                minSupportedVersion: tweak.minv ?? 0.0,
                isOn: mg_tweak_binding(tweak)
            )
        }
    }
}

fileprivate func mg_ui_state() -> (String, Bool, String, String) {
    (selected_st, enable_device_name, mg_device_name, product_type)
}

fileprivate func mg_apply_ui_state(_ selected: String, _ enableName: Bool, _ deviceName: String, _ product: String) {
    selected_st = selected
    enable_device_name = enableName
    mg_device_name = deviceName
    product_type = product
}

struct GestaltView: View {
    @EnvironmentObject var state: AppState

    @State private var show_settings: Bool = false

    @State private var selected_st: String = "og"
    @State private var enable_device_name: Bool = false
    @State private var mg_device_name: String = ""
    @State private var product_type: String = ""
    @State private var tweak_version: Int = 0

    var body: some View {
        NavigationStack {
            List {
                if !is_valid || is_empty {
                    Section {
                        if is_empty {
                            PlainAlert(title: "Do not reboot!", icon: "exclamationmark.triangle.fill", text: "Your MobileGestalt.plist seems to be empty.", color: Color.yellow)
                        }

                        if !is_valid {
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
                        mg_apply_ui_state(selected_st, enable_device_name, mg_device_name, product_type)
                        mg_apply()
                        tweak_version += 1
                    } label: {
                        Text("Apply Tweaks")
                    }

                    Button {
                        mg_revert()
                        tweak_version += 1
                    } label: {
                        Text("Revert Tweaks")
                    }
                    
                    Button {
                        state.respring()
                    } label: {
                        Text("Respring")
                    }
                } footer: {
                    Text("**WARNING:** These tweaks have the capability to break features on your device or softbrick it if misused!")
                }

                Section {
                    Picker(selection: $selected_st) {
                        Text("Original (\(og_st))").tag("og")

                        if is_device_good() {
                            Text("Disable Dynamic Island").tag("no_dynamic_island")
                        }

                        Text("iPhone 14 Pro").tag("14p")
                        Text("iPhone 14 Pro Max").tag("14pm")
                        Text("iPhone 15 Pro Max").tag("15pm")

                        if doubleSystemVersion() >= 18.0 {
                            Text("iPhone 16 Pro").tag("16p")
                            Text("iPhone 16 Pro Max").tag("16pm")
                        }

                        if doubleSystemVersion() >= 26.0 {
                            Text("iPhone Air").tag("air")
                        }

                        if has_home_button() {
                            Text("iPhone X Gestures").tag("x")
                        }
                    } label: {
                        HStack {
                            Text("Subtype")
                            Spacer()
                        }
                    }

                    Toggle("Custom Device Name", isOn: $enable_device_name)

                    if enable_device_name {
                        TextField("Device Name", text: $mg_device_name)
                    }
                } header: {
                    Label("Device Artwork", systemImage: "paintbrush.pointed")
                }

                Section {
                    TweakToggle(title: "Enable Dynamic Island Capability")
                    TweakToggle(title: "Always-On Display")
                    TweakToggle(title: "AOD Vibrancy")
                    TweakToggle(title: "Disable Wallpaper Parallax")
                    TweakToggle(title: "Charge Limit Menu")
                    TweakToggle(title: "Boot & Shutdown Chime")
                    TweakToggle(title: "Enable Liquid Glass Low-Performance Mode")
                    TweakToggle(title: "Disable Liquid Glass Low-Performance Mode")
                } header: {
                    Label("Software-Oriented Features", systemImage: "gearshape")
                }

                Section {
                    TweakToggle(title: "iPhone 16 Camera Control Settings")
                    TweakToggle(title: "Action Button Settings")
                    TweakToggle(title: "Collision SOS")
                    if has_home_button() {
                        TweakToggle(title: "Tap to Wake")
                    }
                    TweakToggle(title: "Pulse Width Modulation")
                } header: {
                    Label("Hardware-Oriented Features", systemImage: "iphone")
                }

                Section {
                    TweakToggle(title: "Security Research Device Mode")
                    TweakToggle(title: "Disable Region Restrictions")
                    TweakToggle(title: "Apple Intelligence")

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
                    TweakToggle(title: "Allow iPad Apps")
                    TweakToggle(title: "Apple Pencil Settings")

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        TweakToggle(title: "Stage Manager Support")
                    }

                    TweakToggle(title: "Enable iPadOS Mode")
                        .disabled({
                            let cache_extra = mg_dict_now["CacheExtra"] as? [String: Any]
                            return cache_extra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone"
                        }())
                } header: {
                    Label("iPadOS Features", systemImage: "ipad")
                }

                Section {
                    TweakToggle(title: "Internal Storage View")
                    TweakToggle(title: "Internal Features")
                    TweakToggle(title: "Apple Internal Install")
                } header: {
                    Label("Internal", systemImage: "ant")
                }
            }
            .navigationTitle("MobileGestalt")
            .tint(Color("AccentColor"))
            .task {
                mg_load()
                while is_loading {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                let s = mg_ui_state()
                selected_st = s.0
                enable_device_name = s.1
                mg_device_name = s.2
                product_type = s.3
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
}

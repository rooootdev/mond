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
                infoTitle: NSLocalizedString("information", comment: ""),
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

    var body: some View {
        NavigationStack {
            List {
                if !is_valid || is_empty {
                    Section {
                        if is_empty {
                            PlainAlert(title: NSLocalizedString("menu_warning.do_not_reboot",tableName: "GestaltView", comment: ""), icon: "exclamationmark.triangle.fill", text: NSLocalizedString("menu_warning.mg_empty_warning", tableName: "GestaltView", comment: ""), color: Color.yellow)
                        }

                        if !is_valid {
                            PlainAlert(title: NSLocalizedString("menu_warning.do_not_reboot",tableName: "GestaltView", comment: ""), icon: "exclamationmark.triangle.fill", text: NSLocalizedString("menu_warning.mg_invalid_warning", tableName: "GestaltView", comment: ""), color: Color.yellow)
                        }
                    } header: {
                        Label(NSLocalizedString("warning", comment: ""), systemImage: "exclamationmark.triangle")
                    } footer: {
                        Text(NSLocalizedString("menu_warning.bootloop", tableName: "GestaltView", comment: ""))
                    }
                }

                Section {
                    Button {
                        mg_apply_ui_state(selected_st, enable_device_name, mg_device_name, product_type)
                        mg_apply()
                    } label: {
                        Text(NSLocalizedString("menu.apply_tweaks", tableName: "GestaltView", comment: ""))
                    }

                    Button {
                        mg_revert()
                    } label: {
                        Text(NSLocalizedString("menu.revert_tweaks", tableName: "GestaltView", comment: ""))
                    }
                    
                    Button {
                        state.respring()
                    } label: {
                        Text(NSLocalizedString("respring", comment: ""))
                    }
                } footer: {
                    Text(try! AttributedString(markdown: NSLocalizedString("menu.tweak_warning", tableName: "GestaltView", comment: "")))
                }

                Section {
                    Picker(selection: $selected_st) {
                        Text("\(NSLocalizedString("Original", tableName: "SettingsView", comment: "")) (\(og_st))").tag("og")

                        if is_device_good() {
                            Text(NSLocalizedString("artwork.disable_dynamic_island", tableName: "GestaltView", comment: "")).tag("no_dynamic_island")
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
                            Text(NSLocalizedString("artwork.subtype", tableName: "GestaltView", comment: ""))
                            Spacer()
                        }
                    }

                    Toggle(NSLocalizedString("artwork.custom_device_name", tableName: "GestaltView", comment: ""), isOn: $enable_device_name)

                    if enable_device_name {
                        TextField(NSLocalizedString("artwork.device_name", tableName: "GestaltView", comment: ""), text: $mg_device_name)
                    }
                } header: {
                    Label(NSLocalizedString("artwork.device_artwork", tableName: "GestaltView", comment: ""), systemImage: "paintbrush.pointed")
                }

                Section {
                    TweakToggle(title: NSLocalizedString("software.enable_dynamic_island_capability", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.always_on_display", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.aod_vibrancy", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.disable_wallpaper_parallax", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.charge_limit_menu", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.boot_shutdown_chime", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.enable_liquid_glass_low_performance_mode", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("software.disable_liquid_glass_low_performance_mode", tableName: "GestaltView", comment: ""))
                } header: {
                    Label(NSLocalizedString("software.software_oriented_features", tableName: "GestaltView", comment: ""), systemImage: "gearshape")
                }

                Section {
                    TweakToggle(title: NSLocalizedString("hardware.camera_control_settings", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("hardware.action_button_settings", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("hardware.collision_sos", tableName: "GestaltView", comment: ""))
                    if has_home_button() {
                        TweakToggle(title: NSLocalizedString("hardware.tap_to_wake", tableName: "GestaltView", comment: ""))
                    }
                    TweakToggle(title: NSLocalizedString("hardware.pulse_width_modulation", tableName: "GestaltView", comment: ""))
                } header: {
                    Label(NSLocalizedString("hardware.hardware_oriented_features", tableName: "GestaltView", comment: ""), systemImage: "iphone")
                }

                Section {
                    TweakToggle(title: NSLocalizedString("eligibility.security_research_device_mode", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("eligibility.disable_region_restrictions", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("eligibility.apple_intelligence", tableName: "GestaltView", comment: ""))

                    HStack(spacing: 10) {
                        Picker(NSLocalizedString("eligibility.spoofing", tableName: "GestaltView", comment: ""), selection: $product_type) {
                            Text(NSLocalizedString("eligibility.default_model", tableName: "GestaltView", comment: "")).tag(machine_name())
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
                            AlertinatorLocalized.shared.alert(
                                title: NSLocalizedString("eligibility.device_spoofing_info", tableName: "GestaltView", comment: ""),
                                body: NSLocalizedString("eligibility.device_spoofing_info_body", tableName: "GestaltView", comment: "")
                            )
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label(NSLocalizedString("eligibility.eligibility", tableName: "GestaltView", comment: ""), systemImage: "checklist")
                }

                Section {
                    let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary

                    TweakToggle(title: NSLocalizedString("ipados.allow_ipados_apps", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("ipados.apple_pencil_settings", tableName: "GestaltView", comment: ""))

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        TweakToggle(title: NSLocalizedString("ipados.stage_manager_support", tableName: "GestaltView", comment: ""))
                    }

                    TweakToggle(title: NSLocalizedString("ipados.ipados_mode", tableName: "GestaltView", comment: ""))
                        .disabled(cache_extra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } header: {
                    Label(NSLocalizedString("ipados.ipados_features", tableName: "GestaltView", comment: ""), systemImage: "ipad")
                }

                Section {
                    TweakToggle(title: NSLocalizedString("internal.internal_storage_view", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("internal.internal_features", tableName: "GestaltView", comment: ""))
                    TweakToggle(title: NSLocalizedString("internal.apple_internal_install", tableName: "GestaltView", comment: ""))
                } header: {
                    Label(NSLocalizedString("internal.internal", tableName: "GestaltView", comment: ""), systemImage: "ant")
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
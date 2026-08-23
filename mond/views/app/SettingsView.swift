//
//  SettingsView.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import SwiftUI
import PartyUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: AppState
    @EnvironmentObject private var l10n: L10n
    
    @AppStorage("method") private var method: String = "bad_query"
    @AppStorage("ka_on") private var ka_on = true
    @AppStorage("token") private var token: String = ""
    @AppStorage("dismiss_after_import") private var dismiss_after_import = false
    @AppStorage("atomic_write") private var atomic_write = true
    @AppStorage("ignore_failure") private var ignore_failure = false
    
    @State private var show_confirm: Bool = false
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if let url = URL(string: "https://github.com/rooootdev/mond"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                               let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                               let files = primary["CFBundleIconFiles"] as? [String],
                               let icon = files.last,
                               let img = UIImage(named: icon) {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                                     ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                                     ?? "Unknown App")
                                .font(.headline)
                                
                                Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                                .imageScale(.small)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    Picker(l10n.t("Method"), selection: $method) {
                        Text("bad_query").tag("bad_query")
                        Text("cmg").tag("cmg")
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        grant_all(state: state)
                    } label: {
                        Text(l10n.t("Run Exploit"))
                    }
                } header: {
                    Label("Exploit", systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(LocalizedStringKey(l10n.t(method == "cmg"
                        ? "**CMG:** Supports iOS 27.0 b1 - b4. Only MobileGestalt will work with this method. Only use this when bad_query isnt working for you."
                        : "**bad_query:** Supports iOS 27.0 b1 - b4. By [forcequit](https://github.com/forcequitOS).")))
                }
                
                Section {
                    TextField(l10n.t("Sandbox Extension Token."), text: $token)
                    .contextMenu {
                        Text("Class: \(token.split(separator: ";").first { $0.contains("com.apple") }.map(String.init) ?? "N/A")")
                        Text("Path: \(token.split(separator: ";").last.map(String.init) ?? "N/A")")
                        
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Label(l10n.t("Copy Token"), systemImage: "doc.on.doc")
                        }
                    }
                    .lineLimit(1)
                    
                    Button {
                        token = sandbox_extension_issue_file(path: TweakPaths.gestalt_dir) ?? l10n.t("Failed to get token.")
                    } label: {
                        Text(l10n.t("Generate Token"))
                    }
                    .disabled(!state.exploit_succeeded)
                } header: {
                    Label("Token", systemImage: "key")
                } footer: {
                    if !token.isEmpty && token != l10n.t("Failed to get token.") {
                        if valid {
                            Text(l10n.t("Your sandbox token is valid."))
                        } else {
                            Text(l10n.t("Your sandbox token is invalid."))
                        }
                    }
                    
                    if !state.exploit_succeeded {
                        Text(l10n.t("Disabled because the exploit failed. Is your iOS version supported?"))
                    }
                }
                
                Section {
                    PlainToggle(text: l10n.t("Keep Alive"), infoType: .info, infoTitle: l10n.t("Information"), infoMessage: l10n.t("Keeps the app running in the background after you close it, allowing it to remain active."), isOn: $ka_on)
                        .onChange(of: ka_on) { _, enabled in
                            if enabled {
                                keep_alive()
                            } else {
                                let_die()
                            }
                        }

                    PlainToggle(text: l10n.t("Dismiss after importing"), infoType: .info, infoTitle: l10n.t("Information"), infoMessage: l10n.t("When enabled, the Tendies explorer will close automatically after importing a .tendies file into PosterBoard."), isOn: $dismiss_after_import)

                    PlainToggle(text: l10n.t("Persist after reboot"), infoType: .info, infoTitle: l10n.t("Information"), infoMessage: l10n.t("When enabled, MobileGestalt is written in-place on the same inode, which (hopefully) prevents iOS from regenerating the cache on reboot. Disable to use atomic file replacement instead."), isOn: $atomic_write)
                    
                    PlainToggle(text: l10n.t("Ignore exploit failure"), infoType: .info, infoTitle: l10n.t("Information"), infoMessage: l10n.t("When enabled, All Tweaks will be accessible even if the exploit failed."), isOn: $ignore_failure)
                } header: {
                    Label(l10n.t("Settings"), systemImage: "gear")
                }
                
                Section {
                    Button {
                        show_confirm = true
                    } label: {
                        Text(l10n.t("Respring"))
                    }
                } header: {
                    Label(l10n.t("Tools"), systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(LocalizedStringKey(l10n.t("Respring method by [neon](https://github.com/neonmodder123), swift implementation by [skadz](https://github.com/skadz108).")))
                }
                
                Section {
                    CreditsRow(name: "roooot", role: l10n.t("Main developer"), profile: URL(string: "https://github.com/rooootdev")!)
                    CreditsRow(name: "forcequit", role: l10n.t("The bad_query exploit"), profile: URL(string: "https://github.com/forcequitOS")!)
                    CreditsRow(name: "johnny", role: l10n.t("His work on the MCM bug class"), profile: URL(string: "https://github.com/0xjohnnydev")!)
                    CreditsRow(name: "jailbreak.party", role: "PartyUI, GestaltView", profile: URL(string: "https://github.com/jailbreakdotparty")!)
                    CreditsRow(name: "SerStars", role: l10n.t("Tendies repository"), profile: URL(string: "https://github.com/SerStars")!)
                } header: {
                    Label(l10n.t("Credits"), systemImage: "person.3.fill")
                }
            }
            .navigationTitle(l10n.t("Settings"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text(l10n.t("Done"))
                        }
                    }
                }
            }
            .alert(l10n.t("Are you sure?"), isPresented: $show_confirm) {
                Button(l10n.t("Cancel")) {
                    show_confirm = false
                }
                
                Button(l10n.t("Confirm")) {
                    state.respring()
                }
            } message: {
                Text(l10n.t("Confirm that you want to respring."))
            }
        }
    }
}

struct CreditsRow: View {
    let name: String
    let role: String
    let profile: URL

    private var pfp: URL? {
        URL(string: profile.absoluteString + ".png")
    }

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: pfp) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onTapGesture {
            UIApplication.shared.open(profile)
        }
    }
}

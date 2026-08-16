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

    @AppStorage("method") private var method: String = "bad_query"
    @AppStorage("ka_on") private var ka_on = true
    @AppStorage("token") private var token: String = ""
    @AppStorage("dismiss_after_import") private var dismiss_after_import = false

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
                                     ?? String(localized: "Unknown App"))
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
                    Picker(String(localized: "Method"), selection: $method) {
                        Text("bad_query").tag("bad_query")
                        Text("cmg").tag("cmg")
                    }
                    .pickerStyle(.segmented)

                    Button {
                        grant_all(state: state)
                    } label: {
                        Text(String(localized: "Run Exploit"))
                    }
                } header: {
                    Label(String(localized: "Exploit"), systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(method == "cmg" ? String(localized: "Supports iOS 27.0 b1 - b4. Only MobileGestalt will work with this method. Only use this when bad_query isnt working for you.") : String(localized: "Supports iOS 27.0 b1 - b4. By forcequit."))
                }

                Section {
                    HStack {
                        TextField(String(localized: "Sandbox Extension Token."), text: $token)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Image(systemName: "document.on.document")
                        }
                    }
                    .contextMenu {
                        let tokenClass = token.split(separator: ";").first { $0.contains("com.apple") }.map(String.init) ?? "N/A"
                        let tokenPath = token.split(separator: ";").last.map(String.init) ?? "N/A"
                        Text("Class: \(tokenClass)")
                        Text("Path: \(tokenPath)")

                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Label(String(localized: "Copy token"), systemImage: "doc.on.doc")
                        }
                    }
                    .lineLimit(1)

                    Button {
                        token = sandbox_extension_issue_file(path: TweakPaths.gestalt_dir) ?? String(localized: "Failed to get token.")
                    } label: {
                        Text(String(localized: "Generate Token"))
                    }
                    .disabled(!state.exploit_succeeded)
                } header: {
                    Label(String(localized: "Token"), systemImage: "key")
                } footer: {
                    if !token.isEmpty && token != String(localized: "Failed to get token.") {
                        if valid {
                            Text(String(localized: "Your sandbox token is valid."))
                        } else {
                            Text(String(localized: "Your sandbox token is invalid."))
                        }
                    }

                    if !state.exploit_succeeded {
                        Text(String(localized: "Disabled because the exploit failed. Is your iOS version supported?"))
                    }
                }

                Section {
                    PlainToggle(text: String(localized: "Keep Alive"), infoType: .info, infoMessage: String(localized: "Keep Alive allows the app to keep running in the background."), isOn: $ka_on)
                        .onChange(of: ka_on) { _, enabled in
                            if enabled {
                                keep_alive()
                            } else {
                                let_die()
                            }
                        }

                    PlainToggle(text: String(localized: "Dismiss after importing"), infoType: .info, infoMessage: String(localized: "When enabled, the Tendies explorer will close automatically after importing a .tendies file into PosterBoard."), isOn: $dismiss_after_import)
                } header: {
                    Label(String(localized: "Settings"), systemImage: "gear")
                }

                Section {
                    Button {
                        show_confirm = true
                    } label: {
                        Text(String(localized: "Respring"))
                    }
                } header: {
                    Label(String(localized: "Tools"), systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(String(localized: "Respring method by neon, swift implementation by skadz."))
                }

                Section {
                    CreditsRow(name: "roooot", role: String(localized: "Main developer"), profile: URL(string: "https://github.com/rooootdev")!)
                    CreditsRow(name: "forcequit", role: String(localized: "The bad_query exploit"), profile: URL(string: "https://github.com/forcequitOS")!)
                    CreditsRow(name: "johnny", role: String(localized: "His work on the MCM bug class"), profile: URL(string: "https://github.com/0xjohnnydev")!)
                    CreditsRow(name: "jailbreak.party", role: String(localized: "PartyUI, GestaltView"), profile: URL(string: "https://github.com/jailbreakdotparty")!)
                    CreditsRow(name: "SerStars", role: String(localized: "Tendies repository"), profile: URL(string: "https://github.com/SerStars")!)
                    CreditsRow(name: "Erico", role: String(localized: "Translate"), profile: URL(string: "https://github.com/EricoEC")!)
                } header: {
                    Label(String(localized: "Credits"), systemImage: "person.3.fill")
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text(String(localized: "Done"))
                        }
                    }
                }
            }
            .alert(String(localized: "Are you sure?"), isPresented: $show_confirm) {
                Button(String(localized: "Cancel")) {
                    show_confirm = false
                }

                Button(String(localized: "Confirm")) {
                    state.respring()
                }
            } message: {
                Text(String(localized: "Confirm that you want to respring."))
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

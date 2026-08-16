//
//  SantanderView.swift
//  mond
//
//  Created by ruter on 14.08.26.
//

import SwiftUI
import AVKit
import AVFoundation
import UniformTypeIdentifiers
import ImageIO

struct SantanderPath: Hashable {
    let url: URL
    let last_path_component: String
    let display_name: String?
    let is_directory: Bool
    let content_type: UTType?

    var path: String { url.path }
    var title: String { display_name ?? (path == "/" ? "/" : last_path_component) }
    var is_hidden: Bool { last_path_component.hasPrefix(".") }

    var icon_name: String {
        if is_directory { return "folder.fill" }
        guard let type = content_type else { return "doc" }
        if type.isSubtype(of: .text) { return "doc.text" }
        if type.isSubtype(of: .image) { return "photo" }
        if type.isSubtype(of: .audio) { return "waveform" }
        if type.isSubtype(of: .movie) || type.isSubtype(of: .video) { return "play" }
        return "doc"
    }

    nonisolated init(url: URL) {
        self.url = url
        self.last_path_component = url.path == "/" ? "/" : url.lastPathComponent
        let values = try? url.resourceValues(forKeys: [.contentTypeKey])
        var is_dir = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &is_dir)
        self.is_directory = exists && is_dir.boolValue
        self.content_type = values?.contentType
        self.display_name = nil
    }

    nonisolated init(url: URL, is_directory: Bool) {
        self.url = url
        self.last_path_component = url.path == "/" ? "/" : url.lastPathComponent
        self.is_directory = is_directory
        self.content_type = nil
        self.display_name = nil
    }

    nonisolated init(url: URL, display_name: String?, is_directory: Bool) {
        self.url = url
        self.last_path_component = url.path == "/" ? "/" : url.lastPathComponent
        self.display_name = display_name
        self.is_directory = is_directory
        self.content_type = nil
    }
}

struct SantanderView: View {
    var body: some View {
        SantanderDirectoryView(path: SantanderPath(
            url: URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/"),
            is_directory: true
        ))
    }
}

private struct SantanderDirectoryListing {
    let items: [SantanderPath]
    let empty_state_message: String?
}

struct SantanderDirectoryView: View {
    let path: SantanderPath

    @State private var items: [SantanderPath] = []
    @State private var empty_message: String?
    @State private var is_loading = true
    @State private var search_text = ""
    @State private var sort_ascending = true
    @State private var display_hidden_files = true

    var body: some View {
        content
            .navigationTitle(path.title)
            .searchable(text: $search_text, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar { toolbar }
            .task { load() }
    }

    @ViewBuilder
    private var content: some View {
        if is_loading {
            ProgressView()
        } else if rendered_items.isEmpty {
            ContentUnavailableView(empty_state_message, systemImage: "folder")
        } else {
            list
        }
    }

    private var list: some View {
        List(rendered_items, id: \.self) { item in
            if item.is_directory {
                NavigationLink {
                    SantanderDirectoryView(path: item)
                } label: {
                    row(for: item)
                }
            } else {
                NavigationLink {
                    SantanderFileView(path: item)
                } label: {
                    row(for: item)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(for item: SantanderPath) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon_name)
                .foregroundStyle(item.is_directory ? Color.accentColor : Color.secondary)
                .frame(width: 28)
            Text(item.title)
                .foregroundStyle(item.is_hidden ? Color.secondary : Color.primary)
                .lineLimit(1)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                NavigationLink {
                    SantanderDirectoryView(path: root_path)
                } label: {
                    Label(String(localized: "Go to Root"), systemImage: "externaldrive")
                }
                NavigationLink {
                    SantanderDirectoryView(path: home_path)
                } label: {
                    Label(String(localized: "Go to Home"), systemImage: "house")
                }
                Divider()
                Toggle(String(localized: "Display hidden files"), isOn: $display_hidden_files)
                Divider()
                Button {
                    sort_ascending = true
                } label: {
                    Label(String(localized: "Sort A-Z"), systemImage: "textformat")
                }
                Button {
                    sort_ascending = false
                } label: {
                    Label(String(localized: "Sort Z-A"), systemImage: "textformat")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var root_path: SantanderPath {
        SantanderPath(url: URL(fileURLWithPath: "/"), is_directory: true)
    }

    private var home_path: SantanderPath {
        SantanderPath(url: URL(fileURLWithPath: NSHomeDirectory()), is_directory: true)
    }

    private var rendered_items: [SantanderPath] {
        var result = items
        if !display_hidden_files {
            result.removeAll { $0.is_hidden }
        }
        let query = search_text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(query) || $0.path.localizedCaseInsensitiveContains(query)
            }
        }
        if sort_ascending {
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } else {
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }
        return result
    }

    private var empty_state_message: String {
        if !search_text.isEmpty { return String(localized: "No matching items.") }
        if !display_hidden_files && !items.isEmpty {
            return String(localized: "No visible items. Enable \"Display hidden files\" to show dotfiles.")
        }
        return empty_message ?? String(localized: "Directory is empty.")
    }

    private func load() {
        is_loading = true
        let path = path
        DispatchQueue.global(qos: .userInitiated).async {
            let listing = Self.load_directory_contents(for: path)
            DispatchQueue.main.async {
                self.items = listing.items
                self.empty_message = listing.empty_state_message
                self.is_loading = false
            }
        }
    }

    private static func load_directory_contents(for path: SantanderPath) -> SantanderDirectoryListing {
        let apps_root = "/var/mobile/Containers/Data/Application"

        var normalized = path.path
        if normalized.hasPrefix("/private/") { normalized.removeFirst("/private/".count - 1) }
        if normalized.hasSuffix("/") { normalized.removeLast() }

        if normalized == apps_root {
            let items = list_containers(apps_root).map { container in
                let url = URL(fileURLWithPath: container, isDirectory: true)
                return SantanderPath(url: url, display_name: bundle_id(for: url), is_directory: true)
            }
            if items.isEmpty {
                return SantanderDirectoryListing(items: [], empty_state_message: String(localized: "No app containers found."))
            }
            return SantanderDirectoryListing(items: items, empty_state_message: nil)
        }

        if let listing = try_direct_listing(for: path) {
            return listing
        }

        var grant_c = path.path.utf8CString.map { Int8($0) }
        let handle = bad_query(&grant_c, true, nil, false, nil)
        if handle >= 0, let listing = try_direct_listing(for: path) {
            return listing
        }

        return SantanderDirectoryListing(items: [], empty_state_message: String(localized: "Cannot list directory (missing permissions)."))
    }

    private static func try_direct_listing(for path: SantanderPath) -> SantanderDirectoryListing? {
        guard path.is_directory else {
            return SantanderDirectoryListing(items: [], empty_state_message: String(localized: "Not a directory."))
        }

        let fm = FileManager.default
        var is_dir = ObjCBool(false)
        let exists = fm.fileExists(atPath: path.path, isDirectory: &is_dir)
        if !exists || !is_dir.boolValue {
            return nil
        }
        if !fm.isReadableFile(atPath: path.path) {
            return nil
        }

        do {
            let urls = try fm.contentsOfDirectory(at: path.url, includingPropertiesForKeys: nil)
            let items = urls.map(SantanderPath.init(url:))
            return SantanderDirectoryListing(items: items, empty_state_message: items.isEmpty ? String(localized: "Directory is empty.") : nil)
        } catch {
            return nil
        }
    }

    private static func bundle_id(for container: URL) -> String? {
        let candidates = [
            container.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist"),
            container.appendingPathComponent("com.apple.mobile_container_manager.metadata.plist")
        ]

        for url in candidates {
            if let data = try? Data(contentsOf: url), let id = metadata_identifier(from: data) {
                return id
            }
        }

        for url in candidates {
            if let id = pb.read_meta_key(at: url, key: "MCMMetadataIdentifier") {
                return id
            }
        }

        return nil
    }

    private static func metadata_identifier(from data: Data) -> String? {
        let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        return plist?["MCMMetadataIdentifier"] as? String
    }
}

struct SantanderFileView: View {
    let path: SantanderPath

    @State private var is_editing = false
    @State private var is_editable = false
    @State private var edit_text = ""
    @State private var original_encoding: String.Encoding = .utf8
    @State private var original_plist_format: PropertyListSerialization.PropertyListFormat?
    @State private var save_error: String?

    private enum PreviewKind {
        case image
        case video
        case audio
        case text
    }

    var body: some View {
        content
            .navigationTitle(path.title)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if is_editing {
                        Button(String(localized: "Cancel")) {
                            is_editing = false
                        }
                        Button(String(localized: "Save")) {
                            save()
                        }
                    } else {
                        ShareLink(item: path.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        if is_editable {
                            Button {
                                begin_editing()
                            } label: {
                                Image(systemName: "square.and.pencil")
                            }
                        }
                    }
                }
            }
            .task {
                if preview_kind == .text,
                   Self.grant_file_read(path.path),
                   let data = try? Data(contentsOf: path.url) {
                    is_editable = Self.decode_text(from: data) != nil
                        || Self.plist_editor_content(from: data) != nil
                }
            }
            .alert(String(localized: "Save Failed"), isPresented: Binding(
                get: { save_error != nil },
                set: { if !$0 { save_error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(save_error ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        if is_editing {
            TextEditor(text: $edit_text)
                .font(.system(size: 13, design: .monospaced))
                .padding(4)
        } else {
            switch preview_kind {
            case .image:
                image_preview
            case .video:
                MediaPlayerView(url: path.url, is_audio: false)
            case .audio:
                MediaPlayerView(url: path.url, is_audio: true)
            case .text:
                text_preview
            }
        }
    }

    private var image_preview: some View {
        Group {
            if let image = load_image() {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else {
                ContentUnavailableView(failure_text(String(localized: "Failed to render image")), systemImage: "photo")
            }
        }
    }

    private var text_preview: some View {
        ScrollView {
            Text(Self.render_file(at: path.url))
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }

    private func begin_editing() {
        guard Self.grant_file_read(path.path),
              let data = try? Data(contentsOf: path.url) else {
            return
        }
        if let (text, format) = Self.plist_editor_content(from: data) {
            edit_text = text
            original_encoding = .utf8
            original_plist_format = format
            is_editing = true
            return
        }
        guard let (text, encoding) = Self.decode_text_encoding(from: data) else {
            return
        }
        edit_text = text
        original_encoding = encoding
        original_plist_format = nil
        is_editing = true
    }

    private func save() {
        guard Self.grant_file_write(path.path) else {
            save_error = String(localized: "Missing write permission.")
            return
        }
        if let format = original_plist_format {
            save_plist(format: format)
            return
        }
        guard let data = edit_text.data(using: original_encoding) else {
            save_error = String(localized: "Could not encode text.")
            return
        }
        do {
            try data.write(to: path.url)
            is_editing = false
        } catch {
            save_error = error.localizedDescription
        }
    }

    private func save_plist(format: PropertyListSerialization.PropertyListFormat) {
        guard let edited_data = edit_text.data(using: .utf8) else {
            save_error = String(localized: "Could not encode text.")
            return
        }
        let object: Any
        if let json = try? JSONSerialization.jsonObject(with: edited_data) {
            object = json
        } else if let plist = try? PropertyListSerialization.propertyList(from: edited_data, options: [], format: nil) {
            object = plist
        } else {
            save_error = String(localized: "Edited text is not a valid plist/JSON document.")
            return
        }
        do {
            let out_data = try PropertyListSerialization.data(fromPropertyList: object, format: format, options: 0)
            try out_data.write(to: path.url)
            is_editing = false
        } catch {
            save_error = error.localizedDescription
        }
    }

    private var preview_kind: PreviewKind {
        if let type = path.content_type {
            if type.isSubtype(of: .image) { return .image }
            if type.isSubtype(of: .movie) || type.isSubtype(of: .video) { return .video }
            if type.isSubtype(of: .audio) { return .audio }
            return .text
        }

        let ext = path.url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic", "heif", "bmp", "tif", "tiff", "webp"].contains(ext) {
            return .image
        }
        if ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext) {
            return .video
        }
        if [
            "mp3", "m4a", "m4b", "m4p", "aac", "aiff", "aif", "aifc", "wav", "wave",
            "caf", "flac", "alac", "opus", "oga", "ogg", "mka", "wma", "ac3", "eac3",
            "amr", "3gp", "3gpp", "3g2", "au", "snd", "mp2", "mp1", "ape", "tta", "wv"
        ].contains(ext) {
            return .audio
        }
        return .text
    }

    private func load_image() -> Image? {
        _ = Self.grant_file_read(path.path)
        guard let source = CGImageSourceCreateWithURL(path.url as CFURL, nil),
              let cg_image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return Image(decorative: cg_image, scale: 1)
    }

    private func failure_text(_ title: String) -> String {
        """
        \(title):
        \(path.path)

        \(Self.unreadable_file_details(for: path.url))
        """
    }

    private static func grant_file_read(_ path: String) -> Bool {
        let fm = FileManager.default
        if fm.isReadableFile(atPath: path) {
            return true
        }
        var path_c = path.utf8CString.map { Int8($0) }
        let handle = bad_query(&path_c, true, nil, false, nil)
        return handle >= 0 && fm.isReadableFile(atPath: path)
    }

    private static func grant_file_write(_ path: String) -> Bool {
        let fm = FileManager.default
        if fm.isWritableFile(atPath: path) {
            return true
        }
        var path_c = path.utf8CString.map { Int8($0) }
        let handle = bad_query(&path_c, true, nil, false, nil)
        return handle >= 0 && fm.isWritableFile(atPath: path)
    }

    private static func render_file(at url: URL) -> String {
        let data: Data
        do {
            data = try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            guard grant_file_read(url.path),
                  let granted = try? Data(contentsOf: url, options: .mappedIfSafe) else {
                return """
                Failed to read file:
                \(url.path)
                Error: \(error.localizedDescription)

                \(unreadable_file_details(for: url))
                """
            }
            data = granted
        }

        if data.isEmpty {
            return "(empty file)"
        }

        if let plist = decode_property_list(from: data) {
            return plist
        }

        if let text = decode_text(from: data) {
            return text
        }

        return binary_preview(from: data)
    }

    private static func unreadable_file_details(for url: URL) -> String {
        let fm = FileManager.default
        var lines: [String] = []

        var is_dir = ObjCBool(false)
        let exists = fm.fileExists(atPath: url.path, isDirectory: &is_dir)
        lines.append("Exists: \(exists ? "yes" : "no")")
        if exists {
            lines.append("Kind: \(is_dir.boolValue ? "directory" : "regular item")")
        }

        let keys: Set<URLResourceKey> = [
            .contentTypeKey,
            .isSymbolicLinkKey,
            .isAliasFileKey,
            .fileSizeKey
        ]
        if let values = try? url.resourceValues(forKeys: keys) {
            if let type = values.contentType {
                lines.append("UTType: \(type.identifier)")
            }
            if let size = values.fileSize {
                lines.append("Size: \(size) bytes")
            }
            if let is_symlink = values.isSymbolicLink {
                lines.append("Symlink: \(is_symlink ? "yes" : "no")")
            }
            if values.isSymbolicLink == true,
               let target = try? fm.destinationOfSymbolicLink(atPath: url.path) {
                lines.append("Symlink target: \(target)")
            }
            if let is_alias = values.isAliasFile {
                lines.append("Alias file: \(is_alias ? "yes" : "no")")
            }
        }

        if let attrs = try? fm.attributesOfItem(atPath: url.path) {
            if let file_type = attrs[.type] as? FileAttributeType {
                lines.append("File attribute type: \(file_type.rawValue)")
            }
            let owner_name = attrs[.ownerAccountName] as? String
            let owner_id = (attrs[.ownerAccountID] as? NSNumber)?.intValue
            switch (owner_name, owner_id) {
            case let (name?, id?):
                lines.append("Owner: \(name) (\(id))")
            case let (name?, nil):
                lines.append("Owner: \(name)")
            case let (nil, id?):
                lines.append("Owner ID: \(id)")
            default:
                break
            }

            let group_name = attrs[.groupOwnerAccountName] as? String
            let group_id = (attrs[.groupOwnerAccountID] as? NSNumber)?.intValue
            switch (group_name, group_id) {
            case let (name?, id?):
                lines.append("Group: \(name) (\(id))")
            case let (name?, nil):
                lines.append("Group: \(name)")
            case let (nil, id?):
                lines.append("Group ID: \(id)")
            default:
                break
            }
            if let perms = attrs[.posixPermissions] as? NSNumber {
                lines.append(String(format: "POSIX perms: %04o", perms.intValue))
            }
        }

        lines.append("Readable: \(fm.isReadableFile(atPath: url.path) ? "yes" : "no")")
        lines.append("Writable: \(fm.isWritableFile(atPath: url.path) ? "yes" : "no")")
        lines.append("Executable: \(fm.isExecutableFile(atPath: url.path) ? "yes" : "no")")

        return lines.joined(separator: "\n")
    }

    private static func decode_property_list(from data: Data) -> String? {
        plist_editor_content(from: data)?.0
    }

    private static func plist_editor_content(from data: Data) -> (String, PropertyListSerialization.PropertyListFormat)? {
        guard data.starts(with: Data("bplist".utf8)) || data.starts(with: Data("<?xml".utf8)) else {
            return nil
        }

        var format: PropertyListSerialization.PropertyListFormat = .xml
        guard let plist_object = try? PropertyListSerialization.propertyList(from: data, options: [], format: &format) else {
            return nil
        }

        if JSONSerialization.isValidJSONObject(plist_object),
           let json_data = try? JSONSerialization.data(withJSONObject: plist_object, options: [.prettyPrinted, .sortedKeys]),
           let json = String(data: json_data, encoding: .utf8) {
            return (json, format)
        }

        if let xml_data = try? PropertyListSerialization.data(fromPropertyList: plist_object, format: .xml, options: 0),
           let xml = String(data: xml_data, encoding: .utf8) {
            return (xml, format)
        }

        return (String(describing: plist_object), format)
    }

    private static func decode_text(from data: Data) -> String? {
        decode_text_encoding(from: data)?.0
    }

    private static func decode_text_encoding(from data: Data) -> (String, String.Encoding)? {
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .utf32,
            .utf32LittleEndian,
            .utf32BigEndian,
            .ascii,
            .isoLatin1,
            .windowsCP1252,
            .macOSRoman,
            .nonLossyASCII
        ]

        for encoding in encodings {
            guard let value = String(data: data, encoding: encoding) else { continue }
            if looks_like_text(value) {
                return (value, encoding)
            }
        }
        return nil
    }

    private static func looks_like_text(_ value: String) -> Bool {
        if value.isEmpty { return true }
        let scalars = value.unicodeScalars
        let disallowed = scalars.filter { scalar in
            let v = scalar.value
            if v == 9 || v == 10 || v == 13 { return false }
            if v < 32 { return true }
            if v >= 0x7F && v <= 0x9F { return true }
            return false
        }
        return Double(disallowed.count) / Double(scalars.count) < 0.01
    }

    private static func binary_preview(from data: Data) -> String {
        let limit = min(data.count, 4096)
        let chunk = data.prefix(limit)
        var lines: [String] = []
        lines.append("Binary data (\(data.count) bytes). Showing first \(limit) bytes:")
        lines.append("")

        var offset = 0
        while offset < chunk.count {
            let row = chunk[offset..<min(offset + 16, chunk.count)]
            let hex = row.map { String(format: "%02X", $0) }.joined(separator: " ")
            let ascii = row.map { byte -> String in
                if byte >= 32 && byte <= 126 { return String(UnicodeScalar(byte)) }
                return "."
            }.joined()
            lines.append(String(format: "%08X  %-47@  %@", offset, hex as NSString, ascii))
            offset += 16
        }

        return lines.joined(separator: "\n")
    }
}

private struct MediaPlayerView: View {
    let url: URL
    var is_audio: Bool = false

    @State private var player: AVPlayer

    init(url: URL, is_audio: Bool) {
        self.url = url
        self.is_audio = is_audio
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
            if is_audio {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true, options: [])
            player.play()
        }
        .onDisappear {
            player.pause()
        }
    }
}
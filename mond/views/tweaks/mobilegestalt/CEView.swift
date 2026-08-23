//
//  CEView.swift
//  mond
//
//  Created by ruter on 17.08.26.
//

import SwiftUI
import PartyUI

enum ce_type: String, CaseIterable, Identifiable {
    case str, int, bool, data
    var id: String { rawValue }

    var label: String {
        switch self {
            case .str: "String"
            case .int: "Integer"
            case .bool: "Boolean"
            case .data: "Data (Base64)"
        }
    }

    static func from(_ value: Any?) -> ce_type {
        switch value {
            case is String: .str
            case let n as NSNumber:
                CFGetTypeID(n) == CFBooleanGetTypeID() ? .bool : .int
            case is Data: .data
            default: .str
        }
    }
}

func ce_encode(_ value: Any?, as type: ce_type) -> String {
    switch type {
        case .str:
            value as? String ?? ""
        case .int:
            (value as? NSNumber)?.stringValue ?? ""
        case .bool:
            ((value as? NSNumber)?.boolValue == true) ? NSLocalizedString("true", tableName: "CEView", comment: "") : 
            NSLocalizedString("false", tableName: "CEView", comment: "")
        case .data:
            (value as? Data)?.base64EncodedString() ?? ""
    }
}

func ce_parse(_ text: String, as type: ce_type) throws -> Any {
    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    switch type {
        case .str:
            return text
        case .int:
            guard let v = Int64(t) else { throw ce_err.bad_val(NSLocalizedString("invalid_integer", tableName: "CEView", comment: "")) }
            return NSNumber(value: v)
        case .bool:
            switch t.lowercased() {
                case "true", "1", "yes": return NSNumber(value: true)
                case "false", "0", "no": return NSNumber(value: false)
                default: throw ce_err.bad_val(NSLocalizedString("enter_true_false", tableName: "CEView", comment: ""))
            }
        case .data:
            guard let d = Data(base64Encoded: t) else { throw ce_err.bad_val(NSLocalizedString("invalid_base64", tableName: "CEView", comment: "")) }
            return d
    }
}

enum ce_err: LocalizedError {
    case bad_val(String)

    var errorDescription: String? {
        switch self {
            case .bad_val(let m): m
        }
    }
}

struct CEView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var search = ""
    @State private var editing: CEField?
    @State private var showing_add = false

    private var keys: [String] {
        let cache = mg_dict_now["CacheExtra"] as? [String: Any] ?? [:]
        let all = cache.keys.sorted()
        guard !search.isEmpty else { return all }
        
        return all.filter {
            $0.localizedCaseInsensitiveContains(search) ||
            ce_summary(cache[$0]).localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            if keys.isEmpty {
                Text(search.isEmpty ? NSLocalizedString("no_cache_extra_fields", tableName: "CEView", comment: "") : 
                NSLocalizedString("no_results", tableName: "CEView", comment: ""))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(keys, id: \.self) { key in
                    let cache = mg_dict_now["CacheExtra"] as? [String: Any] ?? [:]
                    Button { editing = CEField(key: key, value: cache[key]) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key)                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text(ce_summary(cache[key]))
                                    .monospaced()
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    guard let cache = mg_dict_now["CacheExtra"] as? NSMutableDictionary else { return }
                    let sorted = keys
                    for i in offsets {
                        cache.removeObject(forKey: sorted[i])
                    }
                    
                    mg_dict_now["CacheExtra"] = cache
                }
            }
        }
        .searchable(text: $search, prompt: NSLocalizedString("search_for_keys_or_values", tableName: "CEView", comment: ""))
        .navigationTitle("CacheExtra")
        .onAppear() {
            mg_load()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showing_add = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        .sheet(item: $editing) { field in
            CEEditSheet(key: field.key, value: field.value) { key, value in
                guard let cache = mg_dict_now["CacheExtra"] as? NSMutableDictionary else { return }
                cache[key] = value
                mg_dict_now["CacheExtra"] = cache
            }
        }
        .sheet(isPresented: $showing_add) {
            CEAddSheet { key, value in
                guard let cache = mg_dict_now["CacheExtra"] as? NSMutableDictionary else { return }
                cache[key] = value
                mg_dict_now["CacheExtra"] = cache
            }
        }
    }

    private func save() {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)
            try mg_write(data)
            
            AlertinatorLocalized.shared.alert(
                title: NSLocalizedString("saved", tableName: "CEView", comment: ""),
                body: NSLocalizedString("you_must_respring", tableName: "CEView", comment: ""),
                actionLabel: NSLocalizedString("respring", comment: ""),
                action: {
                    state.respring()
                }
            )
        } catch {
            AlertinatorLocalized.shared.alert(title: NSLocalizedString("save_failed", comment: ""), body: error.localizedDescription)
        }
    }
}

private struct CEField: Identifiable {
    let key: String
    let value: Any?
    var id: String { key }
}

private struct CEEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let key: String
    let save: (String, Any) -> Void

    @State private var type: ce_type
    @State private var text: String
    @State private var error: String?

    init(key: String, value: Any?, save: @escaping (String, Any) -> Void) {
        self.key = key
        self.save = save
        let t = ce_type.from(value)
        _type = State(initialValue: t)
        _text = State(initialValue: ce_encode(value, as: t))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("type", tableName: "CEView", comment: "")) {
                    Picker(NSLocalizedString("type", tableName: "CEView", comment: ""), selection: $type) {
                        ForEach(ce_type.allCases) { t in Text(t.label).tag(t) }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: type) { _, _ in
                        error = nil
                    }
                }
                Section(NSLocalizedString("value", tableName: "CEView", comment: "")) {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle(key)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) {
                        do {
                            save(key, try ce_parse(text, as: type))
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct CEAddSheet: View {
    @Environment(\.dismiss) private var dismiss

    let save: (String, Any) -> Void

    @State private var key = ""
    @State private var type: ce_type = .str
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("key", tableName: "CEView", comment: "")) {
                    TextField(NSLocalizedString("key_name", tableName: "CEView", comment: ""), text: $key)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                Section(NSLocalizedString("type", tableName: "CEView", comment: "")) {
                    Picker(NSLocalizedString("type", tableName: "CEView", comment: ""), selection: $type) {
                        ForEach(ce_type.allCases) { t in Text(t.label).tag(t) }
                    }
                    .pickerStyle(.menu)
                }
                Section(NSLocalizedString("value", tableName: "CEView", comment: "")) {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle(NSLocalizedString("add_field", tableName: "CEView", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("add", tableName: "CEView", comment: "")) {
                        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            error = NSLocalizedString("key_cant_be_empty", tableName: "CEView", comment: "")
                            return
                        }
                        guard (mg_dict_now["CacheExtra"] as? [String: Any])?[trimmed] == nil else {
                            error = NSLocalizedString("key_already_exist", tableName: "CEView", comment: "")
                            return
                        }
                        do {
                            save(trimmed, try ce_parse(text, as: type))
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private func ce_summary(_ value: Any?) -> String {
    switch value {
    case let s as String: s.isEmpty ? "(empty str)" : s
    case let n as NSNumber:
        CFGetTypeID(n) == CFBooleanGetTypeID()
            ? (n.boolValue ? "true" : "false")
            : n.stringValue
    case let d as Data: "Data (\(d.count) bytes)"
    default: String(describing: value ?? "nil")
    }
}

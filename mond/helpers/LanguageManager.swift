//
//  LanguageManager.swift
//  mond
//

import Foundation
import Combine

struct AppLanguage: Identifiable, Equatable {
    let id: String
    let nativeName: String
    let localizationCredits: String

    static let system = AppLanguage(id: "system", nativeName: "", localizationCredits: "")

    static let supported: [AppLanguage] = [
        .system,
        AppLanguage(id: "en", nativeName: "English", localizationCredits: "Made by rooootdev"),
        AppLanguage(id: "ru", nativeName: "Русский", localizationCredits: "Made by Hikariman"),
        AppLanguage(id: "es", nativeName: "Español", localizationCredits: "Made by usedoperative-sudo / by AI(50%)"),
        AppLanguage(id: "it", nativeName: "Italiano", localizationCredits: "Made by AI(100%)"),
        AppLanguage(id: "uk", nativeName: "Українська", localizationCredits: "Made by Hikariman, Hikariman's brother and fUnGuN\nSorry for skill issue"),
        AppLanguage(id: "sr", nativeName: "Srpski", localizationCredits: "Made by Hikariman"),
    ]
}

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private static let storageKey = "app_language"

    @Published private(set) var current: String

    private init() {
        current = UserDefaults.standard.string(forKey: Self.storageKey) ?? "system"
        Bundle.mond_setLanguage(current == "system" ? nil : current)
    }

    func select(_ code: String) {
        guard code != current else { return }
        current = code
        UserDefaults.standard.set(code, forKey: Self.storageKey)
        Bundle.mond_setLanguage(code == "system" ? nil : code)
    }
}
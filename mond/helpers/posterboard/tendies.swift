//
//  tendies.swift
//  mond
//
//  Created by ruter on 15.08.26.
//

import Foundation
import Observation

struct tendies: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let url: String
    let preview: String
    let authors: String?
    let contest: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case url
        case preview
        case authors
        case contest
    }

    var preview_url: URL? {
        URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/\(preview)")
    }

    var download_url: URL? {
        URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/\(url)")
    }
}

struct tendies_service {
    private let custom = URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-custom.json")!
    private let apple = URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-apple.json")!

    private func fetch(from url: URL) async throws -> [tendies] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse,
              200..<300 ~= response.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([tendies].self, from: data)
    }
    
    func fetch_tendies() async throws -> [tendies] {
        async let custom = fetch(from: custom)
        async let apple = fetch(from: apple)

        let (custom_tendies, apple_tendies) = try await (custom, apple)

        return (custom_tendies + apple_tendies)
            .uniqued()
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

func download_tendies(_ wallpaper: tendies) async throws -> URL {
    guard let url = wallpaper.download_url else {
        throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    guard let response = response as? HTTPURLResponse,
          200..<300 ~= response.statusCode else {
        throw URLError(.badServerResponse)
    }

    let destination = URL(fileURLWithPath: AppPaths.tendies, isDirectory: true)
        .appendingPathComponent(url.lastPathComponent)
    try data.write(to: destination, options: .atomic)
    return destination
}

@Observable
@MainActor
final class TendiesVM {
    private let service = tendies_service()

    var wallpapers: [tendies] = []
    var query = ""
    var loading = false
    var error_msg: String?

    var filtered: [tendies] {
        guard !query.isEmpty else {
            return wallpapers
        }

        return wallpapers.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            ($0.description ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.authors ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    func load() async {
        guard !loading else { return }

        loading = true
        error_msg = nil

        do {
            wallpapers = try await service.fetch_tendies()
        } catch {
            error_msg = error.localizedDescription
        }

        loading = false
    }

    func retry() async {
        await load()
    }
}
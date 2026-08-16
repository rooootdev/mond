//
//  TendiesView.swift
//  mond
//
//  Created by ruter on 15.08.26.
//

import SwiftUI
import UIKit

struct TendiesView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dismiss_after_import") private var dismiss_after_import = false
    @State private var vm = TendiesVM()
    @State private var import_error: String?

    var body: some View {
        NavigationStack {
            Group {
                if vm.loading && vm.wallpapers.isEmpty {
                    ProgressView(String(localized: "Loading wallpapers…"))
                } else if let error = vm.error_msg, vm.wallpapers.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "Couldn't Load tendies"), systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button(String(localized: "Try Again")) {
                            Task {
                                await vm.retry()
                            }
                        }
                    }
                } else {
                    tendies_list
                }
            }
            .navigationTitle(String(localized: "Tendies"))
            .searchable(
                text: $vm.query,
                prompt: String(localized: "Search wallpapers")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await vm.load()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.loading)
                }
            }
            .task {
                await vm.load()
            }
        }
        .alert(String(localized: "Import Failed"), isPresented: Binding(
            get: { import_error != nil },
            set: { if !$0 { import_error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(import_error ?? "")
        }
    }

    private var tendies_list: some View {
        ScrollView {
            MasonryLayout(columns: 2, spacing: 16) {
                ForEach(vm.filtered) { wallpaper in
                    tendies_cell(wallpaper)
                }
            }
            .padding(.horizontal)
        }
        .overlay {
            if vm.filtered.isEmpty &&
                !vm.loading &&
                !vm.query.isEmpty {
                ContentUnavailableView.search
            }
        }
    }

    private func tendies_cell(_ wallpaper: tendies) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink {
                TendiesDetail(wallpaper: wallpaper, dismiss_explorer: { dismiss() })
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    AsyncImage(url: wallpaper.preview_url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        case .failure:
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        @unknown default:
                            EmptyView()
                        }
                    }

                    HStack {
                        Text(wallpaper.name)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .contextMenu {
            if wallpaper.download_url != nil {
                Button {
                    Task {
                        await add_to_imported(wallpaper)
                    }
                } label: {
                    Label(String(localized: "Add to Imported"), systemImage: "arrow.down.circle")
                }
            }
        }
    }

    private func add_to_imported(_ wallpaper: tendies) async {
        do {
            let destination = try await download_tendies(wallpaper)
            state.append_poster_file(destination)
            print("(pb) imported \(destination.lastPathComponent)")

            if dismiss_after_import {
                dismiss()
            }
        } catch {
            print("(pb) download failed: \(error.localizedDescription)")
            import_error = error.localizedDescription
        }
    }
}

private struct MasonryLayout: Layout {
    var columns = 2
    var spacing: CGFloat = 16

    private func column_width(in width: CGFloat) -> CGFloat {
        (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }

    private func shortest_column(_ heights: [CGFloat]) -> Int {
        heights.firstIndex(of: heights.min() ?? 0) ?? 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let cell_width = column_width(in: width)
        var heights = [CGFloat](repeating: 0, count: columns)

        for subview in subviews {
            let height = subview.sizeThatFits(ProposedViewSize(width: cell_width, height: nil)).height
            let column = shortest_column(heights)
            heights[column] += height + spacing
        }

        return CGSize(width: width, height: (heights.max() ?? 0) - spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let cell_width = column_width(in: bounds.width)
        var heights = [CGFloat](repeating: 0, count: columns)

        for subview in subviews {
            let column = shortest_column(heights)
            let size = subview.sizeThatFits(ProposedViewSize(width: cell_width, height: nil))
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(column) * (cell_width + spacing), y: bounds.minY + heights[column]),
                proposal: ProposedViewSize(width: cell_width, height: size.height)
            )
            heights[column] += size.height + spacing
        }
    }
}

struct TendiesDetail: View {
    let wallpaper: tendies
    let dismiss_explorer: () -> Void

    @EnvironmentObject private var state: AppState
    @AppStorage("dismiss_after_import") private var dismiss_after_import = false

    @State private var importing = false
    @State private var import_error: String?

    var body: some View {
        List {
            Section {
                AsyncImage(url: wallpaper.preview_url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 500)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                    case .failure:
                        ContentUnavailableView(String(localized: "Preview Unavailable"), systemImage: "photo", description: Text(String(localized: "The wallpaper preview couldn't be loaded.")))

                    @unknown default:
                        EmptyView()
                    }
                }

                VStack(alignment: .leading) {
                    Text(wallpaper.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let description = wallpaper.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                if let authors = wallpaper.authors, !authors.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                        Text(authors)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                    Text(String(wallpaper.id))
                }

                if let contest = wallpaper.contest {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy")
                            .foregroundStyle(.secondary)
                        Text(contest)
                    }
                }

                if wallpaper.download_url != nil {
                    Button {
                        Task {
                            await import_wallpaper()
                        }
                    } label: {
                        if importing {
                            HStack {
                                ProgressView()
                                Text(String(localized: "Downloading..."))
                            }
                        } else {
                            Text(String(localized: "Add to Imported"))
                        }
                    }
                    .disabled(importing)
                }
            }
        }
        .navigationTitle(wallpaper.name)
        .alert(String(localized: "Download Failed"), isPresented: Binding(
            get: { import_error != nil },
            set: { if !$0 { import_error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(import_error ?? "")
        }
    }

    private func import_wallpaper() async {
        importing = true
        defer { importing = false }

        do {
            let destination = try await download_tendies(wallpaper)
            state.append_poster_file(destination)
            print("(pb) imported \(destination.lastPathComponent)")

            if dismiss_after_import {
                dismiss_explorer()
            }
        } catch {
            print("(pb) download failed: \(error.localizedDescription)")
            import_error = error.localizedDescription
        }
    }
}
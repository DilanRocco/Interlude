//
//  StretchHomePage.swift
//  testMacos
//
//  Created by Dilan Piscatello on 7/5/22.
//

import SwiftUI
import Cocoa
import MediaPlayer
import AVKit

var scrollingAllowedinView = false

struct StretchHomePage: View {
    @ObservedObject private var viewModel = ViewModel()
    @State private var currentSubviewIndex = 0
    @State private var show = false
    @State private var selectedCategory: StretchCategory = .all

    let columns = [GridItem(.adaptive(minimum: 300))]

    var body: some View {
        if !show {
            VStack(spacing: 0) {
                CategoryFilterBar(selectedCategory: $selectedCategory)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)

                let indices = viewModel.filteredIndices(for: selectedCategory)

                if indices.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: selectedCategory.systemImage)
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No \(selectedCategory.rawValue) stretches yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(indices, id: \.self) { i in
                                StretchTile(
                                    show: $show,
                                    index: i,
                                    currentSubviewIndex: $currentSubviewIndex,
                                    viewModel: viewModel
                                ).animation(.none)
                            }
                        }.animation(.none)
                    }
                }
            }
            .frame(width: 800, height: 800, alignment: .top)
            .transition(AnyTransition.move(edge: .leading))
            .animation(.default, value: show)
        }

        if show {
            InDepthView(
                currentSubviewIndex: $currentSubviewIndex,
                viewModel: viewModel,
                show: $show
            )
            .frame(width: 800, height: 800, alignment: .center)
            .transition(AnyTransition.move(edge: .trailing))
            .animation(.default, value: show)
        }
    }
}

// MARK: - Category filter bar

struct CategoryFilterBar: View {
    @Binding var selectedCategory: StretchCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StretchCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct CategoryChip: View {
    let category: StretchCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 12, weight: .medium))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stretch tile

struct StretchTile: View {
    @State var hovered = false
    @Binding var show: Bool
    @State var index: Int
    @Binding var currentSubviewIndex: Int
    @ObservedObject var viewModel: StretchHomePage.ViewModel

    var body: some View {
        VStack {
            Image(nsImage: viewModel.generateThumbnail(
                path: Bundle.main.url(forResource: viewModel.stretches[index][0], withExtension: "mp4")!)!
            )
            .scaleEffect(hovered ? 1 : 1.1)
            .clipped()
            .animation(.default, value: hovered)

            Text(viewModel.stretches[index][1])
                .foregroundColor(hovered ? .blue : .none)
                .animation(.none)
                .font(.title3)

            Text(viewModel.stretches[index][3])
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .animation(.none)
        .onTapGesture {
            withAnimation(.spring()) {
                show.toggle()
            }
            currentSubviewIndex = index
        }
        .onAppear {
            scrollingAllowedinView = false
        }
        .animation(.easeIn(duration: 0.4), value: hovered)
        .onHover { hovering in
            hovered = hovering
        }
        .padding(.bottom)
    }
}


struct AVPlayerControllerRepresented: NSViewRepresentable {
    var player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}

extension AVPlayerView {

    override open func hitTest(_ point: NSPoint) -> NSView? {
        if (!scrollingAllowedinView) {
            return nil
        } else {
            return super.hitTest(point)
        }
    }

    override open func keyDown(with event: NSEvent) {
        let spaceBarKeyCode = UInt16(49)
        if event.keyCode == spaceBarKeyCode {
            return
        }
    }
}

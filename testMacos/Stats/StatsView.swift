//
//  StatsView.swift
//  testMacos
//

import SwiftUI

struct StatsView: View {
    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Stats").fontWeight(.bold).font(.largeTitle)
                Spacer()
            }.padding()

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Today")
                StatRow(label: "Breaks completed", value: viewModel.completedToday)
                StatRow(label: "Breaks skipped", value: viewModel.skippedToday)

                Divider().padding(.vertical, 8)

                SectionHeader("All Time")
                StatRow(label: "Total breaks completed", value: viewModel.allTimeTotal)
            }
            .padding(.horizontal)
            .font(.system(size: 15))

            Spacer()
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.top, 4)
    }
}

private struct StatRow: View {
    let label: String
    let value: Int
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

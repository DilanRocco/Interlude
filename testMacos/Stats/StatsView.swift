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
            }
            .padding()

            Picker("Range", selection: $viewModel.selectedScope) {
                ForEach(StatsScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(viewModel.selectedScope.title)
                StatRow(label: "Breaks taken", value: "\(viewModel.takenForScope)")
                StatRow(label: "Breaks skipped", value: "\(viewModel.skippedForScope)")
                StatRow(label: "Compliance", value: viewModel.complianceText)
                StatRow(label: "Current streak", value: "\(viewModel.streakDays) days")
                StatRow(label: "All-time breaks taken", value: "\(viewModel.allTimeTotal)")
            }
            .padding(.horizontal)
            .font(.system(size: 15))

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Break History")
                HistoryBarChart(data: viewModel.chartData)
                    .frame(height: 120)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            HStack(spacing: 12) {
                Button("Export CSV") {
                    viewModel.exportAsCSV()
                }
                Button("Export TXT") {
                    viewModel.exportAsText()
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)

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
    let value: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryBarChart: View {
    let data: [DailyStats]

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let barCount = max(data.count, 1)
                let spacing: CGFloat = 4
                let barWidth = max((proxy.size.width - CGFloat(barCount - 1) * spacing) / CGFloat(barCount), 2)
                let maxValue = max(data.map(\.totalCount).max() ?? 0, 1)

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(data) { day in
                        let barHeight = CGFloat(day.totalCount) / CGFloat(maxValue) * proxy.size.height
                        let takenRatio = day.totalCount > 0 ? CGFloat(day.takenCount) / CGFloat(day.totalCount) : 0
                        let takenHeight = barHeight * takenRatio
                        let skippedHeight = max(barHeight - takenHeight, 0)

                        VStack(spacing: 0) {
                            if day.totalCount == 0 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.12))
                                    .frame(width: barWidth, height: 2)
                            } else {
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.red.opacity(0.8))
                                        .frame(width: barWidth, height: skippedHeight)
                                    Rectangle()
                                        .fill(Color.green.opacity(0.8))
                                        .frame(width: barWidth, height: takenHeight)
                                }
                                .frame(width: barWidth, height: barHeight)
                                .cornerRadius(2)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            if data.isEmpty {
                Text("No data yet")
                    .foregroundColor(.secondary)
            }
        }
    }
}

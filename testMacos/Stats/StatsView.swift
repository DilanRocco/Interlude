//
//  StatsView.swift
//  testMacos
//

import SwiftUI

struct StatsView: View {
    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Stats").fontWeight(.bold).font(.largeTitle)
                    Spacer()
                }
                .padding()

                SectionHeader("Recovery")
                    .padding(.horizontal)
                    .padding(.top, 16)

                RecoveryScoreSection(
                    state: viewModel.recoveryViewState,
                    score: viewModel.recoveryScoreValue,
                    scoreText: viewModel.recoveryScoreText,
                    tier: viewModel.recoveryTierLabel,
                    insight: viewModel.recoveryInsightText,
                    trend: viewModel.recoveryTrendText,
                    message: viewModel.recoveryStateMessage,
                    onRetry: viewModel.retryRecovery
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Picker("Range", selection: $viewModel.selectedScope) {
                    ForEach(StatsScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 16)

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
                .padding(.top, 16)

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

                Spacer(minLength: 24)
            }
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
                let rawBarWidth = (proxy.size.width - CGFloat(barCount - 1) * spacing) / CGFloat(barCount)
                let barWidth = min(max(rawBarWidth, 2), 28)
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

private struct RecoveryScoreSection: View {
    let state: RecoveryViewState
    let score: Int
    let scoreText: String
    let tier: String
    let insight: String
    let trend: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            RecoveryStateCard(
                title: "Calculating recovery...",
                subtitle: "Collecting today's break and workload signals.",
                actionTitle: nil,
                action: nil,
                isLoading: true
            )
        case .empty:
            RecoveryStateCard(
                title: "No recovery score yet",
                subtitle: "Complete a few break cycles and Interlude will compute your daily score.",
                actionTitle: "Refresh",
                action: onRetry,
                isLoading: false
            )
        case .error:
            RecoveryStateCard(
                title: "Recovery score unavailable",
                subtitle: "Interlude couldn't calculate the score right now.",
                actionTitle: "Retry",
                action: onRetry,
                isLoading: false
            )
        case .partial:
            VStack(alignment: .leading, spacing: 10) {
                RecoveryScoreHero(score: score, scoreText: scoreText, tier: tier, insight: insight, trend: trend)
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 2)
                }
            }
        case .ready:
            RecoveryScoreHero(score: score, scoreText: scoreText, tier: tier, insight: insight, trend: trend)
        }
    }
}

private struct RecoveryScoreHero: View {
    let score: Int
    let scoreText: String
    let tier: String
    let insight: String
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                RecoveryGauge(score: score)
                    .frame(width: 86, height: 86)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Recovery")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(scoreText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(tier)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }

            RecoveryInsightRow(icon: "waveform.path.ecg", text: insight)
            RecoveryInsightRow(icon: "arrow.up.right.circle", text: trend)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.92), Color(red: 0.12, green: 0.15, blue: 0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct RecoveryGauge: View {
    let score: Int

    private var progress: Double {
        min(max(Double(score) / 100.0, 0), 1)
    }

    private var accent: Color {
        switch score {
        case 85...100:
            return .green
        case 70...84:
            return Color(red: 0.45, green: 0.82, blue: 0.47)
        case 55...69:
            return .yellow
        case 40...54:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recovery score")
        .accessibilityValue("\(score) out of 100")
    }
}

private struct RecoveryInsightRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 14, alignment: .center)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct RecoveryStateCard: View {
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .padding(.top, 2)
            }
        }
        .redacted(reason: isLoading ? .placeholder : [])
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

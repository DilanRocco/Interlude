import SwiftUI

struct PostureFlowView: View {
    @ObservedObject var viewModel: PostureMenuViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            progressStrip
            Divider()
            content
                .padding(24)
        }
        .frame(width: 500, height: 560)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(NSColor.windowBackgroundColor),
                            Color.blue.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Posture Check")
                    .font(.title2.weight(.semibold))
                Text("Guided ergonomics scan")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Close") {
                viewModel.closeFlow()
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
    }

    private var progressStrip: some View {
        HStack(spacing: 8) {
            stepDot(index: 0, active: currentPhase >= 0, label: "Intro")
            stepDot(index: 1, active: currentPhase >= 1, label: "Setup")
            stepDot(index: 2, active: currentPhase >= 2, label: "Analyze")
            stepDot(index: 3, active: currentPhase >= 3, label: "Score")
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .intro:
            introCard
        case .calibrating(let reason):
            calibrationCard(reason: reason)
        case .cameraReady:
            cameraReadyCard
        case .analyzing:
            analyzingCard
        case .result(let result):
            scoreCard(result: result)
        case .error(let message):
            errorCard(message: message)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "figure.stand")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.blue)
            Text("Let’s run a clean posture check.")
                .font(.title3.weight(.semibold))
            Text("Interlude will auto-optimize setup if needed, run a fast camera scan, and reveal your posture score.")
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Start Check") {
                viewModel.continueFromIntro()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var cameraReadyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                Text("Camera Ready")
                    .font(.headline)
            }
            Text("Face the screen naturally and keep your shoulders relaxed. When ready, start the scan.")
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.square.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.blue.opacity(0.8))
                        Text("Center your face and keep a natural, relaxed posture.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .frame(height: 220)
            Spacer()
            Button("Analyze Posture") {
                viewModel.startAnalysis()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var analyzingCard: some View {
        VStack(spacing: 24) {
            AnalyzingPulseView()
                .padding(.top, 12)
            Text("Analyzing your posture")
                .font(.title3.weight(.semibold))
            AnalyzingStatusLabel()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func calibrationCard(reason: PostureCalibrationReason) -> some View {
        VStack(spacing: 22) {
            CalibrationPulseView()
            VStack(spacing: 8) {
                Text(reason.title)
                    .font(.title3.weight(.semibold))
                Text(reason.subtitle)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("This takes only a few seconds.")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func scoreCard(result: PostureCheckResult) -> some View {
        let score = postureScoreValue(for: result)
        let badgeColor = score >= 80 ? Color.green : (score >= 60 ? Color.orange : Color.red)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Posture Score")
                .font(.title3.weight(.semibold))
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(Double(score) / 100.0))
                        .stroke(badgeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(score)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                }
                .frame(width: 112, height: 112)
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.classification.rawValue.capitalized + " posture")
                        .font(.headline)
                    if let angle = result.correctedAngleDegrees {
                        Text(String(format: "Angle: %.1f° down", angle))
                            .foregroundColor(.secondary)
                    }
                    Text("Distance: \(result.distanceBand.label)")
                        .foregroundColor(.secondary)
                    Text(String(format: "Confidence: %.0f%%", result.confidence * 100))
                        .foregroundColor(.secondary)
                }
            }
            Text(result.recommendation)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04))
                .cornerRadius(10)
            Spacer()
            HStack {
                Button("Done") {
                    viewModel.closeFlow()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Run Again") {
                    viewModel.startPostureFlow()
                    viewModel.continueFromIntro()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Couldn’t complete check", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack {
                Button("Close") {
                    viewModel.closeFlow()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Try Again") {
                    viewModel.retryAfterError()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func stepDot(index: Int, active: Bool, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(active ? Color.blue : Color.secondary.opacity(0.2))
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(active ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(active ? Color.blue.opacity(0.08) : Color.clear)
        )
    }

    private var currentPhase: Int {
        switch viewModel.step {
        case .intro: return 0
        case .calibrating, .cameraReady: return 1
        case .analyzing: return 2
        case .result: return 3
        case .error: return 2
        }
    }

    private func postureScoreValue(for result: PostureCheckResult) -> Int {
        switch result.classification {
        case .good:
            return max(80, Int((result.confidence * 100).rounded()))
        case .adjust:
            return min(79, max(45, Int((result.confidence * 75).rounded())))
        case .inconclusive:
            return max(20, Int((result.confidence * 50).rounded()))
        }
    }
}

private struct AnalyzingPulseView: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var arcTrim: Double = 0.18
    @State private var breatheScale: Double = 1.0
    @State private var glowOpacity: Double = 0.18
    @State private var iconBob: Double = 0

    var body: some View {
        ZStack {
            // Outermost glow ring — pulses in/out slowly
            Circle()
                .stroke(Color.blue.opacity(glowOpacity), lineWidth: 22)
                .frame(width: 176, height: 176)
                .scaleEffect(breatheScale * 1.04)

            // Outer dashed rotating ring — clockwise slow rotation
            Circle()
                .stroke(
                    style: StrokeStyle(lineWidth: 3, dash: [6, 9])
                )
                .foregroundColor(Color.blue.opacity(0.30))
                .frame(width: 162, height: 162)
                .rotationEffect(.degrees(outerRotation))

            // Sweeping arc — counter-clockwise, trim breathing between 0.18 and 0.82
            Circle()
                .trim(from: 0, to: arcTrim)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(innerRotation))

            // Thin secondary arc offset 180° for depth
            Circle()
                .trim(from: 0, to: arcTrim * 0.5)
                .stroke(Color.blue.opacity(0.35), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(innerRotation + 180))

            // Inner breathing gradient fill
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.22), Color.blue.opacity(0.04)]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(breatheScale)

            // Center icon with subtle bobbing
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: iconBob)
        }
        .onAppear {
            // Outer ring slow rotation
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            // Inner arc fast rotation
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                innerRotation = 360
            }
            // Arc trim sweep 0.18 → 0.82 → 0.18
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                arcTrim = 0.82
            }
            // Breathing core + glow
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                breatheScale = 1.12
                glowOpacity = 0.08
            }
            // Icon subtle bob
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                iconBob = 4
            }
        }
    }
}

private struct AnalyzingStatusLabel: View {
    private let messages = [
        "Reading face landmarks...",
        "Estimating viewing angle...",
        "Comparing to ergonomic targets...",
        "Computing distance profile...",
        "Finalizing score..."
    ]
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0
    private let interval: TimeInterval = 1.1

    var body: some View {
        Text(messages[currentIndex])
            .foregroundColor(.secondary)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .opacity(opacity)
            .onAppear {
                startCycling()
            }
    }

    private func startCycling() {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentIndex = (currentIndex + 1) % messages.count
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }
            }
        }
    }
}

private struct CalibrationPulseView: View {
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 14)
                .frame(width: 130, height: 130)
            Circle()
                .trim(from: 0.1, to: 0.92)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 98, height: 98)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: spin)
            Image(systemName: "viewfinder.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.blue.opacity(0.85))
        }
        .onAppear {
            spin = true
        }
    }
}

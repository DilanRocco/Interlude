import SwiftUI
import AVFoundation

struct PostureFlowView: View {
    @ObservedObject var viewModel: PostureMenuViewModel
    @State private var showErgonomicsInfo = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .padding(24)
        }
        .frame(width: 460, height: 540)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(NSColor.windowBackgroundColor),
                            Color.blue.opacity(0.04),
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
                Text("Body pose analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                showErgonomicsInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            .popover(isPresented: $showErgonomicsInfo, arrowEdge: .bottom) {
                ergonomicsPopover
            }
        }
        .padding(18)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .ready:
            readyCard
        case .analyzing:
            analyzingCard
        case .result(let result):
            scoreCard(result: result)
        case .error(let message):
            errorCard(message: message)
        }
    }

    private var readyCard: some View {
        VStack(spacing: 14) {
            cameraPreview
                .overlay(
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Sit back so your shoulders are visible for the best results")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(8)
                        .padding(8)
                    }
                )

            Button {
                viewModel.startCheck()
            } label: {
                Text("Check Posture")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ergonomicsPopover: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("What does Interlude measure?")
                    .font(.headline)
                    .padding(.bottom, 2)

                Group {
                    Text("Posture Metrics")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                    ErgonomicsInfoRow(
                        icon: "person.fill",
                        title: "Head forward posture",
                        detail: "Your head should be balanced over your shoulders — not jutting forward. 0–15° of forward flex is normal, >30° significantly increases neck fatigue. A forward head often means your monitor is too low or too far."
                    )
                    ErgonomicsInfoRow(
                        icon: "arrow.left.and.right.circle",
                        title: "Head tilt",
                        detail: "Your head should be level, not tilted left or right. A persistent tilt usually means your screen, keyboard, or documents are off to one side."
                    )
                    ErgonomicsInfoRow(
                        icon: "arrow.up.and.down",
                        title: "Shoulder rounding",
                        detail: "Shoulders rolled forward indicates upper back rounding (thoracic kyphosis). Pull shoulder blades gently back and make sure your chair supports your upper back."
                    )
                    ErgonomicsInfoRow(
                        icon: "arrow.left.and.right",
                        title: "Shoulder symmetry",
                        detail: "Shoulders should be roughly level. Uneven shoulders suggest you're leaning to one side — check armrest height and whether you're reaching for a mouse that's too far away."
                    )
                }

                Divider()

                Group {
                    Text("Screen Setup")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                    ErgonomicsInfoRow(
                        icon: "display",
                        title: "Monitor position",
                        detail: "Top of monitor at or just below eye level. Screen center 10–20° below your horizontal line of sight. Distance: 50–90 cm (arm's length). Screen directly in front, not angled."
                    )
                    ErgonomicsInfoRow(
                        icon: "eye",
                        title: "Why looking slightly down matters",
                        detail: "A downward gaze of 10–20° reduces exposed eye surface, slowing tear evaporation and reducing dry eye. Looking up at a screen forces wider eye opening and fewer complete blinks."
                    )
                }

                Divider()

                Group {
                    Text("Quick Checklist")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 6) {
                        checklistRow("Monitor center 10–20° below eye level")
                        checklistRow("Screen at arm's length (50–90 cm)")
                        checklistRow("Head balanced over spine")
                        checklistRow("Neck flexion ≤15° while working")
                        checklistRow("Shoulders relaxed and level")
                        checklistRow("Back upright and supported by chair")
                        checklistRow("Screen directly in front, not angled")
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 340, height: 420)
    }

    private func checklistRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var analyzingCard: some View {
        VStack(spacing: 16) {
            cameraPreview
                .overlay(
                    ZStack {
                        Color.black.opacity(0.4)
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Analyzing...")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                        }
                    }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cameraPreview: some View {
        CameraPreviewView(session: viewModel.cameraManager.session)
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
    }

    private func scoreCard(result: PostureCheckResult) -> some View {
        let badgeColor = result.score >= 80 ? Color.green : (result.score >= 60 ? Color.orange : Color.red)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(Double(result.score) / 100.0))
                        .stroke(badgeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(result.score)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("/ 100")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 6) {
                    Text(result.score >= 80 ? "Good posture" : (result.score >= 60 ? "Fair posture" : "Needs work"))
                        .font(.headline)
                    if result.limitedVisibility {
                        Label("Shoulders not visible", systemImage: "eye.slash")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Text(String(format: "Confidence: %.0f%%", result.confidence * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !result.metrics.availableFactors.isEmpty {
                metricBreakdown(result: result)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(result.recommendations, id: \.self) { rec in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: result.score >= 80 ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundColor(result.score >= 80 ? .green : .blue)
                            .padding(.top, 2)
                        Text(rec)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(10)
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
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func metricBreakdown(result: PostureCheckResult) -> some View {
        VStack(spacing: 6) {
            if let angle = result.metrics.headForwardAngleDegrees {
                metricRow(
                    icon: "person.fill",
                    label: "Head Forward",
                    value: String(format: "%.0f°", angle),
                    score: gaussian(value: angle, sigma: 22.0)
                )
            }
            if let tilt = result.metrics.headTiltDegrees {
                metricRow(
                    icon: "arrow.left.and.right.circle",
                    label: "Head Tilt",
                    value: String(format: "%.0f°", tilt),
                    score: gaussian(value: tilt, sigma: 8.0)
                )
            }
            if let delta = result.metrics.shoulderSymmetryDelta {
                metricRow(
                    icon: "arrow.left.and.right",
                    label: "Shoulder Level",
                    value: String(format: "%.2f", delta),
                    score: gaussian(value: delta, sigma: 0.04)
                )
            }
            if let offset = result.metrics.shoulderRoundingOffset {
                metricRow(
                    icon: "arrow.up.and.down",
                    label: "Shoulder Roll",
                    value: String(format: "%.2f", offset),
                    score: gaussian(value: offset, sigma: 0.06)
                )
            }
        }
    }

    private func metricRow(icon: String, label: String, value: String, score: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            Text(label)
                .font(.caption.weight(.medium))
                .frame(width: 100, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(score >= 0.7 ? Color.green : (score >= 0.4 ? Color.orange : Color.red))
                        .frame(width: max(4, geo.size.width * score))
                }
            }
            .frame(height: 6)
            Text(value)
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(height: 18)
    }

    private func gaussian(value: Double, sigma: Double) -> Double {
        exp(-0.5 * (value * value) / (sigma * sigma))
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Couldn't complete check", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack {
                Spacer()
                Button("Try Again") {
                    viewModel.retryAfterError()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = CALayer()
        view.layer?.addSublayer(previewLayer)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = nsView.layer?.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
}

private struct ErgonomicsInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(.blue)
                .frame(width: 16)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
